# Module 5, Entropy Engineering & Cloud Deployment Examples

**Reference**: SRE Masterclass Specification - Phase 5: CI/CD, Technical Architecture (Entropy), Cloud Deployment

## Module 5: SRE in CI/CD Examples

### SLO-Based Deployment Gates
```yaml
# CI/CD pipeline with SLO enforcement
deployment_pipeline:
  pre_deployment_checks:
    slo_validation:
      - name: "Error Budget Check"
        condition: "error_budget_remaining > 10%"
        action_on_failure: "block_deployment"
        
      - name: "Recent Incident Check"  
        condition: "incidents_last_24h < 2"
        action_on_failure: "require_approval"
        
      - name: "Load Test SLO"
        condition: "load_test_p95_latency < 500ms"
        action_on_failure: "block_deployment"
        
  deployment_gates:
    canary_validation:
      traffic_percentage: 5
      duration: "10 minutes"
      success_criteria:
        - "error_rate < 1%"
        - "latency_p95 < 1000ms"
        - "no_5xx_errors_for_5min"
      rollback_triggers:
        - "error_rate > 5%"
        - "latency_p95 > 2000ms"
        
    full_deployment:
      prerequisites:
        - "canary_success == true"
        - "manual_approval == true"  # For critical services
      monitoring_period: "30 minutes"
      
# GitHub Actions workflow example
github_actions_slo_gates: |
  name: Deploy with SLO Gates
  on:
    push:
      branches: [main]
      
  jobs:
    slo-validation:
      runs-on: ubuntu-latest
      outputs:
        error-budget: ${{ steps.check-budget.outputs.remaining }}
        deployment-approved: ${{ steps.slo-gate.outputs.approved }}
      steps:
        - name: Check Error Budget
          id: check-budget
          run: |
            # Query Prometheus for error budget status
            BUDGET=$(curl -s "${PROMETHEUS_URL}/api/v1/query" \
              --data-urlencode 'query=error_budget_remaining_percent' | \
              jq -r '.data.result[0].value[1]')
            echo "remaining=${BUDGET}" >> $GITHUB_OUTPUT
            
        - name: SLO Gate Decision
          id: slo-gate
          run: |
            if (( $(echo "${{ steps.check-budget.outputs.remaining }} > 10" | bc -l) )); then
              echo "approved=true" >> $GITHUB_OUTPUT
            else
              echo "approved=false" >> $GITHUB_OUTPUT
              exit 1
            fi
            
    deploy:
      needs: slo-validation
      if: needs.slo-validation.outputs.deployment-approved == 'true'
      runs-on: ubuntu-latest
      steps:
        - name: Deploy Application
          run: kubectl apply -f k8s/
          
        - name: Monitor Post-Deployment SLO
          run: |
            # Wait 10 minutes and check SLO compliance
            sleep 600
            ./scripts/validate-post-deployment-slo.sh
```

### Chaos Engineering Integration
```yaml
# Automated chaos experiments in CI/CD
chaos_engineering_pipeline:
  staging_chaos_tests:
    - name: "Payment Service Latency"
      target: "payment-service"
      experiment: "add_latency_500ms"
      duration: "5 minutes"
      success_criteria: "checkout_slo_compliance > 85%"
      
    - name: "Database Connection Chaos"
      target: "postgres"
      experiment: "kill_random_connections"
      percentage: 30
      success_criteria: "api_error_rate < 10%"
      
    - name: "Network Partition Simulation"
      target: "checkout-service"
      experiment: "network_partition"
      affected_services: ["payment", "inventory"]
      success_criteria: "circuit_breaker_activated"

  production_chaos_schedule:
    schedule: "0 14 * * MON-FRI"  # Weekdays at 2 PM
    experiments:
      - name: "Container Resource Limits"
        probability: 0.1  # 10% chance to run
        target: "non-critical-services"
        experiment: "cpu_stress"
        intensity: "50%"
        
# Chaos experiment configuration
chaos_experiment_definitions:
  memory_exhaustion:
    description: "Simulate gradual memory leak"
    target_service: "checkout-service"
    implementation: |
      # Inject memory allocation code
      setInterval(() => {
        global.memoryLeak = global.memoryLeak || [];
        global.memoryLeak.push(Buffer.alloc(1024 * 1024)); // 1MB per second
      }, 1000);
    
    monitoring_expectations:
      - "container_memory_usage increases linearly"
      - "oom_killer activates after ~15 minutes"
      - "kubernetes restarts container automatically"
      - "service recovers within 2 minutes"
      
  network_latency_injection:
    description: "Add variable network latency to external calls"
    target: "payment-processing"
    implementation: |
      # Network delay simulation
      const originalFetch = global.fetch;
      global.fetch = async (url, options) => {
        if (url.includes('external-payment-api')) {
          const delay = Math.random() * 2000 + 500; // 500-2500ms
          await new Promise(resolve => setTimeout(resolve, delay));
        }
        return originalFetch(url, options);
      };
```

