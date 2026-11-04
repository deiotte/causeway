# RECON — {{PROJECT}}

> **What this is.** The record of a first working session with the person who owns a
> problem, written for *them*, in *their* terms. It answers one question before anyone
> opens a repository: **is this worth building, and what would it take?**
>
> **Where it sits.** Recon comes before the Survey. In road and rail work the
> reconnaissance survey walks the route and decides whether it is worth a detailed
> survey; this is the same step. The Survey asks *what must be decided before we
> build*. The Recon asks *should we start*, and the Survey only runs on a yes.
>
> **The rules that make it work.**
> - **Two pages.** The reader is the person who decides, and they will not read three.
> - **Their words, not ours.** If the short version needs a technology name, rewrite it.
> - **No guessing.** A fact you do not have is an `OPEN-` row with an owner and a date.
> - **Proposed until confirmed.** The problem owner confirms or corrects this record,
>   by name. The probe starts against the confirmed version, never the draft.
>
> Delete any row that does not apply. Replace every `{{prompt}}`. An unfilled
> placeholder in a record sent to a decision-maker tells them it was not written for them.

| | |
|---|---|
| **Recon version** | v0.1 |
| **Session date** | YYYY-MM-DD |
| **Written by** | {{name}} |
| **Problem owner** | {{name, office}} |
| **Status** | Proposed \| Confirmed \| Read out |
| **Confirmed by** | {{name, date}}, *blank until they do* |
| **Clocks** | Sent by {{date}} · confirm by {{date}} · readout by {{date}} |

**Clocks** are your team's, not this standard's. Pick them, write them here, and keep
them. A record with no dates gets confirmed whenever someone remembers to.

---

## The short version

> One or two sentences: what we heard, the way the problem owner would say it. Then one
> sentence on what starts now.

---

## R0 · The decision this supports

> The call the problem owner makes at the readout, in one or two sentences. *"Whether to
> fund building X, and whether tool Y is workable for Z."* If nobody can say what
> decision this record supports, the session found a conversation, not a problem.

**Decided by:** {{every person who must agree, by name and role}}. A role is not a
name, and a team is not a person.

**What the readout can return:** go · go with conditions · reframe · no-go.

---

## R1 · What we heard

**The process today:** {{start trigger}} → {{key steps}} → {{end output}}. Run by
{{team or role}}.

| ID | Where it breaks | How often | What it costs | Source |
|---|---|---|---|---|
| PN-1 | {{where the process stalls, breaks or gets reworked, in plain words}} | {{e.g., 400 requests/month}} | {{e.g., 5 days per request}} | said \| measured \| documented |
| PN-2 | | | | |

**Push for numbers.** "Slow" becomes "5 days per request, 400 a month." A number the
owner could not give stays in `{{brackets}}` and goes on the open-questions list.
**Source** is the part people skip: *said in the room*, *measured*, and *in a report*
are three strengths of claim, and the estimate in R5 will lean on whichever you wrote.

---

## R2 · Constraints

**Hard. Cannot change: law, contract, a mandated system, a fixed date or ceiling.**

| ID | Constraint | Source | Verified how |
|---|---|---|---|
| GR-1 | {{e.g., must use tools already authorized for this data}} | {{contract, policy, statute, the owner}} | {{read it \| saw it \| assumed}} |

The test: *who would have to sign to change it?* If the answer is "us," it is not
hard. Move it down.

**Soft. A preference: "we've always used X."**

| ID | Preference | Would the owner trade it for a better result? |
|---|---|---|
| DEC-1 | | yes \| no \| depends on {{what}} |

A soft constraint is a decision with an incumbent answer, so it gets a `DEC-` ID and
becomes a decision row if this goes to a Survey.

**Tried before, and why it didn't work.** {{the earlier attempt and what killed it,
or "none"}}. A failed predecessor is the richest source of hard constraints you
will get. Ask twice.

**Compliance the future state must keep or add.** These are design inputs, not a
review at the end.

- **Data handling:** {{how sensitive the data is, and whether each planned tool is
  authorized for it}} (spine SA-2.11, SA-5.16)
- **Access:** {{who can see and change what}}
- **Approvals and separation of duties:** {{required sign-offs}}
- **Audit trail:** {{what must be logged, and by whom}}
- **Records retention:** {{the applicable schedule}} (spine SA-9.4)
- **Probe data:** synthetic or sanitized only. No production records, and nothing real
  pasted into a model to see whether the idea has legs. That is a spill whether or
  not the idea ever ships.

---

## R3 · Target outcomes

