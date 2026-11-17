# Build DNA — §1 North star

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## 1. North star — Causeway

**Causeway** governs. Velocity comes from prepared ground, not from skipped
steps: a catalog of pre-authorized components, tiered governance, and time-boxed
authorization for work at the edge. Building on the causeway is fast because the
ground was inspected in advance. Stepping off it is a deliberate, visible act
with a named approver — not an accident and not a shortcut.

Implications that the rest of this document exists to serve:

- Composition from the catalog is the default. Bespoke is the exception, and
  exceptions are owned (§8).
- Tier placement — Core, Mission, Operational — is a catalog fact, not a
  self-assessment.
- Criticality is a separate axis from tier, set by whoever owns the
  consequences. See Decision Spine SA-1.1 and SA-1.14.
- **How a system arrives at either** — the tests, the escalators, the
  declaration, and the rules for changing one later — is
  `skills/decision-spine/reference/placement.md`. It is the first thing a new
  build owes and the last thing anybody writes down, which is the wrong order
  and the reason that file exists.
- **Someone else's platform is prepared ground you did not prepare.** Building on
  ServiceNow, Power Platform, or Salesforce inherits a body of decisions, and
  which ones is not obvious from the outside — the answer is written down in a
  **platform overlay** (`overlays/`). An overlay relocates the standard into
  native mechanics. It never reduces what is owed, and a row the platform answers
  still closes with an ADR.
