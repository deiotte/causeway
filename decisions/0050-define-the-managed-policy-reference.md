---
adr: "0050"
title: Define the managed policy reference — what a project records about its organization's floor, and who alone can grant an exception
status: Accepted
date: 2026-10-09
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: An adopter's managed policy will not fit the reference — a policy with no
  version, no named exception authority, or several authorities for one text — or an
  adopter asks for a gate check that reads it. The first changes the format. The second
  is a gate configuration decision with its own warn cycle.
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

Build DNA's layering diagram puts managed policy above everything — "non-negotiable org
floor (ATO/CSfC, secrets handling)" — and says specific wins except that managed policy is
never overridden. Open item 1 has said since v1.0 that the tier was referenced and never
drafted: "the only tier a developer cannot override, which makes it the one that most needs
to exist." `GOVERNANCE.md` repeated it: Causeway still owed a description of what the tier
should contain and how a project finds it.

Without that, a team, an agent and an evaluator cannot tell an organizational obligation
from a project preference. The failure is concrete: a team "fixes" a deviation from a
policy it did not know it was under, or grants itself an exception to one because nothing
said the exception was not its to grant.

Issue #14 asks for the contract: how a project references its policy, how the policy is
pinned and found offline, how conflicts are recorded, who can approve an exception, a
worked example separating policy from customer constraint from project default, and a
statement of what is checked and what is guidance.

## Forces

- **Causeway cannot supply the policy.** It belongs to the adopter's security office,
  authorizing official, records and legal obligations. The standard can only define the
  reference a project keeps to it.
- **A reference has to be findable offline.** Build DNA §6 builds with no network. A
  policy that lives only at a URL is a policy an enclave build cannot read.
- **A pin needs a version and a hash, and a pin needs revisiting.** Build DNA §3 applies to
  policy text as much as to code: which copy, and how would anyone know if it moved.
- **The exception authority is a person outside the project.** Build DNA §8 already
  requires a named individual where accountability matters. A project that could approve
  its own exceptions to managed policy would be the tier below overriding the tier above.
- **Silence is not "none".** A project with no managed policy has to be able to say so,
  and saying so has to look different from never having checked.
- **The tool cannot authenticate an approval.** A name in a file is an assertion. The
  approval lives in the authority's own system, and the record has to point there.

## Decision

**`skills/decision-spine/reference/managed-policy.md`** is the contract, vendored and
digest-covered. It separates three kinds of requirement by one test — *who would have to
sign to change it?* — and gives each its home: managed policy in the policy reference,
customer constraints in Survey `GR-` rows, project defaults in `CLAUDE.md` and ADRs.

**`.causeway/policy.json`** is the reference, format `causeway-managed-policy-v1`. The
template is `templates/managed-policy.json`, vendored. The file itself is the project's:
not vendored, not locked, not re-seeded. Each policy records:
- `id`, `title`, `version`, `authority`
- `effective` and `review_by` dates
- `applies_because`
- `precedence` among the project's managed policies
- `source`
- `copy` and `sha256` — the offline pin
- `exception_authority`, a person by name and role

A policy that may not be committed sets `copy` to `null` and records `held_at`. That pin is
reported unverified, never ok. A project with no managed policy records `none` with the
reason.

**Conflicts:**
- **Policy against Causeway** — the policy wins without asking. The project records the
  deviation from Causeway by ADR and exceptions-register row, citing the policy clause.
- **Project against policy** — only the policy's `exception_authority` can grant it. The
  exception records clause, ADR, approver by name and role, date, expiry and evidence.
- **Customer against policy** — an `OPEN-` row naming both authorities. Causeway takes no
  side.
- **Policy against policy** — `precedence` says which the project follows meanwhile. An
  ADR records the conflict.

**`tools/doctor.sh`** reads the reference, advisory like everything it reports:
- `policy.reference` — present and readable, or `none` with a reason
- `policy.<id>` — required fields, `review_by` not past, the copy present and matching its
  hash
- `policy.exception.<n>` — every field present, the approver's role matching the policy's
  exception authority, the ADR on disk, not expired

A fresh sync therefore reports `.causeway/policy.json` incomplete until the project
records something.

**Build DNA 1.14** names the reference in the layering section and closes open item 1. The
ServiceNow overlay is re-ratified at 1.13 against it, and gains a row: the platform team's
instance governance is managed policy for an application built on it.

## Alternatives considered

- **Ship a default managed policy.** Causeway would be writing the one tier it is never
  allowed to be. An organization adopting a policy because the standard shipped one has
  not adopted a policy.
- **A section in `CLAUDE.md`.** Readable by agents, unreadable by a tool, and mixed in with
  the project's own choices, which is the confusion the tier exists to prevent.
- **A URL only.** Fails offline, and says nothing about which version the project was built
  against.
- **A blocking gate check.** The gate configuration requires a warn cycle before any new
  blocking behavior, and nothing has been measured. Doctor reports it; a gate may read the
  same file later.

## Consequences

Every project now has a place to say what it is under, and a fresh sync tells it so. A
project with no policy pays one line. A project under one pays one file and a committed
copy, and gets told when its review date passes or its copy no longer matches its pin.

The approval itself stays where the authority keeps it. Doctor checks that the record of
the approval is complete and consistent. It does not check that the approval happened,
and says so in every finding it reports `ok`.

Open items: Build DNA item 1 closes. The index records it. Nothing new opens: the
candidate gate check is named in the contract's last section and the revisit trigger, as
the other doctor-only findings are.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-doctor.sh`: 62 passed, 15 of them new. It covers:
  - a fresh sync reporting the reference incomplete
  - `none` with a reason ok, and with no reason incomplete
  - a valid pinned policy ok
  - a hash mismatch, a passed review date and a missing field incomplete
  - a held copy unverified
  - a valid exception ok
  - an expired exception, an approver whose role is not the exception authority's, and
    an exception whose ADR is not on disk, each incomplete
- `tools/validate.py` passes with the overlay re-ratified against Build DNA 1.14 and
  item 1 closed by this ADR.
