# Entropy Engine Architecture

This document outlines the design patterns and architecture for the Entropy Engine.

## Resilient Reset Mechanism

The entropy engine now features a resilient reset mechanism to handle cases where services are in a degraded state (e.g., returning 500 errors). This is achieved through a two-phase reset process with retry logic.

1.  **State Store Reset**: The `entropy-engine` first resets the state of all services in its internal state store. This immediately prevents the engine from propagating further entropy.
2.  **Service Reset with Retries**: The engine then attempts to reset each individual service. If a service fails to respond (e.g., due to its own entropy-induced failures), the engine will retry the request up to 5 times with a short delay between attempts. This ensures that even services in a degraded state can be successfully reset.

This two-phase approach with retries makes the reset operation more robust and prevents the `entropy-engine` from getting stuck in a state where it cannot recover services.

```mermaid
graph TD
    subgraph "Client (Vue.js Dashboard)"
        A[Dashboard UI]
    end

    subgraph "Entropy Engine (Facade API)"
        B[FastAPI App]
        C[Scenario Runner]
        D[State Controller]
        R[Resilient Resetter]
    end

    subgraph "Core Logic"
        E[StateStore ABC]
        F[YAML Loader]
    end

    subgraph "Concrete Implementations (Strategies)"
        G[InMemoryStateStore]
        H[RedisStateStore(...in future)]
        I[services.yml]
        J[scenarios/*.yml]
    end

    subgraph "External Services"
        K[E-commerce API]
        L[Auth API]
        M[Payment API]
        N[Job Processor]
    end

    A -- "POST /api/scenarios/run" --> B
    B --> C
    C --> F -- "Loads" --> J
    C --> D

    A -- "POST /api/entropy/set" --> B
    B --> D

    A -- "POST /api/entropy/reset" --> B
    B --> R

    R -- "Uses (Injected)" --> E
    R -- "Calls with Retries" --> K
    R -- "Calls with Retries" --> L
    R -- "Calls with Retries" --> M
    R -- "Calls with Retries" --> N


    D -- "Uses (Injected)" --> E
    E -- "Implemented by" --> G
    E -- "Implemented by" --> H

    D -- "Calls" --> K
    D -- "Calls" --> L
    D -- "Calls" --> M
    D -- "Calls" --> N


    F -- "Loads" --> I
