---
adr: "0029"
title: Make a shipped skill reachable, and check that it stays reachable
status: Accepted
date: 2026-09-11
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
corrects: []
corrected_by: []
---

## Context

Nothing auto-discovers `skills/`. An agent working in a consuming project learns
that a skill exists because the tool adapter it reads says so — `CLAUDE.md`,
`GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/causeway.mdc`,
four shims that sync writes and that each name the skills by path.

`v1.13.0` shipped `skills/field-note/` with a digested template, four seeded
surfaces, a Practitioner role in Build DNA that points at it, and a front door
telling a practitioner to open an agent and ask for a field note. All four
adapters still listed one skill.

The skill was therefore present, vendored, checksummed in every consumer's lock,
and unreachable by the only mechanism that reaches it. A practitioner following
`START-HERE.md` would have met an agent that had never been told the skill
existed, and the failure mode is the worst available one: the agent would not
say it was missing anything. It would write a plausible field note from its own
priors, which is precisely the outcome the skill's first rule exists to prevent.

`tools/render-adapters.sh` ran green through all of it. It asks whether each
adapter carries a generated marker and points at `AGENTS.md`. Both were true the
whole time. The check was not wrong; it was answering a different question.

This is the same shape as the finding one release earlier. ADR 0028 anchored the
bundle file count after discovering it was stated three times in the README and
checked by nothing — correct for its whole life because the underlying number had
never moved, and wrong within one commit of it moving. A derived list restated in
four documents is that again, and `skills/` had held one entry since the
directory existed. Two instances in consecutive releases is the reason this
becomes a check rather than a resolution to be more careful.

## Decision

Every skill the standard ships is named in every adapter, and
`tools/render-adapters.sh` fails the build when one is not.

The check walks `skills/*/`, requires a `SKILL.md` in each, and requires every
one of the four adapters to contain that skill's path. It is deliberately a
substring test on the path rather than a match against prose: the adapters say
different things in different voices because the tools read differently, and
binding their wording would be the guard-binds-a-rewrite failure ADR 0020 was
written about. What must not vary is whether the pointer is there at all.

The four adapters gain the `field-note` pointer, each in its own register.
`CLAUDE.md` gets a row in its skills table, naming the invocation triggers the way
the decision-spine row does. The three prose shims get a sentence describing the
situation rather than the artifact — *someone is telling you what they know about
the work rather than asking for code* — because an agent reading a shim needs to
recognize the moment, not look up a filename.

## Alternatives considered

**Ship the skills as `.claude/skills/` entries and rely on discovery.** This
would make the adapters unnecessary for Claude and do nothing for the other
three, so the pointer would still be the mechanism for most of the fleet and the
guard would still be needed. It is also a larger change to how `decision-spine`
has always worked, decided on the evidence of one bug. Recorded as Build DNA open
item 9 instead.

**Check the adapter text against the skill's `description` frontmatter.** Binds
prose that legitimately differs per tool, and would fail on a rewording that
improved it. ADR 0020 is the record of doing this once already.

**Fix the four files and move on.** The count in ADR 0028 had also been correct
every time anyone looked at it, right up until it wasn't. A list nothing derives
is a list that is accurate until the set moves, and the set moved twice in two
releases.

## Consequences

`v1.13.1`. A patch: the adapters a consumer receives are corrected, and no check
contract, verdict, input class or profile moves. The bundle digest changes
because `VERSION` is digested; nothing else in the bundle does.

A new skill now costs four adapter edits and the build says so immediately rather
than at the first practitioner who asks for something the agent has never heard
of. That is the intended cost.

One open item. Build DNA item 9: a pointer is not discovery, and this guard
checks only that the pointer exists. It takes the number withdrawn unpublished
during ADR 0028 — `v1.13.0` shipped the register ending at item 8, so no reader
has ever seen a different item 9 and the numbering rule's promise is intact.

## Evidence

- `tools/render-adapters.sh` — the skill-coverage loop, and its failure text.
- `adapters/CLAUDE.md`, `adapters/GEMINI.md`,
  `adapters/copilot-instructions.md`, `adapters/.cursor/rules/causeway.mdc`.
- `.github/workflows/standard.yml` — the step renamed for what it now checks.
- `AGENTS.md` — Build DNA open item 9.
