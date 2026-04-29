import time
import random
import time
import random
import asyncio
import uuid
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_client import make_asgi_app, Counter, Histogram, Summary, Gauge
from fastapi import FastAPI, Request, Response

app = FastAPI()

# In-memory store for entropy state
entropy_state = {"latency": 0, "error_rate": 0}

class LatencyPayload(BaseModel):
    latency: float

class ErrorRatePayload(BaseModel):
    error_rate: float

@app.middleware("http")
async def entropy_middleware(request, call_next):
    # Introduce latency
    if entropy_state["latency"] > 0:
        await asyncio.sleep(entropy_state["latency"])

    # Introduce errors
    if random.random() < entropy_state["error_rate"]:
        return Response("Internal Server Error", status_code=500)

    response = await call_next(request)
    return response

@app.post("/entropy/latency")
async def set_latency(payload: LatencyPayload):
    entropy_state["latency"] = payload.latency
    return {"message": f"Latency set to {payload.latency}"}

@app.post("/entropy/errors")
async def set_error_rate(payload: ErrorRatePayload):
    entropy_state["error_rate"] = payload.error_rate
    return {"message": f"Error rate set to {payload.error_rate}"}

# Define Prometheus metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "http_status"]
)
REQUEST_LATENCY = Histogram(
    "http_request_latency_seconds",
    "HTTP request latency",
    ["method", "endpoint"]
)

SLO_LATENCY_SECONDS = Summary(
    "payment_authorization_slo_latency_seconds",
    "Payment authorization latency SLO (99th percentile)",
    ["method", "endpoint"]
)

PROVIDER_LATENCY = Histogram(
    "payment_provider_latency_seconds",
    "Latency of the external payment provider",
    ["provider"]
)

PAYMENT_SUCCESS = Counter(
    "payment_authorizations_success_total",
    "Total successful payment authorizations"
)

PAYMENT_FAILURE = Counter(
    "payment_authorizations_failure_total",
    "Total failed payment authorizations"
)

TRANSACTION_CONSISTENCY = Gauge(
    "payment_transaction_consistency_ratio",
    "Ratio of consistent to inconsistent transactions"
)

# In-memory store for transaction states for simplicity
transaction_states = {}

# Mount the Prometheus metrics app
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# --- Configuration for External Provider Simulation ---
config = {
    "provider_latency_seconds": {
        "visa": random.uniform(0.1, 0.3),
        "mastercard": random.uniform(0.2, 0.5),
        "amex": random.uniform(0.3, 0.7),
        "default": random.uniform(0.1, 0.4)
    },
    "provider_failure_rate": {
        "visa": 0.05,
        "mastercard": 0.08,
        "amex": 0.1,
        "default": 0.07
    }
}

class PaymentRequest(BaseModel):
    card_number: str
    expiry_date: str
    cvv: str
    amount: float

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/")
def read_root():
    return {"Hello": "Payment API"}

@app.post("/authorize")
async def authorize_payment(request: Request, payment_request: PaymentRequest):
    """Simulates authorizing a payment through a third-party provider."""
    start_time = time.time()
    transaction_id = str(uuid.uuid4())
    transaction_states[transaction_id] = "processing"
    
    # Determine card type for simulation
    card_type = "default"
    if payment_request.card_number.startswith("4"):
        card_type = "visa"
    elif payment_request.card_number.startswith("5"):
        card_type = "mastercard"
    elif payment_request.card_number.startswith("3"):
        card_type = "amex"

    try:
        # Simulate network latency and processing time
        provider_start_time = time.time()
        base_latency = config["provider_latency_seconds"].get(card_type, config["provider_latency_seconds"]["default"])
        processing_time = random.uniform(0.1, 0.5)
        await asyncio.sleep(base_latency + processing_time)
        provider_end_time = time.time()
        PROVIDER_LATENCY.labels(provider=card_type).observe(provider_end_time - provider_start_time)

        # Simulate success/failure based on card type
        failure_rate = config["provider_failure_rate"].get(card_type, config["provider_failure_rate"]["default"])
        if random.random() < failure_rate:
            transaction_states[transaction_id] = "failed"
            PAYMENT_FAILURE.inc()
            REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, http_status=500).inc()
            raise HTTPException(status_code=500, detail=f"Payment authorization failed for {card_type}")

        transaction_states[transaction_id] = "success"
        PAYMENT_SUCCESS.inc()
        REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, http_status=200).inc()
        end_time = time.time()
        latency = end_time - start_time
        REQUEST_LATENCY.labels(method=request.method, endpoint=request.url.path).observe(latency)
        SLO_LATENCY_SECONDS.labels(method=request.method, endpoint=request.url.path).observe(latency)
        
        # Update consistency metric
        update_consistency_metric()
        
        return {"message": "Payment authorized", "transaction_id": transaction_id}
    except HTTPException as e:
        transaction_states[transaction_id] = "failed"
        end_time = time.time()
        latency = end_time - start_time
        REQUEST_LATENCY.labels(method=request.method, endpoint=request.url.path).observe(latency)
        SLO_LATENCY_SECONDS.labels(method=request.method, endpoint=request.url.path).observe(latency)
        
        # Update consistency metric
        update_consistency_metric()
        
        raise e

def update_consistency_metric():
    """Updates the transaction consistency metric."""
    consistent_count = sum(1 for state in transaction_states.values() if state in ["success", "failed"])
    inconsistent_count = len(transaction_states) - consistent_count
    
    if len(transaction_states) > 0:
        consistency_ratio = consistent_count / len(transaction_states)
        TRANSACTION_CONSISTENCY.set(consistency_ratio)
    else:
        TRANSACTION_CONSISTENCY.set(1.0)
