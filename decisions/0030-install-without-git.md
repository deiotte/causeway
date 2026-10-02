---
adr: "0030"
title: Install without git, and let the signature be the release proof
status: Accepted
date: 2026-09-16
spine_rows: [SA-8.8]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
corrects: []
corrected_by: []
---

## Context

From v1.0 to v1.13.1 there was exactly one documented way to obtain this
standard: clone a private repository. The README's quickstart opened with
`git clone`, and `tools/sync.sh` was written to be run from that clone.

That places three requirements on every machine the standard lands on. Git has
to be installed. A credential for this repository has to be enrolled *on that
machine*, because the repository is private. And the network has to be up at the
moment of install. All three are ordinary on a developer workstation and are
exactly the three things missing from the machines this standard was built for.

The rest of the standard had already said so, repeatedly, without anyone
connecting it to distribution:

- Build DNA §6 requires a consuming project's build and test path to reach
  nothing — no registry, no vendor sandbox — and says that retrofitting an
  offline build is a project while never letting the first network call in is a
  rule.
- ADR 0019 chose SSH signing over a log-backed scheme because "the first program
  to consume this standard delivers from a government-owned Azure DevOps
  instance where reaching a public log service is not a safe assumption."
- `gate-configuration.md` §4 derives standard age from `.causeway-lock` alone,
  "with no network and no assumption that the standard's repository is
  reachable."
- `tools/verify-release.sh` opens with "Offline by construction. No network, no
  keyring, no transparency log, no clone."

Four places designed around a consumer who cannot reach us, and every one of
them assumes that consumer has somehow already got the bytes. Nothing said how.

The gap was not merely undocumented. It was enforced. `sync.sh --require-release`
— the flag Build DNA tells you to use for anything that builds for a real
environment — derived *is this a release* from `git describe --exact-match`.
With no git, `IS_RELEASE` stayed 0 and the script exited 7. The refusal it
printed was:

```
REFUSING: --require-release was given and this is not a release.
          HEAD is not at a tag. Check out a published release:
              git -C "/path/to/extracted/causeway-1.13.1" checkout v1.13.1
```

That is an instruction to run git inside a directory that has no git history,
on a machine that has no git. It cannot be followed, and an instruction that
cannot be followed reads to the person holding it as their own failure.

The second finding is the one that decided the shape of the fix. This repository
already had a better answer to "which release is this" than the one it was
gating on, and had had it since v1.8.0.

`git describe --exact-match` proves that some local clone has a tag pointing at
`HEAD`. A tag is a local, unauthenticated, rewritable label. `git tag v99.0.0`
manufactures one in a second, and a mirror serves whatever tags it likes. The
signed release statement proves that a key named in `bundle/allowed-signers`
attested this exact bundle digest, under the `causeway-release` namespace, and
proves it with one file of trusted keys, no keyring, no network, and no clone.

The weaker evidence was mandatory and the stronger evidence was optional. Not
by anyone's decision — by chronology. Git was what existed in v1.0, signing
arrived in v1.8.0, and nothing went back to ask which one `--require-release`
should have been reading.

## Decision

The standard publishes an archive, and a verified release signature establishes
a release exactly as a tag does.

**`tools/build-archive.sh`** produces `causeway-<version>.tar.gz`,
`causeway-<version>.zip`, and a `.sha256` beside each. The archive carries
everything `sync.sh` reads and nothing else — no README, no CHANGELOG, no
`decisions/`, no `conformance/`, none of the machinery that publishes rather
than installs. When the tree has been signed, `bundle/release.statement` and its
`.sig` go *inside* the archive, so the bytes, the statement naming their digest,
the signature over that statement, and the anchor it verifies against are one
file. A consumer who must fetch a second file to check the first will, on the
first inconvenient day, check nothing.

The archive is byte-reproducible: staged with normalized modes, sorted by name,
`mtime` pinned to `RELEASED`, owned by `0:0`, gzipped with `-n`. A checksum
published beside a non-reproducible artifact describes one build rather than one
release.

**`sync.sh` accepts either proof.** A tag at `HEAD` still works. Failing that,
and with a clean tree, it verifies `bundle/release.statement` against the
vendored anchor and takes the version, tag, commit, and digest from the signed
statement. Either establishes a release; `.causeway-lock` records which, in a
new `release_proof=` line whose value is `git-tag`, `signed-statement`, or
`none`. It is written unconditionally, `none` included, for the reason ADR 0015
gave one field over: a lock that rendered a signature-verified pin and a
local-tag pin identically would be hiding the one difference an auditor is
entitled to.

**`sync.sh` copies the statement and its signature into the project**, beside
the anchor it already vendored. `verify-release.sh` has been vendored since
v1.8.0 with nothing to verify; the documented way to give it something was
`gh release download`, which is a network call, a GitHub credential, and a third
tool, in the CI of a project whose reason for vendoring was not to need any of
the three.

**CI exercises the path rather than describing it.** `standard.yml` builds the
archive twice and compares byte for byte, then installs from an extracted
archive with `git` removed from `PATH` and asserts the resulting pin is
identical to the one a clone produces. `release.yml` builds the archive after
signing and attaches it.

