---
layout: lesson
title: "Monitoring Taxonomies Deep Dive"
description: "Master USE, RED, and Four Golden Signals — the three frameworks that define how SREs think about what to measure, and when to apply each."
module_number: 1
module_id: module-1
module_slug: module-1
module_title: "Foundations of Monitoring"
module_icon: "📡"
module_color: "#0ea5e9"
lesson_number: 1
lesson_id: "1-1"
reading_time: 20
difficulty: "Intermediate"
tools_count: 3
objectives:
  - "Distinguish between USE, RED, and Four Golden Signals and explain when each applies"
  - "Map monitoring signals to specific resource types and service categories"
  - "Design a taxonomy-appropriate monitoring strategy for a real service architecture"
  - "Identify the gaps each taxonomy leaves and how to close them strategically"
prev_lesson: /modules/module-0/0-4-collaboration/
prev_title: "Collaboration & Communication"
next_lesson: /modules/module-1/1-2-instrumentation/
next_title: "Instrumentation Strategy & Implementation"
---

## Why Taxonomies Matter Before You Write a Single Alert

Most monitoring systems are built ad hoc: an alert fires, someone adds a metric, the dashboard grows. After a year, you have 400 metrics and no consistent way to reason about whether your systems are healthy.

Monitoring taxonomies solve this by providing a systematic framework for deciding *what to measure and why*. They're not mutually exclusive — the most effective SRE monitoring strategies use all three, applied to the right resource types.

> **The fundamental insight**: USE tells you when your infrastructure is struggling. RED tells you when your services are degrading. Four Golden Signals tell you whether your users are experiencing problems. You need all three perspectives to have complete observability.

---

## The USE Method

**Utilization, Saturation, Errors** — developed by Brendan Gregg for hardware and operating system resources.

### The Three USE Signals

**Utilization**: What percentage of available capacity is being used?
- CPU utilization: `node_cpu_seconds_total{mode="idle"}` inverted
- Memory utilization: `(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes`
- Network interface utilization: bytes transmitted vs. interface capacity
- Disk I/O utilization: time spent doing I/O as a fraction of total time

**Saturation**: Is the resource overloaded and queuing work?
- CPU run queue length: processes waiting for CPU time
- Memory pressure: swap usage, OOM events
- Disk I/O queue depth: requests waiting to be served
- Network queue depth: packets queued for transmission

**Errors**: Are there error events occurring?
- CPU errors: machine check exceptions
- Memory errors: ECC correction events
- Disk errors: I/O errors, SMART failures
- Network errors: dropped packets, CRC errors

### When USE Applies

USE is the right taxonomy for **infrastructure resources** — things that can be measured with a fixed capacity and a utilization rate:

| Resource Type | USE is Applicable? |
|---|---|
| CPU | ✅ Yes — capacity is fixed |
| Memory | ✅ Yes — capacity is fixed |
| Network interfaces | ✅ Yes — bandwidth is fixed |
| Disk I/O | ✅ Yes — IOPS capacity is fixed |
| HTTP web service | ❌ No — use RED instead |
| Database connection pool | ✅ Yes — pool size is fixed |
| Thread pool | ✅ Yes — pool size is fixed |
| External API dependency | ❌ No — use RED instead |

### USE Limitations

USE breaks down when applied to software services rather than physical resources. An HTTP service doesn't have a "utilization" — it has a request rate, error rate, and latency. Forcing USE onto services produces misleading metrics.

---

## The RED Method

**Rate, Errors, Duration** — developed by Tom Wilkie at Weave Works for microservices.

### The Three RED Signals

**Rate**: How many requests is this service handling per second?
```prometheus
# Prometheus query for request rate
rate(http_requests_total[5m])
```

**Errors**: What fraction of requests are failing?
```prometheus
# Error rate
rate(http_requests_total{status_code=~"5.."}[5m])
  / rate(http_requests_total[5m])
```

**Duration**: How long do requests take?
```prometheus
# P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

### When RED Applies

RED is the right taxonomy for **request-driven services** — services that handle discrete requests from clients:

- HTTP APIs and web servers
- gRPC services
- Message queue consumers (treating message processing as "requests")
- Database query handlers
- GraphQL resolvers

RED is *not* appropriate for batch processing, background jobs without fixed endpoints, or infrastructure components (use USE for those).

### RED for SLO Alignment

RED signals map directly to SLO types:
- **Rate** → throughput SLIs
- **Errors** → availability SLIs (`1 - error_rate`)
- **Duration** → latency SLIs (P95, P99 percentile targets)

This makes RED the most natural taxonomy for services that have user-facing SLOs.

---

## The Four Golden Signals

Defined in the Google SRE Book for user-facing systems with complex performance characteristics.

### The Four Signals

**Latency**: Time to service a request — *including failed requests*.

> A critical implementation detail: many teams measure latency only for successful requests. But slow failures are still a bad user experience. Measure latency for all requests, tagged by success/failure.

```prometheus
# Latency percentiles by status
histogram_quantile(0.99, 
  rate(http_request_duration_seconds_bucket{job="frontend"}[5m]))
