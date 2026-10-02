---
adr: "0032"
title: Say how a system gets placed, and ship no check to enforce it
status: Accepted
date: 2026-09-19
spine_rows: []         # governs SA-1.1 and SA-1.14; closes neither, for this repository or any other
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: One portfolio has run the procedure end to end and the receipts show how
  many placements are declarations and how many are the C1 default — at which point
  gate configuration open item 13 can be priced and `placement-argued` decided either
  way.
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Two values drive everything Causeway does to a system. `tier` and
`criticality_class` resolve the gate profile, and the class alone decides whether
23, 89 or 94 spine rows are owed. Every other number in the standard is derived
from those two.

The standard defines neither.

The class had three one-line meanings — *mission failure or a reportable event* ·
*degrades work, survivable for hours* · *an annoyance* — sitting inside a
paragraph in `reference/spine.md` that explains how to read a table column. They
are accurate and they are index entries: nothing in them tells a team which one
it is, and two of the three turn on words ("reportable", "survivable") that are
exactly the words an argument would be about.

Tier had nothing at all. Build DNA §1 says tier placement is a catalog fact and
not a self-assessment, which settles *who decides* and says nothing about *what
they decide on*. `reference/gate-profiles.md` and `gate/gate-configuration.md` §3
both consume tier; neither says what makes a system Core rather than Mission.

Both documents that read the values open the same way. Build DNA §9's first step
is *read `system.json` for `tier` and `criticality_class`* — correct for a system
that has been placed, and no help to one being built, which is the only moment
the answer is actually set. The Decision Spine skill's step 2 does the same, then
routes to "ask the user," which relocates the question rather than answering it.
The `survey` skill is the one place in the standard that gets a proposal onto the
table, with two triage questions about blast radius and reversibility, and it is
reachable only by invoking that skill.

So the default did the work. A missing class resolves to C1 — the right default,
and the loudest thing in the configuration — and a system reaches it by nobody's
decision. Three separate properties of that outcome are bad and only one is
visible: the team gets the strictest gate in the standard, it learns what that
costs without learning what it is for, and **nothing anywhere can tell a C1 that
a sponsor declared from a C1 that nobody declared**. The gate resolves the
profile from two values and never reads `criticality_authority`.

A consuming project is the existing counterexample and is where this was noticed. Its
`system.json` carries `$tier` and `$criticality` — prose siblings the gate does
not read — arguing Core on inheritance and C1 on silent failure, and its
`CLAUDE.md` carries the same under a *Causeway placement* heading taken from
`templates/project-CLAUDE.md`. That is the practice this ADR promotes. It was
invented in a consuming repository because the standard had nowhere to put it.

## Forces

- **Two values, three consumers, zero definitions.** `gate/profiles.json`,
  `reference/gate-profiles.md` and the Spine's `Applies` column all resolve
  against a placement; no document produces one. A value every check depends on
  and no document defines is the shape `bundle/scope.json` exists to catch, one
  layer up.
- **The loud default is spent silently.** C1-on-missing is correct and cannot be
  counted. An organization cannot answer *how much of our portfolio is running on
  the default* from anything the standard emits.
- **The one existing procedure is behind a skill invocation.** The Survey's two
  triage questions are good and reach only the sessions that load the Survey. A
  routing step that lives only in a tool does not happen when the tool is not
  loaded — Build DNA §9 says this about itself and it applies here unchanged.
- **The practice already exists and is unwritten.** That project argues both axes in
  prose siblings nothing reads. A convention invented once per repository is a
  convention that drifts per repository.

## Decision

Ship `skills/decision-spine/reference/placement.md`: four questions about what a
failure costs, five facts that set C1 on their own, the inheritance test that
separates Core from Mission, the six-step procedure that ends in a declaration,
what the declaration has to contain in `system.json` and in the ADR closing
SA-1.1 and SA-1.14, the rules for reclassifying, worked examples, and the
anti-patterns. Bundle it and vendor it, because the gate reads the values it
produces.

Route to it from every document that reads a placement: Build DNA §1 and §9, the
Decision Spine skill's step 2 and file table, `reference/gate-profiles.md`,
`reference/spine.md`'s `Applies` paragraph, `gate/gate-configuration.md` §3,
`templates/project-CLAUDE.md`, `templates/survey.md` and the Survey skill's step
1. The Survey keeps its two triage questions and now cites the file as their
source; `placement.md` quotes them and marks them a route to a *proposal*, never
to a declaration. One definition, one copy, several doors.

**Ship no check.** `placement-argued` — `criticality_authority` carries a real
name and date, and the ADR closing SA-1.1 exists — is registered as gate
configuration open item 13 and is not implemented.

