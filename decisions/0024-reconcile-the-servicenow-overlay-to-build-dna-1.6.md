---
adr: "0024"
title: Reconcile the ServiceNow overlay to Build DNA 1.6, and guard the field that let it drift
status: Accepted
date: 2026-09-02
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

ADR 0022 moved Build DNA from 1.5 to 1.6 at v1.9.0. The ServiceNow overlay's
header says it is ratified against three versions — Decision Spine v0.8, gate
configuration v0.6, Build DNA v1.5 — and `overlays/servicenow.json` carries the
same three under `ratified_against`. Two releases later, v1.9.0 and v1.9.1, the
overlay still said 1.5 and CI was green both times.

It was green because `validate.py` never read the field. ADR 0011 added the
guard that makes overlay staleness a build failure, and it checked the two
versions that had actually moved at the time — the spine and the gate
configuration. Build DNA had not moved since v1.5.0 and did not move for eight
releases after, so the third version in the header was never wired to
anything. The projection's `build_dna` key has existed since ADR 0013 with no
reader. This is the same shape ADR 0011 was written about, one field over: a
version the overlay claims currency against, that core can move, that nothing
compares.

The README recorded it as the reconciliation gap in the ServiceNow section,
credibility gap #3, and development priority #2, which asked for two things —
review the overlay against 1.6, and make `ratified_against.build_dna` a
validated field.

Reviewing the overlay against 1.6 found that ADR 0022's five additions are
process rules, and §7 of the overlay is where process rules get their platform
translation. None of the five had one. Two of them genuinely need one, because
a literal reading is wrong on this platform: §6's offline test path cannot
"reach nothing" when the test runner is the instance, and §9's profile
resolution has a platform-specific way to get it wrong that §8 already warns
about in different words.

## Decision

**The overlay is reconciled and becomes version 1.3**, ratified against Build
DNA v1.6, with the **Reconciled at** row moved to 1.9.2. No row's disposition
changed; the published counts are unmoved; the containment rule still reads
zero rows added, retired or reclassified.

§7 gains five rows, one per 1.6 addition, in Build DNA section order:

- **Adoption contract.** Same three floors. The platform blurs the line the
  contract draws — changing a flow, a business rule or a configured out-of-box
  artifact is changing code — so the Contributor floor applies to App Engine
  Studio work as it does to a scoped-app engineer. The Maintainer's pin has two
  halves here: the vendored standard and the installed Store and spoke versions.
- **§3 pin upstream.** A modified out-of-box artifact is a fork whether or not
  anyone calls it one. The customization ledger row with its ADR is the declared
  fork §3 permits; a skip record at upgrade is the undeclared one surfacing.
- **§6 offline test path.** The honest translation is that the merge-gating
  suite reaches nothing beyond the instance under test — no live spoke, no
  vendor sandbox — and contract tests against a live spoke stay named and out
  of the gate. The row declares the gap rather than papering it: a scoped
  application has no offline build in §6's sense, because the instance is the
  build environment.
- **§8 declared gaps.** The overlay was already the fourth named implementation
  of the rule and applies it three more times — every N/A in its evidence table,
  the input-class map, and §9 step 3's *no ADR yet is acceptable, no row is
  not*. The row says so.
- **§9 profile resolution.** Same three steps. The platform-specific error is
  treating the profile as a property of the instance or the tooling; it is a
  property of the application, and citizen development lands wherever tier ×
  criticality put it.

Open item 5 is corrected in passing: it said `conformance/` ships eight
fixtures, every one a repository with a lockfile. There are nine, and
`floating-dependency` deliberately has none. The item's point stands — none of
them is ServiceNow-shaped — and it now says so with a true premise.

**`validate.py` reads the third version.** The Build DNA version is parsed from
`AGENTS.md`'s header the way the spine version is parsed from the spine's, and
two assertions bind it: the overlay's prose header must name the current Build
DNA, and the projection's `ratified_against.build_dna` must equal it. The second
is a separate assertion rather than an extension of the spine-and-gate-config
pair so that the failure names the field.

