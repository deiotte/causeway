---
name: upgrade
description: Move a consuming project to a newer published Causeway release in one reviewable pull request — sync from the signed archive, offer starter changes, run the checks, and summarize what changed and what now needs a decision. Use when someone asks to upgrade, re-sync, re-pin or bump Causeway, when doctor or standard-currency says the pinned copy is old, or when a new Causeway release is announced.
---

# Upgrade

A project pinned to an old standard never receives a new rule, and the gap is the
project's to close (Build DNA §3). Upgrading is mechanical; deciding what the new
release asks of the project is not. This skill does the first and lists the second.

The result is one pull request a maintainer can read and merge in the GitHub web
UI. Nobody should need a command line to accept an upgrade.

---

## Step 1 — Find the target release

1. Read `.causeway-lock` for the pinned `version=` and `released=`.
2. Find the newest **published** release (the repository's Releases page). A
   version on `main` with no release cannot be pinned with `--require-release`;
   say so and stop rather than sync from a branch.
3. Read `CHANGELOG.md` between the two versions. Note every entry marked as
   breaking, every new spine row, and every check whose blocking behavior moved.

## Step 2 — Sync from the signed archive

On a branch named for the target version:

```bash
curl -fLO https://github.com/deiotte/causeway/releases/download/vX.Y.Z/causeway-X.Y.Z.tar.gz
curl -fLO https://github.com/deiotte/causeway/releases/download/vX.Y.Z/causeway-X.Y.Z.tar.gz.sha256
sha256sum -c causeway-X.Y.Z.tar.gz.sha256
tar -xzf causeway-X.Y.Z.tar.gz -C "$TMPDIR"
bash "$TMPDIR/causeway-X.Y.Z/tools/sync.sh" "$PWD" --require-release
bash tools/upgrade-starters.sh
```

Never sync from a git clone of the standard for a pin: the lock records
`release_proof=git-tag`, which some projects reject. Use the archive.

`upgrade-starters.sh` reports each seeded starter as clean, merged, conflict or
manual. Resolve conflicts by keeping the project's own content and taking the new
upstream sections; never discard a project's edit to make a merge clean.

## Step 3 — Run the checks

```bash
bash tools/check-drift.sh
bash tools/verify-release.sh
bash tools/doctor.sh
python3 tools/evaluate.py --coverage
```

Then the project's own definition of green from its `CLAUDE.md`. If a project
script pins the expected Causeway version (a `want=` line in a wrapper around
`check-drift.sh`, for example), update it in the same pull request.

## Step 4 — Update what the project owns

- The pinned version wherever `CLAUDE.md` states it.
- Any rule the new release added that the project already deviates from: add an
  exceptions-register row and an ADR, or comply. Do not leave it silent.
- New spine rows the release added: they enter as findings with a deadline
  (gate-configuration §4, adoption horizon). List them; close the easy ones with
  coverage ADRs only where a `GR-` fact really forecloses them.

## Step 5 — Open the pull request

Title it `Upgrade Causeway vA → vB`. The body has four parts, in this order:

1. **What you need to do**, first and in GitHub-UI terms: usually "review and
   merge"; plus any repository setting the release asks for, step by step.
2. **What changed for this project**: the changelog entries that matter here, in
   plain words, not the whole changelog.
3. **What now needs a decision**: new rows, new rules this project deviates from,
   checks that will start warning. Each with a recommended answer.
4. **Check results**: drift, signature, doctor and evaluator output, summarized.

What this skill must not do: edit a vendored file to make a check pass, pin a
version that has no published release, or mark a new rule satisfied without
reading what it asks.
