# SRE Masterclass MVP Development Plan

This document outlines the detailed plan for building the SRE Masterclass MVP.

### Phase 1: Project Scaffolding & Environment Setup (Day 1) - COMPLETE

1.  **Create Directory Structure:** - COMPLETE
2.  **Initialize Docker Environment:** - COMPLETE
    *   Create a `docker-compose.yml` to define the services: `entropy-engine`, `ecommerce-api`, `entropy-dashboard`, `prometheus`, and `grafana`.
    *   Create the `.devcontainer/devcontainer.json` file, adding any additional extensions I foresee being useful for Python/Vue development (e.g., linters, formatters).
3.  **Initialize Python Services:** - COMPLETE
    *   In both `entropy-engine/` and `services/ecommerce-api/`, run `poetry init` to create the `pyproject.toml` files. Add `fastapi`, `uvicorn`, `structlog`, `prometheus-client`, and `pyyaml` as dependencies.
4.  **Initialize Frontend Service:** - COMPLETE
    *   In `entropy-dashboard/`, set up a new Vue.js 3 project.

### Phase 2: Backend Development - E-commerce Mock Service (Days 2-3) - COMPLETE

1.  **Create FastAPI Application:** - COMPLETE
2.  **Implement Business Endpoints:** - COMPLETE
3.  **Implement RED Metrics:** - COMPLETE
    *   Add the `http_requests_total` counter and `http_request_duration_seconds` histogram.
    *   Apply these metrics as middleware to the FastAPI app to capture all requests.
4.  **Implement Entropy Handlers:** - COMPLETE
    *   Create internal logic to handle latency and error rate changes.
    *   Expose `POST /entropy/latency` and `POST /entropy/errors` endpoints that the Entropy Engine will call.
5.  **Implement Background Traffic Simulator:** - COMPLETE

### Phase 3: Backend Development - Entropy Engine (Days 4-5) - COMPLETE

1.  **Create FastAPI Application:** - COMPLETE
2.  **Design Pluggable State Management:** - COMPLETE
    *   Define a `StateStore` abstract base class.
    *   Implement an `InMemoryStateStore` that fulfills this contract for the MVP. This will make it easy to add a `RedisStateStore` in the future.
3.  **Implement Core API:** - COMPLETE
    *   `POST /api/entropy/set`: Updates the state in the state store and calls the corresponding service's entropy endpoint.
    *   `GET /api/entropy/status`: Retrieves the current state from the state store.
    *   `GET /api/services`: Returns a list of services from a configuration file.
4.  **Implement Scenario Engine:** - COMPLETE
    *   Create a YAML loader to parse scenario files (like the "5-Minute Latency Spike").
    *   Implement the `POST /api/scenarios/run` endpoint to execute the parsed scenario timeline in a background thread.

### Phase 4: Frontend Development - Vue.js Dashboard (Days 6-8) - COMPLETE

1.  **Develop Core Components:** - COMPLETE
    *   `ServiceCard.vue`: To display the status of a single service.
    *   `EntropyToggle.vue`: For manual control of latency and error rates.
2.  **Implement API Service:** - COMPLETE
3.  **Build Main View:** - COMPLETE
4.  **Add Scenario Panel:** - COMPLETE

### Phase 5: Integration, Monitoring & Validation (Days 9-10) - COMPLETE

1.  **Configure Monitoring:** - COMPLETE
    *   Set up `prometheus/prometheus.yml` to scrape metrics from the `ecommerce-api` service.
    *   Create a basic `grafana/provisioning/dashboards/dashboard.yml` and a `dashboard.json` file to display the RED metrics.
2.  **Finalize Docker Compose:** - COMPLETE
    *   Ensure all services start correctly and can communicate with each other.
3.  **Create Validation Script:** - COMPLETE
    *   Develop a Python script (`validate_mvp.py`) that uses `requests` to:
        1.  Call the Entropy Engine to set latency to "critical".
        2.  Confirm the status change via the status endpoint.
        3.  Make a request to the e-commerce service and measure the response time to verify the latency has increased.
        4.  Query the Prometheus API to ensure the metrics reflect the change.
        5.  Reset the entropy state to "normal".
4.  **Documentation:** - COMPLETE
    *   Write a `README.md` with setup and usage instructions for the MVP.

### Phase 6: Backend Development - Job Processor (Day 11) - COMPLETE

1.  **Add `go-redis` Dependency:** Add the `go-redis` library to the `go.mod` file. - COMPLETE
2.  **Implement Redis Connection:** Implement the logic to connect to the Redis service. - COMPLETE
3.  **Implement Queue Processing:** Create a loop that continuously listens for new jobs on a Redis queue (e.g., `job-queue`). - COMPLETE
4.  **Log Job Processing:** For each job, log a message indicating that the job has been received and processed. - COMPLETE
5.  **Update Integration Tests:** Update the integration tests to include a test case that adds a job to the queue and verifies that it is processed by the `job-processor` service. - COMPLETE

## Post-MVP Enhancements Completed

### Epic 3.1: Core Monitoring (Completed 6/27/2025)

1. **Prometheus Configuration:**
   - Extended scrape configurations for all services
   - Fixed job-processor port configuration (8005 → 8000)
   - Removed non-existent entropy-engine metrics endpoint

2. **SLO Recording Rules:**
   - Implemented comprehensive SLO rules in `monitoring/prometheus/rules/slo_rules.yml`
   - Availability SLOs with multi-window burn rate alerts
   - Latency SLOs (P99 < 500ms) with burn rate calculations
   - Error rate SLOs (< 1%) with appropriate thresholds
   - Transaction consistency metrics

3. **Grafana Dashboards:**
   - Created SLO Compliance Dashboard (`slo_dashboard.json`)
   - Created Resource Utilization Dashboard (`resource_utilization_dashboard.json`)
   - Created Entropy Scenarios Dashboard (`entropy_dashboard.json`)

4. **Service Fixes:**
   - Job Processor: Removed problematic OpenTelemetry, simplified to core functionality
   - Loki: Fixed permission issues by updating storage paths to /tmp
   - Promtail: Added Docker socket mount for container log collection
   - Entropy Dashboard: Fixed frontend bug with incorrect data types

All services are now healthy and the monitoring stack is fully operational.