```

**Traffic**: Demand being placed on the system.

Unlike RED's "rate" (raw RPS), traffic in the Four Golden Signals framework is about measuring demand in user-meaningful terms:
- HTTP requests/second for a web service
- Active connections for a WebSocket service
- Messages processed/second for a streaming service

**Errors**: Rate of requests that fail explicitly or implicitly.

"Implicit" errors are important: a request that returns 200 but with corrupted data, or takes 30 seconds instead of the expected 200ms, is an error from the user's perspective even if HTTP considers it a success.

**Saturation**: How "full" is the service? How much more load can it absorb?

For services (unlike USE's hardware saturation), this means measuring queue depths, connection pool exhaustion, and latency increase under load:
```prometheus
# Connection pool saturation
(hikaricp_connections_active / hikaricp_connections_max) * 100
```

### Four Golden Signals vs. RED

| | RED | Four Golden Signals |
|---|---|---|
| **Best for** | Individual microservices | User-facing systems |
| **Error definition** | HTTP status codes | User experience degradation |
| **Saturation** | Not included | Explicitly included |
| **SLO alignment** | Direct | Requires translation |

---

## Combining All Three Taxonomies

The most complete monitoring strategies apply all three frameworks at different layers:

```
User Experience Layer    → Four Golden Signals
  ├── Web Frontend SLOs
  └── API Gateway metrics

Service Layer            → RED  
  ├── Microservice A
  ├── Microservice B
  └── Database queries

Infrastructure Layer     → USE
  ├── CPU / Memory
  ├── Disk I/O
  └── Network
```

**The diagnostic flow**: When a Four Golden Signals alert fires (user experience problem), you drill into RED metrics to identify which service is degraded, then into USE metrics to identify the resource constraint causing the degradation.

{% include diagram-embed.html
   title="Monitoring Taxonomy Comparison Matrix"
   src="/modules/module-1/1-1-visuals/diagrams/monitoring-taxonomy-comparison.html"
   height="480"
%}

---

## Applying Taxonomies to Real Architectures

Consider an e-commerce platform with these components:

| Component | Taxonomy | Key Metrics |
|---|---|---|
| Load balancer | USE + RED | Connection utilization, request rate, 5xx rate |
| Product API service | RED | RPS, error rate, P99 latency |
| Database (PostgreSQL) | USE + RED | Connection pool saturation, query rate, query latency |
| Cache (Redis) | USE + RED | Memory utilization, hit rate, command rate |
| Worker nodes (Kubernetes) | USE | CPU utilization, memory pressure, disk I/O |
| CDN | RED | Request rate, cache miss rate, origin error rate |

Notice that most components benefit from at least partial coverage of two taxonomies. The rule of thumb: **USE for what has a fixed capacity ceiling, RED for what processes discrete requests**.

{% include diagram-embed.html
   title="E-commerce Architecture Monitoring Map"
   src="/modules/module-1/1-1-visuals/diagrams/ecommerce-monitoring-map.html"
   height="500"
%}

---

## Signal Quality: The Four Properties of Useful Metrics

Choosing which metrics to actually collect and alert on requires evaluating signal quality. A useful metric has four properties:

**1. Actionable**: When this metric changes, someone knows what to do. "CPU utilization > 80% for 5 minutes" is actionable. "CPU utilization changed" is not.

**2. Meaningful**: The metric measures something that matters to users or system health. Vanity metrics (page views, registered users) are not monitoring signals.

**3. Reliable**: The metric is consistently available and accurately reflects the system state it claims to measure. Intermittent metrics or metrics that lag by 5 minutes are problematic as SLI foundations.

**4. Comparable**: The metric can be compared over time and across service instances. Metrics that don't have consistent labeling or resolution are difficult to act on.

---

## Key Takeaways

**1. No single taxonomy is complete.** USE, RED, and Four Golden Signals each capture a different layer of system health. Complete monitoring requires all three.

**2. Match the taxonomy to the resource type.** Fixed-capacity resources → USE. Request-driven services → RED. User-facing systems → Four Golden Signals.

**3. The diagnostic flow runs upward.** Golden Signals alerts trigger RED investigation. RED investigation triggers USE investigation. Each layer explains the one above it.

**4. Signal quality matters more than signal quantity.** 20 high-quality, actionable metrics beat 200 metrics with no clear owner and no response playbook.

**5. Taxonomies align with SLOs.** RED maps directly to availability and latency SLOs. Golden Signals map to user experience SLOs. This makes the taxonomy choice a prerequisite for good SLO design.

---

*The next lesson goes deeper into instrumentation strategy — the technical practice of adding observability signals to your services, managing cardinality, and building the foundation that makes your monitoring taxonomies actionable.*
