# Platform Overlays

**Layer:** Design. An overlay is a projection of the Decision Spine onto one
platform. It adds nothing to the spine and removes nothing from it.

---

## What an overlay is

Causeway assumes you are laying ground. A platform overlay covers the case where
someone else laid it first — ServiceNow, Power Platform, Salesforce, SAP. The
spine's 94 rows still have to be answered. What changes is *who answers them* and
*what the answer looks like on that platform*.

An overlay answers four questions and nothing else:

1. **Disposition.** For each of the 94 rows: does the platform answer it, does it
   supply a mechanism you must still configure, or is it entirely yours?
2. **Answer sets.** Where the platform has specific options, what are they? The
   spine says `silo / pool / bridge`; the overlay says what those are called here.
3. **Evidence.** For each gate check, what artifact does it read on this platform?
4. **Gate mechanics.** What G0–G3 look like concretely — which instance, which
   authorization record, which test framework.

## Why "overlay" and not "profile"

`gate/profiles.json` and `skills/decision-spine/reference/gate-profiles.md` already
own the word *profile*, and it means G0–G3 throughout this standard. Two different
things called "profile" would be the same failure the spine warns about for tier
and criticality — *do not conflate them* — and the spine's own remedy there was two
distinct names rather than a qualifier.

*Overlay* is borrowed from NIST SP 800-53 tailoring, which is already in the
ratified reference set and already feeds SA-5.9's control-allocation question. An
overlay there specifies how a baseline applies in a particular context. That is
exactly this.

## The three disposition states

| State | Meaning | Who writes the ADR |
|---|---|---|
| **I — Inherited** | The platform answers it. There is no configuration to choose and no alternative to weigh. | You do. See below. |
| **S — Shared** | The platform supplies the mechanism, or bounds the answer. You still decide. | You do. |
| **P — Project-answered** | Entirely yours. The platform has no opinion. | You do. |

Note the third column. It does not vary.

### Inherited is a closure state, not an exemption

**An inherited row still closes with an ADR.** This is the load-bearing rule of the
whole instrument, and an overlay that lets anyone read `I` as *skip* has become the
decorative-declaration failure the gate configuration forbids in its first design
rule.

The ADR for an inherited row is short — a paragraph and a citation — but it exists,
it carries the row ID, and it lands in `decisions/` where `shortform-closure` and
`class-scoped-closure` count it:

```yaml
---
adr: 00NN
title: Execution fabric — inherited from the ServiceNow platform
status: Accepted
date: YYYY-MM-DD
spine_rows: [SA-4.1]
---

## Decision

Inherited. The system runs on vendor-operated ServiceNow SaaS. There is no
execution-fabric choice available to this project.

## Evidence

<vendor documentation reference> · <instance record or authorization package
section stating the hosting model>
```

Three consequences worth being explicit about, because they are what keep the
receipt arithmetic honest:

- **The gate does not change.** It counts ADRs, not dispositions. No check reads an
  overlay, no check ID is added, and `rows_closed` means the same thing it meant
  before. An overlay is guidance in the `AGENTS.md` §9 sense; it is on the left-hand
  column of that table.
- **Inheritance never removes a dagger.** A † row that disposes to `I` or `S` still
  requires a named individual in the ADR. SA-5.7 is inherited encryption *and* a
  named key-custody approver. The platform cannot sign for you.
- **Inheritance never moves a deadline.** One-way rows close before production code
  and carry a 180-day adoption horizon regardless of disposition.

## Containment rules

These are what stop an overlay from becoming a fork of the spine.

An overlay **may**:

- assign a disposition to each row;
- supply platform vocabulary for a row's answer set;
- name the platform artifact that satisfies a check's evidence requirement;
- name the platform mechanism for a gate profile.

An overlay **may not**:

- add a row, retire a row, or renumber one;
- change a row's `Applies` class, its one-way flag, or its named-approver status;
- change what any gate check does, or add a check;
- excuse a row from needing an ADR.

If writing an overlay makes you want to do something on the second list, the
finding belongs upstream as a spine or gate change, and the overlay should record
that it wanted to. A platform is a good source of evidence that a row is wrong; it
is not a licence to answer it locally.

## Tightening and loosening

An overlay's dispositions are the starting state of a project's register, not a
verdict on it. Instances differ.

