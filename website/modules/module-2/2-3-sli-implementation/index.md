---
layout: lesson
title: "SLI Implementation Patterns"
description: "Implement the four SLI categories across Prometheus, Loki, and APM platforms. Choose between metric-based and log-based measurement approaches and build composite SLIs for complex user journeys."
module_number: 2
module_id: module-2
module_slug: module-2
module_title: "SLO/SLI Mastery"
module_icon: "🎯"
module_color: "#10b981"
lesson_number: 3
lesson_id: "2-3"
reading_time: 20
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Implement availability, latency, throughput, and correctness SLIs in Prometheus"
  - "Choose between metric-based and log-based SLI measurement based on data availability"
  - "Build composite SLIs that combine multiple signals for complex user journeys"
  - "Validate SLI measurement accuracy before committing to an SLO target"
prev_lesson: /modules/module-2/2-2-latency-distribution/
prev_title: "Latency Distribution & Statistical Analysis"
next_lesson: /modules/module-2/2-4-error-budget/
next_title: "Error Budget Mathematics & Burn Rate"
---

## The Four SLI Categories

Every user-facing service can be measured across four dimensions. Not every service needs all four — choose the SLIs that map to what users actually care about.

### Category 1: Availability SLI

**What it measures**: The fraction of time the service successfully processes requests.

**Prometheus implementation**:
```prometheus
# Good events: non-5xx responses
sum(rate(http_requests_total{status_code!~"5.."}[5m]))

# Total events: all requests
sum(rate(http_requests_total[5m]))

# SLI value
sum(rate(http_requests_total{status_code!~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))
```

**Edge cases to handle**:
- 429 (rate limiting): Usually counts as **bad** event — user couldn't complete their action
- 400 (bad request): Usually counts as **good** event — server worked correctly, request was invalid
- 503 during planned maintenance: Exclude with an annotation or downtime window

**Synthetic probe SLI** (preferred for user-facing availability):
```prometheus
# Blackbox exporter — 1 = probe succeeded, 0 = probe failed
avg_over_time(probe_success{job="synthetic-checkout"}[30d])
```

### Category 2: Latency SLI

**What it measures**: The fraction of requests completing within the target threshold.

```prometheus
# Latency SLI: requests completing within 500ms threshold
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
  / sum(rate(http_request_duration_seconds_count[5m]))
```

**Multi-threshold latency SLIs**: For services with tiered latency targets, compute separate SLIs:
```prometheus
# "Good" = fast (< 200ms)
# "Acceptable" = 200ms-500ms
# "Bad" = > 500ms

# Single SLI using the 500ms threshold
latency_sli = requests_under_500ms / total_requests
```

### Category 3: Throughput SLI

**What it measures**: The fraction of work units successfully processed within a time window.

Throughput SLIs apply to batch processing, message queues, and job systems:

```prometheus
# Good events: jobs completed successfully within the SLA window
rate(jobs_completed_total{status="success"}[5m])

# Total events: jobs submitted (using a gauge for the queue depth is wrong —
# use a counter for submitted jobs)
rate(jobs_submitted_total[5m])

# SLI
rate(jobs_completed_total{status="success"}[5m])
  / rate(jobs_submitted_total[5m])
```

**The queue-depth anti-pattern**: Queue depth is NOT an SLI — it's a leading indicator. The SLI is completion rate. Alert on rising queue depth as a leading indicator of SLI degradation.

### Category 4: Correctness SLI

**What it measures**: The fraction of responses that are semantically correct (not just HTTP 200).

This is the hardest SLI to implement because it requires defining and checking "correctness":

```python
# Example: correctness check via synthetic transactions
# The SLI is measured by probes that verify business logic

def checkout_correctness_probe():
    """
    Returns 1.0 if checkout creates correct order, 0.0 otherwise
    """
    test_order = create_test_order(items=[{"sku": "TEST-SKU-001", "qty": 1}])
    response = checkout_service.submit(test_order)
    
    if response.status_code != 200:
        return 0.0
    
    order_id = response.json()["order_id"]
    
    # Verify the order appears in the order management system
    time.sleep(2)
    order = order_management.get_order(order_id)
    
    if order is None:
        return 0.0  # Order not created despite 200 response
    
    if order["total"] != test_order.expected_total:
        return 0.0  # Incorrect pricing
    
    return 1.0
```

---

## Metric-Based vs. Log-Based SLI Measurement

Two approaches for collecting the raw data that feeds your SLI calculations.

### Metric-Based SLIs

**How it works**: Instrument your service to emit counters and histograms. Compute SLIs directly from Prometheus metrics.

