---
adr: "0047"
title: Tell a declared placement from a defaulted one — in doctor, not yet in the gate
status: Accepted
date: 2026-10-08
spine_rows: []         # governs how SA-1.1 and SA-1.14 evidence is read; closes neither
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: The measurement below has run — three independent projects for one quarter —
  and the counts say whether placement-argued earns a warn-level gate check. Or an
  adopter reports doctor calling a real declaration incomplete, because its evidence
  lives somewhere doctor does not read.
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

Gate configuration §3 derives the profile from `tier` and `criticality_class` and
never reads `criticality_authority`. A system whose sponsor declared C1 and a system
nobody classified therefore produce the same profile, the same rows and the same
receipt. Gate configuration §10 item 13 records this. It names `placement-argued` as the
candidate check, and it blocks the check on a warn cycle that needs a portfolio which
has run the placement procedure at least once. None has.

`skills/decision-spine/reference/placement.md` states the rules: a declaration names a
person, a role and a date; it is argued in an ADR closing SA-1.1 and SA-1.14; it appears
in `CLAUDE.md`. Raising a class needs no ceremony. Lowering one needs a new declaration
from the same authority. Tier moves by catalog placement. Nothing checked any of it.

Issue #15 asks for the distinction to be visible and the rules to be observable,
starting advisory, with a measurement plan before any blocking check is proposed.
ADR 0045's `doctor.sh` already reads `system.json`; it is the natural place.

## Forces

- **The default is correct, and its loudness is spent silently.** C1 for an unclassified
  system is right. The problem is that nothing can count how often a portfolio runs on it.
- **A check must not be declared into existence** (§9). It needs evidence about false
  positives first. The instrument has to come before the check, and be the same thing
  the warn cycle will later count.
- **The evidence is in files with conventions, not schemas.** ADR frontmatter's
  `spine_rows`, a markdown block in `CLAUDE.md`, a JSON object. A reader of them must say
  exactly what it read, so its misses are visible.
- **History is the only record of a change.** A lowering is a difference between two
  versions of `system.json`, and git is where those versions live when there is a git.
- **A name is not a signature.** The authority field records who is on record as
  declaring. No file can prove they approved it, and a tool that implied otherwise would
  be manufacturing assurance.

## Decision

**`doctor.sh` reports a placement state** — one word, in the human report and in
`--json` as `placement.state`:

| State | Condition |
|---|---|
| `declared` | valid tier and class; authority has a name, a role among PO / Product Owner / Service Owner / Customer / Sponsor, and an ISO date not in the future |
| `asserted` | valid tier and class; the authority is missing or incomplete |
| `defaulted` | valid tier; no class — the gate runs C1 |
| `class-invalid`, `tier-missing`, `tier-invalid` | no honest profile |
| `unreadable`, `no-system-json`, `unverified` | the file is broken, absent, or python3 is missing |

Only `declared` is `ok`. Every finding about an authority says that a name in a file is
a recorded assertion, not an authentication of approval.

**It looks for the argument.** It reads `decisions/*.md` frontmatter. An ADR counts when
its `spine_rows` lists the row and its status is not Proposed, Superseded or Deprecated.
A missing SA-1.1 ADR (for a declared or asserted class) and a missing SA-1.14 ADR (for a
valid tier) are each `incomplete`. The remedy is the ADR content placement.md asks for.
Whether `$criticality` is present is mentioned, but it does not substitute for the ADR.

**It checks the records agree.** If `CLAUDE.md` has the template's `**Tier:**` or
`**Criticality class:**` lines, an unfilled one (still `a | b | c`) is incomplete. So is
a value that differs from `system.json`. Agreement is `ok`. Absence of the block is not
reported here; the starter checks cover the template.

**It reads reclassification from git history** of `system.json`, comparing the current
class to the most recent different one:

- A **raise** is `ok`, named, with the note that newly owed rows close against the
  adoption horizon.
- A **lowering** is `ok` only if the current authority is complete, its date is newer
  than the previous declaration's, it names the same person and role, and an accepted
  SA-1.1 ADR is dated on or after it. Otherwise it is `incomplete`, listing which
  conditions failed. The remedy never supplies an authority.
- A **first class** after running on the default is a declaration, not a lowering, and
  is `ok`.
- A **lowered tier** is `unverified`: the catalog places tiers, and doctor cannot see it.
- **No git**: `unverified`.

Doctor still exits 0. Nothing here blocks anything.

**The documents say the same thing.** `placement.md` gains what doctor reads after *The
declaration*, and how it reads history after *Reclassification*. The contributor starter
says a missing class is reported as *defaulted*. ADOPTING.md asks a first adopter for
their placement state at the start and end of the quarter.

**The measurement plan,** for gate configuration item 13, which stays open:

1. **Instrument.** `doctor.sh --json`: `placement.state`, and the status of
   `placement.adr_class` and `placement.reclassification`. Doctor is offline and
   collects nothing; adopters report through the Adopter report form.
2. **Population.** At least three projects that did not author the standard, for one
   quarter each, each reporting state at onboarding and at quarter end, and every
   lowering doctor flagged with how it was resolved.
3. **What is counted.** How many run `defaulted` or `asserted`, and for how long. How
   often a lowering is flagged, and how often the flag was right. **False positives**:
   projects whose declaration exists in a form doctor cannot read (an ADR without
   `spine_rows`, a record outside `decisions/`).
4. **The decision it feeds.** If the counts show placements going undeclared and the
   false positives are explainable, propose `placement-argued` (state `declared` plus an
   SA-1.1 ADR) as a **warn-level** gate check. That is a gate configuration change with
   its own ADR. Blocking is decided only after that warn cycle has run, per §9.

## Alternatives considered

- **Add `placement-argued` to the gate now.** It would block on evidence nobody has
  measured. Item 13 exists to prevent exactly that.
- **Make the gate read `criticality_authority` for the receipt only.** It would make the
  receipts distinguishable, which is the real fix. It is also a receipt contract change,
  and belongs to the gate-configuration decision the measurement feeds.
- **Require a structured placement field in ADR frontmatter.** Precise, and a new
  obligation on every project's ADRs. `spine_rows` already says which row an ADR closes.
- **Query a catalog for tier.** There is no catalog interface in the standard, and
  doctor is offline. `unverified` is the honest answer.

## Consequences

A project running doctor learns whether its C1 is a decision or a default, and whether
the argument for its placement exists anywhere. A portfolio that collects
`doctor --json` gets a count it could not get before.

The ADR reader is a heuristic over frontmatter conventions. An ADR that closes SA-1.1
without listing it in `spine_rows` is missed, and doctor will say no ADR exists. That
is the false positive the measurement counts.

The history check trusts the history. A rewritten history, or a `system.json` committed
for the first time already lowered, shows no lowering. Doctor reports what git shows,
not what happened.

Gate configuration item 13 stays open, with its index note updated to name this ADR. The
gate still cannot tell a declared placement from a defaulted one.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-doctor.sh`: 47 passed, 21 of them added by this ADR, covering:
  - `declared` for a deliberate C1, and the assertion wording
  - `defaulted` for the same system without a class
  - `asserted` with no authority; an unrecognised role
  - `tier-missing`
  - missing and superseded placement ADRs
  - `CLAUDE.md` disagreeing, unfilled and agreeing
  - no git history (`unverified`)
  - seven histories: a raise, a lowering without a declaration, a proper lowering, a
    lowering by a different authority, a lowering with no new ADR, a first declaration
    after the default, and a lowered tier
- The fresh-sync and configured-project cases from ADR 0045 still pass. The configured
  project now carries its placement ADR.
