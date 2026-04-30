---
layout: lesson
title: "SLO Definition Workshop"
description: "A hands-on workshop for defining Service Level Objectives that stakeholders trust — from identifying what users care about to negotiating targets with product, engineering, and business teams."
module_number: 2
module_id: module-2
module_slug: module-2
module_title: "SLO/SLI Mastery"
module_icon: "🎯"
module_color: "#10b981"
lesson_number: 1
lesson_id: "2-1"
reading_time: 20
difficulty: "Intermediate"
tools_count: 1
objectives:
  - "Lead an SLO definition workshop with product, engineering, and business stakeholders"
  - "Distinguish between SLAs, SLOs, and SLIs and explain why each exists"
  - "Apply the user journey mapping technique to identify the right SLO coverage points"
  - "Avoid the five most common SLO definition anti-patterns"
prev_lesson: /modules/module-1/1-5-monitoring-architecture/
prev_title: "Monitoring Architecture Design"
next_lesson: /modules/module-2/2-2-latency-distribution/
next_title: "Latency Distribution & Statistical Analysis"
---

## What Makes an SLO Different from an Uptime Target

Many teams have uptime targets. "We aim for 99.9% availability." But targets without accountability, measurement, or consequences aren't SLOs — they're aspirations.

A real SLO is:
1. **Defined in terms of user experience**, not internal system behavior
2. **Measured continuously** using an SLI (Service Level Indicator)
3. **Connected to a decision framework** (error budget) that governs how reliability and velocity trade off
4. **Agreed on by multiple stakeholders** — not unilaterally declared by engineering

This lesson is a workshop guide for building real SLOs.

> **The hierarchy you must know**: SLI (what we measure) → SLO (our target for that measurement) → SLA (the contractual commitment we make to customers, typically a subset of our SLO). Violating an SLO doesn't necessarily violate an SLA, but it should trigger reliability investment before the SLA is threatened.

---

## The SLA / SLO / SLI Hierarchy

### Service Level Indicator (SLI)

An SLI is a carefully defined quantitative measure of some aspect of the service's behavior. It's a ratio:

```
SLI = good_events / total_events
```

**Example SLIs:**
- `successful_requests / total_requests` (availability)
- `requests_under_500ms / total_requests` (latency)
- `correct_responses / total_responses` (correctness)
- `processed_jobs / submitted_jobs` (throughput)

The SLI is always a number between 0 and 1 (or expressed as a percentage).

### Service Level Objective (SLO)

An SLO is a target value for an SLI over a measurement window:

```
SLO: availability SLI >= 99.9% over a rolling 30-day window
```

The measurement window matters enormously — the same underlying SLI can be expressed as:
- 99.9% over 30 days (43.2 minutes of allowed downtime)
- 99.9% over 7 days (10 minutes of allowed downtime)
- 99.99% over 30 days (4.32 minutes of allowed downtime)

These are very different reliability commitments with very different operational implications.

### Service Level Agreement (SLA)

An SLA is a contract with customers that specifies the minimum service level and the consequences of failing to meet it (typically financial credits or refunds).

**Critical insight**: Your SLO should be stricter than your SLA. If your SLA promises 99.5% availability, your internal SLO should target 99.9%. This gives you buffer — when your SLO is breached, you have time to recover before the SLA is violated.

---

## The Five SLO Anti-Patterns

Before defining your SLOs, understand these common failure modes:

### Anti-Pattern 1: Infrastructure Metrics as SLOs

**Wrong**: "CPU utilization < 70%"
**Problem**: CPU utilization is not a user experience metric. Users don't care about CPU utilization — they care about request latency and error rates. A service can have 90% CPU utilization while serving users perfectly well.

**Right**: "P99 request latency < 500ms"

### Anti-Pattern 2: The "100% Availability" SLO

**Wrong**: "99.99999% availability"
**Problem**: Unachievable SLOs destroy the error budget framework. If the theoretical maximum availability of your system (given dependencies, deployment risks, and maintenance) is 99.9%, setting an SLO of 99.999% means you're always breached. Nobody takes it seriously.

**Right**: Start with historical data. If you've been running at 99.5% over the past 12 months, set an SLO of 99.5% and aspire to 99.9%.

### Anti-Pattern 3: SLOs Without Owner Agreement

**Wrong**: SRE team unilaterally declares SLOs.
**Problem**: Without product and business agreement, SLOs are engineering vanity metrics. When error budgets are depleted and feature releases need to stop, product teams will simply override the SLO.

**Right**: SLOs are negotiated in a workshop with at least product, engineering, and SRE present. The SLO target is a business decision, not a technical one.

### Anti-Pattern 4: Too Many SLOs

**Wrong**: 50 SLOs across all services.
**Problem**: Ops overhead, alert fatigue, and diluted attention. If everything is a priority, nothing is.

**Right**: Start with 1–3 SLOs for your most critical user journeys. The payments flow, the authentication flow, the primary search/browse flow. Add more only when the first cohort is operationally mature.

### Anti-Pattern 5: Measuring SLIs From the Wrong Place

**Wrong**: Measuring SLI at the service layer only (availability SLI = service error rate).
**Problem**: Misses DNS failures, CDN failures, load balancer issues, and network problems — all of which users experience as unavailability.

