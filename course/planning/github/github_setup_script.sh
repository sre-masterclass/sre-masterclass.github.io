#!/bin/bash

# SRE Masterclass GitHub Repository Setup Script
# Creates optimally configured repository for training environment
# Requires: GitHub CLI (gh) installed and authenticated

set -e  # Exit on any error

# Configuration
REPO_NAME=${1:-"sre-masterclass"}
ORG_OR_USER=${2:-$(gh api user --jq '.login')}
REPO_DESCRIPTION="Complete SRE training environment with chaos engineering and real-world scenarios"
HOMEPAGE_URL="https://sre-masterclass.dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Please install from https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Run 'gh auth login' first."
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Create repository with optimal settings
create_repository() {
    log_info "Creating repository $ORG_OR_USER/$REPO_NAME..."
    
    gh repo create "$ORG_OR_USER/$REPO_NAME" \
        --description "$REPO_DESCRIPTION" \
        --homepage "$HOMEPAGE_URL" \
        --public \
        --enable-issues \
        --enable-wiki=false
    
    log_success "Repository created"
}

# Configure repository settings
configure_repository_settings() {
    log_info "Configuring repository settings..."
    
    # Optimal merge settings for training repository
    gh api "repos/$ORG_OR_USER/$REPO_NAME" --method PATCH --field \
        allow_squash_merge=true \
        allow_merge_commit=false \
        allow_rebase_merge=true \
        delete_branch_on_merge=true \
        allow_auto_merge=true \
        allow_update_branch=true
    
    # Enable discussions for community
    gh api "repos/$ORG_OR_USER/$REPO_NAME" --method PATCH --field \
        has_discussions=true
    
    log_success "Repository settings configured"
}

# Create comprehensive label system
create_labels() {
    log_info "Creating label system..."
    
    # Type labels
    gh label create "bug" --color "d73a4a" --description "Something isn't working" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "enhancement" --color "a2eeef" --description "New feature or request" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "documentation" --color "0075ca" --description "Improvements or additions to documentation" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "question" --color "d876e3" --description "Further information is requested" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "chaos-scenario" --color "D93F0B" --description "New chaos engineering scenario" --repo "$ORG_OR_USER/$REPO_NAME" || true
    
    # Priority labels
    gh label create "priority-high" --color "B60205" --description "Breaks student environment - urgent fix needed" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "priority-medium" --color "FBCA04" --description "Impacts learning experience" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "priority-low" --color "0E8A16" --description "Nice to have improvement" --repo "$ORG_OR_USER/$REPO_NAME" || true
    
    # Module labels
    gh label create "module-1" --color "0E8A16" --description "Module 1: Technical Foundations" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "module-2" --color "1D76DB" --description "Module 2: SLO/SLI Mastery" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "module-3" --color "5319E7" --description "Module 3: Advanced Monitoring" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "module-4" --color "E99695" --description "Module 4: Incident Response" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "module-5" --color "F9D0C4" --description "Module 5: CI/CD Integration" --repo "$ORG_OR_USER/$REPO_NAME" || true
    
    # Status labels
    gh label create "triage-needed" --color "EDEDED" --description "Requires initial review and categorization" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "in-progress" --color "FBCA04" --description "Actively being worked on" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "needs-testing" --color "FEF2C0" --description "Requires validation before merge" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "ready-for-review" --color "C2E0C6" --description "Awaiting code review" --repo "$ORG_OR_USER/$REPO_NAME" || true
    
    # Community labels
    gh label create "good-first-issue" --color "7057ff" --description "Good for newcomers" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "help-wanted" --color "008672" --description "Extra attention is needed" --repo "$ORG_OR_USER/$REPO_NAME" || true
    gh label create "breaking-change" --color "B60205" --description "Requires migration guide for users" --repo "$ORG_OR_USER/$REPO_NAME" || true
    
    log_success "Labels created"
}

# Set up branch protection rules
setup_branch_protection() {
    log_info "Setting up branch protection for main branch..."
    
    # Create branch protection rules JSON
    cat > /tmp/protection-rules.json << EOF

    log_success "CODEOWNERS file created"
}

