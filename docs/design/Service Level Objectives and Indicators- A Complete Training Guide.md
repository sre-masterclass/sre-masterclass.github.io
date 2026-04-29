# Service Level Objectives and Indicators: A Complete Training Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Understanding SLOs: Foundations](#understanding-slos-foundations)
3. [Building Your First SLO: E-commerce Example](#building-your-first-slo-e-commerce-example)
4. [Service Level Indicators (SLIs): The Four Categories](#service-level-indicators-slis-the-four-categories)
5. [Implementation: From Planning to Code](#implementation-from-planning-to-code)
6. [Operations: Dashboards and Visualization](#operations-dashboards-and-visualization)
7. [SLO Mathematics and Calculations](#slo-mathematics-and-calculations)
8. [Understanding and Acting on SLO Data](#understanding-and-acting-on-slo-data)
9. [Advanced Concepts: Burn Rate and Error Budgets](#advanced-concepts-burn-rate-and-error-budgets)
10. [Common Objections and Best Practices](#common-objections-and-best-practices)

---

## Introduction

Service Level Objectives (SLOs) are quantifiable targets that provide a vocabulary for specifying the exact level of service expected from software systems. They help teams build reliable software by establishing measurable reliability commitments from a customer's perspective.

**Key Questions SLOs Help Answer:**
- How reliable is our system from the user's perspective?
- Are we providing the level of service our customers expect?
- How reliable is it to create a new user account?
- How reliable is our payment processing system?

**Learning Objectives:**
- Define and implement SLOs for critical business operations
- Understand and categorize Service Level Indicators (SLIs)
- Create operational dashboards for SLO monitoring
- Apply SLO mathematics for reliability calculations
- Develop data-driven reliability strategies

---

## Understanding SLOs: Foundations

### What Are SLOs?

SLOs are **reliability commitments from a customer's perspective**. They transform informal reliability conversations into formal, measurable targets that can be tracked and improved over time.

### The Software Delivery Lifecycle and SLOs

Software delivery occurs in four phases, and SLOs impact each:

1. **Planning**: SLOs begin here - reliability conversations happen during feature planning
2. **Implementing**: SLO requirements influence technical design and architecture
3. **Operating**: SLO data is collected, visualized, and monitored
4. **Understanding**: SLO performance is analyzed to inform future decisions

### Why SLOs Matter

- **Formalize reliability discussions** between teams
- **Provide measurable targets** rather than subjective assessments
- **Enable data-driven decisions** about system reliability
- **Focus on user-impacting operations** rather than internal metrics
- **Create accountability** for reliability commitments

---

## Building Your First SLO: E-commerce Example

SLO definition is always a **collaborative exercise** involving product owners, developers, and architects.

### The Five Components of an SLO

Every SLO requires five elements:

#### 1. Operation
**Example**: "A new order is generated, submitted, and acknowledged"

This should be a customer-facing operation important enough to warrant measurement. Focus only on operations that matter to users.

#### 2. Service Level Indicator (SLI)
**Example**: "Latency in seconds from order submitted to order acknowledged"

This is the actual measurable data collected from the system. The SLI must be obtainable from logs, telemetry, or other data sources.

#### 3. Aggregation Window
**Example**: "8 hours"

SLOs focus on reliability trends, not individual errors. Aggregation windows should be meaningful to the business and can help identify patterns (e.g., Monday evening deployment issues).

#### 4. Target Value
**Example**: "90% reliability"

Accept some unreliability - 100% reliable systems are impossible. Typically use "nines" (90%, 99%, 99.9%, etc.). Higher targets may require significant architectural changes.

#### 5. Complete SLO Statement
**Example**: "New orders are acknowledged within one second and achieve this level of service 90% of the time"

This is the final, succinct definition combining all previous elements.

### SLO Classification

Our example represents a **windowed latency SLI** - we're measuring the reliability of order processing using latency as the key metric within a specific time window.

---

## Service Level Indicators (SLIs): The Four Categories

Based on "Database Reliability Engineering," SLIs fall into four basic categories:

### 1. Latency SLIs

**Definition**: Measurement of delay in communications flow

**Examples**:
- Elapsed time between API request and response
- Delay between message sent and acknowledgment received
- Time to create a new user account (1-2 seconds)

**Measurement**: Units of time, typically with upper boundaries, sometimes with lower bounds to avoid over-engineering

### 2. Availability SLIs

**Definition**: Simple measurement of whether a service is available for valid requests

**Examples**:
- Health check endpoint responses (ping/pong)
- Service uptime percentage
- Banking system availability during business hours

**Measurement**: Boolean (available/unavailable), useful for detecting downtime trends

### 3. Consistency SLIs

**Definition**: Measurement of data quality - do users receive expected data?

**Examples**:
- Cache freshness (bank balance after deposit)
- Data synchronization across systems
- Transaction history updates

**Use Case**: Often combined with other SLIs (e.g., "users see check deposits in transaction history within 2 seconds")

### 4. Throughput SLIs

**Definition**: Measurement of volume processing capability

**Examples**:
- Transactions processed per second
- Bytes streamed per second
- Batch processing rates

**Applications**: High-volume systems like streaming platforms, payment processors

---

## Implementation: From Planning to Code

### Development Impact

SLOs influence the **implementing phase** of software delivery:

- **Basic Level**: Ensure SLIs are available in logs or operational data
- **Advanced Level**: SLO targets may require architectural changes
- **Critical**: 99.999% reliability targets often demand significant infrastructure modifications

### Implementation Strategy

**First Goal**: Get actual reliability under measurement before making architectural changes

**Process**:
1. Add SLIs to code iteratively
2. Connect SLIs to operational visibility tools (Prometheus, etc.)
3. Validate data collection before optimization

### Code Example: E-commerce Checkout

```javascript
function processOrder(orderData) {
    // Log all checkout requests
    logger.info("checkout_request_total");
    
    // Start latency timer
    const startTime = Date.now();
    
    try {
        // Validate credit card
        validateCreditCard(orderData.payment);
        
        // Validate address
        validateAddress(orderData.shipping);
        
        // Process order
        const result = processOrderWithValidation(orderData);
        
        // Calculate latency
        const latency = Date.now() - startTime;
        
        // Log successful request with latency
        logger.info(`checkout_success_total latency=${latency}ms`);
        
        return result;
        
    } catch (ValidationException e) {
        // Log validation errors separately
        logger.error(`checkout_validation_error: ${e.message}`);
        throw e;
        
    } catch (ServiceException e) {
        // Log service errors
        logger.error(`checkout_service_error: ${e.message}`);
        throw e;
    }
}
```

### Key Logging Requirements

1. **Total checkout requests** - overall volume
2. **Successful requests with latency** - for SLO calculation
3. **Validation errors** - excluded from SLO (user input issues)
4. **Service errors** - included in SLO (system failures)

---

## Operations: Dashboards and Visualization

### Prometheus and Sloth

**Sloth** converts simple SLO spec files into Prometheus rules, saving significant implementation time.

**Benefits**:
- Built-in SLI plugins for common services (CoreDNS, Istio, Kubernetes)
- Automated Prometheus rule generation
- Integration with Prometheus AlertManager for notifications

### Sample Sloth Specification

```yaml
version: "prometheus/v1"
service: "ecommerce-checkout"
slos:
  - name: "order-processing-latency"
    objective: 90
    description: "Order processing latency SLO"
    sli:
      events:
        error_query: |
          sum(rate(checkout_requests_total{status!="success"}[5m])) +
          sum(rate(checkout_success_total{latency_ms>1000}[5m]))
        total_query: |
          sum(rate(checkout_requests_total[5m])) -
          sum(rate(checkout_validation_errors_total[5m]))
    alerting:
      name: OrderProcessingLatency
      labels:
        team: sre
        severity: warning
```

### Log-Based SLIs: Loki Alternative

For legacy applications using log files:

**Process**:
1. Configure Promtail to scrape relevant log files
2. Define parser configurations using regular expressions
3. Apply parsers to log streams
4. Use LogQL (Loki Query Language) to extract SLI data
5. Create Grafana dashboards from queried data

**Example LogQL Query**:
```
count_over_time({job="checkout"} |= "checkout_success_total" | regexp "latency=(?P<latency>\\d+)ms" | latency < 1000 [8h])
```

### Tool Recommendations

- **Thanos**: Unlimited retention for Prometheus data
- **Nobl9**: Turnkey SLO platform for existing monitoring
- **Grafana**: Universal dashboarding for both Prometheus and Loki

---

## SLO Mathematics and Calculations

### Scenario: 8-Hour Aggregation Window

**Data**:
- 110 total checkout requests
- 10 validation errors (user input issues)
- 10 server-side errors (timeouts, exceptions)
- 2 slow successful requests (>1 second)
- 88 fast successful requests (<1 second)

### Calculation Method 1: Combined Availability + Latency

**Formula**: (Successful fast requests) / (Total valid requests)

**Calculation**:
- Valid requests: 110 - 10 (validation) = 100
- Successful fast: 88
- **Result**: 88/100 = 88% (fails 90% target)

### Calculation Method 2: Pure Latency SLI

**Formula**: (Successful fast requests) / (Successful requests only)

**Calculation**:
- Total successful: 88 + 2 = 90
- Successful fast: 88
- **Result**: 88/90 = 97.8% (exceeds 90% target)

### Key Decision: Error Handling

**Critical Choice**: How to handle server-side errors
- **Include in denominator**: Measures combined availability + latency
- **Exclude from denominator**: Measures pure latency performance

This decision significantly impacts SLO results and should align with business objectives.

---

## Understanding and Acting on SLO Data

### Periodic Review Process

**Frequency**: Monthly, quarterly, or annually

**Activities**:
1. Review SLO performance against targets
2. Create executive reports on reliability metrics
3. Analyze trends and patterns
4. Plan future reliability investments

### Data-Driven Decision Making

SLO data enables concrete, evidence-based discussions about:
- **Resource allocation** for reliability improvements
- **Feature prioritization** based on reliability impact
- **Architecture decisions** informed by real performance data
- **Team goals** aligned with measurable outcomes

### Reliability vs. Feature Development

**High Performance (exceeding targets)**:
- Consider new features or optimizations
- Evaluate ambitious architectural changes
- Take calculated risks with new technologies

**Poor Performance (missing targets)**:
- Focus exclusively on reliability improvements
- Delay non-critical feature development
- Investigate root causes systematically

---

## Advanced Concepts: Burn Rate and Error Budgets

### Error Budget Fundamentals

**Concept**: The allowable unreliability within your SLO target

**Example**: 90% reliability target = 10% error budget

**Calculation**:
- Target: 90% reliability
- Actual: 99.9% reliability  
- **Remaining error budget**: 9.9% available for risk-taking

### Burn Rate

**Definition**: The rate at which you consume your error budget

**Applications**:
- **Slow burn**: Consistent small issues over time
- **Fast burn**: Major incidents consuming large portions quickly
- **Budget management**: Balance feature velocity with reliability

### Implementation Recommendation

**For beginners**: Focus on basic SLO implementation first
- Establish SLO measurement and reporting
- Build operational dashboards
- Create reliability review processes

**Advanced teams**: Add error budget management later
- Implement burn rate alerting
- Create error budget policies
- Link deployment gates to budget status

---

## Common Objections and Best Practices

### "We Don't Need SLOs - We Build Reliable Software"

**Response**: You might already be doing SLOs without calling them that

**Questions to Ask**:
- Do you have reliability evidence in numbers?
- Do you regularly meet to discuss reliability targets?
- Can you compare current reliability to past performance?
- Do you align on new reliability objectives based on data?

### Getting Started Recommendations

**Start Small**:
1. Choose one critical user-facing operation
2. Define a simple SLO (availability or latency)
3. Implement basic logging and measurement
4. Create a simple dashboard
5. Review monthly performance

**Avoid Early Mistakes**:
- Don't start with complex, multi-dimensional SLOs
- Don't set unrealistic targets (99.999% for new systems)
- Don't measure everything - focus on user impact
- Don't skip the collaborative definition process

### Book Recommendations

- **"Implementing Service Level Objectives"** by Alex Hidalgo
- **"Database Reliability Engineering"** for SLI categories
- **Google SRE resources** for infrastructure-level implementations

### Success Criteria

**You'll know SLOs are working when**:
- Reliability discussions become data-driven
- Teams can quantify the impact of changes
- Planning includes reliability considerations
- Incidents trigger SLO reviews and improvements
- Executive reporting includes reliability metrics

---

## Conclusion

Service Level Objectives and Service Level Indicators provide a framework for building and maintaining reliable software systems. They transform subjective reliability discussions into objective, measurable commitments that align technical teams with business objectives.

**Key Takeaways**:
- SLOs formalize reliability commitments from the user perspective
- SLIs provide the measurable data needed to track SLO performance
- Implementation should start simple and evolve over time
- SLO data enables data-driven reliability decisions
- Regular review and adjustment cycles ensure continued relevance

By implementing SLOs systematically, teams can build software that's "solid as a rock" while maintaining the agility needed for continued innovation and growth.
