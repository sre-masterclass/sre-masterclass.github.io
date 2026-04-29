# Module 2 Examples: SLO/SLI Mastery

**Reference**: SRE Masterclass Specification - Phase 2: SLO/SLI Mastery

## Module 2.1: SLO Definition Workshop Examples

### Complete SLO Definition Framework
```yaml
# E-commerce Checkout SLO Example
slo_definition:
  operation: "A new order is generated, submitted, and acknowledged"
  service_level_indicator: "Latency in seconds from order submitted to order acknowledged"
  aggregation_window: "8 hours"
  target_value: "90% reliability"
  complete_statement: "New orders are acknowledged within one second and achieve this level of service 90% of the time over 8-hour periods"
  
  classification: "windowed latency SLI"
  business_justification: "Order processing is core revenue-generating operation"
  stakeholders: ["Product Manager", "Engineering Lead", "SRE Team"]
```

### SLO Definition Workshop Exercise Templates

#### Payment Processing SLO
```yaml
workshop_exercise_1:
  scenario: "Payment processing service for e-commerce platform"
  stakeholders:
    product_manager:
      concerns: ["user conversion rates", "abandoned carts", "customer satisfaction"]
      constraints: ["processing fees", "fraud prevention", "compliance"]
    
    engineering_lead:  
      concerns: ["system performance", "technical debt", "external dependencies"]
      constraints: ["payment provider APIs", "database performance", "code complexity"]
      
    sre_team:
      concerns: ["system reliability", "incident response", "operational overhead"]
      constraints: ["monitoring capabilities", "alerting fatigue", "on-call burden"]
  
  guided_discussion:
    step_1: "What payment operations matter most to users?"
    step_2: "How do we measure payment processing quality?"
    step_3: "What time window makes sense for payment reliability?"
    step_4: "What reliability target balances user experience with technical constraints?"
    
  expected_outcome:
    operation: "Payment authorization request processed and response returned"
    sli: "Time from payment request to authorization response"
    window: "4 hours"
    target: "95% of payments processed within 3 seconds"
```

### Common SLO Definition Pitfalls
```yaml
pitfall_examples:
  too_many_metrics:
    bad_example: "Monitor latency, throughput, error rate, CPU, memory, and disk space"
    good_example: "Monitor checkout completion latency for user experience"
    lesson: "Focus on user-impacting operations, not internal metrics"
    
  unrealistic_targets:
    bad_example: "99.999% availability for new microservice"
    good_example: "99.5% availability for new microservice, iterate upward"
    lesson: "Start with achievable targets based on current performance"
    
  wrong_time_windows:
    bad_example: "1-minute aggregation windows for seasonal business"
    good_example: "24-hour windows to capture daily usage patterns"
    lesson: "Align windows with business patterns and user expectations"
    
  internal_focus:
    bad_example: "Database connection pool utilization SLO"
    good_example: "User account creation completion SLO"
    lesson: "Measure customer-facing operations, not internal resources"
```

## Module 2.2: SLI Implementation Patterns Examples

### Four SLI Categories Implementation

#### 1. Latency SLI Implementation
```javascript
// Checkout latency SLI
const checkoutLatencySLI = {
  name: 'checkout_latency',
  type: 'latency',
  implementation: {
    // Histogram for percentile calculations
    metric: 'checkout_duration_seconds',
    aggregation: 'histogram',
    slo_threshold: 1.0, // 1 second
    percentile: 95
  },
  
  promql_queries: {
    // Successful requests under threshold
    good_events: `
      histogram_quantile(0.95, 
        rate(checkout_duration_seconds_bucket{status="success"}[5m])
      ) < 1.0
    `,
    
    // Total valid requests (excluding validation errors)
    total_events: `
      rate(checkout_requests_total{status!="validation_error"}[5m])
    `
  }
};
```

#### 2. Availability SLI Implementation
```javascript
// Payment service availability SLI
const paymentAvailabilitySLI = {
  name: 'payment_availability',
  type: 'availability',
  implementation: {
    // Simple binary success/failure
    good_metric: 'payment_requests_total{status="success"}',
    total_metric: 'payment_requests_total'
  },
  
  promql_queries: {
    good_events: `sum(rate(payment_requests_total{status="success"}[5m]))`,
    total_events: `sum(rate(payment_requests_total[5m]))`
  },
  
  health_check: {
    endpoint: '/health',
    expected_response: 200,
    timeout: '5s'
  }
};
```

#### 3. Consistency SLI Implementation  
```javascript
// Cache consistency SLI
const cacheConsistencySLI = {
  name: 'user_data_consistency',
  type: 'consistency',
  implementation: {
    // Measure stale vs fresh data responses
    fresh_metric: 'cache_hits_total{freshness="current"}',
    total_metric: 'cache_hits_total'
  },
  
  consistency_check: {
    operation: 'user_balance_lookup',
    max_staleness: '30s',
    validation_query: `
      (time() - cache_last_update_timestamp) < 30
    `
  },
  
  promql_queries: {
    good_events: `
      sum(rate(cache_hits_total{freshness="current"}[5m]))
    `,
    total_events: `
      sum(rate(cache_hits_total[5m]))
    `
  }
};
```

