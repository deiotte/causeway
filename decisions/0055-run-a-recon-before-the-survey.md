---
adr: "0055"
title: Run a Recon before the Survey — record whether to build, for the person who decides, and make the estimate show what it rests on
status: Proposed
date: 2026-11-04
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Two builds that ran a Recon report that its rows did not carry into the
  Survey (the Survey was started blank anyway, or renumbered), or that problem owners
  did not confirm the record — either means the Recon is ceremony upstream of the
  instrument it was meant to feed. Also revisit if the Recon grows past what one
  section of the Survey skill can hold; a skill of its own then earns its pointer cost.
approver:
  name:
  role: Maintainer review pending
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Causeway's intake starts at the Survey, and the Survey starts from a decision that
has already been made: Step 0 asks *"Is this getting its own repo?"* and proceeds on
a yes. Nothing in the standard records how that yes was reached.

In practice it is reached in a meeting with the person who owns the problem. That
meeting produces three things that matter downstream: the problem as the owner
states it, a go/no-go decision and the people who make it, and an estimate of labor,
schedule and cost. The first is half of Survey S0, written later and from memory. The
second has nowhere to go: every decision Causeway knows how to record is a design
decision. The third is the most load-bearing number a project produces, and it has no
record at all. It gets quoted in a budget, then a schedule, then a contract, and each
use is less careful than the one before. That is the exact failure Survey S1 warns
about for a rate or a volume, applied to the number that matters most.

The prompt was an organization's internal discovery-session template, reviewed with
the maintainer on 2026-11-04. Its method belongs to its owner and is deliberately not
reproduced here. What this ADR takes from it is a list of gaps it exposed in
Causeway, not its structure, timings or name. Compared row by row, about half the
template matched the Survey closely, often in near-identical language: hard
constraints against a "could the team vote to change it" test, prior attempts, out of
scope, owned open questions, and "push for numbers". The other half had no Causeway
equivalent: the decision the work supports, ratification of the whole record by the
problem owner, pain points with frequency and cost, outcome metrics that trace to
them, a scoped proof of concept, an estimate, and a rule for an open question that
misses its date.

## Forces

- **The Survey's reader is an engineer, and the go/no-go reader is not.** The Survey
  runs to 437 lines and is right to. A decision-maker reads two pages. One artifact
  cannot serve both, and the Survey should not be bent toward the reader it does not
  serve.
- **Rows written before the Survey are rows the Survey would otherwise re-derive.**
  Hard constraints, prior attempts and open questions surface in the first meeting.
  If they get IDs then, the Survey starts half-filled. If they don't, they get
  rewritten from memory, and a constraint rewritten from memory loses its source.
- **An estimate is a load-bearing number.** S1 already says to trace every figure
  that a second record depends on. An estimate is depended on by everything after it.
  Causeway has no business prescribing how to estimate, but it can require the
  estimate to show its inputs, and that requirement is the one that makes an
  estimate re-checkable when an input moves.
- **An overdue question needs a rule, or it becomes a guess.** The Survey records
  open questions with a trigger date and says nothing about what happens when the
  date passes. Work proceeds anyway, on an assumption nobody wrote down. The fix is to
  write it down, label it, and keep it out of the ADR register. Survey hard rule 1
  already forbids an ADR on an open dependency. This applies it earlier.
- **Ratification is already the Survey's habit, applied to one field.** Step 2 drafts
  and asks the user to correct it. The criticality class gets a one-line sign-off by
  name. The frame as a whole never does, and it is the part a problem owner is best
  placed to correct.
- **Adding a skill has a known cost.** ADR 0029 makes every shipped skill a pointer
  in four adapters, checked by `render-adapters.sh`. That cost is worth paying for an
  instrument with its own conversation. The Recon's job is mostly to feed the
  Survey, so it belongs inside that skill until it shows otherwise.

## Decision

**Causeway gains a Recon: a short, owner-facing record of whether to build, which
precedes the Survey and hands its rows to it.**

- **`templates/recon.md`** is the artifact. It has a short version, then
  R0 through R6. R0, the decision it supports and the people who make it, by name. R1, today's
  process and pain points (`PN-`) with frequency, cost and source. R2, hard
  constraints (`GR-`) with a verification state, soft constraints as `DEC-` rows,
  prior attempts, and compliance as design inputs. R3, outcomes (`OUT-`) that each
  trace to a pain point. R4, scope, a later list, and one probe (`PR-1`): one
  question, a time box, synthetic data. R5, the estimate. R6, open questions, each
  with the assumption the work proceeds on if it goes unanswered. A readout section
  records go, go with conditions, reframe or no-go, and who decided.
