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
  - `POST /api/v1/competitors`
  - `POST /api/v1/teams`
  - `POST /api/v1/teams/:id/members`
  - `GET /api/v1/tournaments`
  - `GET /api/v1/divisions?tournament_id=<TOURNAMENT_ID>`
  - `GET /api/v1/competitors`
  - `GET /api/v1/divisions/:id/rules`
  - `GET /api/v1/teams?division_id=<DIVISION_ID>`
  - `GET /api/v1/teams/:id/members`
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
  - lineup positions: `senpo`, `jiho`, `chuken`, `fukusho`, `taisho`
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
cd apps/api
mix setup
mix test
mix phx.server
```

## CI

GitHub Actions CI runs from `.github/workflows/ci.yml` and currently validates:

- `mix format --check-formatted`
- `mix test` (with PostgreSQL service in the workflow job)

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

## Next Phase 2 steps

- Add tournament/division/competitor schemas and foreign-key constraints.
- Add round progression and team match resolution rules (including representative match handling).
- Extend scoring with explicit target validation policies by age category defaults.
