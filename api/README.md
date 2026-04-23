# API Service (Phase 2 Foundation)

This directory contains the initial Phoenix-oriented API foundation for the Kendo Tournament Platform.

## What is implemented now

- Phoenix app skeleton files (`mix.exs`, `config`, `application`, `endpoint`, `router`)
- API v1 health endpoint: `GET /api/v1/health`
- Initial match contracts:
  - `POST /api/v1/matches`
  - `GET /api/v1/matches/:id`
  - `POST /api/v1/matches/:id/transition`
  - `POST /api/v1/matches/:id/score`
  - `GET /api/v1/matches/:id/score`
- Competition setup contracts:
  - `POST /api/v1/tournaments`
  - `POST /api/v1/divisions`
  - `PUT /api/v1/divisions/:id/rules`
  - `POST /api/v1/division_stages`
  - `POST /api/v1/division_medal_results`
  - `POST /api/v1/division_special_awards`
  - `POST /api/v1/divisions/:id/compute_results`
  - `POST /api/v1/gradings/sessions`
  - `POST /api/v1/gradings/sessions/:id/results`
  - `POST /api/v1/gradings/examiners`
  - `POST /api/v1/gradings/sessions/:id/panel_assignments`
  - `POST /api/v1/gradings/results/:id/votes`
  - `POST /api/v1/gradings/results/:id/notes`
  - `POST /api/v1/gradings/results/:id/compute`
  - `POST /api/v1/gradings/results/:id/finalize`
  - `POST /api/v1/competitors`
  - `POST /api/v1/teams`
  - `POST /api/v1/teams/:id/members`
  - `POST /api/v1/team_matches`
  - `GET /api/v1/tournaments/:id/export`
  - `GET /api/v1/tournaments`
  - `GET /api/v1/divisions?tournament_id=<TOURNAMENT_ID>`
  - `GET /api/v1/competitors`
  - `GET /api/v1/divisions/:id/rules`
  - `GET /api/v1/division_stages?division_id=<DIVISION_ID>`
  - `GET /api/v1/division_medal_results?division_id=<DIVISION_ID>`
  - `GET /api/v1/division_special_awards?division_id=<DIVISION_ID>`
  - `GET /api/v1/gradings/sessions?tournament_id=<TOURNAMENT_ID>`
  - `GET /api/v1/gradings/sessions/:id/results`
  - `GET /api/v1/gradings/examiners`
  - `GET /api/v1/gradings/sessions/:id/panel_assignments`
  - `GET /api/v1/gradings/results/:id/votes`
  - `GET /api/v1/gradings/results/:id/notes`
  - `GET /api/v1/gradings/results/:id/decision_snapshot`
  - `GET /api/v1/teams?division_id=<DIVISION_ID>`
  - `GET /api/v1/teams/:id/members`
  - `GET /api/v1/team_matches?division_id=<DIVISION_ID>`
- Match lifecycle state machine: `ZanshinApi.Matches.StateMachine`
- OAuth/JWKS auth baseline with Bearer token verification
- Role-aware transition policy (`admin`, `timekeeper`, `shinpan`)
- Score policy:
  - score types: `ippon`, `hansoku`
  - targets: `men`, `kote`, `do`, `tsuki` (target required for `ippon`)
  - actor roles allowed: `shinpan`, `admin`
  - allowed only when match state is `ongoing`
  - `tsuki` can be restricted per division rules (for example children categories)
- Division rules support:
  - category type (`women`, `men`, `mixed`, `open`)
  - age group (`children`, `youth`, `adult`, `masters`, `open`)
  - age range (`min_age`, `max_age`)
  - match duration, enchō mode, and team size
- Team support:
  - team creation per division
  - team avatar/profile image URL support
  - lineup positions: `senpo`, `jiho`, `chuken`, `fukusho`, `taisho`
  - team-vs-team match records with optional representative (`daihyo-sen`) winner
- Competitor profile support:
  - avatar/photo URL support (`avatar_url`; `photo_url` accepted as alias on write)
  - preferred stance support (`chudan`, `jodan_left`, `jodan_right`, `nito`, etc.)
  - grade profile support (`grade_type`, `grade_value`, optional `grade_title`)
- Division progression stages:
  - explicit ordered format plan per division
  - supported stage types: `round_robin`, `knockout`, `pool_to_knockout`, `king_of_hill`, `points_accumulation`
- Podium + awards:
  - medals are modeled by place (`1`, `2`, `3`) and derived medal type (`gold`, `silver`, `bronze`)
  - third place supports two bronze medal recipients (semifinal losers)
  - fighting spirit award is modeled for both individual and team divisions
