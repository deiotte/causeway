---
adr: "0031"
title: Adopt the Survey as the intake artifact, and earn its gate before spending it
status: Accepted
date: 2026-09-18
spine_rows: []
survey_rows: []        # no Survey precedes this ADR; the instrument it adopts is what produces them
forces: []             # not Survey rows — see the Forces section for what discriminated
door: two-way
revisit_if: Three consecutive surveyed builds show no S3/S4/S5 supersessions and none
  stop at the Survey's exit criteria — at which point the intake is either working and
  can be lightened, or is being skipped, and the cause-code register says which.
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

Causeway assumes decisions arrive at the ADR seam ready to be recorded. Nothing in
the contract asks whether they are. `AGENTS.md` §8 governs how an ADR is written
once you have one; the Decision Spine enumerates which rows a system must close;
the gate checks that the required decision and evidence are present. All three
begin at the moment the record is written, and none of them looks upstream of it.

The observed failure is ADR churn — records amended or invalidated within days.
The supersessions inspected so far are not decision-making failures. They fall into
three shapes: a constraint that existed and was knowable on day one but had not
surfaced; a decision recorded before the upstream decision it depended on closed;
and an ADR written for something with no real alternative, rewritten later when the
default moved. Tightening the template does not reach any of them, because the
missing input was information, not rigor.

The cost is not tidiness. Under one-prompt-one-commit (ADR 0003) the handoff
package is generated from the ADR set, so an ADR that is wrong on Tuesday has been
built against by Wednesday and the correction is a code change rather than a
document edit.

A candidate instrument exists and has had exactly one field run. The Survey is a
six-section intake — Frame, Ground, Load, Bearings, Spans, Handoff — with permanent
row IDs, a four-part decision readiness test, and supersession cause codes S1–S5
that classify each future supersession as healthy or as a named intake defect. Its
first run was a retroactive audit of a prior build's handoff package, which had eight
accepted ADRs, zero superseded, and no code. It found three things nobody had
noticed: an ADR specifying a tracker in full detail against an archive the build
order says does not exist yet, a single unmeasured throughput figure leaking across
two ADRs into an unsized retention decision, and a failure-mode TODO that had no
owner because a TODO cannot have one.

That is a real result and it is one result, on a build that has not started. This
ADR adopts the instrument. It deliberately does not adopt the enforcement.

## Forces

This ADR has no Survey upstream of it — the instrument that would produce `GR-` rows
is what it adopts — so its forces are this repository's own constraints rather than
spec IDs. They are stated here because a release that requires `forces` and ships
without them is arguing against itself.

- **The supersession record.** Records amended or invalidated within days, in the three
  recurring shapes named in Context. That record, not a preference, is what says the
  defect is upstream of the seam.
- **`gate/gate-configuration.md` §9.** Every new blocking behavior gets a warn cycle
  before it engages. This is what decides that the two candidate checks cannot ship
  with the instrument: a warn cycle needs a measurement, and the cause codes are it.
- **README limits 2 and 8.** Conformance is a vertical slice and no independent team
  has reported adoption evidence. Shipping blocking checks for an instrument with one
  field run would add a third instance of the thing both limits already admit.
- **ADR 0003, one prompt one commit.** The handoff package is generated from the ADR
  set, so the gap between a wrong record and code built against it is about a day.
  That is what makes intake worth a layer rather than a habit.
- **ADRs 0017, 0027, and 0029.** The quoted ADR identifier, the correction pointers,
  and the adapter-names-every-skill check are each a property the source package would
  have silently regressed. They discriminate hand-merging from copying.

## Decision

The Survey is adopted as an **intake artifact** that the existing layers cite, and
its enforcement is staged across three releases rather than shipped with it.

