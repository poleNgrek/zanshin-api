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

- **Status:** `done`
- **Goal:** implement `ippon`/`hansoku` scoring flow with role and lifecycle guardrails.
- **Done:**
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
- **Verification:**
  - Docker checks passed:
    - `mix format --check-formatted`
    - `MIX_ENV=test mix test` (31 tests, 0 failures)
- **What went wrong / notes:**
  - Initial format check failed for the new score controller; fixed with `mix format`.
- **Outcome:** scoring flow is implemented, tested, and pushed.

### Increment 2.5 - Format Rules and OAuth/JWKS Hardening

- **Status:** `done`
- **Goal:** support key individual/team rules in data model and harden auth with OAuth/JWKS verification.
- **Done in workspace:**
  - Added division rules model + API (`PUT/GET /api/v1/divisions/:id/rules`) with:
    - category type (`women`, `men`, `mixed`, `open`)
    - age group and age range (`children/youth/adult/masters/open`, `min_age`, `max_age`)
    - match duration and enchō settings
    - `allow_tsuki`, `team_size`, representative-match flag
  - Added team domain + APIs:
    - `POST /api/v1/teams`
    - `POST /api/v1/teams/:id/members`
    - `GET /api/v1/teams?division_id=...`
    - `GET /api/v1/teams/:id/members`
    - lineup positions include `senpo`, `jiho`, `chuken`, `fukusho`, `taisho`
  - Extended `score_events` with strike target (`men`, `kote`, `do`, `tsuki`) and enforced:
    - target required for `ippon`
    - `tsuki` rejected when division rule sets `allow_tsuki: false`
  - Added OAuth/JWKS verification path and switched auth plug to token verifier abstraction.
    - default mode: `oauth_jwks`
    - optional dev fallback: `legacy_hs256`
  - Added/updated tests for new rules/team/auth behavior.
- **Verification:**
  - Docker checks passed:
    - `mix format`
    - `MIX_ENV=test mix test` (37 tests, 0 failures)
- **What went wrong / notes:**
  - Initial OAuth/JWKS implementation failed due JOSE JWK representation mismatch; fixed by accepting JOSE key structs in configured JWKS.
  - One run was manually interrupted at interactive Hex prompt; rerun with forced non-interactive setup.

### Increment 2.6 - Division Progression Stage Modeling

- **Status:** `done`
- **Goal:** model explicit progression structure for pool/knockout/hybrid and other format variants.
- **Done in workspace:**
  - Added `DivisionStage` schema and migration for ordered stage plans per division.
  - Added `stage_type` support for:
    - `round_robin`
    - `knockout`
    - `pool_to_knockout`
    - `king_of_hill`
    - `points_accumulation`
  - Added stage APIs:
    - `POST /api/v1/division_stages` (authenticated write)
    - `GET /api/v1/division_stages?division_id=...` (public read)
  - Added context functions, fixtures, and controller/domain tests.

### Increment 2.7 - Podium Results and Fighting Spirit Awards

- **Status:** `done`
- **Goal:** model official podium outcomes and special awards for individual and team divisions.
- **Done in workspace:**
  - Added `DivisionMedalResult` model and API:
    - `POST /api/v1/division_medal_results`
    - `GET /api/v1/division_medal_results?division_id=...`
  - Added `DivisionSpecialAward` model and API:
    - `POST /api/v1/division_special_awards`
    - `GET /api/v1/division_special_awards?division_id=...`
  - Enforced podium rules:
    - place `1` => gold (max one)
    - place `2` => silver (max one)
    - place `3` => bronze (max two; no fourth place model)
  - Enforced division-specific recipient rules:
    - team divisions: medals awarded to teams
    - team divisions: fighting spirit awarded to one competitor linked to a team
  - Added domain and controller tests covering these constraints.

### Increment 2.8 - Tournament Export, Result Compute, and Avatar Profiles

- **Status:** `done`
- **Goal:** provide portable tournament snapshots for analytics, automate podium derivation, and support profile images.
- **Done in workspace:**
  - Added tournament export endpoint:
    - `GET /api/v1/tournaments/:id/export`
    - snapshot includes tournament, divisions/rules/stages, competitors, teams/team members, matches/events, score events, medals, and awards.
  - Added result computation endpoint:
    - `POST /api/v1/divisions/:id/compute_results`
    - computes gold/silver + dual-bronze from completed bracket-style individual match results.
  - Added avatar support:
    - competitors now support `avatar_url` (with `photo_url` write alias)
    - teams now support `avatar_url`
  - Added migrations, context logic, and tests for export/compute/avatar support.
