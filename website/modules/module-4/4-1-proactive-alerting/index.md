---
layout: lesson
title: "Proactive Alerting Design"
description: "Most production alerting is broken — too noisy, too coarse, paging the wrong people for the wrong things. This lesson covers symptom-based alerting, severity classification, escalation policy design, and the alert hygiene practices that prevent alert fatigue."
module_number: 4
module_id: module-4
module_slug: module-4
module_title: "Incident Response & Operations"
module_icon: "🚨"
module_color: "#ef4444"
lesson_number: 1
lesson_id: "4-1"
reading_time: 17
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Distinguish symptom-based from cause-based alerting and apply each appropriately"
  - "Design a three-tier severity classification (page, ticket, log) with clear routing rules"
  - "Build escalation policies that match alert severity to organizational response capability"
  - "Implement alert hygiene practices — review cadence, suppression, deduplication — that prevent alert-fatigue collapse"
prev_lesson: /modules/module-3/3-3-capacity-modeling/
prev_title: "Capacity Modeling & Predictive Monitoring"
next_lesson: /modules/module-4/4-2-incident-response/
next_title: "Incident Response Workflows & Root Cause Analysis"
---

## The Quiet Failure of Most Alerting

Walk into any production team's alerting setup and you'll find one of three pathologies:

1. **The alert graveyard** — hundreds of alerts, dozens firing daily, almost all ignored. Real incidents fly past undetected because nobody notices any specific alert anymore.
2. **The cause sprawl** — alerts on every conceivable failure mode, each tied to a specific root cause. When something new breaks, no alert fires; when something old breaks, fifteen alerts fire simultaneously.
3. **The threshold museum** — alerts written when the service launched, never updated, now firing on yesterday's traffic levels and silently missing today's failure patterns.

All three pathologies share a single root cause: **alerting was treated as something you set up, not as something you maintain.** This lesson is about treating alerts as a designed system with explicit principles, ongoing hygiene, and clear ownership.

> **The core principle**: Alerts should be designed around what users experience, not what infrastructure does. The user doesn't care that a database connection pool is at 95% — they care that checkout is slow. Alert on the slow checkout; let the connection pool show up in the dashboard you check after you wake up.

---

## Part 1: Symptom-Based vs Cause-Based Alerting

### Symptom-Based Alerting

A symptom-based alert fires on **what users observe**: error rates, latency, availability. These map directly to your SLOs.

{% raw %}
```yaml
- alert: CheckoutAvailabilityBreach
  expr: |
    sum(rate(http_requests_total{job="checkout",code=~"5.."}[5m]))
    /
    sum(rate(http_requests_total{job="checkout"}[5m]))
    > 0.005
  for: 5m
  labels:
    severity: page
  annotations:
    summary: "Checkout error rate above 0.5% for 5 minutes"
    description: |
      Customers are experiencing failures completing purchases.
      Runbook: https://runbooks.example.com/checkout-availability
```
{% endraw %}

### Cause-Based Alerting

A cause-based alert fires on **a specific failure mechanism**: connection pool exhaustion, queue saturation, replication lag.

{% raw %}
```yaml
- alert: DatabaseConnectionPoolExhausted
  expr: |
    db_connections_active / db_connections_max > 0.95
  for: 2m
  labels:
    severity: page
```
{% endraw %}

### When To Use Which

**Use symptom-based alerts for paging.** They're the contract with the users. If users aren't impacted, you don't need to wake someone up at 3 AM.

**Use cause-based alerts as ticket-level.** They're the contract with future-you. They surface specific problems your runbooks can act on, but only become a paging concern if they translate into a symptom.

The classic anti-pattern: paging on cause-based alerts that *might* lead to a symptom. Your DBA gets paged at 3 AM for "connection pool at 95%" — but the application has graceful degradation and customers see no impact. Five hours of sleep lost for no operational benefit.

The correct pattern:

```
Symptom alert (user impact)        →  PAGE
Cause alert (might cause symptom)  →  TICKET (review next business day)
Cause alert (caused this symptom)  →  Auto-link to symptom alert; aid diagnosis
```

---

## Part 2: The Three-Tier Severity Model

Every production alerting system needs exactly three tiers. More than three creates confusion ("is this severity 4 or severity 5?"); fewer than three forces you to either over- or under-page.

### Tier 1: Page (Severity 1)

**Definition**: Customer-impacting problem requiring immediate human action. Wakes someone up.

**Examples**:
- Service availability below SLO threshold
- Latency p95 multiple-multiple of SLO
- Multi-window high burn rate (5m AND 1h windows both elevated)
- Catastrophic loss of capacity (e.g., entire AZ down)

**Response time**: Acknowledged within 5 minutes; engineer engaged within 15.

**Routing**: Primary on-call → secondary on-call → manager (5min / 10min / 15min).

### Tier 2: Ticket (Severity 2)

