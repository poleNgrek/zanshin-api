#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Run API formatting and test verification in one command.
#
# Run from:
# - Repository root (recommended), or anywhere using:
#   bash scripts/verify_api.sh
#
# Optional env:
# - USE_LOCAL_MIX_CACHE=1 (default) keeps Mix/Hex cache inside apps/api/.cursor-tmp
#
# What it does:
# - Ensures Hex exists non-interactively
# - Runs `mix format`
# - Runs `MIX_ENV=test mix test`

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_DIR="$ROOT_DIR/apps/api"
USE_LOCAL_MIX_CACHE="${USE_LOCAL_MIX_CACHE:-1}"

if [[ "$USE_LOCAL_MIX_CACHE" == "1" ]]; then
  mkdir -p "$API_DIR/.cursor-tmp/hex" "$API_DIR/.cursor-tmp/mix"
  export HEX_HOME="$API_DIR/.cursor-tmp/hex"
  export MIX_HOME="$API_DIR/.cursor-tmp/mix"
fi

cd "$API_DIR"
mix local.hex --force
mix format
MIX_ENV=test mix test

echo
echo "API verification passed."
