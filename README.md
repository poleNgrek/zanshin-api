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

## GitHub Push Validation

This repository is configured with remote `origin`:

- `git@github.com:poleNgrek/zanshin-api.git`

Bootstrap commit push is used as the first validation of repository write access.
