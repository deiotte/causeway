---
adr: "0046"
title: Offer starter upgrades three ways — record the baseline at seeding, merge only what is clean
status: Accepted
date: 2026-10-08
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: An adopter reports a merge that applied cleanly and was wrong, or that the
  manual path for pre-2.6.0 projects costs more than re-seeding by hand. The first says
  line-based merging is the wrong instrument for some starter; the second says the
  no-baseline case needs a better inference than identity with the current template.
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

`sync.sh` seeds nine starter files — `CLAUDE.md`, `CONTRIBUTING.md`, `START-HERE.md`,
the decisions README, the open-items index, `CODEOWNERS`, the PR template, the
field-note form and the field-notes README — once, and never again. ADRs 0025, 0028,
0035 and 0041 each argued why: the project's names, commands, reviewers and ADR index
are in those files, and a sync that overwrote them would erase exactly what makes them
useful.

That protects a project's edits. It also leaves an established project no way to learn
what a later template improved. ADR 0041 improved the decisions README, and ADR 0045
added a `Gate evaluator` line to the `CLAUDE.md` starter. Neither reached any project
that already had the file. Issue #11 asks for a structured way to offer those changes.

Telling a project's edits apart from upstream's needs the version both started from. No
such record existed: the file on disk is the only copy, and it already carries the
project's changes.

## Forces

- **The starter is the project's.** Whatever is recorded about it must not fall under
  the lock or `check-drift.sh`, or editing your own `CONTRIBUTING.md` becomes drift.
- **A merge that silently drops a line is worse than no merge.** Only merges that
  apply without any conflict may be applied automatically. Anything else is shown, not
  written.
- **Every project before this release has no baseline.** The honest answer for them is
  a diff to review. A guessed baseline would produce confident wrong merges.
- **Offline, few tools.** Consumers install with coreutils and no git (ADR 0030).
  `diff3` ships in GNU diffutils with `diff`; `git merge-file` would need git.
- **Two lists of starters drift.** `sync.sh` seeds them and the upgrader reads them. A
  starter added to one and not the other would be seeded and then never upgraded.

## Decision

**Record the baseline when seeding.** When `sync.sh` seeds a starter it also writes the
template exactly as seeded to `.causeway/starters/<file>.base`. It adds a line to
`.causeway/starters.txt`: the baseline's sha256, the project path, the template path and
the release. Both are part of ADR 0042's staged, all-or-nothing install. A re-sync that
seeds nothing leaves them byte-identical. A re-seed of one deleted starter replaces only
that line. `.base` keeps a baseline from being read as live configuration —
`.causeway/starters/CLAUDE.md` would be a nested instruction file to some agents.

**`tools/upgrade-starters.sh`** ships in the release archive and is run from the release
being upgraded to, as `sync.sh` is. It compares *base*, *yours* and *theirs* for each
starter:

| State | When | `--apply` |
|---|---|---|
| `up-to-date` | the template has not changed since the baseline | nothing |
| `clean` | yours is the baseline, unedited | theirs replaces yours; baseline moves |
| `merge` | both changed, and `diff3 -m` merges with no conflict | the merge replaces yours; baseline moves |
| `conflict` | `diff3` reports a conflict | **never applied.** Conflict file with labelled markers in the report |
| `adopt` | no baseline, and yours is exactly theirs | baseline recorded |
| `manual` | no baseline, and yours differs | **never applied.** A diff in the report |
| `absent` | the project does not have the file | nothing (sync seeds it) |

Report mode is the default and writes nothing to the project: proposals, diffs and
conflict files go to `--out`, which must be outside the project and is refused before
anything is created. `--accept <file>` records theirs as the baseline after a hand merge
and changes none of the project's files. Applying twice is stable: the second run
reports `up-to-date`.

**`validate.py` §22** requires the upgrader's `STARTERS` list to equal `sync.sh`'s
`plan_seed` pairs exactly, and the archive to carry the upgrader.

**`ADOPTING.md`** walks through an upgrade in eight steps, including committing
`.causeway/`.

## Alternatives considered

- **Fetch the old template from the release it was seeded from.** Needs that release on
  hand, or a network to get it, for every upgrade. The baseline copy costs a few
  kilobytes per project and makes the upgrade offline and self-contained.
- **Record only the baseline's checksum.** Enough to tell `clean` from edited, not
  enough to merge. Storing the content is what makes `merge` possible.
- **Put the baselines in the lock.** Then `check-drift.sh` governs them. A project that
  deleted `.causeway/` to start over would fail drift for a file that is not part of the
  standard.
- **Write conflict markers into the project file.** Standard for git, and it leaves a
  half-edited file that might be committed by accident. The conflict stays in the report
  until a person resolves it.
- **Infer baselines for old projects from older releases' templates.** This
  repository's history starts at the public release (ADR 0039), so the older templates
  are not here to compare against. Identity with the current template is the only
  inference that cannot be wrong.

## Consequences

Every sync from v2.6.0 seeds a `.causeway/` directory beside the starters, and projects
should commit it. `doctor.sh` does not inspect it, and nothing else reads it.

Projects that adopted before v2.6.0 get `manual` for every starter they edited. That is
one review of each, once, after which they have baselines like everyone else.

Line-based merging can produce a merge that applies cleanly and is semantically wrong —
most plausibly in `open-items.json`, where it is JSON rather than prose. The report
shows every diff before `--apply`, and the revisit trigger names this case.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-upgrade-starters.sh`: 28 passed, against a future release whose contributor
  guide, `CLAUDE.md` starter and PR template changed. It covers:
  - all nine starters `up-to-date` against their own release
  - report mode byte-identical
  - `clean`, `merge`, `conflict` and `up-to-date` each reached
  - conflict markers labelled
  - `--out` inside the project refused with nothing created
  - apply lands the clean file and the merge (project name and upstream section both
    present), writes no conflict, leaves reviewers untouched, and moves baselines only
    for what it applied
  - a second apply changes nothing
  - `--accept` changes no file and makes the next run `up-to-date`, and refuses a file
    that is not a starter
  - for a project with no baselines: `adopt`, `manual` with a diff, `absent`, and apply
    recording only the adoption
  - re-sync leaves baselines alone, and re-seeding one starter keeps the other eight
- `validate.py` §22 fails, naming the file, when one entry is removed from the
  upgrader's list.
