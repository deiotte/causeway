---
adr: "0041"
title: Seed the decision register with its own README, and index this repository's by family
status: Accepted
date: 2026-10-07
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A consuming project reports that the hand-maintained index fell behind its
  ADRs with nothing noticing, or a reader reports that the short form made §8 look
  optional. Either is evidence about whether a README is the right instrument, which
  is the question this ADR answered on none.
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

`decisions/` is the one directory the standard tells every role about, and the one
directory that does not explain itself. Build DNA §8 states the rules — numbered,
immutable, superseded rather than edited, corrected by a later record, waived with an
expiry, indexed in `open-items.json` — and states them deep in a document the Reader
floor says a reader owes nothing to beyond the project's `CLAUDE.md`. The ADR template
carries a one-line comment on each frontmatter field. Nothing in the directory a
contributor actually opens says what the numbers mean, why the body of an accepted
record is never edited, what to do with a number that was skipped, or where to start
reading.

`sync.sh` creates the directory and seeds `open-items.json` into it. That is the whole
seeding. A consuming project starts with an index of open items and no explanation of
the records the items point at.

The same gap had already been closed once, for a different register.
`domain/field-notes/` is seeded with `templates/field-notes-README.md`, and `sync.sh`
says why: *a directory that explains itself tells the first practitioner they were
expected.* ADR 0028 decided that for the people the standard admits last. The register
the standard admits first never got the same treatment.

The gap surfaced the way these do. A consuming project wrote the file itself, by hand,
in the middle of other work: it explained numbering, immutability, a number that had
been skipped, and indexed that project's ADRs by family. None of it was wrong, and none
of it was the project's to invent. A README four projects write four ways is a rule the
standard stated and did not ship.

This repository's own `decisions/` holds every ADR since 0001 and no index. The
top-level README names the directory in one table cell.

## Forces

- **The rules exist and are far from the files they govern.** §8 is correct and
  complete; what fails is distance. A contributor copying a template into
  `decisions/` is not reading `AGENTS.md`, and the Contributor floor does not ask them
  to.
- **A skipped number is legitimate and looks like a mistake.** Nothing in §8 says what
  to do about one, so a project either closes the gap — renumbering, which the
  open-items rule forbids outright and §8 forbids by implication — or leaves a hole the
  next reader goes looking for a file to fill.
- **A family index is a judgment, not a derivation.** Which ADRs are about distribution
  and which about governance is in no frontmatter field, so the index cannot be
  generated. A hand-maintained index goes stale unless something counts it, and §8 has
  already said what happens then.
- **The precedent already exists.** `field-notes-README.md` is seeded on terms this
  repository has argued through twice, in ADRs 0028 and 0035: written once if absent,
  never overwritten, declared ungoverned, carried in the archive. Different terms for a
  second README would be a second decision for no reason.
- **This repository's record is not a consumer's.** The archive deliberately carries no
  `decisions/`, and `validate.py` fails if it does. Whatever ships has to be a template,
  and whatever this repository writes for itself stays here.

## Decision

**`sync.sh` seeds `decisions/README.md` from `templates/decisions-README.md`, on the
terms it seeds every other project-owned file, and this repository writes its own,
indexing every one of its ADRs by family.**

The template carries the short form of §8 — how to write one, numbering, what
immutability permits and forbids, how to read the frontmatter, what an ADR leaves
behind — and ends in two sections only the project can fill: an index by family, and
a list of unused numbers with the reason each was skipped. Nothing in it restates a rule
at length; every section points at §8 for the argument.

Three things are checked, all in `tools/validate.py` and all about this repository's
own copy:

- every ADR in `decisions/` is linked from `decisions/README.md`;
- every ADR link in the README resolves to a file;
- every number between `0001` and the highest in use is either a file or named in the
  README.

The third is the *unused numbers* promise made checkable. There are no gaps today, so it
passes on nothing — which §16 of the validator would call a number not yet tested, and
is said here so nobody mistakes green for verified.

The template is declared ungoverned in `bundle/scope.json` and listed in
`ARCHIVE_FILES`, for the reasons `field-notes-README.md` is. The bundle digest does not
move for it; it moves for `VERSION`.

## Alternatives considered

**Leave it to §8.** The status quo. Rejected on the evidence that opened this: a project
wrote the file anyway, which means the question was being asked, and answering it four
different ways is worse than once.

**Generate the index from frontmatter.** Rejected. Number, title and status derive;
family does not, and family is the part worth having. §8 states the general case for
the open-items index — *prose that gets parsed starts being written for the parser* —
and a generated index would also have nowhere to put a skipped number's reason. What is
checked instead is completeness, which is the one property of a hand-maintained index a
machine can read.

**Put the explanation in `templates/adr-template.md`.** Rejected. The template is copied
into every new ADR; forty copies of the numbering rules is forty places for them to
drift, and a reader opening the directory still sees no index.

**Ship it as a vendored, digested file.** Rejected. The index is the project's content
by construction, and pinning it would make every project's own rows read as drift — the
same reason `open-items.json` is seeded rather than vendored.

**Check the index in consuming projects too.** Declined, not rejected. The validator
does not ship, and promoting a check into the gate on its first release is the decision
Build DNA open item 6 declines to make for the open-items index. This is the same gap in
the same shape, and it is recorded against item 6 rather than opened as a new item: a
second number for one question is how a register comes to disagree with itself.

## Consequences

A fresh sync produces a `decisions/` that explains itself. A project that already has a
README there keeps it; `sync.sh` never overwrites.

This repository's ADRs are reachable from one page, grouped by what they are about. The
grouping is a judgment and will be argued with; the rows are checked and will not go
missing.

The validator gains three checks, so the count the README states moves.
`tools/build-archive.sh` ships one more file. `standard.yml` asserts the seed in the
scratch-project step, beside the two ADR 0035 added. The contributor front door and the
pull request template now say an ADR lands in the same pull request as its index row.

Nothing a consuming project owes changes. The release is minor for that reason.

## Revisit if

See the frontmatter. The honest trigger is a report from a project that did not author
the standard — the same evidence Build DNA open items 4, 6 and 8 are waiting on.

## Evidence

- `tools/sync.sh` into an empty directory creates `decisions/README.md`; a second run
  reports it left alone.
- `tools/validate.py` passes with the three new checks, and fails when an ADR is
  removed from the index or a link in it is broken.
- `tools/build-archive.sh` lists `templates/decisions-README.md`, and §19 of the
  validator fails if a path `sync.sh` reads is missing from that list.
- The `standard.yml` step that installs from an extracted archive with no git on
  `PATH` seeds the same file, because the archive carries the template.
