import os
import asyncio
import structlog
import httpx
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Dict, Any, List

from core.state import InMemoryStateStore, StateStore
from core.config import load_service_config, ServiceConfig
from core.scenarios import load_scenarios, run_scenario_in_background, Scenario, running_scenarios
from core.docker_utils import get_container, set_environment_variable, update_resource_limits, disconnect_network, connect_network, stop_container, start_container

# Configure structured logging
structlog.configure(
    processors=[
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.PrintLoggerFactory(),
)
logger = structlog.get_logger()

app = FastAPI()

# Load service and scenario configurations on startup
service_config = load_service_config()
scenarios = load_scenarios()

# Dependency Injection for StateStore
state_store = InMemoryStateStore()

def get_state_store():
    return state_store

def get_service_config():
    return service_config

def get_scenarios():
    return scenarios

class ScenarioPayload(BaseModel):
    name: str

class EntropyPayload(BaseModel):
    service_id: str
    state: Dict[str, Any]

class DockerPayload(BaseModel):
    service_id: str
    action: str
    params: Dict[str, Any]

@app.on_event("startup")
async def startup_event():
    logger.info("Entropy Engine starting up...")
    # Initialize state for all services
    for service in service_config:
        state_store.set_state(service.id, {"latency": 0, "error_rate": 0})

@app.get("/api/status")
async def get_status():
    """Provides the current status of the Entropy Engine."""
    logger.info("Status endpoint called")
    return {"status": "running"}

@app.post("/api/entropy/set")
async def set_entropy(payload: EntropyPayload, store: StateStore = Depends(get_state_store), config: List[ServiceConfig] = Depends(get_service_config)):
    """Sets the entropy state for a given service."""
    logger.info("Setting entropy state", service_id=payload.service_id, state=payload.state)
    
    # Find the service configuration
    service = next((s for s in config if s.id == payload.service_id), None)
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    # Normalize the state keys: "errors" -> "error_rate" to match frontend expectations
    normalized_state = {}
    for key, value in payload.state.items():
        if key == "errors":
            normalized_state["error_rate"] = value
        else:
            normalized_state[key] = value
    
    # Update the state with normalized keys
    current_state = store.get_state(payload.service_id) or {"latency": 0, "error_rate": 0}
    current_state.update(normalized_state)
    store.set_state(payload.service_id, current_state)

    # Call the target service's entropy endpoint
    entropy_type, value = next(iter(payload.state.items()))
    endpoint = service.entropy_endpoints.get(entropy_type)
    if not endpoint:
        raise HTTPException(status_code=400, detail=f"Invalid entropy type: {entropy_type}")

    target_url = f"{service.url}{endpoint}"
    try:
        async with httpx.AsyncClient() as client:
            # The payload key should match the Pydantic model in the target service
            payload_key = "latency" if entropy_type == "latency" else "error_rate"
            response = await client.post(target_url, json={payload_key: value})
            response.raise_for_status()
    except httpx.RequestError as e:
        logger.error("Failed to call entropy endpoint", url=target_url, error=str(e))
        raise HTTPException(status_code=500, detail="Failed to call target service")

    return JSONResponse(content={"message": f"Entropy state for {payload.service_id} set"}, status_code=200)

@app.get("/api/entropy/status/{service_id}")
async def get_entropy_status(service_id: str, store: StateStore = Depends(get_state_store)):
    """Retrieves the current entropy state from the state store for a specific service."""
    logger.info("Getting entropy status", service_id=service_id)
    state = store.get_state(service_id)
    if not state:
        raise HTTPException(status_code=404, detail="State for service not found")
    return state

@app.post("/api/entropy/reset")
async def reset_entropy(store: StateStore = Depends(get_state_store), config: List[ServiceConfig] = Depends(get_service_config)):
    """Resets the entropy state for all services."""
    logger.info("Resetting entropy state for all services")
    running_scenarios.clear()
    
    # First, reset the state store to prevent further entropy generation
    for service in config:
        store.set_state(service.id, {"latency": 0, "error_rate": 0})
    
    # Then, reset each service with retries to handle existing entropy effects
    for service in config:
        for entropy_type, endpoint in service.entropy_endpoints.items():
            target_url = f"{service.url}{endpoint}"
            payload_key = "latency" if entropy_type == "latency" else "error_rate"
            
            # Retry up to 5 times to handle services that may be returning 500s due to entropy
            max_retries = 5
            for attempt in range(max_retries):
                try:
                    async with httpx.AsyncClient(timeout=5.0) as client:
                        response = await client.post(target_url, json={payload_key: 0})
                        response.raise_for_status()
                        logger.info("Successfully reset entropy", service=service.id, type=entropy_type, attempt=attempt+1)
                        break  # Success, exit retry loop
                except (httpx.RequestError, httpx.HTTPStatusError) as e:
                    if attempt < max_retries - 1:
                        logger.warning("Retry entropy reset", service=service.id, type=entropy_type, attempt=attempt+1, error=str(e))
                        await asyncio.sleep(0.1)  # Brief delay before retry
                    else:
                        logger.error("Failed to reset entropy after retries", service=service.id, type=entropy_type, error=str(e))
                        # Continue with other services even if this one fails
    
    return JSONResponse(content={"message": "Entropy state for all services reset"}, status_code=200)

@app.get("/api/services", response_model=List[ServiceConfig])
async def list_services(config: List[ServiceConfig] = Depends(get_service_config)):
    """Returns a list of configurable services."""
    logger.info("List services endpoint called")
    return config

@app.get("/api/scenarios", response_model=List[Scenario])
async def list_scenarios(scenarios: List[Scenario] = Depends(get_scenarios)):
    """Returns a list of available scenarios."""
    logger.info("List scenarios endpoint called")
    return scenarios

@app.get("/api/scenarios/status")
async def get_scenario_status():
    """Returns a list of running scenarios."""
    logger.info("Get scenario status endpoint called")
    return running_scenarios

@app.post("/api/scenarios/run")
async def run_scenario(
    payload: ScenarioPayload,
    background_tasks: BackgroundTasks,
    scenarios: List[Scenario] = Depends(get_scenarios),
    store: StateStore = Depends(get_state_store),
    config: List[ServiceConfig] = Depends(get_service_config),
):
    """Runs a pre-defined chaos scenario."""
    logger.info("Run scenario endpoint called", scenario_name=payload.name)

    scenario = next((s for s in scenarios if s.name == payload.name), None)
    if not scenario:
        raise HTTPException(status_code=404, detail="Scenario not found")

    background_tasks.add_task(
        run_scenario_in_background,
        scenario=scenario,
        store=store,
        config=config,
    )
    return JSONResponse(
        content={"message": f"Scenario '{payload.name}' started in the background"},
        status_code=202,
    )

@app.post("/api/docker/control")
async def docker_control(payload: DockerPayload):
    """Controls Docker containers."""
    logger.info("Docker control endpoint called", payload=payload)
    container = get_container(payload.service_id)
    if not container:
        raise HTTPException(status_code=404, detail="Container not found")

    if payload.action == "set_env":
        for key, value in payload.params.items():
            set_environment_variable(container, key, value)
    elif payload.action == "set_resources":
        update_resource_limits(container, **payload.params)
    elif payload.action == "disconnect_network":
        disconnect_network(container)
    elif payload.action == "connect_network":
        connect_network(container)
    elif payload.action == "stop":
        stop_container(container)
    elif payload.action == "start":
        start_container(container)
    else:
        raise HTTPException(status_code=400, detail="Invalid action")

    return {"message": f"Action '{payload.action}' performed on container '{payload.service_id}'"}

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/")
def read_root():
    return {"Hello": "Entropy Engine"}
