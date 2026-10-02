---
adr: "0035"
title: Give the contributor a front door, and seed it where GitHub already looks
status: Accepted
date: 2026-09-29
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A project that did not author the standard onboards a developer through
  the seeded CONTRIBUTING.md and reports how long the Contributor floor actually took
  — at which point Build DNA open item 4 has its first measurement, and this file's
  shape can be judged against it rather than against the people who wrote it.
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Build DNA names four adoption roles and gives each a floor. Only one of them has a
front door.

The Practitioner gets `START-HERE.md`: about a hundred and fifty plain-language
lines, seeded by `sync.sh`, written for somebody who has never seen a repository,
ending in a five-step version of the whole job. ADR 0028 built it on the argument
that handing somebody `AGENTS.md` selects for tolerance of process rather than for
what the project actually needs from them.

The Contributor gets that argument's opposite. Their floor is "everything above,
plus five things," and *everything above* is the Reader floor: *read the project's
`CLAUDE.md`. That is the whole obligation.* On a freshly synced project `CLAUDE.md`
is `templates/project-CLAUDE.md` — a thin reference card with `build:` and `test:`
and nothing after them — which imports seven hundred lines of `AGENTS.md`. The
five things are in `AGENTS.md`, in the adoption section, in prose. Nothing walks a
new developer from clone to first merge, and nothing tells them what a reviewer
will check.

The practitioner template made this visible without meaning to. Its second
paragraph reads *if you write software, you want `CLAUDE.md` instead* — sending
the developer to a file that is not written for arriving.

The shape that works was found in a consuming repository first, the way the
placement block was (ADR 0032). That project wrote a `docs/ONBOARDING.md` — what the
thing is in plain words, a glossary, setup as numbered steps with the expected
output of each, the rules that cannot be broken, where things live, how to work a
task with an assistant, a reading list in order — and a pull request template whose
checklist restates the rules as boxes. Both were written for one project and
neither knew the Contributor floor existed. This ADR promotes the shape and puts
the floor in it.

## Forces

- **Three of four roles route through a file nobody wrote for arriving.** Reader,
  Contributor and Maintainer all start at `CLAUDE.md`. A reference card is the right
  thing for the second visit and the wrong thing for the first.
- **The floor is stated and not walked.** Five obligations, in order, in prose in a
  document the floor itself says a contributor does not need to read. The order is
  the valuable part — gate before code, exceptions before defaults — and prose does
  not enforce order.
- **A reviewer's checklist exists only in the reviewer's head.** `tests-with-source`
  is the only part of the Contributor floor a gate reads (§7). The rest is a review
  property, and a review property nobody has written down is reviewed differently by
  every reviewer.
- **Discovery that depends on prose being obeyed is not discovery.** Build DNA open
  item 9 records this for skills. A contributor front door that only a pointer in
  `CLAUDE.md` names inherits the same failure. GitHub already links
  `CONTRIBUTING.md` from every new pull request and issue page, and already fills a
  new pull request body from `.github/pull_request_template.md`. Those are places a
  developer looks without being told to.
- **The template it came from is too specific to ship.** That project's rules —
  append-only annotations, immutable PDFs — are its own. What generalizes is the shape and the
  Causeway half of the rules.

## Decision

`sync.sh` seeds two more project-owned files, on the terms it already seeds
`START-HERE.md` and `CODEOWNERS`: written once if absent, never overwritten, declared
ungoverned in `bundle/scope.json`, carried in the release archive.

- **`templates/contributor-START-HERE.md` → `CONTRIBUTING.md`.** The Contributor
  floor walked in the order a new developer meets it: what the project is, what
  Causeway is in one paragraph, a glossary, setup as numbered steps each with an
  expected result (including `check-drift.sh`), the five obligations, the rules that
  cannot be broken — Causeway's, then a bracketed slot for the project's — where
  things live, a seven-step loop for working a task with an AI assistant, and a
  reading list that puts `AGENTS.md` last. Every project-specific line is a
  `[BRACKET]`.
- **`templates/pull_request_template.md` → `.github/pull_request_template.md`.**
  *What and why*, *How I checked it*, a Causeway checklist that restates the
  Contributor floor and §5–§8 as boxes, and a bracketed section for the project's
  own rules.

The two existing entry points are re-aimed at it. `templates/project-CLAUDE.md`
gains a two-line *New here?* pointer under the import. `templates/practitioner-START-HERE.md`
sends a developer to `CONTRIBUTING.md` instead of `CLAUDE.md`. Both are seed
templates, so neither change reaches a project that has already synced — which is
correct, because those files are the project's now.

`AGENTS.md` does not change. The floor is the same floor; this is a door onto it.

## Alternatives considered

- **Rewrite the Contributor floor in `AGENTS.md` as a walkthrough.** Moves Build DNA,
  the bundle digest and every consumer's pin to say something the floor already
  says. And the walkthrough needs the project's own commands and names, which a
  vendored file cannot hold without every project's values reading as drift.
- **Put the walkthrough in `templates/project-CLAUDE.md`.** That file says *thin by
  design* and *under ~200 lines* in its first comment, and an agent reads it on
  every session. A twenty-minute on-ramp in a file read on every turn is paid for on
  every turn, forever, by a reader who needed it once.
- **Seed it as `docs/ONBOARDING.md`,** where that project put it. Nothing links there
  unless something names it, which is open item 9's failure. `CONTRIBUTING.md` is
  linked by the platform.
- **Also seed a `system.json` stub,** since step 1 of the floor is *read
  `system.json`* and nothing creates one. Declined. A stub with values is a
  placement nobody declared, which is the silent-default failure ADR 0032 exists to
  end; a stub with empty values is a file the gate reads as present and malformed.
  The front door instead says what to do when the file is absent — do not write one,
  tell the owner, point them at `placement.md` — and that is a decision for someone
  with the authority, not a template.
- **Make the PR checklist a gate check.** §9: a checklist is guidance, and ticking a
  box is not evidence. The parts a machine can read are already checks
  (`tests-with-source`, drift, secrets). This makes the rest visible, not enforced.

## Consequences

- A newly synced project has a developer on-ramp and a reviewer checklist on day
  one, both carrying placeholders that say plainly they are unfilled.
- The Contributor floor is restated in two more places. Where they disagree,
  `AGENTS.md` wins and the template has a bug — the template's own header says so.
  Nothing checks the restatement; it is seeded once, so a project's copy is its own
  from then on and cannot be checked against the standard anyway.
- Existing consumers get nothing until they re-sync, and then only if they have no
  `CONTRIBUTING.md` or PR template already. A project with its own keeps it. That is
  the same bargain every seeded file makes.
- The *Contributor floor costs an afternoon* claim (Build DNA open item 4) is still
  an estimate by the people who wrote it. This makes it cheaper to measure, because
  there is now one path through it to time. It does not measure it.

## Revisit if

A project that did not author the standard onboards a developer through the seeded
`CONTRIBUTING.md` and reports how long it took and where they got stuck. Also if
GitHub stops surfacing `CONTRIBUTING.md` on new pull requests, which removes the
reason for the filename.

## Evidence

- `templates/contributor-START-HERE.md` and `templates/pull_request_template.md`.
- `tools/sync.sh` — two seed blocks, after `START-HERE.md` and after `CODEOWNERS`.
- `tools/build-archive.sh` — both templates in `ARCHIVE_FILES`; `tools/validate.py`
  §19 fails if either is read by `sync.sh` and missing from the archive.
- `bundle/scope.json` — both declared ungoverned, with reasons.
- `.github/workflows/standard.yml` — the scratch-project sync asserts both seeded
  files exist.
