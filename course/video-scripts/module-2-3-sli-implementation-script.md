# SRE Masterclass: SLI Implementation Patterns & Technical Approaches
## Complete Video Script - Module 2.3: Production-Ready SLI Instrumentation

---

## Video Overview
**Duration**: 12-15 minutes  
**Learning Objectives**:
- Implement four SLI categories (latency, error rate, availability, throughput) using production-ready patterns in Prometheus
- Configure histogram-based SLI measurement with appropriate bucket boundaries for accurate percentile calculation  
- Validate SLI accuracy under resource constraints using chaos engineering to ensure measurements remain reliable during system stress
- Apply log-based vs metric-based SLI calculation trade-offs for different operational scenarios and data volumes

**Prerequisites**: Students should have completed Module 2.1 (SLO Definition Workshop) and Module 2.2 (Statistical Foundation) and have basic Prometheus query experience

---

## Introduction: Production SLI Implementation Reality (90 seconds)

**[SCREEN: Grafana dashboard showing broken SLI measurements during resource constraints]**

"Welcome to production SLI implementation. Today we're going to build Service Level Indicators that actually work when your systems are under stress - because SLIs that work in demos but fail in production are worse than no SLIs at all.

**[POINT to dashboard showing inconsistent metrics during high load]**

You're looking at a real production problem: SLI measurements that look perfect during normal operation but become completely unreliable the moment your system experiences resource pressure. Notice how latency percentiles spike unrealistically and error rates show impossible values during memory constraints.

Here's what makes this different from typical SLI tutorials: We're not just going to calculate percentiles - we're going to build **production-ready instrumentation** that remains accurate when your infrastructure is struggling. That means proper histogram configuration, resource-aware measurement, and chaos-validated accuracy.

**[PREVIEW: Show final working SLI dashboard remaining stable during chaos scenario]**

Let me show you what we're building: SLI measurements that maintain accuracy even during resource exhaustion. Notice how our latency SLIs show realistic degradation patterns, error rates remain mathematically consistent, and availability measurements correctly reflect service health. This is how you implement SLIs that operations teams can actually trust."

---

## Part 1: Environment Setup & SLI Foundation (2-3 minutes)

### Production Environment Preparation (90-120 seconds)

**[SCREEN: Terminal showing SRE masterclass e-commerce system status]**

"First, let's verify our production-like environment. I'm starting with our e-commerce microservices system that includes Prometheus, Grafana, and realistic traffic patterns.

**[TYPE: Environment validation commands]**

```bash
# Step 1: Verify all services are healthy
docker-compose ps

# Step 2: Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Step 3: Validate baseline metrics collection
curl http://localhost:9090/api/v1/query?query=up
```

**[PAUSE after each command to show healthy service status]**

Notice that we're starting with a **realistic production topology**:
- **Multiple microservices**: E-commerce API, payment service, job processor - each with different latency and error characteristics
- **Prometheus service discovery**: Automatic target detection, not hardcoded endpoints
- **Traffic simulation**: Built-in load generation that creates realistic SLI patterns

**[VERIFY: Show Prometheus targets are all healthy]**

Perfect. We now have a production-ready environment that matches what you'd deploy in a multi-service architecture."

### SLI Categories & Measurement Approaches (60-90 seconds)

**[SCREEN: Prometheus query interface showing existing metrics]**

"Now let's examine our SLI foundation. In production SRE work, we implement the Four Golden Signals using specific measurement patterns that scale and remain accurate under load.

**[SHOW: Current metric instrumentation in Prometheus]**

```promql
# View current HTTP instrumentation
{__name__=~"http_.*"}

# Check histogram bucket configuration  
http_request_latency_seconds_bucket{job="ecommerce-api"}
```

**[EXPLAIN the Four Golden Signals mapping]**

Let me show you how we map SLI categories to measurement approaches:

