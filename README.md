# Zanshin API - Kendo Tournament Platform

API-first platform for managing kendo tournaments with a web app, analytics layer, and future WordPress plugin integration.

## Why this project

- Run real-world kendo tournaments with strict match lifecycle control.
- Build a reliable event-driven foundation for live operations and analytics.
- Learn Elixir and Phoenix through a practical production-style system.

## Product Scope

- **API backend:** Elixir + Phoenix
- **Frontend app:** React + TypeScript
- **Analytics:** Event pipeline + Neo4j projections
- **Plugin integration:** WordPress plugin as API consumer
- **Storage:** PostgreSQL (transactional) + Neo4j (analytical graph)

See detailed requirements in `docs/PRD.md`.
For browser cross-origin integration notes, see `docs/CORS.md`.

## Repository Structure

- `docs/` - product and system documentation
- `apps/api/` - Phoenix API service (phase 2 scaffold target)
- `apps/frontend/` - React app (phase 3 scaffold target)
- `apps/analytics/` - analytics workers/projections (phase 4)
- `apps/wordpress-plugin/` - WordPress plugin package (phase 5)
- `infra/docker/` - containerization assets
- `scripts/` - local helper scripts

## Quick Start (Bootstrap Environment)

Prerequisites:

- Docker Desktop (or Docker Engine + Compose plugin)

Start infrastructure services:

```bash
docker compose up -d postgres neo4j
```

Check status:

```bash
docker compose ps
```

Stop services:

```bash
docker compose down
```

## Local Dev Scripts

Use helper scripts from repo root:

```bash
bash scripts/dev_api_local.sh
bash scripts/dev_frontend.sh
```

- `dev_api_local.sh` runs backend locally (Elixir on host) and Postgres in Docker.
- `dev_frontend.sh` runs frontend locally (Bun on host).
- `dev_api_docker.sh` runs backend inside Docker on `http://localhost:4000`.
- `dev_frontend_docker.sh` runs frontend inside Docker on `http://localhost:3000`.
- `dev_all_docker.sh` opens two Terminal tabs and starts full Docker mode.
- `check_cors.sh` verifies API CORS headers for a given URL/origin pair.
- If Bun is missing on host, `dev_frontend.sh` prints Bun install instructions.

### Common Run Variations

```bash
# Variation A: both local app processes (DB in Docker)
bash scripts/dev_api_local.sh
bash scripts/dev_frontend.sh

# Variation B: backend in Docker, frontend local (recommended hybrid)
bash scripts/dev_api_docker.sh
bash scripts/dev_frontend.sh

# Variation C: both backend + frontend in Docker
bash scripts/dev_api_docker.sh
bash scripts/dev_frontend_docker.sh

# Optional: populate API with a full-domain sample dataset
cd apps/api && mix run priv/repo/seeds.exs
```

## Environment Defaults

- PostgreSQL
  - host: `localhost`
  - port: `5432`
  - db: `zanshin_dev`
  - user: `zanshin`
  - password: `zanshin`
- Neo4j
  - browser: `http://localhost:7474`
  - bolt: `localhost:7687`
  - user: `neo4j`
  - password: `zanshin_neo4j`

## Delivery Phases

1. **Phase 0** - PRD consolidation
2. **Phase 1** - repository bootstrap + Docker baseline
3. **Phase 2** - Phoenix API foundation
4. **Phase 3** - React frontend foundation
5. **Phase 4** - Analytics foundation (Neo4j projections)
6. **Phase 5** - WordPress plugin integration
7. **Phase 6** - Hardening, CI/CD, release readiness

## Testing Strategy by Phase

- **Phase 2 (API/Phoenix):**
  - Unit and integration tests with `mix test`
  - State machine transition tests for match lifecycle
  - Auth/authorization tests by role (admin/shinpan/spectator)
- **Phase 3 (Frontend/React):**
  - Unit/component tests with Vitest + Testing Library
  - End-to-end tests with Playwright for critical admin workflows
- **Phase 4 (Analytics):**
  - Projection and query correctness tests
  - Replay/resilience tests for event pipeline behavior
- **Phase 5 (WordPress plugin):**
  - Plugin unit tests and API integration tests
  - Manual compatibility checks for install/upgrade