**Right**: Measure primary SLIs from synthetic probes (black box, as covered in Lesson 1.3), with internal service metrics as supplementary diagnostic signals.

---

## The SLO Definition Workshop

Run this workshop with: SRE engineer, product manager, engineering lead, and optionally a customer success or sales representative.

**Duration**: 2–3 hours  
**Outcome**: Documented SLOs for your top 3 user journeys, with stakeholder sign-off

### Step 1: User Journey Mapping (30 min)

List the 5–10 most important things users do in your product. Focus on journeys that directly create or protect business value:

| User Journey | Business Value | Current Reliability (est.) |
|---|---|---|
| User authentication / login | Gateway to all value | ? |
| Product search and browse | Top-of-funnel | ? |
| Checkout and payment | Core revenue | ? |
| Order fulfillment status | Customer trust | ? |
| Account settings and data | Retention | ? |

For each journey, ask: "If this broke completely for 1 hour, what would happen to the business?"

### Step 2: SLI Selection (30 min)

For each priority journey, identify the SLI that best captures user experience. There are four SLI categories:

**Availability SLI**: What fraction of requests succeed?
```
good_events = requests with status_code 2xx or 3xx
total_events = all requests
```

**Latency SLI**: What fraction of requests are fast enough?
```
good_events = requests completing in < 500ms
total_events = all requests
```

**Throughput SLI**: What fraction of expected work gets done?
```
good_events = jobs processed within SLA window
total_events = jobs submitted
```

**Correctness SLI**: What fraction of responses are correct?
```
good_events = responses passing correctness validation
total_events = all responses sampled
```

Most user journeys need 1–2 SLIs. Don't over-engineer — start with the most critical dimension.

### Step 3: Target Setting (45 min)

This is the negotiation. SLO target setting requires historical data and business context:

**Historical baseline**: What has your actual reliability been over the past 90 days? This is your starting point.

**User impact analysis**: At what point do users notice degradation? Research shows:
- Availability < 99.5%: Users notice frequent errors
- P99 latency > 1s: Measurable conversion rate impact
- P99 latency > 3s: Significant abandonment

**Competitive analysis**: What do your direct competitors promise in their SLAs?

**The "what would we do" test**: If the SLO is breached, are we willing to stop feature development and invest in reliability? If the answer is "no," the SLO target isn't high enough to represent a real commitment.

### Step 4: Measurement Window (15 min)

The measurement window affects how much error budget you have:

| SLO | Window | Allowed Downtime |
|---|---|---|
| 99.9% | 30 days | 43.2 min |
| 99.9% | 7 days | 10.1 min |
| 99.5% | 30 days | 3.6 hours |
| 99.5% | 7 days | 50 min |

**Recommendation**: Start with a 30-day rolling window. It's long enough to smooth out normal variance while being short enough to be operationally responsive.

### Step 5: Error Budget Policy (30 min)

The error budget policy converts the SLO into a governance mechanism. As covered in Lesson 0.3:
- > 50% budget: Full velocity
- 20–50%: Enhanced review
- 10–20%: Reliability sprint
- < 10%: Feature freeze

The team must agree on these thresholds *before* the first budget is depleted. Retrospective policy enforcement never works.

---

## Documenting Your SLO

Every SLO should have a standardized document:

```yaml
# SLO: Checkout Service Availability
service: checkout-service
owner: checkout-team
slo_name: checkout_availability
version: 1.2
last_reviewed: 2026-04-01

sli:
  name: availability
  description: "Fraction of checkout requests returning 2xx responses, measured by synthetic probe"
  good_events: "probe_success == 1 AND response_time < 10s"
  total_events: "all synthetic probe executions (every 60s)"
  measurement_source: "Blackbox exporter, 3 geographic probes"

slo:
  target: 99.9%
  window: "30-day rolling"
  allowed_downtime_per_month: "43.2 minutes"

error_budget_policy:
  source: "https://docs.internal/sre/error-budget-policy"
  
stakeholders:
  product: "Sarah Chen, Product Lead - Checkout"
  engineering: "Marcus Rivera, EM - Checkout Team"
  sre: "Alex Kim, SRE Lead"
  
sla_relationship: "Internal SLO. External SLA to enterprise customers is 99.5%."

review_cadence: "Quarterly SLO review, monthly error budget check-in"
```

---

## Key Takeaways

**1. SLIs measure user experience, not system internals.** CPU, memory, and process restarts are not SLIs. Request success rate, latency percentiles, and job completion rate are.

**2. SLO targets must be negotiated, not declared.** An SLO without stakeholder agreement is a monitoring threshold, not a reliability commitment.

**3. Measure from where users are, not from inside your service.** Synthetic probes (black box) give you the most honest SLI measurement.

**4. Start with 3 SLOs, not 30.** Operational maturity with a small number of well-defined SLOs beats a sprawling set of unmaintained targets.

**5. The error budget policy is inseparable from the SLO.** A target without a governance mechanism is aspirational, not operational.

---

*The next lesson dives into the statistics behind latency SLIs — why averages lie, how to interpret percentile distributions, and how to choose the right latency target for your users.*
