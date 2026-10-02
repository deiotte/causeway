# Placement — Skill Reference

**What this answers:** which Causeway tier and which criticality class a system
gets, and how somebody arrives at both *before* there is a `system.json` to read.

The rows are SA-1.14 (tier) and SA-1.1 (class). What the two values *do* once
they exist is `gate/gate-configuration.md` §3 and `reference/gate-profiles.md`.
This file is about how they are arrived at, argued, declared, and changed.

---

## Why this file exists

Every document in the standard read a placement and none of them produced one.

Build DNA §9 opens with *read `system.json` for `tier` and `criticality_class`*,
which is correct for a system that has already been placed and no help at all to
the one being built — which is the moment the answer is actually set. The spine
defined the three classes in nine words apiece, inside a paragraph explaining how
to read a table column. The tiers were never defined anywhere: the standard says
tier is a catalog fact, which is true about the *authority* and silent about the
*test*.

So the default did the work. Missing criticality resolves to C1, and that default
is right — but a system arrives at C1 that way by nobody's decision, and a team
that gets there by silence learns what the strictest gate in the standard costs
without ever learning what it is for. The loud default was carrying a question
the standard had not asked out loud.

This file asks it. It adds no check, moves no profile cell, and changes nothing
any system owes. It is the judgment half of §9's table — the half that belongs in
a document rather than a gate, and had not been written down.

---

## The two axes

Restated from `reference/spine.md`, because the single most common conceptual
error in this standard is folding them into one number.

| | Causeway Tier (SA-1.14) | Criticality Class (SA-1.1) |
|---|---|---|
| **Question** | Who inherits from it? | What does failure cost? |
| **Values** | Core / Mission / Operational | C1 / C2 / C3 |
| **Set by** | Causeway catalog placement | Product/Service Owner, Customer, or Sponsor |
| **Controls** | Which gate profile runs | How many spine rows apply |
| **Missing means** | Configuration error — the system is not registered | C1, the strictest class |

An Operational-tier citizen-developer app can be C1. A Core-tier shared service
can be C3. Assume nothing from one axis about the other, and never argue one by
citing the other.

---

## Criticality class — what a failure costs

Class is about consequence. Not size, not spend, not how visible the system is,
not how hard it was to build, and not how much the team cares about it.

### The four questions

Answer all four from evidence, not from confidence. **The most demanding answer
wins** — the same rule that collapses nine tier-by-class combinations into four
profiles. Three C3 answers and one C1 answer is a C1 system.

| # | Question | What it measures |
|---|---|---|
| 1 | **Harm** — when this is wrong or unavailable, what happens to somebody outside the delivery team? | safety, rights, money, mission |
| 2 | **Reach** — who is affected, and can they opt out? | blast radius |
| 3 | **Window** — how long can it be wrong or down before that harm lands? | survivability |
| 4 | **Detection** — would anybody know it was wrong? | silence |

Question 4 is the one teams skip, and it is the one that moves systems up. A
system that falls over at 3am has a bad night and an incident with a start time.
A system that returns a wrong answer nobody can distinguish from a right one has
an incident with no start time, no blast radius anybody can bound afterward, and
a population of decisions already made on the strength of it. Undetectable
failure is a C1 property on its own, and it is why a compliance engine — which
produces no customer-facing outage of any kind — belongs at C1.

### The classes

| Class | Harm | Reach | Window | Detection | Rows in scope |
|---|---|---|---|---|---|
| **C1** | Mission failure, a reportable event, harm to a person, or a disclosure that cannot be retrieved | People who cannot opt out | Minutes — or the harm has already landed by the time anyone looks | Failure can be silent | 94 |
| **C2** | Work degrades. People route around it at a real cost | A mission thread, a customer, teams beyond the builder | Hours | Failure is visible when it happens | 89 |
| **C3** | An annoyance | The team that built it | Days | Obvious to everybody affected | 23 (the short form) |

The one-line forms in `reference/spine.md` are the same three statements
compressed: *failure is a mission failure or a reportable event* · *failure
degrades work, survivable for hours* · *failure is an annoyance*. Where this
table and that one appear to disagree, they do not — this one is the working
form and that one is the index entry.

### Escalators — five facts that set C1 on their own

No combination of the four questions argues past any of these. Each is a single
fact, checkable, and each one ends the conversation:

1. **Safety of life or physical consequence.** Anything whose output moves,
   dispatches, dispenses, or withholds something in the physical world.
