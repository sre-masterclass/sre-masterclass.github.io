---
layout: lesson
title: "Chaos Engineering Integration in CI/CD"
description: "Make chaos engineering a continuous practice instead of a quarterly event. Automated chaos in staging on every PR, scheduled production chaos, GameDay automation, and the full pipeline pattern that proves resilience before each release ships."
module_number: 5
module_id: module-5
module_slug: module-5
module_title: "SRE in CI/CD"
module_icon: "🚀"
module_color: "#6366f1"
lesson_number: 3
lesson_id: "5-3"
reading_time: 16
difficulty: "Advanced"
tools_count: 0
objectives:
  - "Integrate automated chaos experiments into CI as resilience regression tests"
  - "Schedule production chaos to run continuously without operational toil"
  - "Automate GameDay logistics — scenario selection, scoring, and follow-up tracking"
  - "Build the integrated SRE pipeline that combines deployment automation, SLO gates, and chaos validation"
prev_lesson: /modules/module-5/5-2-slo-deployment-gates/
prev_title: "SLO-Based Deployment Gates"
next_lesson: /modules/
next_title: "Course Map"
---

## Chaos as Continuous Practice

In Module 4.3 you built the case for chaos engineering as hypothesis-driven experimentation. The natural next step is to ask: **why does chaos engineering only happen during scheduled GameDays?** Every CI run already executes test suites, security scans, and load tests. Why not chaos experiments too?

The answer used to be "because chaos is too risky to automate." That answer is wrong now. With the techniques from earlier lessons — bounded blast radius, steady-state validation, automated abort — chaos experiments can run as part of normal CI/CD with no more risk than any other automated test.

The result is a profound shift: **chaos engineering becomes a regression test for resilience properties**. Each PR that affects an availability- or latency-critical code path runs the relevant chaos experiments automatically. Resilience properties that used to be discovered during quarterly GameDays — or worse, during real Sev-1s — get caught at PR-review time.

> **The unifying principle of Module 5**: Modules 1–4 gave you tools to use *during* incidents (and to prevent them). Module 5 makes those tools part of the delivery pipeline so they get applied *every* time, *automatically*. The CI/CD pipeline is the highest-leverage place to enforce reliability practices because every change to the system flows through it.

---

## Part 1: Chaos in CI — Resilience Regression Tests

The simplest pattern: run chaos experiments as part of CI, on every PR that touches certain code paths.

### Pattern: Targeted Chaos Per PR

```yaml
# .github/workflows/ci.yml
name: CI with Chaos Tests

on:
  pull_request:
    
jobs:
  detect_changes:
    runs-on: ubuntu-latest
    outputs:
      affects_payment: ${{ steps.check.outputs.payment }}
      affects_checkout: ${{ steps.check.outputs.checkout }}
    steps:
      - uses: actions/checkout@v4
      - id: check
        run: |
          # Determine which code paths are affected
          CHANGED=$(git diff --name-only origin/main HEAD)
          [[ "$CHANGED" == *"payment-api/"* ]] && echo "payment=true" >> $GITHUB_OUTPUT
          [[ "$CHANGED" == *"checkout/"* ]] && echo "checkout=true" >> $GITHUB_OUTPUT
  
  chaos_payment_tests:
    needs: detect_changes
    if: needs.detect_changes.outputs.affects_payment == 'true'
    runs-on: ubuntu-latest
    
    steps:
      - name: Spin up ephemeral test environment
        run: |
          # Bring up the service + dependencies in an isolated namespace
          kubectl apply -f test-env/ -n ci-pr-${{ github.event.number }}
          
      - name: Run baseline load
        run: |
          k6 run --out=baseline.json scripts/load-baseline.js
          
      - name: Inject dependency latency
        run: |
          kubectl apply -f chaos/inject-payment-provider-latency.yaml \
            -n ci-pr-${{ github.event.number }}
            
      - name: Verify circuit breaker engages
        run: |
          # The hypothesis: when external payment provider is slow,
          # circuit breaker opens within 30s and we fall back to queue-based processing
          
          python -m chaos_validator \
            --hypothesis "circuit_breaker_opens_within_30s" \
            --hypothesis "fallback_to_queue_processing" \
            --hypothesis "no_user_visible_failures" \
            --max-error-rate 0.005 \
            --duration 5m
            
      - name: Tear down chaos
        if: always()
        run: |
          kubectl delete chaos --all -n ci-pr-${{ github.event.number }}
          kubectl delete namespace ci-pr-${{ github.event.number }}
```

