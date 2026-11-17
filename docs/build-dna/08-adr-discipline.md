# Build DNA — §8 ADR discipline

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## 8. ADR discipline — the seam

This section is where the process layer meets the design layer. Every Decision
Spine row closes here or it does not close.

- Every decision with a real alternative gets an ADR in `decisions/`.
- **A decision is recorded only when it is ready to be recorded.** Where the project
  ran a Survey (`skills/survey/`), only a `DEC-` row with verdict **READY** becomes an
  ADR. `BLOCKED` and `PROBE` rows get their dependency or their probe recorded instead;
  a `NOT-A-DECISION` row gets no argued ADR, because an ADR on an uncontested default
  dilutes the register and teaches people to skim it. Where that row maps to an
  applicable spine row, the spine row still closes — with a coverage ADR, below.
  Readiness is the four-part test in `templates/survey.md` §S4.1, not a feeling about
  whether the conversation is finished.
- **An ADR states the forces that discriminated between its alternatives.** Where a
  Survey exists these are its row IDs, copied into `forces` from the `DEC-` row rather
  than re-derived at writing time — if a force has to be invented to fill the field,
  the row was not READY. An ADR justified only by preference will be reopened by the
  first person with a different preference, and that reopening is indistinguishable
  from churn.
- ADRs are **numbered, immutable, and superseded rather than edited**.
- **A superseding ADR classifies why, in `supersession_cause`.** S1 (outside
  information changed) and S2 (learned by building) are healthy. S3 (a constraint we
  already had and never surfaced), S4 (decided before an upstream decision closed), and
  S5 (never actually contested) are intake defects, and each names the step that was
  skipped. The code is assigned when the superseding record is written, while the
  reason is still in the room — not reconstructed at a retro. The codes are a defect
  class reviewed at retro, never an accusation attached to the ADR: a team that reads
  them as blame stops recording them honestly, and then the only signal that says
  whether intake is improving is gone.
- **A factual error in an accepted ADR is corrected by a later ADR, and the
  corrected one gains `corrected_by` in its frontmatter.** The body is not edited.
  Immutability protects the argument, and an argument is not what a wrong count is;
  what it cannot protect is a reader who has no way to reach the correction.
  Frontmatter is the mutable half by construction — `superseded_by` cannot be known
  when an ADR is written, and neither can this — so the pointer costs nothing the
  rule was defending. `corrects` and `corrected_by` are mutual, and the build checks
  both directions.
- Status: `Proposed | Accepted | Deferred | Waived | Deprecated | Superseded`.
- **Waived is a first-class status** and carries mandatory fields: the spine row
  ID, why not now, risk accepted, expiry date, who accepted it, and the review
  trigger. No open-ended waivers. An expired waiver is a gate failure.
- Eight spine rows require a **named individual** as approver, recorded in the
  ADR: SA-1.8, SA-1.9, SA-2.11, SA-5.7, SA-5.10, SA-5.13, SA-5.16, SA-9.4.
- **Code that encodes a contested choice without an ADR is incomplete.**

### The merge is the approval

