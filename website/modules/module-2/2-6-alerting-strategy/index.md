---
layout: lesson
title: "Alerting Strategy & Burn Rate Implementation"
description: "Build an alerting architecture that catches real problems fast without creating alert fatigue — from alert design principles through burn rate implementation to routing, escalation, and continuous improvement."
module_number: 2
module_id: module-2
module_slug: module-2
module_title: "SLO/SLI Mastery"
module_icon: "🎯"
module_color: "#10b981"
lesson_number: 6
lesson_id: "2-6"
reading_time: 18
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Apply the three properties of a good alert to evaluate and improve your existing alert set"
  - "Implement the complete multi-window burn rate alert hierarchy for a 99.9% SLO"
  - "Design an escalation path that routes alerts to the right person at the right time"
  - "Run an alert review process that eliminates low-quality alerts before they cause fatigue"
prev_lesson: /modules/module-2/2-5-advanced-slo/
prev_title: "Advanced SLO Patterns"
next_lesson: /modules/module-2/2-7-slo-governance/
next_title: "SLO Governance & Organizational Maturity"
---

## Why Most Alerting Systems Are Broken

Alert fatigue is the most common symptom of a broken monitoring system. When engineers receive too many alerts, most of which don't require action, they start ignoring all of them. The monitoring system that was supposed to catch incidents is now producing its own incident — a trust deficit that makes actual problems invisible.

The root causes are always the same:
1. **Alerts fire without requiring action** — the metric threshold is too low or the problem resolves itself
2. **Alerts are triggered by symptoms, not causes** — 10 alerts fire for 1 underlying problem
3. **No escalation differentiation** — urgent and non-urgent alerts use the same channel with the same urgency

SLO-based burn rate alerting solves all three problems simultaneously.

---

## The Three Properties of a Good Alert

Before writing any alert, evaluate it against these three properties:

**1. Actionable**: Is there a documented response procedure? Can the on-call engineer do something meaningful when this fires? If "monitor and see if it resolves itself" is the documented response, delete the alert.

**2. Represents a user-visible problem (or its imminent precursor)**: Does this metric represent something users experience? Or is it an internal implementation detail? Alerts on internal metrics that don't directly map to user experience add cognitive load without improving reliability.

**3. Accurate**: Does this alert have a low false positive rate? Does it fire when there's actually a problem, and not fire when everything is fine?

### Evaluating Your Existing Alerts

Run this audit quarterly:
{% raw %}
```
For each alert in the past 90 days:
  - How many times did it fire?
  - How many of those fires led to a documented response?
  - What percentage were false positives (fired, no action needed)?
  
If false positive rate > 20%: retune or delete
If never led to action: delete
If fires daily with no action: retune threshold or delete
```
{% endraw %}

---

## The Complete Burn Rate Alert Hierarchy

The burn rate alert hierarchy from Lesson 2.4, implemented completely:

### Recording Rules (Run These First)

{% raw %}
```prometheus
# All recording rules for a checkout service with 99.9% SLO
# These pre-compute burn rates at multiple windows
# Run in separate Prometheus recording rule group for efficiency

groups:
  - name: slo:checkout:recording
    interval: 30s
    rules:
      # SLI values at multiple windows
      - record: slo:checkout:availability:1m
        expr: >
          sum(rate(http_requests_total{service="checkout",status_code!~"5.."}[1m]))
          / sum(rate(http_requests_total{service="checkout"}[1m]))
      
      - record: slo:checkout:availability:5m
        expr: >
          sum(rate(http_requests_total{service="checkout",status_code!~"5.."}[5m]))
          / sum(rate(http_requests_total{service="checkout"}[5m]))
      
      - record: slo:checkout:availability:30m
        expr: >
          sum(rate(http_requests_total{service="checkout",status_code!~"5.."}[30m]))
          / sum(rate(http_requests_total{service="checkout"}[30m]))
      
      - record: slo:checkout:availability:1h
        expr: >
          sum(rate(http_requests_total{service="checkout",status_code!~"5.."}[1h]))
          / sum(rate(http_requests_total{service="checkout"}[1h]))
      
      - record: slo:checkout:availability:6h
        expr: >
          sum(rate(http_requests_total{service="checkout",status_code!~"5.."}[6h]))
          / sum(rate(http_requests_total{service="checkout"}[6h]))
      
      # Burn rates (error rate / acceptable error rate)
      # For 99.9% SLO: acceptable error rate = 0.001
      - record: slo:checkout:burn_rate:1m
        expr: (1 - slo:checkout:availability:1m) / 0.001
      
      - record: slo:checkout:burn_rate:5m
        expr: (1 - slo:checkout:availability:5m) / 0.001
      
      - record: slo:checkout:burn_rate:30m
        expr: (1 - slo:checkout:availability:30m) / 0.001
      
      - record: slo:checkout:burn_rate:1h
        expr: (1 - slo:checkout:availability:1h) / 0.001
      
      - record: slo:checkout:burn_rate:6h
        expr: (1 - slo:checkout:availability:6h) / 0.001
```
{% endraw %}

### Alerting Rules

