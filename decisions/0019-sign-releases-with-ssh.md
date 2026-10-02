---
adr: "0019"
title: Sign releases with SSH, and make the digest something a consumer verifies
status: Accepted
date: 2026-08-24
spine_rows: [SA-5.7]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

Since v1.6.0 `sync.sh` has written a bundle digest into every `.causeway-lock`,
and its own comment has said what that digest was for:

> The per-file checksums below prove the vendored copy is internally consistent —
> that nobody edited it locally — and they cannot prove it came from us, because
> a local recalculation is exactly what an edited copy would also produce. The
> digest is the value an engine checks against a published release.

No engine checked it against anything. `check-drift.sh` read `digest=` out of the
lock and printed it. `sync.sh` had read the same value out of
`bundle/manifest.json` moments earlier and copied it across. Nothing recomputed
it, and there was no published release to compare it to. **The one value in the
lock whose purpose was to answer "is this copy ours" was decorative**, and the
comment describing its purpose was, read strictly, a description of an intention.

That is the same failure this repository has now found four times — a check
positioned next to the question that matters, answering an adjacent one. It is
worth naming precisely here because it is why this ADR does two things instead of
one.

A signature over the digest would have been theatre on its own. A consumer that
never derives the digest from its own bytes and then verifies a signature over it
has verified a number against a number, both taken on trust from the same copy.
The signature is only load-bearing if the digest is.

**The consumer of record shapes the mechanism.** The first program to adopt this
delivers from a government-owned Azure DevOps instance. Egress to a public
transparency log is not a safe assumption there, and neither is a `gh` binary or
a GitHub API reachable from the build. Whatever verifies a release has to work
with the files at hand.

**The maintainer's situation shapes it too.** ADR 0016 records a single
maintainer with admin on a personal account; that maintainer keeps no local git
checkout and publishes tags through the GitHub web interface. A scheme requiring
`git tag -s` from a workstation would not be used, and a signing story nobody
performs is worse than an absent one because the record implies otherwise.

## Decision

Two changes, and the first is the prerequisite for the second.

**The digest becomes load-bearing.** `check-drift.sh` recomputes the bundle
digest from the vendored `bundle/manifest.json` — the digest is a sha256 over
sorted `"<sum>  <path>"` lines and the manifest carries exactly those pairs — and
fails if it does not match the manifest's own claim or the lock's. Every bundle
file present in the project is then hashed against its manifest entry. `VERSION`
and `RELEASED` are never vendored, but the lock records their exact contents in
its header, so they are rebuilt from it and checked too: **22 of 22 covered, not
20.** Provenance failure exits **8**, distinct from drift's 5, because a copy
whose bytes are clean and whose manifest disagrees has a different problem from
one somebody edited.

**Releases are signed with SSH.** A tag-triggered workflow runs
`tools/sign-release.sh`, which refuses a dirty tree, a stale manifest, or a HEAD
that is not exactly at a tag, and emits a six-line statement binding version,
release date, digest, commit and tag — signed with `ssh-keygen -Y sign` under the
namespace `causeway-release`. The statement and its detached signature are
attached to the GitHub release. `tools/verify-release.sh` verifies them against
`bundle/allowed-signers`, which is vendored into consumers and covered by the
bundle digest.

`ssh-keygen -Y verify` needs one file of trusted keys. No keyring, no agent, no
network, no log. That is the property the ADO consumer needs and it is the
reason for the choice.

The verifier does not stop at "the signature is genuine". A valid signature over
a *different* release verifies exactly as well, so the statement's digest is
compared to the local manifest and the lock, and its tag to the lock's tag. A
lock with no `tag=` fails: a release signature cannot describe a copy that was
never synced from a release, however well it verifies.

**Signing is specified and not yet in force.** No key has been issued, so
`bundle/allowed-signers` does not exist, no release is signed, and every path
says so out loud — `sync.sh` on each sync, `verify-release.sh` on each run, the
release workflow in its job summary. Turning it on is two coupled acts: put the
private half in the `CAUSEWAY_RELEASE_KEY` secret, commit the public half and add
it to `BUNDLE_FILES`. `validate.py` fails if one is done without the other,
because a trust anchor that can be swapped without moving the digest is not an
anchor.

## Alternatives considered

**Sigstore keyless signing.** The strongest argument against every scheme here is
that a private key exists at all, and keyless removes it: the identity is the
workflow, and there is nothing to custody, rotate or lose. Rejected on the
consumer, not on the merits. Verification wants Fulcio and Rekor reachable,
cosign becomes a dependency for every consuming build, and Rekor entries are
public — which, while both repositories are private, would publish repository
identity and content digests. Revisit if the ADO consumer turns out to have
egress, because on custody grounds it is the better scheme.

**GitHub-native build attestations.** Least setup and Sigstore-backed, but
verification runs through the `gh` CLI against the GitHub API, which is the
assumption the ADO consumer cannot make.

**Signed git tags.** The traditional answer, rejected on the maintainer's actual
workflow: it needs both a held key and a local checkout, and there is neither.
It also verifies a commit rather than a content digest, so a consumer would still
need a clone to check anything.

**GPG instead of SSH.** Same trust model, more moving parts — keyrings, trustdb,
expiry, an agent — none of which the verification needs. `ssh-keygen` is present
wherever git is.

**Do the digest verification and skip signing.** Genuinely tempting, because the
digest work closes the larger practical gap and costs nothing. Rejected because
it leaves the chain rooted in "whatever `sync.sh` copied": recomputation catches
accidents and careless edits, and cannot catch a self-consistent forgery, since
anyone who can rewrite the files can rewrite the manifest.

