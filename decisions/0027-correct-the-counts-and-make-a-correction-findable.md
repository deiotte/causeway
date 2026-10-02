---
adr: "0027"
title: Correct the derived counts ADRs 0025 and 0026 stated wrong, and make a correction findable from the record it corrects
status: Accepted
date: 2026-09-03
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
corrects: ["0025", "0026"]
corrected_by: []
---

## Context

ADR 0025 built an index so that the number of open items would stop going stale.
Its own consequences section states two numbers about that index and both are
wrong. ADR 0026 added relations so that entanglement between items would stop
being something a reader had to notice by hand. Its consequences section states
four numbers about those relations and all four are wrong.

Six wrong counts across two ADRs, every one of them derivable from
`decisions/open-items.json` as it stood in the same commit.

| Stated | Where | Actual |
|---|---|---|
| "six registers' worth of history" | ADR 0025, and the index's own `$attribution` | four |
| "`opened_by` is null for fifteen items" | ADR 0025 | 21 |
| "Five of the twenty-eight now carry an edge" | ADR 0026 | six of the twenty-eight; seven including the closed one |
| "six carry a blocker" | ADR 0026 | eleven |
| "Three share `first-adopter-evidence`" | ADR 0026 | four |
| "the remaining three have one each" | ADR 0026 | two have one, `conformance-schema` has two |

**"Six registers" is the one worth dwelling on.** There are four, and there was
never a version of this work in which there were six. Six was the count in an
early draft that included the README's credibility gaps and development
priorities — two lists ADR 0025 then explicitly declined to index, with a stated
reason, in its own alternatives section. The number survived the decision that
falsified it, travelled into the index's `$attribution` string, and shipped from
there into the ADR. Nothing objected, because §16 anchors counts in the README and
`decisions/` has never been read by anything that counts.

The ADR 0026 numbers failed differently and more ordinarily: they were written
against the item set before `blocked_on` was applied to gate configuration items
11 and 12, and never recomputed after. That is the same failure mode as every
other stale count in this repository's history — a true number, superseded by an
edit, restated from memory.

There is a pattern here and it is not flattering. ADR 0025 built counting and
mis-stated its counts. ADR 0026 built relation-checking and mis-stated its
relation counts. The validator's own §16 has said since v1.7.0 that *a number in
prose that is derivable from an artifact belongs in this file*, and two
consecutive releases stated derived numbers outside its reach while claiming to
have solved that class of problem.

Correcting them raises a second problem the record cannot currently solve. §8 says
ADRs are **immutable, and superseded rather than edited**, which is right: the
argument in 0025 and 0026 is sound and is not what was wrong. But an immutable
document with a wrong number in it and no forward pointer will tell every future
reader the wrong number, and this repository has spent three releases establishing
that a finding nobody can reach from where they are standing is a finding nobody
has. The ADR contract has a forward pointer for supersession and none for
correction.

## Decision

**The six counts are corrected here, and the index's `$attribution` is corrected
in place.** The index is a living artifact and simply gets fixed; the ADR bodies
are not touched.

**Their derived counts are anchored.** The index's `$attribution` now states its
numbers in a form `validate.py` checks — null attributions, total items, and
registers — alongside the README's open-item count that ADR 0025 already anchored.
An artifact that exists to count things is the last place a wrong count should
survive, and the sentence that said "six registers" now fails the build if it says
anything but four.

**§8 gains a correction rule and `corrected_by` frontmatter.** A factual error in
an accepted ADR is corrected by a later ADR; the corrected one gains the pointer
and keeps its body. Frontmatter is the mutable half of an ADR by construction —
`superseded_by` cannot be known when an ADR is written and neither can this — so
the pointer costs nothing that immutability was defending. `corrects` and
`corrected_by` are mutual and the build checks both directions, exactly as ADR
0026 checks `duplicate_of`, and for the identical reason: a one-sided pointer is
how this vocabulary would rot.

ADRs 0025 and 0026 gain `corrected_by: ["0027"]`. Nothing else in them changes.

**Build DNA moves to 1.9, the overlay reconciles to 1.6, and Build DNA open item 7
opens** for what is still unchecked: nothing verifies a count stated in an ADR. The
item carries the candidate design rather than leaving it to be re-derived — record
the index version an ADR's numbers were taken at, and check only the ADR whose
version matches the tree being validated, which is precisely the one being added in
that commit.

**Version 1.12.0, minor.** The bump is for `corrected_by`, which changes the ADR
contract a consuming project inherits. The corrections themselves would have been
a patch.

## Alternatives considered