- Result computation engine:
  - computes gold/silver/dual-bronze for bracket-style individual divisions from completed match score events
  - supports semifinal-loser dual bronze output
  - computes team podium from completed team matches, including tied rounds resolved by representative match
- Tournament export:
  - full tournament snapshot export as JSON (`GET /api/v1/tournaments/:id/export`)
- Grading support:
  - per-part grading outcomes (`jitsugi`, `kata`, `written`) with binary final result modeling
  - optional written requirement by session
  - carryover window support for non-finalized sessions
  - examiner registry, panel assignments, pass/fail votes, and free-form examiner notes
  - decision engine computes per-part outcomes from votes using quorum and stores decision snapshots
  - finalize/lock flow prevents post-finalization vote and note changes
- API documentation:
  - Swagger UI: `GET /api/docs`
  - OpenAPI document served by API: `GET /openapi.yaml`
  - OpenAPI source file in repo: `docs/api/openapi.yaml`
  - Postman collection: `docs/api/zanshin-api.postman_collection.json`
- Command idempotency baseline:
  - command routes below now require `idempotency-key` request header:
    - `POST /api/v1/matches/:id/transition`
    - `POST /api/v1/matches/:id/score`
    - `POST /api/v1/divisions/:id/compute_results`
    - `POST /api/v1/gradings/results/:id/compute`
    - `POST /api/v1/gradings/results/:id/finalize`
  - replayed responses include `x-idempotent-replayed: true`
- Standardized pagination baseline:
  - list endpoints accept optional `limit` and `offset` query params
  - list responses include `pagination` metadata:
    - `total`
    - `limit`
    - `offset`
    - `count`
    - `has_more`
- Real tournament/division/competitor entities with DB-level FK constraints on matches
- Persistent audit trail in `match_events` table
- Initial tests for:
  - State machine behavior
  - Match context behavior
  - Health endpoint
  - Match and transition endpoints

## Why we started with a state machine

The match lifecycle is one of the most critical business rules in your PRD. Implementing it first gives us:

- A stable API contract early
- A clear place to enforce domain rules
- Fast automated tests around the most important behavior
- An event trail that supports future analytics and auditing

## How to run locally

Prerequisites:

- Elixir 1.17+
- Erlang/OTP 26+
- PostgreSQL (or Docker Compose from repo root)

From repo root:

```bash
docker compose up -d postgres
cd api
mix setup
mix run priv/repo/seeds.exs
mix test
mix phx.server
```

From repo root, quick verification helper:

```bash
bash scripts/verify_api.sh
```

Seed behavior:

- `mix run priv/repo/seeds.exs` creates a full-domain sample dataset (tournaments/divisions/rules/stages, competitors, teams/matches, grading, medals/awards).
- Seed is intentionally non-destructive; if tournaments already exist, it exits without adding duplicates.

## CI

GitHub Actions CI runs from `.github/workflows/ci.yml` and currently validates:

- `mix format --check-formatted`
- `mix test` (with PostgreSQL service in the workflow job)
- frontend lint and unit tests (`bun run lint`, `bun run test`)
- real API Playwright lane (`tests/e2e/real-api.spec.ts`) with seeded API service

## Test Fixtures

- API tests can use deterministic fixture builders under:
  - `test/support/fixtures/competitions_fixtures.ex`
  - `test/support/fixtures/matches_fixtures.ex`
  - `test/support/fixtures/full_domain_fixtures.ex`
- Gherkin-style API scenarios can live in:
  - `test/features/*.feature`
  - executed by ExUnit test modules that parse scenarios from `test/support/gherkin.ex`
  - run only those scenarios with: `mix test --only gherkin`

## Domain Event Envelope (Outbox-Ready)

Match lifecycle and scoring now emit canonical domain events into `domain_events`.

Envelope fields:

- `event_type`
- `event_version`
- `aggregate_type`
- `aggregate_id`
- `occurred_at`
- `actor_role`
- `payload`
- `source`
- `correlation_id`
- `causation_id`
- `processed_at` (set by future projection workers)

## Analytics Projection Bootstrap (Phase 4.0)

First analytics slices now exist in API:

- `ZanshinApi.Analytics.Workers.Neo4jProjectionWorker`
  - polls unprocessed `domain_events` in ordered batches
  - dispatches to `ZanshinApi.Analytics.Projectors.Neo4jMatchProjector`
  - marks projected events via `processed_at`
  - persists projection progress in `projection_checkpoints`
- worker is disabled by default and controlled via:
  - `config :zanshin_api, ZanshinApi.Analytics.Workers.Neo4jProjectionWorker, ...`
- Neo4j adapter contract is defined via `ZanshinApi.Analytics.Neo4jClient`.
- Active Bolt adapter:
  - `ZanshinApi.Analytics.Neo4jClient.Bolt` (implemented with `neo4j_ex`)
  - Bolt transport endpoint is `NEO4J_BOLT_URL` (default `bolt://localhost:7687`)
