---
adr: "0039"
title: Publish from a fresh history, and carry the open issues across by number
status: Accepted
date: 2026-10-01
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: one-way          # a published history cannot be unpublished
revisit_if: Never for the history itself. The private archive is kept, not deleted,
  so the record of how the standard got here still exists for its author.
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

ADR 0036 redacted other projects' names from the tree and left one thing undone on
purpose: the git history still carries every one of them, and so do the titles and
bodies of earlier pull requests. It made fixing that a precondition of publication
and named two ways to do it — publish from a fresh history, or rewrite this one.

## Forces

- **Anything in the published history is published.** A redacted tree on top of an
  unredacted history hides nothing from anyone who runs `git log -p`.
- **Pull request text is not in git.** A history rewrite cleans commits and leaves
  seven pull request descriptions that name the redacted projects. Only a new
  repository leaves them behind.
- **A rewrite breaks every existing clone and link anyway.** The usual argument for
  rewriting in place — keep the URLs — does not survive contact with a rewrite.
- **Links in the tree point at numbers.** README, GOVERNANCE, and three ADRs cite
  issues #29–#34. A new repository numbers from #1, so those links would 404 or,
  later, silently point at an unrelated issue — the worse of the two.
- **The validator compares RELEASED with the commit that last touched VERSION.** In a
  one-commit history that commit is the publication itself, so the first public
  commit has to be a release or CI fails on its first push.

## Decision

**The public repository is `deiotte/causeway`, starting from a single commit
containing this tree, released as v2.2.0. The existing repository keeps its name,
`causeway-standard`, and stays private as the archive of how the standard got here;
it is not deleted.**

The new name is the standard's own. The `-standard` suffix only ever distinguished
the repository from the author's other private work, and a new repository is the one
moment a rename costs nothing: no clone, link or bookmark points at it yet. Every
link in the tree to `deiotte/causeway-standard` is rewritten to `deiotte/causeway`
in this change, except ADR 0018's record of an API call made against the old
repository, which is history and stays as it happened.

The six open issues are recreated in the public repository as its first six items,
in their original order, so #29–#34 become #1–#6. Every link to them in the tree is
rewritten to the new number in this commit, ahead of publication, so the links are
correct the moment the repository exists. That includes one link in ADR 0030 and two
mentions in `CHANGELOG.md` — edits to accepted records that change a pointer and no
argument, declared here on the rule ADR 0036 established.

Links to commits, workflow runs and release tags that exist only in the old history
are unlinked rather than rewritten; the facts they supported stay in the text.

## Alternatives considered

**Rewrite this repository's history and make it public.** Cleans the commits;
leaves the pull request text; breaks every clone. Rejected on the second force.

**Publish without carrying the issues.** Simpler. Rejected because the issues are
the standard's open work, already cited by number from its own documents, and an
outside reader arriving at a 404 learns that the citations cannot be trusted.

## Consequences

The public repository has no history before v2.2.0. Every earlier ADR, the
changelog, and the open-items index carry that history in prose, which is where a
reader looks for it anyway. Projects that synced from the private repository
re-sync from v2.2.0; their old locks name commits the public repository does not
have, and `check-drift.sh` compares digests, not commits.

The release signing key lives in the old repository's Actions secrets and cannot be
read back out. If the private key is not held anywhere else, the public repository
needs a new key and a new `bundle/allowed-signers` — a key rotation, which is
issue #4's unfinished lifecycle question arriving early, and which would need its
own ADR before the first signed public release.

## Evidence

- A local one-commit repository built from this tree passes `tools/validate.py`
  once `RELEASED` is on or after the commit date.
- `git grep` for each redacted name returns nothing outside ADR 0036.
