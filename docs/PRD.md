# Kendo Tournament Platform PRD

## 1. Document Control

- **Version:** 1.0
- **Status:** Draft for implementation kickoff
- **Date:** 2026-04-21
- **Source Inputs:** `Kendo_Product_Requirements_Spec.pdf`, `Kendo_System_Full_Requirements_COMPLETE.pdf`

## 2. Product Vision

Build an API-first platform to run real-world kendo tournaments end-to-end, support grading sessions, and enable long-term analytics across events and federations. The platform must be practical for live use, extensible for future ranking systems, and intentionally structured as a learning-focused Elixir project.

## 3. Goals and Non-Goals

### 3.1 Goals

- Run tournament operations fully through a stable API.
- Provide a web frontend for tournament administration and live views.
- Support real-time match state, scoring, and timing.
- Maintain an auditable event history with undo-oriented capabilities.
- Establish analytics foundations for cross-tournament insights.
- Keep architecture modular so a WordPress plugin can consume public APIs.

### 3.2 Non-Goals (Initial Phases)

- No full mobile-native apps in initial phases (API compatibility only).
- No advanced ranking model (for example, ELO) in bootstrap/API foundation.
- No full federation onboarding workflows in early releases.
- No WordPress publishing feature parity with the core frontend initially.

## 4. Users and Roles

- **Admin/Timekeeper**
  - Creates and manages tournaments, divisions, and assignments.
  - Controls match lifecycle and authoritative timer actions.
- **Shinpan**
  - Records scoring and penalties only during valid match states.
- **Competitor**
  - Is represented by profile, division links, match history, and grading outcomes.
- **Spectator**
  - Consumes read-only public data (for example, schedules, live results).

## 5. Core Use Cases

1. Create a tournament with one or more divisions and format rules.
2. Register/import competitors and assign them to divisions.
3. Generate pairings and start matches.
4. Record live scoring, penalties, pause/resume actions, and overtime.
5. Handle edge cases such as match cancellation, undo, and reset workflows.
6. Re-pair competitors dynamically when tournament conditions change.
7. Run grading sessions and link outcomes to competitor profiles.
8. Publish live and historical tournament outputs via API and frontend.

## 6. Functional Requirements

### 6.1 Tournament Management

- Support tournament formats:
  - Bracket
  - Swiss
  - Round-robin
  - Team
- Manage lifecycle of tournaments and divisions.
- Maintain assignment models for shiaijo, shinpan, and schedules.

### 6.2 Match Management and State Machine

Required match lifecycle:

`scheduled -> ready -> ongoing -> paused -> ongoing -> completed -> verified`

Rules:

- State transitions must be validated server-side.
- Only role-authorized actions can trigger transitions.
- Transition history must be persisted for auditability.

### 6.3 Timekeeping

- Timer is backend authoritative.
- Support start, pause, resume, and overtime.
- Persist all timer events to preserve exact timeline reconstruction.

### 6.4 Scoring

- Shinpan can submit `ippon` and `hansoku` only while match is `ongoing`.
- Admin can correct or invalidate events through explicit audited actions.
- Score projection should update clients in near real-time.

### 6.5 Dynamic Tournament Handling

- Permit match cancellation due to injury/no-show/disqualification.
- Enable re-pairing logic after cancellations or bracket disruptions.
- Preserve clear event lineage for changed pairings.

### 6.6 Grading

- Manage grading sessions for Kyu/Dan.
- Record outcomes and attach them to competitor records.
- Expose grading history via API.

### 6.7 External Integration

- Prepare adapters for EKF/WKF IDs and external data imports.
- Use caching where external lookups can affect latency/reliability.

### 6.8 Real-Time Delivery

- Broadcast live updates for score, timer, and bracket changes.
- Frontend must react to server events without polling-only dependency.

## 7. Non-Functional Requirements

- **Scalability:** event-driven architecture and read models/projections.
- **Reliability:** immutable event trail, audit logs, and compensating actions.
- **Performance:** low-latency scoring and timer update propagation.
- **Security:** authenticated API access and role-based authorization.
- **Resilience:** tolerate intermittent client connectivity and allow recovery.
- **Maintainability:** clear domain contexts and documented Elixir patterns.

## 8. Product Architecture

### 8.1 Technology Direction

- **API Backend:** Elixir + Phoenix
- **Primary DB:** PostgreSQL
- **Frontend:** React + TypeScript
- **Analytics Store:** Neo4j
- **Containerization:** Docker / Docker Compose
- **Integration Surface:** Public API for WordPress plugin and other clients

### 8.2 Logical Components

