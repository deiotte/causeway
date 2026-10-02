---
name: survey
description: Run a Causeway Survey — the structured intake that produces a build spec before any ADR is written or any Claude Code handoff package is generated. Use when starting a new project, system, or major feature; when someone says "let's spec this out," "package this for Claude Code," or "write the handoff"; when a design conversation has been running long enough to have real content in it; when an existing build keeps amending or invalidating its ADRs; or when a set of ADRs exists but nothing has been built against them yet. Also use when asked what still needs to be decided before building.
---

# Survey

The Survey is the intake stage that precedes a Causeway build. You survey the
ground before you prepare it.

The problem it solves is specific and measurable: **ADR churn**. Records written,
then amended or invalidated within days. That is almost never a decision-making
failure — it is an intake failure. The decision was recorded before the constraint
that governs it had surfaced, or before the decision it depended on was made.

Your job is not to print the template. Your job is to run the conversation that
fills it, to refuse to write ADRs for decisions that are not ready, and to hold
the exit criteria.

---

## Step 0 — Decide whether to survey at all

A Survey that a project does not need is worse than none: the team learns the
instrument is ceremony and stops believing the next one.

**Survey when:** a new system or service; a major feature that adds interfaces,
data, or a security boundary; anything headed for a Claude Code handoff package;
any build whose ADRs are already churning.

**Do not survey when:** a script, a one-file tool, a bug fix, a spike whose entire
purpose is to answer one question. For these, say so in one line and just help.

If unsure, ask exactly one question: *"Is this getting its own repo?"* If yes, survey.

## Step 0.5 — Pick the mode

Three modes, set by what already exists. Say which one you are in, in one line,
before you start — they do different amounts of work and the user should know which.

| What exists | Mode | Run |
|---|---|---|
| A design conversation, no ADRs | **Full Survey** | S0→S5 in order |
| ADRs written, no code yet | **Readiness audit** | S1 Ground, then S4 scored against the existing ADRs, then S5.2 premortem |
| Code shipped, ADRs churning | **Backfill** | S1 Ground, classify existing supersessions S1–S5, S4 on what is still open |

Skip S0, S2, and S3 in the two retroactive modes. The build already encodes those
answers, right or wrong, and re-deriving them is how a retroactive pass turns into a
redesign nobody asked for.

**Readiness audit is the most common mode and the least obvious one.** A team usually
meets this instrument *after* writing ADRs and *before* building against them, which
is neither of the other two: there is no churn to classify yet, so the backfill path's
"classify the existing churn" step has nothing to operate on. It is also the cheapest
mode and the highest-yield, because everything it finds is still free to fix.

In readiness-audit mode:

- **Score, do not redesign.** Take each accepted ADR as if it were a `DEC-` row
  arriving at intake, apply all four tests, and report a verdict and one action. The
  instrument has no opinion about whether the architecture is good.
- **Expect tests 3 and 4 to be what fails.** The usual finding is an ADR that is
  right about its approach and wrong about its own status, and the usual fix is a
  demotion from `accepted` to `proposed` with a probe attached — not a rewrite.
- **Check every proposed demotion against the build order before you propose it.** If
  the probe that would resolve a row is already a scheduled build step, the demotion
  costs nothing and you must say so explicitly. *"Total added schedule: zero"* is the
  sentence that gets a demotion accepted; without it you are asking someone to accept
  a delay you never actually priced.

## Step 1 — Scope before you open the template

Two facts set the depth. Get them in one question, not two turns.

1. **Criticality class** — C1 / C2 / C3 (spine row SA-1.1)
2. **Causeway tier** — Core / Mission / Operational (spine row SA-1.14)

They are independent axes. Never infer one from the other. Neither is defined here:
`skills/decision-spine/reference/placement.md` is the source, and the two questions
below are its triage shortcut rather than a second definition.

**If the class is not forthcoming, do not stall and do not guess silently.** Ask the
two questions that get there:

> 1. If this is wrong, who is affected? *just me · my team · other teams or customers ·
>    people who can't opt out*
> 2. How much of this could you undo in a week? *all of it · most · some · almost none*

