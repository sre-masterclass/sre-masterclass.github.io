# SRE Masterclass: Complete Project Specification

## Project Vision

Creating a comprehensive SRE training series that addresses critical gaps in existing education offerings. The course will be distributed on platforms like Udemy and FreeCodeCamp.

### Problems Being Solved

1. **Lack of Practical Applications**: Existing courses use static websites instead of realistic applications with controllable entropy
2. **Excessive Setup Time**: Too much time spent on environment configuration rather than SRE concepts
3. **Missing Strategic Context**: Courses jump into technical details without explaining SRE business value and organizational integration
4. **Insufficient Depth**: Surface-level coverage of core SRE principles like monitoring taxonomies, SLO mathematics, and proactive monitoring

### Core Differentiators

- **Entropy-Injectable Applications**: Real applications with controllable failure modes for hands-on learning
- **Pre-built Environment**: Single docker-compose command gets complete stack running
- **Deep Instrumentation**: SRE-focused instrumentation patterns, not basic developer logging
- **Strategic Foundation**: Business value, team models, and organizational integration
- **Patterns-Based Monitoring**: Taxonomy-driven approach rather than ad-hoc metrics

---

## Target Audience & Approach

**Target Audience**: SREs and developers seeking deep understanding of reliability engineering
**Instrumentation Depth**: Advanced - custom metrics, histograms, labels, cardinality management
**Course Length**: 30-40 hours of comprehensive content (flexible for modular release)

---

## Course Structure

### **Phase 0: Strategic Foundation (3-4 hours)**
- **Module 0.1**: Business Value Quantification
  - Cost of downtime calculations
  - ROI analysis for SRE investments
  - Practical exercises for different business models
- **Module 0.2**: SRE Team Models & Responsibilities
  - Embedded vs Centralized vs Consulting models
  - Real-world examples (Netflix, Spotify, smaller companies)
- **Module 0.3**: SDLC Integration Points
  - SRE touchpoints in each development phase
  - Planning → Operations integration patterns
- **Module 0.4**: Team Interaction Patterns
  - Agile integration strategies
  - Communication protocols and cross-functional collaboration

### **Phase 1: Technical Foundations (4-6 hours)**
- **Module 1.1**: Monitoring Taxonomies Deep Dive
  - USE vs RED vs Four Golden Signals practical comparison
  - Resource type mapping exercises
  - When to use which taxonomy
- **Module 1.2**: Environment Setup & Instrumentation
  - Deploy the stack (5 minutes)
  - Code walkthrough of instrumentation patterns
  - Adding custom metrics to existing services
- **Module 1.3**: Black Box vs White Box Implementation
  - External monitoring (synthetic transactions)
  - Internal monitoring (resource utilization)
  - Correlation techniques

### **Phase 2: SLO/SLI Mastery (6-8 hours)**
- **Module 2.1**: SLO Definition Workshop
  - Collaborative exercises (role-play with product/eng)
  - Common pitfalls and how to avoid them
  - SLO evolution over time
- **Module 2.2**: SLI Implementation Patterns
  - The four SLI categories with hands-on examples
  - Aggregation window selection strategies
  - Error classification decisions
- **Module 2.3**: SLO Mathematics & Error Budgets
  - Real calculations with e-commerce data
  - Burn rate calculations and alerting
  - Error budget policies and enforcement

### **Phase 3: Advanced Monitoring (8-10 hours)**
- **Module 3.1**: Multi-Window Aggregation (COMPLETE)
  - Why 5-minute windows aren't enough
  - Seasonal pattern detection
  - Deployment impact analysis
- **Module 3.2**: Anomaly Detection (COMPLETE)
  - SAFE methodology implementation
  - Custom anomaly detection with Prometheus
  - Machine learning approaches (optional)
- **Module 3.3**: Capacity Planning (COMPLETE)
  - Predictive monitoring techniques
  - Saturation vs utilization trade-offs
  - Auto-scaling trigger design

