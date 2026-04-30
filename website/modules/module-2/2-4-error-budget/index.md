---
layout: lesson
title: "Error Budget Mathematics & Burn Rate"
description: "Master the mathematics of error budgets — how much reliability budget you have, how fast you're spending it, and the burn rate alerting that tells you when you'll run out before your SLO window closes."
module_number: 2
module_id: module-2
module_slug: module-2
module_title: "SLO/SLI Mastery"
module_icon: "🎯"
module_color: "#10b981"
lesson_number: 4
lesson_id: "2-4"
reading_time: 22
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Calculate error budget remaining using the standard formula for any SLO target and window"
  - "Compute burn rate to determine how fast the error budget is being consumed"
  - "Design multi-window burn rate alerts that provide both fast detection and low false-positive rates"
  - "Implement error budget tracking in Prometheus recording rules"
prev_lesson: /modules/module-2/2-3-sli-implementation/
prev_title: "SLI Implementation Patterns"
next_lesson: /modules/module-2/2-5-advanced-slo/
next_title: "Advanced SLO Patterns"
---

## Error Budget: The Math Behind the Policy

The error budget is not a metaphor — it's a precise mathematical construct. Understanding the math is a prerequisite for implementing burn rate alerting that's both sensitive enough to catch real problems and specific enough not to create alert fatigue.

> **The core formula**: 
> `Error Budget = (1 - SLO target) × measurement window duration`
>
> For a 99.9% SLO over 30 days:
> `Error Budget = (1 - 0.999) × (30 × 24 × 60 minutes) = 43.2 minutes`

---

## Part 1: Error Budget Fundamentals

### Calculating Your Error Budget

| SLO Target | 30-day Budget | 7-day Budget |
|---|---|---|
| 99.0% | 7.2 hours | 1.68 hours |
| 99.5% | 3.6 hours | 50.4 min |
| 99.9% | 43.2 min | 10.1 min |
| 99.95% | 21.6 min | 5.0 min |
| 99.99% | 4.32 min | 60.5 sec |

### Error Budget in Event Terms

For request-based SLIs, the error budget is more usefully expressed as a fraction of allowed bad events:

```
Error Budget (events) = (1 - SLO) × total_requests_in_window

Example: 99.9% SLO, 1M requests/month
Error Budget = 0.001 × 1,000,000 = 1,000 bad requests allowed per month
```

This formulation is more intuitive during incidents: "This outage caused 450 bad requests — we've used 45% of our monthly error budget."

### Remaining Error Budget

```
Budget Remaining = Budget Total - Budget Consumed

Budget Consumed (time-based) = 
  sum(seconds where SLI < SLO target) during measurement window

Budget Consumed (event-based) = 
  bad_events during measurement window / total_allowed_bad_events
```

In Prometheus, implement this as recording rules:

```prometheus
# Total error budget in ratio terms (0 to 1)
# For a 99.9% SLO: total_error_budget = 0.001
record: slo:error_budget:total
expr: 1 - 0.999  # 99.9% SLO

# Budget consumed: ratio of bad events in the 30-day window
record: slo:error_budget:consumed_30d
expr: >
  1 - (
    sum_over_time(slo:availability_sli[30d]) 
    / count_over_time(slo:availability_sli[30d])
  )

# Budget remaining: fraction from 0 (exhausted) to 1 (full)
record: slo:error_budget:remaining_fraction
expr: >
  1 - (slo:error_budget:consumed_30d / slo:error_budget:total)
```

---

## Part 2: Burn Rate

The burn rate tells you how fast you're consuming the error budget relative to the sustainable rate.

### The Burn Rate Formula

```
Burn Rate = actual_error_rate / acceptable_error_rate

where:
  acceptable_error_rate = 1 - SLO_target
  (e.g., for 99.9% SLO: acceptable rate = 0.1% = 0.001)
```

**Burn rate = 1**: You're consuming budget at exactly the sustainable rate. At the end of the measurement window, you'll have exactly 0% budget remaining. Nominal behavior.

**Burn rate = 2**: You're consuming budget twice as fast as sustainable. You'll exhaust your 30-day budget in 15 days.

**Burn rate = 14.4**: You'll exhaust your 30-day budget in 2 days (at this burn rate, a 2-hour problem consumes 100% of the monthly budget).

**Burn rate = 720**: You're in a complete outage (100% error rate). You'll exhaust your 30-day budget in 1 hour.

### Burn Rate Examples

For a 99.9% SLO (0.1% acceptable error rate):

| Actual Error Rate | Burn Rate | Budget Exhausted In |
|---|---|---|
| 0.1% | 1× | 30 days (nominal) |
| 0.2% | 2× | 15 days |
| 1% | 10× | 3 days |
| 5% | 50× | 14.4 hours |
| 50% | 500× | 86.4 minutes |
| 100% | 1000× | 43.2 minutes |