### Performance Regression Detection
```yaml
# Automated performance testing in pipeline
performance_regression_detection:
  load_test_configuration:
    baseline_establishment:
      duration: "10 minutes"
      ramp_up: "2 minutes" 
      virtual_users: 100
      target_endpoints:
        - "/api/checkout"
        - "/api/payment/process"
        - "/api/user/profile"
        
    regression_thresholds:
      latency_p95: "+20% from baseline"
      latency_p99: "+30% from baseline"
      throughput: "-10% from baseline"
      error_rate: "+5% from baseline"
      
  k6_load_test_script: |
    import http from 'k6/http';
    import { check, sleep } from 'k6';
    
    export let options = {
      stages: [
        { duration: '2m', target: 100 },
        { duration: '10m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      thresholds: {
        http_req_duration: ['p(95)<1000'], // 95% < 1s
        http_req_failed: ['rate<0.05'],    // Error rate < 5%
      },
    };
    
    export default function() {
      let response = http.post('http://api/checkout', {
        user_id: '12345',
        items: [{ id: 'item1', quantity: 1 }],
        payment_method: 'credit_card'
      });
      
      check(response, {
        'checkout successful': (r) => r.status === 200,
        'checkout under 1s': (r) => r.timings.duration < 1000,
      });
      
      sleep(1);
    }
    
  performance_comparison: |
    # Compare current performance to baseline
    #!/bin/bash
    CURRENT_P95=$(cat k6-results.json | jq '.metrics.http_req_duration.values.p95')
    BASELINE_P95=$(cat baseline-results.json | jq '.metrics.http_req_duration.values.p95')
    
    REGRESSION_PCT=$(echo "scale=2; ($CURRENT_P95 - $BASELINE_P95) / $BASELINE_P95 * 100" | bc)
    
    if (( $(echo "$REGRESSION_PCT > 20" | bc -l) )); then
      echo "Performance regression detected: ${REGRESSION_PCT}% increase in P95 latency"
      exit 1
    fi
```

## Entropy Engineering System Examples

