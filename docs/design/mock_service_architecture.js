// Mock E-commerce Service - Training-Focused Design
const express = require('express');
const client = require('prom-client');

class MockEcommerceService {
  constructor() {
    this.app = express();
    this.setupMetrics();
    this.setupRoutes();
    
    // Entropy state - this is what the GUI controls
    this.entropyState = {
      latency: { level: 'normal', customMs: null },
      errorRate: { level: 'normal', customRate: null },
      throughput: { level: 'normal', customLimit: null }
    };
    
    // Simulate realistic traffic patterns
    this.startTrafficSimulation();
  }

  setupMetrics() {
    // RED Metrics for SLO demonstrations
    this.httpDuration = new client.Histogram({
      name: 'checkout_duration_seconds',
      help: 'Checkout processing time',
      labelNames: ['status', 'user_tier', 'payment_method'],
      buckets: [0.1, 0.25, 0.5, 1, 2, 5, 10] // SLO-aligned: 1s threshold
    });

    this.httpRequests = new client.Counter({
      name: 'checkout_requests_total',
      help: 'Total checkout requests',
      labelNames: ['status', 'user_tier', 'payment_method']
    });

    // Business metrics for Module 2 (SLO/SLI)
    this.checkoutValue = new client.Histogram({
      name: 'checkout_value_dollars',
      help: 'Checkout transaction value',
      buckets: [10, 25, 50, 100, 250, 500, 1000]
    });

    // Queue saturation for Module 3 (Advanced Monitoring)
    this.processingQueue = new client.Gauge({
      name: 'checkout_queue_depth',
      help: 'Pending checkout requests'
    });

    // External dependency tracking for Module 4 (Incident Response)
    this.externalCalls = new client.Counter({
      name: 'external_service_calls_total',
      help: 'Calls to external services',
      labelNames: ['service', 'status']
    });
  }

  setupRoutes() {
    // Main application endpoints (generate realistic traffic)
    this.app.post('/checkout', this.simulateCheckout.bind(this));
    this.app.get('/products', this.simulateProductListing.bind(this));
    this.app.post('/cart/add', this.simulateCartOperation.bind(this));
    
    // Health and metrics
    this.app.get('/health', this.healthCheck.bind(this));
    this.app.get('/metrics', (req, res) => {
      res.set('Content-Type', client.register.contentType);
      res.end(client.register.metrics());
    });

    // Entropy control endpoints (called by Entropy Engine)
    this.app.post('/entropy/latency', this.setLatencyEntropy.bind(this));
    this.app.post('/entropy/errors', this.setErrorEntropy.bind(this));
    this.app.post('/entropy/throughput', this.setThroughputEntropy.bind(this));
  }

