---
adr: "0060"
title: Hold everyday code and review to a security floor — a broader security rule, a patch-window rule, and security prompts in the PR and ADR templates
status: Accepted
date: 2026-11-16
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: Pull requests in an adopting project routinely tick the Security boxes with
  nothing written beside them, or ADRs fill the Security consequence with "None" on
  changes that plainly moved a boundary. Either means the prompts became ceremony and
  need to be fewer or sharper.
approver:
  name: Karl
  role: Maintainer
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

ADR 0059 gave the gate two security checks. A gate check runs after the code is
written. The cheapest place to stop a vulnerability is earlier: in the instructions
the coding agent reads while it writes, and in the review a person does before
merge. Causeway's floor at those two points was thin.

- **`rules/security.md` was ten lines, scoped to API folders.** It covered timeouts,
  retries, adapters and unhappy-path tests. It said nothing about input validation,
  object-level authorization, output encoding, error leakage, server-side request
  forgery, cryptography, or static analysis — the classes OWASP lists first and the
  classes generated code gets wrong most often.
- **`rules/dependencies.md` covered adding a dependency and nothing about keeping
  one current.** ADR 0059 introduced remediation windows; nothing a contributor
  reads mentioned them.
- **The PR template had one security line**: no secrets or real data in the diff.
  Nothing asked whether the change touched authentication, a trust boundary, or the
  Survey's `TH-` rows (ADR 0057).
- **The ADR template's Consequences section** asked what gets easier and harder and
  never asked about security, so an ADR that moved a trust boundary could say nothing
  about it and look complete.

## Forces

- **Rules are guidance; checks are enforcement** (Build DNA §9). Neither replaces the
  other. A rule that says "authorize the object, not the role" is what prevents the
  bug a static analyzer cannot see.
- **A checklist that is too long gets ticked without reading.** The PR template's
  Security block has five boxes and each one names a concrete trigger.
- **"None" and blank are different claims.** A blank security consequence cannot be
  told apart from a question nobody asked.
- **Starters are the project's.** The PR template is seeded once and then owned;
  `upgrade-starters.sh` offers the new block by three-way merge, and a project that
  edited the template keeps its edits.

## Decision

- **`rules/security.md` becomes the application security floor**, path-scoped to
  source, routes, handlers, controllers, views, templates, middleware and auth code.
  Sections: every input (allowlist validation, no string-built queries, commands,
  paths or templates, uploads and deserialization), every request (authorization on
  every request at the SA-5.2 enforcement point, object-level checks, deny by default,
  session and token handling, CSRF), every output (context encoding, errors that leak
  nothing, logs that hold no secrets), every outbound call (the existing timeout,
  retry, idempotency and adapter rules, plus server-side request allowlists),
  cryptography, static analysis, and a "before done" list that asks for one abuse
  test per defended threat. OWASP ASVS is named as the fuller checklist.
- **`rules/dependencies.md` gains *Keeping current***: scan the SBOM in CI, windows
  as deadlines, automated update PRs reviewed rather than auto-merged, and updates on
  a cadence.
- **`templates/pull_request_template.md` gains a Security block** of five checkboxes:
  security-sensitive areas named and reviewed, new inputs and routes tested against
  the rule, `TH-` rows and Survey boundaries amended, analyzer and scan results
  handled, agent-written diffs read against `rules/agent-workspace.md`.
- **`templates/adr-template.md`** gains a **Security** line under Consequences, and
  `TH-` in the `forces` comment.

## Alternatives considered

**Adopt OWASP ASVS wholesale as the rule.** Rejected. ASVS is hundreds of
requirements across levels; an agent reading it on every file is reading a standard,
not a floor. The rule names it as the fuller checklist and carries the items that
recur.

**A separate `rules/appsec.md`, leaving `security.md` alone.** Rejected. Two files
named for security would split the floor and the old one's API-only scope would keep
looking like the whole story.

**A required "security reviewed" label or check.** Rejected for the starter. Who
counts as a security reviewer is the project's call, recorded in its CODEOWNERS and
branch protection. The template asks the question; the repository settings enforce
the answer.

## Consequences

**Easier.** An agent writing a handler reads the authorization and encoding rules at
the moment it writes it. A reviewer has five concrete triggers instead of one. An ADR
that moves a boundary says so.

**Harder.** Security-relevant pull requests carry a little more text. ADRs owe one
more line.

**Security.** This is the change: it raises the guidance floor for every adopting
project, and it moves no enforcement. The gate checks in ADR 0059 and the scans in CI
remain the controls.

**Declared gaps.**

- **Nothing checks that the boxes were read.** A ticked box is a claim, as it always
  was.
- **The rule is language-neutral**, so it cannot say which library call is the safe
  one in a given stack. That belongs in the project's `CLAUDE.md`.
- **Existing projects get the PR block only if they take the starter upgrade.**

## Revisit if

The Security boxes are routinely ticked with nothing written, or the Security
consequence routinely says "None" on changes that moved a boundary. The frontmatter
states both.

## Evidence

- `rules/security.md`, rewritten; `rules/dependencies.md`, *Keeping current*.
- `templates/pull_request_template.md`, the Security block.
- `templates/adr-template.md`, the Security consequence and the `forces` comment.