The more demanding answer wins. Propose the class it implies, state the mapping out
loud, and put it to the person who owns the consequences as a one-line ratification:
*"That reads as C2 — you own the consequences, yes or no?"* A class you can get
ratified in one line is worth more than a class you were correct about and never got
declared. If you still cannot get one, assume **C1**, say that you are assuming it,
and continue — and note that C1 is also what Causeway defaults a missing class to, so
an undeclared class is the strictest gate arrived at by nobody's decision rather than
a neutral one.

**When the two questions disagree, or somebody argues the class down, stop shortcutting
and read `skills/decision-spine/reference/placement.md`.** It carries the four
questions the proposal is checked against, the five facts that set C1 regardless of
them, and the tier test — which these two questions do not cover at all, because
reversibility is not what tier measures.

The profile derives from tier × class and sets which sections apply. Read the Depth
table in `templates/survey.md` and **state the depth in one line before starting**, so
the user knows what they are in for:

> *"Mission + C2 → G2. Full Survey: all six sections, S3.3 required, three premortem items."*

## Step 2 — Draft first, then ratify. Never interrogate.

This is the difference between a Survey that gets finished and one that gets
abandoned in section two.

By the time someone asks for a spec, the conversation usually already contains half
of it. **Mine what has been said, draft candidate rows, mark them `proposed`, and
ask the user to correct them.** Correcting a wrong row takes five seconds; answering
an open question takes five minutes and feels like a deposition.

```
GR-3  (proposed)  Target enclave has no outbound egress except the artifact mirror.
                  Source: you said "air-gapped except the Nexus mirror"
                  Verified: assumed — confirm?
```

Rules for the conversation:

- **Batch questions by section.** Four to eight at a time, numbered, so the user can
  answer in one pass. Never one question per turn.
- **Ask what only the human knows.** Constraints, org reality, what the customer
  actually said, what failed last time. Never ask what you could infer or look up.
- **Offer a leaning when asked, labeled as a leaning.** The user ratifies or
  negotiates, which is faster than a menu for anyone who already has a view.
- **Take one section at a time, in order.** Later sections depend on earlier ones —
  that dependency is the whole point of the ordering.
- **Keep the running document visible.** Write the Survey to a file and update it
  as you go. A spec that lives only in chat scrollback is not a spec.

## Step 3 — Work the sections

Use `templates/survey.md` as the structure. Where to actually spend the time:

### S0 Frame — cheap to fix, expensive to get wrong
Push on S0.3 (out of scope). An empty out-of-scope list means the frame is not done.
Push on S0.5 (prior art) — a failed predecessor is the richest source of constraints
available, and if an IG report, GAO finding, or postmortem exists, mine it before S1.

### S1 Ground — this is where the churn is actually prevented
**Spend disproportionate time here.** Walk the prompt list and keep going until it
stops producing rows. The classic supersession is a decision made in ignorance of a
constraint that was knowable on day one.

Apply the test on every candidate row: *if the team could vote to change it, it is
not Ground — it is a `DEC-`.* Move it. This misclassification is common and it
quietly produces fake certainty.

Mark every unverified row `assumed` and open an `OPEN-` against it. "The docs say
so" and "I ran it and watched it fail" are different confidence levels, and the
difference predicts which ADRs get torn up.

**Hunt the numbers that have no owner.** A rate, a volume, a latency, a retention
window asserted once in conversation will be quoted downstream as though somebody
measured it. Trace every load-bearing figure to a measurement or an `OPEN-`. A number
becomes load-bearing the moment a *second* record depends on it, so the specific thing
to search for is a figure appearing in more than one place: the second use is almost
never as careful as the first, and the first was often only ever asserted to support a
much weaker claim than the second one now needs. This is how an unmeasured throughput
number ends up sizing a retention window.

### S2 Load — the walkthrough is the deliverable
Capability tables are easy and low-yield. The end-to-end walkthrough is where the
unspecified interface shows up. When the narration reaches "and then it gets to X
somehow," **stop and record an `OPEN-` or a `DEC-` on the spot**, then continue.
Each walkthrough should survive into the handoff package as a fixture.

### S3 Bearings — make invariants testable
Reject invariants that no test could check. "Data is secure" is not an invariant;
"no record leaves the enclave without a release decision in the ledger" is. If the
user gives you the first kind, ask what would have to be observed for it to be false.

The **Never do** column on failure modes is high-value and almost always skipped:
the tempting wrong fix that someone reaches for at 0300. Captured here, it becomes
a rule in `CLAUDE.md`. Uncaptured, it becomes a regression.