## Consequences

**SA-5.7 reopens for this repository.** The kit's ADR 0004 discharged key custody
with "no key to custody"; that answer is no longer available here. The row is
cited above because this decision creates the obligation, and the obligation is
not discharged by this ADR: **there is no rotation procedure, no revocation
path, and no answer for a compromised key.** A `causeway-release-v1` statement
carries no expiry and `allowed-signers` supports validity windows that are not
used. Naming this is not the same as solving it.

**The key sits inside the boundary it protects.** In an Actions secret, anyone
who can land a workflow change on `main` can sign as this key, and so can GitHub.
Against the threat of a tampered vendored copy in a consumer's tree this is a
real improvement; against a compromised repository it is not, and it should not
be described as if it were. Protected `main` plus required checks (ADR 0016, ADR
0018) is what stands between the two, which makes the ruleset load-bearing for
signing as well as for merging.

**A consumer can verify offline, and mostly will not.** The verifier is vendored
and the anchor travels with it, but fetching the two release assets is a manual
step nothing enforces. Nothing in the gate yet requires a verified signature, so
the practical state is: available, documented, unenforced. That is a deliberate
stopping point — requiring it before any release is signed would block every
consumer — and it is the next thing to close.

**The bundle digest now moves when the anchor rotates.** Correct, and worth
stating: rotating the signing key is a release of the standard, not a settings
change.

## Evidence

**Verified end-to-end against a throwaway ed25519 key, 2026-08-24**, in a clean
tagged clone at `v1.8.0` — signed, then verified from a project synced with
`--require-release`.

Six negative cases, each confirmed to fail:

| Case | Result |
|---|---|
| statement's digest altered after signing | signature does not verify |
| re-signed by a key absent from `allowed-signers` | no matching principal |
| genuine key, signature made under another namespace | does not verify |
| `allowed-signers` present but containing no keys | refuses rather than trusting nothing |
| genuine signature over a **different** release | digest mismatch against manifest and lock |
| vendored file and its lock checksum both rewritten | **exit 8** — the case the old check passed |

That last row is the one that matters. Before this change, editing a vendored
file and its checksum in the lock produced a clean `check-drift.sh` run.

Six new assertions in `validate.py` §13 cover the couplings a test would not
reach until the day of a real release: namespace agreement between signer and
verifier, statement format tag, that the verifier reads only fields the signer
writes, that `check-drift.sh`'s sed parses the manifest to exactly what a JSON
parser sees, and both halves of the activation invariant. **Each was mutation-
tested and confirmed to fail when broken.** One of them did not, at first: the
anchor guard read the *manifest* — an output of `BUNDLE_FILES` — so a file
declared but absent could never appear in it, and the check could only ever pass.
It now reads the declaration in `build-bundle.sh`. That is the fifth instance in
this repository of a check measuring the thing next to the one that matters, and
it was found by insisting every new guard demonstrate a failure before being
trusted.

**A key was issued and the first release is signed, 2026-08-24.** The paragraph
this replaces said no key existed, that everything above had been proved with a
throwaway, and that it would be wrong to leave as-is once a real key arrived. It
is filled rather than rewritten, on the precedent ADR 0016 set: recording that
something the ADR declared owed has happened completes a record its author
marked incomplete, which is not the same act as revising an accepted decision.
The decision itself is unchanged.

`bundle/allowed-signers` carries one ed25519 key,
`SHA256:EbUs+x+IdYqz4zbWZn2Ct098YN6XUNAaiRD8lDuYFIk`, under the principal
`release@causeway`. The private half is in the `CAUSEWAY_RELEASE_KEY` Actions
secret and has never been in this tree.

**v1.8.0 is the first signed release.** Run `32740704542`, tag `v1.8.0`, commit
`4306e62f`. The workflow signed, then ran `verify-release.sh` against the
committed anchor before publishing anything, and reported `signer
release@causeway`, `manifest agrees`, `verified`. Both assets were then attached
by `github-actions[bot]`.

That self-verification is the workflow checking its own output, so two
independent confirmations were taken:

**The signed content is right.** The statement was rebuilt from the `v1.8.0` tag
alone — version, released, digest, commit, tag, in the fixed field order — and
hashed to `sha256:8e2fdb2f90fa6bd21267ac75ceb7b068d0eef108885dfbc07f741b0a6c365a07`
at 192 bytes, matching the digest and size GitHub reports for the published
asset byte for byte. What was signed is what should have been signed, and this
was established without trusting the run that produced it.

**The signature verifies for a consumer.** The maintainer downloaded both release
assets and ran `./tools/verify-release.sh` from a checkout: `verified`, exit 0.
That is the first end-to-end confirmation by a party other than the workflow, and
it is the one that mattered, because it exercises the path a consuming project
actually takes.

Activation cost one more guard. `the issued trust anchor is vendored to
consumers` read `"bundle/allowed-signers" in sync_sh` — a substring search that
`sync.sh` also satisfies from its comment block and its `[ -f ... ]` test, so
pointing the `VENDORED` append at a different file left the check green. It could
only ever pass. It now matches the append itself. That is the **sixth** check in
this repository found reading characters rather than meaning, and the second
found by insisting a new guard demonstrate a failure before being trusted — the
count in the paragraph above was five and was correct on the day it was written.

**Still not enforced.** Nothing in the gate requires a verified signature. A
consumer that never fetches the two release assets is in exactly the position it
was in before, and no check anywhere complains. The mechanism now exists, works,
and is optional, which is where this decision said it would stop.
