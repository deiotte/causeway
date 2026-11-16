---
adr: "0057"
title: List the threats before choosing what not to defend — the Survey gains S3.4 and the TH- prefix
status: Accepted
date: 2026-11-16
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Two Surveys at G2 or above finish S3.4 with every row disposed `designed`
  and none `not defended` or `open` — that is a list written to look finished, and the
  prompts are not producing honest rows. Also revisit if teams report the prompts need
  a security specialist to answer; the section was written so that they do not.
approver:
  name: Karl
  role: Human
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Survey S3.3 asks a G2 system to state what it is deliberately *not* defending
against, and the template says why: an assessor will ask, and the difference between
a threat considered and dismissed and one nobody raised is what they are asking about.

Nothing in the Survey produces the threats to consider. S3.3 is a choice made from a
list, and the list does not exist anywhere in the instrument. In practice it is
whatever the people in the room thought of, which is the "nobody raised it" case S3.3
was written to rule out. The rest of the Survey does not have this gap: S3.2 makes
every failure mode end in a designed response, S4 makes every decision end in a
verdict, and S1 makes every constraint end in a source. Threats were the one
consequential category with nowhere to land.

The spine already holds most of the answers a threat would point to: identity
(SA-5.1), authorization (SA-5.2), workload identity (SA-5.3), transit and at-rest
encryption (SA-5.6, SA-5.7), supply chain (SA-5.8, SA-5.14), the inference boundary
(SA-5.15, SA-5.16), audit (SA-2.10) and telemetry classification (SA-6.8). What it
does not hold is the step that asks, boundary by boundary, which of those an attacker
would actually reach for here.

## Forces

- **The Survey already finds the boundaries.** S2.3 lists every interface with a
  direction, and S2.2 walks every hop. A threat list built from those rows is cheap,
  because the hard part — finding where data crosses from something you do not
  control — is already done.
- **The person filling in the Survey is usually not a security specialist.** A
  threat-modeling method that needs one will be skipped, or done by someone else
  after the design is fixed. The prompts have to be plain questions.
- **A threat without a disposition is noise.** The Survey's habit is that every row
  ends somewhere: a designed response, a verdict, an owner. A threat list that is
  only a list adds reading and changes nothing.
- **The coding agent reads the Do-NOT list.** S3.2's `Never do` column already turns
  the tempting wrong fix into a rule in `CLAUDE.md`. The tempting security shortcut
  is the same kind of fact and belongs in the same place.

## Decision

**The Survey gains S3.4, Threats, and a permanent `TH-` prefix.**

- **One row per threat**, worked from each inbound S2.3 interface and each
  walkthrough hop where data arrives from outside: the boundary or asset, who would
  try it, what they would try, a disposition, the row that answers it, and a
  `Never do` column.
- **Every row has exactly one disposition.** `designed` names the `IV-`, `FM-`, or
  `DEC-` row that answers it. `not defended` puts the row in S3.3 with a reason and
  the name of whoever accepted it. `open` makes it an `OPEN-` row, and nothing that
  rests on it is READY.
- **Eight plain prompts**, in STRIDE order with two additions: pretend to be someone
  else, change something, deny it, see something, stop it working, get more power,
  talk the model into it (only where there is an inference path), and already inside
  (including the coding agent). Each names the spine rows it usually lands on.
- **S3.3 gains a table** so `not defended` rows have a fixed place, with an
  *Accepted by* column.
- **Depth follows S3.3.** None at G0. At G1, the inbound interfaces only. At G2 and
  above, every prompt at every inbound boundary.
- **The handoff package carries it.** `SECURITY.md` derives from S3.4's trust
  boundaries as well as S3.3; the Do-NOT list from both `Never do` columns; and each
  `designed` row should become an abuse-case test that tries the threat and fails.
- **Two exit criteria**: S3.4 coverage to profile depth, and every `TH-` row disposed,
  with every `not defended` row listed in S3.3.

S3.4 closes no spine row and is not a gate input, for the reason that applies to the
rest of the Survey: it is written before the repository exists.

## Alternatives considered

**Adopt a named method whole** — STRIDE per element, PASTA, attack trees, LINDDUN.
Rejected. Each is a practice with its own diagrams and vocabulary, and each assumes a
facilitator who knows it. The Survey borrows STRIDE's categories as prompts because
they are a complete-enough checklist that a non-specialist can ask, and stops there.
A team that runs a full method can still record its output as `TH-` rows.

**Add a spine row: "Is there a threat model of record?"** Rejected for now. It would
make threat modeling a gate fact, which is attractive, but a row that closes with
"yes, there is a document" says nothing about whether the document was any good, and
the spine already holds the rows the threats point to. If the revisit condition shows
S3.4 being filled in as theater, a gate-visible record may be what is missing, and
that is the point to reconsider.

**Fold threats into S3.2 failure modes.** Rejected. A failure mode is something that
happens to the system; a threat is something someone does to it, on purpose, and
keeps doing after the first fix. The prompts that find one do not find the other, and
mixing them hides which kind of row is missing.

**Do nothing.** S3.3 keeps asking for a choice from a list nobody wrote, and the
statement an assessor reads keeps describing only the attacks the team happened to
think of. That is the state this ADR found.

## Consequences

**Easier.** S3.3 now has something to choose from, and its answer can be checked
against the list. A reviewer can ask "which boundary has no `TH-` rows?" and get an
answer from the document. The coding agent inherits the tempting security shortcuts as
rules instead of rediscovering them. `tools/impact.sh` already reads any
`[A-Z]{2,5}-n` ID, so `bash tools/impact.sh TH-3` works from day one, with no change.

**Harder.** A G1 Survey owes one more section and a G2 Survey owes a real one. The
`not defended` rows each need a name beside them, which is the uncomfortable part and
the reason for the column.

**Declared gaps.**

- **Nothing checks S3.4.** No validator reads a Survey and no gate check could; the
  Survey predates the repository.
- **The prompts are a floor, not a method.** They find the common classes. They do not
  find a business-logic abuse that only someone who knows the domain would think of,
  which is why *Who* asks for a motive and not a category.
- **No evidence yet.** No Survey has run S3.4. Build DNA open items 4 and 8 wait on the
  same thing: a team that did not write the standard, using it.

**Committed to.** `TH-` is a permanent prefix, under the Survey's rule that IDs are
never renumbered.

## Revisit if

S3.4 comes back with every row `designed` and nothing `not defended` or `open`, or
teams report that answering the prompts needed a security specialist. The first means
the section is being filled in to pass; the second means the prompts are not plain
enough. The frontmatter states both.

## Evidence

- `templates/survey.md`: `TH-` in the prefix table; S3.4 in the Depth table and its
  paragraph; the new S3.4 section with its table, dispositions and eight prompts; the
  S3.3 table; the `SECURITY.md`, Do-NOT list and fixtures rows of the derivation map;
  two exit criteria.
- `skills/survey/SKILL.md`: the S3 Bearings guidance for S3.4, and the depth example.