**Definition**: Real problem worth investigating, but not requiring immediate response. Created as a ticket; reviewed next business day.

**Examples**:
- Slow-burn latency drift (covered in Module 3.1)
- Predictive capacity alerts (30-day horizon)
- Cause-based alerts that didn't cascade to symptoms
- Single-window burn rate alerts (only 1h window elevated, 5m fine)

**Response time**: Reviewed within 1 business day.

**Routing**: Email/ticket queue, no paging.

### Tier 3: Log (Severity 3)

**Definition**: Anomaly worth recording for trend analysis but not actionable individually.

**Examples**:
- Sensitive anomaly detector outputs (Z-score > 2)
- Brief blips in non-critical services
- Information about state transitions

**Response time**: None. These exist for historical analysis.

**Routing**: Logged to anomaly stream, queryable via dashboard.

### The Severity Decision Tree

```
Did this alert correspond to user-visible impact?
├── YES → Page severity
└── NO
    ├── Will this become user-visible if not fixed in 24h?
    │   ├── YES → Page severity
    │   └── NO
    │       ├── Is the team likely to take action on it?
    │       │   ├── YES → Ticket severity
    │       │   └── NO  → Log severity (or DELETE this alert)
```

The "or DELETE this alert" branch is the single most under-used escape hatch in production alerting. If nobody is going to act on the alert, the alert has no business existing.

---

## Part 3: Symptom-Based Alerting From SLOs

The cleanest source of symptom alerts is your SLO definitions. Every SLO produces:

- **A page alert** on multi-window high burn rate (covered in Module 2.6)
- **A ticket alert** on single-window slow burn rate or budget exhaustion forecast
- **A dashboard panel** showing budget remaining

### A Complete SLO Alert Set

For a hypothetical 99.9% availability SLO on the checkout service:

{% raw %}
```yaml
groups:
  - name: checkout_slo_alerts
    rules:
      # Recording rules — burn rates over multiple windows
      - record: checkout:burn_rate_5m
        expr: |
          (
            sum(rate(http_requests_total{job="checkout",code=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{job="checkout"}[5m]))
          ) / 0.001    # SLO error budget = 0.1% allowed errors
      
      - record: checkout:burn_rate_1h
        expr: |
          (
            sum(rate(http_requests_total{job="checkout",code=~"5.."}[1h]))
            /
            sum(rate(http_requests_total{job="checkout"}[1h]))
          ) / 0.001
      
      - record: checkout:burn_rate_6h
        expr: |
          (
            sum(rate(http_requests_total{job="checkout",code=~"5.."}[6h]))
            /
            sum(rate(http_requests_total{job="checkout"}[6h]))
          ) / 0.001

      # Page: burning fast on both 5m and 1h windows
      - alert: CheckoutHighBurnRate_Page
        expr: |
          checkout:burn_rate_5m > 14.4
          and
          checkout:burn_rate_1h > 14.4
        for: 2m
        labels:
          severity: page
          slo: checkout_availability
        annotations:
          summary: "Checkout burning error budget at 14.4× — 2% of monthly budget gone in 1h"
          dashboard: "https://grafana/d/checkout-slo"
          runbook: "https://runbooks/checkout-burn-rate"

      # Ticket: slower burn on 6h window
      - alert: CheckoutHighBurnRate_Ticket
        expr: |
          checkout:burn_rate_1h > 6
          and
          checkout:burn_rate_6h > 6
        for: 15m
        labels:
          severity: ticket
          slo: checkout_availability
        annotations:
          summary: "Checkout sustained moderate burn rate over 6h — 10% of budget consumed"
```
{% endraw %}

This single alert group provides complete coverage of the SLO with no duplication and clear severity routing.

### Why Multi-Window Burn Rate Reduces Pages

Single-window burn rate alerts page on every blip. A multi-window approach (page only when *both* short and long windows agree) achieves a Google-tested precision:

| Approach | True positives | False positives |
|---|---|---|
| Single 5m window, threshold 14× | 100% caught | 1 false page per service per week |
| Single 1h window, threshold 14× | 100% caught (but late) | 1 false page per service per month |
| **Multi-window 5m AND 1h ≥ 14×** | **100% caught** | **<1 false page per service per quarter** |

The multi-window approach catches everything the single-window approach catches, **at roughly 1/10th the false-positive rate**.

---

## Part 4: Escalation Policy Design

An alert that fires but reaches nobody is worse than no alert. Escalation policies ensure alerts always reach a responder.

### The Standard Escalation Pattern

```yaml
escalation_policy:
  name: "checkout-team-page"
  
  steps:
    - delay: 0m
      target: primary_oncall@checkout-team
      methods: [push, sms]
    
    - delay: 5m
      target: primary_oncall@checkout-team
      methods: [phone]   # Loud and persistent
    
    - delay: 10m
      target: secondary_oncall@checkout-team
      methods: [push, sms, phone]
    
    - delay: 20m
      target: engineering_manager@checkout-team
      methods: [phone, slack]
    
    - delay: 35m
      target: vp_engineering
      methods: [phone, slack]
```

