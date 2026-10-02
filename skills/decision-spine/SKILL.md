---
name: decision-spine
description: Apply the Causeway Decision Spine to a system — the complete set of architecture decisions a system must close. Use when designing a new system or service, reviewing one at a gate or milestone, writing a system architecture document, deciding what still needs to be decided, recording an ADR, or checking whether a system is ready to ship, promote, or authorize. Also use when someone asks what they've missed architecturally, what decisions are outstanding, or whether a design is complete.
---

# Decision Spine

The Decision Spine is the complete set of decision surfaces a system has to
close — 94 numbered rows across 9 sections. It is not a checklist of good
practices. It is the index that three working documents are generated from.

Your job is not to print the spine. Your job is to pick the right view of it,
scope it correctly, and refuse to let a row close on prose.

---

## Step 1 — Pick the view

**This is the actual work.** A user who already knew which view they wanted
wouldn't need this skill. Do not ask which view they want; infer it, state your
inference in one line, and proceed.

| Signal in the request | View |
|---|---|
| "designing", "building", "starting", "what do we need to decide", "is this the right approach" | **Decision Register** |
| "reviewing", "gate", "milestone", "ready to ship", "did we miss anything", "audit", "promote" | **Review Checklist** |
| "write the architecture doc", "SAD", "for the customer", "for the evaluator", "document the design" | **SAD Outline** |

Tiebreakers when signals conflict:

- **Tense decides.** Future ("we're going to build") → Register. Past ("we built")
  → Checklist or Outline.
- **Audience decides between Checklist and Outline.** Internal reader who can
  fail the system → Checklist. External reader who receives it → Outline.
- **Genuine ambiguity → Register.** It is the only view that's useful when the
  work isn't finished, and it's the cheapest to be wrong about.

Never produce two views in one response. If the user needs a second, they'll ask,
and the switch is cheap. Blending them produces a document nobody uses.

## Step 2 — Establish scope before reading the spine

Do not load `reference/spine.md` yet. Scope first, or you will burn context on
70 rows the user doesn't need.

Two facts determine scope:

1. **Criticality class** (C1 / C2 / C3) — spine row SA-1.1
2. **Causeway tier** (Core / Mission / Operational) — spine row SA-1.14

Find them in this order:

1. Read `system.json` in the repo if it exists — `criticality_class` and `tier`.
2. If absent, ask for both in one question. One question, not two turns.
3. If the user won't or can't say, **assume C1** and say so explicitly. The
   failure mode of assuming C3 is a mission-critical system reviewed as a
   prototype. The failure mode of assuming C1 is a slightly long conversation.

**If the fields do not exist yet, you are not reading a placement — you are
helping write one.** That is a different job with its own procedure, and it is
`reference/placement.md`: four questions, five escalators that set C1 on their
own, the tier test, and what the declaration has to contain. Read it before
proposing a class, and remember rule 5 below — you may propose one, you may not
record one.

A third fact determines whether the system is **behind**, and you check it in the
same pass:

4. Read `spine.closed_against` from `system.json` and `spine_version` from the
   vendored `gate/profiles.json`. The vendored file is authoritative for what
   applies; `closed_against` is history. If they differ, rows added between the
   two versions are **newly owed** and carry adoption horizons — see *Adoption
   and version drift* in `reference/spine.md`.
5. Missing `spine.closed_against` means no adoption grace. Every applicable row
   is owed now. Do not read a missing field as "up to date."

These axes are **independent**. An Operational-tier citizen-dev app can be C1.
A Core-tier shared service can be C3. Never infer one from the other.

Row counts by class — quote these before producing anything, so the user knows
what they're in for:

| Class | Rows in scope |
|---|---|
| C1 | 94 |
| C2 | 89 |
| C3 | 23 (the short form) |

## Step 3 — Load only what you need

Now read `reference/spine.md`, and read only the sections in play.

- Full-system work → all 9 sections, filtered by the `Applies` column.
- A question scoped to one concern (data model, security posture, DR) → that
  section plus SA-1, which every section inherits constraints from.
- Gate or profile questions → also read `reference/gate-profiles.md`.
- *What class are we?* / *should this be Core?* → `reference/placement.md`, and
  do not answer from the profile matrix. The matrix consumes the placement; it
  cannot produce one.
- Someone asking *why* a row exists or what to read → `reference/references.md`.

## Step 4 — Produce the view

### Decision Register

For the architect, during design. Output a table:

| ID | Decision | Answer | ADR | Status |
|---|---|---|---|---|

- Pre-fill `Answer` from anything already decided in the conversation or repo.
- Leave genuinely open rows blank. Do not guess and do not fill with a
  "recommended" default — an unmade decision that looks made is worse than a
  blank.
- **Sort one-way doors to the top.** 28 rows are expensive or impossible to
  reverse. Say so, and say that they should close before production code.
