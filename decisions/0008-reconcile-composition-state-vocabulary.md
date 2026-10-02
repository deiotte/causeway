---
adr: "0008"
title: Reconcile the composition-state vocabulary on SA-3.13
status: Accepted
date: 2026-08-09
spine_rows: [SA-3.13]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

`composition-state` blocks the build at G0, G1, G2 and G3. It is one of the nine
universal blockers, and it reads a single enumerated field out of `system.json`.
A check that blocks everywhere on a closed answer set needs exactly one place
that says what the answers are.

It had three, and they disagreed:

| Source | Answer set |
|---|---|
| `AGENTS.md` §4 | Catalog-composed / Wrapped / Unmanaged |
| `skills/decision-spine/reference/spine.md` SA-3.13 | Greenfield / wrapped / composed |
| The reference engine's system schema | `catalog-composed` / `wrapped` / `unmanaged` |

The engine and the process layer have always agreed. The spine row is the
outlier, and it has been since the row was written.

The disagreement is not a typo, which is why it is worth an ADR rather than a
commit message. SA-3.13 was mixing two axes. *Greenfield versus brownfield* asks
**how old is this system and did it precede the standard** — a lifecycle
question, and `AGENTS.md` §4 opens with it: "Greenfield is the exception. The
standard has to survive contact with systems that predate it." *Composition
state* asks **what is this system made of**, and §4's three states answer that
one. A greenfield system is catalog-composed, wrapped, or unmanaged like any
other; a wrapped system may be either greenfield or brownfield. The two axes are
independent, and the row was reading as though one implied the other.

`composed` versus `catalog-composed` is the ordinary half of the same problem —
the same state under two names, where the longer one carries the information that
matters. Composition against a catalog is what earns inherited control credit.
Composed *from something else* earns nothing and is not a state the standard
recognizes.

Found while assessing what the reference engine would have to implement to become Causeway's
runtime. It is the first thing that broke on contact, and it broke in the
cheapest possible way — before anyone wrote a check against it.

## Decision

SA-3.13's answer set becomes **Catalog-composed / wrapped / unmanaged**, matching
`AGENTS.md` §4 and the engine schema.

`AGENTS.md` is the source of truth for the vocabulary. The spine cites the
answer set; it does not define it. Where the two disagree in future, the spine
moves.

Spine version bumps to 0.8. No rows added, removed, or rescoped — the counts in
the header are unmoved and the adoption horizon has nothing to bite on. The
version moves because a closed answer set changed and `spine.closed_against` is
how a system tells the gate which vocabulary it answered in.

### Migration

Three cases, and only one of them costs anything.

- An ADR closing SA-3.13 with **`composed`** reads as `catalog-composed`. No
  action. Same state, longer name.
- An ADR closing it with **`wrapped`** is unaffected.
- An ADR closing it with **`Greenfield`** answered the lifecycle question rather
  than the composition question. It needs a one-line amendment naming one of the
  three states. The original answer is not wrong, it is an answer to SA-3.13 as
  the row was mis-written, and it belongs in prose rather than in the field.

No system's `system.json` needs editing, because no engine ever accepted
`greenfield` in that field.

## Alternatives considered

**Widen the enum to four states and accept `greenfield`.** Rejected. It would
make the blocking check accept a value that answers a different question, and the
first system to set it would inherit control credit decisions nobody made. The
category error is the defect; encoding it is not a fix.

**Move `AGENTS.md` §4 to match the spine.** Rejected on the same evidence that
decided the direction: the engine schema already implements §4, three of the engine's
existing checks read `composition-state` expecting those values, and every
`system.json` in the portfolio is written in them. Changing §4 would break the
one part of this that works.

**Leave it and document the mapping.** Rejected. A mapping table between two
spellings of a blocking check's answer set is a permanent tax on every reader,
and it would have to be vendored, checksummed, and kept current in two documents
that already disagreed once.

## Consequences

`composition-state` gains a single source of truth before anything is built
against it. The reference engine's existing schema becomes conformant without changing.

The standard now has a stated precedence rule for vocabulary — `AGENTS.md`
defines, the spine cites — which did not exist before and which the next overlay
will need.

One row's answer set changed without the row changing, which is a revision shape
the spine has not had before. The header note in v0.8 is the precedent for how it
gets recorded: correction, counts restated, no adoption consequence.

The `overlays/servicenow.md` disposition for SA-3.13 already used `wrapped` and
is unaffected. It is worth noting that the overlay was written against the correct
vocabulary while the row it dispositions was not, which is a second, independent
signal that the row was the outlier.
