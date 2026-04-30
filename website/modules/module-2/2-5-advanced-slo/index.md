---
layout: lesson
title: "Advanced SLO Patterns"
description: "Go beyond basic availability SLOs with windowed SLOs, multi-dimensional reliability, user-segment SLOs, and techniques for services that don't fit the standard request/response model."
module_number: 2
module_id: module-2
module_slug: module-2
module_title: "SLO/SLI Mastery"
module_icon: "🎯"
module_color: "#10b981"
lesson_number: 5
lesson_id: "2-5"
reading_time: 18
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Implement windowed SLOs using rolling and calendar-based measurement strategies"
  - "Design multi-dimensional SLOs for complex user journeys with multiple success criteria"
  - "Build user-segment SLOs that differentiate reliability commitments by customer tier"
  - "Handle SLO design for non-request services (streaming, batch, messaging)"
prev_lesson: /modules/module-2/2-4-error-budget/
prev_title: "Error Budget Mathematics & Burn Rate"
next_lesson: /modules/module-2/2-6-alerting-strategy/
next_title: "Alerting Strategy & Burn Rate Implementation"
---

## When Basic SLOs Aren't Enough

The SLO patterns in Lessons 2.1–2.4 handle the majority of use cases. But real services present complications:

- A checkout service needs to meet different SLOs for free users vs. enterprise customers
- A data pipeline has no "requests" — it processes hourly batches
- A streaming service needs SLOs for both video start time AND sustained playback quality
- A database needs separate SLOs for reads vs. writes vs. background jobs

This lesson covers the advanced patterns for these situations.

---

## Pattern 1: Rolling vs. Calendar Windows

### Rolling Windows (Recommended Default)

A 30-day rolling window measures the last 30 days from the current moment. This is the default recommendation because:
- Constantly fresh — reflects recent system behavior
- No "end of month cliff" where everyone rushes to restore budget
- Provides consistent operational pressure throughout the month

**Prometheus implementation**:
```prometheus
# 30-day rolling availability SLI
1 - (
  sum_over_time((1 - slo:availability_sli:5m)[30d:5m]) 
  / count_over_time(slo:availability_sli:5m[30d])
)
```

### Calendar Windows

Some organizations prefer calendar-month windows aligned with billing and reporting cycles. Trade-offs:
- Aligns with business reporting
- Teams know exactly when their budget resets
- Risk: end-of-month pressure creates gaming behavior ("this incident happened on the 29th — we'll just wait for the reset")

### Multi-Window Strategy

For enterprise SLAs, use both:
- **Operational SLO**: 7-day rolling window (fast feedback for engineering)
- **Business SLO**: 30-day rolling window (for stakeholder reporting)
- **SLA**: Calendar month (for customer commitments)

---

## Pattern 2: Multi-Dimensional SLOs

A single SLI can't capture the full complexity of some user journeys. Multi-dimensional SLOs measure reliability across several axes simultaneously.

### The Checkout Multi-Dimensional SLO

```yaml
# Checkout SLO: three dimensions must all be met
dimensions:
  availability:
    sli: "successful_checkouts / attempted_checkouts"
    target: 99.9%
    
  latency:
    sli: "checkouts_under_3s / total_checkouts"
    target: 95%
    
  correctness:
    sli: "orders_with_correct_pricing / total_orders_placed"
    target: 99.99%
```

**Composite error budget**: Each dimension has its own error budget. The overall SLO is met only when all dimensions are within their targets.

**Alert routing**: Different dimensions trigger different responses:
- Availability breach → page on-call immediately
- Latency degradation → team Slack + create reliability sprint ticket
- Correctness violation → immediate P0 incident + executive notification (financial/legal risk)

### Joint SLIs

For journeys where multiple dimensions must succeed together:
```prometheus
# "Good checkout" = available AND fast AND correct
# Bad event if ANY dimension fails
good_checkouts = checkouts where:
  - status_code = 200
  - AND response_time < 3s
  - AND order_created_correctly = true

checkout_joint_sli = good_checkouts / total_checkouts
```

The joint SLI is more conservative than individual SLIs — it catches cases where multiple soft failures combine into a bad user experience.

---

## Pattern 3: User-Segment SLOs

Not all users are equal from a business perspective. Enterprise customers paying $100K/year deserve different reliability commitments than free-tier users.

### Tiered SLO Architecture

```yaml
# Enterprise tier: 99.95% availability
# Professional tier: 99.9% availability
# Free tier: 99.5% availability
```

**Implementation challenge**: You need to segment traffic by user tier in your SLI measurement:

