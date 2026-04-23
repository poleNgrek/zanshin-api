#!/usr/bin/env bash
set -euo pipefail

# This script is intentionally simple so a beginner can follow each step.
# It scaffolds Phoenix in api if you prefer generator output over the
# hand-written starter files currently committed.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_DIR="${ROOT_DIR}/api"

if [[ ! -d "${API_DIR}" ]]; then
  echo "api directory does not exist."
  exit 1
fi

cd "${API_DIR}"

echo "Installing Hex/Rebar and Phoenix generator..."
mix local.hex --force
mix local.rebar --force
mix archive.install hex phx_new --force

echo "Scaffolding Phoenix project in ${API_DIR} ..."
mix phx.new . --app zanshin_api --module ZanshinApi --no-html --no-assets --database postgres

echo "Done. Next:"
echo "  cd api"
echo "  mix setup"
echo "  mix phx.server"