**[HIGHLIGHT: Latency measurement patterns]**
- **Latency SLI**: Histogram-based percentile calculation using `histogram_quantile()`
- **Why histograms**: Aggregatable across services, memory-efficient, mathematically accurate
- **Bucket configuration**: Tailored to e-commerce latency patterns (50ms to 10s range)

**[HIGHLIGHT: Error rate measurement patterns]**  
- **Error Rate SLI**: Success ratio using HTTP status code classification
- **4xx vs 5xx handling**: Client errors don't count against SLI, server errors do
- **Rate function**: Proper time window selection for stable measurements

**[HIGHLIGHT: Availability measurement patterns]**
- **Availability SLI**: Service uptime using Prometheus `up{}` metric plus request success correlation
- **Health check integration**: Synthetic monitoring aligned with real user request patterns
- **Multi-instance aggregation**: Availability calculation across service replicas

**[HIGHLIGHT: Throughput measurement patterns]**
- **Throughput SLI**: Request rate using `rate()` function with capacity planning integration
- **Peak vs sustained**: Different measurement windows for different operational needs

This measurement foundation is battle-tested at companies like Google and scales to millions of requests per second."

---

## Part 2: Hands-On SLI Implementation (4-6 minutes)

### Latency SLI Implementation (120-180 seconds)

**[SCREEN: Prometheus query interface with latency histogram queries]**

"Now let's implement latency SLIs using production-ready histogram patterns. We'll start with percentile calculation and build it using histogram buckets that remain accurate under load.

**[CODE: Latency SLI queries]**

```promql
# 95th percentile latency SLI (already in our recording rules)
histogram_quantile(0.95, 
  sum(rate(http_request_latency_seconds_bucket[5m])) by (le, job)
)

# 99th percentile for more sensitive detection
histogram_quantile(0.99, 
  sum(rate(http_request_latency_seconds_bucket[5m])) by (le, job)
)

# Multi-service latency aggregation
histogram_quantile(0.95,
  sum(rate(http_request_latency_seconds_bucket{job=~"ecommerce-api|payment-api"}[5m])) by (le)
)
```

**[EXPLAIN implementation line by line for critical sections]**

Let me break down the production patterns here:

**[HIGHLIGHT: Histogram bucket analysis]**
```promql
# Check current bucket distribution
http_request_latency_seconds_bucket{job="ecommerce-api"}
```
Notice our bucket boundaries: 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10 seconds. This configuration captures e-commerce latency patterns accurately - fast responses in microsecond precision, slower responses with appropriate granularity.

**[HIGHLIGHT: Rate function usage]**
The `rate()` function with 5-minute windows provides stable measurements that don't fluctuate with temporary traffic spikes. In production, shorter windows (1m) give faster detection but more noise, longer windows (15m) are more stable but slower to detect issues.

**[HIGHLIGHT: Multi-service aggregation]**
```promql
sum(rate(http_request_latency_seconds_bucket{job=~"ecommerce-api|payment-api"}[5m])) by (le)
```
This pattern aggregates histograms across services before calculating percentiles - mathematically correct and gives you end-to-end user experience measurement."

### Error Rate & Availability SLI Implementation (120-180 seconds)

**[SCREEN: Continue with error rate and availability queries]**

"Next, let's add error rate and availability SLIs. These measurements need to handle the complexity of distributed systems where errors and downtime have different meanings.

**[CODE: Error rate SLI implementation]**

```promql
# Error rate SLI (5xx errors only - already in recording rules)
sum(rate(http_requests_total{http_status=~"5.."}[5m])) by (job) / 
sum(rate(http_requests_total[5m])) by (job)

# Success rate (inverse of error rate) 
1 - (
  sum(rate(http_requests_total{http_status=~"5.."}[5m])) by (job) / 
  sum(rate(http_requests_total[5m])) by (job)
)

# Availability SLI combining uptime and request success
avg_over_time(up{job="ecommerce-api"}[5m]) * 
(1 - (sum(rate(http_requests_total{http_status=~"5.."}[5m])) by (job) / 
      sum(rate(http_requests_total[5m])) by (job)))
```

