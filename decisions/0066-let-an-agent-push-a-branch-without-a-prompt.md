---
adr: "0066"
title: Let an agent push a branch without a prompt — the merge is the human step, and branch protection guards main
status: Accepted
date: 2026-11-18
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: An adopting project shows an agent push reaching something a person
  had not yet approved, or projects start running without branch protection on
  their default branch.
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

ADR 0058 shipped `templates/agent-settings.json` with an `ask` rule on every
`git push`. While the file was a template a project copied by hand, the rule was
a project's choice. ADR 0062 (v3.0.0) made `sync.sh` seed the file, so from
v3.0.0 every adopting project got the rule by default.

The first project to adopt v3.0.0 found the cost within a day: an agent running in
a cloud session, with nobody at a terminal, stops at the prompt and the work stalls.
That project took the rest of the starter settings, left this rule out, and wrote
its own ADR to own the deviation. Every other adopting project would have had to
do the same.

## Forces

- **The human approval is the merge.** ADR 0065: a pull request is the unit of
  review, and the approver's merge is the approval. A push to a branch is
  reversible and reaches nothing until a person merges it.
- **The control on `main` is branch protection.** It holds for every client and
  every person, and an agent's local prompt does not.
- **Irreversible steps go through a human** (Build DNA 7.5). Force-pushing rewrites
  history others may hold, and stays denied.
- **A starter every project overrides is a starter that teaches overriding.**

## Decision

1. **The `ask` rule on `git push` is removed from `templates/agent-settings.json`.**
   Force-push in all three spellings stays denied, with everything else in the file.
2. **`rules/agent-workspace.md` says why**: the merge is the approval, and branch
   protection, which `tools/doctor.sh` already reports as `reviewers.required`, is
   what guards the default branch.
3. **A project that wants the prompt adds it to its own `.claude/settings.json`.**
   That is a stricter local rule and needs no ADR. `upgrade-starters.sh` offers the
   change to a project that seeded the v3.0.0 file, and a project that already
   removed the rule by hand will see the two agree.

## Alternatives considered

- **Keep the prompt and document the override.** Every project pays the same ADR
  for the same reason, which is the cost this release removes.
- **Deny pushes to the default branch by pattern.** Patterns over shell text are
  easy to miss (`HEAD:main`, a remote alias), so the denial would read as a control
  it is not. Branch protection already is one.

## Consequences

**Easier.** Agents in cloud and unattended sessions push the branch they were asked
to push and open the pull request.

**Harder.** A project without branch protection on its default branch has lost a
prompt that, by accident, stood in for it. Doctor already flags that as
`reviewers.required: unverified`.

**Security.** Neutral where branch protection is on. The irreversible case,
force-push, is still denied.

## Revisit if

An agent push reaches something no person approved, or projects run without
branch protection.

## Evidence

- `templates/agent-settings.json`, `rules/agent-workspace.md`.
- The adopting project's own deviation record, cited here without its name (ADR 0036).
