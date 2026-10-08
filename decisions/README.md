# Decisions

Causeway's own architecture decision records: every contested choice about the
standard itself, from the day it became the document of record. One decision per
file. One file per decision.

This is this repository's record, not a consumer's. The release archive carries
no `decisions/`, and `tools/validate.py` fails if it does; a project that vendors
the standard gets [`templates/decisions-README.md`](../templates/decisions-README.md)
seeded as the start of its own.

The rules are Build DNA §8 in [`AGENTS.md`](../AGENTS.md). How a change to the
standard becomes a decision at all is [`GOVERNANCE.md`](../GOVERNANCE.md). This
file is the short version of the first, plus the index at the bottom.

## Writing one

Copy the template, take the next number, fill it in, and add a row to the index
below — in the same pull request as the change that encodes the decision.

```
cp templates/adr-template.md decisions/0042-short-imperative-title.md
```

Three templates, one per shape of decision:

| You are recording | Template |
|---|---|
| A choice between real alternatives | [`adr-template.md`](../templates/adr-template.md) |
| A row you are deliberately not closing yet | [`adr-waiver-template.md`](../templates/adr-waiver-template.md) — expiry, risk accepted, a named acceptor |
| A row the spine added after a system shipped | [`adr-retroactive-template.md`](../templates/adr-retroactive-template.md) — as-built answer first, corrected design last |

Quote the number in the frontmatter: `adr: "0010"`, never `adr: 0010`. YAML
reads an unquoted leading zero as octal, so `0010` parses as 8 and nothing
complains. [ADR 0017](0017-quote-the-adr-identifier.md) learned that the slow
way, and the validator now refuses an unquoted one.

## Numbering

- **Four digits, zero-padded, next free number.** The number is an identity, not
  a rank.
- **Never reused and never renumbered.** Other ADRs, `open-items.json`, the
  CHANGELOG and comments in the tools all point at these numbers. Renumbering is
  how a pointer comes to name a different decision than the one it cited.
- **A skipped number is allowed and stays skipped.** Two branches take the same
  number and one is abandoned; a draft is withdrawn before it merges. Do not close
  the gap. Record it under *Unused numbers* below with one line saying why. The
  validator checks that every skipped number is named there.

## Immutability

An accepted ADR is a record of what was decided and why, as of its date. Its body
is not edited. What you do instead depends on what changed:

| What happened | What to do |
|---|---|
| You changed your mind | A new ADR with `supersedes:` naming the old one and a `supersession_cause:` (S1–S5, Build DNA §8). Set the old one's `superseded_by:` and its status to `Superseded`. |
| The old ADR states a fact that was wrong | A new ADR with `corrects:` naming it. Set the old one's `corrected_by:`. The wrong sentence stays; the pointer to the right one is what a reader needs. [ADR 0027](0027-correct-the-counts-and-make-a-correction-findable.md) is the worked example. |
| A waiver expired or the risk changed | A new ADR closes the row, or a new waiver with a new expiry. An expired waiver is a gate failure, which is the point. |
| A typo, a broken link, a formatting slip | Fix it. Immutability protects the argument, not the markdown. |

Frontmatter is the mutable half by construction: `status`, `superseded_by` and
`corrected_by` cannot be known when an ADR is written, so filling them in later
is the design and not a breach. The validator checks that `corrects` and
`corrected_by` name each other.

One exception is on the record. [ADR 0036](0036-redact-other-projects-before-publication.md)
edited eight accepted ADRs in place to redact the names of other projects before
publication, and says why supersession was the wrong tool for that. It is an
exception because it is written down as one.

## Reading one

| Field | What it tells you |
|---|---|
| `status` | `Proposed`, `Accepted`, `Deferred`, `Waived`, `Deprecated`, `Superseded`. Only `Accepted` is a decision in force. |
| `spine_rows` | The Decision Spine rows this closes. Most of this repository's ADRs close none — they are about the standard, not a system built under it — and say so in a comment. |
| `door` | `one-way` or `two-way`. |
| `approver` | A named person. Required on the eight † rows; filled in here anyway, because a human owns every merge. |
| `forces` | The Survey rows that made one alternative win. This repository ran no Survey, so its ADRs carry a Forces section in prose instead and say so in the field's comment. |
| `revisit_if` | The condition under which reopening this is legitimate rather than churn. |