**[DEMONSTRATE: Query results against live system]**

```bash
# Check current error rates across services
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=job:slo:http_error_rate:5m'
```

**[POINT to query results showing normal error rates]**

Perfect! Our error rates show typical production patterns:
- **E-commerce API**: ~0.1% error rate (very reliable)
- **Payment API**: ~0.2% error rate (slightly higher due to external dependencies)
- **Job Processor**: Near 0% (background processing is more predictable)

**[EXPLAIN: Production error classification]**

Critical production pattern: we only count 5xx errors against SLIs because:
- **4xx errors**: Client mistakes, not service reliability issues
- **5xx errors**: Service failures that impact user experience
- **Rate calculation**: 5-minute windows smooth out temporary spikes while detecting real trends

**[CODE: Availability measurement patterns]**

```promql
# Service uptime measurement
avg_over_time(up{job="ecommerce-api"}[5m])

# Request-based availability (successful requests / total requests)
sum(rate(http_requests_total{http_status!~"5.."}[5m])) by (job) /
sum(rate(http_requests_total[5m])) by (job)
```

This dual approach catches both infrastructure failures (service down) and application failures (service up but returning errors)."

### Throughput SLI Implementation (60-120 seconds)

**[SCREEN: Throughput measurement and capacity correlation]**

"Finally, let's implement throughput SLIs that connect request volume to system capacity. In production, throughput SLIs help with capacity planning and performance regression detection.

**[CODE: Throughput SLI queries]**

```promql
# Current request rate (requests per second)
sum(rate(http_requests_total[5m])) by (job)

# Peak throughput over longer period
max_over_time(sum(rate(http_requests_total[1m])) by (job)[1h:1m])

# Throughput efficiency (successful requests per second)
sum(rate(http_requests_total{http_status!~"5.."}[5m])) by (job)
```

**[RUN: Show current throughput metrics]**

```bash
# Check current system throughput
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_requests_total[5m])) by (job)'
```

**[SHOW: Throughput results across services]**

Our traffic simulator is generating realistic patterns:
- **E-commerce API**: ~2-3 requests/second (typical small e-commerce)
- **Payment API**: ~0.5 requests/second (subset of e-commerce transactions)
- **Background processing**: Different measurement approach using job completion rates

**[EXPLAIN: Capacity planning integration]**

```promql
# Throughput capacity utilization
(sum(rate(http_requests_total[5m])) by (job) / 
 scalar(max_over_time(sum(rate(http_requests_total[1m])) by (job)[7d:1m]))) * 100
```

This pattern shows current throughput as a percentage of historical peak - essential for capacity planning and performance regression detection."

---

## Part 3: SLI Accuracy Validation & Chaos Integration (2-3 minutes)

### Baseline Measurement Capture (60-90 seconds)

**[SCREEN: Grafana dashboard showing current SLI baselines]**

"Now let's validate our SLI implementation works correctly. In production, SLI accuracy validation is critical because incorrect measurements lead to false SLO breaches and operational panic.

**[SHOW: Current SLI measurements across all categories]**

```bash
# Capture baseline SLI measurements
echo "=== Latency SLIs ==="
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=job:slo:http_request_latency_seconds:95p'

echo "=== Error Rate SLIs ==="
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=job:slo:http_error_rate:5m'

echo "=== Availability SLIs ==="
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=job:slo:availability:up'

echo "=== Throughput SLIs ==="
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_requests_total[5m])) by (job)'
```

**[POINT to baseline measurements]**

Excellent! Our baseline shows healthy system behavior:
- **Latency**: 95th percentile around 100-200ms for API requests
- **Error Rate**: Less than 0.5% across all services
- **Availability**: 100% uptime with request success correlation
- **Throughput**: Stable request rates matching traffic simulator patterns

**[INTRODUCE: Chaos testing rationale]**

Now here's the critical test: **Do these SLI measurements remain accurate when the system is under stress?** Many SLI implementations break down during resource constraints, giving operations teams false confidence or false alarms."