**What intake is, precisely.** The README's `What Causeway standardizes` table
gains an `Intake` row naming `skills/survey/` and `templates/survey.md`, with the
Survey document itself — `docs/SURVEY.md` in a consuming project — as the artifact.
Intake differs from every other row in that table in one way that must be stated
rather than smoothed over: it is the only row whose artifact is produced *before
the repository exists*, which means it is the only row with no enforcement surface
at the moment it does its work. Its output becomes governable when it lands in the
repository and is cited by ADRs. Until then it is a conversation, and the contract
cannot reach it. Calling intake a fourth peer layer would claim otherwise.

The relationship to the two adjacent layers is exact and non-overlapping:

> The Survey says whether a spine row is **ready to close**. The ADR **closes** it.
> The gate checks it **closed**.

**Release 1 — the instrument, no gate.** `skills/survey/SKILL.md` and
`templates/survey.md` ship and are vendored. The ADR template gains `survey_rows`,
`forces`, `door`, and `revisit_if` as **optional** fields, and `supersession_cause`
as required only on an ADR that supersedes another. No check moves, no profile cell
moves, no verdict is added: a minor bump under this repository's own compatibility
rule.

**Release 2 — the measurement.** The cause codes accumulate. Every superseding ADR
records S1–S5. S1 and S2 are healthy; S3, S4, and S5 each name the intake step that
was skipped. The count across builds is read at retro, and it is the only evidence
that would justify release 3.

**Release 3 — the gate, if the measurement earns it.** Two checks are candidates:
`survey-present` and `adr-forces-nonempty`. Neither ships until the distribution of
cause codes says intake is the binding constraint, and both then follow §9 of the
gate configuration like every other new blocking behavior — warn-only for one cycle,
results read before the block engages.

**Adoption is not retroactive.** The thirty existing ADRs carry no `forces` and are
not backfilled. The requirement attaches to ADRs written after the release that
introduces it, by the same mechanism `tests-with-source` already uses: a decided
`promotes_to` with a stated `engages_after`, not a flag day.

## Alternatives considered

**Ship the instrument and both gate checks in one release, as the source package
proposes.** Rejected on this repository's own record. The README's standing limit 8
is that no independent team has reported adoption evidence, and limit 2 is that
conformance is a vertical slice; adding two blocking-capable checks for an
instrument with one field run, on a build that has not yet been built, reproduces
both. The gate configuration requires a warn cycle for every new blocking check,
and the warn cycle needs something to measure. The cause codes are that something,
and they do not exist yet.

**Treat intake as a fourth layer peer to process, design, and enforcement.**
Rejected as described above. The three existing layers are defined by who executes
them — always-on agent context, an on-demand skill, CI. Intake has no executor
inside the contract at the moment it runs. An honest table row costs nothing; the
layer claim would have the standard assert reach it does not have.

**Extend the Decision Spine with intake rows instead.** Rejected. The Spine is
generic — the same 94 rows for every system — and intake is one system's ground
truth. Folding them together pushes the Spine past the row count at which teams
disengage and crosses the process/design seam the standard is built on.

**Make it a document rather than a skill.** Rejected. The instrument's own failure
mode is a blank template filled through its easy sections and abandoned at the
decision inventory, which is the only section that prevents the problem. The
procedure that gets a Survey finished — draft candidate rows, have the human ratify
— is conversational, and that lives in a skill.

**Do nothing.** Rejected on the handoff argument. Churn is cheap while a decision is
prose and expensive once it is code, and under ADR 0003 the gap between those states
is about a day.

## Consequences

**The source package cannot be applied as written.** It was built against the v1.0.0
layout and the repository is at v1.14.0. Six of its seven steps have since acquired
a constraint it does not know about:

- Its `templates/adr-template.md` would regress three shipped ADRs. It unquotes
  `adr: 0000`, which ADR 0017 quotes deliberately because YAML 1.1 reads a
  leading-zero integer as octal — the property `conformance/fixtures/adr-identifier-boundary`
  exists to pin. It drops `corrects` and `corrected_by`, which ADR 0027 added and
  `validate.py` checks in both directions. And it says *seven dagger rows* where the
  standard has eight. The five new fields are additive and none of them conflict;
  the file must be hand-merged, never copied.
