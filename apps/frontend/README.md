# Frontend (Phase 3 Foundation)

This app is the Phase 3 frontend foundation for Zanshin.

## Stack

- Remix (SPA-first routing model)
- React + TypeScript
- Bun (package manager, runtime, and test runner)
- MUI for UI components
- Zod for API response validation
- Playwright for E2E smoke tests

## Setup

From this directory:

```bash
bun install
```

## Run

```bash
bun run dev
```

Default URL: `http://localhost:3000`

Set API base URL when needed:

```bash
API_BASE_URL=http://localhost:4000 bun run dev
```

## Test

Unit tests:

```bash
bun test
```

E2E smoke tests:

```bash
bun run test:e2e
```

## Lint

```bash
bun run lint
```
