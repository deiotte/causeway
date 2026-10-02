---
adr: "0022"
title: Publish Build DNA 1.6 — adoption contract, declared gaps, pinning, offline builds, gate routing
status: Accepted
date: 2026-08-30
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

Build DNA has read 1.5 since v1.5.0 and the standard around it reached v1.8.0 —
eight releases carrying a gate configuration, a decision spine at v0.8, a
platform overlay, an engine contract, a distribution mechanism, conformance
fixtures and release signing. ADR 0012 established that this is correct behavior
and not drift: Build DNA moves when Build DNA's content moves, and across those
releases its content did not.

A review of the standard against what has actually been built since 1.5 produced
ten recommendations. Most were already closed, several by artifacts the review
had not seen. Four were real, and they share a shape worth naming: each is a
rule the standard **already follows** and has never **stated**. The pinning
discipline is implemented in `.causeway-lock` and `check-drift.sh`. The
declared-gap posture is implemented four separate times under four names. The
offline constraint is the reason ADR 0019 chose SSH signing over a log-backed
scheme. The gate-profile routing step is the first thing the `decision-spine`
skill does.

A rule that is implemented but unstated is a rule that survives only as long as
the people who implemented it are present. That is the gap 1.6 closes.

The fifth addition is different in kind. The standard has a 180-day adoption
horizon, a drift check, a lock file and an exceptions register, and no statement
anywhere of what adopting it actually requires of a person. It has a deadline
and no onboarding.

## Decision

Build DNA moves to 1.6 with five additions and no removals. Sections §1–§10 keep
their numbers and their content.

**Adoption contract** — a new unnumbered section after Layering, giving Reader,
Contributor and Maintainer an explicit floor and telling each to stop there.
Placed before §1 because it is the routing decision a newcomer makes first, and
because a reader who needs only the Reader floor should not have to pass through
eight sections of engineering rules to learn that.

**§3 — pin upstream, never silently fork.** Pin exactly; a local edit to
someone else's code is a fork whether or not anyone calls it one; fork
deliberately, vendored and owned with an ADR, or not at all; the gap between
pinned and current is a number someone owns. The standard is the worked example
and says so — `check-drift.sh` exits `5` rather than forbidding the edit, which
is the shape being generalized: visible, not prohibited.

**§6 — the build and the test path reach nothing.** No network in the test path,
dependencies from a populated local cache, the offline path is the one CI runs,
and contract tests against a live upstream are legitimate, named, and kept out of
the merge gate. The last clause is what makes the rule survivable; without it the
rule gets waived on its first real collision.

**§8 — declared gaps.** A requirement that cannot be satisfied is published with
its blocker, never omitted. Four existing mechanisms are named as one rule in a
table: `Waived` ADRs, retroactive ADRs, the `unsupported` verdict, and the
overlay's refusal to invent evidence.

**§9 — resolve the gate profile before writing.** Read `system.json`; the profile
is derived and never declared; missing criticality means C1.

Section numbering does not move. `overlays/README.md` cites `AGENTS.md` §9 and
the ServiceNow overlay cites Build DNA §2, §3 and §5, so the new material lands
as subsections. This is the rule `gate/gate-configuration.md` §10 states for its
own open items, applied to sections, and 1.6 states it for Build DNA's open items
too — which is why open item 2 closes in place rather than disappearing.

`CHANGELOG.md` is added in the same release. It is repository mechanics rather
than Build DNA content, and it belongs with this work because it answers the
question the adoption contract creates: a maintainer told to keep the pin current
needs to know what moving would cost.

`VERSION` moves to 1.9.0. Minor: content added, no check semantics, input
contract, verdict, profile threshold or bundle composition changed. A project
that re-syncs owes the gate nothing new.

## Alternatives considered

**Take all ten review recommendations.** Rejected on the evidence. Five were
already closed — the three adopted practices had shipped with ADRs 0003 and
0004, the systems-engineering layer was already a separate repository with its
own version and lock, and the repo-level release version has existed since v1.0.
One was based on a false premise: Build DNA does not name three handoff
documents, and `SECURITY.md` appears nowhere in the repository.

**Adopt the overlay-precedence recommendation.** Rejected, and worth recording
because the reasoning generalizes. The recommendation asked for a rule about what
wins when a *profile* and the core disagree — but `profile` means G0–G3
throughout this standard, and `overlays/README.md` has a section explaining why
that word was deliberately not used for platform mappings. Adopting the wording
would recreate the exact collision the spine warns about for tier and
criticality. The rule itself already exists and is stronger than what was asked
for: containment lists, tightening-is-free, loosening-is-a-deviation, inheritance
never removes a dagger, inheritance never moves a deadline.

**Re-couple the Build DNA version to `VERSION`.** Rejected. ADR 0012 withdrew
that coupling deliberately and its reasoning is unchanged: a field that always
equals `VERSION` is `VERSION` with extra steps. The recommendation that prompted
this also held that drift checks go ambiguous without the coupling, which is not
how they work — `check-drift.sh` compares per-file SHA-256 against the digest in
`.causeway-lock`, and no version enters the comparison.

**Number the new material as §11 and §12.** Rejected: it puts two normative
sections after the fun clause, which is written as the document's closer, and it
separates the declared-gap rule from §8 where three of its four implementations
already live.

**Renumber to insert the new sections in place.** Rejected outright. Three
external documents cite Build DNA sections by number, and
`gate/gate-configuration.md` §10 records what renumbering on close already cost
this standard once.

**Add a gate check for the offline test path.** Deferred to open item 5. The
honest version needs a way to distinguish a contract test allowed to reach a
vendor from a unit test that is not, and neither the check nor that distinction
is drafted. Shipping the rule without the check is consistent with §9 — this
document is guidance, and a merge-blocker is a separate decision with its own
evidence.

## Consequences

Four rules the standard depended on tacitly are now stated, which means they can
be argued with, deviated from under §2's owned-exception shape, and inherited by
a project whose authors never spoke to us. That is the whole purpose of writing
a standard down.

The adoption contract creates an obligation this repository cannot yet meet
honestly: it claims the Contributor floor costs an afternoon and the Maintainer
floor is a standing obligation, and both numbers come from the people who wrote
the standard. Open item 4 records that. The first independent adopter will either
confirm or embarrass those estimates, and either outcome is more useful than the
current silence.

`§6`'s offline rule is guidance with nothing enforcing it, and this repository's
own CI has egress. Open item 5 records that too, rather than letting the rule
read as though something checks it.

Every consuming project's vendored `AGENTS.md` is now one minor version behind
until it re-syncs. Nothing breaks — no check reads the Build DNA version — and
`standard-currency` will register the age.

## Evidence

`AGENTS.md` — version header 1.6; the Adoption section; the new subsections under
§3, §6, §8 and §9; open items 2 closed in place, 4 and 5 added, and the
numbering-stability preamble.

`CHANGELOG.md` — the v1.9.0 entry, and the reconstructed history behind it.

`VERSION` 1.9.0, `RELEASED` 2026-08-30, `bundle/manifest.json` regenerated;
`gate/checks.json` and `conformance/expectations.json` carry the new
`standard_version`.

`bundle/scope.json` — `CHANGELOG.md` declared ungoverned with its reason, which
is the check that made the declaration necessary rather than optional.

`./tools/validate.py` — clean. `./tools/build-bundle.sh --check` reproduces the
v1.9.0 digest. Sync, lock, drift and the deliberate-drift test pass, and every
published overlay vendors and locks.
