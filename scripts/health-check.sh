#!/bin/bash
# This script checks the health of the running services.

echo "Checking service health..."

# Check ecommerce-api
curl --fail http://localhost:8000/ || { echo "ecommerce-api health check failed"; exit 1; }
echo "ecommerce-api is healthy."

# Check entropy-dashboard
curl --fail http://localhost:8080/ || { echo "entropy-dashboard health check failed"; exit 1; }
echo "entropy-dashboard is healthy."

# Check Grafana
curl --fail http://localhost:3000/api/health || { echo "Grafana health check failed"; exit 1; }
echo "Grafana is healthy."

# Check Prometheus
curl --fail http://localhost:9090/-/healthy || { echo "Prometheus health check failed"; exit 1; }
echo "Prometheus is healthy."

# Check Alertmanager
curl --fail http://localhost:9093/-/healthy || { echo "Alertmanager health check failed"; exit 1; }
echo "Alertmanager is healthy."

echo "All services are healthy."
exit 0
