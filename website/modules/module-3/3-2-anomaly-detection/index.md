---
layout: lesson
title: "Anomaly Detection & the SAFE Methodology"
description: "Move from threshold-based alerting to detection systems that learn what normal looks like. Z-scores, IQR, the SAFE algorithm, and isolation forests — when each works, when each fails, and how to manage the false positive rate."
module_number: 3
module_id: module-3
module_slug: module-3
module_title: "Advanced Monitoring"
module_icon: "🔬"
module_color: "#f59e0b"
lesson_number: 2
lesson_id: "3-2"
reading_time: 18
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Explain why static thresholds fail for metrics with seasonality, trends, or wide variance"
  - "Implement Z-score, IQR, and SAFE-based detectors directly in PromQL recording rules"
  - "Calibrate detector sensitivity using the precision/recall trade-off"
  - "Recognize when machine-learning approaches (isolation forests, LSTMs) are worth the operational cost"
prev_lesson: /modules/module-3/3-1-multi-window-aggregation/
prev_title: "Multi-Window Aggregation & Seasonal Patterns"
next_lesson: /modules/module-3/3-3-capacity-modeling/
next_title: "Capacity Modeling & Predictive Monitoring"
---

## Why Static Thresholds Fail

Most alerting rules look like this: `error_rate > 0.05`. It's clean, easy to reason about, and works perfectly — until it doesn't.

Static thresholds fail in three predictable ways:

1. **They miss anomalies inside the threshold.** A service whose error rate normally sits at 0.1% has a problem at 2% — but a `> 5%` threshold lets it slide for hours.
2. **They false-fire during legitimate spikes.** Black Friday traffic legitimately pushes everything 5–10× — and your nicely-calibrated thresholds page everyone simultaneously.
3. **They don't adapt as the service evolves.** A threshold tuned for a service handling 1k RPS is wrong by the time the service hits 10k RPS, and nobody remembers to update it.

Anomaly detection replaces "is this value above a fixed line?" with "**is this value unexpected given the recent history of this metric?**" The detector learns what "normal" looks like and alerts on departures from it.

> **The trade-off**: anomaly detectors solve threshold problems but introduce new ones — false positive rates that depend on sensitivity tuning, vulnerability to drift, and operational complexity. Knowing which detector to use, and when, is the skill.

---

## Part 1: Z-Score Detection — The Foundation

The simplest useful anomaly detector: assume your metric is roughly normal-distributed and flag values more than `n` standard deviations from the mean.

{% raw %}
```
Z-score = (current_value - rolling_mean) / rolling_stddev

Anomaly if |Z-score| > threshold (commonly 3.0)
```
{% endraw %}

A Z-score of 3.0 corresponds to about 0.27% of normal samples — so on a metric scraped every 15 seconds, you'd expect roughly one false-positive sample every 15 minutes from pure statistical chance. That's why Z-score alerts always need a `for:` clause.

### Z-Score in PromQL

{% raw %}
```promql
# Compute the Z-score of current latency vs. 1-hour rolling history
(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
  -
  avg_over_time(
    histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:5m]
  )
)
/
stddev_over_time(
  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))[1h:5m]
)
```
{% endraw %}

Wired up as an alert with sustained-anomaly logic:

{% raw %}
```yaml
- alert: LatencyZScoreAnomaly
  expr: |
    abs(
      (job:http_request_p95_5m - avg_over_time(job:http_request_p95_5m[1h:5m]))
      /
      stddev_over_time(job:http_request_p95_5m[1h:5m])
    ) > 3
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "P95 latency >3σ from 1-hour mean (Z-score anomaly)"
```
{% endraw %}

### Z-Score Limitations

Z-score works beautifully when:
- The metric is approximately normal-distributed
- The metric has no strong trend
- Variance is reasonably stable

It fails when:
- The metric has heavy tails (latency p99 is famously NOT normal-distributed)
- The metric trends (a steadily-rising metric will perpetually look "anomalous" to the right)
- The metric has multi-modal behavior (different operating regimes)

When Z-score breaks down, IQR is usually the next thing to try.

---

## Part 2: IQR — Robust to Outliers

The Interquartile Range (IQR) detector uses percentiles instead of mean/stddev:

{% raw %}
```
Q1 = 25th percentile of recent samples
Q3 = 75th percentile of recent samples
IQR = Q3 - Q1

Anomaly if value > Q3 + 1.5 × IQR  (upper outlier)
         or  value < Q1 - 1.5 × IQR  (lower outlier)
```
{% endraw %}

The 1.5× multiplier is the classic Tukey-fence convention. For more sensitive detection, use 1.0×; for more conservative detection, use 3.0×.

