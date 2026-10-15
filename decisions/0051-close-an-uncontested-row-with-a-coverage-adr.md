---
adr: "0051"
title: Close an uncontested spine row with a coverage ADR — the verdict is about the argument, the row still closes
status: Accepted
date: 2026-10-15
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A surveyed build's register shows coverage ADRs carrying alternatives
  sections or several forces — the record is being used to smuggle argued decisions
  past readiness — or an adopter's gate fails a register because a coverage ADR was
  read as something other than an ADR. The first is a Survey defect to name; the
  second is a conformance question for the evaluator.
approver:
  name: Karl Deiotte
  role: Maintainer
supersedes:
superseded_by:
supersession_cause:
corrects: ["0031"]
corrected_by: []
---

## Context

Three places in the standard state a rule about an uncontested default, and read
together they contradict:

- `templates/survey.md` §S4.1 gives the verdict `NOT-A-DECISION` the instruction
  **No ADR.** ADR 0031 restated it as a consequence: "`NOT-A-DECISION` rows never
  become ADRs."
- `skills/decision-spine/SKILL.md` hard rule 1 says a decision without an ADR is
  not closed, and `shortform-closure`, `oneway-closure` and `class-scoped-closure`
  in `gate/checks.json` verify that every applicable row has an accepted ADR. None
  of the three has a notion of a row that is applicable and exempt.
- The ServiceNow overlay requires an ADR for every inherited row and says, in its
  evidence map, that a register which skipped its `I` rows fails there.

A team following the Survey marks the execution fabric `NOT-A-DECISION` because the
organization has one, writes no ADR as told, and fails `shortform-closure` on SA-4.1
at its first gate. A team following the spine writes an argued ADR for a row that
had no argument, which is the S5 ceremony the cause codes exist to catch. Either
team has obeyed the standard. The 2026-10-15 hard-look review named this as its
item 4: the rules may be reconcilable, but the adopter has to infer how, and the
predictable outcome is a register that satisfies the count while teaching people to
skim it.

## Forces

- **Two questions were sharing one answer.** The Survey verdict asks whether there
  is an argument to record. The spine row asks whether anyone looked. The first
  answer was being read as the second, and nothing in the text said they differed.
- **The gate cannot read intent.** A check that counts accepted ADRs per row has no
  way to honor an exemption that lives in a Survey verdict. Making the gate aware of
  the Survey would couple the two layers at a second seam; Build DNA §8 says they
  meet at the ADR and nowhere else.
- **The overlay already had the answer.** Its inherited-row ADRs — "eleven rows,
  four lines each, written once" — are exactly the record an uncontested row needs,
  and nobody had generalized them.
- **Ceremony is the failure the Survey was adopted to prevent.** Any resolution that
  produces an argued ADR for an unargued row re-creates the problem ADR 0031
  solved. The record has to be visibly smaller than a decision, or it will be
  written like one.
- **`forces` already does the work.** `impact.sh` follows `forces` to the ADRs that
  rested on a changed constraint. A row foreclosed by `GR-4` and recorded with
  `forces: [GR-4]` is found the day `GR-4` changes. A row recorded nowhere is not.

## Decision

**An applicable spine row the Survey marked `NOT-A-DECISION` closes with a coverage
ADR.** Build DNA §8 gains the section *Closing a row the Survey found no decision
in*, with the rule, its limits and a worked example. In short:

- A coverage ADR is a real ADR: in `decisions/`, status `Accepted`, the row in
  `spine_rows`, read by the gate like any other.
- It carries the answer the system has, the one fact that foreclosed alternatives
  in `forces` by its ID (a `GR-` constraint, a managed policy clause, or the
  platform row an overlay inherits from), the door read off the spine, and a named
  individual where the row requires one.
- It carries no alternatives section. If no foreclosing fact can be named, the row
  was contested and the verdict was wrong.
- One coverage ADR may close every row its fact forecloses. Rows with different
  facts behind them get different records.