### Comprehensive Entropy Engine Architecture
```javascript
// Complete entropy injection framework
class EntropyEngine {
  constructor() {
    this.scenarios = new Map();
    this.activeExperiments = new Set();
    this.resourceMonitor = new ResourceMonitor();
    this.scheduledEvents = new Map();
  }
  
  // Level 1: Simple toggles
  setServiceState(service, parameter, level) {
    const config = {
      latency: {
        normal: { delay: 50, jitter: 25 },
        degraded: { delay: 500, jitter: 200 },
        critical: { delay: 2000, jitter: 1000 }
      },
      errors: {
        normal: { rate: 0.001 },
        degraded: { rate: 0.05 },
        critical: { rate: 0.25 }
      },
      throughput: {
        normal: { limit: null },
        degraded: { limit: 50 }, // req/sec
        critical: { limit: 10 }
      }
    };
    
    this.applyEntropyToService(service, parameter, config[parameter][level]);
  }
  
  // Level 2: Resource exhaustion patterns
  simulateResourceExhaustion(service, resource, pattern) {
    const patterns = {
      memory: {
        gradual: this.createMemoryLeakPattern(),
        sudden: this.createMemorySpike(),
        oscillating: this.createMemoryOscillation()
      },
      cpu: {
        gradual: this.createCPUBurnPattern(),
        sudden: this.createCPUSpike(), 
        oscillating: this.createCPUOscillation()
      }
    };
    
    return patterns[resource][pattern](service);
  }
  
  createMemoryLeakPattern() {
    return {
      name: 'memory_leak',
      timeline: [
        { time: '0m', allocation: '200MB', rate: '5MB/min' },
        { time: '5m', allocation: '225MB', rate: '10MB/min' },
        { time: '10m', allocation: '275MB', rate: '20MB/min' },
        { time: '15m', allocation: '375MB', rate: '50MB/min' },
        { time: '18m', allocation: '525MB', rate: '100MB/min' },
        { time: '20m', allocation: '725MB', trigger: 'oom_kill' }
      ]
    };
  }
  
  // Level 3: Complex chaos scenarios
  runChaosExperiment(experimentConfig) {
    const experiment = {
      id: this.generateExperimentId(),
      config: experimentConfig,
      startTime: Date.now(),
      hypothesis: experimentConfig.hypothesis,
      successCriteria: experimentConfig.successCriteria
    };
    
    this.activeExperiments.add(experiment);
    this.executeExperimentSteps(experiment);
    return experiment.id;
  }
  
  // Realistic failure patterns
  deploymentFailurePattern() {
    return {
      name: 'monday_deployment_failure',
      schedule: '0 18 * * MON', // Every Monday 6 PM
      steps: [
        {
          time: '0s',
          action: 'increase_error_rate',
          target: 'payment_service',
          value: '15%',
          reason: 'database_migration_conflict'
        },
        {
          time: '30s',
          action: 'cascade_to_service',
          target: 'checkout_service', 
          effect: 'timeout_errors',
          reason: 'payment_dependency_failure'
        },
        {
          time: '2m',
          action: 'resource_exhaustion',
          target: 'auth_service',
          resource: 'memory',
          reason: 'increased_retry_load'
        }
      ]
    };
  }
}

// Frontend entropy control interface
const EntropyDashboard = {
  renderControls() {
    return `
      <div class="entropy-controls">
        <h2>System Entropy Controls</h2>
        
        <div class="service-controls">
          <h3>Checkout Service</h3>
          <label>Latency:</label>
          <select id="checkout-latency">
            <option value="normal">Normal (50-100ms)</option>
            <option value="degraded">Degraded (500-1000ms)</option>
            <option value="critical">Critical (2000-5000ms)</option>
          </select>
          
          <label>Error Rate:</label>
          <select id="checkout-errors">
            <option value="normal">Normal (0.1%)</option>
            <option value="degraded">Degraded (5%)</option>
            <option value="critical">Critical (25%)</option>
          </select>
        </div>
        
        <div class="chaos-scenarios">
          <h3>Chaos Scenarios</h3>
          <button onclick="triggerScenario('payment_outage')">
            Payment Provider Outage
          </button>
          <button onclick="triggerScenario('database_slowdown')">
            Database Slowdown
          </button>
          <button onclick="triggerScenario('memory_leak')">
            Memory Leak Simulation
          </button>
        </div>
        
        <div class="resource-exhaustion">
          <h3>Resource Exhaustion</h3>
          <button onclick="exhaustResource('checkout', 'memory', 'gradual')">
            Gradual Memory Leak
          </button>
          <button onclick="exhaustResource('payment', 'cpu', 'spike')">
            CPU Spike
          </button>
        </div>
      </div>
    `;
  }
};
```

