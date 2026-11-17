---
adr: "0061"
title: Load a rules card and read the argument on demand — AGENTS.md becomes a numbered card, and the reasoning moves to docs/build-dna/
status: Accepted
date: 2026-11-17
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Sessions in adopting projects start missing rules that moved out of the
  card, or the card grows back past its guard because rules keep needing their
  argument restated beside them. Either means the split is in the wrong place.
approver:
  name: Karl Deiotte
  role: Maintainer
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Every adopting project's `CLAUDE.md` imports `@AGENTS.md`, so every coding session
in those projects loads it before reading any code. At v2.16.0 it was 61 KB and
1,041 lines. A review from the builder's side (2026-11-17) sampled six of the
maintainer's repositories, three of them on Causeway, and found:

- **The instruction load.** The three adopting projects load 62 to 70 KB of
  instructions per session. The three that do not use Causeway load 5 to 21 KB, and theirs were the sharpest instruction files in the
  sample: numbered hard invariants, a one-line reason each.
- **What the bulk was.** Perhaps a few dozen lines of the 1,041 changed what an agent
  does on a given task. The rest was rationale, history ("From v1.0 to v1.13.1 the
  only documented way to get Causeway was…"), worked examples, and about 130 lines
  of Causeway's own open-items register, shipped to every consumer though it is
  about how Causeway tracks itself.
- **The cost.** Context is the smaller part. The larger part is signal: written at
  one emphasis throughout, the ten rules that must never bend cannot be told from
  the two hundred sentences arguing for them, and the project's own critical rules
  sit underneath the import.

## Forces

- **What is loaded every time should be what is followed every time.** Reasoning
  is read when a rule is questioned, not on every task.
- **Nothing may be lost.** The argument is the record of why; ADR 0001 made this
  document the document of record.
- **Section numbers are cited everywhere.** Skills, templates, overlays and 60 ADRs
  say "§8"; a renumbering would break every one of them.
- **Build DNA versions independently** (ADR 0012), and an overlay is ratified
  against it by name (ADR 0024).

## Decision

1. **`AGENTS.md` is the rules card.** Numbered rules (`8.7`), each stating what is
   required and its reason in one line, under the same ten section numbers and
   headings as before. It says up front that it is short on purpose and where the
   rest lives. Build DNA moves to **2.0**.
2. **The argument moves, verbatim, to `docs/build-dna/`**, one file per section
   plus `open-items.md`. Each file opens with a note that it is the argument, not
   the rule. The files are vendored and digested with the card, so "read the
   section a change touches" works with no clone of the standard.
3. **Build DNA's open-items register moves with it** to
   `docs/build-dna/open-items.md`; the index's `build-dna` register now names that
   document. Numbers are unchanged.
4. **`validate.py` guards the card's size**, so it cannot quietly grow back into the
   essay. The bound is a line count and a byte count, stated in the check.
5. **The project template puts the project's own durable rules first**, above the
   import, because a project's hard invariants are the most useful lines an agent
   reads: a byte-stable output rule, a table of locked decisions, a funding-boundary
   rule.

## Alternatives considered

- **Trim `AGENTS.md` in place.** Deletes the record of why. Rejected on the second
  force.
- **Keep the essay and add a summary at the top.** The import still loads all of it,
  and the summary and the body become two statements of each rule to keep in step.
- **Renumber into a fresh rule scheme.** Cleaner, and breaks every `§N` citation in
  the repository and in every adopting project. Rejected on the third force; rule
  numbers are nested under the existing section numbers instead.

## Consequences

**Easier.** An agent in an adopting project loads about 11 KB instead of 61 KB, and
every rule it loads is one it is expected to follow. A reviewer can cite "Build DNA
7.6" instead of a paragraph.

**Harder.** Two places to edit when a rule's substance changes: the card's line and
the argument file. The argument files are explicitly subordinate: if they disagree,
the card says what is required and the disagreement is a bug.

**Security.** None directly. The agent-boundary rule (7.5) and the security floor
(5.6) are on the card in full and point at `rules/agent-workspace.md` and
`rules/security.md`, which are unchanged.

**Declared gaps.** Nothing checks that a card rule and its argument file still say
the same thing; that is review, as it was for the essay.

## Revisit if

Rules that moved out of the card start being missed in adopting projects, or the
card hits its size guard because rules keep needing their argument beside them.

## Evidence

- `AGENTS.md` (Build DNA 2.0), `docs/build-dna/`.
- `tools/validate.py`, the card-size guard.
- `templates/project-CLAUDE.md`, the project's durable rules first.
- The review that prompted it: the maintainer's project thread, 2026-11-17.
