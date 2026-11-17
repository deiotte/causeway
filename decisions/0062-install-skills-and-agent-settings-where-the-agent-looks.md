---
adr: "0062"
title: Install skills and agent settings where the agent looks — skill pointers under .claude/skills/, and a seeded .claude/settings.json
status: Accepted
date: 2026-11-17
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Claude Code changes where it discovers skills or settings, or a project
  reports that a causeway- pointer shadowed or collided with a skill of its own.
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

Build DNA open item 9, *a pointer is not discovery*, recorded since ADR 0029 that
nothing auto-discovers `skills/`: an agent learns a skill exists only because the
adapter it reads names the path. The candidate fix, shipping skills where each tool
already looks, was deferred for want of evidence from a session that did not go
through an author of the standard.

The 2026-11-17 review supplied it. None of the three adopting projects had a `.claude/`
directory at all: no discovered skills and no committed agent settings. ADR 0058's
deny list was a template the project was told to copy, and none of the three had.

## Forces

- **Claude Code discovers skills under `.claude/skills/<name>/SKILL.md`** and decides
  when one applies from its `description`.
- **One source per skill.** A second full copy would drift, and the skills cite their
  `reference/` files by relative path.
- **A project's own `.claude/` is the project's.** Causeway may not overwrite a
  project's skills or its settings.
- **Settings are a floor a project adds to** (ADR 0058); a re-sync must never take a
  rule away.

## Decision

1. **Each shipped skill gets a generated pointer** at
   `adapters/claude-skills/causeway-<name>/SKILL.md`: the vendored skill's own
   `description`, and a body that sends the agent to `skills/<name>/SKILL.md`.
   `render-adapters.sh` generates them from the skills' frontmatter and fails CI
   when they are out of date.
2. **`sync.sh` installs the pointers at `.claude/skills/causeway-<name>/`** and
   replaces them on every sync. The `causeway-` prefix is Causeway's namespace;
   a project's own skills beside them are never touched.
3. **`sync.sh` seeds `.claude/settings.json` from `templates/agent-settings.json`**
   when the project has none, once, as a starter the project then owns, with the
   baseline `upgrade-starters.sh` needs.
4. **Open item 9 closes.**

## Alternatives considered

- **Vendor the skill directories themselves under `.claude/skills/`.** Two copies
  of every skill and its references, and `skills/` is cited across the standard.
- **Symlinks.** Not portable to every checkout, and `sync.sh` deliberately treats a
  symlink in the target as the project's.
- **Keep the settings template as an instruction.** The evidence says the
  instruction was not followed in three of three projects.

## Consequences

**Easier.** An agent in an adopting project finds the Survey, Decision Spine,
field-note, backfill and upgrade skills without reading an adapter. A fresh sync
has a committed deny list from the start.

**Harder.** Five more managed files in every project. A project that already has a
`.claude/settings.json` keeps it and is told the starter exists.

**Security.** Positive: the agent's deny list now exists by default rather than by
diligence. The pointers carry no permissions and run nothing.

**Declared gaps.** Gemini, Copilot and Cursor still learn of skills from their
adapters; only Claude Code has a discovery directory this standard can target.

## Revisit if

Claude Code moves its discovery path, or a `causeway-` pointer is found colliding
with a project's own skill.

## Evidence

- `adapters/claude-skills/`, `tools/render-adapters.sh`.
- `tools/sync.sh`, the pointer install and the settings seed.
- `docs/build-dna/open-items.md` item 9, closed.
