import time
import random
import asyncio
import httpx
import json
from fastapi import FastAPI, Request, HTTPException, Depends
from pydantic import BaseModel
from prometheus_client import make_asgi_app, Counter, Histogram
from sqlalchemy.orm import Session
from tenacity import retry, stop_after_attempt, wait_exponential, RetryError
from pybreaker import CircuitBreaker, CircuitBreakerError

import models
import database
from cache import r
from core.tracing import init_tracer
from core.logging import add_opentelemetry_context
import structlog
from opentelemetry import trace

models.Base.metadata.create_all(bind=database.engine)

# --- Structlog Configuration ---
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        add_opentelemetry_context,
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)
logger = structlog.get_logger()

app = FastAPI()

# Initialize tracer before adding any middleware or routes
init_tracer(app)
tracer = trace.get_tracer(__name__)

# --- Service Clients ---
payment_api_client = httpx.AsyncClient(base_url="http://payment-api:8000")

# --- Circuit Breaker ---
payment_breaker = CircuitBreaker(fail_max=5, reset_timeout=60)

# --- Entropy State ---
class EntropySettings(BaseModel):
    latency: float = 0.05
    error_rate: float = 0.0
    throughput: float = 1.0  # as a percentage of normal

entropy_settings = EntropySettings()

# --- Metrics Definitions ---
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP Requests",
    ["method", "endpoint", "http_status"]
)
REQUEST_LATENCY = Histogram(
    'http_request_latency_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

# Mount the Prometheus metrics app
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# --- Middleware for Metrics & Entropy ---
@app.middleware("http")
async def track_metrics_and_inject_entropy(request: Request, call_next):
    # Skip entropy for metrics and entropy endpoints
    if request.url.path in ["/metrics", "/entropy/latency", "/entropy/errors", "/entropy/throughput"]:
        return await call_next(request)

    start_time = time.time()

    # Inject latency
    time.sleep(entropy_settings.latency)

    # Inject errors
    if random.random() < entropy_settings.error_rate:
        REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, http_status=500).inc()
        end_time = time.time()
        REQUEST_LATENCY.labels(method=request.method, endpoint=request.url.path).observe(end_time - start_time)
        raise HTTPException(status_code=500, detail="Internal Server Error")

    # Throttle throughput
    if random.random() > entropy_settings.throughput:
        REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path, http_status=429).inc()
        end_time = time.time()
        REQUEST_LATENCY.labels(method=request.method, endpoint=request.url.path).observe(end_time - start_time)
        raise HTTPException(status_code=429, detail="Too Many Requests")

    response = await call_next(request)
    end_time = time.time()
    duration = end_time - start_time
    
    endpoint = request.url.path
    method = request.method
    status_code = response.status_code

    REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(duration)
    REQUEST_COUNT.labels(method=method, endpoint=endpoint, http_status=status_code).inc()

    logger.info(
        "http_request",
        http_method=method,
        http_path=endpoint,
        http_status_code=status_code,
        duration=duration,
    )
    
    return response

# --- Entropy Control Endpoints ---
class LatencyRequest(BaseModel):
    latency: float

class ErrorRateRequest(BaseModel):
    error_rate: float

class ThroughputRequest(BaseModel):
    throughput: float

@app.post("/entropy/latency")
async def set_latency(req: LatencyRequest):
    entropy_settings.latency = req.latency
    return {"message": f"Latency set to {req.latency}s"}

@app.post("/entropy/errors")
async def set_error_rate(req: ErrorRateRequest):
    entropy_settings.error_rate = req.error_rate
    return {"message": f"Error rate set to {req.error_rate}"}

@app.post("/entropy/throughput")
async def set_throughput(req: ThroughputRequest):
    entropy_settings.throughput = req.throughput
    return {"message": f"Throughput set to {req.throughput}"}


