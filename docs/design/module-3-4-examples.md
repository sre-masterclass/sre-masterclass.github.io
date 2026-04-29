# Module 3-4 Examples: Advanced Monitoring & Incident Response

**Reference**: SRE Masterclass Specification - Phase 3: Advanced Monitoring & Phase 4: Incident Response

## Module 3.1: Multi-Window Aggregation Examples

### Seasonal Pattern Detection
```yaml
# Monday deployment pattern analysis
deployment_pattern_analysis:
  observation: "Checkout SLO violations occur Monday 6-9 PM weekly"
  
  aggregation_windows:
    "5_minute_window":
      observation: "Shows individual spikes but misses pattern"
      limitation: "Cannot distinguish normal load from deployment issues"
      
    "1_hour_window": 
      observation: "Shows Monday evening degradation"
      insight: "Correlates with weekly deployment schedule"
      
    "24_hour_window":
      observation: "Reveals weekly pattern across all Mondays"
      insight: "Monday deployments consistently impact user experience"
      
  prometheus_queries:
    weekly_pattern: |
      # Compare Monday performance to rest of week
      avg_over_time(
        checkout_latency_p95[24h] 
        and on() (day_of_week() == 1)
      ) 
      / 
      avg_over_time(
        checkout_latency_p95[24h] 
        and on() (day_of_week() != 1)
      )
      
    deployment_correlation: |
      # Correlate deployment events with SLO performance
      increase(
        deployments_total[1h]
      ) 
      and 
      checkout_slo_compliance < 0.90
```

### Multi-Window SLO Implementation
```yaml
multi_window_slo:
  service: "payment-processing"
  slo_target: "99.5%"
  
  window_configurations:
    real_time_alerting:
      window: "5m"
      purpose: "Immediate incident detection"
      threshold: "95%"  # Lower threshold for fast response
      alert_severity: "critical"
      
    operational_review:
      window: "1h"  
      purpose: "Hourly operational review"
      threshold: "99%"
      alert_severity: "warning"
      
    business_reporting:
      window: "24h"
      purpose: "Daily business metrics"
      threshold: "99.5%" 
      alert_severity: "info"
      
    capacity_planning:
      window: "7d"
      purpose: "Weekly capacity and trend analysis"
      threshold: "99.5%"
      alert_severity: "none"

prometheus_recording_rules: |
  # Multi-window SLO calculations
  groups:
    - name: payment_slo_windows
      interval: 30s
      rules:
        - record: payment_slo:5m
          expr: |
            (
              sum(rate(payment_requests_total{status="success"}[5m])) /
              sum(rate(payment_requests_total[5m]))
            )
            
        - record: payment_slo:1h
          expr: |
            (
              sum(rate(payment_requests_total{status="success"}[1h])) /
              sum(rate(payment_requests_total[1h]))
            )
            
        - record: payment_slo:24h
          expr: |
            (
              sum(rate(payment_requests_total{status="success"}[24h])) /
              sum(rate(payment_requests_total[24h]))
            )
```

## Module 3.2: Anomaly Detection Examples

### SAFE Methodology Implementation
```javascript
// Saturation, Amendments, Anomalies, Failures, Errors monitoring
const SAFEMonitoring = {
  // Saturation monitoring
  saturation: {
    metrics: [
      'payment_queue_depth',
      'database_connection_pool_usage', 
      'cpu_utilization',
      'memory_usage_ratio'
    ],
    
    alerting: {
      payment_queue: {
        warning: 'payment_queue_depth > 100',
        critical: 'payment_queue_depth > 500',
        prediction: 'predict_linear(payment_queue_depth[1h], 3600) > 1000'
      }
    }
  },
  
  // Amendments tracking
  amendments: {
    tracked_events: [
      'deployments',
      'configuration_changes',
      'infrastructure_modifications',
      'manual_interventions'
    ],
    
    correlation_analysis: |
      # Correlate amendments with error rate increases
      increase(deployments_total[10m]) and
      increase(error_rate[10m]) > 0.05
  },
  
  // Anomaly detection
  anomalies: {
    patterns: [
      {
        name: 'unusual_traffic_pattern',
        detection: 'abs(traffic_rate - avg_over_time(traffic_rate[7d])) > 3 * stddev_over_time(traffic_rate[7d])',
        description: 'Traffic deviates significantly from weekly pattern'
      },
      {
        name: 'latency_memory_correlation',
        detection: 'increase(avg_latency[5m]) > 0.5 and increase(memory_usage[5m]) > 0.2',
        description: 'Unexpected correlation between latency and memory usage'
      }
    ]
  },
  
  // Failure pattern detection
  failures: {
    cascade_detection: |
      # Detect cascading failures across services
      (
        increase(payment_errors[5m]) > 10 and
        increase(checkout_errors[5m offset 1m]) > 5 and  
        increase(inventory_errors[5m offset 2m]) > 3
      )
  }
};
```