The advantage: IQR is **robust** — a single huge outlier in your training data poisons a Z-score detector but barely moves the IQR calculation. For latency metrics where individual long-tail samples are routine, IQR is much harder to fool.

### IQR in Practice

PromQL doesn't have a native quantile function over a time range, so the typical approach is to pre-compute via recording rules using `quantile_over_time`:

{% raw %}
```yaml
- record: job:latency_p95:q25_1h
  expr: quantile_over_time(0.25, job:http_request_p95_5m[1h:5m])

- record: job:latency_p95:q75_1h
  expr: quantile_over_time(0.75, job:http_request_p95_5m[1h:5m])

- record: job:latency_p95:iqr_1h
  expr: job:latency_p95:q75_1h - job:latency_p95:q25_1h

- record: job:latency_p95:iqr_upper_fence
  expr: job:latency_p95:q75_1h + 1.5 * job:latency_p95:iqr_1h

- alert: LatencyIQRAnomaly
  expr: job:http_request_p95_5m > job:latency_p95:iqr_upper_fence
  for: 5m
```
{% endraw %}

---

## Part 3: The SAFE Methodology

**SAFE — Seasonal-Aware, Forecast-Enhanced detection** — is the technique you reach for when your metric has obvious daily/weekly patterns. Rather than asking "is this value anomalous compared to the last hour?", SAFE asks "is this value anomalous compared to *the same time last week*?"

### The SAFE Algorithm

```
1. For each metric m at time t, compute the seasonal baseline:
     baseline(t) = avg(m(t - 1 week), m(t - 2 weeks), m(t - 3 weeks), m(t - 4 weeks))

2. Compute the deviation:
     deviation(t) = m(t) - baseline(t)

3. Compute the seasonal stddev:
     seasonal_stddev = stddev(m(t - 1w), m(t - 2w), m(t - 3w), m(t - 4w))

4. SAFE Z-score:
     SAFE_z(t) = deviation(t) / seasonal_stddev

5. Flag as anomaly if |SAFE_z(t)| > threshold (typically 2.5)
```

### SAFE in PromQL

{% raw %}
```promql
# Seasonal baseline: average of same time, previous 4 weeks
(
  job:http_request_p95_5m offset 1w
  + job:http_request_p95_5m offset 2w
  + job:http_request_p95_5m offset 3w
  + job:http_request_p95_5m offset 4w
) / 4

# SAFE deviation
job:http_request_p95_5m - (above baseline expression)
```
{% endraw %}

In practice, this gets unwieldy quickly. Build it as recording rules:

{% raw %}
```yaml
- record: job:http_request_p95:safe_baseline
  expr: |
    (
      job:http_request_p95_5m offset 1w
      + job:http_request_p95_5m offset 2w
      + job:http_request_p95_5m offset 3w
      + job:http_request_p95_5m offset 4w
    ) / 4

- record: job:http_request_p95:safe_deviation
  expr: |
    job:http_request_p95_5m - job:http_request_p95:safe_baseline

- alert: SAFE_Anomaly_LatencyP95
  expr: |
    abs(job:http_request_p95:safe_deviation) > 0.100  # 100ms above seasonal baseline
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Latency P95 anomaly (SAFE detector)"
    description: |
      Current P95 is more than 100ms above the same-time-last-4-weeks average.
      This persists past normal seasonal variance.
```
{% endraw %}

### When SAFE Shines

- **Strong seasonality**: e-commerce traffic, payroll batch jobs, financial-market services
- **Predictable peaks**: services with known nightly maintenance windows or business-hours patterns
- **Mature services**: SAFE needs at least 4 weeks of historical data to work; for new services, start with Z-score and graduate to SAFE later

### When SAFE Fails

- **Genuine novel events** — Black Friday isn't anomalous because *every* Black Friday is anomalous, so the SAFE baseline catches up after a year. But the *first* Black Friday after launch will trigger SAFE alerts you can't act on.
- **Schedule changes** — if you reschedule a batch job from 02:00 to 03:00, SAFE will alert on the new pattern for 4 weeks until the baseline catches up.

---

## Part 4: When to Use Machine Learning

Statistical detectors handle 90% of production needs. The remaining 10% — typically high-cardinality, high-dimensional, or strongly non-stationary signals — call for ML approaches.

### Isolation Forest

For multi-dimensional anomaly detection (e.g., simultaneously watching `latency`, `error_rate`, and `cpu_util`), an Isolation Forest can identify "weird combinations" that no individual metric flags:

