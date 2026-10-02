---
adr: "0040"
title: Issue a new release-signing key before the first public release
status: Accepted
date: 2026-10-02
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Issue #4's key lifecycle is decided. This ADR replaces one key; it does not
  define how keys are custodied, rotated, revoked or recovered, and the next rotation
  should happen under that policy rather than under this precedent.
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

ADR 0019 issued the release-signing key and committed its public half as the trust
anchor in `bundle/allowed-signers`, fingerprint
`SHA256:EbUs+x+IdYqz4zbWZn2Ct098YN6XUNAaiRD8lDuYFIk`. The private half lived in the
private repository's Actions secrets, which cannot be read back, and ADR 0039 flagged
that the public repository would need it.

It could not be found. The first release attempt in the public repository was signed
with a different key the maintainer held, and `verify-release.sh` refused it — *signature
was not made by any key in bundle/allowed-signers*, exit 8 — which is the check doing
exactly what ADR 0019 built it to do. The archives that run attached were withdrawn and
the tag deleted before the repository was made public.

## Forces

- **A trust anchor whose private half is lost is a key nobody can sign with.** Keeping
  it means never signing a release again; there is no third option.
- **Nobody outside has the old anchor yet.** The public repository has published no
  release. Every consumer of this standard so far is its author, and every one of those
  re-syncs from the first public release anyway (ADR 0039). This is the cheapest a key
  change will ever be.
- **A release key should be dedicated.** Signing with a key that also authenticates a
  person to GitHub or a server means one compromise is two. The replacement was
  generated for this purpose only.
- **The lifecycle question is still open.** Issue #4 asks for custody, rotation,
  revocation, expiry and recovery. Answering it is a larger decision than replacing one
  lost key, and it should not be answered by accident inside this one.

## Decision

**Replace the anchor in `bundle/allowed-signers` with a new, dedicated Ed25519 key,
fingerprint `SHA256:dsW8+Y3vfNpf7GJ4cNwzZWPz7MoeANQtjiZEFmW5iVY`, under the same
principal, `release@causeway`.**

The private half is held by the maintainer outside GitHub and in the public
repository's `CAUSEWAY_RELEASE_KEY` secret, and nowhere else. The principal does not
change, because it names the release role rather than a key — which is what ADR 0019
chose it for.

## Alternatives considered

**Keep looking for the old key.** Rejected after a search came up empty: the release is
blocked on it, and a key that has to be found has already failed its custody test.

**Ship v2.2.0 unsigned and rotate later.** Rejected. The README tells consumers to use
`--require-release`, which an unsigned archive cannot satisfy, so the first public
release would fail the standard's own install instructions.

**Trust both keys for a transition period.** Rejected: there is nothing to transition
from. No release signed by the old key exists in the public repository.

## Consequences

The bundle digest moves, because `bundle/allowed-signers` is digested. v2.2.0 has not
been published, so the change lands in it rather than in a new version.

Releases signed in the private repository's history, v1.8.0 through v2.1.0, verify only
against the old anchor. They are not public and their only consumers are the
maintainer's own projects, which move to v2.2.0.

The custody gap that lost the first key is not closed by this ADR. It is issue #4,
and this record is evidence for it: a key held only as a CI secret is a key that is
lost the moment the repository holding it is retired.

## Evidence

- The new public key parses as a 32-byte Ed25519 key with the fingerprint above.
- The rejected signature embedded the public key
  `SHA256:vSvJt80LhnPGFweRRlTbFWQQevVfW3z+3HDLDRlDZ0c`, neither the old anchor nor the
  new one.
- `tools/validate.py` passes with the new anchor digested and vendored.
