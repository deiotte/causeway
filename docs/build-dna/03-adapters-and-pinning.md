# Build DNA — §3 Adapters, pinning, and how a copy arrives

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## 3. Modularity and the vendor-agnostic adapter pattern

External services are reached **through an adapter behind a canonical interface,
only**. No vendor SDK calls in handler code. That is how lock-in and untestable
edges get in.

- Define the canonical schema first, from the domain, not from the vendor's
  response shape.
- One adapter per vendor. Adapters translate; they do not carry domain logic.
- Swapping a vendor should touch one directory.
- Third-party *packages* earn the same treatment for the same reason (§5). The
  boundary that lets you swap a vendor is the boundary that lets you drop a
  compromised dependency.

Long-term thinking is a first-class concern here, not a virtue signal: the
adapter boundary is what makes Decision Spine SA-3.8 and SA-9.1 answerable at
all.

### Pin upstream. Never silently fork.

Everything the project did not write arrives at a version, and the version is
part of the design. A dependency, a base image, a vendored standard, a schema
someone else publishes — the question is always the same one: *which copy, and
how would anyone know if it moved?*

- **Pin exactly.** A range is a decision deferred to whoever builds next, and
  the build that reproduces today is the only one you can debug.
- **A local edit to someone else's code is a fork**, whether or not anyone calls
  it one. The patch that is faster than upstreaming is also the patch that gets
  silently dropped at the next bump, and the second time it is written the
  reason has been forgotten.
- **Fork deliberately or not at all.** A real fork is fine — vendored, named,
  owned, with an ADR saying what diverged and what would end the divergence.
  What is not fine is a fork nobody declared, because nobody can pin it, patch
  it, or drop it under incident pressure.
- **The gap between pinned and current is a number someone owns.** Pinning is
  not freezing. A pin nobody revisits is how a project arrives at a five-year-old
  transitive dependency with a CVE and no upgrade path.

The standard holds itself to this and is the worked example. Causeway is
vendored into a project, recorded in `.causeway-lock`, and `check-drift.sh`
exits `5` when a governed file no longer matches what was synced. A project
cannot quietly redefine the standard it claims to follow — not because editing
is forbidden, but because the edit is visible and has to go upstream or become
a declared deviation. Apply to your own upstreams what the standard applies to
itself.

### How it arrives is part of the design

Pinning answers *which copy*. This answers *how the copy gets onto the machine*,
and it is the half that stays unstated until somebody is standing in front of a
machine that cannot follow the instructions.

- **The install path may not assume the target's toolchain.** `git clone`, `npm
  install`, `pip install` from a private index — all fine on a workstation, and
  all quietly assuming the same three things: the tool is installed here, a
  credential for it is enrolled here, and the network is up right now. An install
  that needs all three works on every machine you tested it on and on none of the
  ones you ship to.
- **Separate acquisition from installation.** One machine that has the tool, the
  credential and the egress fetches one artifact. That artifact then installs on
  every machine that has none of them. The authenticated step happens once
  instead of once per machine, and that is the difference that scales — not
  convenience, arithmetic.
- **Publish an archive, and publish the same bytes every time.** Sorted entries,
  pinned timestamps, no uid, no build host. A checksum beside a
  non-reproducible artifact describes one build rather than one release, and the
  first person to try reproducing it is the one who finds out.
- **An artifact that travels by hand carries its own integrity.** A tarball
  arriving on a USB stick, an internal share, or an artifact repository has
  crossed a boundary with no transport security in it. The attestation has to be
  *inside* the artifact and checkable with what is also inside it. A signature
  that requires fetching a second file gets skipped on the first day fetching is
  inconvenient, which is the day it mattered.
- **The offline install path is the one the release publishes**, not the one an
  appendix describes. Same rule as §6, same reason: a degraded mode that is never
  the default has not been tested, it has been described.

The standard is the worked example here, and it is a late one. From v1.0 to
v1.13.1 the only documented way to get Causeway was a clone of a private
repository — while §6 above required consuming projects to build with no network
at all, and ADR 0019 chose SSH release signing specifically so an air-gapped
consumer could verify a release offline. Both of those assume a consumer who has
somehow already got the bytes, and nothing in the standard said how. Worse,
`sync.sh --require-release` — the flag this document tells you to use for
anything that ships — derived *is this a release* from `git describe`, so on a
machine without git it could not be satisfied at all, and said so by printing a
`git checkout` command into a directory with no git in it.

v1.14.0 publishes a signed, reproducible archive and `--require-release` is met
by verifying the release signature instead. ADR 0030 records it, including what
it does not do: it does not make a private repository public, and the first
fetch is still authenticated. What it removes is the per-machine enrollment.
