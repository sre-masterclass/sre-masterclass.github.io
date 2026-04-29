#!/bin/bash
# This script resets the environment to a clean state.

echo "Stopping and removing all containers, networks, and volumes..."

docker compose down -v --remove-orphans

echo "Environment has been reset."
exit 0
