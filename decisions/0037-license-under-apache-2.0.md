---
adr: "0037"
title: License the whole standard under Apache-2.0, and carry the license into every copy
status: Accepted
date: 2026-10-01
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way          # until the first outside contribution lands; see Consequences
revisit_if: A second organization takes on maintainership and wants contributors to
  make patent commitments of their own — the case the Community Specification
  License exists for — or a consumer's legal review rejects Apache-2.0 for a reason
  this record did not weigh.
approver:
  name: Karl Deiotte
  role: Author and copyright holder
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Until this commit the repository carried no license. Being able to read a
repository does not grant permission to copy, modify, or redistribute what is in
it, and every consumer of this standard does all three: `sync.sh` copies it into
their repository, they edit the project-owned templates it seeds, and they ship
the result. [Issue #5](https://github.com/deiotte/causeway/issues/5)
recorded the gap. README's *Current limits* item 9 restated it.

The author owns the standard outright and has decided to publish it. What is left
is which terms, and the choice is a real one, because this repository is not
shaped like most software:

- **It is mostly prose, and the prose is normative.** `AGENTS.md`, the spine, and
  the gate configuration are what a project is obliged to do.
- **It is also code and contracts.** Shell scripts that install and verify it, a
  Python validator, and JSON files — `checks.json`, `profiles.json`, the overlay —
  that an engine executes against.
- **Some of it is meant to be changed by the person receiving it.** The templates
  are seeded once and then owned by the consuming project, which fills them in and
  ships them inside its own repository, under its own license.
- **The receiving repository can be anything.** A government system, a contractor's
  proprietary product, an open-source project. Whatever the terms are, they land in
  all of those.

## Forces

- **The terms travel into the consumer's repository.** Vendoring is the
  distribution mechanism, not an edge case. A license that imposes obligations on
  the code a vendored copy sits next to — any copyleft — would make adopting the
  standard a licensing decision about the consumer's own product. That is a cost
  no adopter should pay for a governance document, and for many it would end the
  conversation. The license has to be permissive.
- **The engine contract invites implementations.** `gate/checks.json` and the
  conformance pack exist so that someone else can build an engine that evaluates
  this standard. An implementer is better served by an explicit patent grant than
  by silence about patents. Apache-2.0 §3 is that grant; MIT and the BSD family
  say nothing.
- **The prose/code boundary is not clean, so one license beats two.** Is
  `checks.json` a specification or code? Is `templates/project-CLAUDE.md` a
  document or a source file a consumer modifies and ships? A split license — prose
  under one, code under another — needs an answer for every file, and every file
  added later re-asks the question. A split is a boundary this repository would
  have to govern, and §3 of Build DNA is a long argument about what ungoverned
  boundaries cost.
- **Specifications already use this license.** The OpenAPI Specification,
  CloudEvents, and the OpenTelemetry specification are published under Apache-2.0.
  A consumer's legal reviewer has seen it applied to a normative document before,
  which is worth more than a better-fitted license nobody recognizes.
- **The name should not travel with a modified copy.** Build DNA §3 says *never
  silently fork*, and `check-drift.sh` makes a local edit visible. A license cannot
  enforce that — and should not try; forking is a right this license grants on
  purpose — but it can decline to grant the name. Apache-2.0 §6 grants no trademark
  rights, so a fork may exist and may not call itself Causeway. That is the license
  agreeing with the standard instead of fighting it.
- **Attribution should survive a fork.** Apache-2.0 §4(d) carries the NOTICE file
  into derivative works. The standard already insists a contributor be named where
  their knowledge ends up (Build DNA, Practitioner role); the license does the same
  for the standard itself.
- **The disclaimer has to be unambiguous.** README already says Causeway is not an
  accrediting authority and guarantees no production readiness. A standard used in
  authorization work should have that in the license's warranty and liability
  sections (§7, §8), not only in a README.

## Decision

**Every file in this repository is licensed under the Apache License, Version 2.0.
`LICENSE` carries the text verbatim; `NOTICE` carries the copyright line,
`Copyright 2026 Karl Deiotte`, and a statement that the name is not licensed.**

The license travels with every copy:

- **`sync.sh` writes `bundle/LICENSE` and `bundle/NOTICE` into the consuming
  project** on every sync. Apache-2.0 §4(a) and §4(d) ask a redistributor to pass
  both on; vendoring is the first step of every redistribution, so the copy is
  compliant from the moment it exists, without the consumer having to know to do
  it. They go under `bundle/`, never the project root, where the consumer's own
  `LICENSE` lives.
- **`build-archive.sh` ships both** in the release archive. Validator §19 already
  fails the build when `sync.sh` reads a file the archive does not carry, so the
  two lists cannot drift apart.
- **Neither is digested.** Digested files are vendored at their own path, and a
  digested `LICENSE` would land on the consumer's root `LICENSE`. They are
  declared in `bundle/scope.json` with that reason.

**No per-file license headers.** The Apache-2.0 appendix suggests them; it does
not require them. A header in `AGENTS.md` is a header every agent reads on every
turn in every consuming repository, the same cost ADR 0035 declined for an
on-ramp; and adding one to each digested file would move the digest to say
nothing. `LICENSE` at the root, `NOTICE` beside it, and a copy of both in every
vendored tree is enough for a reader and for a scanner.

**Contributions come in under the same terms.** Apache-2.0 §5 already provides
that a contribution intentionally submitted is licensed under the license, so no
contributor agreement is needed for the license to hold. How contributions are
accepted at all is a governance decision, not a licensing one, and is recorded
separately.

**The license applies to this commit and every release after it.** Whether to
extend it to the earlier, privately distributed releases is the copyright holder's
call and is not made here; until it is, those releases carry no license.

## Alternatives considered

**MIT.** Shorter, permissive, and the most recognized license there is. Rejected
on three of the forces at once: no patent grant for an engine implementer, no
NOTICE mechanism for attribution to survive a fork, and no explicit refusal to
license the name. Everything MIT does, Apache-2.0 also does.

**CC BY 4.0 for the prose, Apache-2.0 for the code.** The closest call, and what
the first discussion of this proposed. Creative Commons licenses fit prose well and
Creative Commons itself advises against using them for software. Rejected because
the split needs a boundary this repository does not have — `checks.json`, the
templates and the overlay JSON are each arguably both — and because CC BY 4.0
carries no patent grant for the normative half, which is the half an engine
implements. One license with a known history on specifications is cheaper than two
with a line between them that every new file has to be placed on.

**Copyleft — GPL-family or CC BY-SA.** Would keep every improvement public.
Rejected because vendoring would bring share-alike obligations into the consuming
repository, and making a governance standard into a decision about the consumer's
own product license is the fastest way to have no consumers.

**Public domain — CC0 or the Unlicense.** Maximally permissive. Rejected because it
gives up attribution and the name both, and because public-domain dedication is not
recognized the same way in every jurisdiction, which is a question a legal reviewer
then has to answer instead of skipping.

**Community Specification License 1.0.** Purpose-built for specifications, with
contributor patent commitments. Rejected for now: it assumes a multi-party
specification body with contributors making patent commitments to each other, and
this standard has one maintainer. It is the license to revisit when that changes,
which is why `revisit_if` names it.

## Consequences

Anyone may use, modify, and redistribute the standard, including inside proprietary
and government products, provided they pass on the license and the notice — which a
vendored copy now does by default. A modified copy may not call itself Causeway.

**The door is two-way today and closes with the first outside contribution.** While
the author holds every copyright, the license can be changed by the author alone.
Once a contribution from someone else is merged under §5, changing the license
needs that contributor's agreement too. That is the ordinary cost of accepting
contributions and the reason it is written down here rather than discovered.

README *Current limits* item 9 narrows: the license is resolved; maintainership and
continuity are not. Issue #5 stays open for those.

## Revisit if

A second organization joins maintainership and wants contributor patent
commitments, or a consumer's legal review rejects Apache-2.0 for a reason not
weighed here.

## Evidence

- `LICENSE` is byte-identical to the Apache-2.0 text published by the Apache
  Software Foundation (SHA-256 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`).
- `tools/validate.py` §19 passes with `LICENSE` and `NOTICE` read by `sync.sh` and
  shipped by `build-archive.sh`; §11 (every tracked path is governed) passes with
  both declared in `bundle/scope.json`.
- A scratch sync writes `bundle/LICENSE` and `bundle/NOTICE` and leaves an existing
  root `LICENSE` in the target untouched.