#### 4. Throughput SLI Implementation
```javascript
// Background job processing throughput SLI
const jobThroughputSLI = {
  name: 'job_processing_throughput',
  type: 'throughput',
  implementation: {
    target_rate: 100, // jobs per second
    measurement_window: '5m'
  },
  
  promql_queries: {
    current_rate: `
      rate(jobs_processed_total{status="completed"}[5m])
    `,
    target_comparison: `
      rate(jobs_processed_total{status="completed"}[5m]) >= 100
    `
  },
  
  capacity_planning: {
    queue_depth_alert: 'job_queue_depth > 1000',
    scaling_trigger: 'rate < 80 AND queue_depth > 500'
  }
};
```

### Sloth Configuration Examples

#### Basic Sloth SLO Configuration
```yaml
# sloth-slo.yml - Prometheus SLO generation
version: "prometheus/v1"
service: "ecommerce-checkout"
labels:
  team: "sre"
  environment: "production"
  
slos:
  - name: "checkout-latency"
    objective: 90
    description: "Checkout processing latency SLO"
    sli:
      events:
        error_query: |
          (
            sum(rate(checkout_requests_total{status!="success"}[{{.window}}])) +
            sum(rate(checkout_success_total{latency_seconds>1}[{{.window}}]))
          )
        total_query: |
          sum(rate(checkout_requests_total[{{.window}}])) -
          sum(rate(checkout_requests_total{status="validation_error"}[{{.window}}]))
    alerting:
      name: CheckoutLatencySLO
      labels:
        severity: warning
        team: sre
      annotations:
        summary: "Checkout latency SLO at risk"
        runbook: "https://runbooks.company.com/checkout-latency"
      page_alert:
        labels:
          severity: critical
        annotations:
          summary: "Checkout latency SLO breached"
```

#### Advanced Multi-Window Sloth Configuration
```yaml
# Multi-window burn rate alerting
version: "prometheus/v1" 
service: "payment-processing"
slos:
  - name: "payment-reliability"
    objective: 99.5
    description: "Payment processing reliability"
    sli:
      events:
        error_query: |
          sum(rate(payment_requests_total{status=~"timeout|error|failed"}[{{.window}}]))
        total_query: |
          sum(rate(payment_requests_total[{{.window}}]))
    alerting:
      name: PaymentReliability
      # Multi-window burn rate alerts
      multiwindow:
        - severity: critical
          for: 2m
          long_window: 1h
          short_window: 5m
          burn_rate_threshold: 14.4
        - severity: warning  
          for: 15m
          long_window: 6h
          short_window: 30m
          burn_rate_threshold: 6
      annotations:
        summary: "Payment processing reliability degraded"
        description: "Error budget burning at {{ $value }}x normal rate"
```

### Log-Based SLI with Loki Examples

#### LogQL Query Patterns
```yaml
# Loki-based SLI extraction
log_based_slis:
  checkout_latency:
    log_query: |
      {job="checkout-service"} 
      |= "checkout_completed" 
      | json 
      | duration < 1000ms
    
    total_query: |
      {job="checkout-service"} 
      |= "checkout_completed" 
      | json
    
    extraction_pattern: |
      count_over_time(
        {job="checkout-service"} 
        |= "checkout_completed" 
        | json 
        | duration < 1000 [5m]
      ) / 
      count_over_time(
        {job="checkout-service"} 
        |= "checkout_completed" 
        | json [5m]
      )
      
  error_rate_from_logs:
    log_query: |
      {job="api-gateway"} 
      |= "request_completed" 
      | json 
      | status_code >= 200 
      | status_code < 500
      
    promtail_config: |
      - job_name: api-gateway
        static_configs:
          - targets:
              - localhost
            labels:
              job: api-gateway
              __path__: /var/log/api-gateway/*.log
        
        pipeline_stages:
          - json:
              expressions:
                timestamp: timestamp
                level: level
                status_code: status_code
                duration: duration_ms
                
          - labels:
              level:
              status_code:
              
          - metrics:
              request_duration:
                type: Histogram
                description: "Request duration from logs"
                source: duration
                config:
                  buckets: [10, 50, 100, 500, 1000, 5000]
```

## Module 2.3: SLO Mathematics & Error Budgets Examples

### SLO Calculation Scenarios