### Memory Exhaustion Detailed Implementation
```javascript
// Detailed memory exhaustion scenario
const memoryExhaustionScenario = {
  name: "checkout_memory_leak",
  description: "Simulate memory leak in checkout service leading to OOM kill",
  
  implementation: {
    type: "resource_exhaustion",
    resource: "memory",
    pattern: "gradual",
    
    timeline: [
      {
        time: "0m",
        memory_usage: "200MB",
        heap_size: "180MB", 
        status: "normal",
        action: "baseline_allocation"
      },
      {
        time: "5m",
        memory_usage: "350MB",
        heap_size: "320MB",
        status: "elevated", 
        action: "start_memory_leak",
        leak_rate: "10MB/min"
      },
      {
        time: "10m", 
        memory_usage: "500MB",
        heap_size: "470MB",
        status: "warning",
        action: "increase_leak_rate",
        leak_rate: "25MB/min"
      },
      {
        time: "12m",
        memory_usage: "600MB", 
        heap_size: "570MB",
        status: "critical",
        action: "gc_pressure_increases"
      },
      {
        time: "15m",
        memory_usage: "800MB",
        heap_size: "780MB", 
        status: "critical",
        action: "performance_degradation_visible"
      },
      {
        time: "18m",
        memory_usage: "1.2GB",
        heap_size: "1.18GB",
        status: "oom_imminent",
        action: "container_memory_limit_approached"
      },
      {
        time: "20m",
        memory_usage: "1.5GB",
        status: "oom_kill",
        action: "kubernetes_kills_container"
      },
      {
        time: "22m",
        memory_usage: "200MB",
        status: "recovering", 
        action: "kubernetes_restarts_container"
      }
    ]
  },
  
  monitoring_expectations: {
    prometheus_metrics: [
      "container_memory_usage_bytes increases linearly",
      "go_memstats_heap_inuse_bytes follows similar pattern",
      "container_memory_oom_kills_total increments at 20m mark"
    ],
    
    alerts_triggered: [
      { name: "HighMemoryUsage", time: "10m" },
      { name: "ContainerOOMKilled", time: "20m" },
      { name: "ServiceRestarted", time: "22m" }
    ],
    
    slo_impact: {
      metric: "checkout_latency_p95",
      degradation_start: "12m",
      max_impact: "15m-20m", 
      recovery_time: "2-3 minutes post-restart"
    }
  },
  
  learning_objectives: [
    "Understand gradual vs sudden resource exhaustion patterns",
    "Observe correlation between memory pressure and response latency",
    "Experience automatic recovery through container orchestration",
    "Practice memory leak investigation techniques"
  ]
};
```

## Cloud Deployment Examples

### GitHub Codespaces Configuration
```json
// .devcontainer/devcontainer.json
{
  "name": "SRE Masterclass",
  "dockerComposeFile": "docker-compose.yml",
  "service": "workspace",
  "workspaceFolder": "/workspace", 
  
  "postCreateCommand": "make setup",
  
  "forwardPorts": [
    3000,  // Frontend
    3001,  // Grafana
    9090,  // Prometheus
    3100,  // Loki
    8080   // Entropy Engine
  ],
  
  "portsAttributes": {
    "3000": {
      "label": "Application Frontend",
      "onAutoForward": "openPreview"
    },
    "3001": {
      "label": "Grafana",
      "onAutoForward": "notify"
    },
    "9090": {
      "label": "Prometheus", 
      "onAutoForward": "ignore"
    }
  },
  
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "ms-vscode.vscode-json"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  },
  
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:1": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {}
  }
}
```