```prometheus
# Availability SLI per customer tier
# Requires user_tier label in your request metrics

# Enterprise tier SLI
sum(rate(http_requests_total{status_code!~"5..", user_tier="enterprise"}[5m]))
  / sum(rate(http_requests_total{user_tier="enterprise"}[5m]))

# Free tier SLI
sum(rate(http_requests_total{status_code!~"5..", user_tier="free"}[5m]))
  / sum(rate(http_requests_total{user_tier="free"}[5m]))
```

**Cardinality warning**: If you have many tiers or if tier is high-cardinality, segment at the application layer rather than as a Prometheus label dimension.

### Degradation Ordering

When system capacity is constrained and you must shed load, tiered SLOs provide clear guidance:
1. Degrade free-tier features first
2. Protect professional-tier core functionality
3. Never degrade enterprise-tier critical paths

This degradation ordering should be documented in your runbooks and implemented as rate limiting / feature flags.

---

## Pattern 4: SLOs for Non-Request Services

### Batch Processing SLOs

Batch jobs don't have "requests" — they process data in runs. The SLI is completion quality, not request success rate:

```yaml
# Batch job SLO: daily ETL pipeline
sli:
  name: etl_completion_quality
  good_run: >
    run completed successfully
    AND completed within 2-hour SLA window
    AND output row count within 5% of expected
  total_runs: all scheduled runs

slo:
  target: 99.5% of runs meeting good_run criteria
  window: 30 days
```

**Prometheus recording rule for batch SLOs**:
```prometheus
# Track each batch run as a binary good/bad event
# good_run_count and total_run_count are counters incremented by the batch job itself
record: slo:etl_pipeline:completion_rate
expr: >
  rate(batch_job_completions_total{status="success", within_sla="true"}[30d])
  / rate(batch_job_runs_total[30d])
```

### Message Queue SLOs

For message-processing systems, the SLI is processing latency and processing success rate:

```yaml
sli_1:
  name: message_processing_latency
  good_events: "messages processed within 5s of receipt"
  total_events: "all messages received"
  
sli_2:
  name: message_processing_success
  good_events: "messages processed without permanent failure"
  total_events: "all messages received"
```

**Important distinction**: Messages that fail and are retried aren't "bad" events if they eventually succeed within the latency SLO. Messages that hit the dead letter queue are definitely bad events.

### Streaming Media SLOs

Video streaming needs multi-stage SLOs:

```yaml
# Stage 1: Initial buffering (user tolerance: < 2s)
stream_start_slo:
  sli: "streams_started_under_2s / total_stream_attempts"
  target: 95%

# Stage 2: Playback quality (user tolerance: < 1% rebuffering ratio)
playback_quality_slo:
  sli: "sessions_under_1pct_rebuffering / total_active_sessions"  
  target: 99%
```

---

## Pattern 5: Dependency-Aware SLOs

Your service's SLO is limited by the SLOs of its dependencies. A service dependent on a database with 99.9% availability cannot itself offer 99.99% availability — the math doesn't work.

### Theoretical Maximum SLO

```
theoretical_max_availability = 
  product(dependency_availabilities)

Example:
  Database: 99.9%
  Cache: 99.95%
  Payment processor: 99.8%
  
  Theoretical max = 0.999 × 0.9995 × 0.998 = 99.65%
```

This assumes all dependencies are on the critical path. If dependencies are optional (graceful degradation), the calculation is more favorable.

**Use this calculation when**:
- Setting initial SLO targets (don't commit to more than the math allows)
- Making the case for dependency SLA improvements
- Evaluating whether to implement graceful degradation for non-critical dependencies

{% include diagram-embed.html
   title="Dependency Chain SLO Budget Analysis"
   src="/modules/module-2/2-5-visuals/diagrams/dependency-chain-slo-budget.html"
   height="460"
%}

---

## Key Takeaways

**1. Rolling windows provide consistent operational pressure.** They're fresher and prevent end-of-period budget gaming.

**2. Multi-dimensional SLOs capture real user experience complexity.** A checkout that's available but slow and incorrect isn't meeting user needs.

**3. Tiered SLOs align reliability investment with business value.** Protect enterprise customers first; use degradation ordering during capacity constraints.

**4. Batch and streaming services need SLOs tailored to their model.** Forcing request-response SLO patterns onto batch jobs produces meaningless metrics.

**5. Your SLO can't exceed your dependency SLOs.** Know the math before committing to your targets, and use it as leverage to improve dependency reliability.

---

*The next lesson covers alerting strategy — translating all the SLO, SLI, and burn rate work into an alerting architecture that wakes up the right person at the right time without creating alert fatigue.*
