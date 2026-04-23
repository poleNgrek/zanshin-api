# CORS Guide (Zanshin)

This document explains what CORS is, how this project is configured, and how to debug CORS issues quickly.

## What CORS is

Browsers block many cross-origin requests by default.

- Frontend origin example: `http://localhost:3000`
- API origin example: `http://localhost:4000`

Because these origins differ (different port), browser requests from frontend to API are cross-origin and require CORS headers from the API.

## How this project handles CORS

API CORS handling is implemented in:

- `api/lib/zanshin_api_web/plugs/cors.ex`
- plugged in `api/lib/zanshin_api_web/endpoint.ex`

Default allowed origins:

- `http://localhost:3000`
- `http://127.0.0.1:3000`

Override origins with environment variable:

- `CORS_ALLOWED_ORIGINS` (comma-separated)

Example:

```bash
export CORS_ALLOWED_ORIGINS="https://app.example.com,https://admin.example.com"
```

The plug also handles CORS preflight (`OPTIONS`) requests and returns no-content response with CORS headers.

## Local development checklist

1. Confirm frontend origin and API origin:
   - frontend: `http://localhost:3000`
   - API: `http://localhost:4000`
2. Check browser DevTools Console for CORS errors.
3. In Network tab, inspect failed request and ensure response includes:
   - `access-control-allow-origin`
   - `access-control-allow-methods`
   - `access-control-allow-headers`
4. If request is preflighted, inspect `OPTIONS` call and confirm success (`204`).
5. If using custom frontend host/port, set `CORS_ALLOWED_ORIGINS`.

Quick helper script from repo root:

```bash
bash scripts/check_cors.sh "http://localhost:4000/api/v1/health" "http://localhost:3000" "GET"
```

Optional arguments:

- arg1: API URL (default `http://localhost:4000/api/v1/health`)
- arg2: Origin header value (default `http://localhost:3000`)
- arg3: Requested method for preflight (default `GET`)

## CI notes

The real API Playwright lane runs frontend and API on different origins in CI.
CORS headers must be present for browser-based API calls to succeed.

## Common confusion

- `curl` or server-to-server requests can work while browser requests fail.
- This is expected: CORS is enforced by browsers, not by backend HTTP clients.

## Security guidance

- Keep allowed origins explicit.
- Do not use wildcard `*` for sensitive APIs.
- CORS is not authentication; continue enforcing token/role checks in API endpoints.