The pattern's key properties:

- **Targeted**: only runs chaos relevant to the changed code
- **Ephemeral**: each PR gets its own isolated environment — no chaos crosstalk
- **Hypothesis-driven**: each test states what should happen and verifies it
- **Cleaned up**: regardless of pass/fail, the environment is torn down

### Library of Chaos Tests

Maintain a library of named chaos experiments, each tied to a specific resilience property:

```yaml
# /chaos-tests/registry.yaml
experiments:
  
  payment_provider_outage:
    description: "External payment provider returns errors"
    relevant_code_paths: ["payment-api/", "checkout/"]
    hypotheses:
      - "Circuit breaker opens within 30s"
      - "Fallback to queue-based processing engages"
      - "User-visible error rate stays below 0.5%"
    duration: 5m
    
  cache_layer_failure:
    description: "Redis cache becomes unreachable"
    relevant_code_paths: ["**/cache.py", "checkout/"]
    hypotheses:
      - "Cache misses route to database with bounded queue depth"
      - "P95 latency increases by no more than 100ms"
      - "Database connection pool does not become saturated"
    duration: 5m
    
  ddb_throttle:
    description: "DynamoDB throttles requests for 30s"
    relevant_code_paths: ["**/ddb_*.py"]
    hypotheses:
      - "Adaptive retry handles throttling without errors"
      - "Backoff prevents thundering herd"
    duration: 3m
    
  zone_failure:
    description: "Single AZ becomes unreachable"
    relevant_code_paths: ["infra/", "**/lb_*"]
    hypotheses:
      - "Traffic routes to healthy AZs within 60s"
      - "No customer-visible errors"
    duration: 2m
```

When a PR touches any matching code path, the relevant chaos experiments are added to its CI pipeline automatically. Reviewers see chaos test results alongside unit test results.

---

## Part 2: Continuous Production Chaos

Beyond CI, scheduled production chaos provides the highest-confidence resilience signal. The trick is making it sustainable — chaos that requires constant human attention won't survive.

### The Continuous Chaos Pattern

```yaml
# Production chaos schedule — runs continuously, automated entirely
apiVersion: chaos-mesh.org/v1alpha1
kind: Schedule
metadata:
  name: continuous-prod-chaos
spec:
  schedule: "0 14 * * 1,2,3,4"   # 14:00 UTC, Mon-Thu (business hours, never Friday)
  type: 'PodChaos'
  
  podChaos:
    selector:
      labelSelectors:
        chaos-eligible: "true"   # only services explicitly opted-in
        environment: "production"
        
    mode: one             # affect one pod at a time
    action: pod-kill
    duration: '1s'
    
  # Automated abort if SLOs degrade
  experimentSafeguards:
    - condition: "slo:checkout_availability:burn_rate_5m > 14"
      action: stop_immediately
    - condition: "active_severity_1_incidents > 0"
      action: stop_immediately
```

The principles:

- **Daily, not occasional.** Continuous chaos surfaces issues that "occasional" chaos misses.
- **Business hours only.** Chaos at 3 AM means engineering can't respond if something breaks. Run during business hours when the team is alert.
- **Never Fridays.** Don't be the team that needed weekend recovery from Friday-afternoon chaos.
- **Opt-in services.** A `chaos-eligible: "true"` label means service owners explicitly accept chaos. Don't chaos-test services that haven't been prepared.
- **Automated abort.** If SLOs start to degrade, the chaos schedule pauses itself.

### Increasing Sophistication Over Time

Start with the smallest possible chaos:

```
Month 1: Single pod kill, low-traffic service, business hours
Month 3: Random pod kill in cluster, 1× per business day
Month 6: AZ network partition, off-peak hour, weekly
Month 12: Multi-service cascading failures, monthly
```

