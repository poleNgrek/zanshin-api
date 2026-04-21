#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/docker-compose.yml" --profile dev)

echo "Starting PostgreSQL + API containers..."
"${COMPOSE[@]}" up -d postgres api

echo "Preparing API dependencies and database inside container..."
"${COMPOSE[@]}" exec -T api sh -lc "mix local.hex --force && mix local.rebar --force && mix deps.get && mix ecto.setup"

echo "Starting Phoenix API in container on http://localhost:4000 ..."
exec "${COMPOSE[@]}" exec -T api sh -lc "PORT=4000 PHX_DOCKER=1 mix phx.server"
