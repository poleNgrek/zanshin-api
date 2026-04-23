#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Run API locally on host with PostgreSQL in Docker.
#
# Run from:
# - Repository root (recommended), or anywhere using:
#   bash scripts/dev_api_local.sh
#
# What it does:
# - Starts postgres container
# - Installs API deps and prepares DB
# - Starts Phoenix server at http://localhost:4000

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_DIR="$ROOT_DIR/api"

if ! command -v mix >/dev/null 2>&1; then
  echo "mix command not found."
  echo "Install Elixir first (macOS):"
  echo "  brew install erlang elixir"
  exit 1
fi

echo "Starting PostgreSQL container..."
docker compose -f "$ROOT_DIR/docker-compose.yml" up -d postgres

echo "Preparing API dependencies and DB..."
(
  cd "$API_DIR"
  mix local.hex --force
  mix local.rebar --force
  mix deps.get
  mix ecto.setup
)

echo "Starting Phoenix API on http://localhost:4000 ..."
cd "$API_DIR"
exec mix phx.server
