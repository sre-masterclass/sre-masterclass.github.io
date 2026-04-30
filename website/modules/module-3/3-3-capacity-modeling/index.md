---
layout: lesson
title: "Capacity Modeling & Predictive Monitoring"
description: "Move from reactive 'we ran out of capacity' postmortems to predictive 'we will run out in 30 days' alerts. Linear regression forecasting, queueing theory in production, saturation SLIs, and auto-scaling design tied to reliability."
module_number: 3
module_id: module-3
module_slug: module-3
module_title: "Advanced Monitoring"
module_icon: "🔬"
module_color: "#f59e0b"
lesson_number: 3
lesson_id: "3-3"
reading_time: 18
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Build predictive capacity alerts using `predict_linear()` to forecast 30 days ahead"
  - "Apply queueing theory (M/M/1, M/M/c) to derive utilization ceilings from latency SLOs"
  - "Implement saturation SLIs that warn before resource exhaustion causes user-visible impact"
  - "Design auto-scaling triggers that respond to SLO risk, not arbitrary CPU thresholds"
prev_lesson: /modules/module-3/3-2-anomaly-detection/
prev_title: "Anomaly Detection & the SAFE Methodology"
next_lesson: /modules/module-4/
next_title: "Module 4 — Incident Response & Operations"
---

## From Reactive to Predictive

Module 2.8 covered capacity planning at the strategic level — connecting SLOs to infrastructure investment decisions. This lesson is the operational counterpart: **the monitoring patterns that turn capacity from a quarterly conversation into a continuous signal**.

The shift in mindset is simple but profound:

- **Reactive capacity monitoring**: alert when utilization is high *now*. By the time it fires, you're already in trouble.
- **Predictive capacity monitoring**: alert when current trends will cause a problem *in 30 days*. You have weeks to respond.

The technique that makes predictive monitoring work is forecasting — extrapolating current trends forward and comparing the projection to your capacity limits.

> **The core insight**: Capacity problems are slow. Most resources don't go from 50% to exhausted overnight — they grow at roughly known rates over weeks. If you can measure the growth rate, you can predict exhaustion. Predicting exhaustion lets you fix the problem during business hours, not during the on-call shift.

---

## Part 1: Linear Forecasting with `predict_linear`

PromQL's `predict_linear()` function fits a least-squares linear regression to a metric's recent history and extrapolates forward. It's the simplest forecasting tool in the SRE toolbox — and frequently the only one you need.

### The Function Signature

{% raw %}
```promql
predict_linear(metric[duration], seconds_into_future)
```
{% endraw %}

`predict_linear(node_filesystem_avail_bytes[7d], 86400)` reads as: "Fit a line to the last 7 days of available filesystem bytes, then return the predicted value 1 day (86,400 seconds) from now."

### The Classic Disk-Will-Fill Alert

{% raw %}
```yaml
- alert: DiskWillFillIn4Hours
  expr: |
    predict_linear(node_filesystem_avail_bytes[1h], 4 * 3600) <= 0
    and
    node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.20
  for: 30m
  labels:
    severity: warning
  annotations:
    summary: "{{ $labels.instance }}:{{ $labels.mountpoint }} projected to fill in 4h"
    description: |
      Based on the last hour of fill rate, this filesystem will run out
      of space within 4 hours unless the trend reverses. Currently at
      {{ $value | humanizePercentage }} available.
```
{% endraw %}

The compound condition is important: we only fire if both the *prediction* says we'll fill *and* the current fill is already concerning (<20% available). Without the second clause, you'd fire on slow-growing filesystems that are only at 50% used.

### Multi-Horizon Capacity Alerting

For different resources, different forecast horizons make sense:

| Resource | Look-back | Forecast horizon | Why |
|---|---|---|---|
| Disk space | 1h | 4h | Disks fill quickly during runaway logs; short horizon catches them |
| CPU utilization | 7d | 30d | Capacity provisioning takes weeks; long horizon gives lead time |
| Memory growth | 6h | 24h | Memory leaks tend to be steady; medium horizon catches them |
| Database connections | 1h | 4h | Connection pool exhaustion is operational, not strategic |

### When `predict_linear` Lies

Linear forecasting assumes a roughly linear trend. It produces nonsense when:

- **The metric has strong seasonality.** Forecasting Tuesday morning's traffic from a 7-day window includes weekend dips, distorting the line. Use seasonality-aware forecasting (Module 2.8) for seasonal metrics.
- **The metric has step-function changes.** A deployment that doubles memory usage breaks the linearity assumption — the forecast will be wrong for at least the next look-back window.
- **The metric is bounded.** A "% utilization" metric can't exceed 100, but `predict_linear` will happily project it to 150%. Use logical guards (the `< 0.20` clause above) to validate forecasts before firing.