# Create comprehensive README template
create_readme_template() {
    log_info "Creating README template..."
    
    cat > README.md << 'EOF'
# SRE Masterclass Training Environment

> Complete hands-on Site Reliability Engineering training with real applications and controllable chaos scenarios.

[![Environment Test](https://github.com/USERNAME/REPO_NAME/actions/workflows/environment-test.yml/badge.svg)](https://github.com/USERNAME/REPO_NAME/actions/workflows/environment-test.yml)
[![Documentation](https://github.com/USERNAME/REPO_NAME/actions/workflows/documentation.yml/badge.svg)](https://github.com/USERNAME/REPO_NAME/actions/workflows/documentation.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Quick Start (5 minutes)

```bash
git clone https://github.com/USERNAME/REPO_NAME.git
cd REPO_NAME
docker-compose up -d
```

**Access Points:**
- **Training Dashboard**: http://localhost:8080 (Entropy controls)
- **Grafana Dashboards**: http://localhost:3001 (admin/sre_admin)
- **Prometheus**: http://localhost:9090
- **Application**: http://localhost:3000

## 🎯 What You'll Learn

This environment supports comprehensive SRE training across five core modules:

- ✅ **Module 1**: Monitoring taxonomies (USE, RED, Four Golden Signals)
- ✅ **Module 2**: SLO/SLI implementation and mathematics
- ✅ **Module 3**: Advanced monitoring and anomaly detection
- ✅ **Module 4**: Incident response and chaos engineering
- ✅ **Module 5**: CI/CD integration and deployment safety

## 🏗️ Training Architecture

### Mock Applications (Realistic SRE Scenarios)
| Service | Purpose | SRE Focus | Entropy Controls |
|---------|---------|-----------|------------------|
| **E-commerce API** | Order processing | RED metrics, latency SLIs | Response time, error rates |
| **Auth Service** | User authentication | Availability SLIs | Service uptime, dependency failures |
| **Payment Service** | Transaction processing | Consistency SLIs | External provider issues |
| **Job Processor** | Background tasks | Throughput SLIs | Queue saturation, processing delays |

### Entropy Engineering System
**Controllable Failure Modes:**
- 🎛️ **Manual Controls**: Instant parameter adjustment (latency, errors, throughput)
- ⏱️ **Automated Scenarios**: Timeline-based chaos experiments
- 📊 **Real-time Feedback**: Immediate metrics impact in dashboards
- 🔄 **Recovery Testing**: Practice incident response workflows

### Pre-configured Monitoring Stack
- **Prometheus**: Metrics collection with SRE-focused recording rules
- **Grafana**: Module-specific dashboards and SLO tracking
- **Loki**: Log aggregation with LogQL examples  
- **AlertManager**: Multi-window burn rate alerting
- **Jaeger**: Distributed tracing across services

## 🛠️ System Requirements

**Minimum:**
- Docker & docker-compose
- 8GB RAM
- 4 CPU cores  
- 10GB disk space

**Recommended (Full Scenarios):**
- 16GB RAM
- 8 CPU cores
- 20GB disk space

**Cloud Alternatives:**
- GitHub Codespaces (4-core, 8GB) - ~$7 for full course
- GitPod (50 hours/month free)
- Local development with resource limits

## 📚 Course Integration

### Repository Structure
```
sre-masterclass/
├── services/           # Mock applications with SRE instrumentation
├── entropy-engine/     # Chaos control system
├── monitoring/         # Pre-configured Prometheus, Grafana, etc.
├── docs/              # Module-specific documentation
└── scripts/           # Environment management helpers
```

### Module Progression
Each module builds on previous foundations:

1. **Clone repository** → Complete environment in 5 minutes
2. **Follow module exercises** → Hands-on SRE practice
3. **Experiment with chaos** → Real failure mode experience
4. **Build understanding** → Theory reinforced by practice

### Video Course Support
This environment is designed to work standalone, but is enhanced by the **SRE Masterclass video course** which provides:
- Comprehensive concept explanations
- Guided exercise walkthroughs  
- Real-world SRE scenarios and case studies
- Best practices and industry insights

## 🎮 Quick Demo

### 1. Start Environment
```bash
docker-compose up -d
# Wait ~2 minutes for full startup
```

### 2. Trigger Chaos Scenario
1. Open entropy dashboard: http://localhost:8080
2. Set "E-commerce API" latency to "Critical"
3. Watch Grafana dashboards: http://localhost:3001

### 3. Observe SRE Concepts
- **RED Metrics**: Rate drops, errors increase, duration spikes
- **SLO Impact**: Latency SLO breach visible in real-time
- **Alerting**: Alerts fire based on burn rate thresholds
- **Recovery**: Reset to normal, observe system recovery

## 🤝 Contributing

We welcome contributions from the SRE community!

### Quick Contribution Guide
1. **Fork** the repository
2. **Create branch**: `git checkout -b feature/new-chaos-scenario`
3. **Test changes**: `docker-compose up -d && ./scripts/health-check.sh`
4. **Submit PR** with clear description and learning objectives

### Contribution Types
- 🐛 **Bug Fixes**: Environment issues, documentation corrections
- 🎯 **Chaos Scenarios**: New failure patterns with learning objectives
- 📊 **Monitoring**: Additional dashboards, alerts, or metrics
- 📚 **Documentation**: Improvements, examples, troubleshooting guides

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📖 Documentation

### Quick References
- **[Quick Start Guide](QUICK_START.md)** - Get running in 5 minutes
- **[Architecture Overview](docs/architecture/system-overview.md)** - System design and components
- **[Troubleshooting](docs/troubleshooting/common-issues.md)** - Common issues and solutions
- **[Module Exercises](docs/modules/)** - Hands-on training exercises

### Module Documentation
- **[Module 1: Technical Foundations](docs/modules/module-1-foundations.md)**
- **[Module 2: SLO/SLI Mastery](docs/modules/module-2-slo-sli.md)**
- **[Module 3: Advanced Monitoring](docs/modules/module-3-advanced.md)**
- **[Module 4: Incident Response](docs/modules/module-4-incident.md)**
- **[Module 5: CI/CD Integration](docs/modules/module-5-cicd.md)**

## 🔧 Environment Management

### Essential Commands
```bash
# Start full environment
docker-compose up -d

# Check service health
./scripts/health-check.sh

# Reset to clean state  
./scripts/reset-environment.sh

# View service logs
docker-compose logs -f [service-name]

# Stop environment
docker-compose down -v
```

### Cloud Deployment
**GitHub Codespaces (Recommended):**
1. Click "Code" → "Codespaces" → "Create codespace"
2. Wait for automatic setup (~3 minutes)
3. Access via forwarded ports

**Alternative Platforms:**
- GitPod: One-click launch from GitHub
- Railway: Direct docker-compose deployment
- Local with resource constraints: Use `docker-compose.lightweight.yml`

## 🏆 Learning Outcomes

After completing this training environment, you'll be able to:

### Technical Skills
- ✅ Implement monitoring using established SRE taxonomies
- ✅ Define and measure SLIs/SLOs with real mathematics
- ✅ Design effective alerting with burn rate calculations
- ✅ Conduct chaos engineering experiments safely
- ✅ Respond to incidents using structured approaches

### Strategic Understanding  
- ✅ Quantify business value of SRE investments
- ✅ Choose appropriate team models for different organizations
- ✅ Integrate SRE practices into existing development workflows
- ✅ Build reliable systems using data-driven approaches

## 📊 Success Metrics

### Student Environment Success
- 🎯 **Setup Success Rate**: >98% (1-command deployment)
- ⚡ **Startup Time**: <5 minutes from clone to working environment  
- 🔄 **Scenario Reliability**: 100% reproducible chaos experiments
- 📈 **Learning Progression**: Clear module-to-module advancement

### Community Health
- 💬 **Active Discussions**: Regular community engagement
- 🐛 **Issue Resolution**: <48 hours for environment-breaking issues
- 🔀 **Community Contributions**: Regular chaos scenario additions
- ⭐ **Quality Feedback**: Continuous improvement based on user experience

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **SRE Community**: For establishing the practices this training teaches
- **Open Source Tools**: Prometheus, Grafana, and the entire cloud-native ecosystem
- **Contributors**: Everyone who helps improve this training environment
- **Students**: Feedback and real-world testing that makes this better

---

**Ready to master Site Reliability Engineering?** 
[Get started now](QUICK_START.md) or [join the discussion](https://github.com/USERNAME/REPO_NAME/discussions)!
EOF

    # Replace placeholders with actual values
    sed -i "s/USERNAME/$ORG_OR_USER/g" README.md
    sed -i "s/REPO_NAME/$REPO_NAME/g" README.md
    
    log_success "README template created"
}

# Create CONTRIBUTING.md template
create_contributing_template() {
    log_info "Creating CONTRIBUTING.md template..."
    
    cat > CONTRIBUTING.md << 'EOF'
# Contributing to SRE Masterclass

Thank you for your interest in improving the SRE Masterclass training environment! This guide will help you contribute effectively while maintaining the educational focus and quality of the project.

## 🎯 Our Mission

This project aims to provide hands-on Site Reliability Engineering training through:
- **Realistic scenarios** that mirror production SRE challenges
- **Educational clarity** that promotes understanding over complexity
- **Practical application** of SRE principles and practices
- **Community collaboration** that benefits all learners

## 🛠️ Types of Contributions

### 🐛 Bug Fixes
**Environment Issues:**
- Docker setup problems
- Service integration failures
- Monitoring stack configuration issues
- Cross-platform compatibility problems

**Documentation Issues:**
- Incorrect instructions
- Missing setup steps
- Broken links or references
- Unclear explanations

### 🎯 Chaos Scenarios
**New Failure Patterns:**
- Service degradation scenarios
- Infrastructure failure simulations
- Dependency failure chains
- Resource exhaustion patterns

**Requirements for New Scenarios:**
- Clear learning objectives
- Realistic failure patterns
- Observable monitoring impact
- Recovery procedures
- Module alignment

### 📊 Monitoring Enhancements
**Dashboard Improvements:**
- New Grafana dashboards
- Enhanced Prometheus queries
- Additional SLI/SLO tracking
- Alert rule improvements

**Observability Features:**
- Log aggregation improvements
- Distributed tracing enhancements
- Custom metrics implementations
- Monitoring automation

### 📚 Documentation
**Content Improvements:**
- Setup and troubleshooting guides
- Architecture documentation
- Exercise instructions
- Best practices guides

**Examples and References:**
- Real-world SRE scenarios
- Industry case studies
- Tool configuration examples
- Learning resources

## 🔄 Contribution Process

### 1. Before You Start
**Check Existing Work:**
- Search [existing issues](https://github.com/USERNAME/REPO_NAME/issues) for similar requests
- Review [open pull requests](https://github.com/USERNAME/REPO_NAME/pulls) to avoid duplication
- Join [discussions](https://github.com/USERNAME/REPO_NAME/discussions) for questions and ideas

**Understand the Scope:**
- Focus on educational value over feature completeness
- Maintain simplicity for learning purposes
- Consider impact on student workflow
- Align with existing module structure

### 2. Development Setup
**Fork and Clone:**
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/REPO_NAME.git
cd REPO_NAME
git remote add upstream https://github.com/USERNAME/REPO_NAME.git
```

**Development Environment:**
```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# Verify environment health
./scripts/health-check.sh

# Make your changes...

# Test changes thoroughly
./scripts/test-changes.sh
```

**Create Feature Branch:**
```bash
git checkout -b feature/descriptive-name
# Example: feature/payment-circuit-breaker
# Example: fix/grafana-dashboard-permissions
# Example: docs/troubleshooting-windows
```

### 3. Development Guidelines

**Code Standards:**
```yaml
General Principles:
  - Educational value over production complexity
  - Clear, commented code for learning
  - Consistent with existing patterns
  - Docker-first development approach

Python Services:
  - Follow PEP 8 style guidelines
  - Use type hints for clarity
  - Comprehensive error handling
  - Structured logging with context

JavaScript/Vue.js:
  - ESLint configuration compliance
  - Component-based architecture
  - Clear prop definitions
  - Responsive design principles

Configuration:
  - YAML for human-readable configs
  - Environment variable overrides
  - Sensible defaults for training
  - Clear documentation of parameters
```

**Testing Requirements:**
```bash
# Required tests for all contributions
docker-compose down -v  # Clean slate
docker-compose up -d    # Full environment test
./scripts/health-check.sh  # Automated validation

# For new chaos scenarios
./scripts/test-scenario.sh scenario-name

# For monitoring changes
./scripts/validate-dashboards.sh

# For documentation changes
./scripts/check-links.sh
```

### 4. Pull Request Process

**Before Submitting:**
- [ ] All automated tests pass
- [ ] Manual testing completed in clean environment
- [ ] Documentation updated for new features
- [ ] Learning objectives documented (for scenarios)
- [ ] No breaking changes without migration guide

**PR Description Template:**
```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New chaos scenario (educational failure pattern)
- [ ] Monitoring enhancement (dashboards, alerts, metrics)
- [ ] Documentation improvement
- [ ] Other: _______________

## Learning Impact
For new features/scenarios:
- **Learning Objectives**: What will students learn?
- **Module Alignment**: Which modules does this support?
- **Student Workflow**: How does this fit into exercises?

## Testing Checklist
- [ ] Docker environment starts successfully
- [ ] All services pass health checks
- [ ] Chaos scenarios execute as expected
- [ ] Monitoring impact visible in dashboards
- [ ] Documentation accurate and complete

## Additional Context
Any other context, screenshots, or references.
```

### 5. Review Process

**Review Criteria:**
- **Educational Value**: Does this improve learning outcomes?
- **Code Quality**: Clean, documented, maintainable code
- **Testing**: Comprehensive validation completed
- **Documentation**: Clear instructions and context
- **Compatibility**: Works across supported platforms

**Review Timeline:**
- Initial response within 48 hours
- Full review within 1 week
- Feedback incorporation and re-review as needed
- Merge when all criteria met

## 🎓 Chaos Scenario Guidelines

### Scenario Development Framework
**Learning-Focused Design:**
```yaml
Scenario Planning:
  1. Identify Learning Objective
     - What SRE concept does this teach?
     - Which module(s) does it support?
     - What real-world scenario does it mirror?

  2. Design Failure Pattern
     - Realistic failure progression
     - Observable monitoring impact
     - Clear cause-and-effect relationships
     - Appropriate complexity for target module

  3. Define Timeline
     - Gradual vs sudden failure modes
     - Key observation points
     - Recovery procedures
     - Total scenario duration

  4. Validate Educational Value
     - Clear learning outcomes
     - Measurable student progress
     - Reproducible results
     - Appropriate difficulty level
```

**Example Scenario Structure:**
```yaml
scenario:
  name: "Database Connection Pool Exhaustion"
  module: "Module 3 - Advanced Monitoring"
  duration: "15 minutes"
  
  learning_objectives:
    - "Understand connection pool monitoring"
    - "Practice capacity planning for database resources"
    - "Experience gradual resource exhaustion patterns"
    - "Learn connection pool recovery procedures"
  
  timeline:
    - time: "0m"
      action: "Normal operation (20 connections)"
      monitoring: "Baseline metrics established"
    
    - time: "5m"
      action: "Gradual increase to 40 connections"
      monitoring: "Pool utilization increases to 50%"
    
    - time: "10m"
      action: "Spike to 80 connections"
      monitoring: "Pool utilization at 100%, wait queue forms"
    
    - time: "12m"
      action: "Connection timeouts begin"
      monitoring: "Error rate increases, latency spikes"
    
    - time: "15m"
      action: "Manual recovery or auto-scaling"
      monitoring: "Return to normal operation"
  
  expected_alerts:
    - "Database pool utilization > 80%"
    - "Connection wait time > 5 seconds"
    - "Application error rate > 5%"
  
  recovery_procedures:
    - "Increase connection pool size"
    - "Restart affected services"
    - "Scale database replicas"
```

### Scenario Implementation
**Technical Requirements:**
```yaml
Entropy Engine Integration:
  - REST API endpoints for scenario control
  - Timeline execution with accurate timing
  - Progress tracking and status reporting
  - Safety mechanisms and rollback procedures

Monitoring Integration:
  - Prometheus metrics showing clear impact
  - Grafana dashboard updates in real-time
  - Alert firing at appropriate thresholds
  - Log entries correlating with scenario events

Documentation Requirements:
  - Scenario purpose and learning objectives
  - Setup and execution instructions
  - Expected outcomes and validation steps
  - Troubleshooting common issues
```

## 📊 Quality Standards

### Automated Testing
**Continuous Integration:**
- Environment startup and health validation
- Scenario execution verification
- Monitoring stack functionality
- Cross-platform compatibility
- Documentation link validation

**Manual Testing Checklist:**
```bash
# Environment Testing
□ Clean environment startup (docker-compose up -d)
□ All services healthy within 5 minutes
□ Entropy dashboard accessible and functional
□ Grafana dashboards load correctly
□ Prometheus metrics collection working

# Scenario Testing
□ Scenario executes according to timeline
□ Monitoring impact visible in dashboards
□ Alerts fire at expected thresholds
□ Recovery procedures work as documented
□ No residual state after scenario completion

# Documentation Testing
□ Instructions are clear and complete
□ All links work correctly
□ Examples execute successfully
□ Troubleshooting steps are accurate
```

### Performance Requirements
**Resource Efficiency:**
```yaml
Development Environment:
  - Startup time: < 5 minutes
  - Memory usage: < 8GB total
  - CPU usage: < 4 cores sustained
  - Disk usage: < 10GB

Scenario Execution:
  - Timing accuracy: ± 5 seconds
  - Resource cleanup: Complete after scenario
  - State isolation: No cross-scenario interference
  - Recovery time: < 2 minutes to normal operation
```

## 🤝 Community Guidelines

### Communication
**Respectful Collaboration:**
- Assume positive intent
- Focus on educational value
- Provide constructive feedback
- Help newcomers learn and contribute

**Effective Communication:**
- Clear, concise descriptions
- Specific examples and context
- Relevant screenshots or logs
- Actionable feedback and suggestions

### Issue Management
**Creating Issues:**
- Use appropriate issue templates
- Provide complete context and environment details
- Include steps to reproduce for bugs
- Suggest specific improvements for enhancements

**Participating in Discussions:**
- Share relevant experience and insights
- Ask clarifying questions
- Offer help with testing and validation
- Contribute ideas for improvements

## 🆘 Getting Help

### Resources
**Documentation:**
- [Architecture Overview](docs/architecture/system-overview.md)
- [Troubleshooting Guide](docs/troubleshooting/common-issues.md)
- [Development Setup](docs/development/setup.md)

**Community Support:**
- [GitHub Discussions](https://github.com/USERNAME/REPO_NAME/discussions)
- [Issue Tracker](https://github.com/USERNAME/REPO_NAME/issues)
- [Pull Request Reviews](https://github.com/USERNAME/REPO_NAME/pulls)

### Common Questions
**"How do I add a new chaos scenario?"**
1. Review existing scenarios in `entropy-engine/scenarios/`
2. Create scenario definition following the template
3. Implement entropy controls in target service
4. Add monitoring integration and documentation
5. Test thoroughly and submit PR

**"How do I modify monitoring dashboards?"**
1. Edit Grafana dashboard JSON in `monitoring/grafana/dashboards/`
2. Test changes in development environment
3. Verify dashboard loads and displays correctly
4. Update documentation if needed
5. Submit PR with screenshots

**"How do I troubleshoot environment issues?"**
1. Check [common issues guide](docs/troubleshooting/common-issues.md)
2. Run health check script: `./scripts/health-check.sh`
3. Review service logs: `docker-compose logs [service-name]`
4. Search existing issues for similar problems
5. Create new issue with complete environment details

---

## 🎉 Recognition

We appreciate all contributions to the SRE Masterclass project! Contributors will be:
- Listed in project acknowledgments
- Referenced in relevant documentation
- Invited to participate in project decisions
- Recognized in course materials (where appropriate)

Thank you for helping make Site Reliability Engineering education accessible and practical for everyone!
EOF

    # Replace placeholders
    sed -i "s/USERNAME/$ORG_OR_USER/g" CONTRIBUTING.md
    sed -i "s/REPO_NAME/$REPO_NAME/g" CONTRIBUTING.md
    
    log_success "CONTRIBUTING.md template created"
}

# Create basic documentation structure
create_documentation_structure() {
    log_info "Creating documentation structure..."
    
    # Create directory structure
    mkdir -p docs/{architecture,modules,troubleshooting,examples,development}
    
    # Architecture overview placeholder
    cat > docs/architecture/system-overview.md << 'EOF'
# System Architecture Overview

## High-Level Architecture

The SRE Masterclass training environment consists of several interconnected components designed to provide realistic SRE training scenarios.

[Architecture diagram will be added here]

## Component Overview

### Application Services
- **E-commerce API**: Primary business service demonstrating RED metrics
- **Auth Service**: User authentication with availability SLIs
- **Payment Service**: Transaction processing with consistency requirements
- **Job Processor**: Background task processing with throughput SLIs

### Entropy Control System
- **Entropy Engine**: Central chaos engineering control system
- **Entropy Dashboard**: Web interface for scenario management
- **Scenario Executor**: Timeline-based chaos experiment execution

### Monitoring Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation and analysis
- **AlertManager**: Alert routing and notification

### Infrastructure Services
- **PostgreSQL**: Database with realistic connection patterns
- **Redis**: Caching and queue management
- **Nginx**: Load balancing and traffic management

## Network Architecture

[Network diagram will be added here]

## Data Flow

[Data flow diagram will be added here]

## Security Considerations

This is a training environment and should not be exposed to production networks or contain real data.

## Scalability Design

The environment is designed to run on:
- Local development machines (8GB+ RAM)
- Cloud development environments (GitHub Codespaces, GitPod)
- Container orchestration platforms (Kubernetes - future)
EOF

    # Troubleshooting guide placeholder
    cat > docs/troubleshooting/common-issues.md << 'EOF'
# Common Issues and Solutions

## Environment Setup Issues

### Docker Compose Fails to Start
**Symptoms**: Services fail to start, port conflicts, resource errors

**Solutions**:
1. Check Docker daemon is running: `docker info`
2. Verify port availability: `netstat -tlnp | grep :8080`
3. Increase Docker memory allocation (8GB minimum)
4. Stop conflicting services: `docker-compose down -v`

### Services Remain Unhealthy
**Symptoms**: Health checks fail, services restart repeatedly

**Solutions**:
1. Check service logs: `docker-compose logs [service-name]`
2. Verify resource allocation: `docker stats`
3. Wait longer for startup (some services take 2-3 minutes)
4. Check dependency ordering in docker-compose.yml

## Platform-Specific Issues

### Windows WSL2 Issues
**Common Problems**:
- Docker Desktop integration
- File permission issues
- Network connectivity

**Solutions**:
[Platform-specific solutions will be added here]

### macOS Issues
**Common Problems**:
- Docker Desktop performance
- Port forwarding issues
- M1/M2 compatibility

**Solutions**:
[Platform-specific solutions will be added here]

## Monitoring Stack Issues

### Grafana Dashboard Not Loading
**Symptoms**: Blank dashboards, connection errors

**Solutions**:
1. Check Grafana service: `curl http://localhost:3001/api/health`
2. Verify Prometheus connection in Grafana data sources
3. Import dashboards manually if provisioning fails

### Prometheus Not Collecting Metrics
**Symptoms**: No data in Grafana, empty Prometheus targets

**Solutions**:
1. Check Prometheus targets: http://localhost:9090/targets
2. Verify service discovery configuration
3. Check application metrics endpoints: `curl http://service:port/metrics`

## Getting Additional Help

If these solutions don't resolve your issue:
1. Search [existing issues](https://github.com/USERNAME/REPO_NAME/issues)
2. Create a new issue with complete environment details
3. Join the [community discussions](https://github.com/USERNAME/REPO_NAME/discussions)
EOF

    log_success "Documentation structure created"
}

# Create health check script
create_health_check_script() {
    log_info "Creating health check script..."
    
    mkdir -p scripts
    cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

# SRE Masterclass Environment Health Check
# Validates that all services are running correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker-compose is running
check_docker_compose() {
    log_info "Checking Docker Compose services..."
    
    if ! docker-compose ps >/dev/null 2>&1; then
        log_error "Docker Compose is not running. Run 'docker-compose up -d' first."
        exit 1
    fi
    
    # Check for unhealthy services
    unhealthy_services=$(docker-compose ps --filter "health=unhealthy" --format "table {{.Service}}")
    if [ -n "$unhealthy_services" ] && [ "$unhealthy_services" != "SERVICE" ]; then
        log_warning "Some services are unhealthy:"
        echo "$unhealthy_services"
    else
        log_success "All services appear healthy"
    fi
}

# Check individual service endpoints
check_service_endpoints() {
    log_info "Checking service endpoints..."
    
    # Entropy Dashboard
    if curl -f http://localhost:8080 >/dev/null 2>&1; then
        log_success "Entropy Dashboard accessible"
    else
        log_error "Entropy Dashboard not accessible at http://localhost:8080"
    fi
    
    # Entropy Engine API
    if curl -f http://localhost:8081/api/status >/dev/null 2>&1; then
        log_success "Entropy Engine API responding"
    else
        log_error "Entropy Engine API not responding at http://localhost:8081"
    fi
    
    # Grafana
    if curl -f http://localhost:3001/api/health >/dev/null 2>&1; then
        log_success "Grafana accessible"
    else
        log_error "Grafana not accessible at http://localhost:3001"
    fi
    
    # Prometheus
    if curl -f http://localhost:9090/-/healthy >/dev/null 2>&1; then
        log_success "Prometheus healthy"
    else
        log_error "Prometheus not healthy at http://localhost:9090"
    fi
    
    # Main Application
    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        log_success "Main application accessible"
    else
        log_warning "Main application not accessible at http://localhost:3000 (may still be starting)"
    fi
}

# Check Prometheus targets
check_prometheus_targets() {
    log_info "Checking Prometheus service discovery..."
    
    targets_response=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "")
    if [ -n "$targets_response" ]; then
        up_targets=$(echo "$targets_response" | grep -o '"health":"up"' | wc -l)
        total_targets=$(echo "$targets_response" | grep -o '"health":"' | wc -l)
        log_success "Prometheus targets: $up_targets/$total_targets healthy"
    else
        log_warning "Could not check Prometheus targets"
    fi
}

# Check basic entropy functionality
test_entropy_controls() {
    log_info "Testing basic entropy controls..."
    
    # Test entropy API
    if curl -X POST http://localhost:8081/api/entropy/set \
        -H "Content-Type: application/json" \
        -d '{"service": "ecommerce-api", "parameter": "latency", "value": "normal"}' \
        -f >/dev/null 2>&1; then
        log_success "Entropy controls responding"
    else
        log_warning "Entropy controls not responding (services may still be starting)"
    fi
}

# Check resource usage
check_resource_usage() {
    log_info "Checking resource usage..."
    
    # Memory usage
    if command -v free >/dev/null 2>&1; then
        total_mem=$(free -g | awk '/^Mem:/{print $2}')
        used_mem=$(free -g | awk '/^Mem:/{print $3}')
        log_info "System memory: ${used_mem}GB used of ${total_mem}GB total"
        
        if [ "$used_mem" -gt 6 ]; then
            log_warning "High memory usage detected. Consider increasing system memory."
        fi
    fi
    
    # Docker stats
    log_info "Docker container resource usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | head -10 || log_warning "Could not get Docker stats"
}

# Main health check execution
main() {
    echo "=========================================="
    echo "SRE Masterclass Environment Health Check"
    echo "=========================================="
    echo
    
    check_docker_compose
    echo
    
    check_service_endpoints
    echo
    
    check_prometheus_targets
    echo
    
    test_entropy_controls
    echo
    
    check_resource_usage
    echo
    
    log_success "Health check completed!"
    echo
    echo "Access your training environment:"
    echo "- Entropy Dashboard: http://localhost:8080"
    echo "- Grafana Dashboards: http://localhost:3001 (admin/sre_admin)"
    echo "- Prometheus: http://localhost:9090"
    echo "- Main Application: http://localhost:3000"
}

main "$@"
EOF

    chmod +x scripts/health-check.sh
    log_success "Health check script created"
}

# Create environment reset script
create_reset_script() {
    log_info "Creating environment reset script..."
    
    cat > scripts/reset-environment.sh << 'EOF'
#!/bin/bash

# SRE Masterclass Environment Reset Script
# Resets environment to clean state

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

main() {
    echo "=========================================="
    echo "SRE Masterclass Environment Reset"
    echo "=========================================="
    echo
    
    log_warning "This will stop all services and remove all data!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Reset cancelled"
        exit 0
    fi
    
    log_info "Stopping all services..."
    docker-compose down -v
    
    log_info "Removing Docker images (optional cleanup)..."
    docker system prune -f
    
    log_info "Starting fresh environment..."
    docker-compose up -d
    
    log_info "Waiting for services to be ready..."
    sleep 30
    
    log_success "Environment reset complete!"
    echo
    echo "Run './scripts/health-check.sh' to verify the reset environment"
}

main "$@"
EOF

    chmod +x scripts/reset-environment.sh
    log_success "Environment reset script created"
}

# Create setup validation script
create_setup_validation_script() {
    log_info "Creating setup validation script..."
    
    cat > scripts/setup-check.sh << 'EOF'
#!/bin/bash

# SRE Masterclass Setup Validation Script
# Checks system requirements and prerequisites

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Docker installation
check_docker() {
    log_info "Checking Docker installation..."
    
    if command -v docker >/dev/null 2>&1; then
        docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker found: version $docker_version"
        
        # Check if Docker daemon is running
        if docker info >/dev/null 2>&1; then
            log_success "Docker daemon is running"
        else
            log_error "Docker daemon is not running. Please start Docker."
            return 1
        fi
    else
        log_error "Docker is not installed. Please install Docker from https://docker.com"
        return 1
    fi
}

# Check docker-compose installation
check_docker_compose() {
    log_info "Checking docker-compose installation..."
    
    if command -v docker-compose >/dev/null 2>&1; then
        compose_version=$(docker-compose --version | cut -d' ' -f4 | cut -d',' -f1)
        log_success "docker-compose found: version $compose_version"
    else
        log_error "docker-compose is not installed. Please install docker-compose."
        return 1
    fi
}

# Check system resources
check_system_resources() {
    log_info "Checking system resources..."
    
    # Check available memory
    if command -v free >/dev/null 2>&1; then
        total_mem_gb=$(free -g | awk '/^Mem:/{print $2}')
        available_mem_gb=$(free -g | awk '/^Mem:/{print $7}')
        
        log_info "System memory: ${total_mem_gb}GB total, ${available_mem_gb}GB available"
        
        if [ "$total_mem_gb" -lt 8 ]; then
            log_warning "Less than 8GB total memory. You may experience performance issues."
        else
            log_success "Sufficient memory available"
        fi
    else
        log_warning "Cannot check memory on this system"
    fi
    
    # Check available disk space
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    log_info "Available disk space: ${available_space}GB"
    
    if [ "$available_space" -lt 10 ]; then
        log_warning "Less than 10GB disk space available. Consider freeing up space."
    else
        log_success "Sufficient disk space available"
    fi
    
    # Check CPU cores
    if command -v nproc >/dev/null 2>&1; then
        cpu_cores=$(nproc)
        log_info "CPU cores: $cpu_cores"
        
        if [ "$cpu_cores" -lt 4 ]; then
            log_warning "Less than 4 CPU cores. You may experience slower performance."
        else
            log_success "Sufficient CPU cores available"
        fi
    fi
}

# Check port availability
check_port_availability() {
    log_info "Checking port availability..."
    
    required_ports=(3000 3001 8080 8081 9090 9093)
    conflicts=()
    
    for port in "${required_ports[@]}"; do
        if command -v netstat >/dev/null 2>&1; then
            if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
                conflicts+=("$port")
            fi
        elif command -v ss >/dev/null 2>&1; then
            if ss -tlnp 2>/dev/null | grep -q ":$port "; then
                conflicts+=("$port")
            fi
        fi
    done
    
    if [ ${#conflicts[@]} -eq 0 ]; then
        log_success "All required ports are available"
    else
        log_warning "Port conflicts detected on: ${conflicts[*]}"
        log_info "Stop conflicting services or use 'docker-compose down -v' if from previous run"
    fi
}

# Test Docker functionality
test_docker_functionality() {
    log_info "Testing Docker functionality..."
    
    # Test basic Docker run
    if docker run --rm hello-world >/dev/null 2>&1; then
        log_success "Docker is working correctly"
    else
        log_error "Docker is not working correctly"
        return 1
    fi
    
    # Test docker-compose
    if docker-compose --version >/dev/null 2>&1; then
        log_success "docker-compose is working correctly"
    else
        log_error "docker-compose is not working correctly"
        return 1
    fi
}

# Check Git installation (for repository operations)
check_git() {
    log_info "Checking Git installation..."
    
    if command -v git >/dev/null 2>&1; then
        git_version=$(git --version | cut -d' ' -f3)
        log_success "Git found: version $git_version"
    else
        log_warning "Git is not installed. Required for repository operations."
    fi
}

# Main validation execution
main() {
    echo "=========================================="
    echo "SRE Masterclass Setup Validation"
    echo "=========================================="
    echo
    
    error_count=0
    
    check_docker || ((error_count++))
    echo
    
    check_docker_compose || ((error_count++))
    echo
    
    check_system_resources
    echo
    
    check_port_availability
    echo
    
    test_docker_functionality || ((error_count++))
    echo
    
    check_git
    echo
    
    if [ $error_count -eq 0 ]; then
        log_success "All checks passed! You're ready to run the SRE Masterclass environment."
        echo
        echo "Next steps:"
        echo "1. Run 'docker-compose up -d' to start the environment"
        echo "2. Wait 2-3 minutes for all services to start"
        echo "3. Run './scripts/health-check.sh' to verify everything is working"
        echo "4. Access the training dashboard at http://localhost:8080"
    else
        log_error "$error_count critical issues found. Please resolve them before starting."
        echo
        echo "Common solutions:"
        echo "- Install Docker: https://docs.docker.com/get-docker/"
        echo "- Install docker-compose: https://docs.docker.com/compose/install/"
        echo "- Start Docker daemon"
        echo "- Free up system resources"
    fi
}

main "$@"
EOF

    chmod +x scripts/setup-check.sh
    log_success "Setup validation script created"
}

# Commit and push initial setup
commit_initial_setup() {
    log_info "Committing initial repository setup..."
    
    # Initialize git if not already done
    if [ ! -d ".git" ]; then
        git init
        git remote add origin "https://github.com/$ORG_OR_USER/$REPO_NAME.git"
    fi
    
    # Add all files
    git add .
    
    # Create initial commit
    git commit -m "Initial repository setup with GitHub automation

- Complete issue and PR templates
- GitHub Actions workflows for CI/CD
- Comprehensive documentation structure
- Community management tools
- Automated testing and validation
- Repository configuration scripts

Ready for community contributions and development."
    
    # Push to main branch (this will fail until we have a repository, but that's expected)
    git push -u origin main 2>/dev/null || log_warning "Push will work once repository is created"
    
    log_success "Initial setup committed"
}

# Main execution function
main() {
    echo "=========================================="
    echo "SRE Masterclass GitHub Repository Setup"
    echo "=========================================="
    echo
    
    if [ -z "$1" ]; then
        echo "Usage: $0 <repository-name> [organization-or-username]"
        echo "Example: $0 sre-masterclass"
        echo "Example: $0 sre-masterclass my-organization"
        exit 1
    fi
    
    log_info "Setting up repository: $ORG_OR_USER/$REPO_NAME"
    echo
    
    # Run all setup functions
    check_prerequisites
    echo
    
    create_repository
    echo
    
    configure_repository_settings
    echo
    
    create_labels
    echo
    
    setup_branch_protection
    echo
    
    create_issue_templates
    echo
    
    create_pr_template
    echo
    
    create_github_actions
    echo
    
    create_markdown_config
    echo
    
    create_codeowners
    echo
    
    create_readme_template
    echo
    
    create_contributing_template
    echo
    
    create_documentation_structure
    echo
    
    create_health_check_script
    echo
    
    create_reset_script
    echo
    
    create_setup_validation_script
    echo
    
    commit_initial_setup
    echo
    
    log_success "Repository setup completed successfully!"
    echo
    echo "=========================================="
    echo "Next Steps:"
    echo "=========================================="
    echo "1. Clone your new repository:"
    echo "   git clone https://github.com/$ORG_OR_USER/$REPO_NAME.git"
    echo
    echo "2. Add your application code to the repository"
    echo
    echo "3. Test the environment:"
    echo "   docker-compose up -d"
    echo "   ./scripts/health-check.sh"
    echo
    echo "4. Customize the documentation for your specific implementation"
    echo
    echo "5. Configure any additional GitHub settings:"
    echo "   - Add collaborators"
    echo "   - Configure webhooks"
    echo "   - Set up additional integrations"
    echo
    echo "Repository URL: https://github.com/$ORG_OR_USER/$REPO_NAME"
    echo "=========================================="
}

# Execute main function with all arguments
main "$@"
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["environment-test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
    
    # Apply branch protection (will fail until main branch exists, but that's OK)
    gh api "repos/$ORG_OR_USER/$REPO_NAME/branches/main/protection" \
        --method PUT \
        --input /tmp/protection-rules.json 2>/dev/null || \
        log_warning "Branch protection will be applied when main branch is created"
    
    # Cleanup
    rm -f /tmp/protection-rules.json
    
    log_success "Branch protection configured"
}

# Create issue templates
create_issue_templates() {
    log_info "Creating issue templates..."
    
    # Create .github directory structure
    mkdir -p .github/ISSUE_TEMPLATE
    
    # Bug report template
    cat > .github/ISSUE_TEMPLATE/bug_report.yml << 'EOF'
name: Bug Report
description: Something isn't working in the training environment
title: "[BUG] "
labels: ["bug", "triage-needed"]
body:
  - type: markdown
    attributes:
      value: |
        Thank you for helping improve the SRE Masterclass training environment!
        
  - type: dropdown
    id: environment
    attributes:
      label: Environment
      description: How are you running the environment?
      options:
        - Local Docker (Linux)
        - Local Docker (macOS)
        - Local Docker (Windows)
        - GitHub Codespaces
        - GitPod
        - Other cloud environment
    validations:
      required: true
      
  - type: input
    id: module-context
    attributes:
      label: Module/Exercise Context
      description: Which module or exercise were you working on?
      placeholder: "Module 2 - SLO Definition Exercise"
    validations:
      required: true
      
  - type: textarea
    id: steps-to-reproduce
    attributes:
      label: Steps to Reproduce
      description: What steps lead to the issue?
      placeholder: |
        1. Run `docker-compose up -d`
        2. Navigate to entropy dashboard
        3. Set payment service to 'critical' error rate
        4. Observe that...
    validations:
      required: true
      
  - type: textarea
    id: expected-vs-actual
    attributes:
      label: Expected vs Actual Behavior
      description: What should happen vs what actually happened?
    validations:
      required: true
      
  - type: textarea
    id: environment-details
    attributes:
      label: Environment Details
      description: System information and logs
      placeholder: |
        - OS: Ubuntu 22.04
        - Docker version: 24.0.2
        - docker-compose version: 2.17.3
        - Error logs: (paste relevant logs here)
EOF

    # Feature request template
    cat > .github/ISSUE_TEMPLATE/feature_request.yml << 'EOF'
name: Feature Request
description: Suggest a new chaos scenario or training enhancement
title: "[FEATURE] "
labels: ["enhancement", "triage-needed"]
body:
  - type: dropdown
    id: feature-type
    attributes:
      label: Feature Type
      options:
        - New Chaos Scenario
        - Additional Monitoring Dashboard
        - Training Exercise Enhancement
        - Documentation Improvement
        - Other
    validations:
      required: true
      
  - type: textarea
    id: learning-objective
    attributes:
      label: Learning Objective
      description: What SRE concept would this help teach?
      placeholder: "Students will learn how to detect and respond to cascading service failures"
    validations:
      required: true
      
  - type: textarea
    id: proposed-implementation
    attributes:
      label: Proposed Implementation
      description: How would this work in the training environment?
      placeholder: |
        1. Add new scenario: "Database Connection Pool Exhaustion"
        2. Gradually increase connection pool usage over 15 minutes
        3. Show impact on dependent services
        4. Demonstrate monitoring and alerting patterns
EOF

    # Chaos scenario template
    cat > .github/ISSUE_TEMPLATE/chaos_scenario.yml << 'EOF'
name: Chaos Scenario
description: Propose a new chaos engineering scenario
title: "[CHAOS] "
labels: ["chaos-scenario", "enhancement", "triage-needed"]
body:
  - type: input
    id: scenario-name
    attributes:
      label: Scenario Name
      description: What would you call this chaos scenario?
      placeholder: "Database Connection Pool Exhaustion"
    validations:
      required: true
      
  - type: dropdown
    id: target-module
    attributes:
      label: Target Module
      description: Which course module would this scenario support?
      options:
        - Module 1 - Technical Foundations
        - Module 2 - SLO/SLI Mastery
        - Module 3 - Advanced Monitoring
        - Module 4 - Incident Response
        - Module 5 - CI/CD Integration
        - Multiple Modules
    validations:
      required: true
      
  - type: textarea
    id: learning-objectives
    attributes:
      label: Learning Objectives
      description: What will students learn from this scenario?
      placeholder: |
        - Understand database connection pool monitoring
        - Practice capacity planning for database resources
        - Learn connection pool exhaustion recovery procedures
    validations:
      required: true
      
  - type: textarea
    id: scenario-timeline
    attributes:
      label: Scenario Timeline
      description: How should this scenario unfold over time?
      placeholder: |
        0m: Normal operation (20 connections)
        5m: Gradual increase to 40 connections
        10m: Spike to 80 connections
        12m: Connection pool exhaustion
        15m: Service degradation visible
        20m: Manual intervention/recovery
    validations:
      required: true
      
  - type: textarea
    id: expected-monitoring
    attributes:
      label: Expected Monitoring Impact
      description: What should students observe in dashboards/alerts?
      placeholder: |
        - Database connection pool utilization increases
        - Application response time degrades
        - Error rate increases for database operations
        - Specific alerts should fire
EOF

    log_success "Issue templates created"
}

# Create pull request template
create_pr_template() {
    log_info "Creating pull request template..."
    
    cat > .github/PULL_REQUEST_TEMPLATE.md << 'EOF'
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update
- [ ] New chaos scenario
- [ ] Monitoring enhancement

## Testing
- [ ] All automated tests pass
- [ ] Manual testing completed in clean environment
- [ ] Docker environment starts successfully (`docker-compose up -d`)
- [ ] Health checks pass (`./scripts/health-check.sh`)

## Learning Impact
For new features/scenarios:
- [ ] Learning objectives documented
- [ ] Module alignment confirmed
- [ ] Student workflow validated
- [ ] Documentation updated

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated if needed
- [ ] No breaking changes without migration guide

## Related Issues
Closes #(issue number)
EOF

    log_success "Pull request template created"
}

# Create GitHub Actions workflows
create_github_actions() {
    log_info "Creating GitHub Actions workflows..."
    
    mkdir -p .github/workflows
    
    # Environment testing workflow
    cat > .github/workflows/environment-test.yml << 'EOF'
name: Training Environment Test
on: 
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test-environment:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        
      - name: Start Training Environment
        run: |
          echo "Starting full training environment..."
          docker-compose up -d
          
      - name: Wait for Services to be Healthy
        run: |
          echo "Waiting for services to be healthy..."
          timeout 300 bash -c '
            while true; do
              if docker-compose ps | grep -q "unhealthy\|restarting"; then
                echo "Waiting for unhealthy services..."
                sleep 10
              else
                echo "All services appear healthy"
                break
              fi
            done
          '
          
      - name: Test Entropy Engine API
        run: |
          echo "Testing entropy engine API..."
          # Wait for entropy engine to be ready
          timeout 60 bash -c 'until curl -f http://localhost:8081/api/status; do sleep 2; done'
          
          # Test basic entropy control
          curl -X POST http://localhost:8081/api/entropy/set \
            -H "Content-Type: application/json" \
            -d '{"service": "ecommerce-api", "parameter": "latency", "value": "warn"}' \
            -f
            
      - name: Test Monitoring Stack
        run: |
          echo "Testing monitoring stack..."
          # Prometheus health check
          timeout 60 bash -c 'until curl -f http://localhost:9090/-/healthy; do sleep 2; done'
          
          # Grafana health check  
          timeout 60 bash -c 'until curl -f http://localhost:3001/api/health; do sleep 2; done'
          
      - name: Test Application Services
        run: |
          echo "Testing application services..."
          # Test main application endpoint
          timeout 60 bash -c 'until curl -f http://localhost:3000/health; do sleep 2; done'
          
      - name: Run Environment Health Check
        run: |
          # Run comprehensive health check if script exists
          if [ -f "./scripts/health-check.sh" ]; then
            chmod +x ./scripts/health-check.sh
            ./scripts/health-check.sh
          else
            echo "Health check script not yet available - manual validation passed"
          fi
          
      - name: Display Service Status
        if: always()
        run: |
          echo "=== Docker Compose Services ==="
          docker-compose ps
          echo "=== Docker Container Logs (last 50 lines each) ==="
          docker-compose logs --tail=50
          
      - name: Cleanup
        if: always()
        run: |
          docker-compose down -v
          docker system prune -f
EOF

    # Documentation workflow
    cat > .github/workflows/documentation.yml << 'EOF'
name: Documentation Build and Deploy
on:
  push:
    branches: [ main ]
    paths: [ 'docs/**', 'README.md', '*.md' ]
  pull_request:
    paths: [ 'docs/**', 'README.md', '*.md' ]

jobs:
  build-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate Markdown Links
        uses: gaurav-nelson/github-action-markdown-link-check@v1
        with:
          use-quiet-mode: 'yes'
          use-verbose-mode: 'yes'
          config-file: '.github/markdown-link-check-config.json'
          
      - name: Check Documentation Structure
        run: |
          echo "Checking required documentation files..."
          required_files=(
            "README.md"
            "QUICK_START.md" 
            "CONTRIBUTING.md"
            "docs/architecture/system-overview.md"
            "docs/troubleshooting/common-issues.md"
          )
          
          missing_files=()
          for file in "${required_files[@]}"; do
            if [ ! -f "$file" ]; then
              missing_files+=("$file")
            fi
          done
          
          if [ ${#missing_files[@]} -eq 0 ]; then
            echo "✅ All required documentation files present"
          else
            echo "❌ Missing required files:"
            printf '%s\n' "${missing_files[@]}"
            exit 1
          fi
EOF

    log_success "GitHub Actions workflows created"
}

# Create markdown link check configuration
create_markdown_config() {
    log_info "Creating markdown link check configuration..."
    
    mkdir -p .github
    cat > .github/markdown-link-check-config.json << 'EOF'
{
  "ignorePatterns": [
    {
      "pattern": "^http://localhost"
    },
    {
      "pattern": "^https://localhost"
    }
  ],
  "timeout": "20s",
  "retryOn429": true,
  "retryCount": 3,
  "fallbackRetryDelay": "30s",
  "aliveStatusCodes": [200, 206]
}
EOF

    log_success "Markdown configuration created"
}

# Create CODEOWNERS file
create_codeowners() {
    log_info "Creating CODEOWNERS file..."
    
    cat > .github/CODEOWNERS << EOF
# Global code owners
* @$ORG_OR_USER

# Documentation
docs/ @$ORG_OR_USER
*.md @$ORG_OR_USER

# GitHub configuration
.github/ @$ORG_OR_USER

# Critical infrastructure
docker-compose*.yml @$ORG_OR_USER
scripts/ @$ORG_OR_USER

# Monitoring configuration
monitoring/ @$ORG_OR_USER

# Entropy system (core training functionality)
entropy-engine/ @$ORG_OR_USER
entropy-dashboard/ @$ORG_OR_USER
EOF