### Cloud-Optimized Docker Compose
```yaml
# docker-compose.cloud.yml - Optimized for GitHub Codespaces
version: '3.8'

services:
  # Lightweight application services
  frontend:
    image: sre-masterclass/frontend:latest
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:3002
      - NODE_ENV=development
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
          
  checkout-service:
    image: sre-masterclass/checkout:latest
    ports:
      - "3002:3000"
    environment:
      - NODE_ENV=cloud
      - DATABASE_URL=postgresql://user:pass@postgres:5432/checkout
      - REDIS_URL=redis://redis:6379
      - ENTROPY_ENGINE_URL=http://entropy-engine:8080
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    depends_on:
      - postgres
      - redis
      
  # Monitoring stack - cloud optimized
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.cloud.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/rules:/etc/prometheus/rules
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=2h'    # Reduced for cloud
      - '--storage.tsdb.retention.size=1GB'
      - '--web.enable-lifecycle'
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
          
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_SECURITY_ADMIN_USER=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
          
  # Essential infrastructure
  postgres:
    image: postgres:13-alpine
    environment:
      - POSTGRES_DB=checkout
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
          
  redis:
    image: redis:7-alpine
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.25'
          
  # Entropy control system
  entropy-engine:
    image: sre-masterclass/entropy-engine:latest
    ports:
      - "8080:8080"
    volumes:
      - ./entropy-configs:/configs
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - SCENARIOS_PATH=/configs/scenarios
      - DOCKER_HOST=unix:///var/run/docker.sock
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'

volumes:
  postgres_data:

networks:
  default:
    name: sre-masterclass
```

### Quick Setup and Validation Scripts
```bash
#!/bin/bash
# scripts/setup-cloud.sh - Cloud environment setup

echo "🚀 Setting up SRE Masterclass Cloud Environment"
echo "=============================================="

# Check resource availability
echo "📊 Checking system resources..."
FREE_MEM=$(free -g | awk '/^Mem:/{print $7}')
if [ $FREE_MEM -lt 4 ]; then
    echo "⚠️  Warning: Only ${FREE_MEM}GB memory available (4GB+ recommended)"
fi

# Start services in dependency order
echo "🐳 Starting infrastructure services..."
docker-compose -f docker-compose.cloud.yml up -d postgres redis

echo "⏳ Waiting for databases to be ready..."
sleep 10

echo "🚀 Starting application services..."
docker-compose -f docker-compose.cloud.yml up -d

echo "📊 Starting monitoring stack..."
docker-compose -f docker-compose.cloud.yml up -d prometheus grafana

echo "🎮 Starting entropy engine..."
docker-compose -f docker-compose.cloud.yml up -d entropy-engine

# Validate services
echo "🔍 Validating service health..."
./scripts/health-check.sh

echo "✅ SRE Masterclass environment ready!"
echo ""
echo "📱 Access points:"
echo "  Frontend:        http://localhost:3000"
echo "  Grafana:         http://localhost:3001 (admin/admin)"
echo "  Prometheus:      http://localhost:9090"
echo "  Entropy Engine:  http://localhost:8080"
```

### Cost Analysis for Different Platforms
```yaml
# Cloud platform cost comparison
platform_costs:
  github_codespaces:
    free_tier: "60 hours/month for personal accounts"
    cost_per_hour:
      "2_core_4gb": "$0.09"
      "4_core_8gb": "$0.18"
      "8_core_16gb": "$0.36"
    
    course_cost_estimate:
      duration: "40 hours"
      recommended_config: "4_core_8gb"
      total_cost: "$7.20"
      
  gitpod:
    free_tier: "50 hours/month"
    cost_per_hour:
      standard: "$0.09"
      large: "$0.18"
    
    course_cost_estimate:
      duration: "40 hours"
      overage_hours: "0 (fits in free tier)"
      total_cost: "$0"
      
  railway:
    pricing_model: "usage_based"
    base_cost: "$5/month"
    additional_usage: "$0.000463/GB-hour"
    
    course_cost_estimate:
      duration: "1 month"
      estimated_usage: "20 GB-hours"
      total_cost: "$5 + $0.01 = $5.01"

student_recommendations:
  primary: "GitHub Codespaces"
  reasoning: 
    - "Most consistent with development workflows"
    - "Integrated with VS Code"
    - "Automatic port forwarding"
    - "Cost-effective for course duration"
    
  alternative: "Local development"
  fallback: "GitPod for immediate free access"
```