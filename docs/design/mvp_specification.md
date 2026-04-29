# SRE Masterclass MVP Specification

## Project Overview

**Status**: Completed  
**Goal**: To validate the core entropy control concept with a minimal but complete implementation.  
**Success Criteria**: The MVP successfully demonstrated that a GUI entropy toggle could induce a service behavior change, which was then reflected in the monitoring metrics.

## MVP Scope & Features

### **Core Components**
1. **Entropy Engine** (Python FastAPI) - Central control system
2. **E-commerce Mock Service** (Python FastAPI) - Single training service 
3. **Vue.js Dashboard** - GUI entropy controls
4. **Monitoring Stack** - Basic Prometheus + Grafana

### **Functional Requirements**

#### Manual Entropy Controls
- **Latency Control**: normal (50-100ms) | warn (500-1000ms) | critical (2-5s) | custom (user-defined)
- **Error Rate Control**: normal (0.1%) | warn (5%) | critical (25%) | custom (user-defined)
- **Visual Feedback**: Service status indicators, real-time GUI updates
- **Metrics Impact**: Changes visible in Grafana within 10 seconds

#### Single Automated Scenario
- **"5-Minute Latency Spike"**: Demonstrates timeline execution capability
- **GUI Controls**: Start/stop scenario, progress indication
- **Timeline**: 0s→warn, 2m30s→critical, 5m→normal
- **Purpose**: Validate foundation for future complex scenarios

#### Monitoring Integration
- **RED Metrics**: Rate, Errors, Duration from e-commerce service
- **Prometheus Scraping**: Automatic metrics collection
- **Grafana Dashboard**: Pre-configured with basic SRE metrics
- **Real-time Updates**: 2-second polling for GUI status

## Technical Architecture

### **Technology Stack (Final Decisions)**
- **Backend**: Python + FastAPI + Poetry
- **Frontend**: Vue.js 3 + Composition API
- **Development**: Docker-based development with VSCode
- **Monitoring**: Prometheus + Grafana
- **State Management**: In-memory (MVP), Redis (future)
- **Service Discovery**: Manual configuration (MVP), auto-discovery (future)
- **API Design**: REST + periodic polling
- **Logging**: Structured logging (structlog) from start

### **Repository Structure**
```
sre-masterclass/
├── README.md
├── docker-compose.yml
├── docker-compose.dev.yml
├── .devcontainer/
│   └── devcontainer.json
│
├── entropy-engine/                 # Central control system
│   ├── main.py
│   ├── models/                    # Pydantic models
│   ├── core/                      # Config, logging, state
│   ├── api/                       # REST endpoints  
│   ├── scenarios/                 # Scenario execution
│   ├── pyproject.toml
│   └── Dockerfile
│
├── entropy-dashboard/              # Vue.js frontend
│   ├── src/
│   │   ├── components/
│   │   ├── services/              # API clients
│   │   ├── composables/           # Vue 3 composables
│   │   └── views/
│   ├── package.json
│   └── Dockerfile
│
├── services/                       # Mock applications
│   ├── ecommerce-api/             # MVP service
│   │   ├── main.py
│   │   ├── models/
│   │   ├── core/                  # Metrics, logging, entropy
│   │   ├── api/                   # Business + entropy endpoints
│   │   ├── services/              # Mock business logic
│   │   ├── pyproject.toml
│   │   └── Dockerfile
│   └── job-processor/
│       ├── main.go
│       ├── go.mod
│       ├── go.sum
│       └── Dockerfile
│
├── monitoring/                     # Pre-configured monitoring
│   ├── prometheus/
│   ├── grafana/
│   └── alertmanager/
│
└── tests/
    └── integration/               # End-to-end tests only
```

### **Data Flow Architecture**
```
┌─────────────────┐    HTTP REST     ┌─────────────────┐
│ Vue.js GUI      │◄────────────────►│ Entropy Engine  │
│ - Service Cards │  POST /entropy   │ (FastAPI)       │
│ - Toggles       │  GET /status     │ - In-memory     │
│ - Scenarios     │                  │ - Manual config │
└─────────────────┘                  └─────────┬───────┘
         ▲                                     │ HTTP REST
         │ 2s polling                          ▼
         │                           ┌─────────────────┐
         │              Prometheus   │ E-commerce API  │
         │              ◄────scrape──│ (FastAPI)       │
         │                           │ - RED metrics   │
         │                           │ - Entropy       │
┌────────▼─────────┐                 │   handlers      │
│ Grafana         │                 └─────────────────┘
│ - Dashboards    │
│ - Real-time     │
│   updates       │
└─────────────────┘
```

## Development Timeline

### **Week 1: Core Backend (Days 1-5)**

**Days 1-2: Entropy Engine**
- FastAPI application with structured logging
- In-memory state management
- Core API endpoints:
  - `POST /api/entropy/set` - Set entropy parameters
  - `GET /api/entropy/status` - Get current state
  - `GET /api/services` - List configured services
  - `POST /api/scenarios/run` - Execute simple scenario
- Manual service configuration
- Integration with e-commerce service

**Days 3-4: E-commerce Mock Service**  
- FastAPI application with Prometheus metrics
- Business endpoints:
  - `POST /checkout` - Primary business operation
  - `GET /products` - Supporting operation
  - `POST /cart/add` - Supporting operation
- Observability endpoints:
  - `GET /metrics` - Prometheus metrics
  - `GET /health` - Health check
- Entropy control endpoints:
  - `POST /entropy/latency` - Control response latency
  - `POST /entropy/errors` - Control error injection
- Background traffic simulation
- RED metrics implementation

**Day 5: Integration & Testing**
- Docker-compose setup for all services
- Prometheus configuration and scraping
- Basic Grafana dashboard
- Integration test suite
- Simple scenario executor
- End-to-end validation