- **Verification:**
  - Docker checks passed:
    - `mix format`
    - `MIX_ENV=test mix test` (49 tests, 0 failures)

### Increment 2.9 - Grading Workflow and Examiner Panel Modeling

- **Status:** `done`
- **Goal:** model realistic shinsa workflow with per-part outcomes, examiner panel voting, and stance/grade profile data.
- **Done in workspace:**
  - Expanded competitor profile:
    - preferred stance (`chudan`, `jodan_left/right`, `nito`, etc.)
    - grade profile (`grade_type`, `grade_value`, optional `grade_title`)
  - Expanded grading session/rules:
    - optional written requirement per session
    - carryover month configuration for kata and written parts
  - Expanded grading result model:
    - final result (`pass`/`fail`/`pending`)
    - per-part outcomes for `jitsugi`, `kata`, `written`
    - carryover deadline and declared stance per candidate entry
  - Added examiner and panel domain:
    - examiner registry
    - session panel assignments (head/member)
    - per-part examiner votes
    - examiner notes/comments
  - Added API namespaces under `/api/v1/gradings/...` for sessions, results, examiners, panel assignments, votes, and notes.
  - Added migrations, context logic, and controller/domain tests for the new grading flow.
- **Verification:**
  - Docker checks passed:
    - `mix format`
    - `MIX_ENV=test mix test` (53 tests, 0 failures)

### Increment 2.10 - Team Match Engine and Daihyo-sen Support

- **Status:** `done`
- **Goal:** model team-vs-team match outcomes and enable automated team podium computation with representative tie-breaks.
- **Done in workspace:**
  - Added `TeamMatch` domain model and migration:
    - team-vs-team match rows per division
    - team wins/ippon counters
    - optional representative (`daihyo-sen`) tie-break winner
    - persisted winner/loser team IDs
  - Added team match API:
    - `POST /api/v1/team_matches`
    - `GET /api/v1/team_matches?division_id=...`
  - Extended tournament export snapshot with `team_matches`.
  - Extended `compute_division_results/1`:
    - team-format divisions now compute gold/silver/dual-bronze from completed team matches
    - supports semifinal ties resolved by representative winner.
  - Added fixtures and tests for team match creation and team podium computation.
- **Verification:**
  - Docker checks passed:
    - `mix format`
    - `MIX_ENV=test mix test` (55 tests, 0 failures)

### Increment 2.11 - Grading Decision Engine and Finalize/Lock Flow

- **Status:** `done`
- **Goal:** compute grading outcomes from examiner votes and enforce finalization locks for result integrity.
- **Done in workspace:**
  - Added grading decision fields:
    - session-level `required_pass_votes` override
    - result-level `decision_snapshot`, `computed_at`, `finalized_at`, `locked_at`
  - Added decision engine in `Gradings` context:
    - computes per-part outcomes (`jitsugi`, `kata`, `written`) from vote counts and quorum
    - respects optional written requirement and carryover expiry
    - stores a decision snapshot for audit/read APIs
  - Added finalize/lock flow:
    - `POST /api/v1/gradings/results/:id/compute`
    - `POST /api/v1/gradings/results/:id/finalize`
    - `GET /api/v1/gradings/results/:id/decision_snapshot`
    - vote/note creation now blocked once result is locked
  - Added context and controller tests for compute/finalize/lock behavior.
- **Verification:**
  - Docker checks passed:
    - `mix format --check-formatted`
    - `MIX_ENV=test mix test` (56 tests, 0 failures)
  - Changes committed and pushed to `main`:
    - `8ceb051 Add Phase 2.11 grading decision engine and publish/lock flow`
- **Outcome:** grading decisions are now auditable, reproducible from votes, and protected by a finalize/lock boundary.

### Increment 2.12 - API Contract Documentation (OpenAPI + Swagger + Postman)

- **Status:** `done`
- **Goal:** publish a consumable API contract so external frontends can integrate safely.
- **Done in workspace:**
  - Added OpenAPI spec at `docs/api/openapi.yaml` for current `/api/v1` endpoints.
  - Added static OpenAPI serving via API at `/openapi.yaml`.
  - Added Swagger UI endpoint at `GET /api/docs`.
  - Added Postman collection at `docs/api/zanshin-api.postman_collection.json`.
  - Added API docs controller tests for docs and OpenAPI static endpoint.
