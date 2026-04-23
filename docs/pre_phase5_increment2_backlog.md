# Pre-Phase-5 Increment 2 - Extensive Hardening Program

This document captures the dedicated Increment 2 execution plan for the deferred extensive backlog.

## Scope

1. Timer command/event model (`start`, `pause`, `resume`, overtime) with auditable reconstruction
2. Realtime updates (channels/SSE) for match/timer/score/admin state
3. Shiaijo/shinpan scheduling and assignment workflows
4. Explicit bracket graph model (round/slot/link) replacing insertion-order assumptions
5. Broader admin UI for match/scoring/team-match/grading panel operations
6. Idempotency keys on command endpoints
7. Standardized pagination contracts for list endpoints
8. Projection replay/drift tests once analytics workers exist

## Rollout Sequence

### Wave 1: API Reliability Foundations
- Idempotency keys on command endpoints
- Standardized pagination contracts
- Projection replay/drift tests

Verification gates:
- `mix test` domain + controller suites for command endpoints
- deterministic replay test coverage for analytics workers
- OpenAPI contract updates for idempotency/pagination

### Wave 2: Core Domain Architecture
- Timer command/event model
- Explicit bracket graph model
- Shiaijo/shinpan scheduling model

Verification gates:
- full state reconstruction tests for timer events
- bracket traversal and ordering tests
- scheduling conflict and assignment tests

### Wave 3: Realtime + Admin Operations
- Realtime updates (channels/SSE)
- Broader admin UI operations

Verification gates:
- channel/SSE integration tests for event broadcast paths
- frontend e2e coverage for critical admin operations
- fallback polling behavior where realtime transport is unavailable

## Exit Criteria

- Every scope item is delivered through sub-increments with dedicated tests and docs.
- API contracts remain stable under `/api/v1` and are reflected in OpenAPI docs.
- No regressions to closed Pre-Phase-5 Increment 1 frontend/CI foundations.
