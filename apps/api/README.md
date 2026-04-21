# API Service (Phase 2 Foundation)

This directory contains the initial Phoenix-oriented API foundation for the Kendo Tournament Platform.

## What is implemented now

- Phoenix app skeleton files (`mix.exs`, `config`, `application`, `endpoint`, `router`)
- API v1 health endpoint: `GET /api/v1/health`
- Initial match contracts:
  - `POST /api/v1/matches`
  - `GET /api/v1/matches/:id`
  - `POST /api/v1/matches/:id/transition`
- Match lifecycle state machine: `ZanshinApi.Matches.StateMachine`
- JWT auth baseline with Bearer token verification
- Role-aware transition policy (`admin`, `timekeeper`, `shinpan`)
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
  - `curl -X POST http://localhost:4000/api/v1/matches -H 'content-type: application/json' -H 'authorization: Bearer <JWT>' -d '{"tournament_id":"t1","division_id":"d1","aka_competitor_id":"c1","shiro_competitor_id":"c2"}'`
- Transition check:
  - `curl -X POST http://localhost:4000/api/v1/matches/<MATCH_ID>/transition -H 'content-type: application/json' -H 'authorization: Bearer <JWT>' -d '{"event":"prepare"}'`

Generate a local test token in `iex -S mix`:

```elixir
ZanshinApi.Auth.JWT.generate_token("local-user-1", "admin")
```

## Next Phase 2 steps

- Add tournament/division/competitor schemas and foreign-key constraints.
- Replace local JWT baseline with full OAuth/JWKS integration.
- Add scoring events (`ippon`, `hansoku`) and tighter role-state guards.