> What good looks like in six to twelve months. Two to four metrics. Each one traces to
> a pain point; a metric that traces to nothing is a wish.

| ID | Metric | Baseline today | Target | By when | Traces to |
|---|---|---|---|---|---|
| OUT-1 | {{e.g., cycle time per request}} | {{e.g., 5 days}} | {{e.g., 1 day}} | {{date}} | PN-1 |
| OUT-2 | | | | | |

A baseline nobody measured is an `OPEN-` row, not a baseline. A pain point with no
outcome against it is either out of scope, which goes in R4, or forgotten.

---

## R4 · Scope and the probe

**The probe.** What gets built before the readout, to answer the question R0 needs.

| ID | The one question it answers | What the owner will see | Time box | Data |
|---|---|---|---|---|
| PR-1 | {{e.g., can tool Y carry step 3 without the rework in PN-2?}} | {{e.g., a click-through of the flow, start to end}} | {{hours or days}} | synthetic |

A probe answers one question in a fixed time. It serves no real users and touches no
production data. A "prototype" that real people depend on is a production system with
an unflattering label and no one on call, and placement gives that shape a real
answer (`skills/decision-spine/reference/placement.md`). This is not it.

**Out of scope:** {{production deployment, live data connections, authorization
paperwork, anything else agreed out}}.

**Later list:** new asks during the probe go here, not into the probe. A good idea
that shows up in week two is a later-list item, not a scope change.

**First moves:**

| Who | What starts now | What the owner sees |
|---|---|---|
| {{person}} | {{the first concrete action}} | {{output}} |

---

## R5 · The estimate, and what it rests on

> Causeway does not tell you how to estimate. Use your team's method. It requires one
> thing of the result: **every number shows what it rests on.** An estimate is a
> load-bearing number. It will be quoted at the readout, in a budget, and in a schedule
> nobody revisits, and every one of those uses is less careful than the first.

| Line | Value | Range | Rests on | Weakest input |
|---|---|---|---|---|
| Labor to a working solution | {{e.g., 2 people × 10 weeks}} | {{low – high}} | GR-1, PN-1, OPEN-2 | {{e.g., OPEN-2 volume is assumed}} |
| Schedule and milestones | | | | |
| Cost | | | | |
| Staffing model | | | | |

Rules:

- **Every line cites its rows.** A line that rests on nothing on this page rests on
  somebody's memory, and that is the line that gets torn up.
- **Give a range.** A single number is a claim of certainty you do not have yet.
- **Say when a line leans on something unproven.** If a line cites an `assumed` hard
  constraint or an unanswered `OPEN-`, the **Weakest input** column names it. That is
  the line the readout should hear about first.
- **When a cited row changes, re-run the line** and bump the record's version. Nothing
  automates that: `tools/impact.sh` reads ADRs and the Survey, not this record. Search
  this page for the ID that moved.

---

## R6 · Open questions

| ID | Question | Owner | Due | If not answered by then, we proceed on |
|---|---|---|---|---|
| OPEN-1 | {{anything the owner could not answer in the session}} | {{name}} | {{date}} | {{the assumption, stated plainly}} |
| OPEN-2 | {{e.g., confirm the people who decide at the readout}} | | | |

**Past due, the work does not stop.** It proceeds on the stated assumption, the row is
marked `assumed`, and the readout hears about it. An assumed answer may steer the
probe. It may never be marked verified, never be quoted in R5 without saying so, and
never become an ADR. The Survey's first hard rule applies here before the Survey has
even started.

---

## Readout

**Outcome:** ☐ Go ☐ Go with conditions ☐ Reframe ☐ No-go

**Decided by:** {{name, date}}

**Conditions, if any:**

> **Go** starts the Survey (`templates/survey.md`) from this record, not from a blank
> page. Every row keeps its ID: `PN-` and `OUT-` rows feed S0.1 and S0.2, `GR-` rows open
> S1, `DEC-` rows land in S4.2, `OPEN-` rows carry over open, and the probe's answer is
> evidence. Never renumber. The Survey continues the sequence from the highest ID used here.
>
> **Reframe** is a second recon, not a failed one. Version this record and say what moved.
>
> **No-go** is a result. Write down why in one line. The next person who walks this route
> starts from it, the way the Survey's S0.5 starts from prior attempts.

---

## Amendment log

| Version | Date | Change | Rows touched | Triggered by |
|---|---|---|---|---|
| v0.1 | | Initial record | — | — |

<!-- Unit 60460 walked this route first. Leave the gate the way you found it. 🐂 -->
