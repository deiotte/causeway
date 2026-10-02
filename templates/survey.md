# SURVEY — {{PROJECT}}

> **What this is.** The Survey is the intake artifact that precedes a Causeway build.
> It is written on the chat side, with a human in the loop, *before* any ADR is
> written and before the Claude Code handoff package is generated.
>
> **Why it exists.** ADR churn — records amended or invalidated within days of being
> written — is almost never a decision-making failure. It is an intake failure: the
> decision was recorded before the constraint that governs it had surfaced, or before
> the decision it depends on was made. The Survey exists to make that constraint
> surface *here*, where changing your mind is free.
>
> **The rule that makes it work:** a Survey that changes twice a day is working
> correctly. An ADR that changes twice a day is broken. Push the churn upstream.
>
> This is intake, not a design review. Its only job is to say which decisions you are
> in a position to make. If it starts arbitrating architecture it has overreached.

| | |
|---|---|
| **Survey version** | v0.1 |
| **Date** | YYYY-MM-DD |
| **Surveyor(s)** | {{name}} + Claude |
| **Causeway tier** | operational \| mission \| core |
| **Criticality class** | C1 \| C2 \| C3 — *declared by PO/Service Owner/Customer/Sponsor, by name* |
| **Declared by** | {{name, role, date}} |
| **Gate profile** | *derived — do not set* |
| **Survey depth** | *derived from profile — see Depth below* |
| **Status** | Drafting \| At exit criteria \| Passed \| Passed w/ conditions |

**If the class is not declared yet,** do not guess it and do not stop. Ask the two
questions that get there — *if this is wrong, who is affected?* and *how much of it
could you undo in a week?* — propose the class they imply, and put it to the named
person as a one-line ratification. The strictest answer wins across the two. Causeway
defaults a missing class to **C1**, so an undeclared class is not a neutral state; it
is the strictest gate, arrived at by nobody's decision. A class you got ratified in
one line is worth more than a class you were right about and never got declared.

Those two questions are triage and produce a **proposal**. The test the proposal gets
checked against — four questions, five facts that set C1 on their own, and the
inheritance test for tier — is `skills/decision-spine/reference/placement.md`. Read it
when the two questions disagree, when somebody argues the class down, or when the tier
is the part in doubt.

---

## Depth — how much of this template applies

Do not fill in sections that the profile does not require. A C3 sandbox forced
through the full Survey produces theater, and the team stops believing the instrument.

| Section | G0 | G1 | G2 | G3 |
|---|---|---|---|---|
| S0 Frame | ✅ | ✅ | ✅ | ✅ |
| S1 Ground (constraints) | ✅ | ✅ | ✅ | ✅ |
| S2 Load (capabilities + walkthroughs) | short | ✅ | ✅ | ✅ |
| S3.1–S3.2 Bearings (invariants + failure modes) | invariants only | ✅ | ✅ | ✅ |
| S3.3 Deliberate non-defenses | — | optional | ✅ | ✅ |
| S4 Spans (decision inventory) | one-way doors only | ✅ | ✅ | ✅ |
| S5 Handoff (derivation + premortem) | ✅ | ✅ | ✅ | ✅ |
| Premortem | 1 item | 3 items | 3 items | 5 items + named reviewer |

S3.3 is what separates G2 from G1. A system whose failure degrades a mission owes an
explicit statement of what it is *not* defending against, because at G2 the difference
between a threat that was considered and dismissed and one nobody raised is the
difference an assessor will ask about. Below G2 that statement is a nicety; at G2 it
is the record.

**IDs are permanent.** Every row in this document carries an ID. ADRs cite them,
the handoff package cites them, and supersession traces back through them. Never
renumber. A deleted row keeps its ID with status `withdrawn` and one line saying why.

| Prefix | Meaning |
|---|---|
| `GR-n` | Ground — a constraint we did not choose and cannot negotiate away |
| `LD-n` | Load — a capability, flow, or volume the system must carry |
| `IV-n` | Invariant — something that must be true at all times |
| `FM-n` | Failure mode — a way this breaks, and the designed response |
| `DEC-n` | Decision surface — something with a real alternative |
| `PR-n` | Probe — a time-boxed spike that decides one `DEC-` row |
| `OPEN-n` | Open question — unresolved, with an owner and a trigger |

---

# S0 · Frame

> The cheapest place to be wrong. Spend real time here — a Survey built on a
> misframed problem is a well-engineered answer to the wrong question.

## S0.1 The problem, in the customer's words

> Two or three sentences. Whose problem, what it costs them today, why now. If you
> cannot write this without using the name of a technology, the frame is not done.

## S0.2 What "done" looks like

> Observable, from outside the system. "The watch officer sees the alert within 30s
> of the detection" — not "the alert service is deployed."

## S0.3 Explicitly out of scope