- **Verification:**
  - Docker checks passed:
    - `mix format --check-formatted`
    - `MIX_ENV=test mix test` (58 tests, 0 failures)
- **Outcome:** API contract docs are now available for internal and external client development.

---

## Phase 3 - Frontend Foundation

- **Status:** `in_progress`
- **Goal:** scaffold React + TypeScript frontend with API integration and Playwright baseline.

### Increment 3.0 - Frontend Scaffold (Bun + Remix SPA + TS + MUI + Zod)

- **Status:** `done`
- **Goal:** establish frontend runtime, UI framework, validation layer, and testing baseline.
- **Done in workspace:**
  - Scaffolded `apps/frontend` with Bun-managed Remix SPA + TypeScript project files.
  - Added MUI theme + shared app shell/navigation.
  - Added Zod-based API client and starter schemas.
  - Added starter routes:
    - dashboard
    - tournaments list/create flow
    - grading results list + compute/finalize actions scaffold
  - Added ESLint configuration and scripts.
  - Added Bun unit tests (`bun test`) for schemas and API client.
  - Added Playwright config and smoke test.
- **Verification:**
  - API regression suite remains green after integration work (`58 tests, 0 failures`).
  - Frontend Bun verification pending on local machine because Bun runtime is not available in this tool environment.

### Increment 3.1 - Admin Flows and Auth Token UX

- **Status:** `done`
- **Goal:** remove manual-ID-heavy interactions by wiring practical admin flows for tournaments and grading.
- **Done in workspace:**
  - Upgraded frontend runtime to React 19 and Remix 2.17.x package line.
  - Added persistent auth token UI in app header and automatic token injection in API client.
  - Extended tournaments screen:
    - create/list tournaments
    - create/list divisions scoped to selected tournament
    - create/list grading sessions scoped to selected tournament
  - Extended grading results screen:
    - tournament/session selectors
    - competitor selector + grading result creation
    - per-result compute/finalize actions directly from list rows
  - Updated `apps/frontend/README.md` with complete local run instructions and auth token usage.

### Increment 3.2 - Frontend Test Hardening

- **Status:** `done`
- **Goal:** improve confidence for critical admin paths and client auth behavior.
- **Done in workspace:**
  - Expanded Playwright suite with API-mocked critical-path coverage for:
    - tournaments page data/render flow
    - grading results page data/render flow
  - Added Bun unit tests for token storage behavior used by auth header injection.

### Increment 3.3 - Real API UX Hardening and Admin Coverage

- **Status:** `done`
- **Goal:** improve real API usability with stronger client validation, loading/error states, and less ID-driven operator workflow.
- **Done in workspace:**
  - Upgraded frontend dependencies to latest requested baseline, including:
    - Zod v4
    - MUI v9 line
    - TypeScript v6
    - latest Remix/react/playwright/eslint ecosystem versions currently published
  - Added dedicated competitor admin route (`/competitors`) with list/create flow.
  - Improved tournaments and grading screens with:
    - client-side Zod validation before write requests
    - loading and in-flight action states
    - clearer empty-state and failure feedback
    - persistent token-based auth flow through app shell + API client
- **Verification:**
  - Frontend verification in containerized Bun runtime:
    - `bun install` passed
    - `bun run typecheck` passed
    - `bun run lint` passed (warnings only)
    - `bun run test` passed (6 tests, 0 failures)

### Increment 3.4 - Frontend Lint Strictness Cleanup

- **Status:** `done`
- **Goal:** restore stricter React Hooks lint guardrails after dependency/tooling upgrades.
- **Done in workspace:**
  - Re-enabled strict hooks lint checks in frontend ESLint config:
    - `react-hooks/set-state-in-effect`
    - `react-hooks/immutability`
  - Refactored route/component data-loading flow to satisfy strict hooks rules without suppressions.
  - Switched Playwright `webServer` to a production-like startup (`bun run build && bun run start`) to avoid dev-server readiness/404 issues during E2E startup.
  - Fixed frontend `start` script to use the correct Remix server build entry (`build/index.js`).
  - Updated Playwright smoke assertion to avoid strict-mode ambiguity from duplicated visible text.
  - Updated frontend README command section with Playwright browser-install prerequisite and production-like start commands.
- **Verification:**
  - Frontend verification passed in local Bun runtime:
    - `bun run typecheck` passed
    - `bun run lint` passed
    - `bun run test` passed (6 tests, 0 failures)
    - `bun run test:e2e` passed (3 tests, 0 failures)

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

