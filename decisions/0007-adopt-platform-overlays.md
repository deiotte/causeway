---
adr: "0007"
title: Adopt platform overlays, and ship ServiceNow as the first
status: Accepted
date: 2026-08-09
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

Teams doing ServiceNow development asked whether Causeway applies to them. The
same question is owed to Power Platform, where a prior build already adapted to SharePoint
and Power Automate in practice without anyone writing down what the adaptation
was. That undocumented adaptation is the actual problem: the standard has been
flexed to platforms twice and has no place to record the flexing, so each team
rediscovers it.

A draft ServiceNow profile was written before this repository was in front of the
author. Reading it against the register falsified its central claim. The draft said
*the Decision Spine shrinks, on the record* and *a huge fraction of your ~90 rows
are platform-answered*. Dispositioning all 94 rows says **11 are inherited**, and
**one of the 23 short-form rows** is. The draft also had the row count, four of the
nine section names, and a parallel register of seven "ServiceNow one-way doors"
that does not survive contact with the spine's 28 — three of the seven are not
one-way rows at all, and the other four already exist as SA-1.7, SA-2.1, SA-3.1,
and SA-3.8.

None of that is a criticism of the draft. It is the argument for why an overlay
gets written against the register or not at all, and it is the reason the draft
marked itself *pending row-level ratification* rather than shipping as-is.

The gap between the intuition and the number is worth naming, because it is the
thing an overlay exists to prevent people from getting wrong: *I do not have to
build it* and *I do not have to decide it* are different statements. ServiceNow
provides encryption at rest. Which columns get it, who holds the keys, and whose
name is on that choice remain three open questions. That pattern produces 39 shared
rows — mechanism supplied, decision outstanding — and a team that reads a managed
platform as a reduced spine will close none of them.

## Decision

Platform overlays are a first-class artifact of the standard, living in
`overlays/`, and the ServiceNow overlay ships as the first one, ratified against
spine v0.7.

An overlay dispositions all 94 rows as **inherited**, **shared**, or
**project-answered**; supplies platform vocabulary for the answer sets that have
one; names the artifact each gate check reads on that platform; and names the
concrete mechanism for each gate profile. It does nothing else.

Four decisions inside that, each of which could have gone another way:

**Inherited is a closure state, not an exemption.** A row the platform answers
still closes with an ADR — a paragraph and a citation. This is what keeps the gate
untouched: it counts ADRs, not dispositions, so no check reads an overlay and no
check ID is added. It also keeps `rows_closed` in the receipt meaning what it
meant. An overlay that let `I` read as *skip* would be a self-service exemption
mechanism, which is the decorative-declaration failure the gate configuration
forbids in its first design rule.

**Overlays are contained by rule, not by discipline.** An overlay may not add,
retire, or renumber a row; may not change a row's `Applies` class, one-way flag, or
named-approver status; may not change or add a gate check; and may not excuse a row
from needing an ADR. The ServiceNow overlay hit that wall once and left the finding
where it hit — SA-8.8, source control versus update sets, reads like a one-way door
and is not one in the spine. It is recorded as an open item pointing upstream
rather than legislated locally, which is the rule working rather than the rule
being tested.

**They are called overlays, not profiles.** `gate/profiles.json` and
`reference/gate-profiles.md` already own *profile*, and it means G0–G3 everywhere
in this standard. Two things under one word is the failure the spine warns about
for tier and criticality, and its remedy there was two names rather than a
qualifier. *Overlay* is NIST SP 800-53 tailoring vocabulary, already in the
ratified reference set, already feeding SA-5.9's control-allocation question, and
it means precisely this.

**Vendoring is opt-in and checksummed.** `sync.sh --overlay <name>` copies the
overlay and records it in `.causeway-lock` as both a named line and a hash. A Go
service carries no ServiceNow disposition table, and a ServiceNow project cannot
edit its own dispositions without failing `check-drift.sh`. Dispositions are the
one thing in an overlay that looks like it grants relief, so they get the same
treatment as everything else that does.

Projects may tighten a disposition freely and silently. Loosening one is a
deviation with a row in the exceptions register and an ADR behind it.

## Alternatives considered

**Fork the spine per platform.** A `spine-servicenow.md` with rows removed. Fails
immediately: row IDs are cited by ADRs, receipts, and other systems, and two
documents with the same IDs and different contents is how the canonical copy goes
missing — the failure this repository exists because of.

**Add platform rows to the spine.** An SA-10 for platform concerns, or ServiceNow
answer sets inline. Fails on scale — every platform's vocabulary in one document —
and on relevance, since a Rust service would carry rows about domain separation.

**Leave it in each project's `CLAUDE.md`.** What happens today. It is why the
SharePoint and Power Automate adaptation is unwritten. Every team pays the analysis
cost again and gets a different answer, and none of the answers is reviewable.

**Ship the draft as `profiles/servicenow.md` with the section-level disposition it
had.** Tempting, because it was close and it was already written. Rejected on the
name collision and because section-level disposition is where the draft's central
error lived: at section level, SA-4 reads as *inherited* and the fact that SA-4.7
is project-answered, one-way, and in the short form disappears. The row-level table
is not a refinement of the draft. It is the part that makes it true.

## Consequences

**Easier.** A ServiceNow team has a register scoped to their platform on day one,
with the five one-way rows whose answer sets actually differ called out in the
platform's own vocabulary. The `AGENTS.md` §8 exceptions register doubles as the
customization ledger, which turns *what did we modify* from an upgrade-window
archaeology exercise into a list someone already owns. Onboarding a new platform is
a documented six-step procedure rather than an improvisation.

**Harder.** Every overlay is a maintenance surface that ages with its platform —
the ServiceNow overlay already records that Now Assist is moving faster than it is.
An overlay written from memory of the spine rather than against it produces
confident, wrong dispositions, and a wrong disposition is worse than none because
it looks like it was checked. The containment rules are prose, and nothing
mechanically enforces that an overlay leaves the row set alone.

**Committed to.** Overlays are guidance in the `AGENTS.md` §9 sense and will stay
there. The moment a check reads an overlay, dispositions become a control surface
teams can argue with, and the arithmetic that makes a receipt trustworthy stops
adding up.

**Not committed to.** Power Platform is not written here. It is the obvious second
overlay and it needs someone with that build's history, because deriving it from the
platform's documentation would reproduce exactly the error this ADR is about.

## Evidence

`overlays/README.md` — the mechanism, the three disposition states, the containment
rules, and the inherited-row ADR shape.

`overlays/servicenow.md` — 94 of 94 rows dispositioned, counts published and
summing to 94, all 8 named-approver rows preserved, 0 rows added or reclassified.

`tools/sync.sh --overlay <name>` and the `overlay=` line in `.causeway-lock`;
`tools/check-drift.sh` covering the vendored overlay. Verified: a plain sync carries
no overlay, an overlay sync records and hashes it, and an edited vendored overlay
fails drift with exit 5.
