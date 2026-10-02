---
adr: "0025"
title: Index the open items ADRs leave behind, and check the index against the registers
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

An ADR closes a spine row. It also leaves things behind — a question it declined
to answer, a guard it deferred, a gap it published under §8's declared-gaps rule —
and each of those lands as a numbered item in whatever document the ADR was
amending. Four documents carry such a list here: `AGENTS.md`,
`gate/gate-configuration.md` §10, `overlays/servicenow.md` §10, and the spine's
*Open questions*. Four independent numberings, every open and every close written
in prose and nowhere else, and nothing counting any of it.

The report came from a consuming project. It found that its ADR count and
its open-item count both went stale, in the ordinary way: a number stated in one
document, restated in a second, and nothing recomputing either when an ADR moved
the underlying set. That is a consumer hitting the shape this repository has been
fixing one instance at a time — ADR 0011 for the overlay's versions, ADR 0020 for
prose guards, ADR 0024 for the third version in an overlay header. The same shape
one register over, again.

Reading our own registers against that report found it here too, and worse than
the reporter's version.

**`gate/gate-configuration.md` open item 10 was not in §10.** ADR 0009 opened it
and appended it to the end of §11, two hundred lines past where the register ends.
ADR 0019 half-closed it in place. ADR 0023 amended it again and described it as
keeping *its number per the rule §10 states for itself* — a sentence that is only
true if the item is in §10, and it was not. Three ADRs pointed at an item no
reader of the register could find. §10 showed nine items for eleven releases, the
README cited item 10 by number, and nothing disagreed, because nothing was
counting. This is not a typo. It is the exact failure the numbering-stability note
at the top of §10 was written to prevent, arriving through a door that note does
not cover: the note protects an item's *number* and says nothing about its
*position*, and a register is a place before it is a sequence.

The distinguishing feature of this class of bug is that every individual document
is defensible. Item 10 was well written. Its amendments were correct. The
register's rule about numbers was right and was followed. Nothing was wrong except
that no artifact anywhere answered *how many items are open*, so the question was
answered by whoever last counted by hand, and that answer aged.

## Decision

**An open-items index carries the state; the prose entry keeps the argument.**
`decisions/open-items.json` lists every numbered item across all four registers
with its status, the ADRs that opened and closed it, and the version each happened
in. The prose entry keeps its number, its paragraph, and its reasoning, and stops
being the only place status lives.

The split is the decision. An open item is a paragraph of reasoning with a number
on it, and reasoning does not belong in JSON; a status is a fact about a set, and
a fact about a set does not belong in twenty-seven separate paragraphs. Everything
that follows is that line drawn in one place at a time.

**Build DNA moves to 1.7** and §8 gains the rule, between the exceptions register
and declared gaps — the two neighbours it belongs with, since it is an index of
ADR output and an open item is a declared gap that outlived the ADR that declared
it. Five sub-rules: numbers stay stable and closed items keep their entry; every
register is declared in the index; the index is hand-maintained; an item cites
ADRs that exist; every stated count derives.

**`tools/validate.py` §17 checks the index against the prose.** For each declared
register it reads the named section, extracts the numbered items, and asserts the
number sets match exactly; that the closed marker in an item's bold lead-in agrees
with the index's status; that every ADR named exists; that a closed item names
both its ADR and its version; that no open item already names a closing ADR; that
the counts derive; and that the README's stated count matches. Sixteen assertions
in total, and the number-set assertion is the one that would have caught item 10:
§10 would have offered nine numbers against an index carrying ten.

**Item 10 is relocated into §10**, keeping its number and its text. The gate
configuration version does not move — nothing normative changed, which is ADR
0023's own reasoning about this same item, applied again.

**Consumers get the rule and the template, not a check.** `templates/open-items.json`
is seeded once by `sync.sh` into `decisions/open-items.json` and never overwritten,
on the same terms as `CLAUDE.md` and for a sharper version of the same reason: an
index this script clobbered on re-sync would delete every item the project had
recorded, which is a more thorough version of the failure it exists to prevent.
Neither file is in the digested bundle, both are declared in `bundle/scope.json`,
and the reasons differ — ours is this repository's own record, theirs becomes
theirs on first write.