## What an ADR leaves behind

An ADR that declines a question, defers a guard, or publishes a gap opens an
**open item**. The item's argument lives in prose, in one of four registers —
Build DNA, the gate configuration, the spine, the ServiceNow overlay. Its state
lives in [`open-items.json`](open-items.json), and `tools/validate.py` §17 and §18
check the index against every register it names. If your ADR opens or closes
one, edit the index in the same pull request.

## Index

By family, not by number: the number says when, the family says what it is about.
One row per ADR, added in the pull request that adds the file. The validator
checks that every ADR on disk is linked from this page and every link resolves;
which family a record belongs to is a judgment, and yours is welcome.

### Document of record

What this repository is, and what it is not.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-adopt-causeway-standard.md) | Adopt the Causeway standard as the engineering document of record | Accepted |
| [0012](0012-decouple-the-build-dna-version.md) | Decouple the Build DNA version from the standard's release number | Accepted |
| [0014](0014-bound-the-repository-scope.md) | Bound the repository to the process layer, and enforce that boundary in CI | Accepted |
| [0021](0021-close-the-document-of-record.md) | Close the document-of-record question and retire the reconciliation notice | Accepted |

### Build DNA

The process layer's content.

| ADR | Decision | Status |
|---|---|---|
| [0002](0002-disfavor-npm-hosted-dependencies.md) | Treat the package registry as inside the authorization boundary, and disfavor npm | Accepted |
| [0003](0003-one-prompt-one-commit.md) | Bind one commit to one prompt, and gate only the part CI can see | Accepted |
| [0022](0022-publish-build-dna-1.6.md) | Publish Build DNA 1.6 — adoption contract, declared gaps, pinning, offline builds, gate routing | Accepted |

### Decision Spine

The design layer's content, and how a system arrives at its obligations under it.

| ADR | Decision | Status |
|---|---|---|
| [0004](0004-govern-the-inference-boundary.md) | Govern the inference boundary — tool surface and pre-inference data egress | Accepted |
| [0005](0005-ratify-the-adoption-horizon.md) | Ratify the adoption horizon as the spine version-drift policy | Accepted |
| [0008](0008-reconcile-composition-state-vocabulary.md) | Reconcile the composition-state vocabulary on SA-3.13 | Accepted |
| [0032](0032-say-how-a-system-gets-placed.md) | Say how a system gets placed, and ship no check to enforce it | Accepted |
| [0034](0034-close-the-one-way-deadline-against-the-spine.md) | Close the one-way deadline against the spine, not against a release | Accepted |

### Gate and engine contract

What an engine owes, what it reads, and how a check earns the right to block.

| ADR | Decision | Status |
|---|---|---|
| [0006](0006-promote-tests-with-source.md) | Promote tests-with-source on its definition, behind a derived release marker | Accepted |
| [0009](0009-publish-the-engine-contract.md) | Publish the engine contract — standard bundle, check specifications, conformance fixtures | Accepted |
| [0033](0033-read-release-evidence-not-tag-topology.md) | Read release evidence, not tag topology | Accepted |

### Platform overlays

Relocating the standard into somebody else's prepared ground.

| ADR | Decision | Status |
|---|---|---|
| [0007](0007-adopt-platform-overlays.md) | Adopt platform overlays, and ship ServiceNow as the first | Accepted |
| [0011](0011-reconcile-the-servicenow-overlay.md) | Reconcile the ServiceNow overlay, and make overlay staleness a build failure | Accepted |
| [0013](0013-publish-the-overlay-in-machine-readable-form.md) | Publish the ServiceNow overlay in machine-readable form, and state the platform posture | Accepted |
| [0024](0024-reconcile-the-servicenow-overlay-to-build-dna-1.6.md) | Reconcile the ServiceNow overlay to Build DNA 1.6, and guard the field that let it drift | Accepted |

