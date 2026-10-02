---
adr: "0013"
title: Publish the ServiceNow overlay in machine-readable form, and state the platform posture
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

Two things arrived together: a request to re-ratify the ServiceNow overlay against
Causeway 1.6, and an external review of what the overlay and its engine still owe.

The re-ratification is the smaller half and it resolves to *nothing moved*.
Causeway 1.6.2 changed `AGENTS.md`'s header wording, the release number, and one
`validate.py` check. The spine is still v0.8, the gate configuration still v0.6,
Build DNA still 1.5 — the three versions the overlay is ratified against, and the
three `validate.py` §13 already enforces. There was no drift to reconcile, which
is what the guard added in ADR 0011 is for: it turns "is the overlay current" from
a reading exercise into a build result.

What was missing is a way to say *when that was last confirmed*. The header states
what the overlay is ratified against and CI keeps those honest; it said nothing
about which release the confirmation happened in, so a reader asking "is this
current with 1.6?" had to derive the answer from three component versions.

The review's substantive finding is different and correct: **the overlay is not
consumable.** It is 94 dispositions, five answer sets, an input-class map and a
gate-evidence table, all in markdown tables. Anything that needs the mapping —
an engine, a register scaffold, a dashboard — has to parse prose or retype it.
Retyping is the part that matters. A team that retypes the disposition table into
its own tooling has forked the overlay, and the fork is not checksummed, not
versioned, and not covered by `check-drift.sh`.

The review also supplied the sentence this document had been assuming for two
versions without writing down: *ServiceNow should be the human work surface, not
the place where Causeway's semantics are independently reimplemented.*

## Decision

**Overlay 1.2.** Three changes, one of which is not a change.

**Ratified again, and recorded.** The header gains a **Reconciled at** row naming
the standard release the confirmation happened in — 1.7.0. It is history, in the
same sense `spine.closed_against` is history: the **Ratified against** row is what
CI enforces, and the new row is what a reader consults. It carries no coupling to
`VERSION` and nothing bumps it automatically, which is the distinction ADR 0012
just spent a release establishing.

**`overlays/servicenow.json`.** The same overlay, machine-readable: all 94
dispositions with their daggers, platform-vocabulary marks and notes; the five
one-way answer sets; all fourteen input classes with what supplies each one on
this platform with and without source control; and **a platform evidence statement
for every one of the 27 checks** rather than the eleven the prose curates.

Three rules keep it from becoming a second overlay, and they are in
`overlays/README.md` where the next overlay author will find them. The prose is
normative and the JSON is a projection. No gate check reads it — the containment
rules do not acquire an exception for being machine-readable. And it is derived
wherever derivation is possible: `validate.py` §14 recomputes the dispositions
from the markdown, the counts from those, the repo-class check list from
`checks.json`, and the per-profile blocking arithmetic from `profiles.json`, then
fails the build on any disagreement. It also enforces one containment rule
directly — an overlay may supply vocabulary for a one-way row but may not decide a
row is one-way, so every row in `one_way_vocabulary` must carry `Y` in the spine's
one-way column.

**The posture, stated.** §1 gains it explicitly: Causeway defines what must be
true, an engine determines whether it is true, ServiceNow carries the human work
and is a source of evidence like any other system of record. With a concrete test,
because the principle alone does not settle arguments — if a value the gate acts on
can be edited on the instance by someone holding a role, the instance is deciding,
and the receipt is describing the instance's opinion rather than the system's
state.

Version 1.7.0. Minor rather than patch: the standard publishes an artifact it did
not publish before, `sync.sh` vendors it, and the bundle digests it. No row, check
or threshold moved, so nothing a consuming project owes has changed.

## Alternatives considered

**Bump the overlay to 1.2 for the re-ratification alone.** Rejected, and worth
recording because it was the literal request. Cutting an overlay version to say
nothing changed is the empty bump ADR 0012 rejected for `AGENTS.md` one release
ago, and it would train the version number out of meaning anything. The
re-ratification rides along with work that does change the overlay.

**Make the JSON the overlay and generate the markdown.** Rejected. The prose
carries the reasoning — why extension is one-way, what a clone preserves, why
`not_applicable` is a verdict rather than an exemption — and none of that survives
a schema. The document is what makes the dispositions defensible; the mapping is
what makes them consumable.

**Generate the JSON from the markdown with a tool, like `bundle/manifest.json`.**
Rejected on coverage. Only part of the file is derivable — the platform evidence
for 27 checks and the input-class map are new content that no parser could produce
from the prose. A generator that emits half a file and requires hand-editing the
rest is worse than a hand-authored file with a guard, because the next person
cannot tell which half they are allowed to touch.

**Let the gate read the overlay, so dispositions become enforceable.** Rejected,
and it is the tempting one. It would let `shortform-closure` know that SA-4.1 is
inherited here. It also breaks the rule that makes overlays safe: the gate counts
ADRs, not dispositions, and an overlay that the gate reads is an overlay that can
grant relief. Inherited already closes with an ADR; there is nothing for the gate
to learn from the disposition that the ADR does not already tell it.

## Consequences

An engine integrating ServiceNow reads one file instead of inferring a mapping
from a document. That is the whole point, and it is the precondition for the
review's other asks — a ServiceNow evidence provider, native evidence mappings —
which are engine work that now has something to build against.

Overlays acquire an optional second artifact, and with it the risk that a future
overlay ships a JSON that quietly disagrees with its prose. That risk is why §14
exists and why it recomputes rather than trusts. The cost lands on the overlay
author: hand-editing the disposition table now means hand-editing two files, and
CI says so immediately rather than eventually.

The posture statement gives the overlay something it did not have — a stated
reason to say no. "Build the profile-resolution logic as a flow, it's easier" now
has a document to disagree with rather than needing to be relitigated per team.

Several findings from the review remain open and are deliberately not acted on
here: centrally inheritable platform baselines, SA-8.8's one-way behaviour,
platform-impact escalation rules, and ServiceNow conformance fixtures. The first
three change what systems owe or how profiles resolve, which is spine and gate
work rather than overlay work, and the fourth needs the conformance format to be
able to express an engine that cannot supply an input class — a schema question
that deserves its own decision. They are recorded as overlay open items rather
than folded into a version that claims to be a reconciliation.

## Evidence

`overlays/servicenow.json` — 94 dispositions, 27 evidence statements, 14 input
classes, 5 one-way answer sets. `./tools/validate.py` — 390 checks, including
§14's. Each class of guard was confirmed to fail on a seeded defect: a disposition
changed in the JSON only, an evidence entry disagreeing with `checks.json` about
what a check reads, one-way vocabulary attached to a row the spine does not flag
one-way, a tampered per-profile blocking count, and a dropped input class.
