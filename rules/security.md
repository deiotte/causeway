---
description: API-layer security rules
globs: ["src/api/**", "**/handlers/**", "**/routes/**"]
---

# Security rules — API layer

## Every outbound call
- Timeout and retry with exponential backoff plus jitter.
- Idempotency key on anything a retry could double-fire.

## Talking to vendors or external services
- Through an adapter behind the canonical interface only (AGENTS.md §3).
  No vendor SDK calls in handler code — that is how lock-in and untestable
  edges get in.

## Before "done" on an API change
- Ships with tests including unhappy paths (401 / 403 / 422 / timeout).
- API test suite green before handoff.

<!-- Eyebrow-raisers live here. True merge-blockers (the scan, the control check) live in CI. -->