Each step graduates only when the previous step has been running smoothly for a full month. Earned trust, not assumed trust.

---

## Part 3: GameDay Automation

GameDays from Module 4.3 produce huge value but demand significant logistics: scenario design, scheduling, scoring, follow-up. Automating the logistics keeps the practice sustainable.

### GameDay Coordinator Bot

```python
# A weekly cron job that runs the GameDay logistics
import datetime
import random
from gameday_lib import (
    select_scenario, schedule_meeting, notify_responders,
    create_postmortem_doc, track_action_items
)

def run_weekly_gameday_prep():
    """Prepare next week's GameDay automatically."""
    
    # Select a scenario from the library, weighted by:
    # - Time since last run (don't repeat too soon)
    # - Service criticality (more chaos for more critical services)
    # - Recent incidents (test scenarios related to recent failures)
    scenario = select_scenario(
        scenario_library='/gameday/scenarios.yaml',
        history='/gameday/history.json',
        recent_incidents=fetch_recent_incidents(days=30)
    )
    
    # Schedule GameDay for the same time next week
    next_week = datetime.date.today() + datetime.timedelta(days=7)
    schedule_meeting(
        date=next_week,
        time='14:00 UTC',
        duration='3h',
        attendees=fetch_team_oncall(),
        # IMPORTANT: don't reveal scenario to responders
        agenda='Quarterly resilience exercise — scenario revealed at start'
    )
    
    # Notify stakeholders (not responders)
    notify_stakeholders(
        gameday_date=next_week,
        scenario=scenario,
        coordinator='sre-team'
    )
    
    # Pre-create the postmortem doc
    create_postmortem_doc(
        date=next_week,
        scenario=scenario,
        template='/gameday/postmortem-template.md'
    )
```

What this automates:

- **Scenario selection** — based on history, criticality, recent incident patterns
- **Scheduling** — recurring meetings that don't require human coordination
- **Stakeholder communication** — automatic, consistent, no one forgets
- **Postmortem doc creation** — template ready to fill in during the retrospective
- **Action item tracking** — open items from previous GameDays surfaced

### Action Item Persistence

The single biggest GameDay failure mode: action items don't get done. Automate the persistence:

```python
def track_action_items():
    """Daily check on outstanding GameDay action items."""
    
    open_items = fetch_open_gameday_action_items()
    
    for item in open_items:
        if item.due_date < datetime.date.today():
            slack_notify(
                channel=item.owner_team,
                message=f"⏰ GameDay action item overdue: {item.title} (was due {item.due_date})"
            )
            
        if item.due_date < datetime.date.today() - datetime.timedelta(days=14):
            # Two weeks overdue — escalate to manager
            slack_notify(
                channel='#sre-leads',
                message=f"⚠️  GameDay action item severely overdue: {item.title}, owner: {item.owner}"
            )
```

GameDay action items get the same treatment as postmortem action items: tracked, escalated, and reported on as a leading indicator of program health.

---

## Part 4: The Integrated SRE Pipeline

You now have all the pieces. Putting them together, here's what a fully integrated SRE-aware CI/CD pipeline looks like:

```
┌─────────────────────────────────────────────────────────────────┐
│ STAGE 1: COMMIT & UNIT TESTING                                   │
│ - Standard unit tests, lint, type checks                         │
│ - Container build + signing                                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STAGE 2: PRE-DEPLOY GATES (5.2)                                  │
│ ✓ Error budget check — all affected services > 10% remaining    │
│ ✓ Recent incident check — no Sev-1s in past 24h                 │
│ ✓ Performance regression test — meets SLO targets in load test   │
│ ✗ FAIL → block deploy or require named approver                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STAGE 3: CHAOS REGRESSION TESTS (5.3)                            │
│ - Identify chaos experiments relevant to changed code            │
│ - Spin up ephemeral env, run experiments                         │
│ - Verify hypotheses (resilience properties hold)                 │
│ ✗ FAIL → block deploy; PR review needed                          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STAGE 4: CANARY DEPLOY (5.1)                                     │
│ 5% → 25% → 50% → 100%, with SLI delta analysis at each step     │
│ Multi-window rollback triggers armed                             │
│ ✗ FAIL at any stage → automatic rollback                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STAGE 5: POST-DEPLOY VALIDATION                                  │
│ - SLI verification (Module 2.3)                                  │
│ - Synthetic transactions (Module 1.3)                            │
│ - Continuous chaos remains armed against new version             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ STAGE 6: 24-HOUR MONITORING WINDOW                               │
│ - Multi-window burn rate monitoring (Module 3.1)                 │
│ - Anomaly detection on slow-burn drift (Module 3.2)              │
│ - Automatic rollback if burn rate alert fires                    │
└─────────────────────────────────────────────────────────────────┘
```

