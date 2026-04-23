#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Quick CORS validation for API endpoint + origin combination.
#
# Run from:
# - Repository root (recommended), or anywhere using:
#   bash scripts/check_cors.sh [API_URL] [ORIGIN] [REQUEST_METHOD]
#
# Example:
# - bash scripts/check_cors.sh http://localhost:4000/api/v1/health http://localhost:3000 GET
# - Returns PASS/FAIL based on allow-origin behavior.

API_URL="${1:-http://localhost:4000/api/v1/health}"
ORIGIN="${2:-http://localhost:3000}"
REQUEST_METHOD="${3:-GET}"

echo "CORS quickcheck"
echo "  URL:    $API_URL"
echo "  Origin: $ORIGIN"
echo "  Method: $REQUEST_METHOD"
echo

echo "== Preflight (OPTIONS) =="
preflight_headers="$(curl -sS -D - -o /dev/null -X OPTIONS "$API_URL" \
  -H "Origin: $ORIGIN" \
  -H "Access-Control-Request-Method: $REQUEST_METHOD" \
  -H "Access-Control-Request-Headers: authorization,content-type" || true)"
printf "%s\n" "$preflight_headers" | awk 'BEGIN{IGNORECASE=1}/^HTTP\/|^access-control-|^vary:/{print}'
echo

echo "== Actual request =="
actual_headers="$(curl -sS -D - -o /dev/null "$API_URL" -H "Origin: $ORIGIN" || true)"
printf "%s\n" "$actual_headers" | awk 'BEGIN{IGNORECASE=1}/^HTTP\/|^access-control-|^vary:/{print}'
echo

allow_origin="$(printf "%s\n" "$actual_headers" | awk 'BEGIN{IGNORECASE=1}/^access-control-allow-origin:/{print $0}')"
if [[ -z "$allow_origin" ]]; then
  echo "Result: FAIL - access-control-allow-origin header missing on actual response."
  exit 1
fi

if ! printf "%s\n" "$allow_origin" | grep -Fq "$ORIGIN"; then
  echo "Result: WARN - allow-origin does not match requested origin."
  echo "  Header: $allow_origin"
  exit 1
fi

echo "Result: PASS - CORS allow-origin present and matches requested origin."
