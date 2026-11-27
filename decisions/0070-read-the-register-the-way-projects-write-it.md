---
adr: "0070"
title: Read the register the way projects write it — ranges of unused numbers, a recorded lapse, and corrections that restate their rows
status: Accepted
date: 2026-11-27
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A project needs a lapse to carry more than a sentence (a date, an owner,
  a review), or a range under Unused numbers is read as something its author did
  not mean.
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

ADR 0067 shipped `tools/check-register.py` in v3.1.0. The first two projects to
upgrade ran it the same day, and each found the checker disagreeing with a record
that was correct:

1. **A range of unused numbers.** One project's `decisions/README.md` says
   *0001 to 0008: taken by the ADRs written before adoption*. The checker looked for
   each four-digit number as a literal string, found `0001` and `0008`, and warned
   that 0002 to 0007 were skipped with no line saying why. The line was there. The
   project listed every number by hand to quiet it.
2. **A lapse it told people to record.** The violation for a closed item with no
   closing ADR says *name the closing ADR, or answered_by, or say it lapsed*. No
   field said it lapsed. A project that followed the message had nowhere to write
   the answer, and the violation stayed.
3. **A correction is not a duplicate.** Build DNA 8.4 corrects a factual error with
   a later ADR and leaves the earlier one live; the later record restates the
   decision, rows included. The checker read the two as two live ADRs closing one
   row and warned that a supersession had never been written down. None was owed.

Each is the checker asking for a record the standard does not ask for.

## Forces

- **The checker exists to say true things about the record** (ADR 0067). A warning
  a correct record cannot clear teaches people to stop reading warnings.
- **Prose that gets parsed starts being written for the parser** (Build DNA §8,
  *the index is hand-maintained*). People write runs of numbers as ranges; the
  parser should read what they wrote.
- **An item closed by nothing lapsed rather than closed** (Build DNA §8), and the
  register is where that difference is supposed to be visible. Visible means
  written somewhere a check can see it.
- **A correction keeps both records live by design** (Build DNA 8.4).

## Decision

1. **Ranges count under *Unused numbers*.** `0001 to 0008`, `0001 through 0008`,
   `0001–0008`, `0001-0008` and `0001..0008` each cover every number between their
   ends, alongside any number listed on its own. Both ends must be four digits, so a
   date or a count in the same sentence is not read as a range.
2. **A closed item may record a lapse.** `lapsed` is a new optional item field: one
   sentence saying why the item closed with no ADR and no answering document. A
   closed item needs `closed_by`, `answered_by` or `lapsed`. `lapsed` is a violation
   when it is empty, when the item is still open, and beside a `closed_by`: an item
   closed or it lapsed, not both. `templates/open-items.json` describes the field.
3. **A correction and the record it corrects may close the same rows** without a
   warning. Two live ADRs on one row still warn when neither names the other in
   `corrects` or `corrected_by`.

## Consequences

- A project that listed every number to quiet the first warning can go back to the
  range, or leave the list; both pass.
- `lapsed` gives a project a legitimate way to close an item with no ADR. That is a
  door a project could use to close the hard items quietly. The field is visible in
  the index and in review, which is the same protection `answered_by` has, and no
  more.
- `tools/validate.py` still requires the standard's own closed items to name an ADR
  and a version. The standard holds itself to the stricter rule, as it did before.
- The template change reaches existing projects through `upgrade-starters.sh` as an
  offered change to `decisions/open-items.json`, the way every starter change does
  (ADR 0046).

Ships in v3.1.1, a patch: no gate check, verdict, input contract, profile cell or
spine row moves.