2. **Failure starts a clock somebody else owns.** Breach notification, incident
   reporting to an external authority, a statutory deadline. If being wrong
   creates a reporting obligation, the class is not yours to argue down.
3. **An irreversible disclosure is in scope.** Data that leaves your control is
   not retrievable by any later decision — the property SA-2.11 and SA-5.16 are
   one-way for. A system that *can* make that disclosure is C1 whether or not it
   has made one.
4. **It authorizes, denies, or attests on behalf of others.** A gate, an
   approval workflow, an evidence store, an identity broker. Its failure mode is
   a false pass, which is silent by construction and reaches every system
   downstream that believed it.
5. **Money or a benefit moves.** Payment, entitlement, eligibility, scoring that
   determines either.

**Escalators only escalate.** There is no de-escalator and there is deliberately
no list of facts that argue a system *down*. A team that wants a lower class
brings evidence against the four questions, to the authority that owns the
consequences, and gets a new declaration — it does not find an exemption here.

### What is not a criticality argument

- **"It's a prototype."** Prototypes serving real users are not prototypes; they
  are production systems with an unflattering label and no on-call rotation.
  Causeway has a legitimate answer for this shape and it is Operational tier plus
  a time-boxed Tactical Authorization — not a lower class.
- **"Only ten people use it."** Ten people who cannot opt out is a C1 reach.
  Reach is about optionality, not headcount.
- **"We would notice immediately."** That is an assertion, and question 4 asks
  for the mechanism. Name the alert, the reconciliation, or the person whose job
  it is to see it. If none exists, the answer to question 4 is *no*.
- **"The gate would be expensive at that class."** That is the cost of the
  consequence, correctly priced. Arguing the class to move the gate is arguing
  the gate, in the wrong document, to the wrong person.
- **"It sits behind a bigger system that is already C1."** Inheritance runs the
  other way. Being downstream of something serious does not make you serious, and
  being upstream of it is a tier question, below.

---

## Causeway tier — what inherits from you

Tier is a catalog fact. It is set by catalog placement, not by the delivery team,
and nothing here changes that. What this section supplies is **the test the
catalog applies** — so a team can predict its placement, propose one when it
registers, and recognize the day its system has outgrown one. A test nobody
outside the catalog can read is a test that gets discovered at a gate.

### The test

| Tier | The test |
|---|---|
| **Operational** | Serves one team or one mission thread. Nothing else is authorized on the strength of it. Time-boxed by design. |
| **Mission** | Serves a mission, a customer, or teams beyond the one that built it. Other systems **call** it. |
| **Core** | Other systems **inherit** from it — controls, authorization credit, or enforcement. Its failure reaches systems that never called it. |

### The Mission/Core line: "depends on" is not "inherits from"

This is the line that gets drawn wrong, and it is drawn wrong in the generous
direction — teams promote themselves to Core because a lot of things import them.

A shared library that forty services import is Mission. So is a popular internal
API, a reporting service the whole directorate reads, and a platform team's
paved-road template. All of them are *called*, and a caller that goes away stops
calling.

You are Core when your controls are **counted in somebody else's authorization
package** — when a reviewer reading another system's package is, without being
told, reading yours. Inheritance is the word, and it is literal: control
inheritance, authorization credit, an enforcement primitive another system's gate
consumes. The test is not *how many systems would notice if you broke*. It is
*how many systems would have to re-argue their own authorization if you turned
out to be wrong*.

That is also why **Core + C3 lands at G2**, which looks heavy for something
low-criticality and is not: at Core tier your blast radius is not your own
criticality. Core tier is never cheap, and that is the cost of being inherited
from rather than a penalty for being important.

### Operational is time-boxed, and the standard means it

**Operational + C1 lands at G1**, which looks light for a mission-critical system
and is only honest because Operational tier is temporary by construction. The
rule that keeps it honest is promote-or-sunset: a Tactical Authorization with a
duration, and **no third renewal**. Either the system earns Mission tier and G2,
or it is retired. Sunset counts as a disposition — the rule is *decide*, not
*promote*.

A system that keeps renewing in place is not an Operational system. It is a
Mission system that has not been re-placed, and the second renewal is the warning
the standard gives you before the third one blocks.

### What is not a tier argument

- **Headcount, budget, org chart, or prominence.** None of the four appears in
  the test.
- **"Everyone uses it."** Usage is reach, reach is question 2, and question 2 is
  a criticality question. Answer it over there.
- **"We want the lighter gate."** See above; same answer, same wrong document.