Every stage has SRE practice baked in. Every stage has an off-ramp. Every stage produces evidence the next stage uses for its decisions.

This is what "shifting reliability left" actually looks like in practice — not as a slogan, but as a concrete pipeline architecture where each stage applies a specific SRE technique from earlier in the course.

---

## Part 5: Maturity Progression

Don't try to build the full integrated pipeline at once. Mature in stages:

| Stage | What you have | What you're working on |
|---|---|---|
| **Level 1: Manual** | Engineers deploy manually; rollback is "redeploy the old version" | Automating canary deploys |
| **Level 2: Automated rollouts** | Canary or blue/green automated; rollback automated | Adding pre-deploy SLO gates |
| **Level 3: SLO gates** | Error budget checks block bad deploys | Adding chaos regression tests |
| **Level 4: Chaos in CI** | Chaos tests run on PR; resilience regressions caught early | Adding continuous production chaos |
| **Level 5: Continuous resilience verification** | Production chaos runs daily; GameDays automated | Optimization and iteration |

Most teams are at Level 1 or 2. The jump from 2 to 3 (adding SLO gates) is the highest-leverage transition — it's what makes the error budget policy real. The jump from 3 to 4 (chaos in CI) is the next-highest. Don't skip levels.

---

## Course Conclusion

You've now completed the SRE Masterclass. Six modules. Twenty-three lessons. Eleven interactive tools. A complete framework spanning:

- **Module 0** — the strategic foundation: why SRE matters, team models, organizational integration
- **Module 1** — the technical foundation: monitoring taxonomies, instrumentation, black/white box patterns
- **Module 2** — the SLO/SLI mastery: definition, mathematics, governance, capacity planning
- **Module 3** — the advanced monitoring: multi-window analysis, anomaly detection, predictive capacity
- **Module 4** — the operational practice: alerting, incident response, chaos engineering
- **Module 5** — the integration: deployment automation, SLO gates, continuous chaos

The framework isn't a checklist. Each piece reinforces the others. SLOs without alerting don't drive action. Alerting without incident response produces fatigue. Incident response without chaos engineering keeps you reactive. CI/CD without SRE integration ships bugs into production. The whole system works because the parts work together.

### Where to Go Next

You have three immediate paths:

1. **Apply the framework to your current systems.** Audit each module against your existing practice. The biggest gaps are usually in Module 2 (SLO governance) and Module 5 (CI/CD integration).
2. **Build the missing piece.** Most teams have one specific gap that limits everything else. Module 2.4 (error budget mathematics) is often the keystone — without it, the rest of the framework is hard to anchor.
3. **Run a Module 4.3-style GameDay against the most important user journey** in your system. Use the integrated pipeline checklist (Section 4 above) as a maturity assessment. The gaps you find are your roadmap.

### What This Course Was Really About

Strip away the YAML configurations, the Prometheus queries, and the architecture diagrams, and the SRE Masterclass is about one core idea:

**Reliability is not an attribute of a system. Reliability is a practice — a set of disciplined, repeatable activities that you do every day, embedded in how you build and operate software.**

The teams that achieve world-class reliability aren't smarter than other teams. They're not luckier. They've simply made reliability *the way they work*, not a thing they do separately. The framework you've learned across these six modules is one path to that practice.

The rest is up to you. Go build it.

---

*— End of the SRE Masterclass —*

*To revisit any module, see the [Course Map](/modules/). Each module is designed to stand alone for review; the cross-references throughout the lessons make it easy to find related concepts.*
