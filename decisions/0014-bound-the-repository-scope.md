---
adr: "0014"
title: Bound the repository to the process layer, and enforce that boundary in CI
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

On 2026-08-21 a systems engineering kit — sixteen files, Python and JavaScript
source, a `package.json` with a floating `^9.0.0` dependency, no lockfile and no
tests — was committed to this repository directly on `main` through a web upload,
without a pull request. `VERSION`, `RELEASED`, `bundle/manifest.json`, the README
and the CI scope were all unchanged. It was reverted in `893f708`.

Two separate things went wrong, and only one of them is about the kit.

**The kit is a different product at a different layer.** Causeway governs how a
product repository is built and decided about. The kit governs the documents a
program owes a customer: it generates deliverables from a fact model. Its
consumers are program repositories, its release cadence is its own, and its
`README` already described itself as a member of a family rather than a part of
this repository. Landing it here made this repository two products wearing one
version number.

**Nothing here could have caught it, and that is the larger finding.** CI reported
green, and CI was not wrong — nothing asked it the question.
`tools/build-bundle.sh` digests an explicit `BUNDLE_FILES` allowlist.
`tools/validate.py` globbed `decisions/` and `overlays/` and read a fixed set of
named artifacts. No guard in this repository had ever enumerated the working tree,
so a new top-level directory was invisible by construction. The standard that
blocks a product repository for shipping source without a lockfile had done
exactly that to itself, and its own gate had no opinion.

It was first supposed that the workflow might not have executed at all — that
the account's CI allowance for the month was exhausted. The run history says
otherwise, and the record should be exact: workflow run `32481170683` executed
against `133a791` at 12:17:20Z on 2026-08-21 and completed `success` in eleven
seconds. **The gate ran, and passing was the wrong answer.** That is the more
damning version of the same finding and the one worth keeping — a gate that
does not run announces itself eventually, while a gate that runs and approves is
trusted.

## Decision

This repository is the process layer, and only the process layer. The systems
engineering kit becomes **`causeway-se-kit`**, a sibling repository, vendored into
program repositories under `vendor/se-kit/` and pinned by a `kit.lock` — the same
relationship product repositories already have with this standard.

Repository scope stops being an implicit property of the code that happens to
enumerate files. Every tracked path must now be either digested by
`bundle/manifest.json` or declared in **`bundle/scope.json`** with a written
reason it is not part of the standard. `tools/validate.py` §11 fails on any path
governed by neither, rejects a catch-all pattern, rejects an exemption with no
reason, and reports a declared pattern that has stopped matching anything. §11
also holds the README's repository map to the tree: every path it names must
exist, and every tracked top-level directory must appear in it.

The bundle digest is unchanged by this ADR. Scope declaration and validation are
governance machinery, not standard content, so nothing a consumer vendors moved
and no version bump is owed.

## Alternatives considered

**Incorporate the kit here — version it, test it, bundle it.** Rejected. It would
put program-deliverable machinery under the standard's digest, so every kit fix
would move the standard's version and every consumer would see drift in content
they never vendored. The two artifacts have different consumers and different
cadences; one digest cannot serve both honestly.

**Leave scope implicit and rely on review.** Rejected — this is the status quo,
and it is what failed. The kit passed through a review that did not look for a
question nobody had asked yet.

**Enforce with a denylist — ignore known-bad paths.** Rejected. A denylist
enumerates what someone already thought to forbid, and the thing that got in was
precisely the thing nobody thought of. An allowlist plus declared exemptions
inverts the default: the unanticipated case fails closed.

**Bundle everything tracked.** Rejected. ADRs, conformance fixtures, the
validator and the CI workflow are this repository's own apparatus, not text a
consumer inherits. Digesting them would make the standard's identity change every
time its governance did.

## Consequences

Adding a directory now costs a `scope.json` entry with a reason a reviewer can
evaluate, which is the intended friction. The README map is load-bearing rather
than decorative, so it cannot rot silently again.

The Causeway family is now explicitly multi-repository, which makes the owning
organization load-bearing: a program repository's `kit.lock` names the source it
pins, and that name cannot stay a placeholder. Choosing the organization is now a
prerequisite to the kit's first tag, not a cosmetic question.

**Open item — CI runs but does not block.** `main` is unprotected and no status
check is required to merge, so a red gate stops nothing. This is not
hypothetical: run `31402595407` failed against `c46cca4` on 2026-08-10 and
`main` stayed red until PR #11 repaired it on 2026-08-14, four days later. The
scope check does not help here. It guarantees that when the gate runs the tree
is enumerated; it cannot make anyone wait for the answer. Branch protection
requiring the full suite is the fix, and it is governance rather than code.

## Evidence

`bundle/scope.json` — eleven declared exemptions, each with a reason.
`tools/validate.py` §11 — the scope and README-map guards.

Both were made to fail before being trusted. Replaying the original failure —
`systems_engineering/package.json` plus a source file, staged — fails
`every tracked file is bundled or declared ungoverned`. A `**` pattern fails
`no ungoverned pattern is a catch-all`. Restoring `adrs/` to the README map fails
both `every path in the README repository map exists` and `every tracked
top-level directory appears in the README map`.
