---
adr: "0004"
title: Govern the inference boundary — tool surface and pre-inference data egress
status: Accepted
date: 2026-08-08
spine_rows: [SA-5.15, SA-5.16]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

ADR 0002 established the shape of this argument for package registries: a
third-party input that executes code inside the authorization boundary is an
architectural decision, not a tooling detail. A model provider is the same
species of problem pointed the other way. Nothing executes on our machines;
instead, our data executes on theirs, and the artifact left behind is a log we
cannot read, cannot retain, and cannot purge.

The spine had nothing to say about it. SA-5.2 asks where authorization is
enforced, SA-5.10 draws the authorization boundary, SA-2.12 governs field-level
PII treatment — and a system can close all three, honestly, while shipping a
feature that hands a language model a database session and pastes unredacted
case records into a commercial API. Every existing control points at a caller
that is a human or a service. None of them anticipated a caller whose input
channel is prose that arrived from outside.

Two distinct decision surfaces are hiding in that gap, and conflating them is
how systems get one of the two right and believe they are done.

**Capability.** A tool like `run_sql(query)` gives a model the authority of the
credential behind it, and every prompt reaching the model is an input to that
authority — including text lifted from a user, a document, or an upstream feed.
The alternative is a hand-written tool per task with typed parameters, which
removes the injection class by construction rather than by filtering: there is no
free-text field to smuggle a query through. It costs a tool surface someone
maintains forever, and a question nobody wrote a tool for cannot be answered.
That is a real trade with a real loser, which is what makes it a decision rather
than a best practice.

**Data.** Redaction before the call is not the same control as redaction after
it, and only one of them exists. Once bytes reach a provider's logs, no
downstream control retrieves them, no retention setting in a vendor console
un-sends them, and the incident is a disclosure rather than a bug. This is the
same failure mode as SA-2.11, data residency — which the spine already marks
one-way for exactly this reason.

## Decision

**The inference boundary is an authorization boundary crossing, and both sides of
it are recorded per system.** Spine goes to v0.6 with two new rows in SA-5.

1. **SA-5.15** — *what tool surface does inference get, and is any of it a
   generalized query or execution interface?* Answers: no inference path /
   task-specific tools only / generalized interface plus an owned exception. Not
   one-way, C1–C2, no named approver. Reversible engineering with a real cost on
   both sides, in the §2 owned-deviation shape.
2. **SA-5.16 †** — *what crosses the inference boundary, and what is removed
   before it does?* Answers: no inference path / in-boundary inference only /
   redacted or tokenized pre-call / cleared to send unmodified. **One-way, C1–C3,
   in the short form, named approver.** The approver is the data owner,
   countersigned by the ISSM wherever the answer is anything but "nothing."
3. **`rules/inference.md`** carries the floor for both, path-scoped to tool
   definitions and inference call sites so it costs nothing until someone opens
   one of those files.
4. **The gate needs no new check.** Both rows are closed by the existing
   short-form, one-way-door, class-scoped, and named-approver checks. SA-5.16
   joins `named_approver_rows`; the closure counts move to 23 / 28 / 8.
5. **A count correction rides along**, in the manner of ADR 0002 §3a. The
   reference set claimed eighteen resources against a table holding nineteen
   entries. The table is authoritative, the total is restated from it, and the
   count is now explicitly of entries — some entries carry more than one
   document, which is where the ambiguity started.

**Systems with no LLM path answer `No inference path` and both rows close.** That
is a real closure, not a waiver, and it is the same pattern SA-5.12 uses for a
system with no UI.

## Alternatives considered

**One row instead of two.** Rejected. The two halves have different
reversibility, different scope, and different approvers: capability is
engineering-reversible at C1–C2, egress is irreversible at C1–C3 with a named
human on it. Folding them together forces the merged row to take the stricter
value on every axis, which would put tool-surface design in front of a data owner
and drag a C3 prototype's tool inventory into the short form. ADR 0002 rejected
folding SA-5.14 into SA-5.8 on the same ground — one row, one reversibility
property.

