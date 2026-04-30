---
layout: lesson
title: "Multi-Window Aggregation & Seasonal Patterns"
description: "A single aggregation window is a single perspective. Learn the multi-window techniques that surface deployment correlations, seasonal patterns, and slow-burn drift hidden inside your time-series data."
module_number: 3
module_id: module-3
module_slug: module-3
module_title: "Advanced Monitoring"
module_icon: "🔬"
module_color: "#f59e0b"
lesson_number: 1
lesson_id: "3-1"
reading_time: 16
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Articulate why single-window aggregation hides production-critical patterns"
  - "Build multi-window Prometheus queries that surface seasonal and deployment-driven behavior"
  - "Detect slow-burn metric drift before it triggers SLO alerts"
  - "Design recording rules that pre-compute multi-window views without query-time cost"
prev_lesson: /modules/module-2/2-8-capacity-planning/
prev_title: "Capacity Planning with SLO Integration"
next_lesson: /modules/module-3/3-2-anomaly-detection/
next_title: "Anomaly Detection & the SAFE Methodology"
---

## The Tyranny of the Five-Minute Window

Walk into any monitoring war room and you'll find dashboards built on `rate(...[5m])`. Five minutes is the comfortable default — short enough to show "now," long enough to smooth out noise. It's also a window that systematically lies to you about three classes of problem:

1. **Slow-burn degradation** — a service that drifts from 50ms to 80ms latency over two weeks looks identical at every 5-minute snapshot. The 5-minute view is *blind* to slope.
2. **Seasonal patterns** — Monday-evening deployments that consistently cause Tuesday-morning incidents disappear into the same noise floor as Wednesday-afternoon background variation.
3. **Burst signals** — a 30-second spike that doubles latency for half your users gets averaged into a 20% blip on the 5-minute view, indistinguishable from normal traffic variance.

The fix is not to pick a different "right" window. The fix is to look through **multiple windows simultaneously** and treat the divergence between them as the signal.

> **The core insight**: A single aggregation window collapses three things — instantaneous behavior, current load, and trend — into one number. Pulling them apart with multi-window analysis is the foundation of advanced monitoring.

---

## Part 1: The Three-Window Model

For most production services, three aggregation windows running in parallel give you the complete picture:

| Window | Purpose | What it reveals |
|---|---|---|
| **Short (1m–5m)** | "What is happening right now?" | Real-time spikes, immediate incidents, deployment-induced regressions |
| **Medium (1h–6h)** | "Is the service healthy this shift?" | Operational drift, on-call decision-making, gradual saturation |
| **Long (1d–7d)** | "Is the service trending in the right direction?" | Seasonal patterns, capacity trends, deployment-week-over-deployment-week comparisons |

The same metric, viewed through all three windows, tells three different stories — and the disagreement between them is where insight lives.

### Three Windows in PromQL

{% raw %}
```promql
# Short: instantaneous behavior — what's happening right now
sum(rate(http_requests_total{job="checkout"}[5m]))

# Medium: this shift's behavior — what we're operating against
sum(rate(http_requests_total{job="checkout"}[1h]))

# Long: this week's behavior — what the trend is
avg_over_time(
  sum(rate(http_requests_total{job="checkout"}[5m]))[7d:5m]
)
```
{% endraw %}

The third query is worth dwelling on. It uses a **subquery** (`[7d:5m]`) — Prometheus computes the inner expression every 5 minutes for the past 7 days, then averages those 2,016 samples. This gives you a stable trend baseline that doesn't move when traffic spikes briefly.

---

## Part 2: Detecting Seasonal Patterns

### The "Monday Deployment" Problem

A real pattern from a real production system: Tuesday-morning checkout failures. The 5-minute view showed brief Tuesday spikes; the daily view showed nothing unusual. The pattern only emerged when we compared Mondays-with-deployments to all other days:

{% raw %}
```promql
# Latency on days with deployments (uses metric label `deploy=true` set by CI)
avg_over_time(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
  [24h:5m]
) and on() (deploy_today == 1)

# Latency on days without deployments (baseline)
avg_over_time(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
  [24h:5m]
) and on() (deploy_today == 0)
```
{% endraw %}

When the deploy-day average runs 1.4× the no-deploy-day average for *six consecutive weeks*, you have a seasonal pattern — and a deployment-quality problem to fix.

### Day-of-Week Comparison

When you suspect a weekly pattern, the `day_of_week()` function lets you isolate any specific day:

{% raw %}
```promql
# P95 latency, only on Mondays
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket[5m])
) and on() (day_of_week() == 1)

# Ratio: Monday performance vs. weekly average
(
  avg_over_time(
    histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[7d:5m]
  ) and on() (day_of_week() == 1)
)
/
avg_over_time(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[7d:5m]
)
```
{% endraw %}

A ratio that consistently exceeds 1.2 means Mondays are systematically worse than other days — that's a pattern, not coincidence.

### Hour-of-Day Patterns

Daily traffic cycles are nearly universal. The technique: compare the current hour's value to the same hour from prior days:

{% raw %}
```promql
# Compare current request rate to the same hour, 7 days ago
sum(rate(http_requests_total[5m]))
/
sum(rate(http_requests_total[5m] offset 7d))
```
{% endraw %}

A value of `1.0` means traffic this hour matches the same hour last week. A value of `1.4` means 40% above last week — possibly growth, possibly an incident in progress. The `offset 7d` operator is a multi-window technique you'll use constantly.

---

## Part 3: Detecting Slow-Burn Drift

### The Drift That Doesn't Trigger Alerts

A service that goes from 50ms p95 to 80ms p95 over six weeks never triggers an alert if you set thresholds at "150ms for 5 minutes." But that 60% degradation is exactly the kind of problem your customers notice and your incident retrospectives miss.

The technique: compare a current short window to a historical long window:

{% raw %}
```promql
# Current 1-hour latency vs. the same metric averaged over 30 days
(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[1h]))
)
/
(
  avg_over_time(
    histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
    [30d:5m]
  )
)
```
{% endraw %}

A value drifting from 1.0 to 1.6 over weeks tells you the service is getting slower — even though no single sample looks anomalous. Wire this into a slow-moving alert:

{% raw %}
```yaml
- alert: SlowBurnLatencyDrift
  expr: |
    (
      histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[6h]))
    )
    /
    (
      avg_over_time(
        histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[30d:5m]
      )
    ) > 1.3
  for: 24h
  labels:
    severity: warning
  annotations:
    summary: "{{ $labels.service }} P95 has drifted >30% above 30-day baseline"
    description: |
      Current 6-hour P95 is significantly above the 30-day rolling average.
      No single window triggered a fast alert, but the trend is unfavorable.
```
{% endraw %}

The `for: 24h` clause is critical. Drift alerts should fire only when the drift has been sustained — they're not for incident response, they're for triggering the next reliability investigation.

---

## Part 4: Recording Rules — The Performance Layer

Multi-window queries get expensive. A single dashboard with eight panels each computing 30-day subqueries can saturate your Prometheus instance during query time. The fix is **recording rules** — pre-compute the multi-window views and store them as new metrics.

{% raw %}
```yaml
# /etc/prometheus/rules/multi-window.yml
groups:
  - name: multi_window_slo
    interval: 30s
    rules:
      # 5-minute window — pre-computed for fast dashboards
      - record: job:http_request_p95_5m
        expr: |
          histogram_quantile(0.95,
            sum by (job, le) (rate(http_request_duration_seconds_bucket[5m]))
          )

      # 1-hour window — operational view
      - record: job:http_request_p95_1h
        expr: |
          histogram_quantile(0.95,
            sum by (job, le) (rate(http_request_duration_seconds_bucket[1h]))
          )

      # 24-hour window — daily trend
      - record: job:http_request_p95_24h
        expr: |
          avg_over_time(job:http_request_p95_5m[24h])

      # 7-day baseline — only updated hourly to save resources
      - record: job:http_request_p95_7d_baseline
        expr: |
          avg_over_time(job:http_request_p95_5m[7d:5m])

      # Drift ratio — the key signal
      - record: job:http_request_p95_drift_ratio
        expr: |
          job:http_request_p95_1h / job:http_request_p95_7d_baseline
```
{% endraw %}