**`validate.py` §19 binds the two lists.** `ARCHIVE_FILES` is an allowlist with
one failure mode: somebody adds a file to `sync.sh` and forgets the archive. That
failure cannot surface here, or in CI, or on any machine with a clone. It
surfaces on a machine with no git and no way to fetch what is missing. So the
guard lives where the list is written.

**Build DNA §3 states the rule**, because this is not a fact about Causeway. How
a dependency arrives on the target machine is part of its design, and an install
path may not assume a toolchain the target does not have.

What this does **not** do, stated here so it is not read into the above: it does
not make a private repository public, and the first fetch is still
authenticated. One machine that has git, a credential, and egress fetches one
file; that file installs on every machine that has none of them. What is removed
is the per-machine enrollment — the part that scales with the fleet — not the
authentication.

## Alternatives considered

**Document a tarball workaround and leave the mechanism alone.** This is what
the standard effectively had, minus the documentation, and §6 of Build DNA
already rules on it: a degraded mode that is never the default has not been
tested, it has been described. It also stops exactly where it matters.
`--require-release` would still refuse, so the workaround would cover every case
except the one the standard tells you to use for anything that ships.

**Use GitHub's auto-generated source tarball.** It exists for every tag and costs
nothing to produce, and it loses on four counts. It is not reproducible — the
generator's output has changed before and is not ours to pin. It is unsigned,
and there is nowhere in it to put a statement. It contains the whole repository,
so a consumer would extract this project's own ADRs into a directory called
`decisions/` and could reasonably read them as theirs. And for a private
repository it is authenticated anyway, so it costs the same fetch and buys
strictly less.

**Let `--require-release` pass when git is absent.** The shortest diff, and it is
the "check that can only pass" this repository keeps finding in its own tools. A
flag that silently stops checking on precisely the machines that most need
checking is worse than one that refuses, because the refusal at least tells
someone.

**Distribute through a package registry — npm, or an OCI artifact.** ADR 0002
already disfavors npm-hosted dependencies for this project, and a registry
reintroduces all three requirements the archive removes while adding a supplier
inside the authorization boundary, which is what SA-5.14 exists to make someone
decide deliberately.

**Publish the archive with a checksum and no signature.** A checksum served from
the same page as the artifact proves the transfer to the person who made it and
nothing at all to the machine that received the file on a USB stick three weeks
later. That machine is the reason for the archive.

## Consequences

`v1.14.0`. A minor: capability is added and no check contract, verdict, input
class, or profile moves. Build DNA goes to 1.11 for the §3 rule, and the
ServiceNow overlay is re-ratified at 1.8 against it. The bundle digest moves
because `AGENTS.md`, `tools/check-drift.sh`, and `VERSION` are digested.

`.causeway-lock` gains a header key. A project still running a `check-drift.sh`
from before this release reads `release_proof=` as a checksum line with an empty
filename and skips it, so an old vendored checker does not break on a new lock.

The cost is a second list to keep. A file added to `sync.sh` and not to
`ARCHIVE_FILES` now fails the build here, which is the intended price and is
cheaper than the alternative, where it fails in a consumer who cannot fetch the
remedy.

An unsigned release still publishes an archive and says in its own output and in
the workflow summary that it is unsigned and cannot satisfy `--require-release`.
A release with no install path at all would be the worse failure.

**Two things this does not close.** The archive is self-contained by design,
which means a substituted archive is self-consistent by the same design: its
statement verifies against its own anchor. And an archive install makes the
signature the *only* release evidence, because there is no tag to read as a
second signal. Both reduce to the fingerprint in `bundle/allowed-signers` needing
one confirmation through a channel that is not the archive, and to a key
lifecycle — custody, rotation, revocation, compromise recovery — that still does
not exist. That is `gate-configuration.md` §10 item 10 and
[issue #4](https://github.com/deiotte/causeway/issues/4), already
open. No new open item is filed for it: a second entry for one gap is the
duplication ADR 0026 built relations to catch.

Nobody outside this repository has installed from an archive. CI proves the
mechanism works with `git` removed from `PATH`. It does not prove that an
air-gapped team has done it, and the adoption-evidence limit in the README still
stands.

## Evidence

- `tools/build-archive.sh` — the file list, the determinism argument, and the
  unsigned-tree warning.
- `tools/sync.sh` — the release-identity block, `release_proof=`, the statement
  copy, and the rewritten refusal.
- `tools/check-drift.sh` — the new header key, and which proof it reports.
- `tools/validate.py` §19 — the archive-coverage guard, and the three mutations
  it catches.
- `.github/workflows/standard.yml` — "The release archive is byte-reproducible"
  and "Install from an extracted archive with no git".
- `.github/workflows/release.yml` — archive built after signing, attached
  whether or not signing ran.
- `AGENTS.md` §3 — "How it arrives is part of the design".
- `README.md` — the two distribution routes, and what the archive does not
  remove.
