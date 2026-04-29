from abc import ABC, abstractmethod
from typing import Dict, Any

class StateStore(ABC):
    """Abstract base class for a key-value state store."""

    @abstractmethod
    def get_state(self, service_id: str) -> Dict[str, Any]:
        """
        Retrieves the state for a given service.

        Args:
            service_id: The identifier of the service.

        Returns:
            A dictionary representing the service's state.
        """
        pass

    @abstractmethod
    def set_state(self, service_id: str, state: Dict[str, Any]) -> None:
        """
        Sets the state for a given service.

        Args:
            service_id: The identifier of the service.
            state: A dictionary representing the service's new state.
        """
        pass

class InMemoryStateStore(StateStore):
    """An in-memory implementation of the StateStore."""

    def __init__(self):
        self._state: Dict[str, Dict[str, Any]] = {}

    def get_state(self, service_id: str) -> Dict[str, Any]:
        """Retrieves the state for a given service."""
        return self._state.get(service_id, {})

    def set_state(self, service_id: str, state: Dict[str, Any]) -> None:
        """Sets the state for a given service."""
        self._state[service_id] = state
