#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Run frontend locally with Bun on host.
#
# Run from:
# - Repository root (recommended), or anywhere using:
#   bash scripts/dev_frontend.sh
#
# Optional env:
# - API_BASE_URL (default: http://localhost:4000)
#
# What it does:
# - Installs frontend deps
# - Starts Remix dev server at http://localhost:8080

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/front-end"
API_BASE_URL="${API_BASE_URL:-http://localhost:4000}"

if ! command -v bun >/dev/null 2>&1; then
  echo "bun command not found."
  echo
  echo "Install Bun, then rerun this script:"
  echo "  curl -fsSL https://bun.sh/install | bash"
  echo "  # restart terminal afterwards"
  echo
  echo "Alternative on macOS (Homebrew):"
  echo "  brew tap oven-sh/bun"
  echo "  brew install bun"
  exit 1
fi

echo "Installing frontend dependencies..."
cd "$FRONTEND_DIR"
bun install

echo "Starting frontend on http://localhost:8080 ..."
echo "Using API_BASE_URL=$API_BASE_URL"
exec env API_BASE_URL="$API_BASE_URL" bun run dev