- **Tightening is free.** A project may treat any row as more its own than the
  overlay says — `I` → `S`, `S` → `P` — silently. That is just doing more work.
- **Loosening is a deviation.** Moving a row the other way — deciding a row the
  overlay calls `P` is actually inherited on your instance — needs a row in the
  project's exceptions register and an ADR behind it, like every other deviation
  from the standard.

The asymmetry is the same one the whole standard runs on: nobody has ever needed a
process to stop a team from doing more.

## Distribution

Overlays are vendored per project, on request:

```bash
./tools/sync.sh /path/to/project --overlay servicenow
```

This copies `overlays/<name>.md` — and `overlays/<name>.json` where one exists —
into the project and records them in `.causeway-lock` as an `overlay=` line and a
checksum each, so `check-drift.sh` covers them like every other vendored file.
Projects that name no overlay get none — a Go service has no business carrying the
ServiceNow disposition table.

### The machine-readable projection

An overlay may ship a `.json` beside its markdown: the same dispositions, the same
answer sets, plus a platform evidence statement and input classes for every check.
Three rules keep it from becoming a second overlay.

1. **The prose is the overlay.** The JSON is a projection. Where they disagree the
   JSON is the defect, and `validate.py` fails the build rather than letting anyone
   find out which one a reader trusted.
2. **No gate check reads it.** The containment rules above are unchanged — an
   overlay cannot become gate input by being machine-readable. It is consumed by
   engines, register scaffolds and dashboards, all of which sit outside the gate.
3. **It is derived where it can be.** Dispositions, counts, the repo-class check
   list and the per-profile blocking arithmetic are all recomputed by `validate.py`
   from the prose, `checks.json` and `profiles.json`. Only the platform prose — what
   an artifact is called on this platform — is hand-written, because nothing can
   derive it.

The reason to ship one is narrow and worth stating: a team that has to parse a
markdown table to get its dispositions will retype them into its own tooling, and a
retyped disposition table is a fork of the overlay that nobody checksums.

The checksum is deliberate. An overlay a project can edit is a project deciding its
own dispositions, and dispositions are the one thing in here that looks like it
grants relief.

## Writing a new one

Do it against the actual register, not from memory of it. The first draft of the
ServiceNow overlay was written without the spine in front of it and got the row
count, four of the nine section names, and its central claim wrong — see ADR 0007.

1. Read `skills/decision-spine/reference/spine.md` end to end.
2. Disposition all 94 rows. Publish the I/S/P counts and make them sum to 94.
3. Identify which of the spine's 28 one-way doors the platform actually changes the
   answer set for. Map them to row IDs. Resist inventing a parallel register of
   platform doors — a second numbering scheme is a second spine.
4. Translate the Build DNA defaults into platform terms, keeping the
   default-with-owned-deviation shape.
5. Map the gate checks to platform evidence. Where a check cannot read anything on
   this platform, say so plainly rather than inventing an artifact.
6. Write the ADR, bump `VERSION` and `RELEASED`, add the overlay to `sync.sh`, and
   run `./tools/build-bundle.sh` — overlays are part of the digested bundle, so an
   overlay that changes without a regenerated manifest is a bundle whose digest no
   longer describes it. `./tools/validate.py` checks the row set, the published
   counts, and the versions this overlay claims to be ratified against.

## Keeping one current

An overlay is ratified against a spine version and a gate configuration version,
and both move underneath it. `validate.py` fails the build when the versions named
in an overlay's header fall behind the ones the standard actually ships, which
makes reconciliation a release-blocking task rather than something noticed later by
whoever next reads the file.

Reconciling is usually cheap. Most core revisions change no disposition, and the
work is confirming that and moving the header — see the ServiceNow overlay's 1.1
note for the shape. The cases that cost something are the ones worth catching:
a corrected answer set the overlay repeats in its own words, or a gate mechanic
whose platform evidence the overlay maps.

## Overlays

| Overlay | Version | Status |
|---|---|---|
| [`servicenow.md`](servicenow.md) | 1.12 | Ratified against spine v0.8 |

Power Platform is the obvious second one — a prior build already adapted to
SharePoint and Power Automate in practice, and that adaptation is currently
undocumented tribal knowledge. Writing it means recovering what that build
actually did, not deriving it from the platform's marketing surface, so it needs someone with that history rather
than someone with the spine.