- **The record is proposed until the problem owner confirms it by name**, and the
  probe starts against the confirmed version. The template asks the team to write its
  own clocks for sending, confirming and reading out. It does not set them.
- **The estimate shows what it rests on.** Each line cites its rows, gives a range,
  and names its weakest input. Causeway prescribes no estimating method.
- **An overdue `OPEN-` proceeds on its stated assumption**, marked `assumed` and
  reported at the readout. An assumed answer may steer the probe. It may never become
  an ADR, never be marked verified, and never appear in the estimate unflagged.
- **Rows keep their IDs into the Survey.** `templates/survey.md` gains `PN-` and
  `OUT-` in its prefix table, a header field naming the Recon it starts from, and the
  carry-over rule: same IDs, sequences continued, assumed rows still assumed.
- **The Survey skill runs it.** `skills/survey/SKILL.md` gains *Before Step 0 —
  Recon*, and its description, its Files table, its *Where this sits* diagram and all
  four adapters name the moment it is for. No new skill directory.
- **The template is vendored and digested** on the Survey's terms, because it mints
  IDs the Survey reads as its own.

The Recon closes no spine row and is not a gate input. Like the Survey, it produces
its artifact before the repository exists, so nothing in `gate/` can reach it.

## Alternatives considered

**Add the missing sections to Survey S0.** The smallest diff. Rejected because it
puts the decision-maker's two pages inside an engineer's 437 lines, which guarantees
the decision-maker never reads them. It also runs at the wrong time. The Survey
starts after the yes, and the go/no-go is what produces the yes.

**Ship `skills/recon/` as a separate skill.** Cleaner to name, and it may be right
later (see *Revisit if*). Rejected for now because the Recon has no conversation of
its own that the Survey's Step 2 does not already describe. A fourth adapter pointer
for a section-sized instrument is ADR 0029's cost without its benefit.

**Adopt an estimating method.** Rejected outright. How an organization estimates
belongs to that organization, the same way managed policy does. What Causeway can
say without overreaching is that the result must show its inputs, which is S1's
existing rule about load-bearing numbers.

**Adopt the reviewed template as-is.** Rejected. It belongs to its owner, and its
timings are one organization's operating rhythm, not a standard.

**Do nothing.** The go/no-go keeps happening in email, the estimate keeps arriving
without its assumptions, and the Survey keeps re-deriving the first meeting from
memory. That is the state this ADR found.

## Consequences

**Easier.** A problem owner gets a record they can confirm in one read. The Survey
starts with its S0 drafted and its first `GR-` rows sourced. An estimate that moves
can be traced to the row that moved it. A no-go leaves a one-line reason for the
next person.

**Harder.** Every probe now owes a stated question and a time box before it starts.
Every estimate owes its inputs. Teams used to a single number will find a range
uncomfortable, and that discomfort is the point.

**Declared gaps.**

- **Nothing checks a Recon.** No validator reads it and no gate check could, for the
  reason that applies to the Survey: it predates the repository.
- **`tools/impact.sh` does not read the Recon.** It follows ADR frontmatter and the
  Survey. An estimate line resting on a constraint that changes is found by searching
  the Recon for the ID. Extending the tool is possible and is not done here, because
  nobody has run a Recon yet and the tool should follow evidence, not anticipate it.
- **One source of evidence.** The gaps this ADR closes were found by comparing
  Causeway against one organization's template. That is enough to name the gaps and
  not enough to know whether this shape closes them. Build DNA open items 4 and 8
  wait on the same kind of evidence: a team that did not write the standard, using it.

**Committed to.** `PN-` and `OUT-` are permanent prefixes, under the Survey's rule
that IDs are never renumbered.

## Revisit if

Builds that ran a Recon started their Survey blank or renumbered its rows. Problem
owners did not confirm the record. Or the Recon section outgrows the Survey skill.
The first two mean the Recon is not feeding anything. The third means it has earned
its own skill. The frontmatter states all three.

## Evidence

- `templates/recon.md`, with the header table, R0–R6, readout and amendment log.
- `templates/survey.md`: `PN-` and `OUT-` in the prefix table, the *Starting from a
  Recon* paragraph, the `Recon` header field, and the S0.1 and S0.2 pointers.
- `skills/survey/SKILL.md`: description, *Before Step 0 — Recon*, the Step 0 handoff
  line, the Files row, and the *Where this sits* diagram.
- `adapters/CLAUDE.md`, `adapters/GEMINI.md`, `adapters/copilot-instructions.md`,
  `adapters/.cursor/rules/causeway.mdc`: each names the Recon moment.
- `tools/sync.sh` and `tools/build-bundle.sh` vendor and digest `templates/recon.md`.
  `bundle/manifest.json` is regenerated.