**Put the tool-surface rule in `AGENTS.md`.** Rejected on the seam test. "Use
tiny tools, not generalized SQL" reads like a build rule, but it is a per-system
architecture decision with a trade-off the standard should not make on every
project's behalf. A system doing ad-hoc analytics over a read replica has a
legitimate generalized interface; a system serving external users does not. That
variance is the definition of a spine row.

**Put pre-inference redaction in `AGENTS.md` as a flat prohibition.** Rejected
harder. "Never send PII to a provider" is a rule the standard has no authority to
make — the data owner does, and for public or already-released data the correct
answer is *send it*. A prohibition would also be routed around within a quarter
by the first team whose mission genuinely requires it, which costs the standard
authority on the rules that matter. What the standard can require is that
somebody named answers the question first.

**Widen SA-2.12 instead of adding SA-5.16.** Rejected. SA-2.12 is a data-handling
spec for data at rest and in the application's own flows, correctly marked
not-one-way — you can re-mask a column and re-run a migration. Inference egress
cannot be re-run. Widening SA-2.12 would put an irreversible failure behind a
reversible row's rigor and make the one-way-door list wrong, and that list is the
part of the spine people actually act on. SA-5.16 reads SA-2.12's field-level
table rather than replacing it.

**Leave SA-5.16 out of the short form.** Rejected on the short form's own
selection principle: keep every row where a wrong answer creates a problem
someone outside the delivery team cleans up. A spill is the canonical example.
The prototype case is also where this most often goes wrong — production data
pasted into a commercial model to see whether the idea has legs is a spill
whether or not the idea ships.

**Not one-way, because "the decision is easy to change."** Rejected on the
distinction the column actually encodes. The decision is cheap to revise; the
disclosure is not. SA-2.11 has been marked one-way on precisely that reading
since v0.1, so this is the existing definition applied consistently rather than a
new one. The `How to read the columns` section now names both shapes explicitly
so the next reader does not have to re-derive it.

**Add rows for evaluation, model pinning, and non-determinism too.** Rejected as
premature. Those are real decision surfaces, but we have not built enough
AI-bearing systems to know their answer sets, and a row with a guessed answer set
is worse than no row — it gets closed on prose. Recorded as spine open question 6
for v0.7.

## Consequences

- Every system now owes an inference posture, and most existing ones have an
  answer they never wrote down. For the majority it is `No inference path` and
  the closure is a paragraph. For the rest, SA-5.16 needs a data owner's name,
  and finding that name is the slow part — as intended, and identical to the
  `criticality_class` backfill.
- SA-5.16 is the second consecutive revision to add a short-form row that lands
  on systems which already passed a gate. That makes the unratified spine
  version-drift policy materially worse, and both spine open question 3 and gate
  open item 4 now say so and set v0.7 as a hard deadline rather than a
  restatement.
- Teams building agent features get a defensible reason to say no to a
  general-purpose SQL tool, and a named cost to put opposite it when they say
  yes. The ADR is where that trade gets argued once instead of in every review.
- `rules/inference.md` auto-loads on paths most repositories do not have, so the
  cost to a non-AI project is one vendored file nobody reads.
- The gate's row counts change; no gate code changes. That is the closure
  mechanism working — a new decision surface costs a row and an ADR, not a new
  check.
- Spine v0.6, gate configuration v0.3, standard v1.2.0. Consuming projects pick
  it up by re-syncing.

## Evidence

`skills/decision-spine/reference/spine.md` SA-5.15, SA-5.16, the inference-boundary
note, the one-way list, and the C3 short form · `skills/decision-spine/SKILL.md`
hard rule 2 · `skills/decision-spine/reference/references.md` (OWASP Top 10 for
LLM Applications, NIST AI RMF and its Generative AI Profile, NIST SP 800-122) ·
`rules/inference.md` · `AGENTS.md` §7, §8 · `gate/profiles.json`
(`named_approver_rows`) · `gate/gate-configuration.md` §4, §6 · per-project ADRs
closing SA-5.15 and SA-5.16.
