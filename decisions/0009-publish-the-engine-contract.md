---
adr: "0009"
title: Publish the engine contract — standard bundle, check specifications, conformance fixtures
status: Accepted
date: 2026-08-09
spine_rows: [SA-9.5, SA-9.6]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

This standard has never executed anything and was never going to. §1's second
design rule — *the gate reads files* — implies something else does the reading,
and `gate-configuration.md` has named a reference engine in its header since v0.1.

What was never written down is the seam. A reader learned that the engine implements
this document from a header line, learned which checks exist by counting rows in
a prose table, and learned what a check means by reading a paragraph that
sometimes existed. `profiles.json` carried the blocking matrix and nothing else:
it says `named-approvers` blocks at G0, and says nothing about what
`named-approvers` is, what it reads, whether it can be waived, or what it owes the
receipt.

An engine can be built from that. Two engines cannot be built from that and agree,
and one engine cannot be verified against it at all.

Three specific failures made this urgent rather than tidy:

**The vocabulary drift in ADR 0008.** `composition-state` blocks at all four
profiles and had three different answer sets in three files. Nothing caught it
because nothing could — no artifact stated what the check's valid values were, so
there was nothing for a checker to check.

**The exit codes had already forked.** §8 defines five codes with distinct
remedies. The implementing engine defines three, and its code `2` means *fatal
error* where this document's means *expired waiver*. Two systems have been using
the same integers for opposite conditions, and neither was wrong about its own
document.

**Nothing distinguishes a check that failed from a check that could not run.**
The engine reduces an exception inside a check to a warning, which is defensible
if the result vocabulary has no way to say otherwise — and it did not, because
this document never defined one.

## Decision

The standard publishes a machine-readable engine contract, in three parts.

### 1. `gate/checks.json` — what each check means

A specification per check: stable id, the question it answers, applicability,
waiver eligibility and form, the evidence keys it contributes to the receipt,
control mappings, spine rows, remediation text, the version that introduced it,
and an engine contract number.

The **stable id is the contract**. `named-approvers` means one thing forever. An
engine maps that id to whatever code it likes and the standard does not know or
care what language it is written in.

Also declared there: the **verdict vocabulary** (`pass`, `fail`, `waived`,
`not_applicable`, `not_run`, `advisory`, `unsupported`, `error`) and which
verdicts block. This is what makes "the check crashed" expressible.

### 2. Input classes, and a capability handshake built on them

Each check declares the **input classes** it must be able to read —
`repo-decisions`, `repo-manifests`, `repo-changeset`, `system-record`, and eleven
others. An engine declares the classes it can supply, not the checks it knows.

A required check whose input class the engine cannot supply resolves to
`unsupported` and **blocks**, at exit code 4. A profile can no longer silently
outrun its engine.

### 3. `bundle/manifest.json` — which bytes were evaluated

A deterministic manifest: every file in the standard with its sha256, and a bundle
digest over the sorted set. `sync.sh` writes the digest and the upstream commit
into `.causeway-lock`, and an engine records the digest in every receipt.

Conformance fixtures live in `conformance/`, with expected outcomes in
`expectations.json`, evaluated against a pinned date rather than the wall clock.

## Alternatives considered

**Per-check capability lists.** The obvious handshake: the engine enumerates the
check ids it supports. Rejected because it makes every new check a negotiation.
The standard adds `dr-plan-of-record`, every engine adds a line, and nothing about
any engine actually changed — it could already read `decisions/`. Input classes
make the declaration proportional to the capability: closing `repo-changeset` once
unlocks every check reading a changed-file set rather than one.

The rejection also surfaced the number that matters. Fourteen of 27 checks read a
`repo-*` class. An engine evaluating portfolio records and SBOMs is not most of the
way here whatever its check count suggests, and an input-class declaration says so
in one line rather than in a spreadsheet.

**Generating `checks.json` from `gate-configuration.md`.** Attractive — one source,
no drift. Rejected: the prose carries reasoning that no schema wants, and the
generator would become a second thing to maintain with worse failure modes than
the drift it prevented. Instead `tools/validate.py` asserts the two agree, which
gets the same guarantee without a build step in the middle of a document.

**Signing the bundle rather than digesting it.** Correct destination, wrong first
step. A signature needs a key, a holder, a rotation policy and a revocation story,
and none of those exist yet. The digest is the part that is useful immediately and
is a precondition for signing anyway — a signature is a signature *over* this
digest. Recorded as open item 10.

**Publishing all 27 conformance fixtures now.** Rejected as dishonest. A fixture
no engine executes is an untested assertion that reads like a guarantee. The five
in the Phase 1 slice are the ones about to be executed; the rest arrive with their
implementations.

## Consequences

The standard becomes verifiable rather than merely readable. `tools/validate.py`
ties `profiles.json`, `checks.json`, the prose table, the spine, `AGENTS.md`, the
bundle and the fixtures to each other on every push — 328 assertions, of which the
ADR 0008 drift is one.

An engine can now fail conformance, which it could not before. That is the point,
and it will be uncomfortable the first time.

`.causeway-lock` gains `digest=` and `commit=`. Existing locks lack both;
re-syncing writes them, the same migration `released=` had in v1.3.0.
`check-drift.sh` reports the digest and tolerates its absence.

**The gap this does not close.** A locally recalculated checksum proves the
vendored copy is internally consistent — that nobody edited it — and cannot prove
it came from us, because an edited copy recalculates just as cleanly. Verifying
the digest against a *trusted published* release is the missing half, and it needs
somewhere trusted to publish to. Open item 10.

The standard now ships four machine-readable artifacts where it shipped one. That
is more surface to keep consistent, which is precisely why the validator was
written first and why CI landed in the same revision (ADR 0010).
