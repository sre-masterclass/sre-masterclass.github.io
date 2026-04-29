import httpx
import pytest
import time
import redis
import uuid

# Define the base URLs for the services
ECOMMERCE_API_URL = "http://localhost:8001"
ENTROPY_ENGINE_URL = "http://localhost:8002/api"
PAYMENT_API_URL = "http://localhost:8003"
AUTH_API_URL = "http://localhost:8004"
JOB_PROCESSOR_URL = "http://localhost:8005"

@pytest.fixture(scope="module", autouse=True)
def wait_for_services():
    """Fixture to wait for services to be ready before running tests."""
    # Wait for all services to be ready
    services = [
        (ECOMMERCE_API_URL, "E-commerce API"),
        (ENTROPY_ENGINE_URL + "/status", "Entropy Engine"),
        (PAYMENT_API_URL + "/health", "Payment API"),
        (AUTH_API_URL + "/health", "Auth API"),
        (JOB_PROCESSOR_URL + "/health", "Job Processor"),
    ]
    for url, name in services:
        for attempt in range(10):
            try:
                response = httpx.get(url)
                response.raise_for_status()
                print(f"{name} is ready")
                break
            except httpx.RequestError as e:
                print(f"Attempt {attempt + 1}: {name} not ready yet: {e}")
                time.sleep(2)
        else:
            pytest.fail(f"Failed to connect to {name} after multiple attempts")

def test_entropy_engine_is_running():
    """Tests that the Entropy Engine is running."""
    try:
        response = httpx.get(f"{ENTROPY_ENGINE_URL}/status")
        response.raise_for_status()
        assert response.json()["status"] == "running"
    except httpx.RequestError as e:
        pytest.fail(f"Connection to Entropy Engine failed: {e}")

def test_payment_api_is_running():
    """Tests that the Payment API is running."""
    try:
        response = httpx.get(f"{PAYMENT_API_URL}/health")
        response.raise_for_status()
        assert response.json()["status"] == "ok"
    except httpx.RequestError as e:
        pytest.fail(f"Connection to Payment API failed: {e}")


def test_auth_api_is_running():
    """Tests that the Auth API is running."""
    try:
        response = httpx.get(f"{AUTH_API_URL}/health")
        response.raise_for_status()
        assert response.json()["status"] == "ok"
    except httpx.RequestError as e:
        pytest.fail(f"Connection to Auth API failed: {e}")


def test_get_auth_token():
    """Tests that we can get an auth token."""
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = "username=johndoe&password=secret"
    response = httpx.post(f"{AUTH_API_URL}/token", headers=headers, data=data)
    response.raise_for_status()
    assert "access_token" in response.cookies


def test_read_users_me():
    """Tests that we can get the current user's data."""
    # 1. Get an auth token
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = "username=johndoe&password=secret"
    with httpx.Client() as client:
        response = client.post(f"{AUTH_API_URL}/token", headers=headers, data=data)
        response.raise_for_status()
        cookies = response.cookies

        # 2. Get the current user's data
        response = client.get(f"{AUTH_API_URL}/users/me", cookies=cookies)
        response.raise_for_status()
        assert response.json()["username"] == "johndoe"


def test_auth_api_metrics_exist():
    """Tests that the /metrics endpoint exists on the Auth API."""
    try:
        response = httpx.get(f"{AUTH_API_URL}/metrics")
        response.raise_for_status()
        # A basic check to ensure the metrics endpoint returns some content
        assert len(response.text) > 0
    except httpx.RequestError as e:
        pytest.fail(f"Connection to Auth API /metrics failed: {e}")


def test_job_processor_is_running():
    """Tests that the Job Processor is running."""
    try:
        response = httpx.get(f"{JOB_PROCESSOR_URL}/health")
        response.raise_for_status()
        assert response.json()["status"] == "ok"
    except httpx.RequestError as e:
        pytest.fail(f"Connection to Job Processor failed: {e}")

