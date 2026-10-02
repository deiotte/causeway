---
adr: "0016"
title: Require status checks rather than approvals while there is one maintainer
status: Accepted
date: 2026-08-21
spine_rows: [SA-1.11]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

ADR 0014 recorded an open item: `main` was unprotected, no status check was
required to merge, and a red gate stopped nothing. Run `31402595407` failed
against `c46cca4` on 2026-08-10 and `main` stayed red until PR #11 repaired it
four days later.

Branch protection was enabled on 2026-08-21. The first pull request to meet it —
PR #13, the v1.7.1 release — went green on all three CI jobs and sat at
`mergeable_state: blocked`, waiting for an approving review that was never going
to arrive.

**GitHub does not permit the author of a pull request to approve it.** This
repository has exactly one collaborator, `deiotte`, with the admin role. Every
pull request here is authored by the only person who could approve one. A
required-approvals rule is therefore unsatisfiable by construction, not
occasionally but always.

Two review submissions were made on PR #13, bodies "Approved" and "OK". Both
recorded as `COMMENTED`, because `APPROVE` was not an option the interface
offered. The rule was not bent; it simply could not be met.

PR #13 was then merged **by admin bypass**. That is the fact this ADR exists to
respond to. The first merge under the new protection was a bypass of it, on day
one, by the person who enabled it — and every subsequent pull request would have
been the same. A control whose normal operation is an override is not a control.
Worse, it is corrosive: the habit it builds is clicking through protection, which
is the same reflex that produced the `Add files via upload` commit on `main` that
ADR 0014 was written about.

The two settings are independent and only one of them was ever load-bearing here.
Required approvals asks whether a second person looked. Required status checks
asks whether the gate passed. With one maintainer the first question has no
possible answer and the second has a precise one.

## Decision

While this repository has a single maintainer, `main` is protected by **required
status checks and a required pull request, with required approvals set to zero**.

The ruleset requires:

| Setting | Value |
|---|---|
| Require a pull request before merging | on |
| Required approvals | **0** |
| Require status checks to pass | on |
| — `Tie the standard to itself` | required |
| — `A synced project passes drift detection` | required |
| — `Overlays vendor and lock` | required |
| Block force pushes | on |

Every change still arrives as a pull request, so the diff and its rationale exist
and are reviewable after the fact. What no longer happens is a rule being
overridden on every merge to achieve that.

**Approvals are reinstated the moment a second person holds write access.** That
is the trigger, and it is written here rather than left to be noticed: at one
maintainer the requirement is unsatisfiable, and at two it is the thing that stops
either of them self-merging. The setting is wrong in exactly one configuration and
right on both sides of it.

## Alternatives considered

**Keep required approvals and bypass each time.** Rejected, and it is the status
quo this ADR ends. It produces a repository whose protection is defeated by its
owner on every change, and an audit trail in which every merge is an exception.
The rule would be documentation of an intention, not a constraint.

**Create a second account to approve.** Rejected. It satisfies the letter of the
rule with a party that reviews nothing. A second approver who is the first person
wearing a different hat is worse than no approver, because it produces an approval
record that a reader would reasonably believe.

**Leave PRs blocked until a second maintainer exists.** Rejected. Releases stop,
and the pressure to bypass grows rather than disappears.

**Turn protection off entirely and rely on care.** Rejected outright. That is
precisely the state ADR 0014 recorded as the open item, and it is what let `main`
stay red for four days.

## Consequences

ADR 0014's open item is closed by the required-checks half of this decision: a
red gate now blocks a merge. That is the property that was missing, and it never
depended on approvals.

Single-maintainer risk is unchanged and unmitigated by this ADR. Nobody reviews
this repository's changes before they land. Required status checks verify that the
standard ties to itself; they do not verify that a decision was a good one. That
gap closes by adding a maintainer, not by configuring anything, and it is the
strongest argument for moving this repository under a durable organization rather
than a personal account.

The bypass on PR #13 stands in the history. It is recorded here rather than
quietly left behind, because a repository claiming to be a document of record does
not get to omit the one merge that went around its own gate.

## Evidence

`.github/workflows/standard.yml` — the three jobs by the names the ruleset
selects them under.

**Required approvals — confirmed 0, by observation, 2026-08-21.** PR #14 reports
`mergeable_state: clean` while carrying zero approving reviews. PR #13, one hour
earlier, reported `blocked` in the same condition. A pull request with no approval
cannot be clean under a rule requiring one, so the approvals half of this decision
is in force.

**Required status checks — confirmed 2026-08-22.** All three checks are listed by
the names in the table above. **ADR 0014's open item is closed:** a red gate now
blocks a merge to `main`.

The confirmation was made by a person reading Settings → Rules, and could not have
been made any other way. Observation from outside cannot settle it — a pull
request whose checks have already passed reports `clean` whether or not those
checks are required, so the two configurations are indistinguishable until one of
them fails.

This section was written with the slot left open and is filled rather than
rewritten. The ADR stated the verification as owed; recording that it happened
completes a record its author declared incomplete, which is not the same act as
revising a decision, and is not a precedent for editing an accepted ADR whose
evidence has merely gone stale.

That this cannot be checked from inside the repository remains the finding, and
closing the item does not close the gap. The ruleset lives in GitHub settings,
outside the tree, where no assertion in `validate.py` can reach it. Every other
claim this repository makes about itself is enforced by something; this one rests
on a person having looked, once, on a date. Nothing detects it being turned off.
