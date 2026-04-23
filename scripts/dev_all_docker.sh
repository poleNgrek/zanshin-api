#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Start full Docker dev mode (API + frontend) in two Terminal tabs.
#
# Run from:
# - Repository root (recommended), or anywhere using:
#   bash scripts/dev_all_docker.sh
#
# Notes:
# - macOS only automation (uses osascript + Terminal app).
# - If osascript is unavailable, run the two scripts manually.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_API="$ROOT_DIR/scripts/dev_api_docker.sh"
SCRIPT_FRONTEND="$ROOT_DIR/scripts/dev_frontend_docker.sh"

if ! command -v osascript >/dev/null 2>&1; then
  echo "osascript not available. Run manually in two terminals:"
  echo "  bash scripts/dev_api_docker.sh"
  echo "  bash scripts/dev_frontend_docker.sh"
  exit 1
fi

echo "Opening two Terminal tabs and starting full Docker dev..."

osascript <<EOF
tell application "Terminal"
  activate
  do script "cd \"$ROOT_DIR\" && bash \"$SCRIPT_API\""
  do script "cd \"$ROOT_DIR\" && bash \"$SCRIPT_FRONTEND\""
end tell
EOF

echo "API:      http://localhost:4000"
echo "Frontend: http://localhost:3000"
