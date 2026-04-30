---
layout: lesson
title: "Deployment Automation & Progressive Delivery"
description: "Move from 'deploy when the engineer hits go' to controlled progressive delivery: blue/green, canary, and traffic-shifting patterns with automatic rollback triggers tied to live SLI signals."
module_number: 5
module_id: module-5
module_slug: module-5
module_title: "SRE in CI/CD"
module_icon: "🚀"
module_color: "#6366f1"
lesson_number: 1
lesson_id: "5-1"
reading_time: 17
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Compare blue/green, canary, and progressive rollout patterns and choose appropriately for each service"
  - "Design canary analysis logic that uses SLI signals (not deploy-counter timeouts) to make progression decisions"
  - "Build automated rollback triggers tied to multi-window burn rate analysis"
  - "Architect a CI/CD pipeline where every deploy is observable, reversible, and bounded in blast radius"
prev_lesson: /modules/module-4/4-3-chaos-engineering/
prev_title: "Chaos Engineering & Operational Validation"
next_lesson: /modules/module-5/5-2-slo-deployment-gates/
next_title: "SLO-Based Deployment Gates"
---

## Every Deploy Is a Small Chaos Experiment

In Module 4.3 you saw chaos engineering framed as hypothesis-driven failure injection. Now apply the same lens to deployment:

**Deploying new code is a chaos experiment with a hypothesis: "this new version will perform at least as well as the current version under real production traffic."**

Most teams don't think about deploys this way. They think of them as "shipping the feature" — a binary act of pushing code and hoping. The reframe is enormously useful:

- The hypothesis is testable: are SLIs after the deploy at least as good as before?
- The steady state matters: was the system healthy before we deployed?
- The blast radius can be bounded: don't expose 100% of users to the new version immediately
- The off switch must exist: rollback must be fast and automated
- The result must be measured: did the new version actually perform as predicted?

This lesson is about building a pipeline that operates this way — making each deploy a small, controlled, observable, reversible event.

> **The core principle**: A deploy that can't be rolled back fast is a deploy that's permanently broken once it ships. The first investment in deployment automation is rollback speed; everything else builds on that foundation.

---

## Part 1: The Deployment Pattern Spectrum

Different deployment patterns trade off speed, risk, and complexity. Understanding the spectrum lets you choose the right pattern for the right service.

### Pattern 1: Recreate (legacy / not recommended)

```
Old version → kill all → start new version
```

**Use case**: Stateful services where running two versions concurrently is impossible.
**Risk**: Total outage during the transition.
**Speed**: Fastest deploy, slowest rollback (you have to redeploy).

### Pattern 2: Rolling Update

```
Replicas: 5
Update strategy:
  - Kill 1, start 1 new version
  - Wait for healthy
  - Kill next, start next new version  
  - Repeat
```

**Use case**: Stateless services that can tolerate version mixing during rollout.
**Risk**: Bad version partially exposed for the duration of the rollout.
**Speed**: Moderate.

### Pattern 3: Blue/Green

```
[Blue: v1.0]   ← all traffic
[Green: v1.1]  ← idle, fully provisioned

After validation:
[Blue: v1.0]   ← idle (kept warm)
[Green: v1.1]  ← all traffic (instant switch)

Rollback: switch back to Blue (instant)
```

**Use case**: Services where instant rollback is critical and double-resourcing is acceptable.
**Risk**: Cost (running 2× capacity); database/state migration complexity.
**Speed**: Slow to provision, instant to switch, instant to rollback.

### Pattern 4: Canary

```
[v1.0]: 95% of traffic
[v1.1]: 5% of traffic

If SLIs healthy, progress:
[v1.0]: 75% / [v1.1]: 25%

Continue progressing if SLIs healthy:
[v1.0]: 50% / [v1.1]: 50%
[v1.0]:  0% / [v1.1]: 100%
```

**Use case**: Gradual exposure, automated SLI-based progression. The reliability gold standard for stateless services.
**Risk**: Pipeline complexity; needs strong observability.
**Speed**: Slowest end-to-end, but rollback at any stage rolls back to the previous percentage.

### Choosing the Right Pattern

| Service property | Recommended pattern |
|---|---|
| Stateless, high traffic, has SLOs | **Canary** with SLI-based progression |
| Stateful or DB-coupled | **Blue/green** with explicit data migration |
| Low-traffic internal services | **Rolling update** is usually sufficient |
| Critical financial systems | **Blue/green** + manual approval gates |

The pattern is not a religion — different services in the same pipeline can use different patterns. What matters is the *principle*: bounded blast radius, fast rollback, observable progression.

---

## Part 2: Anatomy of a Canary Deploy

The canary pattern deserves a deep look because it's both the most powerful and the most commonly misimplemented.

### Stage 1: Initial Canary (5% traffic)