### Custom Anomaly Detection with Prometheus
```yaml
# Advanced anomaly detection rules
anomaly_detection_rules:
  - alert: UnusualErrorRatePattern
    expr: |
      (
        rate(http_requests_total{code=~"5.."}[10m]) > 
        (
          avg_over_time(
            rate(http_requests_total{code=~"5.."}[10m])[7d:10m]
          ) + 
          3 * stddev_over_time(
            rate(http_requests_total{code=~"5.."}[10m])[7d:10m]
          )
        )
      )
    for: 5m
    annotations:
      summary: "Error rate anomaly detected"
      description: "Error rate {{ $value }} exceeds historical pattern"
      
  - alert: ResourceUtilizationAnomaly  
    expr: |
      (
        abs(
          cpu_usage_percent - 
          avg_over_time(cpu_usage_percent[7d])
        ) > 
        (3 * stddev_over_time(cpu_usage_percent[7d]))
      )
      and
      (
        abs(
          memory_usage_percent - 
          avg_over_time(memory_usage_percent[7d])
        ) > 
        (3 * stddev_over_time(memory_usage_percent[7d]))
      )
    for: 10m
    annotations:
      summary: "Unusual resource utilization pattern"
      description: "Both CPU and memory deviate from normal patterns"
```

## Module 3.3: Capacity Planning Examples

### Predictive Monitoring Implementation
```yaml
capacity_planning_queries:
  # Linear prediction for scaling decisions
  database_connections_prediction: |
    predict_linear(
      avg(db_connections_active)[30m], 
      7200  # 2 hours ahead
    )
    
  # Growth rate analysis
  user_growth_analysis: |
    (
      rate(user_registrations_total[7d]) - 
      rate(user_registrations_total[7d] offset 7d)
    ) / rate(user_registrations_total[7d] offset 7d) * 100
    
  # Seasonal capacity requirements
  seasonal_traffic_forecast: |
    # Compare current hour to same hour last week
    avg_over_time(
      request_rate[1h] 
      and on() (hour() == hour(timestamp() - 7*24*3600))
    )

auto_scaling_triggers:
  scale_up_conditions:
    cpu_based: "avg(cpu_usage) > 70% for 5 minutes"
    latency_based: "p95(response_time) > 2s for 3 minutes"
    queue_based: "avg(queue_depth) > 100 for 2 minutes"
    
  scale_down_conditions:
    conservative_cpu: "avg(cpu_usage) < 30% for 15 minutes"
    latency_safety: "p95(response_time) < 0.5s for 10 minutes"
    minimum_capacity: "instance_count > 2"  # Never scale below minimum
```

## Module 4.1: Proactive Alerting Design Examples

### Alert Severity Classification
```yaml
alert_severity_framework:
  critical:
    definition: "Service completely unavailable or SLO breach imminent"
    response_time: "< 5 minutes"
    examples:
      - "Payment processing down completely"
      - "Error budget will be exhausted in < 1 hour"
      - "Security breach detected"
    escalation: "Immediate page to on-call engineer"
    
  warning:
    definition: "Service degraded or trending toward SLO breach"
    response_time: "< 30 minutes"
    examples:
      - "Latency increased but within SLO"
      - "Error rate elevated but manageable"
      - "Capacity utilization high"
    escalation: "Slack notification to team channel"
    
  info:
    definition: "Informational events for operational awareness"
    response_time: "Next business day"
    examples:
      - "Deployment completed successfully"
      - "Certificate expiring in 30 days"
      - "Weekly SLO report generated"
    escalation: "Email digest or dashboard only"

alerting_best_practices:
  actionable_alerts_only:
    bad_example: "CPU usage > 50%"
    good_example: "CPU usage > 80% AND latency > 2s for 5 minutes"
    reasoning: "Combine resource metrics with user impact"
    
  clear_resolution_steps:
    alert_template: |
      Alert: {{ $labels.alertname }}
      Summary: {{ $annotations.summary }}
      
      Immediate Actions:
      1. Check service dashboard: {{ $annotations.dashboard_url }}
      2. Review runbook: {{ $annotations.runbook_url }}
      3. If no improvement in 10 minutes, escalate to: {{ $annotations.escalation_contact }}
      
      Context:
      - Current value: {{ $value }}
      - Historical baseline: {{ $annotations.baseline }}
      - Related services: {{ $annotations.dependencies }}
```

### Alert Fatigue Prevention
```yaml
alert_fatigue_prevention:
  grouping_strategy:
    # Group related alerts to prevent spam
    prometheus_config: |
      route:
        group_by: ['service', 'alertname']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 12h
        
        routes:
          - match:
              severity: critical
            group_wait: 10s
            repeat_interval: 5m
            
  adaptive_thresholds:
    # Adjust thresholds based on historical patterns
    dynamic_cpu_alert: |
      cpu_usage > (
        avg_over_time(cpu_usage[7d]) + 
        2 * stddev_over_time(cpu_usage[7d])
      )
      
  alert_suppression:
    # Suppress low-priority alerts during incidents
    maintenance_mode: |
      # Suppress non-critical alerts during known maintenance
      absent(maintenance_mode_active) == 0 or severity == "critical"
```

## Module 4.2: Incident Response Workflow Examples

