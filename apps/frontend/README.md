# Frontend (Phase 3)

This folder contains the Remix SPA admin app for Zanshin.

## Stack

- Remix + React 19 + TypeScript
- Bun (package manager, runtime, and test runner)
- MUI for UI components
- Zod for API response validation
- Playwright for E2E tests

## Prerequisites

- Bun installed locally
- API service running at `http://localhost:4000`
- PostgreSQL running (API dependency)

## Run Options

### Option A: Hybrid (backend Docker + frontend local)

1) Start backend in Docker from repository root:

```bash
bash scripts/dev_api_docker.sh
```

2) In a second terminal, run frontend locally:

```bash
bash scripts/dev_frontend.sh
```

### Option B: Full local app processes (DB in Docker)

1) Start infrastructure and API from repository root:

```bash
docker compose up -d postgres
cd apps/api
mix setup
mix phx.server
```

2) In a second terminal, run frontend:

```bash
cd apps/frontend
bun install
API_BASE_URL=http://localhost:4000 bun run dev
```

### Option C: Full Docker (backend + frontend)

Run in two terminals from repository root:

```bash
bash scripts/dev_api_docker.sh
bash scripts/dev_frontend_docker.sh
```

Open:

- Frontend: `http://localhost:3000`
- API docs: `http://localhost:4000/api/docs`

## Auth Token in UI

Write endpoints require authentication.

- Generate or obtain a valid Bearer token for your API environment.
- In the app header, paste token into `Bearer token` field and click `Save Token`.
- Token is stored in `localStorage` and automatically attached to API write requests.

## Commands

```bash
# Development server
bun run dev

# Production-like server (used by Playwright webServer)
bun run build
bun run start

# Type checks
bun run typecheck

# Lint
bun run lint

# Unit tests
bun test

# One-time browser install for Playwright
bunx playwright install chromium

# E2E tests
bun run test:e2e
```