```prometheus
# Burn rate calculation
# error_rate / (1 - slo_target)
record: slo:burn_rate:1h
expr: >
  (
    sum(rate(http_requests_total{status_code=~"5.."}[1h]))
    / sum(rate(http_requests_total[1h]))
  ) / (1 - 0.999)

record: slo:burn_rate:6h
expr: >
  (
    sum(rate(http_requests_total{status_code=~"5.."}[6h]))
    / sum(rate(http_requests_total[6h]))
  ) / (1 - 0.999)
```

---

## Part 3: Multi-Window Burn Rate Alerting

The Google SRE Workbook describes the multi-window, multi-burn-rate alerting pattern that balances detection speed with false positive rate.

### The Problem with Single-Window Alerting

**Too short a window (1h)**: Catches fast-burning incidents quickly, but fires constantly on transient spikes. High false positive rate → alert fatigue.

**Too long a window (30d)**: Smooth, accurate burn rate calculation, but by the time it fires, most of the budget is already gone. Useless for real-time incident response.

### The Solution: Multiple Windows

Use two windows simultaneously for each alert:
- **Long window** (1h or 6h): Confirms that a real burn rate problem exists
- **Short window** (5m or 30m): Confirms the problem is still ongoing (not already resolved)

Alert fires only when **both conditions are true simultaneously**.

### Recommended Alert Thresholds (Google SRE Workbook)

For a 99.9% SLO over 30 days:

```yaml
# Critical: Fast-burning incident
# 14.4× burn rate = budget exhausted in 2 hours if sustained
# Short window: confirms problem is current
# Long window: confirms it's not a 1-minute spike
alert: SLOFastBurn
expr: >
  slo:burn_rate:1h > 14.4
  AND slo:burn_rate:5m > 14.4
for: 1m
labels:
  severity: critical
annotations:
  summary: "Fast burn rate: error budget will be exhausted in ~2 hours"

---
# Warning: Moderate burn (but will exhaust budget in 3 days if sustained)
alert: SLOModerateBurn
expr: >
  slo:burn_rate:6h > 3
  AND slo:burn_rate:30m > 3
for: 5m
labels:
  severity: warning
annotations:
  summary: "Moderate burn rate: error budget will be exhausted in ~3 days"

---
# Info: Slow burn (exhausts in ~7.5 days if sustained)
alert: SLOSlowBurn
expr: slo:burn_rate:3d > 1
for: 1h
labels:
  severity: info
annotations:
  summary: "Slow but elevated burn rate over the past 3 days"
```

### Alert Routing for Burn Rate

Burn rate alerts are fundamentally different from traditional threshold alerts:
- **Fast burn** → page the on-call engineer immediately
- **Moderate burn** → send to Slack, create a ticket, notify team lead
- **Slow burn** → include in weekly SLO review, no immediate response required

This tiered response reduces on-call burden while ensuring fast detection of serious incidents.

{% include tool-embed.html
   title="SLO Calculator & Burn Rate Simulator"
   src="/tools/slo-calculator-burn-rate-simulator.html"
   description="Calculate error budgets, simulate burn rates, and design multi-window alert thresholds for your specific SLO targets. See how different incident scenarios affect budget consumption over time."
   height="720"
%}

---

## Part 4: Error Budget Accounting

For error budget governance to work, you need accurate accounting of how budget was consumed and why.

### Budget Consumption Sources

Budget consumption comes from multiple sources, and tracking each separately enables better prioritization:

- **Incidents**: Unplanned failures — the main category you're trying to minimize
- **Deployments**: Canary failures, rollback time, deployment-related errors
- **Planned maintenance**: Scheduled downtime that users experience
- **Third-party failures**: Dependency failures outside your control
- **Synthetic probe noise**: False positives from flapping probes

```prometheus
# Tag budget consumption by source for accurate attribution
record: slo:budget_consumed:by_source
labels:
  source: incident | deployment | maintenance | dependency | noise
```

### Incident Attribution

During incidents, track:
1. Time of detection (when did alerts fire?)
2. Time of acknowledgment (when did someone start working on it?)
3. Time of resolution (when did SLI return to healthy?)
4. Duration of impact (resolution time - detection time)
5. Budget consumed: `duration_minutes / total_budget_minutes`

---

## Key Takeaways

**1. Error budget is a precise number, not a metaphor.** `(1 - SLO) × measurement_window` gives you the exact allowance. Know yours.

**2. Burn rate is more actionable than absolute error rate.** "Error rate is 1%" tells you the rate. "Burn rate is 10×" tells you you're on track to exhaust your budget in 3 days — that's actionable.

**3. Multi-window alerting balances sensitivity and specificity.** Long window alone produces slow detection. Short window alone produces alert fatigue. Both together catches real incidents quickly without crying wolf.

**4. Fast burns wake people up; slow burns get fixed in sprints.** Design your response policy to match the urgency encoded in the burn rate.

**5. Track budget consumption by source.** Knowing that 40% of your budget consumption comes from deployment failures vs. 60% from incidents tells you very different things about where to invest.

---

*The next lesson covers advanced SLO patterns — windowed SLOs, multi-dimensional SLOs, dependency-aware SLOs, and the techniques for handling services that don't fit the standard availability/latency model.*
