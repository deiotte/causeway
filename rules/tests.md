---
description: Testing standard
globs: ["**/test/**", "**/tests/**", "**/*_test.*", "**/*.test.*", "**/*.spec.*"]
---

# Tests

- New or changed behavior ships with tests, including the unhappy paths.
- Green before handoff, not after review.
- Test data is synthetic or masked. Never production PII in a fixture (Spine SA-8.2).
- Contract tests are the compatibility guarantee (Spine SA-3.7). If a consumer
  depends on it, a contract test proves it.
- A test that has been skipped for more than one sprint is either fixed or deleted.
  Permanently skipped tests are worse than absent ones — they read as coverage.
