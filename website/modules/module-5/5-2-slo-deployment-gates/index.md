---
layout: lesson
title: "SLO-Based Deployment Gates"
description: "Connect error budget mathematics to pipeline policy. Block deploys when budgets are exhausted, run automated performance regression checks against SLO thresholds, and turn the error budget policy from a document into executable code."
module_number: 5
module_id: module-5
module_slug: module-5
module_title: "SRE in CI/CD"
module_icon: "🚀"
module_color: "#6366f1"
lesson_number: 2
lesson_id: "5-2"
reading_time: 17
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Implement pre-deploy gates that query SLO and error budget state before allowing deployment"
  - "Build performance regression tests that compare against SLO targets, not arbitrary thresholds"
  - "Encode the error budget policy as executable pipeline configuration"
  - "Design tiered approval flows for budget-exhausted deploys (block, require approval, allow with risk)"
prev_lesson: /modules/module-5/5-1-deployment-automation/
prev_title: "Deployment Automation & Progressive Delivery"
next_lesson: /modules/module-5/5-3-chaos-integration/
next_title: "Chaos Engineering Integration in CI/CD"
---

## The Error Budget Policy as Code

In Module 2.4, you built the mathematics of error budgets. In Module 2.7, you built the governance — including the error budget policy that says "when budget is exhausted, feature work pauses." This lesson is about **executing that policy automatically**.

Most error budget policies are PDFs. They're written, approved, posted to the wiki — and then ignored. The first time the budget is depleted, the on-call engineer doesn't remember to pause feature work, the PM doesn't accept that interpretation, and the policy collapses.

The fix: turn the policy into pipeline configuration. When the deploy attempts to run, the pipeline queries the SLO state, applies the policy, and either ships the deploy, blocks it, or requires explicit approval. **No human discretion required at deploy time.**

> **The core insight**: Error budget policies fail when they require willpower in the moment. The pipeline never has willpower problems. Encoding the policy in CI/CD means it actually gets enforced — every time, automatically, without conflict.

---

## Part 1: The Pre-Deploy Gate

Every deploy should pass through a pre-deploy gate that asks two questions:

1. **Is the SLO healthy enough to absorb the risk of this deploy?**
2. **Does this specific change introduce a performance regression vs. SLO targets?**

If either answer is "no," the deploy doesn't proceed.

### Gate Architecture

```yaml
deployment_pipeline:
  
  pre_deploy_gates:
    - name: error_budget_check
      type: prometheus_query
      query: |
        slo:checkout_availability:budget_remaining_30d
      condition: "result > 0.10"   # >10% budget remaining
      on_failure: block_or_approve
      
    - name: recent_incident_check
      type: prometheus_query
      query: |
        count_over_time(
          ALERTS{severity="page",service="checkout",alertstate="firing"}[24h]
        )
      condition: "result < 2"
      on_failure: require_approval
      
    - name: performance_regression_check
      type: load_test
      target: staging
      slo_target_p95: 200ms
      slo_target_error_rate: 0.005
      on_failure: block
```

Each gate has three properties:
- **What it checks** (a query or test)
- **What "passing" means** (an explicit condition)
- **What happens when it fails** (`block`, `require_approval`, `block_or_approve`)

### The Three Failure Modes

`block` — deploy is rejected outright. Engineer must address the issue and rerun the pipeline.

`require_approval` — deploy is paused; named approver(s) must explicitly approve before proceeding. Used for "yellow flag" conditions.

`block_or_approve` — combination: blocked by default, but a senior approver (e.g., VP Engineering) can override. Reserved for the most serious gate failures.

The choice between these depends on how much pipeline-time vs. human-time you want to invest:

