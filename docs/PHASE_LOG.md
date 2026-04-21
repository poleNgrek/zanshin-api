# Phase Execution Log

This file is the execution history for the project.  
It tracks each phase/increment with goals, delivered scope, verification, issues, and next actions.

## Status Legend

- `done` - completed and pushed
- `in_progress` - implemented in workspace, not finalized/pushed yet
- `planned` - not started

---

## Phase 0 - PRD Consolidation

- **Status:** `done`
- **Goal:** consolidate product/system drafts into one actionable PRD.
- **Done:**
  - Created `docs/PRD.md` from source requirement PDFs.
  - Defined architecture direction, role model, non-functional requirements, and phased roadmap.
  - Added explicit testing/documentation requirements by phase.
- **Verification:**
  - PRD committed and pushed.
- **What went wrong / notes:**
  - No critical blockers in this phase.
- **Outcome:** requirements baseline established.

---

## Phase 1 - Repository Bootstrap

- **Status:** `done`
- **Goal:** establish initial project baseline and validate GitHub push access.
- **Done:**
  - Created root `README.md`.
  - Added project skeleton directories (`apps/api`, `apps/frontend`, `apps/analytics`, `apps/wordpress-plugin`, etc.).
  - Added `docker-compose.yml` baseline (`postgres`, `neo4j`, placeholder API/frontend services).
  - Added `.gitignore` baseline.
  - Pushed first bootstrap commit to GitHub.
- **Verification:**
  - `docker compose config` validated.
  - Initial commit pushed to `origin/main`.
- **What went wrong / notes:**
  - No product-level blockers.
- **Outcome:** repo is bootstrapped and remote workflow is functional.

---

## Phase 2 - API Foundation

### Increment 2.0 - Phoenix-Oriented API Kickoff

- **Status:** `done`
- **Goal:** create initial Phoenix-compatible API skeleton and first testable lifecycle contract.
- **Done:**
  - Added app skeleton files in `apps/api` (`mix.exs`, config, app modules, endpoint/router/controllers).
  - Added health endpoint and initial lifecycle transition endpoint.
  - Implemented `ZanshinApi.Matches.StateMachine`.
  - Added initial tests for state machine and controller flows.
- **Verification:**
  - Code committed and pushed.
- **What went wrong / notes:**
  - Local environment lacked direct `elixir/mix`; workaround used by building skeleton and container-based commands.
- **Outcome:** API foundation established for deeper domain work.

### Increment 2.1 - Persisted Match Lifecycle

- **Status:** `done`
- **Goal:** move from stateless transition demo to persisted lifecycle with audit trail.
- **Done:**
  - Added persisted models and context flow:
    - `Match`
    - `MatchEvent`
    - `Matches.transition_match/3`
  - Added DB migrations for matches and match events.
  - Added role-aware transition policy and controller integration.
  - Expanded tests (context + controller).
  - Updated docs for new contracts.
- **Verification:**
  - Docker test run passed (`mix test`).
  - Commit pushed (`Implement Phase 2 persisted match lifecycle foundation`).
- **What went wrong / notes:**
  - First container test attempt failed due to DB host mismatch; fixed by setting `DB_HOST=postgres` in compose API service.
- **Outcome:** lifecycle transitions are now persisted and auditable.

### Increment 2.2 - JWT Baseline + CI

- **Status:** `done`
- **Goal:** replace header role simulation with JWT claim extraction and add CI baseline.
- **Done:**
  - Added JWT auth module and auth plug.
  - Protected mutating API routes with bearer token auth.
  - Replaced `x-actor-role` simulation with claim-derived role.
  - Added JWT tests and updated controller tests for auth paths.
  - Added GitHub Actions CI (`.github/workflows/ci.yml`) for API format and tests with PostgreSQL service.
- **Verification:**
  - Docker checks passed:
    - `mix format --check-formatted`
    - `MIX_ENV=test mix test`
  - Commit pushed (`Add JWT auth baseline and API CI workflow`).
- **What went wrong / notes:**
  - Some container runs prompted interactively for Hex install (`mix` prompt). Resolved by non-interactive setup:
    - `mix local.hex --force`
    - `mix local.rebar --force`
  - Used `kill` to terminate blocked interactive background process before rerunning safely.
- **Outcome:** authenticated API mutation path and automated CI baseline are active.

### Increment 2.3 - Competition Core Entities and FK Wiring

- **Status:** `done`
- **Goal:** replace placeholder match references with real `Tournament`/`Division`/`Competitor` entities and foreign keys.
- **Done:**
  - Added `Competitions` context and schemas:
    - `Tournament`
    - `Division`
    - `Competitor`
  - Added migration creating those tables and linking `matches` via UUID FK constraints.
  - Updated `Match` schema to `belongs_to` references and FK constraints.
  - Added competition endpoints/controllers:
    - create/list tournaments
    - create/list divisions
    - create/list competitors
  - Updated fixtures and tests to use real entity IDs.
  - Updated docs (`README.md`, `apps/api/README.md`) for new endpoints.
- **Verification:**
  - Docker checks passed:
    - `mix format --check-formatted`
    - `MIX_ENV=test mix test` (24 tests, 0 failures)
- **What went wrong / notes:**
  - One fixture test failed due to tournament name minimum length (`"T1"`); fixed by using valid names.
  - Repeated non-interactive Hex setup required in ephemeral containers.
- **Outcome:** competition and required domain entities are in place with FK-backed match consistency.

### Increment 2.4 - Scoring Events and Match-State Guards

- **Status:** `in_progress`
- **Goal:** implement `ippon`/`hansoku` scoring flow with role and lifecycle guardrails.
- **Done (workspace):**
  - Added `ScoreEvent` model and migration.
  - Added score recording/listing APIs:
    - `POST /api/v1/matches/:id/score`
    - `GET /api/v1/matches/:id/score`
  - Implemented guards:
    - allowed roles for scoring: `shinpan`, `admin`
    - allowed match state: `ongoing`
    - supported score types: `ippon`, `hansoku`
    - supported sides: `aka`, `shiro`
  - Added context and controller tests for valid, forbidden, and invalid state flows.
- **Verification (workspace):**
  - Docker checks passed:
    - `mix format --check-formatted`
    - `MIX_ENV=test mix test` (31 tests, 0 failures)
- **What went wrong / notes:**
  - Initial format check failed for the new score controller; fixed with `mix format`.
- **Outcome:** scoring flow is implemented and validated locally; awaiting final commit/push.

---

## Phase 3 - Frontend Foundation

- **Status:** `planned`
- **Goal:** scaffold React + TypeScript frontend with API integration and Playwright baseline.
- **Planned increments:**
  - app scaffold + routing/state baseline
  - tournament/match admin starter flows
  - Playwright smoke + critical path tests

---

## Phase 4 - Analytics Foundation

- **Status:** `planned`
- **Goal:** event projection pipeline and Neo4j integration for first analytics outputs.

---

## Phase 5 - WordPress Plugin

- **Status:** `planned`
- **Goal:** plugin as API consumer (listings + live snippets + embeds).

---

## Phase 6 - Hardening and Release

- **Status:** `planned`
- **Goal:** full CI/CD maturity, observability, regression confidence, and release readiness.

