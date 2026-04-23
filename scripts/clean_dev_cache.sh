#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Remove local dev cache directories created by scripts/test runs.
#
# Run from:
# - Repository root (recommended), or anywhere using:
#   bash scripts/clean_dev_cache.sh
#
# What it removes:
# - apps/api/.cursor-tmp
# - apps/frontend/.cursor-tmp

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGETS=(
  "$ROOT_DIR/apps/api/.cursor-tmp"
  "$ROOT_DIR/apps/frontend/.cursor-tmp"
)

for target in "${TARGETS[@]}"; do
  if [[ -d "$target" ]]; then
    rm -rf "$target"
    echo "Removed: $target"
  else
    echo "Not found (skipped): $target"
  fi
done

echo
echo "Dev cache cleanup complete."