Until v3.0.0 an ADR reached `Accepted` in three steps: the author's pull request
landed it as `Proposed`, the approver opened a second pull request editing
`status` and `approver`, and a third moved the register. Causeway's own history is
the evidence: five of the eight commits before v3.0.0 were that bookkeeping (PRs
\#45 and \#46 among them), and every one of them carried less information than the
merge it followed.

**The approver's review and merge of the pull request that carries the ADR is the
approval.** The ADR is written `Accepted`, names the approver, and the register and
open-items index move in the same pull request. Three things make this the stronger
record rather than the weaker one:

- **A name in a file authenticates nothing** — the README has said so since v1. A
  merge by a named account, on a protected branch, is recorded by the platform
  with who and when, which is the evidence the old second pull request was
  pretending to add.
- **The record cannot drift from the code.** One pull request means the decision,
  the code that encodes it and the register entry land or fail together.
- **Holding a decision open is still possible.** Where the approver wants to sit
  on it, the author writes `Proposed` and the acceptance is a later pull request,
  as before. That is the exception, chosen by the approver, not the default.

What does not change: the eight named-approver rows still need a named individual
in `approver`, and the gate's `named-approvers` check reads the frontmatter exactly
as it did. A role is still not a name. ADR 0065.

### Closing a row the Survey found no decision in

Two rules in this standard read as a contradiction, and until now an adopter
had to infer the resolution. The Survey says an uncontested default is
`NOT-A-DECISION` and gets no ADR (`templates/survey.md` §S4.1). The spine says a
row without an ADR is not closed, and `shortform-closure`, `oneway-closure` and
`class-scoped-closure` read exactly that. The ServiceNow overlay fails a
register that skipped its inherited rows. All three are right, because they are
about two different things.

A `NOT-A-DECISION` verdict is a finding about an **argument**: there is no
alternative to weigh, so there is nothing to argue, and an ADR that pretends
otherwise is the S5 ceremony the cause codes exist to catch. A spine row is a
**coverage obligation**: somebody looked, and the record says what they found.
The verdict answers the first question. It never answered the second.

**An applicable spine row the Survey marked `NOT-A-DECISION` closes with a
coverage ADR.** It is a real ADR in `decisions/`, status `Accepted`, the row in
`spine_rows`, and the gate reads it like any other. What makes it a coverage
ADR is what it carries and what it leaves out:

- **The answer the system has.** One sentence.
- **The fact that foreclosed every alternative, in `forces`, by its ID** — a
  `GR-` constraint, a managed policy clause, or the platform row an overlay
  inherits from. If no such fact can be named, the row was contested and the
  verdict was wrong: go back to §S4.1, not forward to a longer ADR.
- **The door**, read off the spine, and **a named individual** where the row is
  one of the eight that require one. Coverage does not waive the name.
- **No alternatives section.** The record's claim is that there were none. Four
  lines is a normal length, and a reviewer should be able to check one in the
  time it takes to read it.

One coverage ADR may close every row its fact forecloses: the five rows an
enclave constraint answers are one record, not five. Rows foreclosed by
different facts get different records — the Survey's *one record, one verdict*
rule, applied here. A coverage ADR cannot close a `BLOCKED` or `PROBE` row, and
it is not a waiver: a waiver says *not now*, a coverage ADR says *there was
nothing to decide*. The Survey's `DEC-` row names it in the ADR column the way
a READY row names its argued one. Supersession is unchanged, and so is
`impact.sh`: when the fact in `forces` changes, the tool lists the coverage ADR
with everything else that rested on it, and a coverage ADR overturned because
an alternative was there all along is an S3.

The ServiceNow overlay has been writing this record since it existed. Its
inherited-row ADRs — "eleven rows, four lines each, written once" — are
coverage ADRs whose foreclosing fact is the platform, and nothing in them
changes.

**Worked example.** A C3 internal tool is surveyed. `GR-4` records that the
organization has exactly one accredited execution fabric and that running
anywhere else needs an authorization the project does not hold. `DEC-5`, *where
does this run?*, maps to SA-4.1, lists no alternatives, and takes the verdict
`NOT-A-DECISION`. SA-4.1 is in the short form, so `shortform-closure` fails the
register at the first gate if nothing closes it. The project writes, abridged:

```
adr: "0007"
title: Run on the accredited fabric, because GR-4 leaves nowhere else
status: Accepted
spine_rows: [SA-4.1]
survey_rows: [DEC-5]
forces: [GR-4]
door: one-way
revisit_if: GR-4 changes — a second fabric is accredited for this data.

Runs on the accredited fabric. GR-4 forecloses every alternative: no
other fabric is accredited for this classification, and the project
holds no authority to accredit one.
```

The gate counts SA-4.1 closed, `impact.sh GR-4` finds the record the day a
second fabric is accredited, and the register has gained one entry a reader can
verify in ten seconds. It has lost nothing, because what `NOT-A-DECISION`
protects the register from is an argument that was never had — not a fact that
was never written down.

### Closing a row that arrived after the system did

The spine gets revised, and a revision can add a row to a system that is already
in production. Where that row is **one-way**, the ADR closing it is a different
document from the one a new system writes, because the door is already shut.

- **State the as-built answer.** What the system has actually been doing, with
  dates — not what you would choose today. A decision made by default is still
  the decision that got made, and the record should say so.
- **Where the as-built answer is an ongoing unrecoverable exposure, the ISSM is
  notified and the ADR records the name and the date.** The disclosure has
  already happened; the only open question is who knows about it. A live
  exposure written down honestly and left sitting in a repository is the failure
  this rule exists to prevent, and it is a blocking gate failure.
- **Going forward is the last section, not the first.** An ADR that opens with
  the corrected design has quietly answered a different question than the one the
  row asked.

`templates/adr-retroactive-template.md` carries the shape. The deadline these
close against is the adoption horizon — design layer, in the spine.

The exceptions register in each project's `CLAUDE.md` is the index into the ADRs
that record deviations from this standard. A deviation nobody can find is a
deviation nobody owns.

### The open-items index

**An ADR that opens or closes an open item records it in the project's open-items
index. The index holds the item's state; the prose entry holds its argument.**

An ADR does not only close a spine row. It leaves things behind — a question it
declined to answer, a guard it deferred, a gap it published under the rule below —
and each of those lands as a numbered item in whatever document the ADR was
amending. That document is the right home for the *argument*. An open item is a
paragraph of reasoning with a number on it, and reasoning does not belong in JSON.

It is the wrong home for the *state*. Items accumulate across several documents,
each list numbered independently, each item closed in place by a later ADR that
says so in its own prose and nowhere else. Nothing counts them. The failure is not
that any one item is wrong — it is that nobody can say how many are open without
reading every register end to end, so the number stated at the front door goes
stale, and the next ADR inherits the stale number and restates it.

That is not hypothetical. Causeway lost one of its own: gate configuration open
item 10 was appended to the end of §11 and stayed there through three ADRs, two of
which amended it in place and one of which described it as sitting in §10. The
register showed nine items. Nothing disagreed, because nothing was counting.

So the two halves are split:

| The index holds | The prose entry holds |
|---|---|
| `status` — `open` or `closed` | Why the item exists |
| The ADR that opened it and the ADR that closed it | What closing it would take |
| The version each of those happened in | What the item was right and wrong about |
| Which register it belongs to, and its number | The resolution, written in when it closes |

Five rules govern it:

- **Numbers stay stable and a closed item keeps its entry.** The index does not
  replace that rule; it is how the rule finally gets checked. A closed item keeps
  its number, its prose entry, and its row in the index.
- **Every register is declared in the index.** A numbered open-item list the index
  does not name is a register nothing counts, which is the state this rule ends.
- **The index is hand-maintained, not generated.** Deriving it would mean parsing
  the prose, and prose that gets parsed starts being written for the parser. The
  index is edited by the commit that edits the entry — same change, same review.
- **An item cites its ADRs by number, and they exist.** `opened_by` and `closed_by`
  name real records in `decisions/`. An item that closed by nothing lapsed rather
  than closed, and telling those apart is most of why this is written down.
- **Every stated count derives from the index.** Wherever a document says how many
  items are open, that number comes from here and a check says so.

#### Relations between items

Counting items is not enough. The registers are separate documents; the questions
in them are not. An item can be a duplicate of one in another register, or already
settled by one, or a finding whose resolution belongs somewhere else entirely.
None of that is a counting error, so a count cannot find it, and none of it is
visible to a reader with one register open — which is every reader.

**An item names its relationship to items in other registers, and the build
enforces what the name promises.**

| Relation | What it promises |
|---|---|
| `duplicate_of` | The same question in another register. Mutual, and both halves carry the same status — you cannot close half a duplicate. |
| `superseded_by` | Another item settled this one's question. When that item closes, this one closes. |
| `upstream_of` | The resolution belongs to another register's item. Targets cross registers and must exist; when one closes, this item is re-read against it. |
| `answered_by` | A document outside this register answered the question this item asks. Names the document and the heading, and both must still be there. |
| `blocked_on` | Keys from a declared vocabulary, so *several items are waiting on the same thing* is a fact somebody can query rather than a pattern somebody noticed. |

Two rules about using them:

- **A finding that belongs upstream names the item it belongs to.** Where no such
  item exists, open one. *The finding belongs upstream* with no target is a finding
  with no owner, and it reads as tracked when it is not — worse than an untracked
  one, which at least looks the way it is.
- **A relation is not a merge.** Two registers may legitimately ask the same
  question at different layers and close it on different arguments. The edge
  records that they are the same question; it does not decide which register owns
  it, and collapsing them into one item would.

`templates/open-items.json` carries the shape. `sync.sh` seeds it once and then it
is the project's file, the way `CLAUDE.md` is.

An open item is a declared gap that outlived the ADR that declared it, which is
the rule immediately below. The index is what keeps it declared.

### Declared gaps

**A requirement that cannot be satisfied is published with its blocker. It is
never omitted.**

This is one rule with four existing implementations, and naming it once is
overdue — each mechanism below was built for its own reason, and nothing said
they were the same idea.

| Where | The mechanism | What it refuses to let you do |
|---|---|---|
| ADRs (§8) | `Waived` status, with expiry, risk accepted, and a named acceptor | Leave a row open by saying nothing about it |
| ADRs (§8) | The retroactive ADR: as-built answer first, corrected design last | Answer the question you wish the row had asked |
| The gate | `unsupported` as a verdict distinct from `pass` and `fail` | Report "could not evaluate" as success |
| Overlays | "Where a check cannot read anything on this platform, say so plainly rather than inventing an artifact" | Manufacture evidence to fill a cell |

The shape is the same every time. A gap that is written down has an owner, a
date, and an argument. A gap that is omitted has none of those, and it does not
stop existing — it stops being *tracked*, which is strictly worse, because the
system now looks complete to everyone who reads it.

Applied to work in flight, this is a rule about what you hand back:

- **Ship the blocker with the deliverable.** A control you could not implement,
  a check you could not make pass, a row you could not close — say which, say
  why, and say what would unblock it. Deliver the rest complete.
- **Name the blocker precisely enough to act on.** "Not feasible" is not a
  blocker. "Requires a key custody decision nobody has made; SA-5.7; blocked on
  a named approver" is.
- **Silence reads as done.** Anyone who omits a gap has made a claim about the
  system whether or not they meant to, and it is the one claim they had no
  evidence for.

The declaration is not the fix and does not pretend to be. It is the difference
between a known gap and an unknown one, and every control regime we build
against — a gate, an ATO, an assessor, an incident review — is built on that
distinction.