# --- Background Traffic Simulator ---
async def simulate_traffic():
    """A simple async task to simulate user traffic."""
    endpoints = ["/", "/products", "/checkout", "/cart/add"]
    methods = {
        "/": "GET",
        "/products": "GET",
        "/checkout": "POST",
        "/cart/add": "POST"
    }
    
    async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
        while True:
            try:
                endpoint = random.choice(endpoints)
                method = methods[endpoint]
                if method == "GET":
                    await client.get(endpoint)
                else:
                    await client.post(endpoint)
            except httpx.RequestError as e:
                print(f"Traffic simulator request failed: {e}")

            await asyncio.sleep(random.uniform(0.1, 0.5))

@app.on_event("startup")
async def startup_event():
    # Seed the database with some products if it's empty
    db = database.SessionLocal()
    if db.query(models.Product).count() == 0:
        db.add(models.Product(name="Laptop", description="A powerful laptop", price=1200.00))
        db.add(models.Product(name="Keyboard", description="A mechanical keyboard", price=150.00))
        db.add(models.Product(name="Mouse", description="A wireless mouse", price=50.00))
        db.commit()
    db.close()
    asyncio.create_task(simulate_traffic())


# --- Business Endpoints ---
@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/")
def read_root():
    return {"Hello": "E-commerce API"}

@app.post("/checkout")
@retry(wait=wait_exponential(multiplier=1, min=4, max=10), stop=stop_after_attempt(3))
async def checkout():
    with tracer.start_as_current_span("checkout") as span:
        try:
            # Call payment API with circuit breaker
            @payment_breaker
            async def call_payment_api():
                with tracer.start_as_current_span("call_payment_api") as child_span:
                    response = await payment_api_client.post("/authorize", json={"card_number": "1234", "expiry_date": "12/25", "cvv": "123", "amount": 100.0})
                    child_span.set_attribute("http.status_code", response.status_code)
                    return response

            response = await call_payment_api()
            response.raise_for_status()
            logger.info("checkout_successful", order_id="some-order-id")
            return {"message": "Checkout successful"}
        except CircuitBreakerError as e:
            logger.error("payment_service_unavailable", error=str(e))
            span.record_exception(e)
            span.set_status(trace.StatusCode.ERROR, "Payment service is unavailable")
            raise HTTPException(status_code=503, detail="Payment service is unavailable")
        except RetryError as e:
            logger.error("payment_service_timeout", error=str(e))
            span.record_exception(e)
            span.set_status(trace.StatusCode.ERROR, "Payment service timed out")
            raise HTTPException(status_code=504, detail="Payment service timed out")
        except Exception as e:
            logger.error("checkout_failed", error=str(e))
            span.record_exception(e)
            span.set_status(trace.StatusCode.ERROR, "Checkout failed")
            raise HTTPException(status_code=500, detail="Internal Server Error")

@app.get("/products")
async def get_products(db: Session = Depends(database.get_db)):
    cached_products = r.get("products")
    if cached_products:
        return json.loads(cached_products)
    
    products = db.query(models.Product).all()
    # Convert products to a list of dicts to make it JSON serializable
    products_dict = [{"id": p.id, "name": p.name, "description": p.description, "price": p.price} for p in products]
    r.set("products", json.dumps(products_dict))
    return products_dict

class ProductCreate(BaseModel):
    name: str
    description: str
    price: float

@app.post("/products")
async def create_product(product: ProductCreate, db: Session = Depends(database.get_db)):
    db_product = models.Product(**product.dict())
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    r.delete("products")
    return db_product

@app.post("/cart/add")
async def add_to_cart():
    # time.sleep(0.01) # Simulate work - now handled by middleware
    return {"message": "Item added to cart"}

@app.post("/orders")
async def create_order(db: Session = Depends(database.get_db)):
    # In a real application, you would get the cart from the current user's session
    # For simplicity, we'll create an order with a single, hardcoded item
    db_order = models.Order()
    db.add(db_order)
    db.commit()
    db.refresh(db_order)

    db_item = models.OrderItem(order_id=db_order.id, product_id=1, quantity=1)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)

    return {"id": db_order.id}