**The overlay reconciles to 1.4**, forced by ADR 0024's guard doing its job on its
first Build DNA bump. §7 gains one row. The platform-specific content is real:
ServiceNow has three surfaces shaped like an open-item register — the
customization ledger, skip records, Instance Scan findings — and none of them is
this one, so the row says which is which before a shop merges them into a list
where *open* means four different things.

**Version 1.10.0, minor.** It adds an obligation a consumer did not have.

## Alternatives considered

**Make the index authoritative and retire the prose entries.** The question
the consuming project raised, and the one place here where the argument is
genuinely two-sided.
It is cheaper, it removes the duplication this ADR instead chose to check, and the
single location is unambiguous rather than merely enforced. Rejected on what it
costs: *a closed item keeps its number and its entry, marked closed with the
resolution* is a rule ADR 0021 leaned on to close Build DNA item 2 in place, ADR
0022 restated for Build DNA's own items, and ADR 0024 applied when it corrected
overlay item 5 rather than dropping it. Retiring the entries reverses all three,
and it moves the reasoning into JSON or loses it. The reasoning is the expensive
part. What went stale was the arithmetic, and this ADR fixes the arithmetic
without spending the argument to do it. Recorded as a real alternative rather than
a strawman, because if a second register goes wrong in a way the split causes, it
is the option to reopen.

**Generate the index from the prose.** The obvious way to make duplication
impossible, and it requires parsing the registers to build the artifact. ADR 0020
and §16 of the validator are both about what happens next: a guard that reads
prose cannot distinguish *this went stale* from *this was rephrased*, it reports
the second as the first, and the cheapest way to green is to write the sentence
back. §16 fired three times on three README rewrites with the number correct every
time. Generating the index would make that mechanism load-bearing instead of
merely present. Hand-maintained and checked is more work per commit and the work
is in the commit that already knows the answer.

**Skip the index; extend the validator to count the registers.** Would fix the
staleness with no new artifact. Rejected because it does not answer the question
that was actually asked. *How many items are open* is answerable by counting; *what
is open, and which ADR left it that way* is not, and the second is the one a person
opens a register to ask. A check that knows the count and cannot show the list is a
check that has the data and withholds it.

**Add a 28th gate check.** Would make the index enforceable in a consuming project
rather than merely stated. Rejected for now and recorded as Build DNA open item 6
rather than deferred silently: the gate's 27 checks each earned their place from
something observed, an index is a discipline before it is a control, and promoting
it on the release that invents it would be deciding on its first day what it costs.
The candidate check is written down in the item so the next person does not have to
re-derive it.

**Renumber gate item 10 into the register, or leave it where it was.** Renumbering
is the practice §10's own note ends. Leaving it was briefly tempting on grounds
that moving bytes in a bundled file is a release — but that is an argument for when
to ship the fix, not whether, and this release moves the file anyway.

**Include the README's credibility gaps and development priorities.** Nine and nine
more, already cross-referenced by number from ADR 0024. Rejected because
`bundle/scope.json` declares the README ungoverned for a stated reason: it
describes the standard and is not part of it. Pulling its lists into a governed
index would make the front door carry an obligation it was explicitly relieved of.
They stay editorial.

## Consequences

**Twenty-seven items are open.** Nobody knew that number before today, which is
the finding rather than a preamble to it. Eight of the twenty-seven are in the
gate configuration, eight in the overlay, six in the spine, five in Build DNA.
Six items have closed across the standard's life and all six name the ADR that
closed them.

**A count in prose can no longer drift, and a register can no longer lose an
item.** Those are two different guarantees and the second is the new one. §16
already stopped counts from going stale where an anchor covered them; nothing
before this stopped an item from existing outside the list that was supposed to
contain it.