> The most valuable list in S0. Everything here is a thing you will otherwise be
> asked for in week six as though it had always been agreed.

- 
- 

## S0.4 Who decides

| Role | Name | Decides |
|---|---|---|
| Problem owner | | Whether the frame is right |
| Criticality class authority | | C1/C2/C3 |
| Technical authority | | Architecture, ADR acceptance |
| Named approvers (spine dagger rows) | | See Decision Spine |

## S0.5 Prior art and autopsies

> What has already been tried here, by us or anyone else, and what happened. A failed
> predecessor is the single richest source of `GR-` rows you will get. If an IG report,
> GAO finding, or postmortem exists, mine it before writing S1.

---

# S1 · Ground

> Constraints that already exist and are not ours to choose. This section is where
> ADR churn is actually prevented — the classic supersession is a decision made in
> ignorance of a constraint that was knowable on day one.
>
> **Test for a real `GR-`:** if the team could vote to change it, it is not Ground.
> It is a `DEC-`. Move it.

| ID | Constraint | Source | Verified how | Binds |
|---|---|---|---|---|
| GR-1 | | | | DEC-n, DEC-n |
| GR-2 | | | | |

**Source** is where it comes from: a contract clause, an ATO boundary, an existing
system's actual behavior, a platform limitation, an org reality, a law. **Verified how**
is the part people skip — *"the vendor's docs say so"* and *"I ran it and watched it
fail"* are different confidence levels, and the difference predicts which ADRs get
torn up later. Mark unverified constraints `assumed` and open an `OPEN-` to close them.

**Trace every load-bearing number to a measurement or an `OPEN-`.** A figure someone
asserted once — a rate, a volume, a latency, a retention window — gets quoted
downstream as though it were measured. A number becomes load-bearing the moment a
*second* record depends on it, and the second use is almost never as careful as the
first: the first was often only ever asserted to support a much weaker claim than the
second one needs. Find every figure that appears in more than one place and say, for
each, whether anyone has measured it.

### Prompts — work these until they stop producing rows

- **Environment.** Classification level, network enclave, air-gap, cloud region and
  authorization boundary, what egress exists.
- **Platform.** What the target platform cannot do. *(Worked example: GCC High Power
  Automate has no Initialize/Set/Append/Increment Variable actions.)*
- **Compliance.** Controls inherited vs. owned, the framework in force, the evidence
  the customer will actually ask for.
- **Existing systems.** What we must integrate with, in the state it is actually in —
  not the state its documentation describes.
- **Data reality.** Volume, shape, quality, ownership, retention obligations, what is
  PII/CUI and who says so.
- **Organization.** Who operates this at 0300. What skills the sustaining team has.
  Conway's Law is a constraint, not an observation.
- **Contract and money.** Period of performance, funding shape, what a CDRL obligates,
  what an option year assumes.
- **Time.** The date that is not moving, and what is tied to it.

---

# S2 · Load

> What the system must carry. Capability statements plus at least one end-to-end
> walkthrough. The walkthrough is not optional at G1 and above — it is the cheapest
> known way to find the interface nobody specified.

## S2.1 Capabilities

| ID | Capability | Actor | Trigger | Success is | Volume/rate | Priority |
|---|---|---|---|---|---|---|
| LD-1 | | | | | | must \| should \| later |

## S2.2 End-to-end walkthroughs

> Narrate one real transaction from the outside world to durable state and back.
> Name every hop. Where you find yourself writing "and then it gets to X somehow,"
> stop — you have found either an `OPEN-` or a `DEC-`. Record it and continue.

**Walkthrough A — {{the normal one}}**

1. 
2. 

**Walkthrough B — {{the one that goes wrong}}**

1. 
2. 

## S2.3 Interfaces

> Every seam where this system meets something it does not control. Each row needs a
> named contract, or an `OPEN-` to produce one. An interface without a contract is the
> most reliable ADR-churn generator in this document.

| ID | Interface | Direction | Contract | Owner | Status |
|---|---|---|---|---|---|
| LD-n | | in \| out \| both | `name.v1` / *none yet* | | specified \| assumed \| OPEN-n |

---

# S3 · Bearings

> What must hold, and what happens when it doesn't. Skipping this section is how a
> system arrives at its first outage having never considered the condition that caused it.

## S3.1 Invariants

> Things that must be true at all times, stated so that a test could check them.
> "Data is secure" is not an invariant. "No record leaves the enclave without a
> release decision recorded in the ledger" is.

| ID | Invariant | Enforced where | Checked how |
|---|---|---|---|
| IV-1 | | | |

## S3.2 Failure modes

> One row per way this breaks. The **Designed response** column is the deliverable —
> a failure mode with no designed response is an outage you have chosen in advance.

| ID | Failure mode | Trigger | Designed response | Never do |
|---|---|---|---|---|
| FM-1 | | | | |

