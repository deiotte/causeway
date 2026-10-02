---
description: Secrets handling
globs: ["**/*"]
---

# Secrets

- Zero hardcoded credentials. Ever. The scan is a merge-blocker, not a review comment.
- Secrets injected at runtime from a vault or KMS-backed store (Spine SA-5.5).
- No secrets in: source, config committed to the repo, test fixtures, log output,
  error messages, or CI logs.
- Credential lifetime and rotation are a decision, not a default (Spine SA-5.4).
- If you need a secret to run tests locally, that is a fixture problem. Fix the
  fixture; do not commit the secret.
