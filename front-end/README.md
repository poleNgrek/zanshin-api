# Frontend (Phase 3)

This folder contains the Remix SPA admin app for Zanshin.

## Stack

- Remix + React 19 + TypeScript
- Bun (package manager, runtime, and test runner)
- MUI for UI components
- Zod for API response validation
- Madge for circular dependency checks
- Playwright for E2E tests
- Storybook for dev-only component previews

## Package Strategy

- This project keeps a single application package in `front-end/package.json`.
- We evaluated splitting into root/app dual package manifests, but did not adopt that structure now to avoid extra script indirection during the current migration.
- `eslint-plugin-zanshin` remains a dedicated local tooling package under `front-end/eslint-plugin-zanshin`.

## Source Layout

- `app/src/routes` - Remix route modules (nested folders, no dot-delimited filenames)
- `app/src/api` - API client package
- `app/src/components` - UI component package
- `app/src/providers` - provider/state adapter package
- `app/src/schemas` - validation schema package
- `app/src/types` - shared frontend types package
- `app/src/utils` - runtime utilities package
- `app/src/__fixtures__` - frontend fixtures for stories/tests
- `app/src/storybook` - Storybook story modules
- `app/client.tsx` and `app/server.tsx` - Remix entry modules

Import alias examples:

- `import { fetchWithSchema } from "@zanshin/api"`
- `import type { Tournament } from "@zanshin/types"`

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
cd api
mix setup
mix phx.server
```

2) In a second terminal, run frontend:

```bash
cd front-end
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

- Frontend: `http://localhost:8080`
- API docs: `http://localhost:4000/api/docs`

## Consumer vs Admin Views

- Consumer routes:
  - `/` dashboard
  - `/matches` read-only match list
- Admin routes:
  - `/admin` console
  - `/admin/tournaments`
  - `/admin/competitors`
  - `/admin/gradings/results`
- Write operations require a bearer token saved via the header token input.

## Auth Token in UI

Write endpoints require authentication.

- Generate or obtain a valid Bearer token for your API environment.
- In the app header, paste token into the admin auth field and click `Save`.
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

# Unit tests + circular dependency checks
bun run test

# One-time browser install for Playwright
bunx playwright install chromium

# E2E tests
bun run test:e2e

# Dependency cycle check only
bun run depcheck:circular

# Check import ordering/grouping without writing changes (exit code 2 on differences)
bun run check-imports

# Organize imports in place
bun run organize-imports

# Storybook (dev-only)
bun run storybook

# Real API integration lane (expects API running on localhost:4000)
bun run test:e2e:api
```

## E2E Mock Fixtures

- Shared Playwright mock data lives in `tests/e2e/fixtures.ts`.
- Keep route mocks in specs deterministic by reusing IDs/payloads from that file.
