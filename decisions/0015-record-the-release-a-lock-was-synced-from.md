---
adr: "0015"
title: Record in the lock which release a copy was synced from
status: Accepted
date: 2026-08-21
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

`v1.7.0` was tagged on 2026-08-21 — the first release object this repository has
ever had. Before it, a consumer could only pin to a commit on a branch.

Tagging gave projects something to pin *to*. It did not give `sync.sh` any way to
record that it had. The lock reads:

```
version=1.7.0
released=2026-08-10
digest=sha256:dc0f21e9…
commit=905fc88ff44f01b332ecd7ccc0dccb42370479a3
```

Those four lines are identical whether the sync came from the published release
or from an arbitrary branch commit that happens to be the same object. The reader
cannot tell a deliberate pin from an accidental one, and neither can a gate.

This is not hypothetical. While `causeway-se-kit` was being prepared it was
synced from `874271c` — a commit on an unmerged pull request branch. The lock it
produced looked entirely normal. Nothing in the file, and nothing in
`check-drift.sh`, indicated that the pinned standard had never been released. It
was caught by a person remembering, which is the mechanism ADR 0001 exists to
stop relying on.

`digest=` does not close this. It proves the vendored bytes are internally
consistent and identifies which bytes they are. It says nothing about whether
those bytes were ever published, because a digest computed from an unreleased
tree is just as valid a digest.

## Decision

`sync.sh` resolves whether its own checkout is a published release and records
the answer.

`git describe --exact-match --tags HEAD` yields the tag when HEAD *is* that
release. When it does, the lock gains `tag=<name>`. When it does not, the key is
**absent** — never guessed, never derived from `VERSION`. A dirty working tree is
not a release regardless of what HEAD points at, and clears the tag.

Every sync says which case it is. A release prints `release: v1.7.1`. A
non-release prints a warning that the lock will carry a commit with no tag beside
it, and that this is fine for development and wrong for anything that ships.

`--require-release` turns that warning into a hard failure, exit 7, naming
whether the cause was a dirty tree or a detached non-tag HEAD. Anything building
for a real environment should pass it.

`check-drift.sh` skips the new header key and reports the release when the lock
carries one — and reports its *absence* when it does not, because a lock with no
tag is exactly what cannot be recognised by looking.

## Alternatives considered

**Infer the release from `VERSION`.** Rejected. `VERSION` is a file in the tree
that anyone can edit, and the question being asked is whether *this checkout* is
that release. Only a tag answers it, and a lock that asserted `tag=v1.7.1`
because a text file said `1.7.1` would be the most confidently wrong line in the
file.

**Use `git describe` without `--exact-match`.** Rejected, and it is the trap
worth naming. Plain `describe` reports the nearest tag *reachable from* HEAD, so
every commit after a release would report that release. A lock claiming
`tag=v1.7.1` for a commit forty patches later is worse than no tag at all: it
converts an unanswered question into a false answer.

**Fail by default when there is no tag.** Rejected. Development syncs from a
branch are legitimate and constant, and a check that fails on the normal case is
a check somebody disables in a week. The warning is unconditional and the failure
is opt-in, which puts the choice at the call site that knows whether it is
shipping.

**Record a signature rather than a tag.** Not yet possible — no signing key
exists. Deferred rather than rejected; see below.

## Consequences

The lock format gains an optional field. Older `check-drift.sh` copies tolerate
it: an unrecognised `tag=` line parses as a checksum whose filename is empty and
is skipped, so a project on 1.7.0 does not break when a sibling moves to 1.7.1.

`check-drift.sh` is inside the bundle, so the digest moves and this is a release.
Patch, not minor: no row, check, threshold or artifact changed, and the lock
change is additive and backward-compatible. Consumers pick it up on their next
sync, and until then keep working.

**This still does not authenticate anyone.** `tag=` answers "which release is
this", not "who published it". `v1.7.0` and `v1.7.1` are lightweight tags created
through the GitHub UI, carrying no annotation object and no signature. Someone
who can write to this repository can move a tag. Signing, key custody, rotation
and revocation remain open, and this ADR narrows the gap rather than closing it:
the three questions are whether a copy was edited (`check-drift.sh`), which bytes
it is (`digest=`), and whether it was ever released (`tag=`). Who published it is
still unanswered.

## Evidence

`tools/sync.sh` — tag resolution, the unconditional warning, `--require-release`.
`tools/check-drift.sh` — the skipped key, and the report on both branches.
`tools/validate.py` §10 — asserts `check-drift.sh` skips every header key
`sync.sh` writes.

**That guard did not work, and this change found it.** It read
`^\s*echo "([a-z_]+)="`, matching only an `echo` at the start of a line. Three of
the seven keys are written conditionally — `[ -n "$COMMIT" ] && echo
"commit=..."` — so `commit` and `overlay` had been invisible to it since they
were added, and `tag` would have been too. The check reported the two lists
agreeing while silently comparing a subset of one against all of the other: a
guard that could only ever pass. It now scopes to the block that writes the lock
and takes every echoed key in it, conditional or not, and sees all seven.

This is the failure mode the kit's own README names — a check that appears to
pass while measuring the wrong thing — found in the guard this ADR was relying
on. It was caught only because adding `tag=` to `sync.sh` and deliberately *not*
adding it to `check-drift.sh` produced no failure.

Exercised before being trusted: a non-release sync warns and writes no `tag=`; the
same sync under `--require-release` exits 7; a sync from a tagged checkout writes
`tag=` and `check-drift.sh` reports the release; a dirty tree is refused even when
HEAD is at a tag. With §10 widened, removing `tag=` — or `commit=` — from
`check-drift.sh` now fails the build; before the fix, neither did.