### **Week 2: Frontend & Polish (Days 6-10)**

**Days 6-7: Vue.js Dashboard**
- Vue 3 application with Composition API
- Core components:
  - `ServiceCard.vue` - Individual service control
  - `EntropyToggle.vue` - Latency/error toggles  
  - `StatusIndicator.vue` - Visual service status
  - `MetricsPreview.vue` - Expected impact display
- API integration with HTTP client
- Reactive state management
- Real-time status polling (2-second intervals)

**Day 8: Automated Scenario**
- `ScenarioPanel.vue` component
- Simple scenario execution in GUI
- Progress indicators and timeline visualization
- Start/stop/reset functionality
- Integration with entropy engine scenario API

**Days 9-10: End-to-End Testing & Documentation**
- Complete integration testing
- Performance validation
- Setup and development documentation
- MVP demo preparation
- Bug fixes and polish

## Implementation Details

### **Structured Logging Standard**
```python
# Both services use structlog with JSON output
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        structlog.processors.add_logger_name,
        structlog.processors.JSONRenderer()
    ]
)

# Usage examples:
logger.info("entropy_changed", 
    service="ecommerce-api", 
    parameter="latency", 
    old_value="normal", 
    new_value="warn"
)
```

### **RED Metrics Implementation**
```python
# E-commerce service metrics
prometheus_metrics = {
    "http_requests_total": Counter(
        "http_requests_total",
        "Total HTTP requests", 
        ["method", "endpoint", "status"]
    ),
    "http_request_duration_seconds": Histogram(
        "http_request_duration_seconds", 
        "HTTP request duration",
        ["method", "endpoint"],
        buckets=[0.1, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0]
    )
}
```

### **Simple Scenario Definition**
```yaml
# 5-minute latency spike scenario
scenario:
  name: "5-Minute Latency Spike"
  duration: "5m"
  timeline:
    - time: "0s"
      action: "set_entropy"
      service: "ecommerce-api"
      parameter: "latency"
      value: "warn"
    - time: "2m30s"
      action: "set_entropy" 
      service: "ecommerce-api"
      parameter: "latency"
      value: "critical"
    - time: "5m"
      action: "set_entropy"
      service: "ecommerce-api" 
      parameter: "latency"
      value: "normal"
```

## Success Criteria & Validation

### **Week 1 Technical Validation**
- [x] Entropy engine accepts API calls and maintains state
- [x] E-commerce service responds to entropy changes
- [x] Latency changes are measurable and consistent
- [x] Error injection works with configurable rates
- [x] Prometheus metrics reflect entropy changes
- [x] Basic integration tests pass

### **Week 2 Complete MVP Validation**
- [x] GUI entropy toggles work end-to-end
- [x] Service status updates in real-time
- [x] Grafana dashboard shows metric changes within 10 seconds
- [x] Simple automated scenario executes successfully
- [x] `docker-compose up -d` creates working environment
- [x] Complete integration test suite passes (for implemented services)

### **Training Environment Readiness**
- ✅ Non-technical user can operate entropy controls
- ✅ Clear cause-and-effect between actions and metrics
- ✅ Suitable for Module 1-2 SRE training content
- ✅ Foundation established for rapid service expansion
- ✅ Scenario framework ready for complex chaos engineering

## Development Environment Setup

### **VSCode + Docker Configuration**
```json
// .devcontainer/devcontainer.json
{
    "name": "SRE Masterclass Dev",
    "dockerComposeFile": "docker-compose.dev.yml", 
    "service": "dev-workspace",
    "workspaceFolder": "/workspace",
    "postCreateCommand": "poetry install",
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",
                "ms-python.black-formatter",
                "ms-vscode.vscode-docker", 
                "octref.vetur"
            ]
        }
    }
}
```

### **Poetry + Docker Integration**
- Each Python service uses Poetry for dependency management
- Dockerfile multi-stage builds for development and production
- Hot reload enabled for both Python and Vue.js services
- Integrated debugging support in VSCode

## Integration Testing Strategy

### **Test Categories**
```python
class TestMVPWorkflow:
    def test_manual_entropy_control(self):
        """GUI toggle → API → Service → Metrics validation"""
        
    def test_error_injection(self):
        """Error rate control accuracy verification"""
        
    def test_automated_scenario(self):
        """Simple scenario execution validation"""
        
    def test_metrics_integration(self):
        """Prometheus scraping and Grafana display"""
```

### **Performance Requirements**
- Entropy changes take effect within 1 second
- GUI status updates within 2 seconds  
- Grafana metrics visible within 10 seconds
- Docker startup time under 5 minutes
- Scenario execution timing accuracy ±5 seconds

## Risk Mitigation

### **Technical Risks**
- **Docker complexity**: Use .devcontainer for consistent environment
- **Vue.js learning curve**: Focus on simple components first
- **Integration timing**: Build comprehensive integration tests
- **Metrics accuracy**: Validate entropy effects with automated tests

### **Scope Risks**
- **Feature creep**: Strict adherence to MVP feature list
- **Over-engineering**: In-memory state and manual config for simplicity
- **Timeline pressure**: Daily progress validation and scope adjustment

## Next Steps After MVP

### **Immediate Post-MVP (Week 3)**
- Additional mock services (auth, payment)
- Advanced entropy parameters (throughput, memory)
- More complex automated scenarios
- Enhanced Grafana dashboards

### **Module Integration (Weeks 4-6)**
- Module 1-2 specific training content
- SLO/SLI demonstration scenarios
- Business metrics and SLO calculations
- Training documentation and exercises

This MVP specification serves as the definitive guide for the initial 2-week development sprint, establishing the foundation for the complete SRE training environment.
