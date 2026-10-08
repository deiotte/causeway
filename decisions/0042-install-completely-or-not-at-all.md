---
adr: "0042"
title: Install completely or not at all — decide, plan, stage, then apply
status: Accepted
date: 2026-10-08
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: An installation is reported to have left a target half-written by a path
  this ADR did not name, or a consuming project reports that the manifest content
  check refused a copy it had a legitimate reason to install. The first means the
  plan missed a failure; the second means warn-only outside --require-release was the
  wrong line.
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

`tools/sync.sh` copied the standard into the target first and decided whether it was
allowed to second. The vendored files, the adapters, the license and every seeded
starter were written; only then were the release proof and `--require-release`
evaluated. A refusal exited `7` with the target already changed and no new lock to
record it. Issue #9 reproduced it: syncing an untagged commit into a directory that
held its own `AGENTS.md` overwrote that file, created three gate files, wrote no lock,
and reported a refusal. The README carried the defect as current limit 10 and told
readers to install into a scratch directory first.

Fixing the order exposed a second gap behind it. A release proof — a tag at `HEAD`, or
a statement that verifies against `bundle/allowed-signers` — names a bundle digest.
Nothing in `sync.sh` checked that the files on disk were the ones that digest
describes. An extracted archive with a genuine statement and an edited `AGENTS.md`
installed under `--require-release`, exit `0`, with `release_proof=signed-statement` in
the lock. `check-drift.sh` in the consuming project recomputes the digest and would
have caught it afterwards; the installer had already vouched for bytes nobody signed.

## Forces

- **A refusal is a promise about the target.** "Refusing" that leaves files behind is
  the declared-gap failure §8 names — the output says one thing and the directory says
  another, and only one of them is read.
- **The target is a project root, not a directory the standard owns.** Project files
  sit beside vendored ones, so the install cannot build a new tree and swap it in. Any
  atomicity has to be per file, with a record of what was there before.
- **Some failures are knowable in advance and some are not.** A destination that is a
  directory, a parent that is a file, a symlink, a read-only path: all visible before a
  byte moves. A full disk or a vanished mount is not, and needs a rollback rather than
  a check.
- **The proof has to be about these bytes.** A signature over a digest is evidence
  about the digest. Tying it to the files is one hash per manifest entry, offline, with
  tools the archive install already requires.
- **Development syncs from a working tree are legitimate.** A contributor editing the
  standard syncs from a tree whose manifest is not yet rebuilt. Making a content
  mismatch fatal everywhere would make that the hard path for no gain; it is not a
  release, and the lock already says so.

## Decision

`sync.sh` runs in four phases, and only the last one writes to the target.

1. **Decide.** Arguments, overlay, prerequisites (`sha256sum`, `sed`, `sort`, `awk`,
   `cmp`, `mktemp`, `cp`, `mv`), a complete source, the content check, the release
   proof, and the `--require-release` refusal. Exit `1` or `7`. The refusal now says
   *Nothing in <target> was changed*, and names the specific reason: content mismatch,
   dirty tree, invalid signature, no verifier, no tag, or no signature material.
2. **Plan.** Every file the run would write, as source → destination, with seeded
   files dropped from the plan when they already exist. Every destination and every
   existing parent is checked: a symlink, a non-regular file where a file goes, a
   non-directory where a directory goes, or anything unwritable is a conflict. All
   conflicts are reported together and the run exits `9`.
3. **Stage.** A directory is made inside the target (`.causeway-sync.XXXXXX`), so the
   apply is a rename on one filesystem. Every planned file and the lock are written
   there, and each staged file is compared to its source before anything moves.
4. **Apply.** Staged files are renamed into place one at a time, the lock last. Before
   each overwrite the existing file is backed up into the stage. If any step fails,
   every applied file is restored from its backup or removed, every directory the run
   created is removed, and the run exits `10`. The stage is deleted on every exit,
   unless the rollback itself could not finish — then it is kept, because it holds the
   only copy of what it could not put back, and its path is printed.