#### Scenario: 8-Hour E-commerce Analysis
```yaml
# Raw data for 8-hour period
measurement_data:
  total_checkout_requests: 110
  validation_errors: 10      # User input issues
  server_side_errors: 10     # Timeouts, exceptions  
  slow_successful_requests: 2  # >1 second latency
  fast_successful_requests: 88 # <1 second latency

calculation_methods:
  method_1_combined_availability_latency:
    description: "Include server errors in denominator"
    formula: "successful_fast_requests / valid_requests"
    calculation: 
      valid_requests: 110 - 10  # Exclude validation errors
      successful_fast: 88
      result: "88 / 100 = 88%"
      slo_target: "90%"
      outcome: "FAILS target (88% < 90%)"
      
  method_2_pure_latency:
    description: "Exclude server errors from denominator" 
    formula: "successful_fast_requests / successful_requests"
    calculation:
      successful_requests: 88 + 2  # All successful requests
      successful_fast: 88
      result: "88 / 90 = 97.8%"
      slo_target: "90%" 
      outcome: "MEETS target (97.8% > 90%)"

decision_framework:
  include_server_errors:
    when: "SLO measures combined availability + performance"
    business_impact: "Reflects true user experience during outages"
    alerting: "Will alert on both performance and availability issues"
    
  exclude_server_errors:
    when: "SLO measures pure performance of working system"
    business_impact: "Separates availability from performance concerns"
    alerting: "Requires separate availability monitoring"
```

### Error Budget Mathematics

#### Error Budget Calculation Examples
```yaml
error_budget_examples:
  high_availability_service:
    slo_target: "99.9%"
    error_budget: "0.1%"
    monthly_budget:
      total_minutes: 43200  # 30 days * 24 hours * 60 minutes
      allowed_downtime: 43.2  # 0.1% of 43200
      budget_remaining_calculation: |
        if actual_availability = 99.95%:
          actual_downtime = 21.6 minutes
          budget_consumed = 21.6 / 43.2 = 50%
          budget_remaining = 50%
          
  medium_availability_service:
    slo_target: "99%"
    error_budget: "1%"
    weekly_budget:
      total_minutes: 10080  # 7 days * 24 hours * 60 minutes  
      allowed_downtime: 100.8  # 1% of 10080
      risk_assessment: |
        budget_remaining > 75%: "Low risk - proceed with deployments"
        budget_remaining 25-75%: "Medium risk - careful with changes"
        budget_remaining < 25%: "High risk - freeze non-critical changes"
```

### Burn Rate Calculations

#### Burn Rate Alert Thresholds
```yaml
burn_rate_calculations:
  # For 99.9% SLO (0.1% error budget)
  critical_burn_rates:
    "1h_window":
      acceptable_errors: "0.1% / 720 = 0.000139%"  # 720 hours in month
      critical_threshold: "14.4x normal rate"
      calculation: "If error rate = 2% for 1 hour"
      burn_rate: "2% / 0.000139% = 14,388x normal"
      budget_consumption: "2% in 1 hour = 20x monthly budget"
      
    "6h_window": 
      acceptable_errors: "0.1% * 6 / 720 = 0.000833%"
      warning_threshold: "6x normal rate"
      calculation: "If error rate = 0.5% for 6 hours" 
      burn_rate: "0.5% / 0.000833% = 600x normal"
      budget_consumption: "50% of monthly budget in 6 hours"

prometheus_burn_rate_rules:
  fast_burn: |
    # Alert if burning budget 14.4x faster than sustainable
    (
      (
        rate(http_requests_total{code=~"5.."}[1h]) /
        rate(http_requests_total[1h])
      ) > (14.4 * 0.001)
    )
    and
    (
      (
        rate(http_requests_total{code=~"5.."}[5m]) /
        rate(http_requests_total[5m])
      ) > (14.4 * 0.001)  
    )
    
  slow_burn: |
    # Alert if burning budget 6x faster than sustainable  
    (
      (
        rate(http_requests_total{code=~"5.."}[6h]) /
        rate(http_requests_total[6h])
      ) > (6 * 0.001)
    )
    and  
    (
      (
        rate(http_requests_total{code=~"5.."}[30m]) /
        rate(http_requests_total[30m])
      ) > (6 * 0.001)
    )
```

### SLO Review and Decision Making Examples

#### Monthly SLO Review Template
```yaml
monthly_slo_review:
  service: "checkout-api"
  period: "October 2024"
  
  slo_performance:
    target: "90% of requests complete within 1 second"
    actual: "94.2%"
    outcome: "EXCEEDED target"
    
  error_budget_status:
    allocated: "10%"
    consumed: "5.8%"
    remaining: "4.2%"
    
  incident_analysis:
    major_incidents: 1
    total_budget_consumed: "3.2%"
    incident_breakdown:
      - date: "2024-10-15"
        duration: "45 minutes"  
        impact: "Payment processing unavailable"
        budget_impact: "3.2%"
        root_cause: "Database connection pool exhaustion"
        
  reliability_investments:
    completed:
      - "Implemented database connection pool monitoring"
      - "Added payment processing circuit breaker"
    planned:
      - "Upgrade database connection pool size"
      - "Implement payment fallback provider"
      
  next_period_decisions:
    slo_target_adjustment: "Maintain 90% target"
    feature_velocity: "Normal deployment cadence approved"
    architecture_changes: "Proceed with payment provider redundancy"
    reasoning: "Exceeded SLO target with comfortable error budget margin"
```