---
layout: lesson
title: "Monitoring Architecture Design"
description: "Design enterprise-scale monitoring architectures — data pipelines, tool ecosystems, federation strategies, and IaC-driven configuration management that stays maintainable as your system grows."
module_number: 1
module_id: module-1
module_slug: module-1
module_title: "Foundations of Monitoring"
module_icon: "📡"
module_color: "#0ea5e9"
lesson_number: 5
lesson_id: "1-5"
reading_time: 22
difficulty: "Advanced"
tools_count: 1
objectives:
  - "Design a monitoring data pipeline that scales from startup to enterprise without a full rewrite"
  - "Choose between monitoring architectures (centralized vs federated vs hybrid) based on your organizational context"
  - "Implement monitoring configuration as code using Prometheus operator and Grafana as Code"
  - "Integrate monitoring with the broader observability ecosystem (traces, logs, metrics)"
prev_lesson: /modules/module-1/1-4-advanced-patterns/
prev_title: "Advanced Monitoring Patterns"
next_lesson: /modules/module-2/2-1-slo-definition/
next_title: "SLO Definition Workshop"
---

## Monitoring Is Infrastructure — Treat It Like Infrastructure

Most organizations treat monitoring as a collection of dashboards and alerts that gradually accumulates. After a few years, they have an unmaintainable mix of manually created Grafana panels, Prometheus rules that nobody owns, alerting configs that fire too often or too rarely, and no clear picture of what's actually being monitored.

The solution is to treat monitoring infrastructure the same way you treat production infrastructure: designed, versioned, reviewed, and deployed with the same rigor as your application code.

> **The governing principle**: Your monitoring system should have a known state that can be described as code, deployed reproducibly, and reviewed before changes go to production. If you can't describe what your monitoring system does in code, you don't fully understand it.

---

## The Monitoring Architecture Stack

A complete monitoring architecture has five layers:

{% raw %}
```
┌─────────────────────────────────────────────────┐
│  5. Alerting & Response                         │
│     AlertManager, PagerDuty, OpsGenie           │
├─────────────────────────────────────────────────┤
│  4. Visualization & Dashboards                  │
│     Grafana, custom dashboards                  │
├─────────────────────────────────────────────────┤
│  3. Storage & Query                             │
│     Prometheus, Thanos/Cortex, VictoriaMetrics  │
├─────────────────────────────────────────────────┤
│  2. Collection & Aggregation                    │
│     Prometheus scrape, Telegraf, OpenTelemetry  │
├─────────────────────────────────────────────────┤
│  1. Instrumentation                             │
│     Application metrics, exporters, agents      │
└─────────────────────────────────────────────────┘
```
{% endraw %}

Each layer has distinct design decisions. Changing the storage layer (e.g., migrating from single Prometheus to Thanos) shouldn't require changes to instrumentation. Decisions at each layer should be loosely coupled from decisions at adjacent layers.

---

## Architecture Pattern 1: Single Prometheus

The starting point for most organizations. One Prometheus instance collects all metrics across all services.

{% raw %}
```
Services → Prometheus → Grafana
              ↓
          AlertManager → PagerDuty
```
{% endraw %}

**When it works**: 
- < 500,000 active time series
- Single datacenter / single cloud region
- < 20 engineers contributing monitoring configuration

**When it breaks**:
- Prometheus memory and CPU become bottlenecks (typically > 500K series)
- Multi-region requirements — a US-East Prometheus can't reliably scrape EU-West services
- High availability becomes critical — single Prometheus is a SPOF

**Scaling strategies before moving to federation**:
- Use recording rules to pre-aggregate high-cardinality queries
- Tune scrape intervals (not everything needs 15s)
- Reduce retention period (Prometheus is not long-term storage)
- Move long-term storage to remote write (S3-backed Thanos or Cortex)

---

## Architecture Pattern 2: Federated Prometheus

Multiple Prometheus instances at the "leaf" level (one per service cluster or region), with a "root" Prometheus that federates aggregated data from all leaves.

{% raw %}
```
Cluster A → Prometheus-A ─────────┐
Cluster B → Prometheus-B ─────────┤→ Federation Prometheus → Grafana
Cluster C → Prometheus-C ─────────┘              ↓
                                          AlertManager
```
{% endraw %}

