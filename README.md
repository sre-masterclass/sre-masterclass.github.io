# SRE Masterclass

This project contains the applications and infrastructure for the SRE Masterclass course. It is a hands-on environment for learning Site Reliability Engineering principles.

## Quick Start

This project is designed to run with Docker and Docker Compose.

1.  **Prerequisites:**
    *   Docker
    *   Docker Compose V2 (i.e., the `docker compose` command)

2.  **Build and Run:**
    From the root of the project, run the following command:
    ```bash
    docker compose up --build
    ```

3.  **Accessing Services:**
    Once the stack is running, you can access the services at the following URLs:

    *   **E-commerce API:** [http://localhost:8001](http://localhost:8001)
    *   **Entropy Engine:** [http://localhost:8002](http://localhost:8002)
    *   **Payment API:** [http://localhost:8003](http://localhost:8003)
    *   **Auth API:** [http://localhost:8004](http://localhost:8004)
    *   **Job Processor:** [http://localhost:8005](http://localhost:8005)
    *   **Entropy Dashboard:** [http://localhost:3000](http://localhost:3000)
    *   **Frontend (E-commerce UI):** [http://localhost:3002](http://localhost:3002)
    *   **Prometheus:** [http://localhost:9090](http://localhost:9090)
    *   **Grafana:** [http://localhost:3001](http://localhost:3001) (Default credentials: `admin` / `admin`)
    *   **Jaeger (Tracing):** [http://localhost:16686](http://localhost:16686)
    *   **Alertmanager:** [http://localhost:9093](http://localhost:9093)

## Project Structure

-   `services/`: Contains the mock microservices for the training environment.
    -   `ecommerce-api/`: A Python/FastAPI service simulating an e-commerce backend.
    -   `job-processor/`: A Go service for processing background jobs.
    -   `payment-api/`: A Python/FastAPI service simulating payment processing.
    -   `auth-api/`: A Python/FastAPI service for authentication.
    -   `frontend/`: A React-based e-commerce UI.
-   `entropy-engine/`: The central Python/FastAPI service for controlling the chaos and entropy within the environment.
-   `entropy-dashboard/`: The Vue.js frontend for interacting with the Entropy Engine.
-   `monitoring/`: Contains the configuration for the monitoring stack.
    -   `prometheus/`: Prometheus configuration and SLO recording rules.
    -   `grafana/`: Grafana dashboards and provisioning.
    -   `alertmanager/`: Alert routing configuration.
    -   `loki/`: Log aggregation configuration.
    -   `promtail/`: Log shipping configuration.
-   `docs/`: Project documentation, including design and planning documents.
-   `tests/`: Integration and validation tests.

## Monitoring Stack

The project includes a comprehensive monitoring stack:

### Dashboards (Grafana)
- **SLO Compliance Dashboard**: Real-time SLO status, burn rates, and error budgets
- **Resource Utilization Dashboard**: CPU, memory, network I/O, and disk usage
- **Entropy Scenarios Dashboard**: Visualizes chaos engineering impacts
- **E-commerce Dashboard**: Application-specific metrics

### SLO Definitions
- **Availability SLO**: 99.9% uptime with multi-window burn rate alerts
- **Latency SLO**: 99th percentile < 500ms
- **Error Rate SLO**: < 1% error rate
- **Transaction Consistency**: Data integrity monitoring

### Observability Features
- Distributed tracing with Jaeger
- Log aggregation with Loki
- Metrics collection with Prometheus
- Alert management with Alertmanager

## Running Tests

To run the integration tests, first ensure the Docker Compose stack is running. Then, from the root of the project, execute the following commands:

```bash
cd tests
poetry install --no-root
poetry run pytest
```
