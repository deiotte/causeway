---
adr: "0065"
title: The pull request is the unit of work, it lands as one commit, and the approver's merge is the approval
status: Accepted
date: 2026-11-17
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Squash merging loses history a project needed to bisect, or approvers
  report that decisions were accepted by a merge they did not mean as acceptance.
approver:
  name: Karl Deiotte
  role: Maintainer
supersedes: "0003"
superseded_by:
supersession_cause: S2   # learned by building: the rule met the workflow it governs
corrects: []
corrected_by: []
---

## Context

**One prompt, one commit (ADR 0003).** Build DNA §7 asked the author to rewrite a
branch into prompt-sized commits before opening a pull request. In practice the
author is an agent in a cloud session and the merger is a person working only in the
GitHub web UI. Neither rewrites history comfortably, the rule went unfollowed, and
the maintainer had never used squashing at all. The property the rule protected, one
readable and revertible record per intent, is what squash merging produces, and a
repository setting enforces it where an instruction only asked.

**Approval took two extra pull requests.** An ADR reached `Accepted` in three steps:
the author's pull request landed it `Proposed`, the approver opened a second editing
`status` and `approver`, and a third moved the register. Five of the eight commits
before v3.0.0 were that bookkeeping (PRs #45 and #46 among them). The README has said
since v1 that a name in a file authenticates nothing; the merge, by a named account
on a protected branch, is what the platform actually records.

## Forces

- **The unit of revert should be the unit of intent.**
- **The people doing the work use the web UI**, not a command line.
- **A name in a file is not an authentication.** A merge by a named account is
  recorded by the platform with who and when.
- **The named-approver rows still need a named person** (Build DNA 8.6), and the
  `named-approvers` check reads frontmatter.

## Decision

1. **The pull request is the unit of review and revert, and it lands as one
   commit.** Repositories allow squash merging only; branch commits are working
   notes. One pull request, one purpose. Build DNA 7.6.
2. **The approver's review and merge is the approval.** An ADR is written
   `Accepted`, names its approver, and moves the register and open-items index in
   the same pull request as the change. `Proposed` is used only when the approver
   asks to hold a decision open. Build DNA 8.7.
3. **Templates say so**: the pull request template asks for one purpose and says it
   will be squash merged; the ADR template's `status` comment and the decisions
   README describe acceptance by merge; `CONTRIBUTING.md` gives the web-UI setting.
4. **Supersedes ADR 0003** on the commit rule. ADR 0003's other half, that the gate
   checks only what CI can see (`tests-with-source`), is unchanged.

## Alternatives considered

- **Keep one prompt, one commit.** Unfollowed in practice; a rule that cannot tell
  being followed from being ignored is dead (ADR 0003's own words).
- **Rebase merging.** Keeps the agent's working commits on the default branch, which
  is the history ADR 0003 called un-bisectable.
- **Keep the separate acceptance pull request.** It adds a commit carrying less
  information than the merge it follows.

## Consequences

**Easier.** Accepting a decision is one click on a pull request the approver was
reviewing anyway. `main` reads as one commit per pull request.

**Harder.** An approver who merges a pull request accepts the ADRs in it. Reviewers
have to read the ADRs before merging, which they were supposed to do already.

**Security.** Approval evidence moves from a typed name to the platform's merge
record, which is stronger. Branch protection is what makes the merge mean anything;
doctor already reports it as unverified until someone checks it.

**Declared gaps.** No check reads the merge record; `named-approvers` still reads
the frontmatter name.

## Revisit if

Squash merging loses history a project needed, or an approver says a merge was not
meant as acceptance.

## Evidence

- `AGENTS.md` 7.6 and 8.7; `docs/build-dna/07-building-with-ai.md`,
  `docs/build-dna/08-adr-discipline.md`.
- `templates/pull_request_template.md`, `templates/adr-template.md`,
  `templates/decisions-README.md`, `CONTRIBUTING.md`.
