---
layout: lesson
title: "Capacity Planning with SLO Integration"
description: "Use SLO data, error budget trends, and demand forecasting to make data-driven capacity investment decisions — moving from reactive scaling to proactive infrastructure planning tied directly to reliability commitments."
module_number: 2
module_id: module-2
module_slug: module-2
module_title: "SLO/SLI Mastery"
module_icon: "🎯"
module_color: "#10b981"
lesson_number: 8
lesson_id: "2-8"
reading_time: 18
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Integrate SLO performance data into capacity planning models"
  - "Build demand forecasting models that account for traffic seasonality and growth trends"
  - "Calculate the capacity headroom required to maintain SLOs under traffic variance"
  - "Make data-driven infrastructure investment decisions using reliability cost modeling"
prev_lesson: /modules/module-2/2-7-slo-governance/
prev_title: "SLO Governance & Organizational Maturity"
next_lesson: /modules/module-1/1-1-monitoring-taxonomies/
next_title: "Continue to Module 3"
---

## The Capacity-Reliability Connection

Most capacity planning is disconnected from reliability engineering. Infrastructure teams plan capacity based on cost and utilization targets. SRE teams plan reliability based on SLOs and error budgets. The two processes don't talk to each other — until a capacity shortage causes an SLO breach.

The integrated approach treats capacity planning as a reliability engineering function: **infrastructure decisions should be driven by what's required to maintain your SLO commitments under expected traffic patterns, not by cost minimization alone**.

> **The core insight**: If your service can maintain its SLO at 60% CPU utilization but can't at 80%, then "keep CPU below 80%" is a reliability requirement, not just an ops preference. The error budget cost of a capacity-related outage quantifies exactly how much you should invest to prevent it.

---

## Part 1: SLO-Informed Capacity Requirements

### The SLO Headroom Model

Your capacity plan must account for three sources of traffic variance:

1. **Baseline growth**: Monthly organic traffic growth (measure your trend)
2. **Seasonal peaks**: Daily, weekly, and annual patterns (Black Friday, end-of-month billing cycles, weekday vs. weekend)
3. **Incident headroom**: Capacity to absorb sudden traffic surges that would otherwise trigger SLO breaches

**Capacity formula**:
{% raw %}
```
Required Capacity = 
  peak_traffic × (1 + growth_rate × planning_horizon)
  × seasonal_peak_multiplier
  × safety_headroom_factor

where:
  safety_headroom_factor = 1 / (1 - target_utilization_ceiling)
  
Example:
  Current peak: 10,000 RPS
  Monthly growth: 8%
  Planning horizon: 6 months: 1.08^6 = 1.587
  Seasonal peak multiplier (Black Friday): 4×
  Target utilization ceiling: 70% → safety factor = 1/0.3 = 3.33×
  
  Required capacity = 10,000 × 1.587 × 4 × 3.33 = 211,487 RPS capacity
```
{% endraw %}

### Why 70% Utilization Ceiling?

Setting a capacity ceiling at 70% (not 90%) provides:
- **30% headroom for unexpected traffic spikes** without degrading
- **Burst capacity for restarts** — during rolling restarts, traffic redistributes to remaining instances
- **Degraded mode operation** — if one instance fails, remaining capacity absorbs the load without SLO breach

For services with latency SLOs, the utilization ceiling may need to be lower. Queueing theory (M/M/1 queue model) shows that latency increases nonlinearly as utilization approaches 100%:

{% raw %}
```
Average response time = service_time / (1 - utilization)

At 50% utilization: latency = 2× service time
At 70% utilization: latency = 3.33× service time  
At 90% utilization: latency = 10× service time
At 95% utilization: latency = 20× service time
```
{% endraw %}

**Implication**: A service with a P99 latency SLO of 200ms that takes 100ms at idle will breach its SLO before reaching 50% CPU utilization if requests are queuing. The SLO-informed utilization ceiling may be well below 70%.

---

## Part 2: Demand Forecasting

