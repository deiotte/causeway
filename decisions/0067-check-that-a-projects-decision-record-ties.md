---
adr: "0067"
title: Check that a project's decision record ties — a shipped register check, warn-only, read by doctor
status: Accepted
date: 2026-11-27
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A second adopting project runs the check in CI for a release, which is the
  evidence Build DNA open item 6 asks for before it earns a number in gate/checks.json;
  or the check reports something false on a record the gate reads correctly.
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

Build DNA §8 states the rules a decision record has to keep: numbered and
immutable, superseded rather than edited, supersession and correction written in
both directions, a cause for every supersession, an open-items index whose counts
derive. `tools/validate.py` holds this repository to all of them. It does not ship,
so a consuming project gets the rules and nothing that reads them. Build DNA open
item 6 has recorded that gap since ADR 0025, and has said what would close it: a
candidate check, run by one adopter, before it earns a number in `checks.json`.

That evidence now exists. An adopting project wrote its own register check and
runs it in CI, and it was the only adopted project whose counts never drifted. Read
against the others for this ADR, the same kind of check found real faults: one
project's supersessions carry their cause in a field the standard does not read,
and another project's seeded index names a register heading that the seeded
`CLAUDE.md` does not have. That last one is the standard's own fault. Two starters
it ships disagree with each other, and nothing noticed, because nothing read both.

## Forces

- **A rule the standard states and does not check is a rule it finds broken later**
  (Build DNA open item 5, the same shape).
- **One parser for one format.** `tools/evaluate.py` already reads ADR frontmatter
  for the gate. A second reader that disagreed with it would pass records the gate
  rejects.
- **Warn before block** (ADR 0063). The evaluator ships warn-only; a project
  decides when a check becomes blocking.
- **Open item 6 asks for a second adopter before a gate number.** One project's
  evidence earns the tool, not the gate check.
- **Never name the adopting projects** (ADR 0036).

## Decision

1. **`tools/check-register.py` ships and is vendored.** It reads `decisions/` and
   `decisions/open-items.json` and reports two levels:
   - **violations** (exit 1): an ADR the gate cannot parse; a missing required
     field; an `adr` field that disagrees with the filename or is not the quoted
     four-digit number; a status outside the six; a row the vendored spine does not
     have; supersession or correction named in one direction only; `superseded_by`
     on a record whose status is not `Superseded`; a supersession with no S1–S5
     cause; a superseding ADR that drops a row nothing else re-closes; and, in the
     index, an undeclared register, a register document or heading that is gone,
     a duplicate id or number, an item naming an ADR that does not exist, an item
     open with a closing ADR or closed by nothing, an undeclared blocker, a
     relation that does not hold (half a duplicate closed, a closed supersessor),
     and counts that do not derive from the items;
   - **warnings** (exit 0, or 1 with `--strict`): two live ADRs on one row; a
     skipped number not listed under *Unused numbers*; an ADR missing from the
     `decisions/README.md` index; a declared blocker no item cites; the template's
     example still in the index.
2. **It reuses `evaluate.py`'s parser and spine reader**, imported by path.
3. **`tools/doctor.sh` reports it as one finding, `decisions.register`**, and never
   fails on it. A project makes it blocking by running the check in its own CI.
4. **The seeded `CLAUDE.md` gains the *Open items* heading** that the seeded index
   already names, so a fresh sync ties.
5. **It is not a gate check.** Open item 6 stays open, and its entry now says the
   candidate ships and what is still owed: a second adopter, the clause that every
   ADR naming an open item has a row, and the field-note age clause.

## Alternatives considered

- **A gate check now, in `checks.json`.** That is the step open item 6 says needs a
  second project's evidence. Shipping the tool first gives the second project
  something to run.
- **Derive the index from ADR frontmatter, as the adopting project does.** It works
  there, and it changes who owns the index. Build DNA §8 makes it hand-maintained
  on purpose; changing that is its own decision, and checking the hand-maintained
  index is useful whichever way that one goes.
- **Fold it into `evaluate.py`.** The evaluator reports gate checks by their
  `checks.json` ids; a check with no id there would be reported as something it is
  not.

## Consequences

**Easier.** A project can find a one-way supersession, a row ID that does not
exist, or a stale count before a reviewer has to. Doctor says whether the record
ties, beside whether the setup is complete.

**Harder.** One more vendored file. A project that adopted an earlier release and
wrote its supersession cause in its own field will see a violation on upgrade until
it moves the cause to `supersession_cause`. The message names the field.

**Security.** None directly. The check reads local files only, makes no network
call, writes nothing, and runs nothing it reads.

**Declared gaps.** It cannot tell whether an argument is any good, and does not
read prose register documents for their counts; it checks that the document and
heading the index names still exist.

## Revisit if

A second adopting project has run it in CI for a release, or it reports a fault on
a record the gate reads correctly.

## Evidence

- `tools/check-register.py`, `tools/test-check-register.sh` (CI step *The register
  check finds a record that does not tie*).
- `tools/doctor.sh`, finding `decisions.register`.
- `templates/project-CLAUDE.md`, the *Open items* heading.
- `docs/build-dna/open-items.md` item 6, and its row in `decisions/open-items.json`.
- The adopting project's own register check, cited without its name (ADR 0036).