**Attribution is honest about its holes.** `opened_by` is null for fifteen items,
because six registers' worth of history predates this index and two rounds of
renumbering ran through it. A cell filled by inference would be manufactured
evidence, which is the thing §8's declared-gaps table refuses in four other
places. Null means *not attributable from the record*, the index says so in
`$attribution`, and every item opened from here forward carries its ADR.

**Two items are now visibly duplicated across registers.** `gate-config-2` and
`spine-3` are the same question — do catalog items get a criticality class —
asked in the enforcement layer and the design layer, neither citing the other.
`spine-1` asks the spine's version of a Build DNA question that ADR 0021 settled.
Both were true before today and neither was visible. They are annotated rather
than merged: closing an item because a neighbour closed is how a register stops
meaning anything, and the ADR that closes either should close both rows and say
so.

**Every future Build DNA bump costs an overlay reconciliation.** Already true
since ADR 0024; this is the first release to pay it, and it cost one §7 row and
one note. That is roughly what ADR 0024 predicted, which is a small piece of
evidence for a guard whose cost was argued rather than measured.

**The gate is unchanged.** Twenty-seven checks, same semantics, same inputs, same
profile matrix. A project that re-syncs owes one file it did not have, seeded for
it, with no check reading it.

## Evidence

**The guard was written first and made to fail before anything was reconciled.**
On the tree with the index added and nothing else moved, `validate.py` reported
six failures and nothing else — the two `scope.json` patterns not yet tracked, ADR
0024's Build DNA guard firing on 1.7 in both the prose header and the projection,
and three from the new section:

```
FAIL  no ungoverned pattern is dead
      matches no tracked file: ['decisions/open-items.json', 'templates/open-items.json']
FAIL  overlay servicenow: ratified against the current Build DNA
      overlay says 1.6, standard ships 1.7 — reconcile the overlay and move its header
FAIL  overlay servicenow.json is ratified against the current Build DNA
      json 1.6 vs AGENTS.md 1.7 — reconcile the overlay against the new Build DNA and move both headers
FAIL  open-items index standard_version matches VERSION
      index 1.10.0 vs VERSION 1.9.2
FAIL  every ADR named by an open item exists
      [('build-dna-6', 'opened_by', '0025')]
FAIL  the open-item count is no longer stated in prose
      the index derives (27, 4). State it, or add an anchor to OPEN_ITEM_ANCHORS if the wording is right and the pattern is not.
6 failed · 527 passed
```

The number-set and status assertions passed on that run, against all four
registers and including the relocated item 10 — which is the evidence that the
index describes the registers as they are rather than as it would like them.

**Each class of guard was confirmed to fail on a seeded defect,** in the sense
ADR 0013 established. Dropping an item from the index, flipping a status,
citing an ADR that does not exist, and breaking the derived counts each fail with
a message naming the defect rather than the pattern. The fourth mutation is the
one worth recording — item 10 moved back to where it spent eleven releases:

```
FAIL  open-items register gate-config: the index and gate/gate-configuration.md carry the same numbers
      indexed but not in the section: [10] · in the section but not indexed: none
```

The bug that motivated this ADR now stops a push, and the failure says which
number went missing from which register.

`decisions/open-items.json` — 33 items, 27 open, 6 closed, four registers.
`AGENTS.md` — version 1.7, §8 *The open-items index*, open item 6.
`gate/gate-configuration.md` — item 10 in §10, and the relocation note in the
section preamble. `tools/validate.py` §17. `tools/sync.sh` — the seeding block.
`templates/open-items.json`. `bundle/scope.json` — two patterns with distinct
reasons. `overlays/servicenow.md` — header, the *Reconciled in 1.4* note, §7;
`overlays/servicenow.json` — `overlay_version`, `ratified_against.build_dna`,
`reconciled_at_standard`; `overlays/README.md` — the overlay table.

`VERSION` 1.10.0, `RELEASED` 2026-09-03, `bundle/manifest.json` regenerated;
`gate/checks.json` and `conformance/expectations.json` carry the new
`standard_version`.