### Memory Exhaustion Chaos Scenario (90-120 seconds)

**[SCREEN: Entropy engine chaos trigger interface]**

"Let's validate SLI accuracy using memory exhaustion - a common production failure mode that often corrupts SLI measurements.

**[TRIGGER: Memory exhaustion chaos scenario]**

```bash
# Trigger memory exhaustion scenario on e-commerce API
curl -X POST http://localhost:8001/scenarios/memory-exhaustion/start

# Monitor the scenario progression
curl http://localhost:8001/scenarios/memory-exhaustion/status
```

**[OBSERVE: System behavior during chaos in real-time]**

Watch how our system responds to progressive memory constraint:
- **Phase 1** (512MB limit): Slight latency increase, error rates stable
- **Phase 2** (256MB limit): More noticeable latency degradation, occasional errors
- **Phase 3** (128MB limit): Significant performance impact, higher error rates

**[SHOW: SLI measurements during chaos]**

```promql
# Real-time SLI behavior during memory exhaustion
histogram_quantile(0.95, sum(rate(http_request_latency_seconds_bucket{job="ecommerce-api"}[1m])) by (le))
```

**[POINT to SLI accuracy during stress]**

Critical observation: Our SLI measurements **remain mathematically consistent** during resource constraints:
- **Latency SLIs**: Show realistic degradation (200ms → 500ms → 2s) rather than impossible spikes
- **Error Rate SLIs**: Increase proportionally to actual failures, not measurement artifacts
- **Availability SLIs**: Correctly reflect service health degradation
- **Throughput SLIs**: Show capacity reduction due to resource constraints

**[HIGHLIGHT: Production pattern validation]**

This is exactly what you want in production: SLI measurements that accurately reflect system behavior under stress, enabling proper SLO evaluation and incident response."

---

## Part 4: Production Deployment & Monitoring Integration (2-3 minutes)

### Prometheus Recording Rules Configuration (90-120 seconds)

**[SCREEN: Prometheus recording rules configuration file]**

"Now let's prepare these SLI queries for production deployment. Ad-hoc queries are fine for exploration, but production SLI measurement requires recording rules for performance and consistency.

**[SHOW: Current recording rules configuration]**

```yaml
# monitoring/prometheus/rules/slo_rules.yml
groups:
- name: slo_rules
  interval: 30s
  rules:
  # Latency recording rules
  - record: job:slo:http_request_latency_seconds:95p
    expr: histogram_quantile(0.95, sum(rate(http_request_latency_seconds_bucket[5m])) by (le, job))
  - record: job:slo:http_request_latency_seconds:99p
    expr: histogram_quantile(0.99, sum(rate(http_request_latency_seconds_bucket[5m])) by (le, job))

  # Error rate recording rules  
  - record: job:slo:http_error_rate:5m
    expr: sum(rate(http_requests_total{http_status=~"5.."}[5m])) by (job) / sum(rate(http_requests_total[5m])) by (job)

  # Availability recording rules
  - record: job:slo:availability:up
    expr: up{job=~"ecommerce-api|auth-api|payment-api|job-processor|entropy-engine"}
```

**[EXPLAIN: Recording rule patterns]**

Production recording rule patterns:

**[HIGHLIGHT: Naming convention]**
- **job:slo:metric:aggregation**: Hierarchical naming that indicates scope and purpose
- **Evaluation interval**: 30 seconds balances accuracy with Prometheus performance
- **Retention**: Recording rules create new time series that follow retention policies

**[HIGHLIGHT: Performance considerations]**
```yaml
# Resource management for high-cardinality environments
- record: job:slo:http_error_rate:5m
  expr: sum(rate(http_requests_total{http_status=~"5.."}[5m])) by (job) / sum(rate(http_requests_total[5m])) by (job)
```
Notice we aggregate `by (job)` rather than keeping all labels - this prevents cardinality explosion while maintaining operational utility.

**[DEPLOY: Recording rules update]**