The 5-minute → 10-minute → 20-minute progression is empirically tuned: long enough that the primary actually has a chance to respond, short enough that someone is engaged within 30 minutes for any unanswered page.

### Follow-the-Sun Routing

For 24/7 services with global teams, route alerts to the on-call in the appropriate time zone:

```yaml
routing:
  - match: time_local_to_oncall("UTC+0", "07:00-19:00")
    escalation: emea-team-oncall
  - match: time_local_to_oncall("UTC-5", "07:00-19:00")
    escalation: amer-team-oncall
  - match: time_local_to_oncall("UTC+8", "07:00-19:00")
    escalation: apac-team-oncall
  - default:
    escalation: global-fallback-oncall
```

The principle: a 3 AM page is a failure of routing, not a normal cost of doing business. If you're paying for follow-the-sun coverage, route accordingly.

### Severity-Based Routing

Different severities should hit different channels:

| Severity | Method | Wake from sleep? |
|---|---|---|
| Page | Push + SMS + phone (escalating) | Yes |
| Ticket | Slack channel + email | No |
| Log | Anomaly stream dashboard | Never |

Mixing them — using SMS for ticket-level alerts, for instance — is the start of alert fatigue. Once your phone buzzes for both real fires and "FYI items," your reflexive response decays.

---

## Part 5: Alert Hygiene Practices

Alerts decay. Services evolve, traffic patterns shift, dependencies change. Without active hygiene, every alerting system trends toward useless within 18 months.

### The Weekly Alert Review

Every week, the on-call team should review:

1. **What pages fired?** Was each actionable? If not, fix or delete the alert.
2. **What pages did NOT fire that should have?** Often surfaces gaps post-incident.
3. **What's our paging rate?** Per-service per-week target: <2 pages, ideally 0–1.
4. **Any flapping alerts?** Alerts that fire-resolve-fire-resolve in cycles need investigation or deletion.

### The Quarterly Alert Audit

Every quarter, review every paging alert:

- **Is it still tied to a current SLO?** SLOs change; alerts must follow.
- **Has the threshold been correct?** A threshold tuned 18 months ago may be wildly off.
- **Has anyone actually responded to this alert in 90 days?** If not, downgrade or delete.
- **Is the runbook still accurate?** Stale runbooks cause longer incidents than no runbook.

### Alert Suppression

Two suppression patterns are essential:

**Maintenance silencing** — explicit windows where alerts are expected:
```yaml
silence:
  matchers:
    - service = "checkout"
  starts: "2026-04-15T02:00:00Z"
  ends:   "2026-04-15T04:00:00Z"
  reason: "Scheduled DB migration — checkout will see brief errors"
```

**Cascading suppression** — when a parent alert fires, suppress the children that are merely symptoms:
```yaml
inhibit_rules:
  - source_match:
      alertname: ZoneFailure
    target_match_re:
      alertname: ".*HighLatency"
    equal: [zone]
    # If a zone is down, don't page on every service-level latency alert in that zone
```

Cascading suppression turns "20 alerts firing simultaneously" into "1 alert firing — the actual root cause." This is the single biggest win for incident-response clarity.

---

## Try the Incident Response Decision Tree

The interactive tool simulates real incident scenarios and asks you to make triage decisions under time pressure. It's the closest thing to live on-call practice without real customer impact.

{% include tool-embed.html
   title="Incident Response Decision Tree"
   src="/tools/incident-response-decision-tree.html"
   description="Practice incident triage on realistic scenarios. Choose your response actions, see how decisions affect MTTR and customer impact, and review feedback on missed signals or unnecessary actions. Each scenario teaches a specific decision-making pattern."
   height="780"
%}

---

## Key Takeaways

**1. Alert on symptoms users feel; investigate causes from dashboards.** Page-tier alerts should map to SLO breaches, not infrastructure conditions. Cause-based alerts at ticket tier; suppress them when they're caused by an active page-tier symptom.

**2. Three severity tiers — Page, Ticket, Log — and no more.** Each has clear routing, response-time, and channel rules. Confusion comes from over-tiering or mixing channels across tiers.

**3. Multi-window burn rate alerts are the gold standard for SLO paging.** They catch real problems at ~1/10th the false-positive rate of single-window alerts.

**4. Cascading suppression turns alert storms into single signals.** When AZ-1 dies, you should get one "AZ-1 down" alert, not 200 service-level alerts. Set up the inhibit rules deliberately.

**5. Alert hygiene is a weekly + quarterly practice, not a one-time setup.** The teams with the best on-call experience are the ones who actively prune, not the ones with the most "complete" coverage.

---

*Next, when an alert does fire, what does excellent incident response look like? Lesson 4.2 covers the complete incident lifecycle from detection through postmortem.*
