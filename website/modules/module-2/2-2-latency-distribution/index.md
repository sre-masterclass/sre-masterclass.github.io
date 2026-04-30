---
layout: lesson
title: "Latency Distribution & Statistical Analysis"
description: "Understand why averages lie and percentiles tell the truth. Master latency distribution analysis, the statistics behind percentile SLIs, and how to choose the right latency targets for your users."
module_number: 2
module_id: module-2
module_slug: module-2
module_title: "SLO/SLI Mastery"
module_icon: "🎯"
module_color: "#10b981"
lesson_number: 2
lesson_id: "2-2"
reading_time: 18
difficulty: "Intermediate"
tools_count: 1
objectives:
  - "Explain mathematically why average latency is a misleading SLI for user experience"
  - "Interpret latency histograms and identify distribution shapes that indicate specific problems"
  - "Choose appropriate latency percentile targets (P90, P95, P99) based on your user base size"
  - "Implement histogram-based latency SLIs that are accurate and aggregatable"
prev_lesson: /modules/module-2/2-1-slo-definition/
prev_title: "SLO Definition Workshop"
next_lesson: /modules/module-2/2-3-sli-implementation/
next_title: "SLI Implementation Patterns"
---

## Why Your Average Latency Is Lying to You

Consider a web service with the following response times for 100 requests:
- 98 requests complete in 100ms
- 2 requests complete in 30,000ms (30 seconds — a database timeout)

**Average latency**: `(98 × 100ms + 2 × 30,000ms) / 100 = 697ms`

Your average latency dashboard shows 697ms — indicating moderate performance. But 98% of users experienced 100ms response times while 2% experienced 30-second timeouts. The average hides both the good news (most users are fine) and the bad news (some users are experiencing catastrophic failures).

> **The fundamental problem with averages**: They combine all experiences into a single number that accurately represents nobody's experience. In a bimodal distribution (fast requests + slow timeouts), the average falls between the peaks — a value that no actual request had.

---

## Understanding Latency Distributions

### The Normal Distribution Assumption (That Is Usually Wrong)

Average-based thinking assumes a roughly normal (bell curve) distribution where most values cluster around the mean and outliers are rare. Network and application latency distributions almost never look like this.

Real latency distributions are typically:

**Right-skewed (long tail)**: Most requests are fast, but there's a tail of slow requests. This is the most common pattern. The P99 and P100 (maximum) are dramatically higher than the P50 (median).

**Bimodal**: Two distinct populations — fast requests and slow requests. Often indicates two code paths with very different performance characteristics, or cache hits vs. misses.

**Multimodal**: Multiple distinct populations. Often indicates retries (first attempt fast, retry with backoff much slower), or requests that hit different backends with different performance characteristics.

### Reading Latency Histograms

A latency histogram divides the latency range into buckets and shows how many requests fell into each bucket:

```
Latency   Count  %      Histogram
0-100ms:  8,450  84.5%  ████████████████████████████████████
100-200ms: 820    8.2%  ████
200-500ms: 380    3.8%  ██
500ms-1s:  200    2.0%  █
1s-5s:     130    1.3%  █
5s-30s:    20     0.2%  
> 30s:      0     0.0%  
```

**What this tells you**: The distribution is right-skewed. 84.5% of requests complete in under 100ms, but there's a tail. The P95 is approximately 500ms, the P99 is approximately 2–3 seconds.

### Key Percentile Definitions

| Percentile | Meaning |
|---|---|
| P50 (median) | 50% of requests are faster than this |
| P90 | 90% of requests are faster; 10% are slower |
| P95 | 95% of requests are faster; 5% are slower |
| P99 | 99% of requests are faster; 1% are slower |
| P99.9 | 99.9% of requests are faster; 0.1% are slower |

---

## Choosing the Right Percentile for Your SLO

The percentile you choose for your latency SLO determines whose experience you're protecting.

### The User Population Math

