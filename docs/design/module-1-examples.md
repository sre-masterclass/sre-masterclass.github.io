# Module 1 Examples: Technical Foundations

**Reference**: SRE Masterclass Specification - Phase 1: Technical Foundations

## Module 1.1: Monitoring Taxonomies Deep Dive Examples

### Taxonomy Comparison Matrix
```
Resource Type    | USE Metrics          | RED Metrics        | Four Golden Signals
CPU             | Utilization,         | N/A               | Latency, Traffic,
                | Saturation, Errors   |                   | Errors, Saturation
Disk            | Utilization,         | N/A               | Latency, Traffic,
                | Saturation, Errors   |                   | Errors, Saturation  
API Endpoint    | N/A                  | Rate, Errors,     | Latency, Traffic,
                |                      | Duration          | Errors, Saturation
Load Balancer   | Utilization,         | Rate, Errors,     | Latency, Traffic,
                | Saturation, Errors   | Duration          | Errors, Saturation
```

### Resource Type Mapping Exercise
```yaml
# Example taxonomy assignment for e-commerce system
microservices:
  checkout-api:
    taxonomy: RED
    justification: "User-facing endpoint, focus on throughput and user experience"
    metrics: ["request_rate", "error_rate", "response_duration"]
    
  payment-processor:
    taxonomy: "Four Golden Signals"
    justification: "Critical business component, needs capacity planning"
    metrics: ["latency", "traffic", "errors", "saturation"]
    
infrastructure:
  kubernetes-nodes:
    taxonomy: USE
    justification: "Infrastructure resource requiring efficiency optimization"
    metrics: ["cpu_utilization", "memory_saturation", "disk_errors"]
    
  load-balancer:
    taxonomy: "Four Golden Signals"  
    justification: "Traffic distribution point, burst management needed"
    metrics: ["request_latency", "request_traffic", "backend_errors", "connection_saturation"]
```

## Module 1.2: Environment Setup & Instrumentation Examples

### Shallow vs Deep Instrumentation Comparison

#### Shallow Instrumentation (Developer-focused)
```javascript
// Basic approach - just add logging
app.post('/checkout', (req, res) => {
  const startTime = Date.now();
  logger.info('checkout_attempt');
  
  try {
    // business logic
    const result = processCheckout(req.body);
    logger.info('checkout_success', { 
      latency: Date.now() - startTime 
    });
    res.json(result);
  } catch (error) {
    logger.error('checkout_error', { 
      error: error.message,
      latency: Date.now() - startTime 
    });
    res.status(500).json({ error: 'Checkout failed' });
  }
});
```

#### Deep Instrumentation (SRE-focused)
```javascript
// Advanced approach - custom metrics, histograms, labels
const client = require('prom-client');

// Histogram for latency measurement with proper buckets
const checkoutDuration = new client.Histogram({
  name: 'checkout_duration_seconds',
  help: 'Checkout processing time distribution',
  labelNames: ['payment_method', 'region', 'user_tier', 'status'],
  buckets: [0.1, 0.25, 0.5, 1, 2, 5, 10] // SLO-aligned buckets
});

// Counter for success/failure tracking
const checkoutTotal = new client.Counter({
  name: 'checkout_requests_total',
  help: 'Total checkout requests',
  labelNames: ['payment_method', 'region', 'user_tier', 'status']
});

// Gauge for current processing queue depth
const checkoutQueueDepth = new client.Gauge({
  name: 'checkout_queue_depth',
  help: 'Current number of checkout requests in queue'
});

app.post('/checkout', async (req, res) => {
  const timer = checkoutDuration.startTimer();
  checkoutQueueDepth.inc();
  
  const labels = {
    payment_method: req.body.paymentMethod || 'unknown',
    region: req.user?.region || 'unknown',
    user_tier: req.user?.tier || 'standard'
  };
  
  try {
    // Validate request (don't count validation errors in SLO)
    validateCheckoutRequest(req.body);
    
    const result = await processCheckout(req.body);
    
    // Record successful transaction
    const finalLabels = { ...labels, status: 'success' };
    checkoutTotal.inc(finalLabels);
    timer(finalLabels);
    
    res.json(result);
    
  } catch (error) {
    let status;
    if (error instanceof ValidationError) {
      status = 'validation_error'; // Exclude from SLO
    } else if (error instanceof PaymentError) {
      status = 'payment_error'; // Include in SLO
    } else {
      status = 'system_error'; // Include in SLO
    }
    
    const finalLabels = { ...labels, status };
    checkoutTotal.inc(finalLabels);
    timer(finalLabels);
    
    res.status(error.statusCode || 500).json({ 
      error: error.message 
    });
  } finally {
    checkoutQueueDepth.dec();
  }
});
```

