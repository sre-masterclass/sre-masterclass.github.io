import yaml
from typing import List, Dict, Any
from pydantic import BaseModel

class ServiceConfig(BaseModel):
    id: str
    name: str
    url: str
    entropy_endpoints: Dict[str, str]

def load_service_config(path: str = "services.yml") -> List[ServiceConfig]:
    """Loads the service configuration from a YAML file."""
    with open(path, "r") as f:
        config_data = yaml.safe_load(f)
    
    services = config_data.get("services", [])
    return [ServiceConfig(**service) for service in services]
