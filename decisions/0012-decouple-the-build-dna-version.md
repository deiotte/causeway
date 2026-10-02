---
adr: "0012"
title: Decouple the Build DNA version from the standard's release number
status: Accepted
date: 2026-08-10
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

`AGENTS.md` opened with **Version: 1.5 — document of record, tracking `VERSION`**
while `VERSION` read 1.6.1. The claim in the header was false, and it had been
false since 1.6.0.

The wording is not an accident. ADR 0003 added it deliberately, as item 6 of a
decision about something else: `AGENTS.md` carried "Version: 1.0" while the
repository was at 1.1.0, so the header was corrected and given the tracking clause
"so the document of record cannot quietly disagree with the thing projects pin to."

The clause has now failed in exactly the way it was written to prevent, which is
the useful part. It was a promise with nothing behind it. Three releases have
changed the gate, the spine, the tooling and an overlay without touching Build DNA
content, and each one moved `VERSION` past a header that was still correct about
the document it labels. The header did not drift — the coupling was wrong.

Keeping the clause would mean bumping the process standard's version to say
nothing changed in it, which empties the field of the only information it carries:
*has the Build DNA itself moved.*

## Decision

Drop the tracking clause. `AGENTS.md` reads **Version: 1.5 — document of record**.

Build DNA carries its own document version and moves when Build DNA's content
moves. `VERSION` is the standard's release number and moves when anything in the
bundle moves. The two are related — every Build DNA change is a release — and they
are not the same number, in the same way that the Decision Spine is at v0.8 and the
gate configuration at v0.6 inside a standard at 1.6.2.

This reverses ADR 0003's item 6 and nothing else in that ADR. One prompt, one
commit stands. The version-header *correction* in that item also stands: the header
was wrong at the time and fixing it was right. It is the coupling that is
withdrawn.

`validate.py` gains one check — that `AGENTS.md` declares a parseable document
version at all. Small, and it is what remains enforceable once the coupling goes:
the field must exist and be readable, and nothing may claim it means more than it
does.

Version 1.6.2. Patch, and the release exists because `AGENTS.md` is inside the
digested bundle — four words changing its bytes is still a different bundle, and
two bundles calling themselves 1.6.1 is the thing the digest exists to prevent.

## Alternatives considered

**Enforce the coupling instead — bump `AGENTS.md` to 1.6.1 and guard it.** The
honest other half of the fork, and it was rejected because it makes the header
redundant. A field that always equals `VERSION` is `VERSION` with extra steps, and
the reader who most needs it — someone diffing a vendored `AGENTS.md` against a
newer one — learns nothing from a number that moved for a change to a JSON file
they never read.

**Delete the version line entirely.** Rejected. Build DNA ships into other
repositories and gets read there long after it was vendored; a document of record
with no version is the missing-canonical problem ADR 0001 exists because of.

**Leave it and bump `AGENTS.md` next time Build DNA changes.** Rejected. That is
the status quo, and the status quo is a document asserting something untrue about
itself in its third line. The standard fails builds over prose counts that
disagree with a JSON file; it does not get to carry this.

## Consequences

The Build DNA version becomes informative. A project comparing its vendored
`AGENTS.md` against a newer standard can read the header and know whether the
process rules moved, without diffing.

Three version numbers now move independently inside one release — Build DNA, the
spine, the gate configuration. That was already true of two of them, and the
overlay guards added in ADR 0011 are the pattern for keeping the claims about them
honest: the standard states which versions it ships, and CI fails when a document's
header disagrees with what it describes.

Nothing a consumer owes changes. No row, no check, no threshold moved, and a
project that never re-syncs is unaffected.

## Evidence

`AGENTS.md` line 3. `./tools/validate.py` — the version-header check, confirmed to
fail on a header with no parseable version, and 371 checks passing overall.