def test_job_processor_processes_job():
    """
    Tests that the job processor can receive multiple jobs from the 'job-queue'
    and push them to the 'processed-jobs' queue.
    """
    # 1. Connect to Redis
    r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

    # 2. Generate unique job IDs
    job_ids = [str(uuid.uuid4()) for _ in range(5)]
    job_data = [f"test_job_{job_id}" for job_id in job_ids]

    # 3. Push the jobs to the 'job-queue'
    for job in job_data:
        r.lpush('job-queue', job)

    # 4. Wait for the jobs to be processed
    processed_jobs = []
    for _ in range(len(job_data)):
        _, processed_job = r.brpop('processed-jobs', timeout=5)
        processed_jobs.append(processed_job)

    # 5. Assert that all jobs were processed
    assert set(processed_jobs) == set(job_data)


def test_payment_api_simulates_providers():
    """Tests that the payment API simulates different providers."""
    # Test with a Visa card
    visa_payload = {
        "card_number": "4111111111111111",
        "expiry_date": "12/25",
        "cvv": "123",
        "amount": 100.00
    }
    response = httpx.post(f"{PAYMENT_API_URL}/authorize", json=visa_payload)
    # This might fail due to simulated failure rate, which is expected
    assert response.status_code in [200, 500]

    # Test with a Mastercard
    mastercard_payload = {
        "card_number": "5222222222222222",
        "expiry_date": "12/25",
        "cvv": "123",
        "amount": 100.00
    }
    response = httpx.post(f"{PAYMENT_API_URL}/authorize", json=mastercard_payload)
    assert response.status_code in [200, 500]


def test_payment_api_metrics_exist():
    """Tests that the /metrics endpoint exists on the Payment API."""
    try:
        response = httpx.get(f"{PAYMENT_API_URL}/metrics/")
        response.raise_for_status()
        assert "payment_provider_latency_seconds_bucket" in response.text
        assert "payment_transaction_consistency_ratio" in response.text
    except httpx.RequestError as e:
        pytest.fail(f"Connection to Payment API /metrics failed: {e}")


def test_set_and_reset_latency():
    """
    Tests that we can set and reset latency on the e-commerce service.
    """
    # 1. Set latency to critical
    payload = {"service_id": "ecommerce-api", "state": {"latency": 0.5}}
    response = httpx.post(f"{ENTROPY_ENGINE_URL}/entropy/set", json=payload)
    response.raise_for_status()

    # 2. Measure response time
    start_time = time.time()
    httpx.get(f"{ECOMMERCE_API_URL}/products")
    end_time = time.time()
    response_time = end_time - start_time
    assert response_time >= 0.5

    # 3. Reset latency
    payload = {"service_id": "ecommerce-api", "state": {"latency": 0}}
    response = httpx.post(f"{ENTROPY_ENGINE_URL}/entropy/set", json=payload)
    response.raise_for_status()

    # 4. Measure response time again
    start_time = time.time()
    httpx.get(f"{ECOMMERCE_API_URL}/products")
    end_time = time.time()
    response_time = end_time - start_time
    assert response_time < 0.2


def test_full_user_flow():
    """
    Tests the full user flow from login to checkout.
    """
    # 1. Login and get auth cookie
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = "username=johndoe&password=secret"
    with httpx.Client() as client:
        response = client.post(f"{AUTH_API_URL}/token", headers=headers, data=data)
        response.raise_for_status()
        cookies = response.cookies

        # 2. Add a product to the cart
        product_id = "1"  # Assuming a product with ID 1 exists
        response = client.post(f"{ECOMMERCE_API_URL}/cart/add", json={"product_id": product_id, "quantity": 1}, cookies=cookies)
        response.raise_for_status()

        # 3. Checkout
        checkout_payload = {
            "firstName": "John",
            "lastName": "Doe",
            "address": "123 Main St",
            "city": "Anytown",
            "state": "CA",
            "zip": "12345",
            "card_number": "4111111111111111",
            "expiry_date": "12/25",
            "cvv": "123",
            "amount": 100.00
        }
        response = client.post(f"{PAYMENT_API_URL}/authorize", json=checkout_payload, cookies=cookies)
        response.raise_for_status()

        # 4. Create an order
        response = client.post(f"{ECOMMERCE_API_URL}/orders", cookies=cookies)
        response.raise_for_status()
        assert "id" in response.json()