### Linear Trend Forecasting

The simplest model — assumes consistent percentage growth:

{% raw %}
```python
import numpy as np
from scipy import stats

def forecast_traffic(historical_rps, days_to_forecast):
    """
    Linear regression on log-transformed traffic (models exponential growth).
    Returns forecasted RPS and 95% prediction interval.
    """
    days = np.arange(len(historical_rps))
    log_rps = np.log(historical_rps)
    
    slope, intercept, r_value, p_value, std_err = stats.linregress(days, log_rps)
    
    forecast_days = np.arange(len(historical_rps), 
                               len(historical_rps) + days_to_forecast)
    
    # Point forecast
    log_forecast = slope * forecast_days + intercept
    forecast = np.exp(log_forecast)
    
    # 95% prediction interval
    prediction_interval = 1.96 * std_err * np.sqrt(
        1 + 1/len(days) + 
        (forecast_days - days.mean())**2 / ((days - days.mean())**2).sum()
    )
    
    return {
        'forecast': forecast,
        'upper_95': np.exp(log_forecast + prediction_interval),
        'lower_95': np.exp(log_forecast - prediction_interval),
        'monthly_growth_rate': np.exp(slope * 30) - 1
    }
```
{% endraw %}

### Seasonality-Aware Forecasting

For services with strong seasonal patterns, linear trends alone are insufficient. Use decomposition:

{% raw %}
```python
from statsmodels.tsa.seasonal import seasonal_decompose

# Decompose traffic into: trend + seasonality + residual
decomposition = seasonal_decompose(
    historical_rps,
    model='multiplicative',  # Growth amplifies seasonal patterns
    period=7  # Weekly seasonality
)

# For capacity planning, use the peak seasonal multiple:
seasonal_peak_factor = decomposition.seasonal.max()
# Plan for trend_forecast × seasonal_peak_factor
```
{% endraw %}

### Event-Based Capacity Planning

Some traffic spikes are predictable from business events, not seasonal patterns:
- Product launches → 2–5× baseline
- Marketing campaigns → 3–10× baseline
- Regulatory deadlines → end-of-period spikes

Maintain a capacity events calendar:
{% raw %}
```yaml
# capacity-events-2026.yml
events:
  - name: "Q4 Black Friday"
    date: 2026-11-27
    expected_multiplier: 8.0
    preparation_lead_time: 30 days
    capacity_type: [compute, database_read_replicas, cdn]
    
  - name: "Annual subscription renewal push"
    date: 2026-12-15
    expected_multiplier: 3.0
    preparation_lead_time: 14 days
    capacity_type: [payment_processing, checkout]
```
{% endraw %}

---

## Part 3: SLO-Cost Trade-Off Analysis

Every SLO target has a cost. Tighter SLOs require more capacity headroom, more redundancy, and more engineering investment. The SLO-cost trade-off analysis quantifies this relationship.

### The Capacity Cost of SLO Targets

{% raw %}
```
For each availability target, calculate:
  Expected downtime per year = (1 - SLO) × 8760 hours
  Expected revenue loss = expected_downtime × hourly_revenue_impact
  Infrastructure cost to achieve SLO = f(redundancy, capacity headroom, tooling)
  
Break-even: SLO is worth achieving if:
  infrastructure_cost < expected_downtime_savings
```
{% endraw %}

**Example analysis**:

| SLO Target | Expected Annual Downtime | Infrastructure Premium | Annual Savings |
|---|---|---|---|
| 99.0% | 87.6 hours | Baseline | Baseline |
| 99.5% | 43.8 hours | +15% | $2.2M (at $50K/hour) |
| 99.9% | 8.76 hours | +40% | $3.9M additional |
| 99.99% | 52.6 min | +200% | $4.1M additional |

For most businesses, the jump from 99.0% to 99.9% has the best ROI. The jump from 99.9% to 99.99% is expensive relative to the marginal benefit.

### Error Budget Cost of Capacity Incidents

When a capacity-related incident depletes your error budget, quantify the cost:

