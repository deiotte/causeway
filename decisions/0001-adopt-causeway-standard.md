---
adr: "0001"
title: Adopt the Causeway standard as the engineering document of record
status: Accepted
date: 2026-08-02
spine_rows: [SA-9.5, SA-9.6]
approver:
  name: Karl
  role: Contract CTO
supersedes:
superseded_by:
---

## Context

Three artifacts govern how we build: the Build DNA process standard, the
Decision Spine design layer, and the Causeway gate configuration. Until now they
existed as prose in conversations and as per-project reconstructions.

The failure this repository exists to fix is concrete: the canonical `AGENTS.md`
became unretrievable, and at least one project shipped a reconstruction of it
carrying a "reconcile before first commit" header that was never reconciled.
That is a distribution failure, not a documentation failure. A standard with no
versioned home and no drift detection will diverge, and nobody will be able to
say which copy is real.

## Decision

This repository is the document of record for the Causeway engineering standard.

- `AGENTS.md` is the process layer, versioned here and vendored into projects.
- `skills/decision-spine/` is the design layer, packaged as a portable skill.
- `gate/` is the enforcement layer, consumed by CI.
- Projects consume the standard by vendoring with `tools/sync.sh`, which writes
  `.causeway-lock`; `tools/check-drift.sh` fails CI on divergence.
- The repository is versioned with semver. Projects pin.

## Alternatives considered

**Git submodule.** Cleaner in theory. Rejected: submodules are painful in mixed
tooling, and they do not survive air-gapped or mirrored repositories, which is a
substantial share of where this standard has to run.

**Package manager distribution (npm / pip).** Rejected: adds a runtime dependency
and a registry to a set of markdown files, and the registries are not reachable
from every environment we deploy into.

**Copy without a lock file.** Rejected as the status quo. It is precisely what
produced the missing-canonical problem.

## Consequences

- Local edits to vendored files become a build failure. Changes go upstream or
  they do not happen. This is the intended friction.
- Every project carries a version pin, so "which standard is this built to" has
  an answer.
- The standard now has its own `decisions/` directory and is subject to its own
  ADR discipline. If that becomes burdensome, the discipline is wrong for
  everyone, not just for us.

## Evidence

`VERSION`, `.causeway-lock` in each consuming project, and the drift check in CI.
