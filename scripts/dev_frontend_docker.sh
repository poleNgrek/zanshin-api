#!/usr/bin/env bash
set -euo pipefail

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