```yaml
# Argo Rollouts canary configuration
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: checkout-rollout
spec:
  replicas: 20
  strategy:
    canary:
      maxSurge: 10%
      maxUnavailable: 0
      
      steps:
        - setWeight: 5      # Start with 5% to canary
        - pause:
            duration: 5m    # Hold for 5 minutes; let SLIs accumulate
            
        # Analysis step: query Prometheus for SLI health
        - analysis:
            templates:
              - templateName: canary-sli-analysis
            args:
              - name: service
                value: checkout
                
        - setWeight: 25
        - pause: {duration: 10m}
        - analysis:
            templates: [canary-sli-analysis]
            
        - setWeight: 50
        - pause: {duration: 10m}
        - analysis:
            templates: [canary-sli-analysis]
            
        - setWeight: 100    # Full rollout
```

The key elements:

- **`setWeight`** controls traffic percentage to the canary
- **`pause`** lets SLI signals accumulate before measurement
- **`analysis`** queries Prometheus for SLI health and aborts if unhealthy

### The Analysis Template

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: canary-sli-analysis
spec:
  args:
    - name: service
      
  metrics:
    # Compare canary error rate to stable error rate
    - name: error-rate-delta
      successCondition: result[0] < 0.005
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            (
              sum(rate(http_requests_total{job="{{args.service}}",version="canary",code=~"5.."}[5m]))
              /
              sum(rate(http_requests_total{job="{{args.service}}",version="canary"}[5m]))
            )
            -
            (
              sum(rate(http_requests_total{job="{{args.service}}",version="stable",code=~"5.."}[5m]))
              /
              sum(rate(http_requests_total{job="{{args.service}}",version="stable"}[5m]))
            )
            
    # Compare canary p95 latency to stable
    - name: latency-delta-ratio
      successCondition: result[0] < 1.10
      provider:
        prometheus:
          query: |
            histogram_quantile(0.95, 
              rate(http_request_duration_seconds_bucket{job="{{args.service}}",version="canary"}[5m])
            )
            /
            histogram_quantile(0.95,
              rate(http_request_duration_seconds_bucket{job="{{args.service}}",version="stable"}[5m])
            )
            
    # Sample size check — don't progress on too little data
    - name: sample-size
      successCondition: result[0] > 1000
      provider:
        prometheus:
          query: |
            sum(increase(http_requests_total{job="{{args.service}}",version="canary"}[5m]))
```

The crucial details:

1. **Differential analysis**: compare canary to stable, not canary to a static threshold. A spike in latency caused by a traffic surge would fail an absolute threshold but pass a differential check.
2. **Sample size guard**: don't make decisions based on 5 requests. Require enough volume that the comparison is statistically meaningful.
3. **Multiple SLIs**: error rate AND latency AND sample size. Any failure aborts the canary.

### Stage Failure Behavior

When an analysis step fails:

```yaml
strategy:
  canary:
    abortScaleDownDelaySeconds: 30  # On abort, scale down canary in 30s
    
    # On abort behavior:
    # - Stop progressing
    # - Set canary weight back to 0%
    # - 100% traffic to stable version
    # - Alert team that canary aborted
```

The default behavior of canary frameworks (Argo Rollouts, Flagger, etc.) is to **automatically abort and rollback** on analysis failure. This is the right default — manual intervention is a slower, more error-prone rollback.

---

## Part 3: Multi-Window Rollback Triggers

A simple "if error rate > X then rollback" rule is too brittle. The same multi-window thinking from Module 3 applies to rollback decisions.

### The Three-Trigger Pattern

```yaml
rollback_triggers:
  
  # Fast trigger — high confidence, immediate response
  - name: fast_trigger
    expr: |
      canary:error_rate_5m > 5 * stable:error_rate_5m
      AND
      canary:request_count_5m > 100
    action: immediate_rollback
    
  # Slow trigger — sustained problem
  - name: slow_trigger
    expr: |
      canary:error_rate_30m > 1.5 * stable:error_rate_30m
    action: rollback_after: 5m
    
  # Latency trigger — separate dimension
  - name: latency_trigger
    expr: |
      canary:p95_latency_5m > 1.3 * stable:p95_latency_5m
      AND
      canary:p95_latency_30m > 1.2 * stable:p95_latency_30m
    action: rollback_after: 2m
```

The three triggers catch different failure modes:

- **Fast trigger** catches dramatic regressions (5× error rate). Roll back immediately.
- **Slow trigger** catches subtle but sustained regressions (50% worse over 30 minutes). Roll back after a brief confirmation period.
- **Latency trigger** catches performance regressions independent of error rate.

### Avoiding Rollback Loops

A common pitfall: a deployed bug fix triggers rollback, the rollback succeeds, an engineer manually re-promotes, the bug fires again, rollback again. To prevent this:

```yaml
deployment_policy:
  max_consecutive_rollbacks: 2
  on_max_reached:
    action: pause_deployments
    notify: [oncall, eng-lead]
    
  cooldown_after_rollback: 30m
  # Don't allow a re-promotion of the same image within 30 min of rollback
  # Forces investigation before retry
