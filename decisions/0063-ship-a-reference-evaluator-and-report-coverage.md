---
adr: "0063"
title: Ship a reference evaluator for a slice of the gate, and make doctor report coverage beside setup
status: Accepted
date: 2026-11-17
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A conforming engine outside this repository covers the slice, at which
  point this file should defer to it; or adopting projects start treating the
  reference evaluator's pass as a gate pass for checks it does not implement.
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

Since ADR 0009 the standard has published the gate contract (29 checks, 16 input
classes, four profiles, eight verdicts, a receipt shape) and nine conformance
fixtures, and shipped no engine, on the principle that evaluation belongs
elsewhere. ADR 0045 then gave adopting projects `doctor.sh`, which checks setup and
says plainly that it evaluates nothing.

The 2026-11-17 review found what that boundary produced in practice. No engine
exists anywhere. Two C1 adopting projects both read `adoption: complete-except-unverified`
from doctor while, at G3, 5 and 2 of their 94 spine rows were closed, every ADR in
both had `forces: []`, and neither had a Survey. Doctor was accurate about setup and
silent about everything setup is for, and "complete" was the word a reader kept.

## Forces

- **An unsupported check is not a pass** (gate-configuration §11). Whatever ships
  must say what it cannot run.
- **Conformance is defined by the fixtures, not by an engine** (`conformance/`).
  Anything this repository ships has to match them exactly.
- **Doctor is advisory and exits zero** (ADR 0045). Coverage must not turn it into a
  gate.
- **The closure checks are the ones that say whether the record is used.** They read
  only ADR frontmatter, `system.json` and the vendored spine.

## Decision

1. **`tools/evaluate.py`, a reference evaluator, vendored into every project.** It
   implements the five checks the conformance fixtures pin (`standard-currency`,
   `named-approvers`, `dependency-provenance`, `composition-state`,
   `install-scripts`) and the three closure checks (`shortform-closure`,
   `oneway-closure`, `class-scoped-closure`). Every other check is reported
   `unsupported` wherever its profile cell is not `skip`.
2. **It honors the contract's exit codes**, so a full run on a real project exits 4:
   required checks it cannot execute. `--advisory` prints the same report and exits
   0, for a warn cycle in CI. `--coverage` prints only the closure counts.
   `--conform` runs every fixture and fails on any difference; CI runs it.
3. **Where it cannot decide, it says so.** A `system.json` whose `closed_against` is
   older than the vendored spine needs the adoption-horizon arithmetic, which is not
   implemented: the closure checks report `unsupported` with that reason, and still
   report their counts. Waivers are read from ADR frontmatter only. Build DNA open
   item 12 records both.
4. **Doctor reports coverage beside setup**, measured by the vendored evaluator: rows
   closed of rows in scope at the profile, waived rows, accepted ADRs citing
   `forces`, and whether a Survey exists. It is a report, not a finding, and never
   changes doctor's exit status. Doctor's setup state is renamed
   `setup-complete-except-unverified`, because setup is all it measures.

## Alternatives considered

- **Keep the boundary.** It is principled and, on the evidence, means the gate never
  runs anywhere.
- **Implement all 29 checks.** Most read input classes (SBOM, evidence stores, a
  catalog) no adopting project can supply yet, and a check without a fixture is an
  untested assertion (`conformance/README.md`).
- **Report coverage from doctor with its own parser.** A second reading of the spine
  table would be a second place to drift; doctor calls the evaluator instead.

## Consequences

**Easier.** A project can see, in one command, how much of its spine it has closed
and which checks would fail. One of those projects now reads `spine 2/94 rows closed at G3`.

**Harder.** The standard now ships code that reaches verdicts, so a bug in it is a
wrong verdict in someone's CI. The conformance fixtures and `test-evaluate.sh` are
the guard, and the evaluator labels every report partial.

**Security.** Positive at the margin: `install-scripts` and `dependency-provenance`
now run somewhere. Running it found real gaps in the sampled projects (a Python
manifest without a lockfile, an `npm install` without `--ignore-scripts`, and
`composition-state` absent from two `system.json` files).

**Declared gaps.** Open item 12: no adoption-horizon arithmetic, waivers read from
ADRs only, no receipts. Cargo and Python are reported as ecosystems
`install-scripts` does not read, so those projects see `unsupported` there.

## Revisit if

A conforming engine elsewhere covers the slice, or projects start reading this
evaluator's pass as a gate pass.

## Evidence

- `tools/evaluate.py`, `tools/test-evaluate.sh`; 9 of 9 fixtures match.
- `tools/doctor.sh`, the coverage block; `tools/test-doctor.sh`.
- `docs/build-dna/open-items.md` item 12.