{% raw %}
```
Budget Cost = incident_duration_minutes / monthly_budget_minutes

Example: 4-hour capacity incident on a 99.9% SLO service
  Monthly budget = (1 - 0.999) × 30 × 24 × 60 = 43.2 minutes
  Incident duration = 240 minutes
  
  Budget consumed = 240 / 43.2 = 5.6× the monthly budget
  → 5.6 months of reliability budget consumed in 4 hours
  → If not addressed: feature freeze for next 5+ months
```
{% endraw %}

This calculation makes the business case for proactive capacity investment concrete.

{% include tool-embed.html
   title="Capacity Planning Simulator"
   src="/tools/capacity-planning-simulator.html"
   description="Model capacity requirements for your services. Input traffic patterns, growth rates, SLO targets, and utilization ceilings to get capacity recommendations and cost projections. See how capacity decisions affect error budget risk."
   height="720"
%}

---

## Part 4: The Capacity Planning Process

### Quarterly Capacity Review

**Inputs**:
- Current utilization metrics (USE methodology: CPU, memory, network, storage)
- SLO performance over the past quarter (any capacity-related budget consumption?)
- Demand forecast for next 6–12 months
- Planned capacity events from the business calendar

**Outputs**:
- Capacity adequacy assessment: Are current resources sufficient for the next 6 months?
- Infrastructure investment recommendations with cost/benefit analysis
- SLO risk assessment: Which services are most likely to breach SLOs due to capacity constraints?

### Automated Capacity Alerting

Don't wait for the quarterly review to catch capacity trends:

{% raw %}
```prometheus
# Alert: service will exceed 70% CPU within 30 days at current growth rate
alert: CapacityGrowthRisk
expr: >
  predict_linear(
    avg(rate(container_cpu_usage_seconds_total[1h]))[7d:1h],
    30 * 24 * 3600  # 30 days in seconds
  ) > 0.70
for: 24h
labels:
  severity: warning
annotations:
  summary: "{{ $labels.service }} projected to exceed 70% CPU in 30 days"
  description: "Current growth trajectory will require capacity expansion"

# Alert: capacity-related error rate emerging
alert: CapacityPressureEvidenced
expr: >
  histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) 
    > (histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[30d:5m])) * 1.5)
  AND
  avg(rate(container_cpu_usage_seconds_total[5m])) > 0.65
for: 15m
annotations:
  summary: "Latency increase correlated with high CPU — capacity pressure emerging"
```
{% endraw %}

---

## Key Takeaways

**1. Capacity planning is a reliability function.** The cost of not having enough capacity is measured in error budget consumption. Quantify it and use it in infrastructure investment decisions.

**2. The queueing theory relationship between utilization and latency is non-negotiable.** For services with latency SLOs, your utilization ceiling may be well below 70%. Calculate it explicitly from your SLO target and observed service time.

**3. Seasonal forecasting prevents Black Friday disasters.** Build the capacity events calendar into your planning process. The cost of over-provisioning for a predictable peak is always less than the cost of an SLO breach during that peak.

**4. The error budget cost of capacity incidents creates a compelling ROI case.** "This 4-hour outage consumed 5.6 months of error budget, triggering a feature freeze, because we delayed a $50K infrastructure investment" is a persuasive argument for proactive capacity management.

**5. Automate the trend detection.** Don't wait for the quarterly review to discover capacity problems. `predict_linear()` alerts give you 30-day early warning when growth trajectories are heading toward capacity limits.

---

*You've completed Module 2: SLO/SLI Mastery. You now have the complete toolkit for defining, measuring, governing, and optimizing service level objectives — from the mathematics of error budgets through organizational governance to capacity planning.*

*The course continues with Module 3: Advanced Monitoring (anomaly detection, capacity modeling, and reliability engineering at scale), Module 4: Incident Response (the complete incident management lifecycle), and Module 5: SRE in CI/CD (integrating reliability practices into your delivery pipeline).*