- **Mark newly-owed rows with their horizon date**, sorted alongside the one-way
  doors rather than in a section of their own. A row owed by a date is more
  urgent than an open row with no date, and burying it under a "version drift"
  heading is how it gets read as bookkeeping.
- End with the count: closed / open / waived / newly owed.

### Review Checklist

For the reviewer, at a gate. Output a table:

| ID | Criterion | Pass / Fail / Waived | Finding | Evidence |
|---|---|---|---|---|

- Every verdict needs an evidence pointer. "Looks fine" is not a pass.
- Fail is the default for anything you cannot verify. Absence of evidence is
  not evidence of closure.
- A newly-owed row inside its adoption horizon is a **finding with a date**, not
  a pass and not a fail. Say which date and say what happens on it.
- Findings are specific and actionable: name the row, name what's missing, name
  what would close it.

### SAD Outline

For the reader at delivery. Output narrative section headings with the relevant
decisions as prompts beneath each. Prose, not tables.

- Do not write the prose unless asked. The outline is the deliverable; the
  decisions are the prompts.
- Group by reader logic, not by spine section order. Readers want context →
  architecture → security → operations, not SA-1 through SA-9.

---

## Hard rules — apply in every view

These are the reason the spine works. Enforce them even when the user pushes.

1. **A decision without an ADR is not closed.** If someone says "yeah we decided
   Postgres," the row is *open* until there's an ADR reference. Say so plainly
   and offer to draft the ADR. Do not accept conversational agreement as
   closure.

2. **Eight rows require a named human.** SA-1.8, SA-1.9, SA-2.11, SA-5.7,
   SA-5.10, SA-5.13, SA-5.16, SA-9.4. A role is not a name. "The AO" does not
   close SA-5.10; "Jane Doe, AO" does. Four of these eight are in the C3 short
   form — even a sandbox prototype needs names on classification, key custody,
   disposition, and what it sends to a model it does not run.

3. **Waivers are ADRs with mandatory expiry.** Status `Waived`, and it must
   carry: row ID, why not now, risk accepted, expiry date, who accepted, review
   trigger. Maximum 180 days for C1, 365 for C2–C3. There is no such thing as an
   open-ended waiver. An expired waiver is a gate failure, identical to an
   unclosed row. Surface anything expiring within 60 days unprompted.

4. **Never let anyone set a gate profile.** G0–G3 is derived from tier × class,
   never declared. If a user asks to set `gate_profile` in `system.json`, refuse
   and explain: a profile a team can choose is decorative.

5. **Never guess a criticality class.** It is set by the Product Owner, Service
   Owner, Customer, or Sponsor — whoever owns the consequences. You may assume
   C1 as a working default; you may not record one. A team may raise its own
   class the moment it learns something; lowering one takes a new declaration
   from the same authority, and never applies backward — `reference/placement.md`
   has the rules and the two questions that get a proposal ratified in one line.

6. **"Not yet" is a legitimate answer. "Never asked" is not.** The point of the
   spine is coverage, not speed. A waived row with a date is a success. A row
   nobody considered is the failure this exists to prevent.

7. **A retroactively added one-way row does not close on an intended answer.**
   When a revision adds a one-way row to a system that is already running, the
   door is already shut and the ADR must state what the system has *actually*
   been doing. Refuse a forward-looking answer here as firmly as you refuse
   prose in place of an ADR. If the as-built answer reveals ongoing
   unrecoverable exposure, say plainly that it needs the ISSM and a date in the
   ADR, not a design discussion.

---

## Anti-patterns

- **Dumping all 94 rows.** Scope first, always. A C3 team shown 94 rows will
  ignore the whole instrument, and you will have made things worse.
- **Filling blanks with plausible defaults.** You are surfacing decisions, not
  making them. The exception: you may propose an answer *labeled as a proposal*
  when explicitly asked what you'd recommend.
- **Accepting prose as closure.** See hard rule 1. This is the most common way
  the spine degrades into theater.
- **Treating tier and class as one axis.** They are orthogonal. This is the
  single most common conceptual error with this model.
- **Producing a view nobody asked for the moment.** A design conversation does
  not need a review checklist appended.
- **Re-deriving the spine from memory.** Read `reference/spine.md`. Row IDs are
  stable and cited by ADRs, gate receipts, and other systems; an invented row ID
  is worse than no row ID.

---

## Files

| File | Read when |
|---|---|
| `reference/spine.md` | Always, after scoping. The 94 rows, sections, `Applies` column, one-way doors, C3 short form. |
| `reference/placement.md` | Before scoping, when `tier` or `criticality_class` does not exist yet or is being challenged. How a system arrives at both, and how a placement changes. |
| `reference/gate-profiles.md` | Gate, CI, promotion, or Tactical Authorization questions. |
| `reference/references.md` | Someone asks why a row exists or what to read on it. |

The spine is the design layer. `AGENTS.md` at the repo root is the process
layer. They meet at the ADR and nowhere else — if you find yourself explaining
*how the team builds* rather than *what this system decided*, you're in the
wrong document.