Two things ride along, both in text this change was already rewriting.
`templates/project-CLAUDE.md` gains a *why* line under each axis, promoting
that project's practice into the template every project starts from. And
`reference/spine.md`'s "22-row short form" is corrected to 23: the `Applies`
column has said 23 since SA-5.16 joined the form at Spine v0.6, as do the
short-form section four hundred lines below it, the skill's scope table,
`gate/checks.json` and the ServiceNow overlay. One sentence was stale and every
other statement of the number was right, so nothing ever disagreed loudly enough
for a reader to catch it. `tools/validate.py` §16 now anchors the count in both
documents that state it in digits.

## Alternatives considered

**Define the classes in `reference/spine.md` and stop.** The table is already
there and expanding it in place is the smallest diff. Rejected on audience: the
spine is loaded *after* scoping, by the skill's own instruction, and scoping is
the step that needs the definition. It would also have left tier undefined,
since the spine has no natural home for a catalog fact.

**Put it in Build DNA.** It is the file every project imports, so reach is best
there. Rejected on the §8 seam: Build DNA is the process layer and the two axes
are design-layer rows. Build DNA already routes both questions to SA-1.1 and
SA-1.14, and moving the answer up would put the design layer's content in the
process layer's file — the seam failure §9 warns about, committed by the document
that warns about it. Build DNA gets the routing step and nothing else.

**Name it `classification.md`.** Rejected on a live collision: *classification*
in this standard means data classification, SA-1.8, a named-approver row that
blocks at every profile including G0. *Placement* is already the word — Build DNA
§1 says "tier placement", `templates/project-CLAUDE.md` heads the block "Causeway
placement", and that project's `CLAUDE.md` uses it for exactly these two axes. Settling
this before shipping rather than after is the practice ADR 0031 established.

**Ship the check with the document.** Rejected twice over. Gate configuration §9
requires a warn cycle before blocking behavior engages, and a warn cycle needs
something to measure; the measurement is the declared-versus-defaulted
distribution, which does not exist because no portfolio has run the procedure.
And `criticality_authority` is present in `system.json` today with no check
reading it, so a `placement-argued` that blocked on arrival would fail every
adopter on a field the standard has never asked anyone to fill in. The candidate
check is named and registered instead, which is what ADR 0031 did with
`survey-present` for the same reason.

**Write the tier test as a negotiation.** Rejected as the failure mode the file
most has to avoid. Tier authority stays with catalog placement; what ships is the
test the catalog applies, so a team can predict a placement and propose one. The
escalators only escalate, there is deliberately no de-escalator list, and every
*what is not an argument* bullet in the document routes a cost objection back to
the gate discussion it belongs in.

## Consequences

**Easier.** A team scoping a build has a procedure and can price its gate before
it writes code rather than at a gate run. An agent that reads `system.json` and
finds nothing now knows that is a different job and where the job is written
down. Reclassification has rules, so *we're lower risk now* is a claim somebody
has to make to a named authority against four questions rather than a value
quietly edited in a file.

**Harder.** One more bundled file to keep current, and one more document that can
drift from the spine's `Applies` column — mitigated by the count anchors added
here and by the file citing the column as authoritative rather than restating it.
Build DNA moves to 1.13, which forces a ServiceNow overlay re-ratification; the
overlay moves to 1.10, re-read with no disposition moved, and adds one row of its
own — on that platform the class tracks the table an application writes to, not
the interface it presents.

**Committed to.** The declaration is now a described artifact, which makes its
absence describable, which is what open item 13 will eventually price. And to the
word *placement* for both axes together, in every document that discusses them.

## Revisit if

One portfolio has run this end to end and the receipts can separate declarations
from defaults. That is the number open item 13 is blocked on and the only
evidence that can decide `placement-argued` in either direction. Absent it, this
document stays guidance, per §9.

## Evidence

`skills/decision-spine/reference/placement.md`, bundled in
`bundle/manifest.json` and vendored by `tools/sync.sh`. Routing in `AGENTS.md` §1
and §9, `skills/decision-spine/SKILL.md` steps 2–3 and rule 5,
`skills/decision-spine/reference/gate-profiles.md`,
`skills/decision-spine/reference/spine.md`, `gate/gate-configuration.md` §3,
`skills/survey/SKILL.md` step 1, `templates/survey.md`, and
`templates/project-CLAUDE.md`. Open item 13 in `gate/gate-configuration.md` §10
and `decisions/open-items.json`. The corrected short-form count and its anchor in
`tools/validate.py`.
