---
adr: "0038"
title: Govern as one maintainer in public — issues open, pull requests closed, continuity written down
status: Accepted
date: 2026-10-01
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A second person commits to maintaining the standard, or the issue queue
  shows outside contributors arriving with changes the maintainer would accept as
  written — either of which makes a closed pull-request queue cost more than it saves.
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

ADR 0037 licensed the standard. A license says what others may do with a copy; it
says nothing about how the original is run. [Issue
#5](https://github.com/deiotte/causeway/issues/5) listed what a public
reference standard owes beyond its license: who maintains it, who may review,
merge and release, how a normative change is proposed, how a vulnerability is
reported, what precedence model applies, and what happens if the maintainer
disappears.

None of that was written down, because nobody outside the author needed it. Making
the repository public changes who needs it.

The repository has one maintainer, and that is the fact every choice below is
fitted to.

## Forces

- **A change to the standard is a decision, and decisions here have a record.** The
  argument for a change — the alternatives, the forces, the evidence — is the
  valuable half of it, and Build DNA §8 puts that in an ADR the maintainer owns. A
  pull request carries a diff, which is the cheap half.
- **Outside copyright makes the license sticky.** ADR 0037, *Consequences*: once a
  contribution from someone else is merged under Apache-2.0 §5, relicensing needs
  their agreement. That is a reasonable cost to accept on purpose and a bad one to
  accept because a pull request looked small.
- **An unanswered queue teaches people to stop.** Build DNA's Practitioner role says
  a register nobody answers is worse than none, and teaches its contributors to
  give up faster than any other failure. One maintainer cannot promise review
  throughput on an open pull-request queue. They can promise an answer to every
  issue.
- **The most valuable contribution is not code.** Several of the standard's open
  items — Build DNA 4, 8 and 9 — wait on evidence from a project that did not write
  the standard. That evidence arrives as a report, not a diff.
- **The precedence model has a hole with a number on it.** The layering diagram
  names a managed policy tier that Causeway never drafted (Build DNA open item 1).
  Issue #5 asks for it to be resolved or explicitly scoped. Scoping is honest
  today; resolving it is a design job the item already describes.
- **Continuity cannot be a person yet, so it has to be a property.** There is no
  second maintainer to name. What can be said is what keeps working without the
  first one.

## Decision

**Issues are open to anyone. Pull requests are accepted only from the maintainer.
Every issue gets one of four dispositions, and its author is told which.**

The four dispositions are Build DNA's own for a field note — an ADR, a fix, a change
to a rule or template, or closed with a pointer to where it is already handled.
The maintainer writes the ADR when there is one and names the issue, and its
author, that shaped it.

Five files make that operational:

| File | What it holds |
|---|---|
| `GOVERNANCE.md` | The maintainer, their authorities, how a change is proposed and ships, the precedence statement, and the continuity plan |
| `CONTRIBUTING.md` | What contributions help, why pull requests are closed, and what happens to an issue |
| `SECURITY.md` | Private vulnerability reporting, and a scope that includes normative text — a rule that is unsafe to follow is a vulnerability in every system that follows it |
| `.github/CODEOWNERS` | Every path to the one maintainer |
| `.github/ISSUE_TEMPLATE/field-note.yml` | This repository's own field-note form, with the same prompts as the one `sync.sh` seeds into consuming projects |

**Precedence is scoped, not resolved.** `GOVERNANCE.md` states that the managed
policy tier belongs to the adopter, that Causeway cannot supply it, and that it
wins over Causeway where they disagree. What a managed policy should contain
remains Build DNA open item 1, which stays open.

**Continuity is stated as what survives.** Released archives install with no
network and no access to this repository (ADR 0030). Apache-2.0 lets anyone
continue the work as a fork under another name (ADR 0037). No successor is named,
and `GOVERNANCE.md` says so as a declared gap; a second maintainer is added by an
ADR that also settles how release-signing authority is shared.

None of these files is vendored. They govern this repository, not a consumer's,
and `bundle/scope.json` says so for each.

## Alternatives considered

**Open pull requests with a Developer Certificate of Origin sign-off.** The common
arrangement for a permissive project, and the one to move to when `revisit_if`
fires. Rejected for now on the throughput force: an open queue with one reviewer
is a promise this project cannot keep, and it would put outside copyright into the
tree before anyone has decided that the license is final.

**Open pull requests under a contributor license agreement.** Would preserve the
right to relicense. Rejected as the heaviest process for the smallest current
need, and as a reliable way to deter exactly the casual, field-experienced
contributor the standard most wants to hear from.

**No contribution channel at all — publish read-only.** Simplest. Rejected because
it publishes the standard without the one thing publishing it was for: outside
evidence about whether it works.

**Resolve the managed policy tier now.** Rejected as out of scope for a governance
change. It is a design question about what the tier must contain, and Build DNA
item 1 already owns it.

## Consequences

An outside contributor's path is an issue, and every issue ends somewhere they are
told about. The license stays the author's to change until the first outside
contribution is merged, which this decision postpones on purpose.

The maintainer takes on the same reciprocal obligation the standard puts on every
consuming project's owner: an answer to every note. That is a standing cost, and
an unanswered issue is the visible sign it is not being paid.

Issue #5 narrows to the second maintainer and the public-adoption checklist. The
checklist is the adopter guide that follows this ADR.

## Revisit if

A second person commits to maintaining the standard, or outside contributors start
arriving with changes the maintainer would accept as written. Either one makes a
closed pull-request queue cost more than it saves.

## Evidence

- `tools/validate.py` passes with every new path declared in `bundle/scope.json`.
- The bundle digest does not move: none of the five files is vendored.