```

Two failed rollouts in a row is signal that something is structurally wrong. Pausing for human investigation is correct.

---

## Part 4: Database & State Considerations

The hardest deploys are ones that touch database schemas. Naive schema changes break the canary pattern: if v1.0 expects column `foo` and v1.1 expects column `bar`, you can't run them concurrently.

### The Expand-Migrate-Contract Pattern

Each schema change ships in three independent deploys:

```
Deploy 1 (Expand):
  - Add new column `bar` (nullable)
  - Code still reads/writes `foo`
  - Backfill `bar` from `foo` for new writes
  - VERIFY: no behavioral change

Deploy 2 (Migrate):
  - Code reads `bar`, writes both `foo` and `bar`
  - Background job backfills `bar` from `foo` for old rows
  - VERIFY: `bar` is fully populated

Deploy 3 (Contract):
  - Code reads/writes only `bar`
  - Drop `foo` column
  - VERIFY: no readers of `foo` remain
```

This pattern means each individual deploy is a normal canary deploy — running two versions concurrently is safe at every stage. The schema migration becomes three small, low-risk deployments instead of one terrifying one.

### Feature Flags as Decoupling Layer

Feature flags decouple deployment from feature exposure:

```python
# Deploy 1: ship the code, flag off, no behavioral change
if feature_flag("new_checkout_flow", user.id):
    return new_checkout_flow(user)
return existing_checkout_flow(user)

# Deploy 2: turn flag on for 5% of users (canary)
# Deploy 3: turn flag on for 100% (graduated)
# Cleanup: remove flag and old code path
```

This pattern is the deepest expression of the principle: **separate the technical act of deploying from the user-facing act of releasing**. The deploy can ship anytime; the release is a feature-flag toggle that is independently managed and instantly reversible.

---

## Part 5: Pipeline Architecture

Putting it all together, a production CI/CD pipeline looks like:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Code commit → CI                                          │
│    - Unit tests                                              │
│    - Static analysis                                         │
│    - Container build + signing                               │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Pre-deploy gates (covered in 5.2)                        │
│    - Error budget check                                      │
│    - Performance regression test                             │
│    - Chaos test in staging (covered in 5.3)                  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Canary deploy with SLI analysis                          │
│    - 5% → analyze → 25% → analyze → 50% → analyze → 100%   │
│    - Multi-trigger rollback armed                            │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Post-deploy validation                                    │
│    - SLI verification (no regression)                        │
│    - Synthetic transaction tests                             │
│    - Chaos verification (covered in 5.3)                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Monitor for 24h                                           │
│    - Anomaly detection on slow-burn drift                    │
│    - Auto-rollback if multi-window burn rate alert fires     │
└─────────────────────────────────────────────────────────────┘
```

Every stage has an off-ramp. Every stage has SLI-based gates. Every stage's progression is explicitly evidence-based, not time-based.

---

## Try the Pipeline SRE Integration Builder

The interactive tool lets you assemble a CI/CD pipeline by dragging stages and SRE practices into place. Build different pipelines for different service profiles and see how the choices affect deploy speed, rollback time, and SLO impact.

{% include tool-embed.html
   title="Pipeline SRE Integration Builder"
   src="/tools/pipeline-sre-integration-builder.html"
   description="Drag-and-drop CI/CD pipeline builder. Add stages, gates, and SRE integration points. See how different pipeline architectures trade off deploy velocity, blast radius, and rollback speed."
   height="780"
%}

---

## Key Takeaways

**1. Treat every deploy as a chaos experiment.** State the hypothesis (this version performs as well as the current one), define the steady state (current SLI values), bound the blast radius (canary), and have an off switch (automated rollback).

**2. Choose the deployment pattern that matches the service.** Canary for stateless high-traffic services with strong SLOs. Blue/green for stateful or critical financial systems. Rolling update for low-traffic internal services. The pattern is not a religion.

**3. Canary analysis must use differential SLI comparisons, not absolute thresholds.** Comparing canary to stable handles traffic surges, time-of-day effects, and other context that absolute thresholds break under.

**4. Multi-trigger rollback handles different failure modes.** Fast triggers catch dramatic regressions; slow triggers catch subtle ones; latency triggers catch performance regressions invisible to error-rate triggers. All three armed simultaneously.

**5. Decouple deploy from release with feature flags.** Schema changes use expand-migrate-contract. Behavioral changes ship behind flags. Deploy frequency goes up; per-deploy risk goes down.

---

*Now we add the SLO data layer to the pipeline. Lesson 5.2 connects the error budget mathematics from Module 2 to deployment policy: how to gate releases, automate the error budget policy, and integrate SLO health into every CI/CD decision.*