```python
from sklearn.ensemble import IsolationForest
import numpy as np

# Features: [latency_p95, error_rate, cpu_util, queue_depth]
X_train = np.array([...])  # 30 days of healthy operation, 5-minute samples

clf = IsolationForest(
    contamination=0.01,  # Expect 1% anomalies in clean training data
    random_state=42,
    n_estimators=100
)
clf.fit(X_train)

# Score current sample
current = np.array([[0.082, 0.003, 0.65, 12]])
anomaly_score = clf.decision_function(current)
is_anomaly = clf.predict(current) == -1

# Lower decision_function score = more anomalous
```

Isolation forests excel at finding "unusual conjunctions" — for example, "latency normal, error rate normal, but CPU is unusually low for this RPS" (which might indicate a downstream dependency timing out and short-circuiting).

### LSTM / Transformer Forecasters

For services with complex temporal dependencies (long-running batch jobs, multi-step transactions), neural-network forecasters can predict expected behavior with much greater fidelity than statistical baselines.

The catch: **operational cost**. An LSTM-based detector requires:
- A separate ML pipeline (training, validation, deployment)
- A feature store for input data
- Drift detection on the model itself
- A team that understands when the model is wrong

For most SRE teams, a well-tuned SAFE detector outperforms a poorly-maintained LSTM. **Don't reach for ML until you've exhausted statistical methods.**

---

## Part 5: The Precision/Recall Trade-Off

Every anomaly detector has a sensitivity knob. Turn it up, you catch more real anomalies (high recall) but also fire more false alarms (low precision). Turn it down, fewer false alarms but you miss real incidents.

### Measuring Detector Quality

Run your detector against historical data and label each detection:

| | Detector said anomaly | Detector said normal |
|---|---|---|
| **Was actually anomaly** | True Positive (TP) | False Negative (FN) |
| **Was actually normal** | False Positive (FP) | True Negative (TN) |

Then compute:

```
Precision = TP / (TP + FP)
  "Of the alerts I fired, how many were real?"
  
Recall    = TP / (TP + FN)
  "Of the real anomalies, how many did I catch?"
  
F1        = 2 × (Precision × Recall) / (Precision + Recall)
  "Single number balancing both."
```

### Tuning Strategy

1. **Set a target precision** for paging alerts. The on-call team's sanity is the constraint. **Precision ≥ 0.85** for paging is a common target — i.e., no more than 15% of pages are false alarms.
2. **Maximize recall subject to that precision constraint.** Once precision is acceptable, push recall as high as possible.
3. **Re-evaluate quarterly.** Service behavior drifts; detector tuning that worked in Q1 won't necessarily work in Q3.

### The Detection Tier Model

In practice, run multiple detectors at different sensitivities for the same metric:

| Tier | Detector | Sensitivity | Action |
|---|---|---|---|
| **Page** | SAFE, Z>4 | Low (high precision) | Wake up the on-call |
| **Ticket** | SAFE, Z>3 | Medium | Create a ticket for next-business-day investigation |
| **Log** | SAFE, Z>2 | High (high recall) | Log to anomaly stream for trend analysis, no alert |

The tiered approach means you catch more with the sensitive detector (no missed events) without paging on every twitch.

---

## Try the Anomaly Detection Playground

The interactive tool lets you run all four algorithms — Z-score, IQR, SAFE, and Isolation Forest — against the same configurable traffic patterns. Tune sensitivity in real time and watch precision and recall change.

{% include tool-embed.html
   title="Anomaly Detection Playground"
   src="/tools/anomaly-detection-playground.html"
   description="Compare anomaly detection algorithms on the same data. Choose a traffic pattern (normal, seasonal, trending, spike), inject anomalies, and tune detector parameters to see how precision and recall respond. Learn when each algorithm shines and when it fails."
   height="780"
%}

---

## Key Takeaways

**1. Static thresholds are a starting point, not a destination.** Once you have any service with seasonality, growth, or evolution, threshold-based alerting accumulates technical debt fast. Anomaly detection is the response.

**2. Use the simplest detector that works.** Z-score for stationary metrics. IQR for metrics with heavy tails. SAFE for metrics with seasonality. Don't reach for ML until statistical methods have demonstrably failed.

**3. SAFE is the workhorse.** For most production services with daily or weekly patterns, SAFE outperforms Z-score and IQR while remaining simple enough to debug. Build SAFE detectors as your default for any metric with obvious seasonality.

**4. Tune for precision before recall on paging alerts.** A page is a person's sleep. Aim for ≥85% precision on paging-tier alerts; accept lower recall and use ticket-tier or log-tier detectors to catch what page-tier missed.

**5. Run anomaly detection at multiple sensitivities simultaneously.** The tiered model — Page / Ticket / Log — gives you both high recall (you see everything) and high precision (you only get woken up for real problems).

---

*Next, we extend predictive thinking from "is something abnormal right now?" to "will something be abnormal in 30 days?" — Lesson 3.3 covers capacity modeling and predictive resource planning.*