---

## Arriving at a placement

Six steps, in order. For a system already under way, the same six run as a review
— the only difference is that step 1 has evidence to draw on instead of estimates.

1. **Answer the four questions in writing.** Not in a meeting, not in a head. One
   line each, naming what the answer is drawn from. The writing is the point: a
   class you cannot reconstruct the reasoning for is a class that gets
   re-litigated from scratch the first time somebody questions it.
2. **Check the five escalators.** Any one of them ends step 1's arithmetic.
3. **Apply the tier test.** Independently — do not let the class you just derived
   colour it. *Who inherits from this?* is the only question in scope.
4. **Resolve the profile and say what it costs, out loud, before anybody
   starts.** Tier × class gives the profile; the profile and class give the rows.
   One line: *"Mission + C2 → G2, 89 rows in scope, one-way doors close before
   production code."* A profile discovered at a gate is a profile that arrives as
   a surprise, and surprise is the expensive way to learn this.
5. **Get it declared, by name.** Criticality is declared by the Product Owner,
   Service Owner, Customer, or Sponsor — whoever owns the consequences — as a
   person, not a role and not a board. Tier is proposed to the catalog and set
   there. A class you can get ratified in one line is worth more than a class you
   were correct about and never got declared.
6. **Write both down, with the argument.** `system.json` carries the values; the
   ADR closing SA-1.1 and SA-1.14 carries the reasoning. See *The declaration*.

**When step 5 stalls** — and it does, because the person who owns the consequences
is rarely in the room where the build starts — do not stall with it and do not
guess silently. Two questions get a proposal on the table:

> 1. If this is wrong, who is affected? *just me · my team · other teams or
>    customers · people who can't opt out*
> 2. How much of this could you undo in a week? *all of it · most · some ·
>    almost none*

The more demanding answer wins. Propose the class it implies, state the mapping
out loud, and put it to the authority as a one-line ratification: *"That reads as
C2 — you own the consequences, yes or no?"* If you still cannot get one, assume
**C1**, say that you are assuming it, and continue. That is what Causeway defaults
a missing class to anyway, so an undeclared class is not a neutral state; it is
the strictest gate in the standard, arrived at by nobody.

This is the triage `skills/survey/SKILL.md` step 1 runs, and it is a shortcut to a
*proposal*, never to a declaration. The four questions above are the test the
proposal gets checked against.

---

## The declaration

SA-1.1's evidence is *a class declaration signed by PO/SO/Customer/Sponsor*. Here
is what that means concretely, in the two places a reviewer will look.

**In `system.json`** — the values the gate reads, and the argument it does not:

```jsonc
{
  "tier": "core",                 // SA-1.14. Catalog placement, not self-assessment.
  "$tier": "Why this tier: who inherits, and what they inherit.",

  "criticality_class": "C1",      // SA-1.1.
  "$criticality": "Why this class: the question or escalator that decided it.",
  "criticality_authority": {
    "name": "Jane Doe",           // a person
    "role": "Sponsor",            // PO | Service Owner | Customer | Sponsor
    "declared": "2026-08-09"
  }
}
```

The `$`-prefixed siblings are conventional, not schema — the gate does not read
them and no check requires them. They exist because **a value with no argument is
a value nobody can disagree with**, which sounds like strength and is the
opposite: the first person who questions the placement has nothing to question,
so the whole derivation gets rebuilt from memory by somebody who was not there.
One paragraph, written once, ends that permanently. The worked example in the
table below is one of these, quoted verbatim from a real record.

**In the ADR closing SA-1.1 and SA-1.14** — the four answers, the escalator if one
fired, the alternatives considered (which class was nearly chosen, and what
decided against it), and the revisit condition. This is an ordinary ADR against
`templates/adr-template.md`; neither row is a named-approver row, so no `approver`
block is required, but the declaring authority belongs in the record by name
regardless because SA-1.1's evidence is a *signed* declaration.

**In the project's `CLAUDE.md`** — the placement block from
`templates/project-CLAUDE.md`, which is where an agent or a new engineer reads it
without opening anything else.

---

## Reclassification

Placement is a decision, not a property, and decisions change. Four rules keep a
change from being an escape hatch:

- **Up is immediate and needs no ceremony.** A delivery team may raise its own
  class the moment it learns something — the escalator it missed, the population
  it did not know could not opt out. It may not lower it. Raising is the one
  direction in which the team is a competent authority, because it costs the team
  and nobody else.