**Advantages**:
- Low overhead — metrics are sampled and aggregated
- Real-time — dashboards and alerts update on the scrape interval
- Works without changing query logic — just change the PromQL

**Disadvantages**:
- Requires instrumentation changes to capture new dimensions
- Limited to data you thought to instrument
- No retroactive analysis — you can't re-run metrics from logs

**Best for**: Services where you control the code and have complete instrumentation.

### Log-Based SLIs

**How it works**: Parse structured logs to extract request outcomes and latencies. Use Loki or Elasticsearch to run SLI queries.

```logql
# Loki query: availability SLI from access logs
sum(rate({job="nginx-access-log"} | json | status !~ "5.." [5m]))
  / sum(rate({job="nginx-access-log"} [5m]))
```

**Advantages**:
- Retroactive analysis — can recalculate SLIs from historical logs
- Richer context — logs contain fields that metrics don't
- No instrumentation changes required — works from existing log output
- Better for correctness SLIs where semantic meaning is in log content

**Disadvantages**:
- Higher overhead — log parsing is expensive at scale
- Query latency — log-based SLIs have higher computation time
- Log shipping reliability — SLI accuracy depends on log delivery

**Best for**: Third-party services where you can't add instrumentation, or when you need retroactive SLI analysis.

### The Hybrid Approach

Use metric-based SLIs for real-time alerting (low latency, low cost) and log-based SLIs for forensic analysis and SLA reporting (high fidelity, retroactive).

---

## Composite SLIs

Many user journeys span multiple services. A checkout that is "available" requires the frontend, cart service, payment service, and order service all working correctly. A composite SLI combines multiple individual SLIs into a single user-journey SLI.

### Composite SLI Design

```
checkout_availability_sli = 
  min(
    frontend_availability_sli,
    cart_service_availability_sli, 
    payment_service_availability_sli,
    order_service_availability_sli
  )
```

**Why `min()`, not multiplication or average?**
- The checkout journey fails if **any** component fails
- `min()` correctly represents the "weakest link" semantics
- Multiplication would compound small probabilities in misleading ways (99.9% × 99.9% × 99.9% × 99.9% = 99.6% — but you'd only breach the composite SLI if any ONE component was at the worst of its SLI values)

Actually, the most accurate composite SLI is:
```prometheus
# A checkout request is "good" if it succeeded end-to-end
# Measure from the user's perspective (synthetic probe), not from individual services
checkout_e2e_sli = probe_success / total_probes
```

The end-to-end synthetic probe composite is more honest than combining individual service SLIs.

{% include tool-embed.html
   title="SLI Implementation Comparison Tool"
   src="/tools/sli-implementation-comparison-tool.html"
   description="Compare metric-based vs. log-based SLI implementations side-by-side. See how different measurement approaches produce different SLI values for the same underlying events. Explore composite SLI design patterns."
   height="700"
%}

---

## SLI Validation: Before You Commit to an SLO

Before publishing an SLO based on an SLI, validate that the SLI accurately measures what you intend:

### The Five Validation Tests

**1. Incident replay test**: Take a known past incident. Does the SLI show the impact during that window? If a major outage doesn't show as an SLI dip, the SLI is measuring the wrong thing.

**2. False positive test**: Find a period of healthy operation. Does the SLI stay consistently near 100%? If it shows frequent small dips during normal operation, you have measurement noise or a metric classification problem.

**3. Customer correlation test**: Compare SLI dips with customer support ticket volume. Do they correlate? If tickets spike but SLI is healthy (or vice versa), the SLI doesn't represent customer experience.

**4. Aggregation test**: Does the SLI behave correctly when aggregated? Verify that the SLI across multiple service instances equals what you'd expect from combining them.

**5. Saturation test**: What happens to the SLI under extreme load? Some SLI implementations return artificially high values when traffic drops (denominator shrinks) — validate boundary behavior.

---

## Key Takeaways

**1. Match the SLI category to user expectations.** Availability for "can I use it?", latency for "is it fast enough?", throughput for "does my batch job complete?", correctness for "does it give me the right answer?"

**2. Express all SLIs as ratios.** `good_events / total_events` — consistent, composable, directly usable in error budget math.

**3. Log-based SLIs enable retroactive analysis; metric-based SLIs enable real-time alerting.** Use both where possible.

**4. Composite SLIs should use end-to-end synthetic probes, not min() of components.** Individual component SLIs don't account for the interactions between components.

**5. Validate before committing.** An SLI that doesn't correlate with customer experience during past incidents will produce error budgets nobody trusts.

---

*The next lesson covers the mathematics of error budgets and burn rates — how to calculate exactly how fast you're consuming your reliability budget and what burn rate thresholds trigger different responses.*
