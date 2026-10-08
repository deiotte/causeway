---
adr: "0044"
title: Publish only what was verified, all at once, and withdraw on failure
status: Accepted
date: 2026-10-08
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A release is published that a consumer cannot install with --require-release,
  or a release fails for a reason this workflow should have tolerated. The first means
  a gate is missing; the second means one is wrong.
approver:
  name: Karl Deiotte
  role: Maintainer
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

The release workflow signed a tagged commit, verified the signature, built the
archive, checked it rebuilt byte for byte, and attached everything to the GitHub
release. The archive steps — build, reproducibility, upload — carried
`if: '!cancelled()'`. That condition means "run unless the run was cancelled",
including after a failure. Issue #13 read it from the source: a release whose
signature did not verify, or whose archive did not reproduce, could still have its
archive attached. ADR 0040 already records one signing attempt whose attached archives
had to be withdrawn by hand.

Three more gaps sat beside it:

- **Missing signing prerequisites produced a warning,** and the run went on to publish
  an unsigned archive as the release. The summary said it was unsigned; the release
  page did not.
- **The statement and the archives were uploaded in separate steps,** to a release the
  maintainer usually creates from the web interface before the workflow runs (ADR
  0016). Each upload was visible as it landed, and a failure between them left a
  half-filled release on show.
- **The artifact a consumer downloads was never installed before it shipped.** Standard
  CI installs an *unsigned* archive without `--require-release`; the release workflow
  verifies the statement but never extracts the signed archive and installs from it.
  The combination is the path the README tells consumers to use.

The workflow is the control here, and nothing runs it before a tag is pushed. A defect
in it is found on a release day, in public.

## Forces

- **A failure has to stop everything downstream.** That is the default in GitHub
  Actions, and the workflow had opted out of it for the steps that publish.
- **Release day is the worst time to discover a broken gate.** Anything the release
  relies on has to run on every pull request, against something shaped like a signed
  release, without the real key.
- **The bytes tested must be the bytes shipped.** A test of one build followed by
  publication of another proves nothing about the second.
- **A maintainer publishes from the web.** The release often exists, and is visible,
  before any verification has run. "Do not publish" is not enough: a failed run must
  also un-publish what is already showing.
- **The key never leaves its step.** Nothing added here may read or print it.

## Decision

**Every step runs only if every step before it succeeded.** No `!cancelled()` and no
`always()`. The order is:

1. The tag names `v$VERSION`, and the run is on a tag at all.
2. The source validates on the tagged commit: `validate.py`, `build-bundle.sh --check`,
   `render-adapters.sh`, `test-sync.sh`, `test-release-archive.sh --throwaway`,
   `test-publish-release.sh`.
3. The signing prerequisites exist. If not, the run **fails** with the setup steps in
   its summary. There is no unsigned official release.
4. Sign; verify with the consumer's verifier.
5. Build the archive; rebuild it and require identical bytes.
6. **Install the archive as a consumer would** — `tools/test-release-archive.sh
   --dist dist`, below.
7. **Publish** — `tools/publish-release.sh`, below.
8. On any failure, and only then: **withdraw** — `tools/publish-release.sh --withdraw`.

**`tools/test-release-archive.sh`** checks the release set is complete and matches its
checksums, the `.tar.gz` and `.zip` hold the same files and the zip keeps the installer
executable, the archive carries a statement signing `v$VERSION`, and then installs it
into an empty project with git hidden from `PATH` and `--require-release`. The lock must
record `release_proof=signed-statement` and the statement's tag and digest, and the
project must pass `check-drift.sh` and `verify-release.sh`. Then three copies are
refused with exit `7` and nothing written: an altered statement, altered content
beside the genuine signature, and no `ssh-keygen`. On success it writes
`dist/.accepted`, the sha256 of the tarball that passed. `--throwaway` runs the same
checks on this checkout signed with a key generated and discarded for the run
(`tools/lib-throwaway-release.sh`).

**`tools/publish-release.sh`** is the only thing that changes a release. Before it
contacts GitHub at all it requires: the tag is `v$VERSION`; all six assets exist; the
statement verifies and signs this tag and version; both archives match their checksums;
the statement inside the tarball is byte-identical to the one being published, so the
archive was built after signing; and `.accepted` names this tarball. Any failure exits
`3` with GitHub untouched. Then the release is made a draft — created as one, or turned
back into one if it was published from the web — all six assets are uploaded in one
call, and only then is it published. A GitHub failure partway exits `4` and leaves a
draft. `--withdraw` turns a published release into a draft and uploads nothing.

**`validate.py` §21 guards the workflow's shape:** the only step condition that
overrides success is the withdrawal's `failure()`, no `gh release` command appears in
the workflow outside the publisher, and the gates appear in the order above.

**`tools/test-publish-release.sh`** runs the publisher against a stub `gh` that
records every call and keeps a release state. Standard CI runs it, and the archive test
with `--throwaway`, on every pull request.

## Alternatives considered

- **Delete `!cancelled()` and stop there.** Fixes the reported path. Leaves an unsigned
  release possible, a partial upload visible, and the shipped artifact uninstalled.
- **Split into jobs with `needs:`.** The same ordering at three times the billed
  minutes (ADR 0018), and artifacts would have to cross job boundaries, which is one
  more place the tested bytes and the shipped bytes could part.
- **Never touch a release that already exists; fail instead.** The maintainer's web
  flow creates the release first, so every release would fail. Hiding it as a draft
  while assets change is what that flow needs.
- **Delete a release after a failure.** Deletes the maintainer's notes and, with
  GitHub's defaults, can delete the tag. A draft is invisible and recoverable.
- **Test the workflow by running it.** Only possible by pushing tags. The static guard
  plus a stubbed publisher covers its decisions without publishing anything.

## Consequences

A release either appears complete and verified, or it does not appear. A run that fails
for any reason — missing key, bad signature, unreproducible archive, failed install —
publishes nothing, and hides a release that was already visible.

Releases get slower by the length of the source gate and the two archive tests, about a
minute. Pull requests get two more steps of a few seconds each.

A maintainer who creates a release from the web will see it go to draft briefly while
assets upload, then return. If the run fails, it stays a draft, and the run summary says
why.

**What this does not do.** It does not change who holds the key or how it is rotated;
that is issue #4. It does not authenticate the archive's checksum sidecars, which are
unsigned; the signature inside the archive covers the bundle, and the installer
re-checks content against it (ADR 0042). And it cannot prove the workflow's own YAML
behaves as written on GitHub: the static guard checks its shape, the stub checks the
publisher's decisions, and the first real release under this workflow is the first end
to end run.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-release-archive.sh --throwaway`: 13 passed. Against an unsigned archive
  built from the checkout: 6 failed, and no `.accepted` written.
- `tools/test-publish-release.sh`: 12 passed — draft-then-publish for a new release and
  for one published from the web, a failed upload left a draft, seven bad inputs each
  refused with zero `gh` calls (each for its own stated reason), withdraw on a
  published release and on none.
- `validate.py` §21 passes on the new workflow, and fails all four of its checks on the
  previous one.
