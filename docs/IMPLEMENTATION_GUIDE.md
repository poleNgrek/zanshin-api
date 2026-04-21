# Implementation Guide (Learning-Focused)

## Purpose

This document explains how implementation decisions are made in each phase, with beginner-friendly context for Elixir/Phoenix and clear testing expectations.

## How to Read the Codebase

- `docs/PRD.md` describes the product and architecture requirements.
- `apps/api` will hold Phoenix code organized by domain contexts.
- `apps/frontend` will hold React UI and Playwright tests.
- `apps/analytics` will consume domain events and build analytics projections.
- `apps/wordpress-plugin` will consume public API endpoints.

## Elixir and Phoenix Basics (for this project)

- **Elixir modules** group functions by responsibility.
- **Phoenix contexts** group domain logic (for example, `Tournaments`, `Matches`) and keep controllers thin.
- **Ecto schemas** map domain entities to database tables.
- **Changesets** validate and transform incoming data before persistence.
- **Controllers** expose REST endpoints.
- **Channels/PubSub** support real-time updates for live match data.

Project rule: business rules must live in contexts/domain modules, not in controllers.

## Phase-by-Phase Implementation and Testing

### Phase 2 - API Foundation

What we implement:

- Phoenix application scaffold
- Core contexts and first entities
- Match state machine and role-aware command handlers

How we test:

- Unit tests for domain modules and state transitions
- Integration tests for API endpoints
- Permission tests by role

How we document:

- Context-level README notes for non-obvious flows
- Comments for complex transition and event-handling logic

### Phase 3 - Frontend Foundation

What we implement:

- React + TypeScript app scaffold
- Admin-first workflows (tournament setup, match overview)
- API client and typed models

How we test:

- Component tests (Vitest + Testing Library)
- Playwright end-to-end tests for critical paths

How we document:

- Frontend architecture notes for routing/state/data fetching
- Test coverage notes for key user journeys

### Phase 4 - Analytics Foundation

What we implement:

- Event consumption and projection logic
- Neo4j graph models and first analytics endpoints

How we test:

- Projection correctness from known event sequences
- Query result validation against expected fixtures
- Replay/idempotency checks

### Phase 5 - WordPress Plugin

What we implement:

- Plugin scaffolding and settings
- Tournament list/live snippet blocks consuming API

How we test:

- Unit tests for plugin rendering and config behavior
- Integration checks against staged API contracts
- Manual install/upgrade checks

### Phase 6 - Hardening

What we implement:

- CI pipelines and deployment checks
- Observability and reliability improvements

How we test:

- End-to-end regressions
- Performance checks for live scoring/timer paths
- Security tests for auth and endpoint access

## Testing Philosophy

- Start with behavior-focused tests for each new business rule.
- Keep test suites fast and deterministic.
- Add end-to-end tests only for high-value user journeys.
- Do not merge code that changes behavior without corresponding tests.

## Code Commenting Guidelines

- Add comments only for non-obvious intent and constraints.
- Prefer comments for:
  - state machine rules
  - event ordering assumptions
  - domain edge-case handling
- Avoid comments that just repeat code syntax.

## Review Checklist for Each Phase

1. Scope aligns with PRD phase definition.
2. Tests cover the changed behaviors.
3. README/docs updated with run/review/test instructions.
4. Commands to run app and tests work locally.
5. Security and role checks are present for mutating APIs.