{% raw %}
```yaml
groups:
  - name: slo:checkout:alerts
    rules:
      # CRITICAL: Fast burn — budget exhausted in ~2 hours
      # Requires BOTH 1h and 5m windows to be elevated
      # Prevents alerting on: brief spikes (caught by 5m short-circuit)
      # and brief recoveries from long incidents (caught by 1h confirmation)
      - alert: CheckoutSLOFastBurn
        expr: >
          slo:checkout:burn_rate:1h > 14.4
          AND
          slo:checkout:burn_rate:5m > 14.4
        for: 2m
        labels:
          severity: critical
          team: checkout
          slo: checkout_availability
        annotations:
          summary: "Checkout SLO fast burn — budget exhausted in ~2h at current rate"
          description: >
            Burn rate is {{ $value }}×. 
            At this rate, the monthly error budget will be exhausted in
            {{ printf "%.1f" (div 720.0 $value) }} hours.
          runbook: "https://runbooks.internal/checkout-slo-fast-burn"
          dashboard: "https://grafana.internal/d/checkout-slo"
      
      # WARNING: Moderate burn — budget exhausted in ~3 days
      - alert: CheckoutSLOModerateBurn
        expr: >
          slo:checkout:burn_rate:6h > 3
          AND
          slo:checkout:burn_rate:30m > 3
        for: 10m
        labels:
          severity: warning
          team: checkout
          slo: checkout_availability
        annotations:
          summary: "Checkout SLO moderate burn — elevated error rate for 6+ hours"
          runbook: "https://runbooks.internal/checkout-slo-moderate-burn"
      
      # INFO: Budget below 20% — trigger reliability sprint discussion
      - alert: CheckoutErrorBudgetLow
        expr: slo:checkout:error_budget_remaining < 0.20
        for: 1h
        labels:
          severity: info
          team: checkout
        annotations:
          summary: "Checkout error budget {{ $value | humanizePercentage }} remaining this month"
```
{% endraw %}

---

## Alert Routing Architecture

{% raw %}
```yaml
# AlertManager routing for SLO-based alerts
route:
  group_by: ['alertname', 'service', 'slo']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default'
  
  routes:
    # Critical burn rate: page immediately
    - matchers:
        - severity="critical"
        - alertname=~".*FastBurn"
      receiver: 'pagerduty-critical'
      group_wait: 0s  # No delay for critical
      repeat_interval: 1h
      
    # Warning: Slack + create ticket
    - matchers:
        - severity="warning"
        - alertname=~".*ModerateBurn"
      receiver: 'slack-warning'
      continue: true  # Also create Jira ticket
      
    # Info: Email digest
    - matchers:
        - severity="info"
      receiver: 'email-digest'
      group_interval: 1h
      repeat_interval: 24h
```
{% endraw %}

### Escalation Policy

The escalation path for a critical burn rate alert:
1. **T+0**: Alert fires → primary on-call paged
2. **T+5m**: Primary acknowledges → incident channel created
3. **T+15m**: If not acknowledged → secondary on-call paged
4. **T+30m**: If burn rate still > 14×, MTTR > 30m → engineering manager paged
5. **T+60m**: If not resolved → director level notification

---

## Reducing Alert Noise

The most common alert noise sources and how to eliminate them:

### Flapping Alerts

**Symptom**: An alert fires and resolves multiple times in quick succession.

**Fix**: Increase the `for:` duration. If an alert requires 5 consecutive minutes at the threshold before firing, single-minute spikes won't trigger it.

{% raw %}
```yaml
# Before: fires every time metric crosses threshold
alert: HighErrorRate
expr: error_rate > 0.01
for: 0s  # Fires immediately — very noisy

# After: requires sustained condition
alert: HighErrorRate
expr: error_rate > 0.01
for: 5m  # Must be above threshold for 5 consecutive minutes
```
{% endraw %}

### Missing Data Alerts

**Symptom**: Alert fires because metrics stopped being reported (service restarted, scrape failure) rather than because of an actual condition.

**Fix**: Use `absent()` to detect missing metrics explicitly, and add `or` clauses to handle missing data gracefully:

{% raw %}
```yaml
# Fires when metric is missing OR when condition is met
expr: >
  (absent(http_requests_total) == 1)
  OR
  (rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01)
```
{% endraw %}

### Cause-and-Effect Alert Storms

**Symptom**: One underlying problem triggers 10+ alerts simultaneously.

**Fix**: Use AlertManager's inhibition rules to suppress downstream alerts when a root cause alert is already firing:

{% raw %}
```yaml
# inhibit_rules: if a node-down alert is firing,
# suppress all per-service alerts on that node
inhibit_rules:
  - source_matchers:
      - alertname="NodeDown"
    target_matchers:
      - alertname=~"Service.*"
    equal: ['node']
```
{% endraw %}

---

## Key Takeaways

**1. Alert fatigue is an architecture problem, not an attention problem.** If engineers ignore alerts, the alert architecture is wrong — not the engineers.

**2. Every alert must be actionable.** If there's no documented response procedure, it shouldn't be an alert.

**3. Multi-window burn rate alerts are self-auditing.** They fire only when a real SLO-relevant problem persists across two windows simultaneously — dramatically reducing false positives.

**4. Route by urgency, not by source.** Critical burn rates page on-call. Moderate burns create tickets. Low-burn info goes to weekly review. Different urgency = different channel.

**5. Review your alerts quarterly.** Delete alerts with high false positive rates. Retune thresholds for alerts that fire constantly without action. Your alert set should shrink over time as you improve quality, not grow.

---

*The next lesson covers SLO governance — the organizational processes, review cadences, and maturity model that turn individual SLOs into a program-level reliability management system.*
