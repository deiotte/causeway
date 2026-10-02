---
adr: "0034"
title: Close the one-way deadline against the spine, not against a release
status: Accepted
date: 2026-09-19
spine_rows: []
survey_rows: []
forces: []
door: two-way
revisit_if: The profile matrix changes such that G1 no longer implies a deployed
  system — the proxy this rests on is "a Tactical Authorization and a sandbox tenant
  mean production code exists", and if G1 ever stops meaning that, the deadline needs
  a different readable form.
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

`oneway-closure` blocks at G1 and above and has since v0.1. Its question has read
*Were all 28 one-way rows closed before the first release tag?* for just as long.

Gate configuration open item 9 recorded the tension between those two facts:

> A repository that has never released and has open one-way rows has not missed the
> deadline, so the block may be firing early. The alternative reading — that G1+
> means *close them now, release or not* — is also defensible, which is why this is
> an open item rather than a correction.

Two defensible readings, no way to pick. It sat from v0.5.

**Both readings were of the gate, and the deadline is not the gate's to set.** The
spine is the design layer; the gate resolves its rules against something on disk.
So the question is not *which reading of the check is right* but *what does the
spine say the deadline is*. It says this, in four places:

| Where | What it says |
|---|---|
| `spine.md`, the One-way column | "Close every `Y` row **before writing production code**." |
| `spine.md`, the one-way doors section | "If you close nothing else **before code**, close these." |
| `AGENTS.md`, the Maintainer floor | "One-way doors close **before production code**." |
| `skills/decision-spine/SKILL.md` | "they should close **before production code**." |

Not once does the design layer mention a release.

So item 9's own first sentence mis-cites its subject. It opens *"Its **row** reads
28 rows closed before first release tag"* — the row reads nothing of the kind. The
phrase lives in the check's question string and in this document's §4 inventory
row, and §4 says where it came from: *"`oneway-closure` has read 'before first
release tag' since v0.1, and that term is defined nowhere in this document or the
spine."* The gate carried a deadline the design layer never set, v0.5 then defined
`release_state` to give that deadline a meaning, and item 9 asked which half of the
gate to believe.

## Forces

- **The design layer is unambiguous and the gate is the outlier.** Four statements
  against one, and the one admits in §4 that its term was undefined. Where the two
  layers disagree the spine is the design layer and the gate implements it — the
  same precedence Build DNA §9 states in the other direction for enforcement.
- **The blocking column was already correct.** The gate's second design rule is
  that it reads files, not opinions, and *production code exists* is not a file.
  But the profile already is one: G1 requires a Tactical Authorization and a
  sandbox tenant, which is what a deployed system looks like from disk. Warn at G0,
  block at G1 and above, is the spine's deadline compiled. Nobody had to invent a
  second, worse proxy on top of it.
- **`release_state` never reached the verdict.** It sat in the check's `evidence`
  list and its `modifiers` are `["adoption-horizon"]` — no `pre-release`. Two
  releases of open item, and the marker the item was about had never changed an
  answer in the check the item was about.
- **`repo-git` was therefore a required input for decoration.** An engine that
  could read `decisions/` and the system record, but had no git, reported
  `unsupported` on a check about whether ADRs exist — and at G1 and above that is
  exit 4, a blocked deployment, for want of a tag whose value would not have been
  consulted.
- **The other consumer is the one that fits.** `tests-with-source` reuses
  `release_state` because its promotion turns on *has this shipped yet*, which §4
  argues at length and which is coherent. One marker, two checks, and only ever one
  of them wanted it.

## Decision

Close item 9 as a **correction**, with the correction running opposite to the
direction the item anticipated: the question string moves to meet the blocking
column, not the reverse.

`oneway-closure` now asks *Are all 28 one-way rows closed?* Its description carries
the spine's deadline and states how the gate reads it. It stops declaring
`repo-git`, and stops listing `release_state` as evidence. Its blocking column is
untouched — warn at G0, block at G1 and above — and `adoption-horizon` remains the
modifier, which is the correct softener for rows a spine revision added after a
system shipped.

`engine_contract` stays at 1, with a note saying why. Contract numbers move when a
check's meaning changes; this check's verdict logic has not moved since v0.1. What
moved is the declared input set, and only downward, so every engine that could run
it before still can.

Gate configuration goes to v0.8. The standard goes to **2.1.0**.

## Alternatives considered

**Add the `pre-release` modifier to `oneway-closure`.** The reading item 9 leaned
toward: a repository that has never released warns instead of blocking. Rejected
because it contradicts four statements in the design layer to satisfy one phrase in
the enforcement layer, and because of what it would do downstream — it would make
`release_state` load-bearing for a check that blocks, which puts a platform release
record on the critical path for every non-git platform and makes open item 14 a
prerequisite rather than a backlog entry. A correction that creates a dependency is
usually the wrong correction.

**Close item 9 as "the blocking column is right" and change nothing else.** The
minimal edit, and it was tempting because no verdict moves either way. Rejected
because it leaves the question string contradicting the spine and leaves `repo-git`
required for decoration — which means the next reader re-derives this whole argument
from the same contradictory artifacts, and the platform lockout stays. An item that
closes without removing its own evidence has been marked rather than resolved.

**Change the spine to say "release" instead of "production code".** Considered only
long enough to reject it. It would move a deadline later for every system to make an
unexamined phrase in a check description correct, which is the design layer deferring
to the enforcement layer — exactly backwards, and the more expensive direction, since
one-way doors are the rows where being late costs the most.

## Consequences

**No system's verdict changes.** The check's behaviour is what it has been since
v0.1. This release makes its description true.

**A platform with no git can run `oneway-closure`.** On `repo-decisions` and
`system-record` alone. That is the concrete win, and it lands where the standard
had the least excuse: refusing to evaluate an ADR register because there were no
tags.

**Open item 14 narrows and leaves the critical path.** `tests-with-source` is now
the only consumer of `release_state`, it warns at all four profiles, and its
promotion has not engaged. The platform release record is still owed and is no
longer blocking anybody.

**An engine's declaration may now be over-broad.** An engine that declared
`repo-git` solely to run `oneway-closure` still conforms and still runs everything
it ran before; it is simply declaring a capability one fewer check needs. Nothing
is owed for that, and no contract number moves for it.

**`tests-with-source` is where the release-tag reasoning survives**, and it should
be read as load-bearing there, not as a leftover. §4's argument for it — profile is
*where a system lives* and *what its failure costs*, neither of which is *has this
shipped* — is the reason a lifecycle marker exists at all.

## Revisit if

G1 stops implying a deployed system. This decision rests on the proxy that a
Tactical Authorization and a sandbox tenant mean production code exists. If the
profile matrix or the G1 definition changes so that is no longer true, the spine's
deadline needs a different readable form and this closure should be re-read against
it.

## Evidence

`gate/checks.json` — `oneway-closure` question, description, `inputs`, `evidence`,
`engine_contract_note`, and the removal of its `open_item` pointer.
`gate/gate-configuration.md` §4 (inventory row, the `release_state` provenance
paragraphs) and §10 items 9 and 14. `gate/profiles.json` `release_state.$comment`.
`decisions/open-items.json`.
