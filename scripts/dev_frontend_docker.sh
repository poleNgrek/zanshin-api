#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Run frontend inside Docker.
#
# Run from:
# - Repository root (recommended), or anywhere using:
#   bash scripts/dev_frontend_docker.sh
#
# Optional env:
# - API_BASE_URL (default: http://localhost:4000)
#
# What it does:
# - Starts frontend container
# - Installs frontend deps in container
# - Starts frontend dev server at http://localhost:3000

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/docker-compose.yml" --profile dev)
API_BASE_URL="${API_BASE_URL:-http://localhost:4000}"

echo "Starting frontend container..."
"${COMPOSE[@]}" up -d frontend

echo "Installing frontend dependencies inside container..."
"${COMPOSE[@]}" exec frontend sh -lc "bun install"

echo "Starting frontend in container on http://localhost:3000 ..."
echo "Using API_BASE_URL=$API_BASE_URL"
exec "${COMPOSE[@]}" exec frontend sh -lc "API_BASE_URL=$API_BASE_URL bunx remix dev --host 0.0.0.0 --port 3000"