The **Never do** column captures the tempting wrong fix — the thing a future
engineer, or a future agent, will reach for at 0300 under pressure. Write it down
here and it becomes a rule in the handoff package instead of a regression.

## S3.3 What we are deliberately not defending against

> Required at G2 and above. Threats, loads, and failure classes that are out of scope
> by decision rather than by oversight. Each of these is a `DEC-` if anyone could
> reasonably disagree — and at G2 someone will ask, so the row is the answer.

---

# S4 · Spans

> The decision inventory. This is the section that replaces "we'll ADR it as we go,"
> which is the practice that produces the churn.
>
> **Nothing here becomes an ADR until it passes the readiness test.** An ADR written
> against a `BLOCKED` or `PROBE` row is the defect this whole document exists to prevent.

## S4.1 Readiness test

A decision is **READY** only when all four hold:

1. **Two or more real alternatives are named.** Not "X vs. not-X."
2. **The discriminating forces are stated** — the specific `GR-`, `LD-`, `IV-`, or
   `FM-` rows that make one alternative better here. A decision justified only by
   general preference has no forces and will be reopened by the first person with a
   different preference.
3. **The evidence needed to discriminate exists.** If choosing requires a number
   nobody has measured, the decision is not ready; it is a probe.
4. **Every decision it depends on is closed.** Dependency order is recorded in
   `Depends on`. This single check kills the most common supersession cause.

Verdicts:

| Verdict | Meaning | What happens next |
|---|---|---|
| **READY** | All four hold | Write the ADR now. Cite the spec IDs in *Forces*. |
| **BLOCKED** | An upstream `DEC-` or `OPEN-` is unresolved | Record the dependency. **Do not write an ADR.** |
| **PROBE** | Discriminating evidence does not exist | Time-boxed spike with one named question. Decide after. |
| **NOT-A-DECISION** | No real alternative — it is a default | Record it in the spec. **No ADR.** Ceremony dilutes the register. |

**One row, one verdict.** If parts of a row would score differently — a technology
choice that is READY bundled with a threshold that is a PROBE — split it before
judging. A compound row always resolves to its most optimistic half, and that is how a
PROBE ends up recorded as an accepted ADR.

## S4.2 Decision inventory

| ID | Decision | Alternatives | Forces (spec IDs) | Spine row | Door | Depends on | Verdict | ADR |
|---|---|---|---|---|---|---|---|---|
| DEC-1 | | | GR-2, IV-1 | SA-2.2 | one-way | — | READY | ADR-0003 |
| DEC-2 | | | | | two-way | DEC-1 | BLOCKED | — |
| DEC-3 | | | | | one-way | — | PROBE | — |

**Door** is one-way (expensive or impossible to reverse) or two-way. Sort one-way
doors to the top and close them first; a two-way door decided wrongly costs a
refactor, a one-way door decided wrongly costs the program.

**Where a row maps to a spine row, the door is read from the Spine, not authored
here.** The Decision Spine marks its one-way rows in the `One-way` column — 28 of
them at spine 0.8 — and `oneway-closure` already gates on that marking. A `DEC-` row
that calls a decision two-way when the Spine marks its row `Y` is not a judgment
call; it is a contradiction, and the Spine wins. Only a row with no spine mapping
gets a door you decide.

## S4.3 Probes

> Every `PROBE` row gets one here. A probe with no time box is a research project,
> and a probe with more than one question is a project plan.

| ID | For | The one question | Method | Time box | Decides |
|---|---|---|---|---|---|
| PR-1 | DEC-3 | | | 2 days | DEC-3 |

## S4.4 Open questions

| ID | Question | Owner | Blocks | Trigger / needed by |
|---|---|---|---|---|
| OPEN-1 | | | DEC-2 | |

"Unresolved is fine; unrecorded is not." An `OPEN-` with an owner and a date is a
managed risk. The same question in someone's head is the thing that rewrites ADR-0004.

**Sweep the package for TODO, TBD, FIXME, and "we should probably."** Each one is an
open item somebody already recorded without an owner, a trigger, or anything that
notices it — most often parked inside a table cell where it reads as handled.
Promote each to an `OPEN-` row or delete it. Nothing changes but the placement, and
the placement is what makes it get done. A fact already known and already written
down is the cheapest finding in this document and the most embarrassing one to miss,
because nobody had to discover anything.

---

# S5 · Handoff

## S5.1 Derivation map

> Where each part of the Claude Code package comes from. Fill this in *before*
> generating the package — if a cell is empty, the package will contain an invention.

