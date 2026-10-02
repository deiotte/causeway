# Project: [CALLSIGN]

<!--
  THIN BY DESIGN. "How we build" lives in the imported standard below.
  This file holds only what is true for THIS project. Keep it under ~200 lines
  and front-load the critical parts.
-->

## House standard (imported — read first)

@AGENTS.md

> Everything below is this project's specifics and any documented, owned
> deviations from the standard.
>
> **New here?** `CONTRIBUTING.md` walks a new developer through setup, the gate,
> and a first pull request, in order. This file is the reference it points at.

---

## What this is

[One or two sentences. What does [CALLSIGN] do, and for whom? Name the customer
context if it shapes decisions — agency or sector, ATO target, CSfC boundary.]

## Causeway placement

> How you arrive at these two is `skills/decision-spine/reference/placement.md`.
> Both *why* lines are one sentence and they are not optional filler: a value with
> no argument is a value nobody can disagree with, so the whole derivation gets
> rebuilt from memory by whoever is asked next.

- **Tier:** operational | mission | core
  - **Why:** [who inherits from this — not who calls it]
- **Criticality class:** C1 | C2 | C3
  - **Why:** [the question or escalator that decided it]
- **Declared by:** [name, role, date]
- **Gate profile:** derived — do not set
- **Platform overlay:** none | [name] — see `.causeway-lock`. If set, the
  overlay's dispositions are this register's starting state. Inherited rows still
  need ADRs; loosening a disposition is a row in the exceptions register below.

## Stack

- **Runtime / language:**
- **Framework(s):**
- **Data:**
- **Deploy target:**
- **Package ecosystems / registries:** [per Spine SA-5.14 — name the ecosystems,
  the mirror they install through, and the install-script posture. If npm is in
  here, the ADR that owns that deviation goes in the exceptions register below.]
- **Inference path:** [per Spine SA-5.15 and SA-5.16 — the provider and whether
  it runs inside the boundary, the tool surface the model gets, and what is
  redacted before the call. "None" is a complete answer and closes both rows.
  Anything else needs a named data owner on SA-5.16.]

## Commands

```
build:
test:
lint:
run:
```

## ⚠️ Environment constraints

[Non-obvious things that will waste an agent's time or break a build.
Worked example: GCC High Power Automate has no Variable actions — use Compose.]

## Do NOT

- [Files, paths, or systems nothing should touch.]

## Exceptions register

Deviations from the standard. Every row needs an ADR.

| Standard § | Deviation | ADR | Revisit when |
|---|---|---|---|
| | | | |

## Decision Spine status

- **Rows in scope:** [94 / 89 / 23]
- **Register:** `decisions/`
- **Last review:**
