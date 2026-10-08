---
adr: "0048"
title: Keep the field-note queue visible — owner, age, evidence, and a target the project chooses
status: Accepted
date: 2026-10-08
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: An adopter reports a quarter of field-note numbers from this tool, or reports
  that recording the disposition in the header cost more than the prose block did.
  The first is the evidence Build DNA items 6 and 8 wait on; the second says the
  structure is in the wrong place.
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

Build DNA's Practitioner role promises every field note a disposition — an ADR, a test,
a constraint, or "already handled" with where — and promises its author is told which.
It calls that the obligation most likely to lapse quietly. ADR 0028 admitted the
practitioner. Nothing since has shown whether the promise is being kept.

A note's state lived in a `status` field and a prose Disposition block. Nothing read
either. No queue, no age, no owner, no record of what happens next. "Told the author:
yes" was a claim with nothing behind it. A reopened note had no way to say so. Build DNA
item 6's candidate check — *no note sits undisposed past an age this project chose* —
had no instrument. Item 8's disposition load had no numbers. Issue #16 asks for a
lightweight queue that starts advisory and measures before choosing any threshold.

## Forces

- **The obligation is the maintainer's, and the evidence must be too.** A disposition
  recorded by the person who owes it is only worth what it points at. "Told" needs a
  link to the telling.
- **The threshold is not the standard's to pick.** Item 6 says an age chosen before
  anyone has run the process is a number invented to have one. The project chooses it,
  and none is not a failure.
- **A note is an input, not an entry** (Build DNA item 6). A queue of notes must not
  become a second numbering of the open-items index.
- **Existing notes are in the prose format.** A reader that ignored them would report a
  project's real dispositions as missing.
- **Reassignment and reopening are ordinary.** Neither should reset the clock nobody is
  meant to game, and a reopening must not hide behind a closed status.

## Decision

**The template's header carries the reviewer's half,** below a marked line the author
never fills:

- `owner`, `next_action`
- `disposition` (`outcome`: adr, test, constraint or already-handled; `landed_at`; `date`)
- `author_told` (`date`, `evidence`: a link to the comment, message or meeting note)
- `effort_minutes`
- `reopened` (a list of dates)
- an optional `source` for notes that arrived as issues

The prose Disposition section keeps what the author should read.

**`tools/field-notes.sh`** is vendored and digest-covered. It is read-only and offline,
needs python3, and exits 0. It reads every `domain/field-notes/*.md`.

- **The queue.** Notes with status new or in-review, oldest first, with age (from the
  note's date, or the latest `reopened` date), owner or *unassigned*, next action and
  source.
- **The problems.** It reports:
  - a disposed note with no recognised outcome, no `landed_at`, or no date
  - an author not recorded as told
  - an author recorded as told with no evidence
  - a note reopened after its disposition and still marked promoted or closed
  - an unreadable header, a missing date, or an unknown status
- **The numbers.** Open, overdue, unassigned, disposed, median days from note to
  disposition, authors told with evidence, and reviewer minutes with how many notes
  recorded them.

`--json` emits `causeway-field-notes-v1`.

**Overdue** is measured against `respond_within_days` in `.causeway/field-notes.json`, or
`--target-days`. With neither, nothing is overdue, and the report says ages only.
Reassigning a note changes its owner and not its age.

**Older notes** are read from their prose `Reviewed by / Date / Outcome / Landed at /
Told the author` bullets. "Told: yes" without evidence is still flagged, because it
always was a claim without evidence.

**`doctor.sh`** gains `feedback.field_notes`:
- `ok` when there are no notes, or when a target is chosen and nothing is late or
  unevidenced
- `incomplete` when notes exist with no target, or any are late or carry a problem
- `unverified` when the tool or python3 is missing

**Nothing writes to `decisions/open-items.json`.** A note earns a row there only when the
ADR that read it leaves something open, as the field-note skill already says.

The field-note skill, the field-notes README and ADOPTING.md say how to record a
disposition, a reassignment and a reopening, and where the trial's numbers come from.
The open-items notes for Build DNA items 6 and 8 name this instrument. Both items stay
open.

## Alternatives considered

- **A queue in the open-items index.** Rejected in Build DNA item 6 itself: a register of
  every note is a second numbering of the note directory.
- **Issues as the queue.** The issue form already exists, and a project on GitHub can
  use labels. Not every project's notes arrive as issues, and the standard is offline by
  construction. The header works wherever the file is; `source` links the issue when
  there is one.
- **A default target, such as fourteen days.** That is the invented threshold item 6
  warns against. The README and the doctor remedy suggest a number to start from; the
  project writes it down or does not.
- **Make overdue notes fail the gate.** Not before a warn cycle with real numbers, and
  this tool is how those numbers get collected.
- **Keep the disposition only in prose.** Readable, and uncountable — which is how the
  obligation went unmeasured until now.

## Consequences

A maintainer can see, in one command, which practitioners are waiting and for how long,
and which answers were given without the evidence that they were given. An adopter can
report item 8's numbers by running it at the start and end of a quarter.

The template's header is longer, and the reviewer fills more fields. The author fills
the same ones as before. The marked line says where the author stops.

The header reader is a small YAML subset — scalars, inline and block lists, one level of
nesting — enough for the template. A note edited into deeper YAML is reported as
unreadable, not misread.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-field-notes.sh`: 26 passed, with today pinned. It covers:
  - an empty register; read-only
  - oldest-first ordering; age and unassigned; owner and next action
  - no target, a project target, and an override
  - reassignment that keeps the clock
  - a fully evidenced disposition and its counts (10 days, told with evidence, 45 minutes)
  - already-handled without a place
  - told without evidence; not told; an unknown outcome
  - a reopened note aged from its reopening, and one still marked closed
  - an older prose note read and still flagged
  - an unreadable header and an unknown status
  - the human report
  - doctor's four outcomes
  - nothing written to the open-items index
- `test-doctor.sh` still passes: the fresh-sync and configured-project cases have no
  notes, and report `feedback.field_notes` ok.
