---
adr: "0064"
title: Backfill systems that already exist, and upgrade in one pull request — two skills for the adoption Causeway actually gets
status: Accepted
date: 2026-11-17
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A backfill closes rows that a later review finds were never decided, or
  upgrade pull requests keep needing hand repair the skill did not describe.
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

Build DNA §4 says brownfield is the normal case. Every intake Causeway ships, the
Recon and the Survey, is for work not yet decided. The 2026-11-17 review found that
all three adopting projects adopted after they were built:

- **One** keeps 73 architecture ADRs in a separate concept-documents register and
  declared that second register on purpose, so the spine and `impact.sh` see none of them. 5 of 94 rows
  closed.
- **Another** keeps its real decisions in a ten-row *Locked decisions* table in
  `CLAUDE.md`. 2 of 94 rows closed.
- **The third**, the one with a Survey, closed 37 of 89.

The same review found the pins far behind: v2.11.0, v2.11.0 and v1.14.0 against
v2.16.0 on `main`, after about thirty releases in three months. Upgrading is a
command-line procedure, so it happens only when someone sits a session down to it,
and the maintainer works in the GitHub web UI.

## Forces

- **A backfill must not re-argue settled decisions**, and must not close a row by
  finding a sentence that sounds like an answer.
- **Coverage ADRs already exist for this** (ADR 0051): one record per foreclosing
  fact, about four lines each.
- **Accepted ADRs are immutable.** A backfill cites them; it does not edit them.
- **An upgrade is reviewed by a person in a browser.** The output has to be one pull
  request that says what the person needs to do first.

## Decision

1. **`skills/backfill/`**: read the placement and the open rows, inventory every
   place a decision already lives, write the Ground (`GR-`) rows those decisions
   rest on, then close rows with coverage ADRs (or retroactive ADRs for one-way rows
   answered by default), each citing its `GR-` facts in `forces`. Batches stay
   reviewable; rows that were never decided stay open and are listed.
2. **`skills/upgrade/`**: sync from the signed release archive, run
   `upgrade-starters.sh` and the checks, update what the project owns, and open one
   pull request whose body starts with what the reviewer must do in the web UI.
3. **Both are vendored, digested, and installed as Claude Code skill pointers**
   (ADR 0062).
4. **Reading a second register directly is deferred**: Build DNA open item 13.

## Alternatives considered

- **Tell brownfield projects to run the full Survey.** It asks for a design
  conversation that already happened, and the evidence is that it does not get run.
- **Let the backfill edit existing ADRs' frontmatter.** Breaks immutability for
  Accepted records; allowed only for `Proposed` ones.
- **Automate upgrades with a bot.** Possible later, as a scheduled routine that
  follows this skill. The skill is the procedure the routine would run.

## Consequences

**Easier.** A project that adopted late has a procedure that makes `impact.sh`,
doctor and the evaluator useful. Upgrades arrive as a pull request to read.

**Harder.** A backfill is real work for the maintainer to review: dozens of short
ADRs. The skill keeps batches small for that reason.

**Security.** A backfill surfaces the one-way rows a system answered by default,
which is where an unrecorded exposure would sit.

**Declared gaps.** Open item 13: a second register is cited, not read.

## Revisit if

A later review finds a backfilled row was never actually decided, or upgrade pull
requests keep needing hand repair.

## Evidence

- `skills/backfill/SKILL.md`, `skills/upgrade/SKILL.md`.
- `docs/build-dna/open-items.md` item 13.