```bash
# Validate recording rule syntax
promtool check rules monitoring/prometheus/rules/slo_rules.yml

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

**[VERIFY: Recording rules are working]**

```bash
# Check that recording rules are generating metrics
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=job:slo:http_request_latency_seconds:95p'
```

Perfect! Our recording rules are now generating SLI metrics every 30 seconds with production-appropriate performance characteristics."

### Grafana Dashboard & Alert Integration (60-120 seconds)

**[SCREEN: Grafana SLI dashboard configuration]**

"Final step: integrate our SLI measurements with operational dashboards and SLO burn rate alerting. This connects SLI measurement to actual operational workflows.

**[SHOW: SLI dashboard panels]**

Our SLI dashboard shows:
- **Latency trends**: 95th and 99th percentile over time with SLO threshold lines
- **Error rate tracking**: Current error rate vs SLO budget consumption
- **Availability correlation**: Uptime vs request success rate comparison
- **Throughput capacity**: Current vs historical peak with capacity planning context

**[DEMONSTRATE: SLO burn rate alert integration]**

```yaml
# Alert rules that use our SLI recording rules
- alert: HighErrorRate_1h
  expr: job:slo:http_error_rate:5m > (14.4 * (1-0.99))
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "High error rate on {{ $labels.job }} (1h window)"
```

**[POINT to alert calculation]**

This alert uses our SLI recording rule `job:slo:http_error_rate:5m` and compares it to the mathematical burn rate threshold for a 99% SLO over 30 days. The `14.4` multiplier represents the 1-hour error budget consumption rate that would exhaust a 30-day budget.

**[SHOW: Multi-environment consistency]**

In production deployments, these same SLI patterns work across:
- **Development**: Same queries, different thresholds  
- **Staging**: Production-like measurement, pre-production validation
- **Production**: Full implementation with operational alerting

The SLI implementation remains consistent while operational thresholds adapt to environment requirements."

---

## Part 5: Troubleshooting & Production Operations (1-2 minutes)

### Common SLI Implementation Issues (45-90 seconds)

**[SCREEN: Common SLI problems and solutions]**

"Before we wrap up, let's cover the most common production issues you'll encounter with SLI implementation and how to resolve them systematically.

**Issue 1: Histogram Bucket Misconfiguration**
- **Symptoms**: Percentile calculations showing impossible values (negative latency, >100% error rates)
- **Root cause**: Bucket boundaries don't match actual latency distribution
- **Solution**: Analyze actual latency patterns and adjust bucket configuration
- **Prevention**: Use `rate(http_request_latency_seconds_sum[5m]) / rate(http_request_latency_seconds_count[5m])` to validate average latency makes sense

**Issue 2: Cardinality Explosion in Recording Rules**
- **Symptoms**: Prometheus memory usage growing rapidly, query performance degrading
- **Diagnosis**: Check `prometheus_tsdb_symbol_table_size_bytes` and `prometheus_engine_queries_concurrent_max`
- **Solution**: Reduce label cardinality in recording rules using appropriate `by()` clauses
- **Optimization**: Use separate recording rules for different aggregation levels

**Issue 3: Rate Function Time Window Issues**
- **Symptoms**: SLI measurements showing excessive noise or missing important events
- **Troubleshooting**: Compare 1m, 5m, and 15m rate windows for same metric
- **Resolution**: Match rate window to detection speed requirements (1m for fast detection, 5m for stability, 15m for trending)
- **Monitoring**: Alert on rate of change in SLI measurements to detect configuration drift

**[POINT to troubleshooting resources]**

The course materials include a complete troubleshooting guide covering cardinality analysis, query optimization, and SLI validation procedures for production deployments."

### Next Steps & Production Scaling (30-45 seconds)

**[SCREEN: SLI implementation scaling roadmap]**

"You now have production-ready SLI implementation patterns that remain accurate under system stress. Here are the logical next steps for scaling this to enterprise production:

**Immediate extensions**:
- **Multi-region SLI aggregation**: Combine SLI measurements across geographic deployments
- **Service dependency SLIs**: Measure SLIs for service-to-service communication patterns
- **Custom business logic SLIs**: Extend patterns to business-specific reliability measurements

**Advanced capabilities**:
- **Automated SLI validation**: Continuous testing that SLI measurements remain mathematically consistent
- **SLI-driven capacity planning**: Use SLI trends to predict infrastructure scaling needs
- **Cross-team SLI sharing**: Standardize SLI patterns across multiple engineering teams

In our next lesson, Module 2.4, we'll build on these SLI implementations to create error budget mathematics and multi-window burn rate alerting that transforms SLI measurements into actionable operational intelligence."

---

## Part 6: Key Takeaways & Production Best Practices (45-60 seconds)

### Implementation Best Practices (30-45 seconds)

**[SCREEN: Return to final SLI dashboard showing chaos recovery]**

"Let's summarize the production SLI implementation patterns we've covered:

**First**: **Measurement accuracy under stress** - We implemented SLIs using histogram buckets and rate functions that remain mathematically consistent during resource constraints and system degradation.

**Second**: **Production-appropriate aggregation** - Our recording rules balance measurement precision with Prometheus performance using proper cardinality management and evaluation intervals.

**Third**: **Chaos-validated reliability** - Every SLI measurement was tested under realistic failure conditions to ensure accuracy when operations teams need it most.

**Fourth**: **Operational integration** - Our SLI implementation connects directly to burn rate alerting, capacity planning, and incident response workflows.

**Fifth**: **Multi-service scalability** - The patterns work across microservice architectures and aggregate correctly for end-to-end user experience measurement."

### Production SLI Implementation Checklist (15-30 seconds)

"When you implement SLI measurement in your environment, use this checklist:

- [ ] Histogram bucket boundaries match actual latency distribution patterns
- [ ] Error rate calculation excludes client errors (4xx) and includes only service errors (5xx)  
- [ ] Availability measurement combines infrastructure uptime with request success correlation
- [ ] Throughput measurement connects to capacity planning and performance regression detection
- [ ] Recording rules use appropriate cardinality management and evaluation intervals
- [ ] SLI accuracy validated under realistic system stress and resource constraints
- [ ] Alerting integration uses mathematically correct burn rate calculation
- [ ] Dashboard integration provides operational context for SLI trend analysis

Remember: **Production SLI implementation is about measurement accuracy when your systems are failing, not just when they're healthy. Chaos engineering validation is essential for operational confidence.**"

---

## Video Production Notes

### Visual Flow and Timing

**SLI Implementation Demonstration Sequence**:
1. **0:00-1:30**: Introduction showing broken vs reliable SLI measurements
2. **1:30-4:30**: Environment validation and SLI foundation explanation
3. **4:30-10:30**: Hands-on implementation of all four SLI categories
4. **10:30-13:30**: Chaos engineering validation and production deployment  
5. **13:30-15:00**: Troubleshooting guidance and implementation best practices

### Critical Visual Moments

**SLI Accuracy Revelation Points**:
- **2:00**: Environment showing realistic multi-service topology - "This is production-scale complexity"
- **5:00**: Histogram bucket configuration - "This prevents percentile calculation errors"
- **8:30**: Real-time SLI behavior during chaos - "This validates measurement accuracy under stress"
- **11:00**: Recording rule performance - "This enables production-scale SLI calculation"

**Emphasis Techniques**:
- Use Prometheus query interface to show actual query execution and results
- Split-screen view showing SLI measurements vs system behavior during chaos
- Zoom in on specific bucket boundaries and rate calculation parameters
- Highlight mathematical relationships between SLI measurements and SLO thresholds

### Educational Hooks

**Production Confidence Building**:
- Start with realistic production environment that students can replicate
- Show working SLI queries that execute against actual metrics
- Demonstrate SLI behavior under real system stress conditions
- Provide troubleshooting guidance for common implementation issues

**Mathematical Understanding**:
- Students learn histogram_quantile() vs raw percentile calculation trade-offs
- Recognition of rate() function time window impact on measurement stability
- Understanding of cardinality management in high-scale environments
- Building intuition for SLI accuracy validation and measurement consistency

### Technical Accuracy Notes

**Query Validation**:
- All Prometheus queries tested against running SRE masterclass environment
- Recording rules validated for syntax and performance characteristics
- Chaos scenario produces measurable, consistent SLI behavior changes
- Grafana dashboard integration displays SLI data with appropriate time windows

**Implementation Fidelity**:
- Histogram bucket configuration: Matches e-commerce API latency patterns from traffic simulation
- Error rate calculation: Uses actual HTTP status code patterns from microservices
- Availability measurement: Integrates with service discovery and health check patterns
- Chaos integration: Memory exhaustion scenario produces realistic system degradation

### Follow-up Content Integration

**Module 2.4 Setup**:
This SLI implementation perfectly prepares students for:
- Error budget mathematics using these SLI measurements
- Multi-window burn rate alerting based on SLI recording rules
- SLO threshold optimization using historical SLI trend analysis
- Operational runbook development for SLI-based incident response

**Practical Application Support**:
- SLI implementation checklist for student production environments
- Troubleshooting guide for common Prometheus cardinality and performance issues
- Recording rule template library for different service architectures
- Chaos scenario integration patterns for SLI accuracy validation

### Assessment Integration

**Technical Knowledge Validation**:
Students should be able to:
- Implement histogram-based latency SLI measurement with appropriate bucket configuration
- Configure error rate SLI calculation that handles HTTP status code classification correctly
- Set up availability SLI that combines infrastructure uptime with request success patterns
- Create throughput SLI that connects to capacity planning and performance monitoring

**Production Application**:
- Adapt SLI patterns to their specific service architecture and latency characteristics
- Apply recording rule performance optimization to their Prometheus deployment scale
- Integrate SLI measurements with their existing alerting and dashboard infrastructure
- Validate SLI accuracy using chaos engineering appropriate to their failure modes

---

## Instructor Notes

### Common Student Questions

**Q: "How do I choose the right histogram bucket boundaries for my service latency patterns?"**
A: "Analyze your actual latency distribution using `rate(http_request_latency_seconds_sum[5m]) / rate(http_request_latency_seconds_count[5m])` for average latency, then use bucket boundaries that provide 2-3 buckets below your 50th percentile, 2-3 buckets between 50th and 95th percentile, and 2-3 buckets above 95th percentile. The key is matching bucket density to where your actual measurements fall."

**Q: "Should I use different rate() time windows for different SLI categories?"**
A: "Yes, match the time window to your detection speed requirements. Latency SLIs often use 5m windows for stability, error rate SLIs might use 2m windows for faster detection, availability SLIs might use 1m windows for rapid incident detection. The trade-off is detection speed vs measurement noise."

**Q: "How do I prevent cardinality explosion when aggregating SLI measurements across many services?"**
A: "Use hierarchical recording rules - create service-level SLI measurements first, then create aggregate measurements from those. Use `by (job)` or `by (service)` clauses rather than keeping all labels. Consider using separate recording rules for different operational needs rather than one rule trying to serve all use cases."

### Extension Activities

**For Advanced Students**:
- Implement multi-region SLI aggregation patterns for geographically distributed services
- Create custom SLI measurements for business logic reliability (e.g., order completion success rate)
- Develop automated SLI validation that continuously tests measurement accuracy
- Design SLI-driven capacity planning that uses trend analysis for infrastructure scaling

**For Practical Application**:
- Adapt SLI implementation patterns to student's specific technology stack and service architecture
- Implement SLI recording rules optimized for student's Prometheus scale and cardinality requirements
- Create organization-specific SLI troubleshooting procedures and operational runbooks
- Design training materials for spreading SLI implementation knowledge across engineering teams

This hands-on script provides comprehensive, production-tested SLI implementation guidance while maintaining technical accuracy and operational relevance for real-world SRE practice.
