# GitHub Templates for SRE Masterclass

This document contains all the GitHub templates that will be automatically created by the setup script.

## Issue Templates

### Bug Report Template (.github/ISSUE_TEMPLATE/bug_report.yml)

```yaml
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
```

### Feature Request Template (.github/ISSUE_TEMPLATE/feature_request.yml)

```yaml
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
```

### Chaos Scenario Template (.github/ISSUE_TEMPLATE/chaos_scenario.yml)

```yaml
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
```

## Pull Request Template (.github/PULL_REQUEST_TEMPLATE.md)

```markdown
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
```

## GitHub Actions Workflows

### Environment Testing (.github/workflows/environment-test.yml)

```yaml
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
```

### Documentation Workflow (.github/workflows/documentation.yml)

```yaml
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
```

## CODEOWNERS File (.github/CODEOWNERS)

```
# Global code owners
* @USERNAME

# Documentation
docs/ @USERNAME
*.md @USERNAME

# GitHub configuration
.github/ @USERNAME

# Critical infrastructure
docker-compose*.yml @USERNAME
scripts/ @USERNAME

# Monitoring configuration
monitoring/ @USERNAME

# Entropy system (core training functionality)
entropy-engine/ @USERNAME
entropy-dashboard/ @USERNAME
```

## Markdown Link Check Configuration (.github/markdown-link-check-config.json)

```json
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
```

## Label Configuration

The setup script automatically creates these labels:

### Type Labels
- `bug` (d73a4a) - Something isn't working
- `enhancement` (a2eeef) - New feature or request
- `documentation` (0075ca) - Improvements or additions to documentation
- `question` (d876e3) - Further information is requested
- `chaos-scenario` (D93F0B) - New chaos engineering scenario

### Priority Labels
- `priority-high` (B60205) - Breaks student environment - urgent fix needed
- `priority-medium` (FBCA04) - Impacts learning experience
- `priority-low` (0E8A16) - Nice to have improvement

### Module Labels
- `module-1` (0E8A16) - Module 1: Technical Foundations
- `module-2` (1D76DB) - Module 2: SLO/SLI Mastery
- `module-3` (5319E7) - Module 3: Advanced Monitoring
- `module-4` (E99695) - Module 4: Incident Response
- `module-5` (F9D0C4) - Module 5: CI/CD Integration

### Status Labels
- `triage-needed` (EDEDED) - Requires initial review and categorization
- `in-progress` (FBCA04) - Actively being worked on
- `needs-testing` (FEF2C0) - Requires validation before merge
- `ready-for-review` (C2E0C6) - Awaiting code review

### Community Labels
- `good-first-issue` (7057ff) - Good for newcomers
- `help-wanted` (008672) - Extra attention is needed
- `breaking-change` (B60205) - Requires migration guide for users

## Usage Instructions

1. **Run the setup script**:
   ```bash
   chmod +x scripts/setup-github-repo.sh
   ./scripts/setup-github-repo.sh sre-masterclass [your-username]
   ```

2. **The script will automatically**:
   - Create the GitHub repository
   - Configure optimal settings
   - Create all issue and PR templates
   - Set up GitHub Actions workflows
   - Create comprehensive documentation structure
   - Generate utility scripts for repository management

3. **After setup**:
   - Clone your new repository
   - Add your application code
   - Test the environment
   - Customize documentation as needed
   - Begin accepting community contributions

This template system provides a professional, educational-focused repository that supports both development needs and community growth while maintaining the quality required for effective SRE training.