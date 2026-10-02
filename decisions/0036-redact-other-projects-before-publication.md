---
adr: "0036"
title: Redact the names of other projects before publication, and say so here
status: Accepted
date: 2026-10-01
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A redacted passage turns out to have carried an argument and not only a
  name — a reader cannot follow a worked example or an alternative without knowing
  which system it was about. That passage gets rewritten so the argument stands on
  its own; the name does not come back.
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

The standard is going public. Its author owns it, and that is settled. What is not
the author's to publish is the name of every other project, program and internal
artifact the standard learned from along the way.

The standard learned from a lot of them, and said so in its text. A consuming
engine was named in the gate configuration's header, in five ADRs, in the overlay
index and in a worked placement example. A consuming project was named as the
source of the open-items index (ADR 0025), another as the source of the
contributor front door (ADR 0035), a third as the Survey's first audit target (ADR
0031). Build DNA §10 listed six callsigns as the bar for naming. Build DNA's
migration note named the standard's previous name and the concept decks it
appeared in. A project template offered two agency names as examples of customer
context.

None of that is an argument. Every passage made its point about a *kind* of system
— an engine, a consuming project, an air-gapped appliance — and used a real name
because one was to hand. A reader outside the room gets nothing from the name and
the project behind it gets an exposure it never agreed to.

The awkward part is §8. ADRs are immutable and superseded rather than edited, and
eight accepted ADRs carry such passages.

## Forces

- **Ownership of the text is not ownership of the names in it.** The standard is
  the author's to license. A program's name, a customer's name, or a consuming
  project's internal practice is not, and publishing it is a disclosure on their
  behalf.
- **Immutability protects the argument, not the nouns.** §8 makes ADRs immutable
  so that the reasoning a decision rested on cannot be quietly rewritten after the
  fact. ADR 0027 already drew the line this ADR uses: frontmatter is the mutable
  half because what goes there was never the argument. A proper noun that can be
  replaced by its category without changing a single claim is on the same side of
  that line.
- **A redaction nobody declares is indistinguishable from a rewrite.** This is the
  §8 declared-gaps rule applied to the record itself. Editing eight accepted ADRs
  silently would be the exact failure immutability exists to prevent, whatever the
  edits were.
- **The obligations must not move.** A consumer pinned to Build DNA 1.13 owes the
  same things after this change as before it. If any replacement changed what is
  owed, it is not a redaction.

## Decision

**Replace every reference to another project, program, or non-public artifact with
the category it was standing in for, in the working tree, and record the rule and
the list here.**

The rule a replacement had to pass: the sentence makes the same claim with the
category as it did with the name. Where it did not — a sentence whose point was
*this specific system declared this* — the sentence was rewritten to make the
general claim and stopped claiming a declaration.

| What was named | What it is now | Where |
|---|---|---|
| The reference engine | "the reference engine", "an engine", "any conforming engine" | `gate/gate-configuration.md` header, §1, §10, §11 example; ADRs 0008, 0009, 0033; `CHANGELOG.md`; `README.md`; `conformance/README.md`; `overlays/servicenow.md` item 6 |
| The same engine, as a worked placement example | A compliance lifecycle manager, described by shape | `skills/decision-spine/reference/placement.md` — the paragraph claiming the first row was a real declaration now says none of the rows is one |
| Consuming projects that originated a practice | "a consuming project", "that project" | ADRs 0025, 0032, 0035; `CHANGELOG.md` |
| A prior build's platform adaptation | "a prior build" | ADR 0007; `overlays/README.md` |
| The Survey's first audit target | "a prior build's handoff package", "the audited build" | ADR 0031 |
| The modular-monolith example in Build DNA §2 | "an appliance", by shape | `AGENTS.md` §2; `placement.md` |
| Six callsigns in Build DNA §10 | Removed; the bar is the name you are reading | `AGENTS.md` §10 |
| The previous name of §1, and the decks it appeared in | Removed with the migration note | `AGENTS.md` §1 and the migration note |
| Two agency names as example customer context | "agency or sector" | `templates/project-CLAUDE.md` |

Public standards, public documents and well-known products stay: NIST, OSCAL, the
DoD CIO cATO memo, NARA schedules, ServiceNow and its Automated Test Framework,
Power Platform, GCC High, and the books in the reference list. They are citations,
not disclosures. The fictional names in the conformance fixtures stay too.

**Build DNA stays at 1.13.** ADR 0012 decoupled its version so that it moves when
what it says moves, and nothing it requires moved. The migration note is the only
removed section, and it addressed instances written before v1.0 — none of which
exists outside the author's own repositories. `VERSION` moves at the next release
because the bundle digest did.

## Alternatives considered

**Supersede each affected ADR with a redacted copy.** The by-the-book reading of
§8. Rejected: it would add eight ADRs whose only content is a noun swap, put the
unredacted originals permanently in the published record — which defeats the
purpose — and teach a reader that supersession is a typo-correction mechanism. That
last cost is the real one; ADR 0027 rejected the same trade for the same reason.

**Leave the ADRs alone and redact only the vendored files.** Rejected because ADRs
are published with the repository even though they are not vendored. A redaction
that stops at the bundle boundary redacts what consumers copy and publishes what
everyone reads.

**Keep the names and ask permission.** Possible for some, impossible for others,
and it would make publication wait on parties with no stake in it. The names
carried nothing the categories do not.

## Consequences

The published text names no project but this one. Every worked example still
works, because each was already an argument about a shape.

**The git history still carries every name.** This ADR redacts the tree, not the
record of how the tree got here, and a public repository publishes both. Making
the repository public safely therefore needs one of two things first: publish from
a fresh history whose first commit is the redacted tree, or rewrite this
repository's history and accept that every existing clone and pull request link
breaks. Branch names, pull request titles and bodies, and issue text are published
with the repository the same way and need the same review. That is a precondition
of publication, owned by whoever flips the visibility, and it is written down here
so that it is not discovered after.

A consumer that re-syncs sees the diff and nothing it owes changes.

## Revisit if

A redacted passage turns out to have carried an argument the category cannot.
Rewrite the argument; do not restore the name.

## Evidence

- `tools/validate.py` passes unchanged: no anchored count, cross-reference or
  version tie moved.
- `git grep -i` for each removed name returns nothing in the tree.
- `tools/build-bundle.sh` moves the digest; `tools/render-adapters.sh` reports the
  adapters unchanged.
