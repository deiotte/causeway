---
description: Data layer rules
globs: ["**/migrations/**", "**/models/**", "**/repositories/**", "**/db/**"]
---

# Data layer

- Schema changes use expand-contract unless an ADR says otherwise (Spine SA-2.4).
  Never a destructive migration in a single deploy.
- The partition or shard key is a one-way door (Spine SA-2.2). Changing it is an
  ADR, not a refactor.
- PII and CUI carry field-level treatment per the data handling spec (Spine SA-2.12).
  New columns holding either need that treatment decided before merge.
- Retention and purge are legal obligations, not preferences (Spine SA-2.9).
- No raw SQL string interpolation. Parameterize or use the query builder.