**Version 1.9.2, patch.** The overlay is inside the digested bundle, so the
bytes moving is a release. Nothing normative changed: the five rows translate
rules a consumer already owes through its vendored `AGENTS.md`, no row, check,
threshold, input class or profile moved, and a project that re-syncs owes the
gate nothing new. ADR 0011 set the precedent — a reconciliation is a patch, and
spending a minor on one makes the number stop carrying information.

## Alternatives considered

**Move the header and skip the §7 rows.** What "re-ratify" has meant twice
before (1.1 and 1.2), and rejected here because the premise that made it right
then is false now. Those reconciliations recorded that nothing relevant moved.
This time Build DNA moved, its additions are process rules, and §7 exists to
translate process rules. A header that says 1.6 over a table that stops at 1.5's
content would be the overlay making exactly the currency claim the JSON was
making — true about the number, silent about the content.

**Skip the guard and fix the header.** Rejected for the reason ADR 0011 and
ADR 0023 both give: a rule the standard states about itself and does not check
is a rule it discovers broken later. The header has said 1.5 through two
releases with the guard one line away from catching it. The README's own
priority asked for the guard by name.

**Fold `build_dna` into the existing spine-and-gate-config assertion.** Rejected
on the failure message. That assertion reports the pair it checks; adding a
third value to a tuple comparison produces a failure that names three versions
and leaves the reader to find the one that differs. A field that went unread for
eleven releases earns an assertion that says its name.

**Bump the minor version.** Rejected as in ADR 0011. Every minor so far added an
obligation; this adds none.

**Also move the gate configuration or the spine.** Not considered seriously and
recorded so the next reader does not have to: neither changed, and moving
either would force the very reconciliation this ADR is performing to be
performed again.

## Consequences

The three versions in an overlay's header are now all load-bearing. A Build DNA
bump fails the build until every overlay's header and projection move, which
forces the question *does this change need a translation* at the moment the
person who wrote the change can still answer it. That is the cost ADR 0011
accepted for the other two versions, extended to the third.

The §6 row is the one that adds a real obligation to a reader's understanding,
without adding one to the gate: a ServiceNow shop that reads "the test path
reaches nothing" and concludes the rule cannot apply now has the version that
does. Nothing enforces it, on this platform or any other — Build DNA open item
5 records that and this ADR does not close it.

README credibility gap #3 loses its second clause and development priority #2
closes. The README's assertion count moves and its guard makes that visible.

## Evidence

`tools/validate.py` §7 — `build_dna_version`; §13 — the Build DNA entry in the
header loop; §15 — the `ratified_against.build_dna` assertion.

**The guard was written first and made to fail before the overlay moved.** On
the unreconciled tree it reported both new assertions red and nothing else:

```
FAIL  overlay servicenow: ratified against the current Build DNA
      overlay says 1.5, standard ships 1.6 — reconcile the overlay and move its header
FAIL  overlay servicenow.json is ratified against the current Build DNA
      json 1.5 vs AGENTS.md 1.6 — reconcile the overlay against the new Build DNA and move both headers
2 failed · 506 passed
```

`overlays/servicenow.md` — header, the *Reconciled in 1.3* note, §7, open item 5.
`overlays/servicenow.json` — `overlay_version`, `ratified_against.build_dna`,
`reconciled_at_standard`. `overlays/README.md` — the overlay table.

`VERSION` 1.9.2, `RELEASED` 2026-09-02, `bundle/manifest.json` regenerated;
`gate/checks.json` and `conformance/expectations.json` carry the new
`standard_version`.

`./tools/validate.py` — 515 passed. `./tools/build-bundle.sh --check`
reproduces the digest. Sync, lock, drift, the deliberate-drift test, and the
overlay vendoring step from `standard.yml` pass locally.