If your service handles 100,000 requests per day:

| SLO Percentile | Users with slow experience |
|---|---|
| P90 | 10,000 users/day |
| P95 | 5,000 users/day |
| P99 | 1,000 users/day |
| P99.9 | 100 users/day |
| P99.99 | 10 users/day |

**For a high-traffic service**, even P99 represents thousands of bad experiences per day. P90 means tens of thousands of users hit slow requests daily.

**For a low-traffic service** (1,000 requests/day), P99 means 10 requests/day miss your target — probably acceptable. P99.9 means 1 request/day — might be too strict to be operationally meaningful.

### Practical Percentile Selection Guidelines

**P50/P75 SLOs**: Appropriate for batch processing, background jobs, or internal tools where a minority of slow operations is acceptable. Rarely appropriate for user-facing services.

**P90 SLOs**: Good starting point for internal APIs or services used by technical users who understand system behavior. Also useful as a "fast enough" baseline before you have good P99 data.

**P95 SLOs**: Appropriate for most user-facing web services as a primary SLO. Catches the most meaningful performance degradation while being operationally achievable.

**P99 SLOs**: Required for high-transaction-volume services where the "1 in 100" experience affects large absolute numbers of users. Also appropriate for payment and authentication flows where even rare failures have high business impact.

**P99.9 SLOs**: Reserved for critical financial transactions, healthcare, or services where any user experiencing a slow response has disproportionate impact. Very expensive to maintain — use sparingly.

> **Recommendation**: Implement both P95 and P99 latency SLOs for user-facing services. The P95 catches systemic degradation early. The P99 catches the tail that the P95 might miss.

---

## The Statistics Behind Histogram Quantiles

When you compute `histogram_quantile(0.99, ...)` in Prometheus, it's doing linear interpolation within histogram buckets. Understanding this process helps you design accurate SLIs.

### How Prometheus Computes Quantiles

Prometheus histograms don't store individual observations — they store bucket counts. To compute P99, Prometheus:

1. Finds the total observation count
2. Calculates the target rank: `0.99 × total`
3. Finds which bucket the target rank falls in
4. Linearly interpolates within that bucket

**The accuracy implication**: Quantile accuracy is determined by bucket granularity around the target percentile. If your P99 typically falls between 400ms and 500ms but your nearest buckets are 200ms and 1000ms, your P99 estimate could be off by hundreds of milliseconds.

### Bucket Design for Accuracy

```python
# Histograms for a service with P99 ≈ 300ms
# and an SLO of P99 < 500ms

from prometheus_client import Histogram

# Poor bucket design — buckets too coarse around the SLO target
bad_latency = Histogram('latency_bad', 'Coarse buckets',
    buckets=[0.1, 0.5, 1.0, 5.0, 10.0])
# P99 estimate will be inaccurate — SLO target 0.5s is a bucket boundary
# which is ok, but everything between 0.1s and 0.5s is lumped together

# Good bucket design — fine-grained around expected P99 range
good_latency = Histogram('latency_good', 'Fine-grained buckets',
    buckets=[
        0.010, 0.025, 0.050, 0.075, 0.100,  # 10ms - 100ms
        0.150, 0.200, 0.250, 0.300, 0.400,  # 100ms - 400ms
        0.500, 0.750, 1.0, 2.5, 5.0, 10.0  # 500ms - 10s
    ])
# Fine granularity around the 100-500ms range where P99 likely falls
```

**Rule of thumb**: Have at least 2–3 bucket boundaries within the range where you expect your SLO target to fall. The more buckets in the target range, the more accurate your percentile estimate.

---

## The Interactive Latency Distribution Analyzer

The best way to develop intuition for latency distributions is to manipulate them interactively. The tool below lets you:

- Switch between traffic scenarios (normal operation, cache miss storm, database slowdown, partial failure)
- See how the distribution shape changes
- Observe how P50, P95, and P99 diverge as tail events increase
- Compare average vs. percentile behavior