### **Phase 4: Incident Response & Operations (6-8 hours)**
- **Module 4.1**: Proactive Alerting Design (COMPLETE)
  - Alert fatigue prevention
  - Severity classification
  - Escalation policies
- **Module 4.2**: Incident Response Workflows (COMPLETE)
  - Detection to resolution lifecycle
  - Runbook automation
  - Post-incident analysis
- **Module 4.3**: Operational Excellence (COMPLETE)
  - Toil identification and elimination
  - SRE team scaling patterns
  - Reliability culture building

### **Phase 5: SRE in CI/CD (3-4 hours)**
- **Module 5.1**: Deployment Automation (COMPLETE)
  - Blue/green and canary deployment patterns
  - Rollback automation triggers
- **Module 5.2**: SLO-Based Deployment Gates (COMPLETE)
  - Error budget enforcement in pipelines
  - Performance regression detection
- **Module 5.3**: Chaos Engineering Integration (COMPLETE)
  - Automated chaos experiments in staging
  - Production chaos scheduling
  - Experiment result validation

---

## Technical Architecture

### **Core Applications**
- **E-commerce API** (Node.js) - Demonstrates RED metrics
- **User Authentication Service** (Python) - Shows availability SLIs
- **Payment Processing Service** (Python) - Latency SLIs with consistency
- **Background Job Processor** (Go) - Throughput SLIs and queue saturation

### **Monitoring Stack**
- **Prometheus** + **Grafana** (with pre-built dashboards)
- **Loki** + **Promtail** (log aggregation)
- **Jaeger** (distributed tracing)
- **AlertManager** (with Slack webhook examples)
- **Grafana OnCall** (FOSS incident management)

### **Infrastructure Components**
- **Nginx** (load balancer with metrics)
- **Redis** (caching layer with monitoring)
- **PostgreSQL** (database with connection pool metrics)
- **k6** (load generation for realistic traffic)

### **Enhanced Docker Compose Architecture**
```yaml
services:
  # Applications with resource controls
  checkout-service:
    deploy:
      resources:
        limits:
          memory: 1G  # Allows OOM scenarios
          cpus: '1.0'
    environment:
      - ENTROPY_ENDPOINT=http://entropy-engine:8080
      - CHAOS_MONKEY_ENABLED=true
  
  # Entropy control engine  
  entropy-engine:
    volumes:
      - ./entropy-configs:/configs
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - SCENARIOS_PATH=/configs/scenarios
  
  # Enhanced monitoring
  node-exporter:
    image: prom/node-exporter
  cadvisor:
    image: gcr.io/cadvisor/cadvisor
```

---

## Entropy Engineering System

### **Complexity Levels**

**Level 1: Simple Toggles**
- Basic service state controls (normal/degraded/critical)
- Latency, error rate, throughput adjustments
- Manual toggle interface

**Level 2: Realistic Patterns**
- Monday deployment failures
- Traffic spike simulations
- Cascading failure chains
- Scheduled chaos events

**Level 3: Advanced Chaos Engineering**
- Network partition simulations
- Dependency failure scenarios
- Resource exhaustion patterns
- Full chaos experiment framework

### **Memory Exhaustion Scenario Example**
```javascript
const memoryLeakScenario = {
  name: "checkout_memory_leak",
  description: "Simulate memory leak in checkout service",
  timeline: [
    { time: "0m", usage: "200MB", status: "normal" },
    { time: "5m", usage: "500MB", status: "elevated" },
    { time: "10m", usage: "800MB", status: "warning" },
    { time: "15m", usage: "1.2GB", status: "critical" },
    { time: "18m", usage: "1.5GB", status: "oom_kill" }
  ],
  monitoring_expectations: {
    alerts_triggered: ["memory_usage_high", "container_restart"],
    slo_impact: "checkout_latency_degraded", 
    recovery_time: "2-3 minutes"
  }
};
```

---

## Incident Response Implementation