S3.3 — what you are deliberately *not* defending against — is required at G2 and
above, and is the section that separates a G2 Survey from a G1 one. At G2 an assessor
will ask, and the difference between a threat considered and dismissed and one nobody
raised is exactly what they are asking about.

### S4 Spans — hold the readiness test
Enumerate every decision surface first, *then* judge readiness. Judging as you go
biases toward READY because the next section is more interesting than the current one.

Apply all four tests to every row. The two that get skipped:

- **Test 3 (evidence exists).** If choosing requires a number nobody has measured,
  the verdict is PROBE, not READY-with-an-assumption.
- **Test 4 (dependencies closed).** Sort by dependency before assigning verdicts.
  This one check prevents the most common supersession cause in practice.

Be willing to assign **NOT-A-DECISION**. An ADR on an uncontested default dilutes the
register and trains people to skim it.

**Read the door off the Spine.** Where a `DEC-` row maps to a spine row, the
one-way/two-way answer is whatever the Spine's `One-way` column says — it is not
yours or the user's to judge, and `oneway-closure` already gates on that marking. Only
an unmapped row gets a door you decide.

**Watch for compound rows.** If the readiness verdict differs across parts of a single
`DEC-` row — a technology choice that is READY bundled with a threshold that is a PROBE
— it is two rows, not one. Split before assigning a verdict. A compound row always
resolves to its most optimistic half, which is how a PROBE gets recorded as an accepted
ADR. This is common in storage, retention, and algorithm decisions, where the *what*
is settled and the *how much* is not.

**Sweep for TODO, TBD, FIXME, and "we should probably."** Each is an open item somebody
already recorded without an owner, a trigger, or anything that notices it — usually
parked in a table cell where it reads as handled. Promote each to an `OPEN-` row or
delete it. Nothing changes but the placement, and the placement is what makes it get
done. These are the cheapest findings available and the most embarrassing to miss,
because nobody had to discover anything.

### S5 Handoff — fill the derivation map before generating anything
An empty cell in the derivation map means the generated package will contain an
invention. The premortem is not a formality: for each named rewrite, ask whether it
can be prevented *now, for free*, and most of the time one or two can.

## Step 4 — Hold the exit criteria

Run the exit-criteria checklist explicitly and report the outcome. **"Ready with open
rows" is the normal, healthy result** — generate the package, seed only the READY
ADRs, carry the `OPEN-` rows into the build as tracked work.

Do not call this a gate. The gate is the machine-readable contract in `gate/`, with
its own verdicts and exit codes and an evaluator that executes it; this is a
human-run checklist. Two things called a gate in one standard is a vocabulary
collision Causeway has already paid for once.

Only after the exit criteria: generate the Claude Code handoff package from the
derivation map. Seed ADRs **only** from rows with verdict READY.

**A seed ADR's frontmatter is copied, not authored.** `survey_rows` is the `DEC-` row
ID. `forces` is that row's Forces column, verbatim. `door` comes from the Spine row.
`revisit_if` is the condition that would legitimately reopen it. If you find yourself
inventing a force while writing the ADR, the row was not READY and you have just
discovered it the expensive way — go back and fix the verdict.

## Step 5 — Close the loop after the build

When an ADR from a surveyed build is superseded, classify it with a supersession
cause code (S5.3) in the superseding ADR. S1/S2 are healthy. S3, S4, and S5 are
intake defects, and each one points at the specific Survey step that was skipped.

**You are in Step 5 whenever you are writing an ADR whose `supersedes` field is
non-empty.** That is the trigger — not a retro, not a reminder, not this skill being
invoked again months later. The code is assigned at the moment the superseding record
is written, by whoever is writing it, while the reason is still in the room. Build
DNA §8 states the same rule in the process layer, because an agent that never invokes
this skill still writes the ADR.

Name the code plainly and without blame. The count across builds is the only signal
that says whether the intake is actually improving, and a team that reads the codes as
blame stops recording them honestly — at which point the signal is gone.

---

## Hard rules

Enforce these even when the user pushes, which they will, because every one of them
sits between someone and the fun part.

1. **No ADR for a BLOCKED or PROBE row.** This is the rule the whole instrument
   exists to enforce. When asked for one anyway, say what it depends on, offer to
   write the probe or the `OPEN-` instead, and do not write the ADR. An ADR written
   against an open dependency is the defect, not a head start on it.