### Distribution

Pinning, signing, and installing — which copy, and how anyone would know if it moved.

| ADR | Decision | Status |
|---|---|---|
| [0015](0015-record-the-release-a-lock-was-synced-from.md) | Record in the lock which release a copy was synced from | Accepted |
| [0019](0019-sign-releases-with-ssh.md) | Sign releases with SSH, and make the digest something a consumer verifies | Accepted |
| [0023](0023-reconcile-the-signing-state-prose.md) | Reconcile the signing-state prose, and guard the claim against the artifact | Accepted |
| [0030](0030-install-without-git.md) | Install without git, and let the signature be the release proof | Accepted |
| [0040](0040-issue-a-new-release-signing-key.md) | Issue a new release-signing key before the first public release | Accepted |
| [0042](0042-install-completely-or-not-at-all.md) | Install completely or not at all — decide, plan, stage, then apply | Accepted |

### The standard's own CI and record-keeping

How this repository checks itself, and how its record stays honest.

| ADR | Decision | Status |
|---|---|---|
| [0010](0010-adopt-ci-for-the-standard.md) | The standard runs its own gate | Accepted |
| [0017](0017-quote-the-adr-identifier.md) | Quote the ADR identifier, because YAML reads leading zeros as octal | Accepted |
| [0018](0018-one-run-one-job.md) | One run per commit, and one job per run | Accepted |
| [0020](0020-anchor-prose-guards-to-the-claim.md) | Anchor the prose-count guards to the claim rather than to the sentence | Accepted |
| [0025](0025-index-the-open-items-adrs-leave-behind.md) | Index the open items ADRs leave behind, and check the index against the registers. Corrected by 0027. | Accepted |
| [0026](0026-make-cross-register-relations-real.md) | Make relations between open items real, and enforce what each kind promises. Corrected by 0027. | Accepted |
| [0027](0027-correct-the-counts-and-make-a-correction-findable.md) | Correct the derived counts ADRs 0025 and 0026 stated wrong, and make a correction findable from the record it corrects | Accepted |
| [0041](0041-seed-the-decision-register-with-its-own-readme.md) | Seed the decision register with its own README, and index this repository's by family | Accepted |

### People

Roles, intake, and front doors.

| ADR | Decision | Status |
|---|---|---|
| [0028](0028-admit-the-practitioner-and-owe-them-an-answer.md) | Admit the practitioner, and owe them an answer | Accepted |
| [0029](0029-make-a-shipped-skill-reachable.md) | Make a shipped skill reachable, and check that it stays reachable | Accepted |
| [0031](0031-adopt-the-survey-as-the-intake-layer.md) | Adopt the Survey as the intake artifact, and earn its gate before spending it | Accepted |
| [0035](0035-give-the-contributor-a-front-door.md) | Give the contributor a front door, and seed it where GitHub already looks | Accepted |

### Publication and governance

Going public, and who decides what once there.

| ADR | Decision | Status |
|---|---|---|
| [0016](0016-require-checks-not-approvals.md) | Require status checks rather than approvals while there is one maintainer | Accepted |
| [0036](0036-redact-other-projects-before-publication.md) | Redact the names of other projects before publication, and say so here | Accepted |
| [0037](0037-license-under-apache-2.0.md) | License the whole standard under Apache-2.0, and carry the license into every copy | Accepted |
| [0038](0038-govern-as-a-single-maintainer-in-public.md) | Govern as one maintainer in public — issues open, pull requests closed, continuity written down | Accepted |
| [0039](0039-publish-from-a-fresh-history.md) | Publish from a fresh history, and carry the open issues across by number | Accepted |

## Unused numbers

None. Every number from 0001 to the highest in use is a file. When one is
skipped, it gets a line here: the number, and why.
