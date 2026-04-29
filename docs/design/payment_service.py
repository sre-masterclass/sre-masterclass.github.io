# Payment Processing Service - Latency and Consistency SLI showcase
from fastapi import FastAPI, HTTPException, Request
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import asyncio
import time
import random
import json
from typing import Dict, Any
from enum import Enum

class PaymentStatus(str, Enum):
    PENDING = "pending"
    AUTHORIZED = "authorized" 
    CAPTURED = "captured"
    FAILED = "failed"
    REFUNDED = "refunded"

class PaymentService:
    def __init__(self):
        self.app = FastAPI(title="Payment Processing Service")
        self.setup_metrics()
        self.setup_routes()
        self.entropy_config = {
            "latency": {"level": "normal", "base_ms": 100},
            "consistency": {"level": "normal", "stale_rate": 0.01},
            "external_errors": {"level": "normal", "rate": 0.005}
        }
        # Simulated external payment processor states
        self.external_processors = {
            "stripe": {"available": True, "latency_ms": 200},
            "paypal": {"available": True, "latency_ms": 300}, 
            "square": {"available": True, "latency_ms": 150}
        }
        
    def setup_metrics(self):
        # Latency SLI metrics
        self.payment_duration = Histogram(
            'payment_processing_duration_seconds',
            'Payment processing time distribution',
            labelnames=['processor', 'payment_method', 'status'],
            buckets=[0.1, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0]
        )
        
        self.payment_requests = Counter(
            'payment_requests_total',
            'Total payment processing requests',
            labelnames=['processor', 'payment_method', 'status']
        )
        
        # Consistency SLI metrics
        self.cache_operations = Counter(
            'cache_operations_total',
            'Cache operations for payment status',
            labelnames=['operation', 'result'] # hit, miss, stale
        )
        
        self.payment_state_consistency = Counter(
            'payment_state_consistency_total',
            'Payment state consistency checks',
            labelnames=['consistency_status'] # consistent, stale, conflicted
        )
        
        # External dependency metrics
        self.external_calls = Counter(
            'external_payment_calls_total',
            'Calls to external payment processors',
            labelnames=['processor', 'status']
        )
        
        self.external_latency = Histogram(
            'external_payment_latency_seconds',
            'External payment processor latency',
            labelnames=['processor'],
            buckets=[0.1, 0.25, 0.5, 1.0, 2.0, 5.0]
        )
        
        # Business metrics
        self.transaction_amounts = Histogram(
            'payment_transaction_amounts',
            'Payment transaction amounts',
            buckets=[10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
        )
        
        # Current state gauges
        self.active_transactions = Gauge(
            'active_payment_transactions',
            'Currently processing payment transactions'
        )

    def setup_routes(self):
        @self.app.post("/payments/authorize")
        async def authorize_payment(request: Request):
            return await self.process_payment_authorization(request)
            
        @self.app.post("/payments/{payment_id}/capture")
        async def capture_payment(payment_id: str):
            return await self.capture_payment(payment_id)
            
        @self.app.get("/payments/{payment_id}/status")
        async def get_payment_status(payment_id: str):
            return await self.get_payment_status_with_consistency_check(payment_id)
            
        @self.app.get("/health")
        async def health_check():
            return {"status": "healthy", "service": "payment-processor"}
            
        @self.app.get("/metrics")
        async def metrics():
            return generate_latest()
            
        # Entropy control endpoints
        @self.app.post("/entropy/latency")
        async def set_latency_entropy(request: Request):
            data = await request.json()
            self.entropy_config["latency"]["level"] = data["level"]
            return {"success": True, "latency_level": data["level"]}
            
        @self.app.post("/entropy/consistency")
        async def set_consistency_entropy(request: Request):
            data = await request.json()
            self.entropy_config["consistency"]["level"] = data["level"]
            return {"success": True, "consistency_level": data["level"]}

    async def process_payment_authorization(self, request: Request):
        """Process payment authorization with latency and consistency SLI tracking"""
        start_time = time.time()
        self.active_transactions.inc()
        
        try:
            data = await request.json()
            amount = data.get("amount")
            payment_method = data.get("payment_method", "credit_card")
            processor = data.get("processor", "stripe")
            
            # Apply entropy-based latency
            await self.apply_latency_entropy()
            
            # Check for entropy-based external errors
            if self.should_inject_external_error():
                self.external_calls.labels(processor=processor, status="error").inc()
                raise HTTPException(status_code=503, detail="External processor unavailable")
            
            # Simulate external processor call
            external_start = time.time()
            auth_result = await self.call_external_processor(processor, {
                "amount": amount,
                "method": payment_method,
                "action": "authorize"
            })
            external_duration = time.time() - external_start
            
            self.external_latency.labels(processor=processor).observe(external_duration)
            self.external_calls.labels(processor=processor, status="success").inc()
            
            # Store payment state with potential consistency issues
            payment_id = f"pay_{int(time.time() * 1000)}"
            await self.store_payment_state(payment_id, {
                "status": PaymentStatus.AUTHORIZED,
                "amount": amount,
                "processor": processor,
                "method": payment_method,
                "authorized_at": time.time()
            })
            
            # Record metrics
            duration = time.time() - start_time
            self.payment_duration.labels(
                processor=processor,
                payment_method=payment_method, 
                status="authorized"
            ).observe(duration)
            
            self.payment_requests.labels(
                processor=processor,
                payment_method=payment_method,
                status="success"
            ).inc()
            
            self.transaction_amounts.observe(amount)
            
            return {
                "payment_id": payment_id,
                "status": PaymentStatus.AUTHORIZED,
                "amount": amount,
                "processor": processor,
                "processing_time_ms": int(duration * 1000)
            }
            
        except Exception as e:
            duration = time.time() - start_time
            self.payment_requests.labels(
                processor="unknown",
                payment_method="unknown",
                status="error"
            ).inc()
            
            raise HTTPException(status_code=500, detail=str(e))
            
        finally:
            self.active_transactions.dec()

    async def get_payment_status_with_consistency_check(self, payment_id: str):
        """Get payment status with consistency SLI tracking"""
        
        # Try cache first
        cached_status = await self.get_cached_payment_status(payment_id)
        if cached_status:
            # Check if cache is stale (consistency SLI)
            cache_age = time.time() - cached_status.get("cached_at", 0)
            is_stale = cache_age > 30  # 30 seconds staleness threshold
            
            if is_stale and self.should_return_stale_data():
                self.cache_operations.labels(operation="read", result="stale").inc()
                self.payment_state_consistency.labels(consistency_status="stale").inc()
                return {**cached_status, "consistency_warning": "stale_data"}
            elif not is_stale:
                self.cache_operations.labels(operation="read", result="hit").inc()
                self.payment_state_consistency.labels(consistency_status="consistent").inc()
                return cached_status
        
        # Cache miss - fetch from authoritative source
        self.cache_operations.labels(operation="read", result="miss").inc()
        authoritative_status = await self.get_authoritative_payment_status(payment_id)
        
        # Update cache
        await self.cache_payment_status(payment_id, authoritative_status)
        
        self.payment_state_consistency.labels(consistency_status="consistent").inc()
        return authoritative_status

    async def apply_latency_entropy(self):
        """Apply configurable latency based on entropy settings"""
        config = self.entropy_config["latency"]
        base_delay = config["base_ms"] / 1000.0
        
        if config["level"] == "degraded":
            delay = 1.0 + random.random() * 2.0  # 1-3 seconds
        elif config["level"] == "critical": 
            delay = 3.0 + random.random() * 5.0  # 3-8 seconds
        else:
            delay = base_delay + random.random() * 0.1  # Normal jitter
            
        await asyncio.sleep(delay)

    def should_inject_external_error(self):
        """Determine if external error should be injected"""
        error_rate = self.entropy_config["external_errors"]["rate"]
        return random.random() < error_rate
        
    def should_return_stale_data(self):
        """Determine if stale data should be returned (consistency SLI)"""
        stale_rate = self.entropy_config["consistency"]["stale_rate"]
        return random.random() < stale_rate

    async def call_external_processor(self, processor: str, data: Dict[str, Any]):
        """Simulate external payment processor call"""
        processor_config = self.external_processors.get(processor, {"latency_ms": 200})
        
        # Simulate network latency
        await asyncio.sleep(processor_config["latency_ms"] / 1000.0)
        
        # Simulate processor response
        return {
            "transaction_id": f"ext_{processor}_{int(time.time() * 1000)}",
            "status": "authorized",
            "processor_response_time": processor_config["latency_ms"]
        }

    async def store_payment_state(self, payment_id: str, state: Dict[str, Any]):
        """Store payment state in database"""
        # Simulate database write
        await asyncio.sleep(0.05)  # 50ms DB write time
        
    async def get_cached_payment_status(self, payment_id: str):
        """Get payment status from cache"""
        # Simulate cache lookup
        await asyncio.sleep(0.01)  # 10ms cache lookup
        return None  # Simplified - would return actual cached data
        
    async def cache_payment_status(self, payment_id: str, status: Dict[str, Any]):
        """Cache payment status"""
        await asyncio.sleep(0.01)  # 10ms cache write
        
    async def get_authoritative_payment_status(self, payment_id: str):
        """Get payment status from authoritative source"""
        await asyncio.sleep(0.1)  # 100ms DB read
        return {
            "payment_id": payment_id,
            "status": PaymentStatus.AUTHORIZED,
            "last_updated": time.time()
        }

# Service instantiation and startup
service = PaymentService()
app = service.app