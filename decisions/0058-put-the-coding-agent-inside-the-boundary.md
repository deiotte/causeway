---
adr: "0058"
title: Put the coding agent inside the boundary — a workspace rule, committed starter settings, and a doctor finding
status: Approved
date: 2026-11-16
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A coding tool Causeway adapts to (Claude Code, Gemini, Copilot, Cursor)
  changes its settings format so the starter stops parsing or a key stops meaning what
  this ADR says; or an adopter reports the starter deny list blocked legitimate work
  often enough that teams delete it rather than adding to it.
approver:
  name: Karl
  role: Human
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Causeway is written for software built with coding agents, and it governs what a
*system* may do with a model in some detail: SA-5.15 bounds the tool surface,
SA-5.16 bounds what crosses to a provider, and `rules/inference.md` carries the
floor for both. Build DNA §7 governs how people work with AI: who owns a merge, where
constraints live, the size of a commit.

Nothing governed the agent's own position. A coding agent runs shell commands with
the credentials of the laptop or runner it is on. It reads issues, pull request
comments, web pages, dependency READMEs and tool output, any of which can carry
instructions written by someone who is not on the team. It loads MCP servers and
plugins, each of which is third-party code. And the files that steer it — `CLAUDE.md`,
`AGENTS.md`, `.claude/`, `.mcp.json` — are edited like documentation and reviewed like
documentation, though they change the behavior of every later session.

§5 already makes this argument once, for the package registry: a third-party input
that executes code on developer machines is inside the authorization boundary whether
or not the diagram admits it. The coding agent meets that description at least as
well as the registry does.

## Forces

- **Prose cannot enforce agent behavior** (Build DNA §9). A rule that says "do not
  read `.env`" is guidance. A committed deny list is enforced by the tool before the
  read happens, which is the difference §9 cares about.
- **A deny list is not a wall either.** The tool's own documentation says a command
  rule matches the text the agent writes, not the program that runs: a script, an
  alias or another interpreter goes around it. Saying otherwise would overclaim. The
  honest framing is that the deny list stops accidents and the layers below the agent
  — a sandbox, network limits, and credentials it does not hold — stop the rest.
- **Personal settings protect one machine.** The control has to live in the
  repository to reach every contributor and every agent session.
- **Contributors use different platforms.** The sandbox that would enforce file and
  network limits at the operating-system level does not run on native Windows, and a
  committed setting that refuses to start without it would lock those contributors
  out. The starter cannot turn it on for everyone.
- **The setup page reads `.env.example`** (ADR 0052). A deny pattern broad enough to
  catch `.env.*` hides that file from the agent and breaks the configure step.

## Decision

**Build DNA §7 gains *The agent is inside the boundary too*, and three artifacts back
it.**

- **`rules/agent-workspace.md`**, vendored: what the agent can reach (no production
  credentials, secrets denied, task-scoped credentials), what it can run (committed
  deny list, bypass off, the deny list as a floor not a wall, irreversible steps
  through a human), what it trusts (content is data, MCP servers and plugins are
  dependencies under `rules/dependencies.md`, instruction files are code), and a short
  list of diff changes to read for before calling agent work done.
- **`templates/agent-settings.json`**, vendored, which a project copies to
  `.claude/settings.json`. It denies reading and editing `.env` and its local and
  production variants, `secrets/` directories, `*.pem` and `*.key`, and credential
  files in the home directory; denies `sudo`, printing the environment, and
  force-pushing; asks before any other push; turns the bypass mode off; and does not
  auto-enable project MCP servers. It leaves `.env.example` readable and does not
  enable the sandbox, for the two forces above. The syntax was checked against the
  tool's published settings and permissions documentation on 2026-11-16.
- **`tools/doctor.sh` reports `agent.settings`**: incomplete when no
  `.claude/settings.json` is committed, when it does not parse, when no deny rule
  covers reading `.env`, when the bypass mode is not off or is the default mode, or
  when a deny rule hides `.env.example`. Advisory, like every doctor finding.
- **`templates/CODEOWNERS`** names `CLAUDE.md`, `.claude/`, `.mcp.json` and
  `.github/workflows/` for review.

Survey S3.4 prompt 8 (ADR 0057) points here, so the coding agent appears in a
system's threat list as an insider. The ServiceNow overlay is re-ratified at 1.16
with no row moved.

## Alternatives considered

**Seed `.claude/settings.json` on sync.** The strongest default: every install would
be protected without a step. Rejected for now. Sync would have to merge with a file
the project may already own, and `upgrade-starters.sh` would have to three-way merge a
security control, where a silent merge result is the failure. A template the project
copies, and a doctor finding until it does, keeps the step visible. Revisit if
adopters report skipping it.

**Ship the sandbox on.** Rejected for the platform reason above. The rule says when to
turn it on and that the choice belongs in `CLAUDE.md`.

**A starter per coding tool.** Rejected for now. Claude Code's settings format is the
one Causeway's primary adapter reads, and its keys were verified. Writing starters for
tools whose permission models were not checked would ship controls that may not do
what they say. The rule's principles apply to every tool; the rule says so.

**Put this in `rules/inference.md`.** Rejected. That file governs what a system lets
a model do; this governs the model building the system. §7 already warns that putting
either in the other's file is the seam failure §9 describes.

**A gate check.** Rejected. The gate evaluates a product. Whether a developer's agent
was constrained while building it is a property of the workspace, not the product,
and no input the gate reads would show it.

## Consequences

**Easier.** A project gets a reviewed deny list in one copy step, and doctor says when
it is missing. Reviewers have a short list of agent-diff changes to look for. An
instruction smuggled into an issue or a page has a written answer: it is data.

**Harder.** One more file to copy and keep. Contributors who relied on bypass mode on
a workstation now have a committed setting that refuses it; that is the intent.

**Declared gaps.**

- **The deny list is bypassable** by a determined command, as the tool documents.
  Nothing in this ADR provides the sandbox, egress limits or credential separation
  that actually hold. The rule names them; the project owns them.
- **Only Claude Code has a starter.** Gemini, Copilot and Cursor users get the rule
  and no settings file.
- **Doctor checks shape, not effect.** It cannot see whether a session honored the
  file or whether a sandbox sat under it.
- **The CI surface still has no rule.** Build DNA open item 3 still wants one; this
  ADR adds a CODEOWNERS line for workflows and does not close that item.

## Revisit if

The tool's settings format changes under the starter, or adopters delete the starter
rather than add to it. The frontmatter states both.

## Evidence

- `AGENTS.md` §7, *The agent is inside the boundary too*; open item 3 names the new
  rule; Build DNA 1.17.
- `rules/agent-workspace.md` and `templates/agent-settings.json`, vendored by
  `tools/sync.sh`, digested by `tools/build-bundle.sh`, archived by
  `tools/build-archive.sh`; `bundle/manifest.json` regenerated.
- `tools/doctor.sh`, *The agent's own settings*; `tools/test-doctor.sh` covers the
  starter as shipped, a missing file, invalid JSON, bypass left on, `.env` readable,
  and `.env.example` hidden.
- `templates/CODEOWNERS`: the agent instruction and settings paths.
- `overlays/servicenow.md` and `.json`: ratified again at 1.16.
