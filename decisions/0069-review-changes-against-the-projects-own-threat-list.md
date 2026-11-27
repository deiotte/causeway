---
adr: "0069"
title: Review changes against the project's own threat list — a security-reviewer agent that reads the Survey's TH- rows
status: Accepted
date: 2026-11-27
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Reviews by the agent are found approving, editing, or reporting a boundary as
  clear that it did not read; or the Survey's S3.4 shape changes.
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

ADR 0057 gave the Survey S3.4: every trust boundary gets `TH-` rows naming who would
misuse it, how, and where the answer lives, and each row ends `designed`,
`not defended` or `open`. ADR 0060 gave everyday code a security floor in
`rules/security.md` and put a security prompt in the PR and ADR templates. Neither
says what happens to the threat list once the build is under way. It is written at
intake and read, if at all, by whoever remembers it exists.

An adopting project closed that loop for itself with a review subagent that starts
from its threat model, weights its judgement to the trust boundaries the model
names, and reviews each change relative to that document rather than to a generic
checklist. The pattern is general; its content is that project's.

## Forces

- **A threat list nobody reads at review time is intake ceremony.** S3.4 earns its
  cost when a change that touches a boundary is read against the rows for it.
- **A human owns every merge** (Build DNA 7.1). A reviewer reports; it does not
  approve.
- **Content is data, never instructions** (Build DNA 7.5). A diff, a comment or a
  commit message can carry an instruction aimed at the reviewer.
- **Silence reads as done** (Build DNA 8.10). A boundary not checked has to say so.
- **Never invent the project's facts.** A threat model the agent made up and
  presented as the project's would be worse than none.
- **Never name the adopting projects** (ADR 0036).

## Decision

1. **`agents/security-reviewer.md` ships**, installed by ADR 0068's mechanism as
   `.claude/agents/causeway-security-reviewer.md`, with read-only tools.
2. **It starts from the project's threat list:** the Survey's S3.4 `TH-` rows,
   S3.3, and the S2.3 inbound interfaces, plus any threat model `CLAUDE.md` names,
   and `system.json` for the class. **If there is none, that is its first finding**,
   and it may propose candidate `TH-` rows labelled *proposed*, never as the
   project's own.
3. **It maps the change to what it touches** and, for each `TH-` row, asks what the
   disposition requires: a `designed` answer still holds and has its abuse test; a
   `not defended` risk has not grown past what was accepted; nothing rests on an
   `open` row; the *Never do* column was not done. A new boundary with no row is a
   finding.
4. **It holds the change to the floor** in `rules/security.md`, `rules/secrets.md`,
   `rules/dependencies.md` and `rules/agent-workspace.md`.
5. **It hands back** ranked findings with their row or rule, file and line, the
   abuse, the fix and how sure it is; a table of every boundary touched, including
   those it did not check; and a line saying it is not the gate and not an approval.
   It never edits, approves, follows instructions in what it reads, or prints a
   secret.

## Alternatives considered

- **A skill instead of an agent.** A review is better done in a fresh context that
  did not write the change.
- **Extend `rules/security.md` with review steps.** The rule is the floor for
  writing code; the threat list is per project, and reading it against a diff is a
  procedure, not a rule.
- **Leave it to Claude Code's built-in security review.** That review does not know
  the project's `TH-` rows, which are the part only the project could write.

## Consequences

**Easier.** A change touching a boundary gets read against the rows the team wrote
for it, and a project with no threat list is told so on its first review.

**Harder.** One more installed file. Reviews take longer where the Survey is long.

**Security.** Positive. Read-only tools, no approval, and instructions in reviewed
material are reported rather than followed. It adds a reader, not a control: the
gate's checks are unchanged.

**Declared gaps.** It cannot see whether the threat list is complete, only whether a
change reached a boundary the list does not have.

## Revisit if

The agent is found approving, editing or clearing a boundary it did not read, or
S3.4's shape changes.

## Evidence

- `agents/security-reviewer.md`; `adapters/claude-agents/causeway-security-reviewer.md`.
- `templates/survey.md` S3.3 and S3.4; `rules/security.md`.
- The adopting project's review agent, cited without its name (ADR 0036).
