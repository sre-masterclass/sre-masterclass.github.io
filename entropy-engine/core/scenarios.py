import asyncio
import httpx
import yaml
import os
from typing import List, Dict, Any
from pydantic import BaseModel
import structlog

from .state import StateStore
from .config import ServiceConfig

logger = structlog.get_logger()

running_scenarios = []

class ScenarioStep(BaseModel):
    type: str
    service_id: str
    state: Dict[str, Any]
    duration: int = 0

class Scenario(BaseModel):
    name: str
    description: str
    steps: List[ScenarioStep]

def load_scenarios(path: str = "scenarios") -> List[Scenario]:
    """Loads all scenarios from a directory."""
    scenarios = []
    for filename in os.listdir(path):
        if filename.endswith(".yml"):
            with open(os.path.join(path, filename), "r") as f:
                scenario_data = yaml.safe_load(f)
                scenarios.append(Scenario(**scenario_data))
    return scenarios

async def run_scenario_step(step: ScenarioStep, store: StateStore, config: List[ServiceConfig]):
    """Executes a single step of a scenario by calling the service directly."""
    logger.info("Executing scenario step", step=step)

    if step.type == "docker":
        container = get_container(step.service_id)
        if not container:
            logger.error("Container not found", service_id=step.service_id)
            return

        if step.action == "set_env":
            for key, value in step.params.items():
                set_environment_variable(container, key, value)
        elif step.action == "set_resources":
            update_resource_limits(container, **step.params)
        elif step.action == "disconnect_network":
            disconnect_network(container)
        elif step.action == "connect_network":
            connect_network(container)
        elif step.action == "stop":
            stop_container(container)
        elif step.action == "start":
            start_container(container)
        else:
            logger.error("Invalid docker action", action=step.action)
    else:
        service = next((s for s in config if s.id == step.service_id), None)
        if not service:
            logger.error("Service not found in config", service_id=step.service_id)
            return

        store.set_state(step.service_id, step.state)

        entropy_type, value = next(iter(step.state.items()))
        endpoint = service.entropy_endpoints.get(entropy_type)
        if not endpoint:
            logger.error("Invalid entropy type in scenario step", entropy_type=entropy_type)
            return

        target_url = f"{service.url}{endpoint}"
        try:
            async with httpx.AsyncClient() as client:
                payload_key = "latency" if entropy_type == "latency" else "error_rate"
                response = await client.post(target_url, json={payload_key: value})
                response.raise_for_status()
        except httpx.RequestError as e:
            logger.error("Failed to execute scenario step", step=step, error=str(e))

async def run_scenario_in_background(scenario: Scenario, store: StateStore, config: List[ServiceConfig]):
    """Runs a full scenario in a background task."""
    logger.info("Starting scenario", scenario_name=scenario.name)
    running_scenarios.append(scenario.name)
    for step in scenario.steps:
        await run_scenario_step(step, store, config)
        if step.duration > 0:
            logger.info("Waiting for step duration", duration=step.duration)
            await asyncio.sleep(step.duration)
    logger.info("Scenario finished", scenario_name=scenario.name)
    running_scenarios.remove(scenario.name)