- **Down needs a new declaration from the same authority, against the same four
  questions.** What changed has to be in the world: a capability removed, a
  population that gained an alternative, a disclosure path closed. *"The risky
  part is finished"* is not a change in the world; it is a change in the team's
  confidence, and the four questions never asked about confidence.
- **Down is never retroactive.** A one-way door you already walked through stays
  walked through. Reclassifying C1 → C2 does not un-send data, does not retire
  the ADR that recorded sending it, and does not close a row that was owed at the
  time it was open. Rows newly owed by a reclassification *upward* close against
  the adoption horizon, exactly as rows added by a spine revision do.
- **Tier moves by catalog placement, not by declaration.** A team proposes; the
  catalog places. The two common movements are Operational → Mission at
  promote-or-sunset, and Mission → Core the first time another system's
  authorization package counts your controls — which is usually noticed by the
  other system's reviewer, not by you.

---

## Worked examples

| System | Tier | Class | What decided it |
|---|---|---|---|
| A compliance lifecycle manager — the engine other systems' gates run on | core | C1 | Escalator 4, and question 4. *An engine that passes a system it should have blocked produces a false authorization, and the failure is silent — the worst shape a failure can have.* Core because other systems' gates consume the primitives it emits; there is nothing above Core for it to be promoted into, which is the correct answer for the thing everything else inherits from. |
| An air-gapped appliance on fixed hardware, no local operations staff | mission | C1 | Nobody on site can restart it, so question 3's window is *however long the trip takes*. The air gap that removes whole categories of threat also removes the remediation path, which raises the class rather than lowering it. |
| A citizen-developer leave tracker, ten users | operational | C2 | Question 2: ten people who cannot opt out, on a system that decides whether their leave was recorded. Not C1 — no escalator fires, the window is days, and a wrong answer is visible to the person it was wrong about. Not C3 — the affected population is not the team that built it. |
| An internal design-system component library, imported by forty services | mission | C3 | Mission because forty services **call** it and none inherits authorization credit from it. C3 because the failure is an annoyance: a broken build, caught by the importer's own CI, fixed by pinning the previous version. Forty callers is reach, and reach did not make it C1. |
| A read-only dashboard over an authoritative system of record | operational | C3 | Adds no capability, moves nothing, and its failure sends people to the system it reads from — which is where they would have gone anyway. The system of record's class is the system of record's business. |

These are shapes rather than systems — none is a placement anyone has declared
here, and the second is reasoning about a deployment the standard describes in
Build DNA §2 — and they exist to draw the lines a single example would not: a
window set by physics, C2 without an escalator, high reach with a low class, and
the case where the honest answer is C3.

---

## Anti-patterns

- **Classifying the repository instead of the system.** A monorepo holding a C1
  service and a C3 scratch tool has two systems in it and needs two records. The
  gate reads a system, not a directory.
- **Deriving one axis from the other.** *"It's Core, so it must be C1"* and
  *"it's only Operational, so C3"* are the same mistake in opposite directions,
  and the matrix exists precisely because the two axes disagree often enough to
  need a table.
- **Leaving it blank and taking the default.** C1 by default is the right
  failure mode and a terrible resting state. The gate cannot tell the difference
  between a system somebody classified C1 and a system nobody classified at all;
  `criticality_authority` is the field that can, which is why it carries a name
  and a date rather than a role.
- **Re-arguing the placement at every gate run.** The argument belongs in the
  record once. A placement that gets rebuilt from memory monthly is a placement
  that will eventually be rebuilt wrong, and the rebuild will happen the week
  somebody needs it to come out low.
- **Treating the class as the team's opinion of its own work.** It is the
  authority's statement about consequences to other people. Teams
  systematically under-rate systems they have run for years without incident,
  which is survivorship reading itself as evidence.

---

## What this file does not do

It does not gate anything. The gate reads `tier` and `criticality_class`, resolves
the profile, and never sees the reasoning that produced either — a placement with
a thorough argument and one with none are byte-identical to every check in
`gate/checks.json`.

That is a deliberate stopping point, not an oversight. `placement-argued` — a
check that `criticality_authority` carries a real name and date, and that the
declaration ADR exists — is a candidate check and is registered as
`gate/gate-configuration.md` §10 item 13. Promoting it is a decision about cost
and needs a warn cycle to price, which needs a portfolio that has run this
procedure at least once. Nothing has. Until then this is judgment, in a document,
which is where Build DNA §9 says judgment goes.