| Handoff artifact | Derived from | Notes |
|---|---|---|
| `README.md` build order | LD priorities, DEC dependency order | |
| `CLAUDE.md` project section | S0.1, S0.2 | |
| `CLAUDE.md` environment constraints | all `GR-` rows marked platform/environment | **verbatim** — this is the section that saves agent hours |
| `CLAUDE.md` Do-NOT list | FM `Never do` column | |
| `AGENTS.md` repo-specific rules | `GR-` rows that bind how we build | only additions to Causeway; nothing relaxes it |
| `SECURITY.md` | `IV-` rows, S3.3, classification `GR-` rows | |
| `docs/CONTRACTS.md` | S2.3 interfaces | |
| `docs/FAILURE-MODES.md` | S3.2 | |
| `decisions/` seed ADRs | S4.2 rows with verdict `READY` **only** | `survey_rows` and `forces` are copied from the row, not authored |
| Fixtures / test data | S2.2 walkthroughs | each walkthrough should be a fixture |
| Definition of green | IV checks + `GR-` verification | |

## S5.2 Premortem

> It is six months from now and the ADR register has been rewritten. Name the ways.
> Then fix what you can here, today, for free. Required count is set by profile.

| # | The rewrite that happened | Which spec row should have caught it | Fixed now? |
|---|---|---|---|
| 1 | | | yes / accepted as `OPEN-n` |
| 2 | | | |
| 3 | | | |

## S5.3 Supersession cause codes

> When an ADR from this build *is* eventually superseded, classify why. This is the
> feedback loop — it converts "we keep churning ADRs" into a defect class with a
> section pointer, and it is the only mechanism that makes the next Survey better
> than this one.

| Code | Cause | Verdict |
|---|---|---|
| **S1** | New information from outside — customer, vendor, statute, threat changed | Healthy. Unavoidable. |
| **S2** | Learned by building — knowable only by trying | Healthy, **if** it was a PROBE. If it wasn't, S4.1 test 3 was skipped. |
| **S3** | A constraint we already had but never surfaced | **Intake defect.** Name the S1 prompt that should have caught it. |
| **S4** | Decided before an upstream decision it depended on | **Intake defect.** S4.1 test 4 was skipped. |
| **S5** | Never actually contested — the ADR was ceremony | **Intake defect.** Should have been NOT-A-DECISION. |

Record the code in the superseding ADR's `supersession_cause` field — Build DNA §8
requires it there, which is what makes the code get assigned while the reason is
still in the room rather than reconstructed at a retro. Review the S3/S4/S5 count at
every retro. A build whose supersessions are all S1/S2 has a working intake; one with
recurring S3s has a specific S1 prompt that the team keeps skipping.

A cause code is a defect class, not an accusation. A team that reads it as blame
stops recording it honestly, and at that point the signal is gone and so is the only
evidence that intake is improving.

---

# Survey exit criteria

> Run this before generating the handoff package, not after.
>
> **Not a Causeway gate.** The gate is the machine-readable contract in `gate/` —
> four profiles, 27 checks, eight verdicts, an external evaluator. This is a
> human-run checklist with no evaluator and no exit code, and it is deliberately
> named apart from the gate so the two are never read as one thing.

- [ ] S0.3 out-of-scope list is non-empty
- [ ] Criticality class declared by a **named** person, not a role
- [ ] Every `GR-` row has a source and a verification state; `assumed` rows have an `OPEN-`
- [ ] Every load-bearing number traces to a measurement or an `OPEN-`
- [ ] At least one end-to-end walkthrough completes without an "and then somehow"
- [ ] Every interface in S2.3 has a named contract or an `OPEN-`
- [ ] Every `IV-` row is stated so a test could check it
- [ ] Every `FM-` row has a designed response
- [ ] S3.3 is complete if the profile is G2 or above
- [ ] Every one-way door in scope appears in S4.2
- [ ] Every `DEC-` row has a verdict; no row is verdict-less
- [ ] **No `DEC-` row is marked READY while anything in its `Depends on` is open**
- [ ] Every `PROBE` has a time box and exactly one question
- [ ] Every `OPEN-` has an owner and a trigger date
- [ ] No TODO, TBD, or FIXME remains in the package that is not an `OPEN-` row
- [ ] Premortem complete to profile depth
- [ ] Derivation map has no empty cells for artifacts being generated

**Outcome:** ☐ Ready to build ☐ Ready with open rows ☐ Not ready

**Conditions (if any):**

> "Ready with open rows" is normal and healthy. It means: generate the package, seed
> only the READY ADRs, and carry the listed `OPEN-` rows into the build as tracked
> work. "Not ready" means the frame or the ground is not solid enough to build on —
> go back to S0/S1 rather than building something you will rewrite.

---

## Amendment log

> The Survey is living until the exit criteria pass, then versioned. Amendments after
> that are cheap and expected — record them so the derivation map stays honest and so
> the handoff package can be regenerated without archaeology.

| Version | Date | Change | Rows touched | Triggered by |
|---|---|---|---|---|
| v0.1 | | Initial survey | — | — |
