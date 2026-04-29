#!/bin/bash
# This script checks if the necessary tools are installed to run the SRE Masterclass environment.

echo "Checking for required tools..."

# Check for Docker
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

# Check for Docker Compose
if ! [ -x "$(command -v docker-compose)" ] && ! docker compose version >/dev/null 2>&1; then
  echo "Error: Neither 'docker-compose' (v1) nor 'docker compose' (v2) was found." >&2
  echo "Please install Docker Compose." >&2
  exit 1
fi

echo "All required tools are installed."
exit 0
