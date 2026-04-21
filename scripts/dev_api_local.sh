#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_DIR="$ROOT_DIR/apps/api"

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