- **Core Domain Engine**
  - Tournament, division, competitor, match, grading logic
- **API Layer**
  - REST API v1 contracts and authentication boundaries
- **Real-Time Layer**
  - Channels/pub-sub style event delivery
- **Event Pipeline**
  - Domain events captured and fanned out to projections/analytics
- **Analytics Layer**
  - Graph-oriented models and insight endpoints
- **Presentation Clients**
  - Web frontend
  - WordPress plugin consumer

### 8.3 Data Strategy

- PostgreSQL stores transactional truth and event records (`JSONB` payloads where needed).
- Neo4j stores analytics relationships and cross-tournament graph insights.
- Event-driven synchronization moves relevant facts from transactional to analytical models.

## 9. Domain Model (Initial)

- `Tournament`
- `Division`
- `Competitor`
- `Match`
- `MatchEvent`
- `Shinpan`
- `Shiaijo`
- `Timer`
- `GradingSession`
- `GradingResult`

## 10. Event Catalog (Initial)

- `match_created`
- `match_started`
- `ippon_awarded`
- `match_paused`
- `match_cancelled`
- `match_completed`
- `match_verified`
- `timer_started`
- `timer_paused`
- `timer_resumed`

## 11. API and Security Requirements

- REST API versioning at `/api/v1`.
- JWT/OAuth-compatible authentication baseline.
- Role-based permission checks for all mutating operations.
- Public read endpoints separated from protected admin/shinpan endpoints.

## 12. Analytics and WordPress Strategy

### 12.1 Analytics (Defined Now, Built Later)

- Include analytics requirements in contracts and event design from the start.
- Defer full analytics implementation to dedicated phase.
- First analytics objectives:
  - competitor performance trends
  - division/tournament relationship exploration
  - historical rivalry and federation rollups

### 12.2 WordPress Plugin (Defined Now, Built Later)

- Treat plugin as API consumer, not source of core business logic.
- Initial plugin scope:
  - tournament list widgets
  - live match snippets
  - embeddable public views

## 13. Phased Delivery Plan

### Phase 0 - PRD Consolidation (this document)

- Finalize unified requirements and architecture.

### Phase 1 - Bootstrap

- Repository baseline
- `README.md`
- Initial service directory skeleton
- Docker Compose baseline
- First commit pushed to remote

### Phase 2 - API Foundation

- Phoenix project scaffold
- Core contexts and domain contracts
- Initial match lifecycle and auth boundaries
- Testing:
  - Unit tests for domain and context logic (`mix test`)
  - Integration tests for REST endpoints and auth/role checks
  - Contract tests for match lifecycle state transitions

### Phase 3 - Frontend Foundation

- React + TypeScript scaffold
- Admin starter flows
- API contract integration
- Testing:
  - Component tests (Vitest + Testing Library)
  - End-to-end tests with Playwright for key admin flows
  - Accessibility smoke checks on critical screens

### Phase 4 - Analytics Foundation

- Event pipeline
- Neo4j integration
- Initial analytics endpoints
- Testing:
  - Projection tests from domain events to analytics models
  - Query correctness tests for initial analytics endpoints
  - Pipeline resilience tests for delayed/replayed events

### Phase 5 - WordPress Plugin

- API-consumer plugin scaffolding
- Initial widgets and live embeds
- Testing:
  - Plugin unit tests for rendering and configuration logic
  - Integration tests against staging API endpoints
  - Manual install/upgrade compatibility checks in WordPress

### Phase 6 - Hardening and Release

- Testing, observability, CI/CD, deployment playbooks
- Testing:
  - End-to-end regression pack across API + frontend + plugin
  - Performance baseline checks for live scoring and timer updates
  - Security checks for auth, permissions, and public/private endpoint separation

## 14. Success Metrics

- A complete tournament can be operated via API + frontend.
- Match lifecycle integrity is enforced under real-world edge cases.
- Event history supports reconstruction and audit.
- Architecture supports future analytics and federation features without core rewrites.

## 15. Testing and Documentation Requirements

- Every phase must ship with automated tests matching its scope.
- New business rules must include either unit tests or contract/integration tests before merge.
- Frontend user flows must be covered by Playwright tests once frontend scaffolding exists.
- Documentation updates are required in `README.md` (usage/testing) and dedicated docs for non-obvious implementation details.
- Code comments should explain intent for complex domain logic, not obvious syntax.

## 16. Acceptance Criteria for Current Execution Cycle

1. This PRD is committed in the repository and becomes the requirements baseline.
2. Repository contains a practical bootstrap layout and Docker baseline.
3. Initial bootstrap commit is pushed to GitHub remote for verification.