---

## Part 2: Queueing Theory in Production

The relationship between resource utilization and response latency is **not linear**. It's the most counter-intuitive thing in capacity planning, and ignoring it is the single biggest cause of "the system fell off a cliff" outages.

### The M/M/1 Queue Model

For a service modeled as a single-server queue with random arrival times and random service times:

{% raw %}
```
Average response time = service_time / (1 - utilization)
```
{% endraw %}

Plotted out:

| Utilization | Response time multiplier |
|---|---|
| 0% | 1.0× service time |
| 50% | 2.0× |
| 70% | 3.3× |
| 80% | 5.0× |
| 90% | 10.0× |
| 95% | 20.0× |
| 99% | 100.0× |

The implication: a service with a 100ms service time and a 200ms p95 latency SLO will breach its SLO at **50% utilization**. If you size your fleet for "peak CPU at 80%," you're sizing the fleet to violate latency SLOs at half-peak.

### Deriving Your Utilization Ceiling From Your SLO

The math runs the other direction too. Given an SLO target latency `T_slo` and an observed service time `T_service`:

{% raw %}
```
max_utilization = 1 - (T_service / T_slo)

Example: T_service = 80ms, T_slo = 200ms
  max_utilization = 1 - (80/200) = 0.60 = 60%
```
{% endraw %}

So for this service, the SLO-derived utilization ceiling is **60%**, not 80% or 90%. Auto-scaling should kick in at 60%, not 80%.

### The M/M/c Generalization

Real services have multiple workers (`c` servers in queueing terms). The Erlang-C formula generalizes M/M/1 to M/M/c, and the practical effect is **higher utilization is sustainable as you scale out workers**:

| Workers (c) | Sustainable utilization (10ms latency penalty) |
|---|---|
| 1 | ~50% |
| 4 | ~70% |
| 16 | ~85% |
| 64 | ~93% |

This is a key argument for "many small instances" over "few large instances" — pooled capacity is more efficient. A service running 64 workers can run at higher average utilization than 4 workers handling the same total load.

### A Practical PromQL Implementation

{% raw %}
```yaml
# Compute the queueing-theory derived ceiling for this service
- record: job:slo_utilization_ceiling
  expr: |
    1 - (
      avg(job:http_request_service_time_seconds)  # baseline service time
      /
      0.200  # SLO target latency in seconds
    )

# Alert when current utilization is approaching the SLO-derived ceiling
- alert: ApproachingSLODerivedCeiling
  expr: |
    avg(rate(container_cpu_usage_seconds_total[5m]))
    >
    job:slo_utilization_ceiling * 0.85  # 85% of the ceiling
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "CPU utilization approaching SLO-derived ceiling"
    description: |
      Current utilization is within 15% of the queueing-theory ceiling.
      Latency SLO breaches likely if traffic increases.
```
{% endraw %}

---

## Part 3: Saturation SLIs

Most teams focus on RED metrics (Rate, Errors, Duration) for SLIs. But the **fourth golden signal — saturation — deserves SLI status**, especially for stateful or capacity-bound services.

### What's a Saturation SLI?

A saturation SLI measures *headroom* — how close the service is to its capacity limit, expressed as a fraction the service is currently consuming.

Examples:

| Service | Saturation metric |
|---|---|
| Web server | Active requests / max worker count |
| Database | Active connections / max pool size |
| Queue worker | Queue depth / max queue length |
| Cache | Memory used / max memory |
| Disk | Disk used / disk capacity |

A saturation SLI says: "the service spent 99.5% of the last 30 days with saturation < 0.7."

### Saturation SLI in Practice

{% raw %}
```yaml
# Service saturation: ratio of in-flight to capacity
- record: job:service_saturation_ratio
  expr: |
    (
      sum by (job) (in_flight_requests)
      /
      sum by (job) (max_worker_count)
    )

# Saturation SLI: % of time saturation stayed below 0.70
- record: job:saturation_sli_30d
  expr: |
    avg_over_time(
      (job:service_saturation_ratio < bool 0.70)[30d:5m]
    )

# Alert if saturation SLI dropped below 99%
- alert: SaturationSLIBreach
  expr: job:saturation_sli_30d < 0.99
  labels:
    severity: warning
  annotations:
    summary: "Saturation SLI below target"
    description: |
      Service saturation exceeded 0.70 for more than 1% of the last 30 days.
      Capacity expansion or load shedding required.
```
{% endraw %}

### Why Saturation SLIs Matter

A service can have perfect availability and latency SLIs and still be one traffic spike away from disaster. Saturation SLIs surface that risk *before* it becomes an incident. They're the most predictive of the four golden signal SLIs.

---

## Part 4: SLO-Aware Auto-Scaling

