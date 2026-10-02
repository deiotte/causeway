---
adr: "0005"
title: Ratify the adoption horizon as the spine version-drift policy
status: Accepted
date: 2026-08-08
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

The spine has carried an unratified version-drift policy since v0.4. v0.5 said
"ratify the policy or replace it before v0.6." v0.6 shipped without it and moved
the deadline to v0.7. This is the third time it has come up and the first time
anyone has read it against the check inventory.

The standing proposal was: *a revision applies to newly registered systems, with
re-review forced on existing ones at the next TA renewal or promotion.* It cannot
be ratified, and the reason is structural rather than a matter of tuning.

`ta-valid` and `promote-or-sunset` run at **G1 only**. A Tactical Authorization
exists for operational-tier systems at C1/C2 and mission-tier systems at C3, and
nowhere else. So "forced at the next TA renewal" reaches roughly a quarter of the
portfolio. Promotion is the other half of the proposal and it is not a scheduled
event — it happens when a system earns a tier, which many never do.

The consequence lands exactly backwards. **G3 is core tier**, the top of the
ladder: no TA, and nothing above it to be promoted into. A core-tier C1 system has
no forcing function under the standing proposal, ever. Core tier is where other
systems inherit controls from — "your blast radius is not your own criticality,"
as the gate profiles section puts it. The systems whose drift matters most to
everyone else were the ones the policy could never touch.

Meanwhile the cost of the gap has been compounding. SA-5.14 at v0.5 gave every
existing system an ecosystem it never declared. SA-5.16 at v0.6 gave a share of
them an inference egress they never declared — one-way, named-approver, in the
short form. Two consecutive revisions have put short-form rows onto systems that
already passed a gate, and the portfolio has no defined moment at which either
becomes owed.

There is a window. v0.5 released 2026-08-05 and v0.6 on 2026-08-08. Any policy
anchored to release dates creates its first deadline in February 2027, so this can
be ratified now without a portfolio-wide blocking event. That stops being true
after another revision or two.

## Decision

**A spine revision does not change what a system owes today. It starts a clock.**
The mechanism is the **adoption horizon**, and it is the waiver instrument the
standard already has, issued automatically.

1. **Which spine version applies is derived, never declared.** It is read from the
   vendored `gate/profiles.json`, whose checksum is in `.causeway-lock`, so it
   cannot move without failing `check-drift.sh`. `system.json`'s `spine.version`
   becomes **`spine.closed_against`** — history, not a claim about what applies.
   A missing value yields **no adoption grace**, the same strictest-default
   reasoning that resolves a missing criticality class to C1, and the correct
   behavior for a newly registered system under the identical rule.
2. **Rows added by a revision enter as findings with a deadline**: the revision's
   release date plus 365 days at C2/C3, 180 at C1, and **180 for any one-way row
   regardless of class**. These are the standard's existing maximum waiver terms,
   reused rather than reinvented. On expiry the row blocks wherever the profile
   already says it blocks — nothing new blocks.
3. **The clock is anchored to the release date**, not the sync date. A
   sync-anchored clock is one a project resets by not syncing, the same property
   that puts `renewal_count` on the TA record rather than on the build.
4. **TA renewal, promotion, and reclassification force adoption immediately.** The
   standing proposal survives as an accelerator; it simply is not the mechanism.
5. **Needing longer is a waiver ADR** — named acceptor, expiry, review trigger —
   superseding the automatic horizon. "No open-ended waivers" now covers version
   drift with no further rule.
6. **A retroactively added one-way row closes on the as-built answer.** For a
   running system the row's value is disclosure, not choice. Where the as-built
   answer declares ongoing unrecoverable exposure, the **ISSM is notified and the
   ADR records a name and a date**, verified by a new blocking check.
   `templates/adr-retroactive-template.md` carries the shape, and Build DNA §8
   carries the rule, since it is ADR discipline rather than a system decision.
7. **The pin-and-never-move bypass is closed.** `check-drift.sh` verifies the
   vendored copy against its own pin and never asks whether the pin is current, so
   without this the horizon has an opt-out consisting of doing nothing. A new
   `RELEASED` file, a `released=` field in `.causeway-lock`, and a
   `standard-currency` check measure the pinned copy's **age**. Age, not distance
   behind current, because age computes with no network and no upstream reference
   — the same constraint that made ADR 0001 reject submodules and package-manager
   distribution.