- It cannot close a `BLOCKED` or `PROBE` row, and it is not a waiver.
- The Survey's `DEC-` row names it in the ADR column.

`templates/survey.md` §S4.1 says this at the verdict. `skills/survey/SKILL.md` and
`skills/decision-spine/SKILL.md` say it where each skill would otherwise refuse
the ADR or demand the wrong one. The ServiceNow overlay's inherited-row ADRs are
named as coverage ADRs and change in no other way. Build DNA moves to 1.15.

**This corrects ADR 0031.** Its consequence "`NOT-A-DECISION` rows never become
ADRs" was true of the argued record and wrong for a row that maps to an applicable
spine row, where the gate was always going to require one. The decision 0031
recorded — adopt the Survey, earn its gate before spending it — stands; the
sentence is corrected rather than superseded, and 0031 gains `corrected_by`.

## Alternatives considered

- **Exempt `NOT-A-DECISION` rows from the closure checks.** The gate would need to
  read the Survey to know which rows were exempt, which puts a second seam between
  the layers. It would also make the exemption unverifiable: a row marked
  `NOT-A-DECISION` to avoid an argument looks identical to one that had none.
- **Make `NOT-A-DECISION` rows into ordinary ADRs.** That is the ceremony the
  verdict exists to refuse, and ADR 0031's own anti-pattern. A register where
  every default carries an alternatives section nobody weighed is a register
  people skim.
- **A new status, `Covered`, beside `Accepted`.** Every closure check, the
  conformance fixtures and every conforming engine would have to learn it. The
  gate does not need to tell a coverage ADR from an argued one — both close the
  row — so a status that only the reader cares about is not worth an engine
  contract bump.
- **A fourth ADR template.** The shape is a subset of `adr-template.md` with one
  section omitted. A template whose instruction is "use the other one, shorter"
  is a worked example, and the worked example is in §8 instead.
- **Supersede ADR 0031.** The decision in 0031 is unchanged; one sentence of its
  consequences was wrong. Build DNA §8 provides `corrects` for exactly this, so
  that a reader of 0031 can reach the correction without the record being rewritten.

## Consequences

A surveyed build's register gains one short record per foreclosing fact and loses
the contradiction. The short form on a platform-answered system is now mostly
coverage ADRs, which is what the ServiceNow overlay already said it would be. A
reviewer can tell a coverage ADR from an argued one by its length and its missing
alternatives section, and should: a coverage ADR that has grown an alternatives
section is an argued decision that skipped readiness.

Nothing in `gate/` moves. No check, input class, verdict or profile changes, and
no engine needs a new contract. `impact.sh` gains reach without changing: every
coverage ADR cites its foreclosing fact in `forces`, so a changed constraint now
finds the rows it silently answered as well as the ones it argued.

The overlay's open item 7 — eleven identical inherited-row ADRs per application —
is unchanged. This ADR says what those records are; it does not say where a
platform baseline would let them be written once per instance. That is still a
catalog question.

No open item opens or closes. Build DNA open item 10 (intake stated and
unenforced) gains one more unchecked clause — nothing verifies that a coverage
ADR has no alternatives section — and gains it deliberately: the candidate checks
named in ADR 0031 have not had their warn cycle, and a third unmeasured check
beside them is not an improvement.

## Revisit if

See the frontmatter.

## Evidence

- `AGENTS.md` §8, *Closing a row the Survey found no decision in*, with the worked
  example; Build DNA 1.15.
- `templates/survey.md` §S4.1, the `NOT-A-DECISION` row.
- `skills/survey/SKILL.md` S4 and `skills/decision-spine/SKILL.md` hard rule 1.
- `overlays/servicenow.md` §9, naming the inherited-row ADRs; overlay 1.14,
  re-ratified against Build DNA 1.15.
- ADR 0031 frontmatter, `corrected_by: ["0051"]`.
- `tools/validate.py` passes; `tools/build-bundle.sh --check` passes with the
  regenerated manifest.