- Adding `skills/survey/` without naming it in all four adapters fails CI. ADR 0029
  made that a check after `skills/field-note/` shipped unreachable for a release.
- Every tracked path is bundled or declared ungoverned in `bundle/scope.json`. Both
  new files belong in `BUNDLE_FILES`, for the reason `templates/field-note.md` is
  bundled: a project that quietly edited the survey template would still be
  producing something it called a Survey, and the ADR fields that cite its row IDs
  would be reading a different artifact. The bundle moves 26 → 28, and the README
  states the bundle count in two places under a §16 prose guard.
- The README repository map gains a `skills/survey/` row. `validate.py` checks that
  map against the tree in both directions.
- The source ADR cites `spine_rows: [SA-9.5, SA-9.6]`. Those rows are *where is the
  documentation of record* and *where is the ADR index* — documentation location,
  not intake. A meta-ADR about the standard takes `spine_rows: []`, as 0025 and 0029 do.
- The two proposed checks are described as *a few lines against files you already
  parse*. They are not. Moving 27 → 29 touches five restatements of 27 in the
  README, the `N of the M checks read` anchor in both the README and the gate
  configuration, `gate_config_version`, `standard_version` in `checks.json`, the
  conformance scope, and an `engine_contract` number for every engine that has
  implemented the catalog. This is the single most underestimated item in the
  package, and it is the one release 3 exists to do properly.

**Two vocabulary collisions have to be settled before release 1, not after.** The
Survey's exit criteria are called a *gate* and carry PASS / PASS-with-conditions /
NO-PASS, against the gate's eight verdicts and five exit codes. One standard with
two things called a gate and two verdict vocabularies is the defect ADR 0008 already
paid for once; the Survey's is renamed to **Survey exit criteria**, or its outcomes
map onto the existing verdicts. Separately, the ADR `door` field restates the
Spine's `One-way` column — 28 rows at spine 0.8 — so it is derived from the Spine or
cross-checked against it. An ADR asserting `door: two-way` on a row the Spine marks
`Y` is a contradiction the validator should catch rather than a field the author gets
to choose.

**A third Survey mode exists and is undocumented.** The instrument describes a full
Survey and a backfill of a build already churning. The audited build was neither:
eight accepted ADRs, no churn to classify, no code. Step 2 of the backfill path —
*classify the existing churn* — had nothing to operate on. A retroactive readiness audit of an ADR
set that exists but has not been built against is a distinct mode, it is the cheapest
one to run, and it is almost certainly the most common way a team meets this
instrument: after the ADRs, before the build. It is documented as first-class.

**`PROBE` becomes a real schedule cost.** Some builds start with a spike rather than
a commit. On the audited build every probe was already in the build order and the added
schedule was zero, which is the best case and should not be generalized from.

**The register shrinks.** `NOT-A-DECISION` rows never become ADRs. A smaller
register people actually read is the intent, and it will look like less output.

**The cause codes can embarrass the intake.** That is the only mechanism by which it
improves, and it is also the mechanism a team stops feeding the moment the codes are
read as blame rather than as a defect class.

**What would falsify this ADR.** Three consecutive surveyed builds showing no S3, S4,
or S5 supersessions and none blocked at the Survey's exit criteria. Either the intake
has done its job and can be lightened, or it is being skipped — the cause-code
register distinguishes those, and the answer decides whether this is relaxed or
enforced harder.

## Evidence

`skills/survey/SKILL.md`, `templates/survey.md`, the four optional fields and one
conditional field in `templates/adr-template.md`, the `Intake` row in the README's
`What Causeway standardizes` table, the `skills/survey/` pointer in all four
adapters, the bundle at 28 files, and — from release 2 — the `supersession_cause`
distribution across surveyed builds, read at each retro. Release 3 ships no check
until that distribution exists.
