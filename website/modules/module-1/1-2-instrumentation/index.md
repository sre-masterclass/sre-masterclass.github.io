---
layout: lesson
title: "Instrumentation Strategy & Implementation"
description: "Design and implement production-grade instrumentation — from deep vs shallow trade-offs to cardinality management and the four types of metrics every SRE relies on."
module_number: 1
module_id: module-1
module_slug: module-1
module_title: "Foundations of Monitoring"
module_icon: "📡"
module_color: "#0ea5e9"
lesson_number: 2
lesson_id: "1-2"
reading_time: 22
difficulty: "Intermediate"
tools_count: 2
objectives:
  - "Choose between deep and shallow instrumentation strategies based on service criticality and team capacity"
  - "Implement all four Prometheus metric types correctly with appropriate labeling"
  - "Manage cardinality to prevent metric explosion while preserving analytical power"
  - "Build instrumentation requirements into the development workflow"
prev_lesson: /modules/module-1/1-1-monitoring-taxonomies/
prev_title: "Monitoring Taxonomies Deep Dive"
next_lesson: /modules/module-1/1-3-black-box-vs-white-box/
next_title: "Black Box vs White Box Monitoring"
---

## The Gap Between Having Metrics and Having Observability

Most engineering teams have metrics. They have dashboards, they have Prometheus running, they have Grafana panels. But they still get surprised by production incidents that their monitoring "should have caught."

The gap isn't usually a missing tool — it's an instrumentation strategy problem. This lesson covers how to think about instrumentation as a discipline, not an afterthought.

> **The core distinction**: Instrumentation for debugging tells you *what happened*. Instrumentation for SRE tells you *when something matters to users* and *how much reliability budget you've consumed*. These are different questions that often require different signals.

---

## Deep vs. Shallow Instrumentation

The fundamental trade-off in instrumentation design is the depth vs. coverage balance.

### Shallow Instrumentation

A thin layer of standardized metrics applied uniformly across all services. Typically implemented through middleware, service mesh proxies (Envoy, Linkerd), or APM agents rather than code-level instrumentation.

**What you get:**
- Consistent RED signals (Rate, Errors, Duration) for every service endpoint
- Low implementation cost — often zero code changes per service
- Uniform labeling that enables cross-service comparison
- Automatic coverage for new services

**What you miss:**
- Business logic signals (did the transaction succeed, not just did the HTTP call complete?)
- Internal component performance (is the slow request hitting the database or the cache?)
- Custom error categorization (timeouts vs. validation errors vs. authentication failures)
- Domain-specific health signals

**Best for:** Services that don't have SLOs, internal utility services, third-party services you don't control.

### Deep Instrumentation

Custom metrics added at the application code level, instrumenting business logic, internal components, and domain-specific states.

**What you get:**
- Business transaction success/failure tracking
- Granular performance breakdown (per-query latency, per-cache-operation hit rate)
- Custom error categorization aligned with SLO definitions
- Domain signals (payment processing time, checkout funnel conversion, job queue depth)

**What you invest:**
- Development time for each service
- Maintenance burden as code changes
- Potential performance overhead if implemented carelessly
- Cardinality risk if label dimensions are too broad

**Best for:** Services with user-facing SLOs, high-value business critical paths, services causing frequent incidents.

### The Instrumentation Decision Matrix

Use this framework to decide how deeply to instrument each service:

| Factor | Shallow | Deep |
|---|---|---|
| Has user-facing SLO | ❌ | ✅ |
| Frequent source of incidents | ❌ | ✅ |
| Business-critical transaction | ❌ | ✅ |
| Internal utility service | ✅ | ❌ |
| Team capacity available | N/A | Required |
| Service changes frequently | Preferred | Costly |

---

## The Four Prometheus Metric Types

Prometheus's four metric types are not interchangeable. Using the wrong type creates misleading data and broken dashboards.

### Counter

A monotonically increasing value that only resets on process restart. **Never use for values that can decrease.**

```python
# Python — using prometheus_client
from prometheus_client import Counter

http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests received',
    ['method', 'path', 'status_code']  # Label dimensions
)

# In request handler:
http_requests_total.labels(
    method=request.method,
    path=request.path,
    status_code=response.status_code
).inc()
```

**Always query counters with `rate()` or `increase()`** to convert cumulative values to rates:
```prometheus
rate(http_requests_total{status_code="200"}[5m])
```

**Use for:** Request counts, error counts, bytes transferred, events processed.

### Gauge

A value that can increase and decrease freely. A snapshot of a current state.

```python
from prometheus_client import Gauge

active_connections = Gauge(
    'db_connections_active',
    'Number of active database connections'
)

# Set directly or use context manager
active_connections.set(connection_pool.size())

# Or with automatic tracking:
with active_connections.track_inprogress():
    result = execute_query(sql)
```

**Query gauges directly** — no `rate()` needed:
```prometheus
db_connections_active / db_connections_max
```

**Use for:** Queue depth, memory usage, active connections, in-progress requests, temperature readings.

### Histogram

Samples observations into configurable buckets, enabling percentile calculations. Essential for latency SLIs.

```python
from prometheus_client import Histogram

request_latency = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency in seconds',
    ['method', 'path'],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
)

@request_latency.time()
def handle_request(request):
    return process(request)
```

**The critical detail — bucket selection**: Your SLO target must fall within your bucket boundaries. If your latency SLO is "P99 < 500ms," you need a bucket at `0.5` (or close to it). Missing this means inaccurate percentile calculations.