- First analytics read contract:
  - `GET /api/v1/analytics/matches/summary`
  - `GET /api/v1/analytics/events/feed`
  - `GET /api/v1/analytics/matches/state_overview`
  - `GET /api/v1/analytics/dashboard/overview`
  - required query param: `tournament_id`
  - optional filters: `division_id`, `from`, `to`, `limit`, `offset`
  - response includes `data_source` (`postgres`, `neo4j`, `postgres_fallback`)
  - `dashboard/overview` includes consolidated sections:
    - summary KPIs + event-type breakdown
    - state overview
    - recent event feed
    - insights (`throughput_trend`, `top_active_matches`, `actor_role_activity`)

### Bolt Adapter Basics (Learning Notes)

- Bolt is Neo4j's native binary protocol (optimized for app-to-db query traffic).
- In this project:
  - the worker/projector creates Cypher + params
  - the adapter executes those Cypher statements over Bolt
  - checkpointing and `processed_at` keep replay behavior auditable
- Runtime environment knobs:
  - `NEO4J_BOLT_URL`
  - `NEO4J_USERNAME`
  - `NEO4J_PASSWORD`
  - `NEO4J_POOL_SIZE`
  - `NEO4J_CONNECTION_TIMEOUT_MS`
  - `NEO4J_QUERY_TIMEOUT_MS`
  - `ANALYTICS_SUMMARY_SOURCE` (`neo4j` default, optional `postgres` override)

### Verify projected data in Neo4j Browser

- Open Neo4j Browser: `http://localhost:7474`
- Run quick checks:
  - `MATCH (m:Match) RETURN m LIMIT 10`
  - `MATCH (e:DomainEvent)-[:APPLIES_TO]->(m:Match) RETURN e,m LIMIT 25`
- Compare with API event log:
  - `SELECT event_type, aggregate_id, processed_at FROM domain_events ORDER BY inserted_at DESC LIMIT 25;`

### Live Neo4j smoke sequence (from repo root)

```bash
# 1) Bring infra up
docker compose up -d postgres neo4j

# 2) Prepare API DB state
cd api
mix setup
mix run priv/repo/seeds.exs

# 3) Emit a couple of domain events (replace token/ids as needed)
curl -X POST http://localhost:4000/api/v1/matches/<MATCH_ID>/transition \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer <TOKEN>' \
  -d '{"event":"prepare"}'

curl -X POST http://localhost:4000/api/v1/matches/<MATCH_ID>/score \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer <TOKEN>' \
  -d '{"score_type":"ippon","side":"aka","target":"men"}'

# 4) Run one projection cycle into Neo4j
mix run -e "IO.inspect(ZanshinApi.Analytics.Workers.Neo4jProjectionWorker.run_once())"

# 5) Validate API summary from Neo4j
curl 'http://localhost:4000/api/v1/analytics/matches/summary?tournament_id=<TOURNAMENT_ID>' \
  -H 'authorization: Bearer <TOKEN>'
```

Neo4j adapter interfaces:

  - `ZanshinApi.Analytics.Neo4jClient`
  - concrete adapter: `ZanshinApi.Analytics.Neo4jClient.Bolt`

Then test:

- Health check: `curl http://localhost:4000/api/v1/health`
- Create match:
  - `curl -X POST http://localhost:4000/api/v1/matches -H 'content-type: application/json' -H 'authorization: Bearer <TOKEN>' -d '{"tournament_id":"t1","division_id":"d1","aka_competitor_id":"c1","shiro_competitor_id":"c2"}'`
- Transition check:
  - `curl -X POST http://localhost:4000/api/v1/matches/<MATCH_ID>/transition -H 'content-type: application/json' -H 'authorization: Bearer <TOKEN>' -d '{"event":"prepare"}'`
- Score check:
  - `curl -X POST http://localhost:4000/api/v1/matches/<MATCH_ID>/score -H 'content-type: application/json' -H 'authorization: Bearer <TOKEN>' -d '{"score_type":"ippon","side":"aka","target":"men"}'`

Auth modes:

- Default: OAuth/JWKS validation (`AUTH_MODE=oauth_jwks`)
- Optional local fallback for development: `AUTH_MODE=legacy_hs256`

CORS:

- Local frontend origins are allowed by default:
  - `http://localhost:3000`
  - `http://127.0.0.1:3000`
- Override with `CORS_ALLOWED_ORIGINS` (comma-separated).

## Next steps

- Continue Phase 4 by wiring richer Neo4j read models for analytics dashboards.
- Add replay/drift checks once dedicated analytics workers are expanded.
