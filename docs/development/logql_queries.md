# LogQL Queries for SLI Extraction

This document provides a set of example LogQL queries that can be used to extract Service Level Indicators (SLIs) from the structured logs of the `ecommerce-api` and `job-processor` services.

## E-commerce API

### Availability SLI

This query calculates the percentage of successful requests (status code < 500) to the `/checkout` endpoint over the last 5 minutes.

```logql
(
  sum(rate({job="containerlogs", container="ecommerce-api-1"} | json | http_status_code < 500 and http_path="/checkout" [5m]))
  /
  sum(rate({job="containerlogs", container="ecommerce-api-1"} | json | http_path="/checkout" [5m]))
) * 100
```

### Latency SLI

This query calculates the 95th percentile of request latency for the `/checkout` endpoint over the last 5 minutes.

```logql
quantile_over_time(0.95, {job="containerlogs", container="ecommerce-api-1"} | json | unwrap duration [5m])
```

## Job Processor

### Throughput SLI

This query calculates the number of jobs processed per second over the last 5 minutes.

```logql
sum(rate({job="containerlogs", container="job-processor-1"} | json | msg="Processed job" [5m]))
```

### Latency SLI

This query calculates the 99th percentile of job processing duration over the last 5 minutes.

```logql
quantile_over_time(0.99, {job="containerlogs", container="job-processor-1"} | json | unwrap duration_ms [5m])
