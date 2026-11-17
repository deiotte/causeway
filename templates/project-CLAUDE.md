# Project: [CALLSIGN]

<!--
  THIN BY DESIGN. "How we build" lives in the imported standard below.
  This file holds only what is true for THIS project. Keep it under ~200 lines
  and front-load the critical parts.
-->

## Rules that outlive a single change

<!--
  The most useful lines in this file, so they come first, above the standard.
  Each one is a thing that is expensive or impossible to undo once violated,
  stated as a rule with its reason in one line: an output whose bytes someone
  else recomputes, a boundary that decides who owns the code, a decision that is
  locked and why. Numbered, so a review can cite one. Keep this list short; if
  it grows past a screen, the rest belongs in docs/ and an ADR. Build DNA 2.0.
-->

1. [The rule.] — [Why, in one line. The ADR that records it.]

## House standard (imported)

@AGENTS.md

> `AGENTS.md` is the rules card: short, numbered, loaded every session. The
> reasoning behind each rule is in `docs/build-dna/`, and the procedures are skills
> under `.claude/skills/causeway-*`. Everything below is this project's specifics
> and any documented, owned deviations from the standard.
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
- **Gate evaluator:** [ENGINE AND VERSION] — or "none yet", and why. The engine
  that evaluates `gate/checks.json` for this project; `tools/doctor.sh` reads
  this line.
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
setup:     make setup      # the page built from .env.example (tools/setup); writes .env, runs targets
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
