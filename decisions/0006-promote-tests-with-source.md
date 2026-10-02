---
adr: "0006"
title: Promote tests-with-source on its definition, behind a derived release marker
status: Accepted
date: 2026-08-09
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

`tests-with-source` has been warn-only at every profile since gate configuration
v0.3, deferred to "one portfolio cycle" producing a false-positive rate. Gate open
item 4 named the trap in its own text — *an advisory check with no counter behind it
stays advisory by default rather than by decision* — and then made the counter a
precondition for the decision, which is what kept the decision from being made.

**The deferral condition cannot be satisfied as written.** A portfolio cycle needs
CI, and this repository has none (open item 6). Neither does a receipt field exist
that would record the rate if a cycle did run. Item 4 was waiting on a number that
nothing was arranged to produce, which is a deferral wearing a criterion.

The question that forced the issue was narrower: should a system still under
development be exempt? In principle yes. Early architecture moves, tests written
against a shape that changes daily get skipped or deleted, and `rules/tests.md`
already warns that permanently skipped tests are worse than absent ones because they
read as coverage. A premature blocking check manufactures precisely the failure the
rule exists to prevent.

But the obvious implementation is `pre_release: true` in `system.json`, which is the
decorative-declaration failure §1 forbids in its first sentence. So the search was
for a marker that is derived rather than declared — and that search turned up a
second problem. **`first release tag` appears exactly once in the entire standard**,
in the `oneway-closure` row of the §4 inventory, and is defined nowhere. The spine
states the rule (*close every one-way row before writing production code*) and leaves
the gate to resolve it against something on disk, which is the correct seam. The gate
never wrote down the resolution. A check that blocks at G1 through G3 has been
resting on an undefined term since v0.1.

## Decision

**Promote the check on its definition rather than on a portfolio number, and gate
the block on a lifecycle marker that is derived rather than declared.**

1. **Tighten the definition first.** Two subtractions from the source set, both
   mechanically provable: **pure deletions**, and **renames git scores at 100%
   similarity**. A deletion cannot be accompanied by a test, and one that orphans a
   live test fails the suite on its own. A 100% rename is git asserting the content
   did not change. Neither requires a judgment call, and neither can be gamed
   without editing content — at which point the similarity score drops and the file
   returns to the source set.
2. **What remains is the §6 bar restated.** Source added or modified, no test
   touched. v0.3 named three cases that made the false-positive rate uncertain —
   pure deletions, dependency bumps, pure moves — and the tightened definition
   disposes of all three. Dependency bumps were already N/A under the manifest rule
   unless they force a source change, and a source change a bump forces is behavior
   that owes a test like any other. **This is the substantive move: the unknown was
   converted into a definitional change rather than waited on.**
3. **Blocking at G2 and G3 only.** Warn at G0 and G1 permanently. A sandbox app and
   a time-boxed tactical build see the finding and are not stopped by it.
4. **Gated on `release_state`,** a new §4 primitive that resolves `pre_release` or
   `released` from annotated tags matching a per-system pattern. Warn while
   pre-release, block once a release is cut. `oneway-closure` reads the same
   primitive, so the term it has used since v0.1 acquires a definition instead of
   the standard acquiring a second lifecycle concept.
5. **The counter lands, narrower than item 4 demanded.** The receipt gains
   `release_state` and a `tests_with_source` block carrying a verdict, a reason code,
   and the subtraction counts. A receipt cannot produce a false-positive rate — only
   a human reading a specific change can call a finding wrong, the same limit
   `as-built-notification` runs into. What it produces is a fire rate and an
   exclusion mix.
6. **Decided now, engages after one warn cycle.** `profiles.json` carries the
   promotion as `promotes_to` rather than as the active value, so re-syncing does not
   hand a project a new build failure on arrival. Rows get an adoption horizon;
   checks get a warn cycle.
7. **Gate open-item numbers are stable from v0.5.** Closed items keep their number
   and entry, marked closed — the rule the spine applies to row IDs. ADR 0003's
   pointer to "§10 item 5" already references a different item than the one it
   closed, because v0.4 renumbered on close.

The modifier concept is generalized rather than special-cased: `profiles.json` now
declares both `adoption-horizon` and `pre-release` under a `modifiers` key, and the
three closure checks carry theirs explicitly. The horizon modifier has existed since
v0.4 and was prose-only, which made the machine-readable artifact report those checks
as more absolute than they are.

## Alternatives considered

**Wait for the portfolio cycle.** Rejected because the condition is unsatisfiable,
not because waiting is wrong. With no CI in this repository and no receipt field
recording the rate, "after one cycle" is a date that never arrives. A criterion
nothing is arranged to satisfy is indistinguishable from a decision not to decide,
and it fails in the same direction every time — toward permanence by default, which
is what item 4 warned about in its own text.

**Declare it: `pre_release: true` in `system.json`.** Rejected on §1. A team that
sets its own lifecycle state sets its own exemption, and teams would sit in it for
years. This is the same failure as a declared `gate_profile` and a declared
`spine.version`, both already rejected for the same reason — the third time the
standard has reached for a derived marker after considering a declared one, which is
starting to look like a design rule rather than a coincidence.