2. **A constraint the team can vote to change is not a constraint.** It is a
   decision wearing a constraint's clothes, and it produces fake certainty
   everywhere downstream.

3. **IDs are permanent.** Never renumber. A withdrawn row keeps its ID, gets status
   `withdrawn`, and one line saying why. ADRs and handoff artifacts cite these IDs;
   renumbering silently breaks every citation.

4. **Never guess a criticality class.** You may assume C1 as a working default and
   say so. You may not record one. It is declared by the PO, Service Owner, Customer,
   or Sponsor — whoever owns the consequences — by name, not by role. Proposing one
   against `reference/placement.md` is the job; recording one is theirs.

5. **"Not yet" is a legitimate verdict. "Never considered" is not.** A PROBE with a
   time box is a success. A decision nobody surfaced is the failure this prevents.

6. **The Survey absorbs churn; the ADR register does not.** When something changes,
   amend the Survey and let the ADRs be regenerated or superseded deliberately.
   Never patch an ADR to match a changed reality without a superseding record.

7. **Generate the handoff package only after the exit criteria.** Not during, not "to
   get started." The package is derived from the Survey; deriving it from a
   half-Survey is how invented requirements get into `CLAUDE.md` and stay there.

---

## Anti-patterns

- **Dumping the blank template at the user.** The template is your structure, not
  your first message. Someone handed a blank Survey fills in the easy sections and
  abandons S4, which is the only section that prevents the problem.
- **Interrogating instead of drafting.** See Step 2. Twenty open questions in a row
  gets a Survey abandoned; twenty proposed rows to correct gets it finished.
- **Rushing S1 to reach S4.** The decision inventory is more fun. The constraint hunt
  is what makes it correct. Time spent in S1 is the single highest-yield part of this.
- **Letting a decision close on prose.** "Yeah we decided Postgres" leaves the row
  open until an ADR exists. Offer to draft it. (Causeway `AGENTS.md` §8.)
- **One record, two verdicts.** An ADR bundling a settled choice with an unsettled
  number scores as READY on the strength of its settled half, and the unsettled half
  ships as though it were decided. One ADR, one decision.
- **Quoting a number nobody measured.** If a figure is doing work in two records and
  was measured in none, the second record is resting on the first one's confidence.
- **A readiness audit that becomes a redesign.** Score the ADRs, propose demotions,
  price them against the build order, stop. The moment you start re-litigating the
  architecture you have turned a free pass into an argument.
- **Surveying a two-file script.** See Step 0.
- **Treating tier and class as one axis.** The most common conceptual error in this
  model; they are orthogonal.
- **Filling `OPEN-` rows with plausible answers.** A guess recorded as an answer is
  strictly worse than a blank, because nobody goes back to check it.
- **Skipping the premortem because the design feels solid.** The design always feels
  solid at the end of designing it. That feeling is the reason the section exists.

---

## Files

| File | Read when |
|---|---|
| `templates/survey.md` | Always. The structure, the ID scheme, the readiness test, the exit criteria. |
| `templates/adr-template.md` | Writing a seed ADR from a READY row. |
| `skills/decision-spine/SKILL.md` | Mapping `DEC-` rows onto spine rows; reading a row's `One-way` marking; any gate or profile question. |
| `AGENTS.md` | Any question about how ADRs are written, numbered, or superseded. §8 is the seam. |

## Where this sits

The Survey is the **intake artifact**, upstream of everything else in Causeway:

```
Survey  →  ADRs  →  handoff package  →  build
(spec)     (seam)   (CLAUDE/AGENTS/    (Claude Code,
                     SECURITY/docs)     under the standard)
```

The division of labour is exact: **the Survey says whether a spine row is ready to
close, the ADR closes it, and the gate checks it closed.**

`AGENTS.md` is the process layer — how we build. The Decision Spine is the design
layer — what a system must decide. The Survey is what you know *before* you can
answer either honestly, and unlike the other three it produces its artifact before
the repository exists, which is why nothing in the gate can reach it while it is
running. If you find yourself writing build rules, you are in `AGENTS.md`; if you
find yourself enumerating decision surfaces generically rather than for this system,
you are in the Spine.
