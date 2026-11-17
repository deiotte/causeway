---
name: backfill
description: Bring a system that already exists under Causeway's decision record — turn the decisions it has already made (old ADRs, a locked-decisions table, architecture docs, constraints in CLAUDE.md) into Ground rows and closed spine rows, so the gate, impact.sh and doctor can see them. Use when Causeway is adopted after the build started, when doctor or evaluate.py shows most spine rows open on a system that plainly has answers, when every ADR has an empty forces list, or when someone asks why impact.sh finds nothing.
---

# Backfill

Most systems adopt Causeway after they were built. The Survey and the Recon are
intake for work not yet decided; this skill is intake for work already decided.
It does not re-argue anything. It writes down what the system already answers,
cites where the answer came from, and leaves every genuinely open row visibly open.

The measure of a good backfill is that `impact.sh` starts finding things and the
open rows that remain are the real ones.

---

## Step 1 — Read where you are

1. Read `system.json` for `tier` and `criticality_class`. No placement means stop
   and run `skills/decision-spine/reference/placement.md` first: the class decides
   how many rows are owed, and a backfill against a guessed class is wasted.
2. Run `python3 tools/evaluate.py --coverage` (or `bash tools/doctor.sh`) and keep
   the list of open rows. That list is the work.
3. Say in one line what you found: profile, rows in scope, rows closed, how many
   ADRs carry `forces`.

## Step 2 — Inventory what is already decided

Look in every place a decision hides, and list each one with its location:

| Where | What it usually holds |
|---|---|
| `decisions/` and any other ADR register (`docs/adrs/`, a concept-documents folder, an architecture spec) | Argued decisions, often without spine rows or `forces` |
| `CLAUDE.md` "locked decisions", "hard invariants", "rules that do not bend" | Decisions stated as rules, with a one-line why |
| `SECURITY.md`, `docs/THREAT_MODEL.md`, `docs/ARCHITECTURE.md`, `docs/CONTRACTS.md` | Boundaries, key custody, data classification, interfaces |
| The build itself: `Cargo.toml`, `pom.xml`, `package.json`, Dockerfiles, CI | Ecosystem, deployment shape, what actually runs |
| The customer or funding context in the README | Constraints nobody chose |

Do not read code to infer a decision the project never stated. A guess written as
a record is worse than an open row, because it looks closed.

## Step 3 — Write the Ground

Create or extend the project's Survey file (`docs/SURVEY.md`; `impact.sh` finds it
there) with only **S1 · Ground** to start. Each fact nobody on the team could vote
to change becomes a `GR-` row:

- **Source** names the document, clause or system behavior it came from.
- **Verified how** says `assumed` unless someone checked. An assumed row gets an
  `OPEN-` to verify it.
- Use the template's columns (`templates/survey.md` §S1). Leave S2 to S5 for a
  later pass unless the profile's depth table asks for them now.

Typical Ground in a backfill: air-gapped or on-premises target, a funding or IP
boundary, a mandated crypto library or FIPS path, a fixed hardware platform, a
customer's identity provider, a legal retention rule.

## Step 4 — Map each existing decision to its rows

For each decision from Step 2, name the spine rows it answers
(`skills/decision-spine/reference/spine.md`). Then pick the record it needs:

| The existing decision is… | Write |
|---|---|
| Foreclosed by a `GR-` fact (no real alternative existed) | A **coverage ADR** (Build DNA 8.8). One record per foreclosing fact, closing every row that fact answers. |
| Argued, with alternatives, in an existing ADR in `decisions/` | Add `spine_rows` and `forces` to its frontmatter only if it is still `Proposed`. An `Accepted` ADR is immutable: write a short coverage ADR that cites it instead. |
| Argued in a register outside `decisions/` | A coverage ADR in `decisions/` whose body cites the external record by its own ID (`ADR-042`). Build DNA open item 13 tracks reading the external register directly. |
| A one-way row the system answered by default, already in production | A retroactive ADR (`templates/adr-retroactive-template.md`): the as-built answer first, with dates. |
| Not actually decided | Nothing. It stays open, and you say so in Step 6. |

Every ADR you write carries `forces` with the `GR-` IDs it rests on. That is the
whole point: it is what lets `impact.sh GR-n` find the record the day the fact
changes.

Named-approver rows (Build DNA 8.6) still need a named person. Write the role and
leave the name for the approver to confirm in review; do not invent one.

## Step 5 — Keep the batch reviewable

- One pull request per section of the spine (SA-1, SA-2, …) or per foreclosing
  fact, whichever is smaller. A forty-ADR pull request does not get read.
- Each coverage ADR is about four lines of body. If one needs an alternatives
  section, the row was contested: make it a normal ADR or leave it open.
- Add every new ADR to `decisions/README.md` in the same pull request.
- Per Build DNA 8.7, write them `Accepted` with the approver named; the approver's
  merge is the approval.

## Step 6 — Report what is left

End with three numbers and one list: rows closed before, rows closed now, rows in
scope, and the open rows that remain, each with what would close it (a decision
nobody has made, a probe, a named approver). Run `impact.sh --check` and say how
many ADRs it can now see constraints for.

What this skill must not do: close a row by finding a sentence that sounds like an
answer, write a name into `approver` that nobody gave you, or edit the body of an
accepted ADR.
