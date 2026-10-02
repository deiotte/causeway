---
adr: "0010"
title: The standard runs its own gate
status: Accepted
date: 2026-08-09
spine_rows: [SA-8.3]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

This repository ships a standard whose central claim is that guidance without
enforcement rots. It had no enforcement of its own. No `.github` directory, no
workflow, nothing running `check-drift.sh` or `render-adapters.sh` or anything
else, on any push, ever.

`gate-configuration.md` §10 item 6 named the gap and named it as upstream of
several others:

> The real fix is a release check in the standard's own CI, and **this repository
> has no CI at all** — no workflows, nothing running `check-drift.sh` or anything
> else. That gap is upstream of this item and of several others.

It was right about how much depended on it. Item 6 is `RELEASED` having no guard,
which matters because `standard-currency` measures every consuming project's
staleness against a date nothing verified. `sync.sh` warns best-effort when git
is available, covering a developer running it from a clone and covering nothing in
a tarball mirror.

Two more things were only ever verified by hand. `sync.sh` and `check-drift.sh`
are the entire distribution mechanism, and ADR 0001 exists because a copy of this
standard went missing — yet neither script had been executed by anything but a
person at a keyboard. And the drift that ADR 0008 corrected sat in three files
across several revisions, which is exactly the failure a validator catches on the
push that introduces it.

## Decision

The standard runs its own gate on every push, in three jobs.

**Tie-out.** `tools/validate.py` asserts the standard is consistent with itself:
`profiles.json` and `checks.json` name the same 27 checks, the §4 prose table has
27 rows, modifiers and input classes and waiver forms resolve, the composition
vocabulary agrees across `AGENTS.md`, the spine and `checks.json`, the version
chain agrees across five files, spine row counts match the header's claim, every
cited spine row exists, ADR frontmatter is well-formed and numbered to match its
filename, and the conformance fixtures agree with their expectations. Then
`build-bundle.sh --check` asserts the committed manifest is current, and
`render-adapters.sh` asserts the shims still point at `AGENTS.md`.

**Sync round-trip.** Syncs into a scratch project, verifies the lock carries a
digest and a released date, verifies the digest matches what the bundle published,
and runs `check-drift.sh` against the fresh copy. Then it edits a vendored file
and asserts `check-drift.sh` **fails** — a check that never fails is decorative,
and that rule applies to the scripts enforcing the standard as much as to the
checks inside it.

**Overlay round-trip.** Every overlay vendors, is recorded in the lock, and
survives drift detection.

`RELEASED` is guarded inside the tie-out job: the workflow checks out full history
so `validate.py` can compare `RELEASED` against the last commit that touched
`VERSION`. That closes item 6.

Actions are pinned to commit SHAs. A repository whose `dependency-provenance`
check blocks at every profile does not get to resolve its own supply chain from a
moveable tag.

## Alternatives considered

**A release-time check only.** Item 6 asked for a release check, and that would
have closed it literally. Rejected: `RELEASED` is one of several things nothing
verified, and a workflow that runs only at release finds the other drift after it
has been merged. Per-push is barely more expensive and catches things while the
author is still holding the context.

**Reuse `check-drift.sh` as the validator.** Rejected on a real constraint. That
script runs in *consumers'* CI, in whatever environment they have, and its value
comes from being pure shell with no dependencies. The tie-out needs JSON parsing
and structural comparison. Keeping them separate lets the consumer-facing script
stay dependency-free and lets the internal one assume python3 — different
audiences, different constraints, and merging them would compromise both.

**Require the validator as a pre-commit hook instead.** Rejected. A hook is
advisory by construction: it runs on machines that installed it. The standard's
own §9 rolls out checks by making them blocking, and a repository that recommends
that pattern to others while relying on the honour system locally is making the
argument against itself.

## Consequences

Item 6 closes, and with it the reason it was flagged as upstream of others.

The ADR 0008 class of drift cannot recur silently. `validate.py` asserts the
composition vocabulary agrees across all three files on every push, and reverting
the fix fails CI with both value sets printed.

The distribution mechanism is now exercised on every push, including its negative
case. `check-drift.sh` demonstrably fails an edited copy rather than being
believed to.

CI is now a dependency of contributing. A change to `VERSION` without `RELEASED`,
a check added to `profiles.json` without a specification, a fixture without an
expectation, or an ADR whose frontmatter number disagrees with its filename will
fail the build. All four are the intended behavior and all four will annoy
somebody, probably the author of this ADR, probably within a month.

The repository now has a workflow file, which is the first thing here that is not
either prose or a POSIX script. It is the smallest possible one and it should stay
that way: the moment CI grows logic of its own, the logic belongs in `tools/` where
it can be run by hand.
