---
adr: "0021"
title: Close the document-of-record question and retire the reconciliation notice
status: Accepted
date: 2026-08-30
spine_rows: [SA-9.5, SA-9.6]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

`AGENTS.md` opened with a block quote titled *Reconciliation notice — read
before adopting*. It said the canonical `AGENTS.md` was not retrievable, that
this document was reconstructed from the working shape of the standard rather
than copied from its text, and then this:

> **If a repo copy of `AGENTS.md` still exists, it wins.** Diff it against this,
> keep its language, and take from here only the Causeway rename in §1 and the
> Spine seam in §8. If no copy exists, this becomes canonical and the
> reconstruction risk is retired by adoption.

ADR 0001 decided the opposite, on 2026-08-02, in the same repository:

> This repository is the document of record for the Causeway engineering
> standard.

Both statements have shipped inside the same digested bundle since v1.0.0 —
thirteen releases, v1.0.0 through v1.8.0, ADR 0001 having landed in the same
commit that first set `VERSION`. A consumer vendoring the standard receives a document of
record that instructs them to prefer a different copy if they can find one, and
an ADR telling them not to. The `standard-currency` check measures a project
against this bundle; the notice tells that project the bundle might not be
authoritative.

The contradiction is not academic. It is the repository's own README limit #1
and its first development priority, and it undermines the specific failure
ADR 0001 exists to prevent: a standard with no versioned home diverges, and
nobody can say which copy is real. A notice saying "some other copy wins" is
that divergence, written into the artifact that was built to end it.

Open item 2 has carried this since v1.0 — *until a repo copy is found or this is
formally adopted, every project instance is inheriting from a standard whose
canonical text is missing.* It named the two exits and then waited on neither.

## Decision

The reconciliation notice is retired. This repository is the document of record,
without qualification, as ADR 0001 decided.

The notice's own last sentence gives the closing condition and it has been met:
*if no copy exists, this becomes canonical and the reconstruction risk is
retired by adoption.* No copy was found. Adoption happened — thirteen releases,
a digested bundle, a signed release statement, ADRs governing the standard's own
changes, and a distribution mechanism exercised by CI on every push. There is
nothing left to reconcile against.

Build DNA moves to 1.6 and open item 2 closes in place, keeping its number and
carrying the resolution, per the numbering rule this document now states
explicitly.

What the notice was right about is preserved rather than discarded: the risk it
named was real, and the reason the standard has a lock file, a digest, a drift
check and a release signature is that this exact thing happened once. That
history belongs in the ADR record and in `CHANGELOG.md`, which is where a reader
looks for how a standard got its shape. It does not belong in a header that
tells every adopter their copy might be wrong.

## Alternatives considered

**Search for the canonical text once more, then decide.** The disciplined-looking
option. Rejected because it has been available for thirteen releases and the
notice itself does not require it: the condition is *if no copy exists*, and the
absence of a copy across a year of releases and at least one project that
shipped a reconstruction is the evidence. Waiting longer produces no new
information and the contradiction ships again in the meantime.

**Keep the notice and soften it to a historical footnote in the header.**
Rejected. A header is read as current, and the operative sentence — another copy
wins — cannot be softened without being reversed. Reversing it is this ADR.
The history is preserved where history goes.

**Reverse ADR 0001 instead: declare the missing canonical text authoritative and
this repository a reconstruction of it.** The honest other half of the fork, and
it fails on availability. A document of record nobody can retrieve cannot be
diffed, pinned, digested or vendored, and every mechanism this repository has
built assumes a copy that exists. Choosing an unavailable authority is choosing
the failure mode ADR 0001 was written about.

**Close it silently by deleting the notice.** Rejected. The notice is inside the
digested bundle; it is in every vendored copy of the standard in every consuming
project. A deletion with no record leaves those readers with a document that
changed its central claim and no way to learn why.

## Consequences

The standard tells one story about its own authority. A project that vendors it
can answer "which copy is real" from the artifact rather than from an ADR that
contradicts the artifact.

README limit #1 and development priority #1 are closed by this ADR.

Every existing vendored copy still carries the notice until it re-syncs, and
`check-drift.sh` will not flag that — it compares a copy against its own pin,
not against the current release. The mechanism that surfaces it is
`standard-currency`, which measures age. This is the ordinary way a prose change
reaches consumers and it is not instant.

The reconstruction risk is now genuinely retired rather than pending. If the
original text ever surfaces, it is a historical document and an interesting one.
It is not a competing authority, and no future reader has to adjudicate between
two copies without a rule.

## Evidence

`AGENTS.md` — header reads **Version: 1.6 — document of record**, with no
reconciliation notice. Open item 2 marked closed in place with the resolution.

`decisions/0001-adopt-causeway-standard.md` — unchanged, and now uncontradicted
by the document it governs.

`CHANGELOG.md` — the v1.9.0 entry records the closure and the thirteen-release
overlap.

`./tools/validate.py` — clean, including the AGENTS.md version-header check
ADR 0012 added.
