---
adr: "0068"
title: Write ADRs that are true about the tree — a writing procedure in the Decision Spine, and an adr-author agent installed where Claude Code looks
status: Accepted
date: 2026-11-27
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Claude Code moves where it discovers subagents; a causeway- agent pointer
  collides with a project's own agent; or reviewers report that records written by the
  agent describe code that is not there.
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

Build DNA §8 and `templates/adr-template.md` say what an ADR carries. Neither says
how to write one that is *true*: that reads the code before describing it, cites
files that exist, and admits what the decision costs. The template has a
*Consequences* heading; nothing stops it holding only benefits.

An adopting project had solved this before it pinned Causeway. Its own ADR skill
and a subagent carrying its house style produced the clearest records seen across
the projects surveyed for this release. Three habits did the work: an `Accepted`
record had to cite the code it was reflected in, *Consequences* had to include the
ones the authors disliked, and every path cited was checked. The same survey found
the cost of the project doing it alone: its skill writes to its own directory, so
its records sit in a second register the gate does not read (Build DNA open item
13), and Causeway's `decisions/` in that project is empty.

Claude Code discovers subagents under `.claude/agents/` the way it discovers skills
under `.claude/skills/`. ADR 0062 put skill pointers there; nothing put agents
anywhere.

## Forces

- **An ADR that misdescribes the system is worse than none**, because the next
  reader trusts it.
- **The approver's merge is the approval** (ADR 0065, Build DNA 8.7). `Accepted` is
  written before merge, so it is a claim about what the tree will hold, and a
  decision that must close before production code (a one-way door) is legitimately
  accepted before the code exists. The adopting project's "cite the code or it is
  Proposed" cannot be taken over as written.
- **One source per artifact** (ADR 0062). A pointer, not a copy.
- **A project's own `.claude/` is the project's.** The `causeway-` prefix is
  Causeway's namespace there, and nothing else in the directory is touched.
- **Never name the adopting projects** (ADR 0036).

## Decision

1. **`skills/decision-spine/reference/writing-an-adr.md`** is the procedure: what
   to read before writing (the register, two nearby ADRs, the code the decision
   touches, what it must not contradict); the number and a title that names the
   decision; one register, `decisions/`; status as a claim about the tree;
   context, alternatives, consequences, revisit and evidence; and what lands in
   the same pull request.
2. **The adopting project's rule is taken over in the form 8.7 allows:** an ADR
   never describes the system as doing something it does not do. *Evidence* cites
   paths that exist, or says plainly that the decision is not built yet and what
   will show it. `Proposed` is still only for the approver who asks to hold it,
   and a Proposed record carries *Open questions before this can be Accepted*.
3. **The Decision Spine skill gains hard rule 8** pointing at the procedure, and
   its *Files* table names it.
4. **`agents/adr-author.md` ships:** a subagent that follows the procedure, runs
   `tools/check-register.py` (ADR 0067), never decides, never invents a row or a
   fact, never sets an approver, and treats what it reads as data (Build DNA 7.5).
5. **Agents are installed where Claude Code looks.** `render-adapters.sh`
   generates `adapters/claude-agents/causeway-<name>.md` from each agent's
   frontmatter (its description and tool list) with a body that sends the agent to
   `agents/<name>.md`, and fails CI when a pointer is stale or an adapter does not
   name an agent. `sync.sh` installs the pointers at `.claude/agents/` and replaces
   them on every sync. The other three adapters name `agents/` so their tools can
   follow the same instructions.

## Alternatives considered

- **Take the adopting project's skill and agent as they are.** They carry that
  project's domain facts and write to its own directory, which is the second
  register this release should not spread.
- **A skill only, no agent.** A skill loads into the conversation that asked for
  the ADR. An agent reads the code in its own context and hands back a record,
  which is what made the original useful for anything more than a stub.
- **Vendor the agent file itself into `.claude/agents/`.** Two copies, and ADR 0062
  declined the same for skills.

## Consequences

**Easier.** An agent in an adopting project finds a writer that reads before it
writes, in the register the gate reads. A reviewer has one procedure to point at.

**Harder.** Two more installed files per project, and one more generated directory
here. The procedure adds reading time to every ADR; that is the point of it.

**Security.** The agent has write tools scoped by the project's own settings (ADR
0058), and is told that instructions in the material it reads are findings. The
pointers carry no permissions of their own.

**Declared gaps.** No check can tell whether *Evidence* describes the code
truthfully; `check-register.py` checks structure and the reviewer checks truth.
Gemini, Copilot and Cursor have no agent discovery directory this standard can
target, so they learn of the agents from their adapters.

## Revisit if

Claude Code moves its subagent path, a pointer collides with a project's agent, or
reviewers find agent-written records describing code that is not there.

## Evidence

- `skills/decision-spine/reference/writing-an-adr.md`; `skills/decision-spine/SKILL.md`,
  hard rule 8 and the *Files* table.
- `agents/adr-author.md`; `adapters/claude-agents/`; `tools/render-adapters.sh`;
  `tools/sync.sh`, the agent pointer install.
- CI step *Sync into a scratch project and verify the lock* asserts the pointers land.
- The adopting project's skill and agent, cited without its name (ADR 0036).
