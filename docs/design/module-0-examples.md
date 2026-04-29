# Module 0 Examples: Strategic Foundation

**Reference**: SRE Masterclass Specification - Phase 0: Strategic Foundation

## Module 0.1: Business Value Quantification Examples

### Cost of Downtime Calculation Template
```
Business Impact Analysis:
- E-commerce site: $50k revenue/hour
- 99.9% uptime = 8.76 hours downtime/year = $438k annual cost
- 99.99% uptime = 0.876 hours downtime/year = $43.8k annual cost
- SRE investment to improve reliability: ~$200k (2 engineers)
- ROI: $394k savings - $200k investment = $194k net benefit
```

### ROI Calculation Framework
```
Variables to Define:
1. Annual Revenue
2. Revenue Loss Rate ($/hour of downtime)
3. Current Reliability (%)
4. Target Reliability (%)
5. SRE Team Investment ($)

Formula:
Annual Downtime Cost Savings = (Current Downtime Hours - Target Downtime Hours) × Revenue Loss Rate
Net ROI = Annual Savings - SRE Investment
```

### Business Model Examples for Exercises
```
SaaS Platform:
- $2M ARR, 10k users
- $228/hour revenue impact
- Customer churn: 5% per major outage

Financial Services:
- $100M transaction volume/day
- $4,166/hour impact
- Regulatory penalties: $50k per hour during trading

Media Streaming:
- 50M active users
- $2,083/hour advertising revenue
- User experience degradation threshold
```

## Module 0.2: SRE Team Models Examples

### Team Structure Templates

#### Embedded SRE Model (Google Style)
```
Team Composition:
- 2 SREs embedded in each product team
- Reports to: Product Engineering Manager
- Responsibilities: Product-specific reliability, on-call rotation
- Metrics: Product SLO compliance, incident MTTR
```

#### Centralized SRE Model
```
Team Composition:
- Platform SRE team (5-8 engineers)
- Reports to: Infrastructure/Platform Director
- Responsibilities: Shared infrastructure, tooling, consulting
- Metrics: Platform availability, tooling adoption
```

#### Hybrid Model Example (Spotify-style)
```
Structure:
- Platform SRE: Infrastructure reliability (Kubernetes, databases)
- Embedded Reliability Engineers: Product-specific concerns
- SRE Consultants: Cross-team initiatives, incident response

Interaction Pattern:
- Weekly reliability reviews between teams
- Quarterly SLO target negotiations
- Shared on-call for platform components
```

## Module 0.3: SDLC Integration Points

### SRE Touchpoints by Phase
```
Planning Phase:
- SRE Input: Reliability requirements based on business impact
- SRE Input: SLO target recommendations
- SRE Deliverable: Reliability user stories for sprint

Design Phase:
- SRE Input: Architecture review for failure modes
- SRE Input: Dependency analysis and circuit breaker requirements
- SRE Deliverable: Monitoring and instrumentation requirements

Development Phase:
- SRE Input: Code review for instrumentation patterns
- SRE Input: Error handling and retry logic validation
- SRE Deliverable: SLI implementation guidance

Testing Phase:
- SRE Ownership: Load testing scenarios
- SRE Ownership: Chaos engineering experiments
- SRE Deliverable: Performance baseline establishment

Deployment Phase:
- SRE Ownership: Deployment automation and rollback procedures
- SRE Ownership: SLO validation during rollout
- SRE Deliverable: Go/no-go deployment decisions

Operations Phase:
- SRE Ownership: Production monitoring and alerting
- SRE Ownership: Incident response and post-mortems
- SRE Deliverable: Reliability metrics and improvement recommendations
```

## Module 0.4: Team Interaction Patterns

### Agile Integration Examples

#### Sprint Planning Integration
```
SRE Contributions:
- Present previous sprint's reliability metrics
- Propose reliability-focused user stories
- Review feature designs for operational impact
- Estimate reliability work alongside feature work

Sample Reliability Stories:
- "As an SRE, I need checkout latency metrics to validate SLO compliance"
- "As a user, I expect payment processing to complete within 2 seconds 95% of the time"
- "As an ops team, I need automated rollback when error rates exceed 5%"
```

#### Daily Standup Pattern
```
SRE Daily Standup Format:
- Yesterday: Production incidents, SLO performance, automation progress
- Today: Planned reliability work, deployment support, monitoring improvements  
- Blockers: Missing instrumentation, configuration issues, resource constraints

Example Update:
"Yesterday: Investigated payment latency spike, updated P95 alert threshold
Today: Implementing checkout service circuit breaker, supporting mobile app deployment
Blockers: Need database connection pool metrics from infrastructure team"
```

#### Cross-Team Communication Protocols
```
Weekly Reliability Review Agenda:
1. SLO Performance Review (10 minutes)
   - Current period metrics vs targets
   - Trends and patterns identification
   
2. Incident Review (10 minutes)
   - Recent incidents impact analysis
   - Action items status
   
3. Upcoming Changes (10 minutes)
   - Feature releases affecting reliability
   - Infrastructure changes
   
4. Reliability Improvements (10 minutes)
   - Proposed architecture changes
   - Tooling and automation updates
```

## Prerequisites and Setup Examples

### Hardware Requirements Validation
```bash
#!/bin/bash
# setup-check.sh - Environment validation script

echo "🔍 SRE Masterclass Environment Check"
echo "=================================="

# Check available RAM
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
if [ $RAM_GB -ge 8 ]; then
    echo "✅ RAM: ${RAM_GB}GB detected (8GB+ required)"
else
    echo "❌ RAM: ${RAM_GB}GB detected (8GB+ required)"
    exit 1
fi

# Check available disk space
DISK_GB=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
if [ $DISK_GB -ge 15 ]; then
    echo "✅ Disk Space: ${DISK_GB}GB available (15GB+ required)"
else
    echo "❌ Disk Space: ${DISK_GB}GB available (15GB+ required)"
    exit 1
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker installed and available"
else
    echo "❌ Docker not found - please install Docker Desktop"
    exit 1
fi

# Check docker-compose
if command -v docker-compose &> /dev/null; then
    echo "✅ docker-compose available"
else
    echo "❌ docker-compose not found"
    exit 1
fi

# Check port availability
for port in 3000 3001 9090 3100 8080; do
    if ! nc -z localhost $port 2>/dev/null; then
        echo "✅ Port $port available"
    else
        echo "⚠️  Port $port in use - may cause conflicts"
    fi
done

echo ""
echo "🚀 Environment check complete!"
echo "Ready to start SRE Masterclass"
```

### Quick Start Commands
```bash
# One-command environment setup
make setup

# Expected output validation
echo "Validating services..."
curl -s http://localhost:3000/health || echo "❌ Frontend not ready"
curl -s http://localhost:9090/-/healthy || echo "❌ Prometheus not ready"  
curl -s http://localhost:3001/api/health || echo "❌ Grafana not ready"
echo "✅ All services ready!"
```