{% include tool-embed.html
   title="Latency Distribution Analyzer"
   src="/tools/latency-distribution-analyzer.html"
   description="Explore latency distributions interactively. Switch between traffic scenarios and observe how distribution shape affects average vs. percentile behavior. See why P99 catches problems that P50 misses."
   height="700"
%}

---

## Common Latency Distribution Patterns and What They Mean

### Pattern 1: Healthy Unimodal Distribution

Most requests in a tight band (P50–P95 spread < 3×), with a moderate tail.

**Interpretation**: Healthy service. Normal variance. P99 is elevated but not alarming.
**Action**: Set P95 and P99 SLOs based on this baseline.

### Pattern 2: Bimodal — Cache Hit / Miss

Two distinct peaks: one at 10–50ms (cache hits), one at 200–500ms (cache misses).

**Interpretation**: Expected behavior for cached services. The "slow" peak is not a problem unless the ratio of slow requests increases.
**Action**: Track cache hit rate as a leading indicator. Alert on cache miss ratio increase, not on raw P99.

### Pattern 3: Heavy Tail — Database Timeouts

Normal distribution below 200ms, but a long tail extending to 30s+. The tail is sparse but present.

**Interpretation**: Periodic database timeout storms. Could be lock contention, slow queries, or connection pool exhaustion.
**Action**: Alert on P99 > 2s. Add database query latency histograms to identify the slow query. This is a leading indicator for SLO breach.

### Pattern 4: Stepped Distribution — Retries

Multiple small humps at regular intervals (e.g., 100ms, 300ms, 700ms with exponential backoff).

**Interpretation**: Your service (or a downstream dependency) is retrying requests. Each hump represents requests that failed N times and succeeded on attempt N+1.
**Action**: Track retry rate as a separate metric. High retry rates indicate intermittent failures that percentile-based SLIs may partially mask.

---

## Latency SLI Implementation

### The Count-Based Approach (Recommended)

Rather than measuring "P99 latency," define your latency SLI as a ratio:

```
Latency SLI = requests_faster_than_threshold / total_requests
```

This is consistent with the SLI = good_events/total_events formulation and is directly usable as an error budget metric:

```prometheus
# Latency SLI: fraction of requests completing under 500ms
# Good events: requests under 500ms
# Total events: all requests

# Prometheus — using histogram buckets
sli_latency_good = sum(rate(
    http_request_duration_seconds_bucket{le="0.5"}[5m]
))

sli_latency_total = sum(rate(
    http_request_duration_seconds_count[5m]
))

latency_sli = sli_latency_good / sli_latency_total
```

This formulation:
- Is directly consumable by error budget calculations
- Composes cleanly with availability SLIs (a request that's slow AND fails counts as a bad event once)
- Works correctly when aggregated across multiple service instances

---

## Key Takeaways

**1. Averages hide the most important stories.** A bimodal distribution with 95% fast requests and 5% timeouts will have a "decent" average that masks the timeout storm.

**2. Percentile choice is a business decision.** P99 for payments (where 1 in 100 slow transactions matters). P95 for search (where occasional slow results are acceptable). Match the percentile to the user impact at that percentile.

**3. Bucket design determines percentile accuracy.** Your SLO target must fall within your bucket boundaries. Design buckets around your expected P95–P99 range.

**4. Express latency SLIs as ratios, not percentile thresholds.** `requests_under_500ms / total_requests` is measurable, composable, and directly usable in error budget calculations. Raw P99 values are diagnostic, not SLI-appropriate.

**5. Distribution shapes diagnose root causes.** Bimodal = cache hit/miss. Stepped = retries. Heavy tail = periodic dependency failures. Learn to read the shape, not just the number.

---

*The next lesson implements all four SLI categories — availability, latency, throughput, and correctness — across multiple monitoring platforms and shows you how to choose between metric-based and log-based measurement approaches.*