**Edit the two ADRs and skip the mechanism.** Four characters in one, a sentence in
the other, and nobody would know. Rejected because §8 forbids it in as many words,
and because the rule is right: an ADR that can be silently edited is not a record,
and the moment a wrong number justifies an edit, so does an inconvenient
alternative that turned out to be correct. The immutability rule survives a wrong
count. It does not survive being suspended once.

**Supersede 0025 and 0026.** The status exists and would make the corrections
reachable through machinery that already works. Rejected as a lie about what
happened: both decisions stand, both are still the operative record for their
subject, and marking them `Superseded` would tell a reader to go look for a
replacement that does not exist. A wrong number in a consequences section is not a
wrong decision, and a vocabulary that cannot say so is a vocabulary that will get
used to say the wrong thing.

**Anchor the counts in ADR bodies too.** The obvious symmetric fix, and it does not
work: an ADR is a dated record whose counts are true as of its date, so a guard
comparing them to the current artifacts would fail forever the moment the next item
opened. Recorded as open item 7 with the narrow version that would work, rather
than either building it now or pretending the gap is not there.

**Say nothing and fix it quietly in the next release.** The counts are in
consequences sections, not decisions; nothing depends on them; no consumer reads
them. Rejected because that argument works equally well for every stale number this
repository has spent four ADRs eliminating, and because the person who found these
found them by reading, which is the mechanism this whole line of work exists to
stop relying on.

## Consequences

**Two claims in the record are corrected and one is retracted.** ADR 0025's context
states that a consuming project found its ADR and open-item counts going stale. That
was the report that prompted the work and it is not something this repository has
evidence for; it should have been written as the report it was rather than as a
finding. It is retracted as a claim and stands as provenance. ADR 0026's
alternatives section refers to "the plan this ADR was approved under" — a document
that exists in no repository, which is the same defect as citing an item that is not
in its register.

**The index's self-description is now checked.** Two anchors, three derived values.
Replaying the original error — putting "six registers" back — fails the build, and
so does deleting the sentence, which is the failure mode §16 had to be rewritten to
distinguish.

**A corrected ADR is findable from itself.** This is the fourth instance in four
releases of the same shape: gate item 10 unfindable from its register, the overlay's
evidence unfindable from the core item it answered, a settled question unfindable
from the open one restating it, and now a correction unfindable from the record it
corrects. Each was fixed one layer at a time and each was invisible until something
counted.

**Build DNA open item 7 opens and nothing closes.** Twenty-nine open items across
four registers. The count went up because a gap got named, which is the intended
direction.

**The overlay pays a third reconciliation in three releases.** ADR 0024 accepted
that cost per Build DNA bump; it is now three for three, one §7 row or note each,
no disposition moved. That is worth stating plainly rather than letting it accrete:
if a fourth arrives for a rule with no platform translation, the right response is
to question the guard's granularity, not to write a row that says nothing.

## Evidence

The corrections were derived rather than read, by counting the index directly:

```
registers                : 4
items / open / closed    : 35 28 7
null opened_by           : 21
items with an edge       : 7   (6 of them open)
items with a blocker     : 11
blocker tally            : first-adopter-evidence 4 · gate-check-decision 3 ·
                           conformance-schema 2 · portfolio-count 1 ·
                           warn-cycle-measurement 1
```

**Both new guards were confirmed to fail on a seeded defect.** Restoring the
original wrong count, and removing the sentence entirely:

```
FAIL  every open-item count agrees with the index in all 2 places it is stated
      'null for 21 items of 35, across 6 registers' — the index says (21, 35, 4)

FAIL  every anchored open-item count is still stated
      1 of 2 anchors matched. State the count, or fix the anchor in
      OPEN_ITEM_ANCHORS if the wording is right and the pattern is not.
```

The correction pointer was confirmed to fail one-sided, before this ADR existed:

```
FAIL  every ADR named by a correction exists
      [('0025', 'corrected_by', '0027'), ('0026', 'corrected_by', '0027')]
```

`decisions/open-items.json` — `$attribution`, `standard_version`.
`tools/validate.py` — the `OPEN_ITEM_ANCHORS` extension in §17, and the
`corrects`/`corrected_by` checks in §12. `AGENTS.md` — version 1.9, §8's
correction bullet, open item 7. `templates/adr-template.md` — the two fields.
`decisions/0025-*.md` and `decisions/0026-*.md` — frontmatter only.
`overlays/servicenow.md`, `overlays/servicenow.json`, `overlays/README.md`.

`VERSION` 1.12.0, `RELEASED` 2026-09-03, `bundle/manifest.json` regenerated;
`gate/checks.json` and `conformance/expectations.json` carry the new
`standard_version`.