### **Technology Stack**
- **Grafana OnCall** for incident lifecycle management
- **Slack integration** for notifications
- **Runbook automation** via HTML pages served by applications
- **SOP links** embedded in alert messages

### **Incident Simulation Flow**
```yaml
incident_scenarios:
  payment_outage:
    trigger: "payment_service_error_rate > 10%"
    slack_message: "🚨 Payment processing degraded - SLO at risk"
    runbook_url: "http://localhost:8080/runbooks/payment-outage"
    resolution: "Toggle payment service entropy to 'normal'"
    
  latency_spike:
    trigger: "api_latency_p95 > 2s"
    slack_message: "⚠️ API latency degraded - customer impact likely"
    runbook_url: "http://localhost:8080/runbooks/latency-spike"
    resolution: "Toggle API latency entropy to 'normal'"
```

---

## Cloud Deployment Options

### **Primary Recommendation: GitHub Codespaces**
- **Cost**: ~$0.18/hour for 4-core, 8GB machine
- **Student Cost**: ~$7.20 for 40-hour course
- **Benefits**: Consistent environments, no local setup, easy sharing
- **Implementation**: `.devcontainer/devcontainer.json` configuration

### **Alternative Options**
- **GitPod**: 50 hours/month free, one-click launch
- **Railway**: $5/month, direct docker-compose support
- **Digital Ocean App Platform**: $5/month basic tier

### **Tiered Environment Strategy**
- **Tier 1 (Local)**: Full stack with chaos engineering (16GB RAM)
- **Tier 2 (Cloud Basic)**: Core monitoring + simple entropy (8GB)
- **Tier 3 (Cloud Advanced)**: Full stack minus resource-intensive components

---

## Prerequisites & Setup

### **Hardware Requirements**
- **Local**: 16GB RAM, 4 CPU cores, 20GB disk space
- **Cloud**: 4-core, 8GB Codespace recommended

### **Software Requirements**
- Docker & docker-compose
- Git, text editor, web browser
- Basic command line familiarity

### **One-Command Setup Validation**
```bash
curl -s https://raw.githubusercontent.com/your-repo/sre-masterclass/main/setup-check.sh | bash
```

---

## Items for Future Discussion

### **Technical Implementation Questions**
1. **Specific chaos engineering scenarios** - Which realistic failure patterns to implement first?
2. **Dashboard design patterns** - Standard layouts for different monitoring taxonomies?
3. **Load testing integration** - k6 scenarios for different SLO validation patterns?
4. **Alert rule templates** - Prometheus alerting rules for each taxonomy?

### **Content Development Priorities**
1. **Module ordering** - Should CI/CD integration come earlier in the curriculum?
2. **Hands-on exercises** - Specific workshop formats for SLO definition sessions?
3. **Assessment strategies** - How to validate learning outcomes for practical skills?
4. **Advanced topics** - ML-based anomaly detection inclusion criteria?

### **Platform & Distribution**
1. **Course segmentation** - Split into "Fundamentals" and "Advanced" courses?
2. **Supplementary materials** - Reference guides, cheat sheets, additional resources?
3. **Community building** - GitHub discussions, Discord server, or other community platforms?
4. **Updates and maintenance** - Strategy for keeping content current with evolving SRE practices?

### **Repository Structure**
1. **Branching strategy** - Main branch vs module-specific branches for progressive complexity?
2. **Documentation organization** - Student guides vs instructor notes vs technical documentation?
3. **Version management** - Handling updates to docker images and configurations?

---

## Success Metrics

### **Student Outcomes**
- Ability to implement monitoring taxonomies in production environments
- Successful SLO definition and implementation in real projects
- Demonstrated understanding of SRE business value and organizational integration
- Practical incident response and chaos engineering skills

### **Course Quality Indicators**
- High completion rates (target: >70%)
- Positive student feedback on practical applicability
- Adoption of course patterns in students' work environments
- Community contributions and discussions around course materials

---

*This specification serves as the master reference for the SRE Masterclass project. All implementation decisions and content development should align with the vision and principles outlined in this document.*