- **Phase 6 (Hardening):**
  - Full regression suite across API, frontend, analytics, and plugin
  - Performance and security checks

## How We Will Explain Implementation

This project is intentionally learning-oriented for Elixir/Phoenix. Each phase will include:

- A short architecture note describing what was built and why
- Comments around non-obvious domain logic (for example, state transitions and event projection rules)
- Test notes showing what behaviors are covered and how to run/extend those tests

See `docs/IMPLEMENTATION_GUIDE.md` for the detailed approach.

## How to Review the App

1. Read `docs/PRD.md` to understand product requirements and phase scope.
2. Review `docs/IMPLEMENTATION_GUIDE.md` for architecture and code conventions.
3. Start local dependencies:
   - `docker compose up -d postgres neo4j`
4. In later phases, run API/frontend apps and verify primary flow:
   - Open consumer match list view (`/matches`)
   - Open admin console (`/admin`) and admin workflows
   - Create tournament
   - Start/pause/resume/complete match
   - Record score and verify role constraints
5. Run automated tests before approving changes.

## How to Run Tests

Current status: Phase 2 API foundation has started in `apps/api`.

Planned commands:

- API tests (Phase 2+):
  - `cd apps/api && mix test`
- Frontend unit tests (Phase 3+):
  - `cd apps/frontend && bun test`
- Frontend E2E tests with Playwright (Phase 3+):
  - first run once: `cd apps/frontend && bunx playwright install chromium`
  - `cd apps/frontend && bun run test:e2e`
- Analytics tests (Phase 4+):
  - `cd apps/analytics && <test-command-to-be-defined>`
- WordPress plugin tests (Phase 5+):
  - `cd apps/wordpress-plugin && <test-command-to-be-defined>`

## CI/CD Status

- CI is now enabled via GitHub Actions in `.github/workflows/ci.yml`.
- Current CI scope:
  - Phoenix API format check (`mix format --check-formatted`)
  - Phoenix API test suite (`mix test`) with PostgreSQL service
  - Frontend lint + unit tests (`bun run lint`, `bun run test`)
  - Frontend real-API Playwright lane (`tests/e2e/real-api.spec.ts`) with API boot + seeded data
- CD is intentionally deferred until later hardening/release phases, once deployment targets and secrets strategy are finalized.

## Phase 2 Status

- Phoenix-oriented API skeleton added in `apps/api`.
- JWT auth baseline added for protected mutating API endpoints.
- OAuth/JWKS token validation added for protected mutating API endpoints.
- Competition entities added (`Tournament`, `Division`, `Competitor`) with FK-backed `Match` relations.
- First API endpoints:
  - `GET /api/v1/health`
  - `POST /api/v1/tournaments`
  - `POST /api/v1/divisions`
  - `POST /api/v1/competitors`
  - `PUT /api/v1/divisions/:id/rules`
  - `POST /api/v1/teams`
  - `POST /api/v1/teams/:id/members`
  - `POST /api/v1/matches`
  - `GET /api/v1/matches/:id`
  - `POST /api/v1/matches/:id/transition`
  - `POST /api/v1/matches/:id/score`
  - `GET /api/v1/matches/:id/score`
- First automated tests are included in `apps/api/test`.
- See `apps/api/README.md` for detailed setup and learning notes.
- API docs are available at:
  - Swagger UI: `GET /api/docs`
  - OpenAPI source: `docs/api/openapi.yaml`
  - Postman collection: `docs/api/zanshin-api.postman_collection.json`

## Post-Phase-4 Hardening Backlog

- Timer command/event model with full audited reconstruction.
- Realtime transport for match/scoring/timer/admin state.
- Scheduling workflows for shiaijo/shinpan assignment and conflict management.
- Explicit bracket graph model (round/slot/link) to replace insertion-order assumptions.
- Expanded admin UI for match/scoring/team-match/grading panel operations.
- Idempotency keys for command endpoints and standardized pagination contracts.

## GitHub Push Validation

This repository is configured with remote `origin`:

- `git@github.com:poleNgrek/zanshin-api.git`

Bootstrap commit push is used as the first validation of repository write access.