**Content is checked against the manifest.** Every file `bundle/manifest.json` lists
is hashed and compared to its entry, and the digest is recomputed from those entries
the way `build-bundle.sh` computes it, so a manifest edited to hide a change still
fails. A mismatch withdraws any release proof: the lock records `release_proof=none`
and no `tag=`. Under `--require-release` that is a refusal, exit `7`. Without it the
mismatch is printed as a warning and the install proceeds as a development copy.

**`CAUSEWAY_SYNC_FAIL_AFTER=N`** makes the apply fail after `N` files have moved. It
exists so CI can prove the rollback runs; a failure the plan could foresee would have
been refused there instead, so there is no other honest way to reach it. Unset, it does
nothing.

**`tools/test-sync.sh`** is the regression suite, run by `standard.yml`. It snapshots a
target that already holds a project — its own `AGENTS.md`, an old lock, source — and
requires every refusal to leave it byte-identical with no new path: a clean untagged
source under `--require-release`, an unknown overlay, three kinds of conflict, a
symlinked directory (and that nothing was written through it), and an apply failure
after 0, 5 and 30 files. Then it signs a throwaway copy of the standard with a key it
generates and discards, and requires: the signed archive installs with no git and
verifies in the project; an invalid signature, an edit beside a genuine signature, a
manifest edited under its old digest, and a missing `ssh-keygen` are each refused with
the target untouched. Run against the previous `sync.sh`, twelve of its seventeen cases
fail.

## Alternatives considered

- **Move the refusal above the copy and stop there.** Fixes the reproduced case and
  nothing else: a conflict or a failed copy halfway through still leaves a partial
  install. Rejected because the issue is that a refusal must not change the target,
  and `7` was only one of the ways to refuse.
- **Stage in `$TMPDIR`.** On a different filesystem `mv` is a copy, and a copy can
  stop halfway through a file. Staging inside the target costs one hidden directory
  for the length of the run.
- **Make a content mismatch fatal without `--require-release`.** Stricter, and it
  would turn every sync from a contributor's working tree into a failure. The lock
  already records such a copy as `release_proof=none`; the flag exists for the case
  that ships. Left as a warning, and the revisit trigger names the evidence that would
  move it.
- **Trust the signature alone.** The statement is evidence about a digest, and the
  check that ties the digest to the files is cheap and offline. Leaving it to
  `check-drift.sh` afterwards means the installer certifies first and is contradicted
  second.

## Consequences

A rejected installation leaves the target byte-identical and creates nothing, and a
new lock is written only by a complete one. Successful installs write exactly the
files they did before — compared by hand against the previous script, see Evidence — and
the "created" and "left alone" notes print only after the apply succeeds.

Two new exit codes, `9` (conflict) and `10` (rolled back). A project whose CI treated
any non-zero exit as failure is unaffected.

A copy whose content does not match its manifest is no longer reported as a release.
That is the only behavior a successful install can observe changing, and it only
changes for a copy that was not the release it claimed to be.

**What this does not do.** It does not change *what* sync overwrites: `AGENTS.md`,
`GEMINI.md`, the Copilot instructions and the Cursor rule are still replaced on every
successful sync, whatever the project had there. Preserving them is issue #10, and it
is a policy question this ADR does not answer. It does not make the apply atomic
against a killed process: a `SIGKILL` between two renames leaves the files moved so
far, the old lock, and the stage directory holding the backups. And it does not change
publisher authentication — which key is trusted and how that trust is managed is
issue #4.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-sync.sh`: 17 passed, 0 failed. With the previous `sync.sh` swapped in:
  5 passed, 12 failed.
- The previous `sync.sh`, given an extracted archive signed with a test key and an
  appended line in `AGENTS.md`, exited `0` with `release_proof=signed-statement`.
  The new one refuses with exit `7` and the target untouched.
- A sync of this tree into an empty directory by the previous and new scripts produces
  the same file set, byte-identical, and the same lock apart from `synced=`.
- `tools/validate.py` passes. Its lock-header check now reads the lock block from the
  stage, where `sync.sh` writes it.