**Key design consideration**: Leaf Prometheus instances handle raw scraping and local alerting. The federation layer handles cross-cluster aggregation and global dashboards. **Don't send high-cardinality raw data through the federation layer** — only pre-aggregated recording rules.

{% raw %}
```yaml
# Federation scrape config — only pull aggregated recording rules
# from leaf instances
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{__name__=~"job:.*"}'  # Only recording rules (aggregates)
    static_configs:
      - targets:
          - 'prometheus-a:9090'
          - 'prometheus-b:9090'
          - 'prometheus-c:9090'
```
{% endraw %}

---

## Architecture Pattern 3: Thanos / Cortex (Long-Term Scalable)

For organizations requiring multi-year retention, high availability, and global query across all regions and clusters.

**Thanos components**:
- **Sidecar**: Runs alongside each Prometheus, ships blocks to object storage (S3/GCS)
- **Store Gateway**: Serves queries against historical data in object storage
- **Querier**: Deduplicates and merges results across all Prometheus instances and Store Gateways
- **Compactor**: Downsamples old data to reduce storage costs
- **Ruler**: Evaluates recording rules and alerts globally

{% raw %}
```
Region A: Prometheus + Thanos Sidecar ─── Object Storage (S3)
Region B: Prometheus + Thanos Sidecar ────────────────────────┘
                                                    ↑
                            Thanos Store Gateway ───┘
                                    ↓
                            Thanos Querier → Grafana
```
{% endraw %}

**When to invest in Thanos**:
- Multi-region deployments where a single Prometheus can't cover all targets
- Compliance requirements for > 2 years metric retention
- Large organizations where independent SRE teams need shared visibility

{% include diagram-embed.html
   title="Monitoring Architecture Evolution — Single to Federated to Thanos"
   src="/modules/module-1/1-5-visuals/diagrams/monitoring-architecture-evolution.html"
   height="520"
%}

---

## Monitoring as Code

### Prometheus Rules as Code

All Prometheus alerting and recording rules should be stored in version control, reviewed via pull request, and deployed through CI/CD:

{% raw %}
```yaml
# File: monitoring/rules/api-service.yml
# Reviewed and merged like any application code
groups:
  - name: api-service.rules
    interval: 30s
    rules:
      # Recording rules — pre-computed aggregations
      - record: job:api_request_rate:5m
        expr: rate(http_requests_total{job="api-service"}[5m])
      
      - record: job:api_error_rate:5m
        expr: >
          rate(http_requests_total{job="api-service",status_code=~"5.."}[5m])
          / rate(http_requests_total{job="api-service"}[5m])
      
      # Alerting rules — use recording rules for efficiency
      - alert: APIServiceHighErrorRate
        expr: job:api_error_rate:5m > 0.01
        for: 5m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "API service error rate {{ $value | humanizePercentage }}"
          runbook: "https://runbooks.example.com/api-high-error-rate"
```
{% endraw %}

### Prometheus Operator (Kubernetes)

In Kubernetes environments, the Prometheus Operator allows teams to define monitoring configuration as Kubernetes custom resources — enabling product teams to own their monitoring without giving them access to the global Prometheus config:

{% raw %}
```yaml
# ServiceMonitor — lets the API team define their own scrape config
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-service-monitor
  namespace: api-team
  labels:
    release: prometheus  # Prometheus Operator discovers this
spec:
  selector:
    matchLabels:
      app: api-service
  endpoints:
    - port: metrics
      interval: 15s
      path: /metrics
```
{% endraw %}

{% raw %}
```yaml
# PrometheusRule — teams own their own alert definitions
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: api-service-alerts
  namespace: api-team
spec:
  groups:
    - name: api-service.alerts
      rules:
        - alert: APIHighLatency
          expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1.0
          for: 5m
          labels:
            severity: warning
```
{% endraw %}

### Grafana as Code

Grafana dashboards are JSON — they should be stored in version control and deployed through CI/CD, not edited manually in the UI:

{% raw %}
```python
# Using grafonnet (Jsonnet library for Grafana)
# dashboards/api-service.jsonnet

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;

dashboard.new(
  'API Service — RED Metrics',
  tags=['api', 'slo'],
  refresh='30s',
)
.addPanel(
  graphPanel.new(
    'Request Rate',
    datasource='Prometheus',
  )
  .addTarget(
    prometheus.target(
      'job:api_request_rate:5m',
      legendFormat='RPS'
    )
  ),
  gridPos={x: 0, y: 0, w: 12, h: 8}
)
```
{% endraw %}

---

## The Three Pillars Integration: Metrics, Logs, Traces

Metrics are one of three observability pillars. A complete architecture integrates all three:

**Metrics** (Prometheus): Aggregated numerical time series. Best for alerting, dashboards, SLO tracking, capacity planning.

**Logs** (Loki, Elasticsearch): Discrete events with full context. Best for debugging specific requests, audit trails, error analysis.

**Traces** (Jaeger, Zipkin, OpenTelemetry): Request flows across service boundaries. Best for latency analysis across distributed systems.

### Correlation Between Pillars

The power comes from being able to move between pillars seamlessly during investigation:

{% raw %}
```
Alert fires (Metrics) → Drill into error rate by endpoint
  → Jump to logs for that endpoint during the anomaly window
    → Find a specific error with a trace ID
      → Open the trace to see exactly which service call is slow/failing
```
{% endraw %}

In Grafana, this correlation is enabled by:
1. **Exemplars**: Points on a metric graph that carry a trace ID — click to jump to the trace
2. **Derived fields**: Regex in log lines that extract trace IDs and link to Jaeger/Zipkin
3. **Unified dashboards**: Correlate metrics panels with log panels and trace panels in a single view

---

## Alerting Architecture

Alert routing — deciding who gets notified about what — is a design problem that's as important as what you alert on.

### AlertManager Routing

{% raw %}
```yaml
# AlertManager config — routes alerts to the right team
route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  receiver: 'default-pagerduty'
  
  routes:
    # Critical SLO alerts → immediate PagerDuty
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: false
    
    # Warning alerts → Slack notification
    - match:
        severity: warning
      receiver: 'slack-warnings'
      continue: true
    
    # Infrastructure alerts → infra team
    - match:
        team: infrastructure
      receiver: 'infra-team-pagerduty'
```
{% endraw %}

### Alert Fatigue Prevention

The most common sign of a broken monitoring architecture is **alert fatigue** — on-call engineers get so many alerts that they start ignoring them. Prevention strategies:

1. **Every alert must be actionable** — if there's no documented response, delete the alert
2. **Group related alerts** — AlertManager's grouping prevents 50 individual alerts from the same underlying cause
3. **Tune `for:` durations** — alerts that require 5-minute confirmation reduce flapping by 90%
4. **Regular alert review** — quarterly audit of alert frequency vs. action taken; delete alerts with no action history

{% include diagram-embed.html
   title="Complete Monitoring Architecture Stack"
   src="/modules/module-1/1-5-visuals/diagrams/complete-monitoring-architecture-stack.html"
   height="560"
%}

---

## Key Takeaways

**1. Start simple, design for evolution.** Single Prometheus works for most teams. Design the instrumentation and configuration layers to be portable so you can swap the storage/query layer later without rebuilding everything.

**2. Monitoring configuration is code.** Version control, code review, and CI/CD for Prometheus rules and Grafana dashboards prevents the monitoring debt that accumulates from manual changes.

**3. The Prometheus Operator enables federated ownership.** Teams can own their monitoring configuration via ServiceMonitors and PrometheusRules without requiring access to global Prometheus config.

**4. Integrate metrics, logs, and traces.** The correlation between pillars — jumping from a metric anomaly to the specific log lines and distributed traces — is where monitoring becomes genuine observability.

**5. Alert routing is a product.** Design it deliberately. The right person needs to be woken up for the right alert at the right time. Alert fatigue is not a technical failure — it's an architecture failure.

---

*You've completed Module 1: Foundations of Monitoring. You now have the taxonomy knowledge, instrumentation skills, and architectural patterns to build monitoring systems that catch real problems — not just the ones you anticipated.*

*Module 2: SLO/SLI Mastery takes these monitoring signals and teaches you to turn them into Service Level Objectives that drive business decisions, error budget policies, and the principled reliability trade-offs that distinguish SRE from ad-hoc operations.*