### Grafana OnCall Integration
```yaml
# Grafana OnCall configuration
oncall_configuration:
  escalation_chains:
    payment_service:
      - step: 1
        wait: 5_minutes
        notify: primary_oncall
        
      - step: 2  
        wait: 10_minutes
        notify: secondary_oncall
        
      - step: 3
        wait: 15_minutes  
        notify: engineering_manager
        
  integration_settings:
    prometheus_webhook:
      url: "https://oncall.grafana.net/integrations/v1/prometheus/webhook_id"
      grouping: ["service", "severity"]
      auto_resolution: true
      
  notification_channels:
    slack:
      channel: "#sre-alerts"
      mention_oncall: true
      thread_alerts: true
      
    sms:
      enabled_for: ["critical"]
      carrier: "twilio"
```

### Incident Simulation Scenarios
```yaml
incident_scenarios:
  payment_outage:
    description: "Complete payment processing failure"
    trigger_conditions:
      - "payment_service_availability < 50%"
      - "payment_error_rate > 50%"
    
    simulation_steps:
      1. "Set payment service entropy to 'critical'"
      2. "Observe alert escalation in Grafana OnCall"
      3. "Follow incident response runbook"
      4. "Execute recovery procedure"
      5. "Conduct post-incident review"
    
    expected_alerts:
      - name: "PaymentServiceDown"
        severity: "critical"
        escalation_time: "< 5 minutes"
        
    recovery_steps:
      - "Navigate to entropy dashboard"
      - "Toggle payment service to 'normal'"
      - "Verify service recovery in monitoring"
      - "Update incident status in OnCall"
      
  cascading_failure:
    description: "Checkout failure triggers inventory issues"
    trigger_sequence:
      1. "checkout_service error rate > 25%"
      2. "inventory_service timeouts increase"
      3. "user_auth_service latency spikes"
      
    simulation_implementation: |
      # Entropy configuration for cascading failure
      {
        "scenario": "cascading_failure",
        "timeline": [
          {
            "time": "0s",
            "service": "checkout", 
            "entropy": "error_rate_25"
          },
          {
            "time": "30s",
            "service": "inventory",
            "entropy": "timeout_errors"  
          },
          {
            "time": "90s",
            "service": "auth",
            "entropy": "latency_spike"
          }
        ]
      }
```

### Runbook Automation Examples
```yaml
# Automated runbook integration
runbook_automation:
  payment_service_recovery:
    trigger: "PaymentServiceDown alert fired"
    
    automated_steps:
      - name: "Service Health Check"
        command: "curl -f http://payment-service:8080/health"
        timeout: "30s"
        
      - name: "Database Connectivity"  
        command: "pg_isready -h postgres -p 5432"
        timeout: "10s"
        
      - name: "Redis Cache Check"
        command: "redis-cli -h redis ping"
        timeout: "10s"
        
    manual_steps:
      - "Review application logs for error patterns"
      - "Check external payment provider status"
      - "Verify network connectivity to dependencies"
      
    escalation_criteria:
      - "Automated checks fail after 3 attempts"
      - "Manual intervention required after 15 minutes"
      - "Customer impact confirmed via support tickets"

  self_healing_scenarios:
    high_memory_usage:
      trigger: "container_memory_usage > 90%"
      action: "kubectl delete pod {{ $labels.pod }}"
      verification: "Wait 60s, check memory usage < 80%"
      
    circuit_breaker_activation:
      trigger: "external_service_error_rate > 30%"
      action: "Enable circuit breaker for external service"
      verification: "Check fallback responses functioning"
```

### Post-Incident Analysis Framework
```yaml
post_incident_analysis:
  incident_metadata:
    incident_id: "INC-2024-001"
    start_time: "2024-10-15T18:30:00Z"
    end_time: "2024-10-15T19:15:00Z"
    duration: "45 minutes"
    severity: "critical"
    
  impact_assessment:
    user_impact:
      affected_users: "~15,000 users"
      failed_transactions: "450 payment attempts"
      revenue_impact: "$12,500 estimated"
      
    slo_impact:
      payment_slo_target: "99.5%"
      payment_slo_actual: "94.2%"
      error_budget_consumed: "32% of monthly budget"
      
  timeline_analysis:
    "18:30": "Payment service latency spike detected"
    "18:32": "First alert fired - database connection pool exhaustion"
    "18:35": "On-call engineer paged via Grafana OnCall" 
    "18:40": "Investigation began - database connections at limit"
    "18:45": "Attempted connection pool restart"
    "18:50": "Partial service recovery observed"
    "19:00": "Additional application instances deployed"
    "19:15": "Full service recovery confirmed"
    
  root_cause_analysis:
    primary_cause: "Database connection pool exhaustion"
    contributing_factors:
      - "Monday evening deployment increased connection usage"
      - "Connection pool size not adjusted for new load pattern"
      - "Missing monitoring on connection pool utilization"
      
  action_items:
    immediate:
      - "Increase database connection pool size from 20 to 50"
      - "Add connection pool utilization monitoring"
      - "Update deployment procedures for connection pool validation"
      
    long_term:
      - "Implement connection pool auto-scaling"
      - "Add database performance testing to CI/CD"
      - "Review all service connection pool configurations"
```