Now your dashboards query `job:http_request_p95_drift_ratio` directly — a single point lookup instead of a 30-day subquery. The performance gain on a busy Prometheus instance is typically 100×.

### Recording Rule Hygiene

A few rules of thumb the SRE community has learned the hard way:

- **Use the `level:metric:operations` naming convention.** `job:http_request_p95_5m` is read as "this metric is grouped at the `job` level, derived from `http_request_p95`, over a 5-minute window." When you have hundreds of recording rules, this convention saves your team's sanity.
- **Match the evaluation interval to the use case.** Drift baselines updated every 30 seconds are wasteful — once an hour is plenty.
- **Don't chain too deep.** Recording rules that depend on recording rules that depend on recording rules become impossible to debug. Two levels deep is the practical limit.

---

## Part 5: Multi-Window SLO Burn Rate

The most operationally important application of multi-window aggregation is **burn rate alerting** — covered in depth in Module 2.6, but worth re-examining through the multi-window lens.

A multi-window burn rate alert fires when *both* a fast window (5m) *and* a slow window (1h) show high burn rate simultaneously:

{% raw %}
```yaml
- alert: HighBurnRate_FastAndSlow
  expr: |
    (
      job:slo_error_budget_burn_rate_5m > 14.4
      and
      job:slo_error_budget_burn_rate_1h > 14.4
    )
  for: 2m
  labels:
    severity: page
  annotations:
    summary: "Critical burn rate on both 5m and 1h windows"
```
{% endraw %}

Why both? A single fast-window spike could be a brief blip — paging the on-call for it creates alert fatigue. A single slow-window elevation could be lingering damage from an already-resolved incident — also not actionable. **The intersection is the actionable signal**: something is currently bad *and* has been bad long enough to matter.

This is the multi-window principle generalized: **don't trust any single window. Trust the agreement between windows.**

---

## Try the Visualizer

The interactive tool below loads representative production data and lets you flip between aggregation windows in real time. Watch how the same data tells completely different stories at 5m, 1h, 24h, and 7d.

{% include tool-embed.html
   title="Multi-Window Aggregation Visualizer"
   src="/tools/multi-window-aggregation-visualizer.html"
   description="Interactive comparison of how different aggregation windows reveal or hide patterns. Switch between window sizes, overlay deployment markers, and see seasonal patterns emerge as you widen the lens."
   height="720"
%}

---

## Key Takeaways

**1. One window is one perspective.** Picking a single aggregation window means accepting blindness to whatever that window can't see. Always run multiple windows in parallel.

**2. The disagreement between windows is the signal.** When the 5-minute view says "fine" and the 24-hour view says "drifting," that disagreement is more valuable than either view alone.

**3. Seasonal patterns require explicit comparison.** Use `day_of_week()` and `offset 7d` to compare like-for-like time periods. Background variation drowns these patterns when you don't.

**4. Slow-burn drift needs slow-burn alerts.** A `for: 24h` drift alert is your defense against the kind of degradation that doesn't show up in fast windows. Wire one in for every customer-facing latency SLI.

**5. Pre-compute multi-window views with recording rules.** Subqueries over 30-day windows are query-time-expensive. Recording rules turn them into cheap point lookups, making multi-window dashboards practical at scale.

---

*Up next: with multi-window views in hand, we can ask the harder question — when is "different from baseline" actually anomalous? Lesson 3.2 covers the SAFE algorithm and other anomaly detection techniques that turn multi-window deltas into alertable signals.*
