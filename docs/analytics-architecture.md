# Analytics Architecture (Phase 4.1)

This document explains how domain events are projected into Neo4j over Bolt and how client analytics reads are served.

## Purpose

- Keep projection flow auditable and restart-safe.
- Keep read contracts stable while projection internals evolve.
- Keep transport details (Bolt client) isolated behind an adapter.

## Event Projection Flow

```mermaid
flowchart LR
  commandHandler[MatchCommandHandler] --> domainEvents[domain_eventsPostgres]
  domainEvents --> projectionWorker[Neo4jProjectionWorker]
  projectionWorker --> matchProjector[Neo4jMatchProjector]
  matchProjector --> boltAdapter[Neo4jClientBoltAdapter]
  boltAdapter --> neo4j[(Neo4jGraph)]
  projectionWorker --> checkpoints[(projection_checkpoints)]
```

Flow notes:

- `domain_events` is the durable source of truth for projection replay.
- `Neo4jProjectionWorker` reads unprocessed events in insertion order.
- `Neo4jMatchProjector` maps event payloads to Cypher statements.
- `Neo4jClient.Bolt` executes Cypher using Bolt transport (`neo4j_ex` driver).
- `projection_checkpoints` tracks projection progress per projection name.

## Analytics Read Flow

```mermaid
flowchart LR
  clientView[AdminDashboardOrClientView] --> analyticsRoute[AnalyticsMatchSummaryController]
  analyticsRoute --> analyticsContext[AnalyticsContext]
  analyticsContext --> readModel[(PostgresDomainEventsSummary)]
  analyticsContext --> checkpointRead[(projection_checkpoints)]
  analyticsContext --> futureNeo4j[(Neo4jReadModelsFuture)]
```

Flow notes:

- First read contract is `GET /api/v1/analytics/matches/summary`.
- Endpoint currently serves deterministic summary from `domain_events` scope filters.
- Contract is designed so backing implementation can move to Neo4j projections later without route changes.

## Worker Control and Recovery

```mermaid
flowchart TD
  configToggle[WorkerEnabledConfig] --> workerStart[ApplicationSupervisorStart]
  workerStart --> pollBatch[PollUnprocessedBatch]
  pollBatch --> projectEvent[ProjectSingleEvent]
  projectEvent --> projectOk{ProjectionOK}
  projectOk -->|yes| markProcessed[SetProcessedAt]
  markProcessed --> checkpointUpsert[UpsertCheckpoint]
  projectOk -->|no| haltBatch[StopBatchForRetry]
  haltBatch --> nextTick[RetryOnNextPoll]
```

Recovery notes:

- Failed projection stops the batch and leaves event unprocessed.
- Next worker cycle retries from the same event.
- Checkpoint only advances after successful projection and processed marking.
