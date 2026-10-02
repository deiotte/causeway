---
adr: "0026"
title: Make relations between open items real, and enforce what each kind promises
status: Accepted
date: 2026-09-03
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
corrects: []
corrected_by: ["0027"]
---

## Context

ADR 0025 built the open-items index and, in doing so, produced the first list of
this repository's open items that anyone had ever read end to end. That list
immediately said something the ADR did not act on: the items are entangled with
each other across registers, and the index recorded none of it. The ADR named
three instances in its consequences and left them annotated.

A proper sweep of all twenty-seven found the annotation was the smaller half.

**`gate-config-2` and `spine-3` are the same question, near-verbatim.** *A catalog
item needs a criticality class too, or it inherits the strictest class among its
consumers. The second is more correct and more expensive.* One question asked in
the enforcement layer and the design layer, neither citing the other.

**`spine-1` kept asking a question that had been settled.** ADR 0021 decided that
this repository is the document of record and that waiting for a Drive copy to
diff against was the error rather than the remedy; Build DNA's own item 2 closed
on that argument at 1.6. The spine's version of the same question stayed open for
two more releases, still asking for the diff, because nothing connected a closed
item in one register to an open one in another.

**`gate-config-8`'s question was answered in a different document three releases
ago.** The item asks whether the *G2/G3 and never released* set is small, and says
that if it is not, `release_state` is wrong for both checks that read it.
`overlays/servicenow.md` §8 answers it — *on this platform the set is not small*,
by construction rather than oversight, because nothing in the delivery path asks
git for a version — and it introduces that paragraph with **"this overlay's
contribution is the evidence."** The contribution was filed against a document
core does not read. Nobody carried it back. The item has read as unresolved since
overlay 1.1 while its answer sat one file away.

**Two overlay items say the finding belongs upstream and there is nothing
upstream.** Open items 5 and 6 both end with that phrase. Item 3 has real targets;
5 and 6 point at nothing, because no core item existed for either. A finding
routed to a destination that does not exist reads as tracked, which is worse than
reading as untracked, because untracked at least looks the way it is.

None of these is a counting error. §17 counts items and checks their status
against the prose, and it would pass all five forever. They are errors about the
edges between registers, and the index had no edges.

The overlay case is the one that generalizes furthest. The containment rules
(ADR 0007) forbid an overlay from changing a row, a flag or a check, so when an
overlay concludes something about core, recording it is the *only* action
available. Recording it into a document core does not read is indistinguishable
from not recording it, and that is not a ServiceNow problem — it is the shape of
every register that is downstream of another.

## Decision

**Relations are edges the build enforces, not annotations.** Five types, each
carrying an invariant that fails the build when it does not hold. A relation that
is merely stored would have caught none of the five findings above; what makes
this worth a release is that each type promises something checkable.

| Relation | Invariant |
|---|---|
| `duplicate_of` | Mutual, and both halves carry the same status. |
| `superseded_by` | When the target closes, this item must close. |
| `upstream_of` | Targets exist and cross registers; when one closes, this item must be re-read. |
| `answered_by` | Names a document and a heading outside this register, both of which must still exist. |
| `blocked_on` | Keys from a declared vocabulary; every key declared, every declared key used. |

The asymmetry is deliberate and each half of it was chosen against a specific
failure. `duplicate_of` is mutual and enforced in both directions because half a
closed duplicate is the way this vocabulary will actually rot. `superseded_by` and
`upstream_of` fire when the *target* moves, because the failure they describe is
the downstream item not noticing. `answered_by` points at a document rather than
an item, because the answer that went missing was a section of prose — a relation
vocabulary that could only name items could not have recorded the case it was
built for.

**`blocked_on` gets a declared vocabulary** — five keys, and both directions
checked: an item may not cite a key nothing declares, and a declared key that no
item cites fails too. That second half is what keeps the vocabulary from
accumulating resolved blockers nobody removed. The keys turn *several items are
waiting on the same thing* from a pattern somebody noticed into a fact somebody
can query, which is the difference between knowing the backlog and having read it
recently.

**`spine-1` closes, by the relation rather than by a fresh argument.** Its
`superseded_by` edge points at `build-dna-2`, which is closed, and the invariant
does the rest. It closes in place with its number — the spine's first closure that
does not renumber — and the section gains the numbering-stability note the gate
configuration has carried since v0.5. The Decision Spine version does not move: no
row changed, and ADR 0023's reasoning about status corrections applies here.

**`gate-config-8` stays open and its question changes.** The `answered_by` edge
carries the overlay's evidence back and the prose entry records that the condition
is met, so by the item's own terms the marker is now wrong for both checks. What
is left is the remedy — replacing `release_state` for `oneway-closure` and
`tests-with-source` at once — and that changes what an engine reads. Deciding it
inside an index revision is precisely the *arriving as a side effect* failure
ADR 0013 refused when it declined to invent a conformance-schema change during an
overlay revision. The item is ripe, not answered, and the difference is a whole
ADR wide.

**Gate configuration items 11 and 12 open**, so that overlay items 6 and 5 have
upstream targets that exist: no engine has declared its input classes against any
platform, and `expectations.json` cannot express that an engine lacks one. Both
were already written down in the overlay, both said they belonged upstream, and
neither had anywhere to go. The gate configuration version does not move — §10 is
the register, not the contract, and adding an item to it changes nothing a
consumer owes.

**Build DNA moves to 1.8**, so consuming projects inherit the vocabulary. The
overlay reconciles to 1.5, which is ADR 0024's guard doing its job for the second
time in two releases; §7's index row gains the platform reading rather than a
second row, because relations are part of the index rule rather than a rule beside
it.

