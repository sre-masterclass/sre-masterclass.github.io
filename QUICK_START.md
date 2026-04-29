# Quick Start Guide

This guide will get you up and running with the SRE Masterclass environment in 5 minutes.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- A web browser

## Installation

1.  **Clone the repository:**

    ```sh
    git clone https://github.com/your-repo/sre-masterclass.git
    cd sre-masterclass
    ```

2.  **Start the environment:**

    ```sh
    docker-compose up -d
    ```

    This will build the Docker images and start all the services in the background. It may take a few minutes the first time you run it.

## Accessing the Services

Once the environment is running, you can access the different components:

- **E-commerce API:** [http://localhost:8001](http://localhost:8001)
- **E-commerce API Metrics:** [http://localhost:8001/metrics](http://localhost:8001/metrics)
- **Entropy Engine:** [http://localhost:8002](http://localhost:8002)
- **Entropy Dashboard:** [http://localhost:3000](http://localhost:3000)
- **Payment API**: `http://localhost:8003`
- **Prometheus:** [http://localhost:9090](http://localhost:9090)
- **Grafana:** [http://localhost:3001](http://localhost:3001) (Default credentials: `admin` / `admin`)

## Stopping the Environment

To stop all the services, run:

```sh
docker-compose down
```

## Troubleshooting

If you run into any issues, please check the [issue tracker](https://github.com/your-repo/sre-masterclass/issues) or [create a new issue](https://github.com/your-repo/sre-masterclass/issues/new/choose).