Most auto-scaling rules look like: "scale out when CPU > 70%." This is wrong for the same reason static thresholds are wrong — CPU at 70% isn't a problem in itself. **Latency at 200ms is the problem**, and CPU is just one factor that contributes to it.

### The SLO-Aware Auto-Scaling Pattern

```yaml
# Instead of: scale on CPU > 70
# Scale when: predicted SLO breach is imminent

apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: checkout-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout
  minReplicas: 4
  maxReplicas: 100
  metrics:
    # Primary: scale on the SLI that matches our SLO
    - type: External
      external:
        metric:
          name: checkout_p95_latency_ms
        target:
          type: Value
          value: "150"   # scale before we hit the 200ms SLO ceiling
    
    # Secondary: scale on saturation, not raw CPU
    - type: External
      external:
        metric:
          name: checkout_worker_saturation_ratio
        target:
          type: Value
          value: "0.65"  # scale before queueing kicks in
  
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60   # respond fast to load
      policies:
        - type: Percent
          value: 50    # add up to 50% capacity per minute
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 600  # but scale down slowly
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
```

The key principles:

- **Scale on the SLI that matches your SLO**, not on CPU. Latency SLO? Scale on latency. Throughput SLO? Scale on saturation.
- **Asymmetric stabilization windows**: scale up fast (load is here now), scale down slow (don't oscillate).
- **Set the trigger inside the SLO**: if your SLO is 200ms p95, scale at 150ms p95. The buffer prevents flapping.

### Predictive Scaling

The next evolution: predictive scaling using `predict_linear()` to scale up *before* load arrives:

{% raw %}
```yaml
# Trigger pre-emptive scale-up if load is projected to exceed capacity in 5 minutes
- alert: PredictiveScaleUpNeeded
  expr: |
    predict_linear(sum(rate(http_requests_total[10m]))[15m:1m], 5 * 60)
    >
    sum(kube_deployment_spec_replicas{deployment="checkout"}) * 200  # 200 RPS per replica
  for: 1m
```
{% endraw %}

A workflow can subscribe to this alert and trigger scale-up automation, getting capacity in place 5 minutes ahead of load.

---

## Part 5: The Capacity Dashboard

Every SRE team should have a single dashboard answering: "Will any of our services run out of capacity in the next 30 days?"

### Required Panels

1. **Current utilization heatmap** — every service × every resource (CPU, memory, connections, queue depth)
2. **30-day forecast** — `predict_linear` projection with the capacity limit overlaid
3. **Saturation SLI status** — which services are below their saturation SLI target
4. **Queueing-theory ceiling status** — current utilization vs. SLO-derived ceiling
5. **Recently-scaled services** — services that auto-scaled in the past week (signal of capacity pressure)

This dashboard becomes the agenda for the weekly capacity review. Items in the red on the forecast become tickets. Items consistently red across multiple weekly reviews become projects.

---

## Try the Capacity Planning Simulator

Model real capacity scenarios — input traffic patterns, growth rates, SLO targets, and utilization ceilings — and see how they interact to produce capacity recommendations.

{% include tool-embed.html
   title="Capacity Planning Simulator"
   src="/tools/capacity-planning-simulator.html"
   description="Interactive capacity model. Configure baseline traffic, growth rate, seasonal patterns, SLO targets, and utilization ceilings. See projected resource needs, error budget risk from capacity shortfalls, and cost trade-offs across different planning horizons."
   height="780"
%}

---

## Key Takeaways

**1. Forecast forward. Don't react when it's already broken.** `predict_linear()` is the simplest, highest-leverage tool in the SRE toolbox. Wire it into every resource that has a hard capacity limit.

**2. Queueing theory dictates your utilization ceiling, not gut feel.** A latency SLO mathematically determines the maximum sustainable utilization. Compute it; don't guess. Most teams running at 80% CPU are silently violating their latency SLOs at peak.

**3. Saturation deserves SLI status.** RED is not enough for capacity-bound services. Saturation SLIs are the leading indicator that catches problems weeks before availability or latency SLIs do.

**4. Scale on SLIs, not on CPU.** Auto-scaling triggered by raw CPU thresholds is decoupled from what users actually experience. Trigger scaling on the same metrics your SLOs are defined against.

**5. Build the capacity dashboard.** A single dashboard showing 30-day capacity forecasts across all services becomes the agenda for proactive capacity work. Without it, capacity planning happens during incidents.

---

*That completes Module 3. You now have the full advanced-monitoring toolkit: multi-window analysis to surface patterns, anomaly detection to identify departures from normal, and predictive capacity modeling to see problems before they arrive.*

*Module 4 takes the next step — when monitoring detects a real problem, what does excellent incident response look like? We'll cover proactive alerting design, the incident response lifecycle, and chaos engineering as a way to validate your operational posture.*