**Push the promotion down to G3 alone.** Rejected as a category error. Profile is
derived from tier and class — *where a system lives* and *what its failure costs* —
and neither of those is *has this shipped yet*. Using it as a lifecycle proxy would
permanently exempt every mission-tier system in order to relieve the ones still
under construction, which is the same shape as the G3
inversion that killed the standing version-drift proposal in ADR 0005, where a
mechanism reached the wrong population because it was hung on the wrong axis.

**Promote it unconditionally at G2 and G3, with no lifecycle gate.** Rejected. It
answers the original question with "no," and the argument for the deferral is sound:
a system whose architecture is still moving produces test churn, and the check would
be enforcing a promise the system has not made yet.

**Leave it advisory permanently.** Rejected, and this is the one deferral that
compounds. A stale standard pin is fixable in an afternoon by re-syncing; retrofitting
tests onto a finished system is the expensive thing everyone avoids forever. That
asymmetry is why §6 states the bar at all, and it is why this check is worth the
argument while `standard-currency` can wait.

**Fix `first release tag` separately, as its own change.** Rejected on cost, not
principle. The definition is four lines and two checks read it; splitting it would
produce one revision that defines a term nothing new uses and a second that uses it,
reviewable against neither.

**Resolve `oneway-closure`'s pre-release semantics in the same pass.** Rejected on
scope, and this is the one place the change was deliberately stopped short. Defining
the term exposes a gap that predates it: the row says *closed before first release
tag* while the inventory blocks at G1 and above unconditionally, so the check may be
firing before its own stated deadline. Both readings are defensible — the other being
that G1 means close them now, release or not — and picking one changes what a
blocking check does to every system that has never released. That is a larger change
than defining a word, it affects systems this ADR is otherwise not touching, and it
belongs in its own decision. Recorded as open item 9 rather than resolved quietly.

**Add a `pre-release` modifier only, leaving the horizon modifier as prose.**
Rejected. It would put one of two modifiers in `profiles.json` and leave the other in
a paragraph, which is worse than either doing both or doing neither — a consumer
reading the JSON would see one conditional and reasonably conclude it was the only
one.

## Consequences

- **Every G2/G3 system that has cut a release will owe tests on source changes** once
  the warn cycle ends. That is the point and it will be the loud part. `rules/tests.md`
  and `AGENTS.md` §6 have asked for this since v1.0; nothing enforced it.
- **`oneway-closure` acquires a definition it did not have.** It has read "before
  first release tag" since v0.1 against nothing, so any implementation resolved it by
  assumption. Those assumptions now have to match `release_state` — annotated tags
  only, semver-shaped by default, prerelease suffixes counting as released. An
  implementation that assumed otherwise will move, and that should be checked
  deliberately rather than discovered. Its *blocking* semantics are untouched, and
  the gap that exposes is open item 9.
- **The never-tag bypass now defers a second check.** A system that never tags a
  release never leaves `pre_release`, which defers `tests-with-source` outright and
  may already have been deferring `oneway-closure` — item 9. The receipt makes it a
  portfolio query and §6 makes the honest route cheaper, but neither is a control.
  Recorded as open item 8, and the remedy if the set is not small is to replace the
  marker for both checks at once rather than patch one.
- **File relocations still fire.** Moving a file means updating its importers, and
  those edits are ordinary source modifications. Separating them from real changes
  needs semantic analysis. This is the single named residual, it is open item 7, and
  a finding carrying a non-zero `excluded.renames_100` is its signature.
- **The warn cycle has no mechanism in this repository either.** Same gap as item 6:
  no CI, so "one cycle" is again a portfolio-operator convention rather than something
  the standard runs. It is a weaker position than the decision itself and it is
  recorded rather than papered over.
- **The spine does not change.** Design says *when* (before production code);
  enforcement says *how it is read from files* (a release tag). Spine stays 0.7,
  `spine_version` in `profiles.json` stays 0.7, no system owes a new row for this
  revision. Had this required a spine edit it would have meant the decision leaked
  across the seam `AGENTS.md` §9 warns about, and that was the check on the work.
- Gate open item 4 closes. Items 7, 8, and 9 open. Items 7 and 8 are narrower than
  the one they succeed; item 9 is a gap this work found rather than made. Gate
  configuration v0.5, standard v1.4.0.

## Evidence

`gate/gate-configuration.md` §4 (*Modifiers*, `release_state`, `tests-with-source`),
§6 (`release_tag_pattern`, exclusion), §7 (receipt fields and the counter's stated
limit), §9 step 8, §10 (numbering note, item 4 closed, items 7–9) ·
`gate/profiles.json` (`release_state`, `modifiers`, `promotes_to`, modifier
references on the three closure checks) · `AGENTS.md` §7 · `README.md` (checks get a
warn cycle, not a horizon) · `VERSION` · `RELEASED`.