  async simulateCheckout(req, res) {
    const startTime = Date.now();
    
    // Apply current entropy state
    await this.applyLatencyEntropy();
    
    // Determine if this request should fail based on entropy
    const shouldFail = this.shouldFailRequest();
    const userTier = this.generateUserTier();
    const paymentMethod = req.body?.paymentMethod || this.generatePaymentMethod();
    const transactionValue = this.generateTransactionValue();
    
    try {
      if (shouldFail) {
        // Simulate different types of failures
        const failureType = this.determineFailureType();
        this.recordMetrics('failed', userTier, paymentMethod, startTime, 0);
        this.externalCalls.labels(failureType.service, 'error').inc();
        
        return res.status(failureType.statusCode).json({
          error: failureType.message,
          code: failureType.code
        });
      }

      // Simulate external service calls
      await this.simulateExternalServiceCalls();
      
      // Record successful transaction
      this.recordMetrics('success', userTier, paymentMethod, startTime, transactionValue);
      this.checkoutValue.observe(transactionValue);
      
      res.json({
        orderId: `order_${Date.now()}`,
        value: transactionValue,
        processingTime: Date.now() - startTime
      });
      
    } catch (error) {
      this.recordMetrics('error', userTier, paymentMethod, startTime, 0);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  async applyLatencyEntropy() {
    const config = this.entropyState.latency;
    let delayMs = 50; // Normal baseline
    
    if (config.customMs) {
      delayMs = config.customMs;
    } else {
      switch (config.level) {
        case 'warn':
          delayMs = 500 + Math.random() * 500; // 500-1000ms
          break;
        case 'critical':
          delayMs = 2000 + Math.random() * 3000; // 2-5s
          break;
        default:
          delayMs = 50 + Math.random() * 50; // 50-100ms
      }
    }
    
    await new Promise(resolve => setTimeout(resolve, delayMs));
  }

  shouldFailRequest() {
    const config = this.entropyState.errorRate;
    let errorRate = 0.001; // 0.1% baseline
    
    if (config.customRate !== null) {
      errorRate = config.customRate / 100;
    } else {
      switch (config.level) {
        case 'warn':
          errorRate = 0.05; // 5%
          break;
        case 'critical':
          errorRate = 0.25; // 25%
          break;
      }
    }
    
    return Math.random() < errorRate;
  }

  determineFailureType() {
    const failures = [
      { service: 'payment', statusCode: 502, message: 'Payment processor timeout', code: 'PAYMENT_TIMEOUT' },
      { service: 'inventory', statusCode: 409, message: 'Insufficient inventory', code: 'INVENTORY_ERROR' },
      { service: 'auth', statusCode: 401, message: 'Authentication failed', code: 'AUTH_FAILURE' },
      { service: 'database', statusCode: 500, message: 'Database connection error', code: 'DB_ERROR' }
    ];
    
    return failures[Math.floor(Math.random() * failures.length)];
  }

  async simulateExternalServiceCalls() {
    // Simulate calls to payment service, inventory service, etc.
    const services = ['payment', 'inventory', 'auth'];
    
    for (const service of services) {
      // Small delay to simulate network call
      await new Promise(resolve => setTimeout(resolve, 20 + Math.random() * 30));
      this.externalCalls.labels(service, 'success').inc();
    }
  }

  recordMetrics(status, userTier, paymentMethod, startTime, value) {
    const duration = (Date.now() - startTime) / 1000;
    
    const labels = { status, user_tier: userTier, payment_method: paymentMethod };
    this.httpDuration.observe(labels, duration);
    this.httpRequests.inc(labels);
  }

  generateUserTier() {
    const tiers = ['basic', 'premium', 'enterprise'];
    const weights = [0.7, 0.25, 0.05]; // Realistic distribution
    const random = Math.random();
    
    if (random < weights[0]) return tiers[0];
    if (random < weights[0] + weights[1]) return tiers[1];
    return tiers[2];
  }

  generatePaymentMethod() {
    const methods = ['credit_card', 'paypal', 'apple_pay', 'google_pay'];
    return methods[Math.floor(Math.random() * methods.length)];
  }

  generateTransactionValue() {
    // Realistic e-commerce distribution (log-normal)
    const base = Math.random() * Math.random() * 500 + 25;
    return Math.round(base * 100) / 100;
  }

  startTrafficSimulation() {
    // Generate realistic background traffic for training
    setInterval(() => {
      // Simulate automatic API calls for realistic metrics
      this.simulateBackgroundTraffic();
    }, 1000 + Math.random() * 2000); // Every 1-3 seconds
  }

  async simulateBackgroundTraffic() {
    // Create fake requests to generate realistic metric patterns
    const req = { body: { paymentMethod: this.generatePaymentMethod() } };
    const res = {
      status: () => ({ json: () => {} }),
      json: () => {}
    };
    
    // Only generate traffic if throughput isn't severely limited
    if (this.entropyState.throughput.level !== 'critical') {
      await this.simulateCheckout(req, res);
    }
  }

  // Entropy control endpoints
  setLatencyEntropy(req, res) {
    const { level, customMs } = req.body;
    this.entropyState.latency = { level, customMs };
    
    console.log(`Latency entropy set to: ${level}${customMs ? ` (${customMs}ms)` : ''}`);
    res.json({ success: true, state: this.entropyState.latency });
  }

  setErrorEntropy(req, res) {
    const { level, customRate } = req.body;
    this.entropyState.errorRate = { level, customRate };
    
    console.log(`Error rate entropy set to: ${level}${customRate ? ` (${customRate}%)` : ''}`);
    res.json({ success: true, state: this.entropyState.errorRate });
  }

  setThroughputEntropy(req, res) {
    const { level, customLimit } = req.body;
    this.entropyState.throughput = { level, customLimit };
    
    console.log(`Throughput entropy set to: ${level}${customLimit ? ` (${customLimit}/sec)` : ''}`);
    res.json({ success: true, state: this.entropyState.throughput });
  }

  healthCheck(req, res) {
    // Health check reflects current entropy state
    let status = 'healthy';
    let details = {};
    
    if (this.entropyState.latency.level === 'critical' || 
        this.entropyState.errorRate.level === 'critical') {
      status = 'unhealthy';
    } else if (this.entropyState.latency.level === 'warn' || 
               this.entropyState.errorRate.level === 'warn') {
      status = 'degraded';
    }
    
    details = {
      latency: this.entropyState.latency.level,
      errorRate: this.entropyState.errorRate.level,
      throughput: this.entropyState.throughput.level
    };
    
    const statusCode = status === 'healthy' ? 200 : status === 'degraded' ? 200 : 503;
    res.status(statusCode).json({ status, details, service: 'ecommerce-api' });
  }
}

// Export for use in docker-compose
module.exports = MockEcommerceService;

// Start server if run directly
if (require.main === module) {
  const service = new MockEcommerceService();
  const port = process.env.PORT || 3000;
  
  service.app.listen(port, () => {
    console.log(`Mock E-commerce Service running on port ${port}`);
    console.log(`Metrics available at http://localhost:${port}/metrics`);
  });
}