| Condition | Recommended action |
|---|---|
| Budget < 10% remaining | `block_or_approve` (VP Eng can override for hotfix) |
| Budget < 30% remaining | `require_approval` (Eng manager must approve) |
| Budget < 70% remaining | Allow normally |
| Active incident on this service | `block` (don't deploy into a fire) |
| 2+ pages in last 24h | `require_approval` (caution) |
| Performance regression vs SLO | `block` (fix before shipping) |

---

## Part 2: Querying SLO State From Prometheus

The pipeline needs to query SLO and error budget state. The recording rules from Module 2.4 do the heavy lifting — the pipeline just queries the pre-computed values.

### Recording Rules for Pipeline Consumption

```yaml
# /etc/prometheus/rules/slo-budget.yml
groups:
  - name: slo_budget_state
    interval: 1m
    rules:
      
      # Total error rate budget consumed in 30-day window
      - record: slo:checkout_availability:budget_consumed_30d
        expr: |
          (
            sum(increase(http_requests_total{job="checkout",code=~"5.."}[30d]))
            /
            sum(increase(http_requests_total{job="checkout"}[30d]))
          )
          /
          0.001   # SLO error budget = 0.1% allowed errors
      
      # Budget remaining as fraction (0.0 to 1.0)
      - record: slo:checkout_availability:budget_remaining_30d
        expr: |
          1 - slo:checkout_availability:budget_consumed_30d
      
      # Time until budget exhausted at current rate (in days)
      - record: slo:checkout_availability:time_until_exhausted_days
        expr: |
          (
            slo:checkout_availability:budget_remaining_30d
            /
            (slo:checkout_availability:budget_consumed_30d / 30)
          )
```

### Pipeline Query Examples

GitHub Actions:

```yaml
# .github/workflows/deploy.yml
jobs:
  pre_deploy_gate:
    runs-on: ubuntu-latest
    outputs:
      budget_remaining: ${{ steps.budget.outputs.remaining }}
      proceed: ${{ steps.gate.outputs.proceed }}
      
    steps:
      - name: Check error budget
        id: budget
        run: |
          REMAINING=$(curl -sG "${PROMETHEUS_URL}/api/v1/query" \
            --data-urlencode 'query=slo:checkout_availability:budget_remaining_30d' \
            | jq -r '.data.result[0].value[1]')
          
          echo "remaining=${REMAINING}" >> $GITHUB_OUTPUT
          echo "Budget remaining: ${REMAINING}"
          
      - name: Apply gate policy
        id: gate
        run: |
          REMAINING=${{ steps.budget.outputs.remaining }}
          
          if (( $(echo "${REMAINING} < 0.10" | bc -l) )); then
            echo "Budget below 10% — block_or_approve required"
            echo "proceed=false" >> $GITHUB_OUTPUT
            echo "approval_required=vp-engineering" >> $GITHUB_OUTPUT
            exit 1
          elif (( $(echo "${REMAINING} < 0.30" | bc -l) )); then
            echo "Budget below 30% — manager approval required"
            echo "proceed=false" >> $GITHUB_OUTPUT
            echo "approval_required=eng-manager" >> $GITHUB_OUTPUT
            exit 1
          fi
          
          echo "Budget healthy at ${REMAINING} — proceeding"
          echo "proceed=true" >> $GITHUB_OUTPUT
  
  deploy:
    needs: pre_deploy_gate
    if: needs.pre_deploy_gate.outputs.proceed == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Run canary deploy
        run: |
          # ... canary deploy steps ...
```

### Multi-Service Budget Coordination

Most deployments touch multiple services. Check the budget for *every* service the deploy could affect:

```yaml
- name: Check budgets for all affected services
  run: |
    SERVICES="checkout payment-api auth-api"
    
    for SVC in $SERVICES; do
      REMAINING=$(curl -sG "${PROMETHEUS_URL}/api/v1/query" \
        --data-urlencode "query=slo:${SVC}_availability:budget_remaining_30d" \
        | jq -r '.data.result[0].value[1]')
        
      if (( $(echo "${REMAINING} < 0.10" | bc -l) )); then
        echo "❌ ${SVC} budget too low (${REMAINING}) — blocking deploy"
        exit 1
      else
        echo "✅ ${SVC} budget OK (${REMAINING})"
      fi
    done
```

---

## Part 3: Performance Regression Testing

The pre-deploy gate also runs a load test in staging and compares results to SLO targets. Unlike "is this faster than yesterday's build" tests, the SLO-aligned regression test asks: **"will this build meet our production SLO under realistic load?"**

### The SLO-Aligned Load Test

```yaml
# k6 load test, configured against SLO targets
load_test:
  duration: 10m
  target_rps: 1000   # representative production load
  
  scenarios:
    - name: checkout_full_flow
      weight: 70
      flow:
        - GET /products
        - POST /cart
        - POST /checkout
        
    - name: browse_only
      weight: 30
      flow:
        - GET /products
        
  thresholds:
    # These thresholds are the SLO targets
    http_req_duration{name:checkout}:
      - 'p(95) < 150'   # SLO is 200ms; build at 150ms threshold for safety margin
      - 'p(99) < 400'
      
    http_req_failed:
      - 'rate < 0.005'  # SLO is 99.9% (0.001 error rate); build at 0.005 for safety
      
    iteration_duration:
      - 'p(95) < 2000'  # full flow under 2s p95
```

### What "Failure" Means

A regression test failure is more nuanced than "did all assertions pass":

```python
# Pseudocode — the regression decision logic
def evaluate_regression_test(results, slo_targets):
    
    # Hard failure: any threshold breached
    if any(t.failed for t in results.thresholds):
        return {"action": "block", "reason": "SLO threshold breached in load test"}
    
    # Soft failure: significant regression vs. previous build
    p95_change = (results.p95 - previous_build.p95) / previous_build.p95
    if p95_change > 0.20:  # >20% regression
        return {"action": "require_approval", "reason": f"P95 latency regressed {p95_change:.1%}"}
    
    # Warning: trending in wrong direction over multiple builds
    p95_trend = analyze_trend(last_10_builds)
    if p95_trend.direction == "increasing" and p95_trend.slope > 0.05:
        return {"action": "warn", "reason": "P95 latency trending upward over last 10 builds"}
    
    return {"action": "pass"}
```

The trend check is particularly valuable — it catches "death by a thousand cuts" performance regressions where each individual build adds 2% latency, but over 50 builds the service has gotten 2× slower.

---

## Part 4: Encoding the Error Budget Policy

The error budget policy from Module 2.7 — "when budget is depleted, feature work stops" — becomes pipeline configuration:

### Sample Policy as Configuration

```yaml
# /policy/error-budget-policy.yaml
# This file is the SOURCE OF TRUTH for the error budget policy.
# Both the deployment pipeline and the SLO governance documents reference it.

policy_version: "2026.04"
last_reviewed: "2026-04-15"
business_owner: "sarah.chen@example.com"
technical_owner: "checkout-team"

services:
  checkout:
    slo_id: checkout_availability
    target: 99.9
    measurement_window: 30d
    
    enforcement_tiers:
      
      # Healthy — full deploy velocity
      - name: green
        condition: "budget_remaining > 0.50"
        deploy_policy: "allow"
        
      # Caution — non-feature deploys preferred
      - name: yellow
        condition: "0.10 < budget_remaining <= 0.50"
        deploy_policy: "allow_with_warning"
        warning_text: |
          ⚠️  Error budget below 50%. Prefer hotfixes and reliability work.
          New features acceptable but use extra caution.
        
      # Red — feature deploys blocked
      - name: red
        condition: "budget_remaining <= 0.10"
        deploy_policy: "block_features"
        block_categories: ["feature", "experiment"]
        allow_categories: ["hotfix", "reliability", "rollback"]
        override_required: "vp-engineering"
        
      # Black — all deploys blocked except rollback
      - name: black
        condition: "budget_remaining <= 0"
        deploy_policy: "block_all_except_rollback"
        override_required: "cto"
```

### How the Pipeline Reads the Policy

```python
# In the pipeline's pre-deploy gate
import yaml
import requests

# Load the policy
with open('/policy/error-budget-policy.yaml') as f:
    policy = yaml.safe_load(f)

service_policy = policy['services']['checkout']

# Query current budget state
budget_remaining = float(query_prometheus(
    "slo:checkout_availability:budget_remaining_30d"
))

# Determine current enforcement tier
for tier in service_policy['enforcement_tiers']:
    if eval_condition(tier['condition'], budget_remaining):
        current_tier = tier
        break

# Apply the policy
deploy_category = get_deploy_category()  # from PR labels or commit message

if current_tier['deploy_policy'] == 'block_features':
    if deploy_category in current_tier['block_categories']:
        require_override(current_tier['override_required'])
        
elif current_tier['deploy_policy'] == 'block_all_except_rollback':
    if deploy_category != 'rollback':
        require_override(current_tier['override_required'])
```

The policy file is the single source of truth. Updating the policy automatically updates the pipeline behavior. The policy is *enforceable*, not just aspirational.

### Categorizing Deploys

For policy enforcement to work, the pipeline must be able to categorize each deploy. Common approaches:

```yaml
# Via PR labels
deploy_category_from_labels:
  - label: "type/hotfix" → category: hotfix
  - label: "type/reliability" → category: reliability
  - label: "type/feature" → category: feature
  - label: "type/experiment" → category: experiment

# Via commit message convention
deploy_category_from_commit_message:
  - prefix "fix:" → category: hotfix
  - prefix "feat:" → category: feature
  - prefix "perf:" → category: reliability
  - prefix "ops:" → category: reliability
```

The category is metadata that the pipeline policy uses; it should be required for every deploy to pass the gate.

---

## Part 5: Override Mechanisms

The override mechanism is essential. Even the best policy will sometimes need to be bypassed — the question is whether bypass requires explicit, recorded human authorization.

### Override Pattern

```yaml
# Pipeline checks for an override before applying the gate
pre_deploy_gates:
  - name: error_budget_check
    on_failure: block
    
    override:
      method: "approval_label"
      label_prefix: "override/budget-bypass:"
      authorized_overriders:
        - team: vp-engineering
        - team: cto
      audit_log: true
      audit_destination: "https://audit.example.com/deploy-overrides"
```

The override pattern requires:

1. **Explicit grant**: a labeled PR or signed commit, not a Slack ping
2. **Limited authority**: only specific people/teams can grant the override
3. **Audit trail**: every override is logged for retrospective review
4. **Justification**: the override must include a reason

### Override Audit

Audit overrides quarterly:

| Date | Service | Reason | Approver | Outcome |
|---|---|---|---|---|
| 2026-04-15 | checkout | Budget at 8%, but feature has marketing dependency | VP Eng | Deploy succeeded; budget didn't drop further |
| 2026-04-22 | payment | Hotfix, but cooldown window active | Eng Mgr | Deploy succeeded; resolved an ongoing minor incident |

Patterns to look for:
- **Same service overridden repeatedly** → policy may be too strict, OR service has chronic reliability issues
- **Same person granting most overrides** → may be circumventing the policy
- **Overrides not followed by reliability investment** → policy isn't working as intended

---

## Part 6: Integrating With the Canary Pipeline

Pre-deploy gates run *before* the canary starts. But the SLO check is also useful *during* the canary — comparing canary SLI delta to the existing SLO budget impact.

```yaml
canary_progression:
  steps:
    - setWeight: 5
    - pause: 5m
    - analysis:
        templates:
          - canary-sli-analysis      # standard SLI delta check
          - budget-impact-projection  # NEW: project full-rollout budget impact
          
budget_impact_projection_template:
  successCondition: |
    # Project: if canary's error rate persists at full rollout, 
    # how much budget would be consumed in the next 24h?
    projected_24h_budget_consumption < 0.05  # don't consume >5% of budget per 24h
    
  query: |
    (
      canary_error_rate_5m * full_traffic_volume * 24
    )
    /
    monthly_error_budget_total
```

The canary gate becomes: "is this build going to be a sustainable burn rate at 100%?" Not just "is this build healthier than the last 5 minutes," but "would shipping this fully consume the error budget in a way the policy permits?"

---

## Try the Deployment Gate Simulator

The simulator lets you configure different gate setups (strict / moderate / permissive) and run synthetic deploys against varying SLO health states. See how gate stringency trades off deploy velocity against incident frequency.

{% include tool-embed.html
   title="Deployment Gate Simulator"
   src="/tools/deployment-gate-simulator.html"
   description="Configure pre-deploy gates and run simulated deploys against various SLO health states. See the trade-off between gate stringency, deploy velocity, error budget consumption, and incident rate."
   height="780"
%}

---

## Key Takeaways

**1. Encode the error budget policy as pipeline configuration.** Policies that require willpower in the moment fail. Policies that the pipeline applies automatically actually get enforced.

**2. Pre-deploy gates need explicit failure modes.** `block`, `require_approval`, and `block_or_approve` cover different severity levels. Don't lump them all into "fail" — the team needs to know what to do.

**3. Performance regression tests should compare to SLO targets, not historical performance.** "Better than yesterday's build" eventually approves builds that violate SLOs. "Meets the SLO target with margin" stays anchored to user-meaningful thresholds.

**4. The override mechanism is essential — make it explicit, authorized, and audited.** Eliminating override would make the system rigid; allowing informal override would gut it. Authorized + logged is the right balance.

**5. Multi-service budget coordination prevents one service's bad week from being amplified.** Checking budgets across all affected services before deploy means you don't ship one team's feature into another team's incident.

---

*The final lesson connects chaos engineering to CI/CD — running automated chaos tests in staging, scheduled production chaos, and the GameDay automation that makes resilience verification a continuous practice rather than a quarterly event.*