**Version 1.11.0, minor.** It adds an obligation.

## Alternatives considered

**Fix the five findings and skip the mechanism.** Cheapest, and it was on the
table because the findings are individually small — merge a duplicate, close a
stale question, carry one paragraph back. Rejected because the method that found
them does not scale and has already failed once in this repository: ADR 0025's
item 10 was found by reading carefully, and its own consequences section then
under-counted the entanglement it was describing, three items where a sweep finds
eight. Fixing these five by hand leaves the ninth to be found the same way, which
is to say eventually and by accident.

**Store relations without invariants.** A `related_to` list would have made the
entanglement visible and cost nothing. Rejected on the same ground the index
itself rests on: visible was what ADR 0025 already achieved, and it is not what
kept `spine-1` open. An edge nothing enforces is a note, and this repository has
established twice now that a note is what goes stale.

**Merge the duplicate into one item.** Tempting for `gate-config-2` and `spine-3`,
and wrong. The layers close on different arguments — the enforcement layer decides
what a check reads, the design layer decides what a system must answer — and
collapsing them would put the surviving item in one register and make the other
layer's readers stop seeing it. That is the failure this ADR is about, performed
deliberately. The edge records that they are the same question without deciding
which register owns it.

**Close `gate-config-8`.** The plan this ADR was approved under said it would, and
reading the item closely says it must not. Recorded here rather than quietly
dropped: the item's remedy is a change to what `oneway-closure` and
`tests-with-source` read, which is gate semantics and an engine-contract move. An
ADR about index bookkeeping does not get to make it as a side effect, and the
distinction between *this is now decided* and *this is now ripe* is the kind of
distinction the whole register exists to preserve.

**Let `upstream_of` point within a register.** Rejected as a category error worth
a check rather than a convention: an item in the same register is a sibling, and
calling it upstream would let a register absorb its own findings and look
resolved.

## Consequences

**Twenty-eight open items, seven closed, thirty-five total.** Up one open from
ADR 0025 on net: two opened, one closed. The two that opened were already written
down in an overlay; what changed is that core now carries them, which is the point
rather than an inflation of the number.

**Five of the twenty-eight now carry an edge, and six carry a blocker.** Three
share `first-adopter-evidence`, three share `gate-check-decision`, and the
remaining three have one each. That distribution is more useful than the count:
half the standard's open backlog is waiting on two things, and one of them is a
decision this repository could make on its own.

**Closing an item now has consequences the build states.** Closing
`gate-config-7` names `overlay-servicenow-3` as needing a re-read. Closing
`gate-config-11` or `12` names the overlay item that was waiting on it. Closing
half of `gate-config-2`/`spine-3` fails. That is a real constraint on future
ADRs and it is the obligation this release adds — an ADR that closes an item now
inherits everything pointed at it.

**A relation can rot in a way a count cannot.** `answered_by` names a heading in
another document, and headings get renamed; the check catches it and the failure
message says the answer moved with the section. That is the mechanism's own
declared risk, checked rather than hoped about.

**The overlay pays a second reconciliation in two releases.** ADR 0024 accepted
that cost for every Build DNA bump and it is now measured rather than argued:
twice, one §7 row each time, one note each time, no disposition moved either time.

**Nothing changes for the gate.** Twenty-seven checks, same semantics, same
inputs, same profile matrix. Build DNA open item 6 still records that no check
reads any of this, and it now carries `blocked_on: gate-check-decision` alongside
the two other items in the same position.

## Evidence

**Each invariant was confirmed to fail on a seeded defect,** and the first three
were re-run realistically after the naive version proved nothing: mutating only
the index trips the §17 count and status checks first, so the prose entry and the
counts were updated too, leaving the relation guard as the only thing that could
object. It objected in every case.

```
FAIL  duplicate_of is mutual and both halves carry the same status
      gate-config-2 is closed and its duplicate spine-3 is open — a duplicate closes on both sides or neither

FAIL  no open item is superseded by an item that has closed
      spine-1 is open and superseded by build-dna-2, which closed

FAIL  no open item is waiting on an upstream item that has closed
      overlay-servicenow-3 is open and waits on gate-config-7, which closed — re-read it against the closure and close it or say what is left

FAIL  open-items gate-config-8: answered_by names a heading overlays/servicenow.md still carries
      no heading '`release_state` on a platform that does not tag' — the section was renamed or removed and the answer this item rests on moved with it

FAIL  every blocked_on key is declared in the blockers vocabulary
      [('build-dna-4', 'someone-elses-problem')]

FAIL  no declared blocker is unused
      declared and cited by nothing: ['warn-cycle-measurement']
```

The second and third are the two findings this ADR fixes, reproduced as failures
on the tree that still had them.

`decisions/open-items.json` — `relation_types`, `blockers`, thirty-five items,
edges on five, blockers on six. `tools/validate.py` §18. `AGENTS.md` — version
1.8, §8 *Relations between items*. `gate/gate-configuration.md` — items 11 and
12, and item 8's carry-back paragraph.
`skills/decision-spine/reference/spine.md` — the numbering-stability note and
question 1 closed in place. `templates/open-items.json` — the relation and
blocker shape. `overlays/servicenow.md` — header, the *Reconciled in 1.5* note,
§7's index row; `overlays/servicenow.json`; `overlays/README.md`.

`VERSION` 1.11.0, `RELEASED` 2026-09-03, `bundle/manifest.json` regenerated;
`gate/checks.json` and `conformance/expectations.json` carry the new
`standard_version`.
