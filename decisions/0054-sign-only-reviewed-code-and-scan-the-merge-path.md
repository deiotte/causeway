---
adr: "0054"
title: Sign only reviewed code, from main's definition, and scan this repository's merge path for credentials
status: Proposed
date: 2026-10-30
spine_rows: []
survey_rows: []
forces: [] # implementation security review, not a Survey
door: two-way
revisit_if: A second maintainer joins (approval on the release environment can then exclude self-review), the release key moves to a signing service outside GitHub, or the scan's rule set misses a credential this repository actually held.
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

The 2026-10-30 security review left two findings that the v2.12.1 fixes in ADR
0053 did not cover.

**Issue #37 — release signing authority.** `release.yml` ran on `push: tags`.
GitHub runs a tag-triggered workflow from the copy stored in the tagged commit,
so a principal able to push a `v*` tag onto an unreviewed commit chose the
workflow and every script that then received `CAUSEWAY_RELEASE_KEY`. The tag and
VERSION check inside that workflow could not help; it was in the file being
replaced. The key was a repository secret, readable by any job, and the job that
held it also ran the full test suite and held `contents: write`.

**Issue #38 — credential scanning.** Build DNA §5 and `rules/secrets.md` make
the secrets scan a merge-blocker. This repository's gate ran no scanner. The
setup page wrote a `.env` whose header said it was gitignored without anything
having checked; mode 600 does not stop `git add`.

## Forces

- The code that decides whether a commit may be signed cannot come from that
  commit.
- Main is the one ref this repository already protects with a required pull
  request and the standard's gate. A commit on main went through both, and so
  did every script it contains.
- The maintainer publishes from the GitHub web interface and keeps no local
  checkout (ADR 0016). A release must still start from creating a tag there.
- The key should be readable by as little code as possible, and never by a job
  that can also write to the repository.
- §5 asks for a merge-blocking scan; §5 also says to count publishers. A
  third-party scanner downloaded in CI is a new publisher on the merge path of
  the repository that tells consumers to count theirs.
- A scanner's log must not repeat the secret it caught.

## Proposed decision

**Signing.** Split the release into a trigger and a decision.

- `release-candidate.yml` runs on the tag. It holds no secret, can write
  nothing, and decides nothing.
- `release.yml` runs on `workflow_run` of `release-candidate`, which GitHub
  executes from the default branch whatever ref started it. Its `authorize` job
  runs main's `tools/authorize-release.sh`, which admits a tag only when it is
  `v<VERSION>` of its own commit, still points where it pointed when the run
  began, and names a commit that is an ancestor of main. Every later job needs
  `authorize`. A manual `workflow_dispatch` with a tag input takes the same path.
- The key moves to the `release` environment. Only the `sign` job names that
  environment; it has `contents: read`, runs `sign-release.sh` and
  `verify-release.sh`, and hands the public statement and signature on as job
  outputs. Validation runs in its own job before it; building, the consumer
  install test and publishing run in a `contents: write` job after it that never
  sees the key. The failure withdrawal runs main's `publish-release.sh`.
- Every checkout sets `persist-credentials: false`. The top level grants nothing.
- `tools/validate.py` checks this shape, because nothing executes the workflow
  before a release.

**Scanning.** Add `tools/scan-secrets.py`: stdlib only, offline, run on every
pull request over the tracked tree and every blob reachable in history. It
matches provider-shaped credentials and private key blocks, reports each
finding by rule, location and SHA-256 fingerprint, and never prints the value.
Suppressions live in `tools/secret-scan-allow.json` and must name an exact path,
an exact fingerprint, a reason, and the person who accepted it; one that matches
nothing fails as stale. `tools/test-scan-secrets.sh` exercises it on synthetic
fixtures assembled at runtime.

**Setup.** Before writing `.env`, establish that git ignores it — ask git when
it is installed, otherwise read `.gitignore` — and add `/.env` when nothing
does, creating `.gitignore` in a newly synced project. Refuse to write secrets
into a `.env` git already tracks. The header claims gitignored only when that
was established.

## Alternatives

- **Keep `push: tags` and add an ancestry check in the workflow.** Rejected: the
  check lives in the file the attacker supplies.
- **`workflow_dispatch` from main only.** Sound, and kept as the re-run path,
  but as the only path it adds a second manual step to every release for a
  maintainer working through the web interface, and a release tag with no run
  is a release nobody signed.
- **A signing service outside GitHub.** The strongest separation and the right
  end state; it needs infrastructure and custody decisions that belong to issue
  #4. This decision narrows the boundary inside GitHub without foreclosing it.
- **gitleaks, trufflehog or GitHub push protection as the gate.** Broader rule
  sets. gitleaks and trufflehog add a downloaded binary from a new publisher to
  the merge path; push protection is a repository setting this checkout cannot
  verify. Either can be added beside the first-party scan without replacing it.

## What this needs outside the repository

The workflow is only half of the control. These are repository settings, and
the release does not work until the first two exist:

1. An environment named `release`, with deployment branches restricted to
   `main`. Required reviewers is recommended; with one maintainer it is a
   deliberate pause, not a second pair of eyes.
2. `CAUSEWAY_RELEASE_KEY` stored as a secret of that environment, and **deleted
   from repository secrets**. A repository secret is readable by every job,
   including one in an environment, so leaving both defeats the environment.
   Secrets cannot be read back: if no copy of the key exists outside GitHub,
   this is a rotation (issue #4), not a move.
3. A tag ruleset on `refs/tags/v*` restricting creation, update and deletion to
   repository admins.

## Consequences and limits

A tag on a commit that is not on main is refused and any release already shown
for it is withdrawn to a draft. A tag moved during a run is refused. A run
started by some other workflow named `release-candidate` names no tag, so it
cannot withdraw one.

Still inside the boundary, and accepted: a repository admin, who can change
settings, rulesets and environment secrets; anyone who can merge to main,
because main requires a pull request but not a second approver (issue #2); and
GitHub itself (ADR 0019). The scan is pattern-based: a credential with no
recognisable format, such as a password in prose, is not found. The settings
above cannot be verified from a checkout; `validate.py` checks the workflow
shape only. Maintainer approval of this proposed decision is not asserted.
