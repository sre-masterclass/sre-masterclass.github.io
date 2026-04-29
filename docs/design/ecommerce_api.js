// E-commerce API - Optimized for RED metrics demonstration
const express = require('express');
const client = require('prom-client');
const { createLogger } = require('winston');

class EcommerceAPI {
  constructor() {
    this.app = express();
    this.setupMetrics();
    this.setupRoutes();
    this.entropyConfig = {
      latency: { level: 'normal', base: 50, jitter: 25 },
      errorRate: { level: 'normal', rate: 0.001 },
      throughput: { level: 'normal', limit: null }
    };
  }

  setupMetrics() {
    // RED Metrics Implementation
    this.httpDuration = new client.Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request duration in seconds',
      labelNames: ['method', 'route', 'status_code', 'user_tier'],
      buckets: [0.1, 0.25, 0.5, 1, 2, 5, 10] // SLO-aligned buckets
    });

    this.httpRequests = new client.Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'route', 'status_code', 'user_tier']
    });

    this.checkoutAttempts = new client.Counter({
      name: 'checkout_attempts_total',
      help: 'Total checkout attempts',
      labelNames: ['payment_method', 'status', 'failure_reason']
    });

    this.inventoryOperations = new client.Counter({
      name: 'inventory_operations_total',
      help: 'Inventory check operations',
      labelNames: ['operation', 'status']
    });

    // Business Metrics for SLO Calculations
    this.orderValue = new client.Histogram({
      name: 'order_value_dollars',
      help: 'Order value distribution',
      buckets: [10, 25, 50, 100, 250, 500, 1000]
    });
  }

  setupRoutes() {
    // Middleware for metrics collection
    this.app.use(this.metricsMiddleware.bind(this));
    
    // Core e-commerce endpoints
    this.app.get('/products', this.getProducts.bind(this));
    this.app.post('/cart/add', this.addToCart.bind(this));
    this.app.post('/checkout', this.processCheckout.bind(this));
    this.app.get('/orders/:orderId', this.getOrder.bind(this));
    
    // Health and observability endpoints
    this.app.get('/health', this.healthCheck.bind(this));
    this.app.get('/metrics', (req, res) => {
      res.set('Content-Type', client.register.contentType);
      res.end(client.register.metrics());
    });

    // Entropy control endpoints
    this.app.post('/entropy/latency', this.setLatencyEntropy.bind(this));
    this.app.post('/entropy/errors', this.setErrorEntropy.bind(this));
    this.app.post('/entropy/throughput', this.setThroughputEntropy.bind(this));
  }

  async metricsMiddleware(req, res, next) {
    const start = Date.now();
    
    // Apply throughput limiting if configured
    if (this.entropyConfig.throughput.limit) {
      // Simple rate limiting implementation
      if (this.shouldThrottle()) {
        return res.status(429).json({ error: 'Rate limited' });
      }
    }
    
    res.on('finish', () => {
      const duration = (Date.now() - start) / 1000;
      const route = req.route ? req.route.path : req.path;
      const userTier = req.headers['x-user-tier'] || 'standard';
      
      const labels = {
        method: req.method,
        route: route,
        status_code: res.statusCode,
        user_tier: userTier
      };
      
      this.httpDuration.observe(labels, duration);
      this.httpRequests.inc(labels);
    });
    
    next();
  }

  async processCheckout(req, res) {
    const timer = this.httpDuration.startTimer();
    
    try {
      // Apply entropy-based latency
      await this.applyLatencyEntropy();
      
      // Apply entropy-based error injection
      if (this.shouldInjectError()) {
        throw new Error('Simulated checkout failure');
      }
      
      const { items, paymentMethod, userId } = req.body;
      
      // Validate request (exclude from SLO)
      if (!items || !paymentMethod) {
        this.checkoutAttempts.inc({ 
          payment_method: paymentMethod || 'unknown',
          status: 'validation_error',
          failure_reason: 'missing_required_fields'
        });
        return res.status(400).json({ error: 'Missing required fields' });
      }
      
      // Check inventory
      const inventoryCheck = await this.checkInventory(items);
      if (!inventoryCheck.available) {
        this.checkoutAttempts.inc({
          payment_method: paymentMethod,
          status: 'inventory_error', 
          failure_reason: 'insufficient_stock'
        });
        return res.status(409).json({ error: 'Insufficient inventory' });
      }
      
      // Process payment (calls payment service)
      const paymentResult = await this.processPayment({
        amount: inventoryCheck.totalAmount,
        method: paymentMethod,
        userId
      });
      
      if (!paymentResult.success) {
        this.checkoutAttempts.inc({
          payment_method: paymentMethod,
          status: 'payment_error',
          failure_reason: paymentResult.errorCode
        });
        return res.status(402).json({ error: 'Payment failed' });
      }
      
      // Create order
      const order = await this.createOrder({
        items,
        paymentResult,
        userId,
        totalAmount: inventoryCheck.totalAmount
      });
      
      // Record successful checkout
      this.checkoutAttempts.inc({
        payment_method: paymentMethod,
        status: 'success',
        failure_reason: 'none'
      });
      
      this.orderValue.observe(inventoryCheck.totalAmount);
      
      timer({ method: 'POST', route: '/checkout', status_code: 200 });
      
      res.json({
        success: true,
        orderId: order.id,
        totalAmount: inventoryCheck.totalAmount
      });
      
    } catch (error) {
      this.checkoutAttempts.inc({
        payment_method: req.body.paymentMethod || 'unknown',
        status: 'system_error',
        failure_reason: 'internal_error'
      });
      
      timer({ method: 'POST', route: '/checkout', status_code: 500 });
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Entropy injection methods
  async applyLatencyEntropy() {
    const config = this.entropyConfig.latency;
    let delay = config.base;
    
    switch (config.level) {
      case 'degraded':
        delay = 500 + Math.random() * 500; // 500-1000ms
        break;
      case 'critical':
        delay = 2000 + Math.random() * 3000; // 2-5 seconds
        break;
      default:
        delay = config.base + Math.random() * config.jitter;
    }
    
    await new Promise(resolve => setTimeout(resolve, delay));
  }

  shouldInjectError() {
    return Math.random() < this.entropyConfig.errorRate.rate;
  }

  setLatencyEntropy(req, res) {
    const { level } = req.body; // normal, degraded, critical
    this.entropyConfig.latency.level = level;
    res.json({ success: true, latencyLevel: level });
  }

  setErrorEntropy(req, res) {
    const { rate } = req.body; // 0.001 to 0.5
    this.entropyConfig.errorRate.rate = rate;
    res.json({ success: true, errorRate: rate });
  }
}

module.exports = EcommerceAPI;