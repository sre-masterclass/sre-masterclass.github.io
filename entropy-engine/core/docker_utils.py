import docker
from docker.errors import NotFound

client = docker.from_env()

def get_container(service_id):
    """Gets a container by its name."""
    try:
        return client.containers.get(service_id)
    except NotFound:
        return None

def set_environment_variable(container, key, value):
    """Sets an environment variable in a running container."""
    # This is a simplified example. In a real-world scenario, you might
    # need to recreate the container with the new environment variable.
    # For this example, we'll just log the action.
    print(f"Setting env var {key}={value} for container {container.name}")

def update_resource_limits(container, mem_limit=None, cpu_shares=None):
    """Updates the resource limits of a running container."""
    container.update(mem_limit=mem_limit, cpu_shares=cpu_shares)

def disconnect_network(container):
    """Disconnects a container from the network."""
    # This is a simplified example. In a real-world scenario, you would
    # need to handle multiple networks and more complex scenarios.
    print(f"Disconnecting container {container.name} from network")
    client.networks.get("sre-masterclass_default").disconnect(container)

def connect_network(container):
    """Connects a container to the network."""
    print(f"Connecting container {container.name} to network")
    client.networks.get("sre-masterclass_default").connect(container)

def stop_container(container):
    """Stops a container."""
    print(f"Stopping container {container.name}")
    container.stop()

def start_container(container):
    """Starts a container."""
    print(f"Starting container {container.name}")
    container.start()