### Instrumentation Strategy Pattern
```javascript
// Reusable instrumentation wrapper
class SREInstrumentation {
  constructor(serviceName) {
    this.serviceName = serviceName;
    this.setupMetrics();
  }
  
  setupMetrics() {
    this.duration = new client.Histogram({
      name: `${this.serviceName}_duration_seconds`,
      help: `${this.serviceName} operation duration`,
      labelNames: ['operation', 'status'],
      buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
    });
    
    this.requests = new client.Counter({
      name: `${this.serviceName}_requests_total`,
      help: `Total ${this.serviceName} requests`,
      labelNames: ['operation', 'status']
    });
  }
  
  instrumentOperation(operationName) {
    return (handler) => {
      return async (...args) => {
        const timer = this.duration.startTimer({ operation: operationName });
        
        try {
          const result = await handler(...args);
          this.requests.inc({ operation: operationName, status: 'success' });
          timer({ operation: operationName, status: 'success' });
          return result;
        } catch (error) {
          const status = this.classifyError(error);
          this.requests.inc({ operation: operationName, status });
          timer({ operation: operationName, status });
          throw error;
        }
      };
    };
  }
  
  classifyError(error) {
    if (error instanceof ValidationError) return 'validation_error';
    if (error instanceof TimeoutError) return 'timeout_error';
    if (error instanceof ExternalServiceError) return 'external_error';
    return 'system_error';
  }
}

// Usage in service
const sre = new SREInstrumentation('checkout');

const processCheckout = sre.instrumentOperation('process_checkout')(
  async (checkoutData) => {
    // Business logic here
    return await actualCheckoutProcessing(checkoutData);
  }
);
```

## Module 1.3: Black Box vs White Box Implementation Examples

### Black Box Monitoring (External Perspective)
```javascript
// Synthetic transaction monitoring
const syntheticCheckout = {
  name: 'synthetic_checkout_transaction',
  interval: '30s',
  timeout: '10s',
  
  async execute() {
    const startTime = Date.now();
    
    try {
      // Step 1: Create user session
      const session = await createTestSession();
      
      // Step 2: Add items to cart
      await addItemsToCart(session, testProducts);
      
      // Step 3: Process checkout
      const checkoutResult = await processTestCheckout(session);
      
      // Step 4: Verify order confirmation
      await verifyOrderConfirmation(checkoutResult.orderId);
      
      const duration = Date.now() - startTime;
      
      // Record successful synthetic transaction
      syntheticTransactionDuration.observe({ 
        transaction: 'checkout',
        status: 'success'
      }, duration / 1000);
      
      return { success: true, duration };
      
    } catch (error) {
      const duration = Date.now() - startTime;
      
      syntheticTransactionDuration.observe({
        transaction: 'checkout',
        status: 'failure'
      }, duration / 1000);
      
      // Alert on synthetic failure
      alertManager.send({
        severity: 'warning',
        summary: 'Synthetic checkout transaction failed',
        description: `User-facing checkout flow is broken: ${error.message}`
      });
      
      throw error;
    }
  }
};
```

### White Box Monitoring (Internal Perspective)
```javascript
// Internal resource monitoring
const resourceMonitor = {
  collectMetrics() {
    // CPU utilization
    const cpuUsage = process.cpuUsage();
    cpuUtilization.set(cpuUsage.user + cpuUsage.system);
    
    // Memory utilization
    const memUsage = process.memoryUsage();
    memoryUtilization.set(memUsage.heapUsed / memUsage.heapTotal);
    
    // Event loop lag (Node.js specific)
    const lag = measureEventLoopLag();
    eventLoopLag.set(lag);
    
    // Database connection pool
    const poolStats = dbPool.getStats();
    dbConnectionsActive.set(poolStats.active);
    dbConnectionsIdle.set(poolStats.idle);
    dbConnectionsWaiting.set(poolStats.waiting);
    
    // Queue depths
    redisQueue.length().then(length => {
      queueDepth.set({ queue: 'payment_processing' }, length);
    });
  }
};

// Correlation between black box and white box
const correlationAnalyzer = {
  analyze() {
    // When synthetic transactions fail, check internal metrics
    if (syntheticCheckoutFailures.get() > 0) {
      const cpuHigh = cpuUtilization.get() > 0.8;
      const memoryHigh = memoryUtilization.get() > 0.9;
      const queueBacklog = queueDepth.get() > 100;
      
      if (cpuHigh) {
        this.reportRootCause('High CPU utilization causing checkout failures');
      } else if (memoryHigh) {
        this.reportRootCause('Memory pressure affecting checkout performance');
      } else if (queueBacklog) {
        this.reportRootCause('Payment processing queue backlog');
      } else {
        this.reportRootCause('External dependency issue likely');
      }
    }
  }
};
```

### Environment Deployment Examples

#### Local Development Docker Compose
```yaml
# docker-compose.local.yml - Full featured local environment
version: '3.8'
services:
  checkout-service:
    build: ./services/checkout
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - LOG_LEVEL=debug
    volumes:
      - ./services/checkout:/app
      - /app/node_modules
    depends_on:
      - postgres
      - redis
      
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/rules:/etc/prometheus/rules
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      
volumes:
  prometheus_data:
  grafana_data:
  postgres_data:
```

#### Cloud-Optimized Docker Compose
```yaml
# docker-compose.cloud.yml - Lightweight for GitHub Codespaces
version: '3.8'
services:
  checkout-service:
    image: sre-masterclass/checkout:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=cloud
      - MEMORY_LIMIT=256m
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
          
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.cloud.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=1h'  # Reduced for cloud
      - '--storage.tsdb.retention.size=1GB'
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```