```prometheus
# P99 latency across all endpoints
histogram_quantile(0.99, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

**Use for:** Request latency, response sizes, batch processing duration — any value where you need percentile analysis.

### Summary

Pre-computed quantiles calculated on the client side. Accurate for individual service instances but cannot be aggregated across multiple instances.

**Avoid summaries in microservice architectures.** Use histograms instead — they're aggregatable across instances and allow you to compute percentiles server-side with flexible time windows.

**Legitimate use case for summaries:** Single-instance processes (batch jobs, standalone workers) where you need very precise percentiles without the bucket granularity constraint.

---

## Cardinality: The Silent Monitoring Killer

Cardinality is the number of unique time series created by your metric labels. High cardinality is the most common cause of Prometheus performance problems and is often what makes teams abandon self-hosted monitoring.

### How Cardinality Compounds

Each label you add multiplies your time series count:
```
http_requests_total with labels {method, path, status_code}

Methods: GET, POST, PUT, DELETE = 4
Paths: if you have 50 API endpoints = 50  
Status codes: 200, 201, 400, 401, 403, 404, 500, 502, 503 = ~9

Total: 4 × 50 × 9 = 1,800 time series for ONE metric
```

That's manageable. But if you make the mistake of including high-cardinality values as labels:

```
# NEVER DO THIS — user ID as a label
http_requests_total{user_id="12345", ...}

# With 1 million users: 1,000,000 × 50 × 9 = 450 MILLION time series
# This will destroy your Prometheus instance
```

### High-Cardinality Label Anti-Patterns

Never use these as metric labels:
- User IDs, session IDs, customer IDs
- Request IDs, trace IDs
- Email addresses, usernames
- IP addresses (large networks)
- Arbitrary string values from user input
- Timestamps embedded in labels

### The Right Approach for High-Cardinality Data

High-cardinality data belongs in **logs and traces**, not metrics:
- Use structured logging with correlation IDs for per-request debugging
- Use distributed tracing (Jaeger, Zipkin) for per-request latency breakdown
- Use metrics for **aggregate statistical behavior** — not per-entity tracking

When you need to understand behavior for a specific customer or user, join your metrics (aggregates) with your logs (details) during investigation.

{% include tool-embed.html
   title="Cardinality Calculator & Simulator"
   src="/modules/module-1/1-2-interactive/cardinality-simulator.html"
   description="Simulate the cardinality impact of different labeling strategies. See how label dimensions compound and identify high-cardinality anti-patterns in your metric design."
   height="660"
%}

---

## Naming Conventions

Inconsistent metric naming is a silent productivity killer. Adopt these conventions across your organization:

**Pattern:** `{namespace}_{subsystem}_{name}_{unit}`

```
# Good
http_request_duration_seconds
db_connection_pool_active_connections_total  
cache_hit_ratio                              
payment_processing_errors_total

# Bad — inconsistent units, vague names
requestTime
db_connections
cacheHits
errors
```

**Rules:**
1. Use snake_case, never camelCase
2. Include the unit as the final word (`_seconds`, `_bytes`, `_total`)
3. Counters always end in `_total`
4. No abbreviations — clarity beats brevity
5. Prefix with service name to avoid collision: `checkout_service_` or `auth_`

---

## Instrumentation Checklist for Production Services

Before a service goes to production (or as part of a reliability review):

**HTTP services:**
- [ ] `http_requests_total` counter with `{method, path, status_code}` labels
- [ ] `http_request_duration_seconds` histogram with SLO-aligned buckets
- [ ] Health endpoints: `/health/live`, `/health/ready`
- [ ] Version info gauge: `service_info{version, commit}`

**Database connections:**
- [ ] Active connection count gauge
- [ ] Connection pool utilization gauge (active / max)
- [ ] Query duration histogram
- [ ] Slow query counter

**Background jobs / workers:**
- [ ] Job queue depth gauge
- [ ] Job processing duration histogram
- [ ] Job success/failure counters
- [ ] Last successful run timestamp gauge

**External dependencies:**
- [ ] Outbound request rate and error rate per dependency
- [ ] Outbound request latency histogram
- [ ] Circuit breaker state gauge (0=closed, 1=open, 0.5=half-open)

{% include tool-embed.html
   title="Instrumentation Coverage Analyzer"
   src="/modules/module-1/1-2-interactive/instrumentation-analyzer.html"
   description="Evaluate your service's instrumentation coverage against SRE best practices. Identify gaps in your metric coverage and get implementation recommendations."
   height="640"
%}

---

## Key Takeaways

**1. Deep vs. shallow is a conscious choice, not a default.** Services with user-facing SLOs need deep instrumentation. Internal utility services can get by with shallow. Be deliberate.

**2. Use the right metric type.** Counters for events, gauges for states, histograms for distributions. Using a gauge where a counter belongs (or vice versa) produces misleading data.

**3. Cardinality is a performance constraint.** Every high-cardinality label dimension you add costs Prometheus storage and query time. Design labels around aggregation use cases, not debugging use cases.

**4. Bucket selection determines percentile accuracy.** Your SLO target must fall within your histogram bucket boundaries. Design buckets around your SLOs, not around defaults.

**5. Naming conventions are organizational infrastructure.** Standardize metric naming early. Renaming metrics in production is painful and breaks dashboards.

---

*The next lesson explores black box vs. white box monitoring — the complementary perspectives that together give you complete visibility into both what users experience and why the system behaves that way.*