Three checks land: `adoption-horizon-60d` and `standard-currency` warn-only,
`as-built-notification` blocking. The horizon itself is a **modifier** on the three
existing closure checks rather than a fourth, so a newly-owed row appears once,
in the check that already owns it.

## Alternatives considered

**Keep the standing proposal.** Rejected on the G3 inversion above. It is not a
policy with a gap; it is a policy that systematically exempts the systems with the
largest blast radius. Reading it against `profiles.json` is what settled this, and
it should have happened at v0.4.

**Apply every revision immediately.** Rejected, and the reason is second-order. A
revision that instantly blocks the portfolio makes revising the spine an act of
sabotage, so the spine stops being revised — and a spine nobody dares improve is
worse than one that adopts slowly. The failure mode is invisible because it looks
like stability.

**Grandfather existing systems permanently.** Rejected. It optimizes for exactly
the wrong population. SA-5.16 exists because the failure is unrecoverable, and a
policy under which running systems never answer it means the row protects only the
systems that were never at risk. It also makes portfolio-level statements
impossible — "which spine is this system closed against" would have as many
answers as there are systems.

**Anchor the horizon to the sync date rather than the release date.** Rejected: a
project delays its own deadline by delaying its sync, indefinitely, which is the
bypass wearing a schedule. Release-date anchoring does mean a project that syncs
late gets less than the full window, which is correct — the window is the
portfolio's, not the project's.

**Let the horizon vary by tier as well as class.** Rejected as false precision.
Tier already governs which gate profile runs, and stacking a second axis onto the
horizon produces twelve numbers nobody will remember in place of three that are
already in the document.

**Make `standard-currency` blocking immediately.** Rejected on the
`tests-with-source` precedent. Nobody has counted how many systems are
legitimately frozen — ATO freezes, air-gapped release trains on fixed cadences —
and a blocking check that fires on legitimate work teaches people to route around
the gate. Warn-only, with the promotion decision recorded and dated.

**Let the as-built rule stop at "record it in the ADR."** Rejected. The failure it
is aimed at is a live unrecoverable disclosure written down honestly and then left
in a repository nobody reads. Recording without routing is how that happens, and
the marginal cost of a name and a date is a sentence.

**Fold this into the tests-with-source work.** Rejected on sequencing, not
substance: both extend §7's receipt, and doing them in one pass would produce a
receipt change nobody could review against either decision.

## Consequences

- Every system owes a `spine.closed_against` value, joining the
  `criticality_class` backfill in §9 step 1. It is the cheaper half of that
  backfill — a repository fact readable from the dates in `decisions/`, not a
  judgment requiring a named human — but it is the same sweep and it will be loud
  where it is skipped.
- A C2 system closed against v0.5 now owes SA-5.15 by 2027-08-08 and SA-5.16 by
  2027-02-04. Both are findings today. Nothing blocks today. That pair is the
  worked example in the spine, and February 2027 is the first real test of whether
  a dated finding converts to action before it converts to a block.
- The gate gains three checks and no new blocking behavior for closure — the
  horizon downgrades existing blocks rather than adding one. `rows_in_adoption` is
  deliberately excluded from `rows_closed` so that a receipt cannot report a
  system as complete on the strength of a deadline it has not met.
- `standard-currency` will fail as a **configuration error** on any lock written
  before v1.3.0, because those have no `released=`. The remedy is a re-sync, which
  is the behavior we want from a check about staleness.
- The `RELEASED` file has no automated guard, because this repository still has no
  CI of any kind. `sync.sh` warns best-effort when git is present. That is a real
  weakness in a mechanism about currency and it is recorded as gate open item 6
  rather than papered over.
- Spine open question 3 and gate open item 4 both close. A new spine open question
  asks whether the horizon survives its first expiry, because ratifying it is a
  claim about behavior that has not been tested once.
- Spine v0.7, gate configuration v0.4, standard v1.3.0. No rows added, so no
  system owes anything new *for this revision* — the policy's first application is
  to the two rows that preceded it.

## Evidence

`skills/decision-spine/reference/spine.md` (*Adoption and version drift*, and the
closed open question) · `skills/decision-spine/SKILL.md` step 2 and hard rule 7 ·
`gate/gate-configuration.md` §2, §4 (horizon arithmetic, `standard-currency`,
`as-built-notification`), §6, §7, §8, §9 steps 1/9/10, §10 · `gate/profiles.json` ·
`AGENTS.md` §8 · `templates/adr-retroactive-template.md` · `RELEASED` ·
`tools/sync.sh` · `tools/check-drift.sh` · per-project ADRs closing rows under a
horizon.
