---
adr: "0053"
title: Enforce setup origins, private file writes, destination ancestry and signed content
status: Proposed
date: 2026-10-30
spine_rows: []
survey_rows: []
forces: [] # implementation security review, not a Survey
door: two-way
revisit_if: A supported consuming project needs a host other than the printed loopback origin, or a future bundle adds another optional file class.
approver:
  name:
  role: Maintainer review pending
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

An owner-requested security review of source `5e74d00` reproduced five boundary
failures using temporary fixtures and disposable signing keys. No production
credentials, real release key, or consuming project was used.

The setup server accepted an arbitrary Host, returned its secrets and write
token, then accepted that token to run an allowed Make target. This supplies the
server side of a DNS-rebinding attack; browser exploitability also depends on
DNS and browser local-network protections. Its predictable temporary `.env`
filename followed a planted symlink and overwrote an outside fixture before
chmod. Sync inspected only the nearest existing parent, so a higher-level
symlink could redirect writes outside the target. Drift checking treated all
missing manifest entries as unvendored, including required files deleted along
with their lock lines. Release verification checked a signed digest field but
did not independently hash the content beside it.

## Forces

- Loopback binding is reachability, not browser-origin authentication.
- Secrets must be private from their first write, and an existing link must not
  redirect that write.
- Installation must stay inside the destination tree even when nested
  directories already exist.
- The signed manifest supplies the inventory; an editable lock must not decide
  that a required file was optional.
- A statement authenticator must verify the content it claims to describe.
- Offline operation and existing standard-library/coreutils dependencies remain
  sufficient; these repairs need no package registry or network service.

## Proposed decision

Check exact loopback Host, supplied Origin, and cross-site fetch metadata before
serving any setup route. Continue to require the session token on writes.
Create a fresh temporary file exclusively, mode 600, in the destination
directory; replace `.env` atomically after writing, and clean up on failure.
Refuse a preexisting `.env` symlink rather than silently changing its meaning.

Walk every ancestor inside the sync target. Require every core manifest file
and the selected overlay during drift checks; reconstruct VERSION and RELEASED
from the installed lock as before, and permit only unselected overlays to be
absent. Require the manifest when a lock carries a digest. Verification of an
installed copy includes its drift check; verification of a full checkout or
archive hashes its complete manifest and recomputes the signed digest.

The alternative was to document these as caller obligations or keep requiring
separate manual integrity checks. That leaves success messages capable of
describing content the tools never verified, and makes a setup token obtainable
through the same server it is intended to protect.

## Consequences and limits

Existing valid installs and the printed local setup URL continue to work.
Custom hostnames and proxies are refused. The setup service is not a security
boundary between local users, and these path checks do not isolate a directory
that an attacker can concurrently rename or modify. Run only in a trusted
project directory with the privileges its targets need.

No release key is rotated and no repository setting changes. The initial trust
anchor and unsigned installer surface remain security issue #4; this decision
does not claim to authenticate a wholly replaced archive that supplies its own
key and verifier. Maintainer approval of this proposed decision is not asserted.
