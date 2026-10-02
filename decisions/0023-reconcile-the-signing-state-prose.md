---
adr: "0023"
title: Reconcile the signing-state prose, and guard the claim against the artifact
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

ADR 0019 issued the release signing key at v1.8.0. Releases have carried a
`release.statement` signed with SSH over the bundle digest since, and
`bundle/allowed-signers` is the vendored trust anchor, itself inside the digest
so it cannot be swapped without moving it.

Two documents never learned that.

`tools/sync.sh` explained why the anchor is appended conditionally:

> Appended conditionally rather than listed in VENDORED above, because it does
> not exist yet: no signing key has been issued, so no release is signed.

`gate/gate-configuration.md` open item 10 listed what closing it would need —
"a signature over the digest, which needs a key, a holder, a rotation policy and
a revocation story" — and then said **none of which exist**.

Both sentences were true when written. Neither was true at v1.8.0, and both
shipped in every release since — `gate-configuration.md` inside the digested
bundle, so every consuming project vendored a document telling it the standard
does not sign its releases while `tools/verify-release.sh` and a trust anchor sat
in the same copy.

The README carried this as credibility gap #2: *the executable behavior is
current; the narrative contract is not fully reconciled.* Its development
priority #2 asked for two things — fix the prose, and **add validation that
signing-state claims agree with the presence of the trust anchor**. This ADR
does both, because doing only the first is how the gap opened.

Nothing pointed from the fact to the sentences. `validate.py` §13 already had
four guards on the signing *mechanism* — namespace agreement, field agreement,
format-tag agreement, and the anchor being vendored and digested together. Every
one of them checks that the machinery is wired consistently. None of them read a
word of the prose describing it, so the machinery could be turned on without a
single check noticing that four documents still said it was off.

## Decision

Correct both documents, and add a fifth guard that binds signing-state prose to
the signing state.

**`tools/sync.sh`.** The conditional append stays; its justification changes.
The condition is no longer *not issued yet* — it is a checkout that does not have
the file, which a consumer reaches by syncing from a tag cut before v1.8.0. The
warning now says that, and says what to do about it.

**`gate/gate-configuration.md` open item 10.** Half-closed in place, keeping its
number per the rule §10 states for itself. The signature and the key exist and
the item says so; the rotation policy and the revocation story do not, and no
gate requires a consumer to verify, so the item stays open on that half. The
gate configuration version does **not** move: nothing normative changed, and a
version that moves for a status correction empties the field — ADR 0012's
reasoning applied to this document. Moving it would also force a re-ratification
of the ServiceNow overlay, which is a real cost for a note.

**`validate.py` §13 guard (e).** When `bundle/allowed-signers` exists, no scanned
document may assert that signing is unissued. When it does not exist, `sync.sh`
must tell the consumer.

Matching is windowed rather than literal, in the ADR 0020 sense: an "unissued"
phrase counts only when signing vocabulary sits within 240 characters, so the
patterns stay short without firing on unrelated prose. `validate.py` is not
scanned — the patterns live there and it would match its own literals.

## Alternatives considered

**Fix the prose and skip the guard.** What the title of this work implied, and
rejected because it is the status quo that produced the defect. The sentences
were written correctly and went stale silently; correcting them without adding
the pointer leaves the next reader to notice by reading carefully, which is what
did not happen for two releases. The repository's own development priority asked
for the guard by name.

**Drop the conditional in `sync.sh` and vendor the anchor unconditionally.**
Tempting, since the file now always exists in this repository. Rejected: a
consumer syncing from a pre-v1.8.0 tag has no anchor, and warning-and-continuing
is the right behavior there — the copy is unverifiable, not broken, and
`check-drift.sh` still covers everything else in it. It would also break guard
(d)'s `VENDORED+=` regex and turn a defensive branch into a hard failure for the
one case it exists to handle.

**Bump the gate configuration to v0.7.** The consistent-looking option, and
rejected on cost against meaning. No check, threshold, profile, input class or
receipt field changed; a reader diffing v0.6 against v0.7 would find a status
note. It would also fail the ServiceNow overlay's ratification guard and demand
a reconciliation pass to record that nothing moved.

**Make the guard exhaustive rather than heuristic.** Rejected as not available.
There is no closed vocabulary for "this text asserts signing is unissued", and a
guard that waits for one ships never. The pattern set catches the shape that has
actually recurred and the ADR records that it will miss a claim worded outside
it — which is the declared-gap posture Build DNA §8 now requires rather than a
weakness to hide.

## Consequences

The signing story is the same in the executable behavior and in the prose that
describes it, in every document a consumer vendors.

Turning signing off again — a revoked key, a withdrawn anchor — now fails the
build until the prose is updated to match, in both directions. That is the
intended friction and it is small: the failure names the document and quotes the
sentence.

Guard (e) is a heuristic and will miss an unissued claim phrased outside
`UNISSUED_CLAIM`. Adding a pattern is the intended response, the same way adding
an anchor is the intended response in ADR 0020's `PROSE_COUNTS`. A future reader
should read a loosened pattern set as a weakened guard.

Rotation, revocation and compromise recovery remain unresolved, and no gate
requires a consumer to verify a signature. This ADR does not touch any of that;
it makes the documents stop claiming otherwise in the other direction. Gate
configuration open item 10 and README limit #6 both still stand on that half.

`gate/gate-configuration.md` is inside the digested bundle, so this is a release:
v1.9.1, patch. No consumer owes anything new.

## Evidence

`tools/sync.sh` lines 99–118. `gate/gate-configuration.md` §10 item 10.
`tools/validate.py` §13 guard (e), and guard (d)'s corrected opening comment.

`./tools/validate.py` — 506 passed.

The guard was deliberately made to fail, three ways:

| Mutation | Result |
|---|---|
| Restore `sync.sh`'s "no signing key has been issued" | `FAIL  no document claims signing is unissued while the trust anchor exists` — quotes the sentence |
| Restore item 10's "none of which exist" | same check, naming `gate/gate-configuration.md` |
| Remove the anchor **and** `sync.sh`'s warning | `FAIL  sync.sh tells a consumer when there is no trust anchor to vendor` |

The third mutation also found a defect in the guard's own first draft: the
anchor-absent branch reused the unissued-claim predicate, which answers a
different question and reported `sync.sh` as silent while it was warning
correctly. It now checks `sync.sh`'s own warning. Seventh time a check in this
repository has been found reading characters instead of meaning.
