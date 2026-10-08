---
adr: "0049"
title: Find the decisions a changed constraint touches — from the references already recorded, and say how sure
status: Accepted
date: 2026-10-08
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: An adopter reports a decision this missed that the references should have
  found, or asks for more than a list — notification, a scheduled check, a required
  review. The first is a bug. The second is the "further machinery" issue #17 says
  should wait for adopter evidence, and it needs its own ADR.
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

The Survey gives every row a permanent ID. A seed ADR copies the `DEC-` row it came from
into `survey_rows` and the rows that discriminated into `forces` (Build DNA §8, ADR 0031).
`revisit_if` states what would reopen a decision. Between them, the record already says
which decisions rest on which constraints.

Nothing reads it in that direction. When a `GR-` row changes — a deployment environment
is newly permitted, a data-release restriction tightens — someone has to search
`decisions/` by hand for the ADRs justified by the old condition. They find the ones
that mention it, and they miss the ones that only reach it through the Survey. That is
the S1 supersession the cause codes exist to record: outside information changed. It
only gets recorded if somebody finds the decision first.

Issue #17 asks for a review list built from explicit relationships first. Human judgment
stays over whether a decision changes. Evidenced and inferred links stay apart. Legacy,
superseded and corrected records are handled, and a worked example shows one constraint
reaching several decisions while an unrelated one stays out.

## Forces

- **The references exist.** No new field is needed: `forces`, `survey_rows`, and the
  Survey's Forces, Binds, Depends on and ADR columns already carry them. A tool that
  required more would be asking every project to re-annotate its record.
- **A link has a strength.** A force cited in frontmatter is evidence. A row reached
  through a dependency is evidence one step removed. An ID mentioned in prose is a
  hint. A list that flattened them would be trusted equally and wrong unequally.
- **The decision is a person's.** A tool that superseded, or even marked, an ADR would
  be deciding that the decision changed. It may only say what to read.
- **Most of today's record has no structured references.** ADRs written before §8
  required `forces` carry none. The tool must say how much it cannot see, not imply
  completeness.
- **A broken reference is a decision nobody can find.** Finding them is cheap, and it
  belongs beside the impact report.

## Decision

**`tools/impact.sh`** is vendored and digest-covered, read-only, offline, advisory, and
needs python3. Given one or more IDs, it reads `decisions/NNNN-*.md` frontmatter and
text, and the Survey. The Survey is found at `survey.md`, `SURVEY.md`, `docs/survey.md`
or `decisions/survey.md`, or named with `--survey`. For each ID it reports every ADR it
reaches, at one of three levels:

| Level | The link |
|---|---|
| **direct** | the ADR cites the ID in `forces`; or came from a `DEC-` row whose Forces column cites it; or came from a `DEC-` row the ID's own Binds column names |
| **indirect** | the ADR came from a `DEC-` row whose Depends on names an affected `DEC-` row, followed transitively |
| **inferred** | the ADR mentions the ID in its body and cites it nowhere structured — uncertain, labelled so |

"Came from" means the ADR lists the `DEC-` row in `survey_rows`, or the row's ADR column
names it. An ADR reached several ways is reported at its strongest level, with every
reason listed.

For each ADR it shows status and `revisit_if`. A Superseded or Deprecated ADR is
followed through `superseded_by` to the record now in force. An ADR with `corrected_by`
is named with its corrections, to be read together. It also lists the `DEC-` rows the
change reaches.

**`--check`** reports references that point nowhere:
- a `forces` or `survey_rows` entry the Survey does not have
- a `DEC-` row naming an ADR not on disk
- a Binds entry naming a `DEC-` row that does not exist
- a `superseded_by` or `corrected_by` naming an ADR not on disk

It also counts accepted ADRs with neither `forces` nor `survey_rows`: the part of the
record the tool cannot see.

**It changes nothing.** The Survey skill's Step 5 says what to do with the list: read each
ADR against the new constraint, and supersede what no longer holds with a new ADR, coded
S1, citing the same row. The ADR template's `revisit_if` comment says the tool shows it.

**The worked example** is `tools/test-impact.sh`, run in CI and the release gate.
GR-1 ("deploy only inside the on-prem enclave") reaches:
- 0001 directly, by `forces`
- 0002 directly, through DEC-2, which GR-1 binds, though 0002 cites only IV-1
- 0004 indirectly, through DEC-4's dependency on DEC-1
- 0005 by inference, from prose
- 0006, which points on to 0007, the record in force

GR-2 reaches 0003 alone.

## Alternatives considered

- **A dependency graph file maintained beside the ADRs.** It would be precise, and it
  would be a second record of what `forces` and the Survey already say. It would drift
  from them the first week nobody updated it.
- **Text search only.** It finds 0005 and misses 0002 and 0004. Those are the links the
  Survey makes and the prose does not, which is the reason the Survey exists.
- **Mark affected ADRs** — a field, a label, a status. That writes a judgment into an
  immutable record before anyone has made it.
- **Notify, or block, when a `GR-` row changes.** Further machinery, which the issue says
  adopter feedback should earn. The revisit trigger is where that request lands.

## Consequences

A project with a Survey and `forces` gets, in one command, the list of decisions to
re-read when a constraint moves, each with its reason and its revisit condition. A project
without a Survey still gets the `forces` and prose links, and is told the rest is absent.

This repository's own record has no Survey and no `forces`. Its first 48 ADRs predate the
field, and this one has no Survey rows to cite. `tools/impact.sh --check .` here reports 49
accepted ADRs it cannot see. That
is the honest result, and it is what any project adopting the standard after its own
history began should expect to see.

Build DNA item 10 (intake is unenforced) is unchanged. This reads the intake's references;
it does not check that they were made.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-impact.sh`: 23 passed, on the worked example. It covers:
  - read-only, and the documented format
  - each level for each kind of link; the unrelated decision left out
  - `revisit_if` shown; a superseded ADR followed to the record in force; a correction
    named; every relationship giving its reason
  - the unrelated constraint reaching only its own decision; several IDs at once; the
    human report
  - the unlinked count
  - four kinds of broken reference
  - no Survey; `--survey`; the usage error
- `tools/impact.sh --check .` on this repository: no broken references, 49 accepted ADRs
  with no structured reference.
