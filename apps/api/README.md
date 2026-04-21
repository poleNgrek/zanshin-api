# API Service (Phase 2 Kickoff)

This directory contains the initial Phoenix-oriented API foundation for the Kendo Tournament Platform.

## What is implemented now

- Phoenix app skeleton files (`mix.exs`, `config`, `application`, `endpoint`, `router`)
- API v1 health endpoint: `GET /api/v1/health`
- Match lifecycle transition contract:
  - `POST /api/v1/matches/transition`
  - Uses `ZanshinApi.Matches.StateMachine`
- Initial tests for:
  - State machine behavior
  - Health endpoint
  - Transition endpoint

## Why we started with a state machine

The match lifecycle is one of the most critical business rules in your PRD. Implementing it first gives us:

- A stable API contract early
- A clear place to enforce domain rules
- Fast automated tests around the most important behavior

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

Then test:

- Health check: `curl http://localhost:4000/api/v1/health`
- Transition check:
  - `curl -X POST http://localhost:4000/api/v1/matches/transition -H 'content-type: application/json' -d '{"current_state":"scheduled","event":"prepare"}'`

## Next Phase 2 steps

- Generate Ecto schemas and migrations for tournaments/divisions/matches.
- Add role-based authorization paths (admin/shinpan/spectator).
- Persist transition events to database (audit trail).
