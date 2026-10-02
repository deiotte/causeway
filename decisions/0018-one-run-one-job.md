---
adr: "0018"
title: One run per commit, and one job per run
status: Accepted
date: 2026-08-23
spine_rows: [SA-8.3]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

ADR 0010 gave this repository a gate. It was written to answer whether the
standard ties to itself, and it does. Nobody asked what it cost to ask, and the
answer turns out to be roughly six times what the question is worth.

Two independent multipliers, both visible in the run history.

**Every commit on a branch with an open pull request ran the whole gate twice.**
The workflow triggered on `push: branches: ["**"]` *and* on `pull_request`. Those
are different events on the same commit, so GitHub scheduled two complete runs of
every job against an identical tree. Of the twenty distinct commits covered by
the last thirty runs of `standard.yml`, **nine ran twice on the same SHA**: run
pairs 17/18, 22/23, 24/25, 28/29, 31/32, 33/34, 36/37, 38/39 and 41/42. Run 36
and run 37 both failed, on the same commit, for the same reason, nine seconds
apart. The kit is worse in proportion: of nine distinct commits, five ran twice —
runs 1/2, 4/5, 6/7, 9/10 and 12/13.

The second run never once said anything the first had not. It could not: same
commit, same workflow, same runner image.

**Each job pays a whole minute for eleven seconds of work.** GitHub's published
billing model for private repositories rounds each *job* up to the nearest
minute, not each run. This repository ran three jobs; the kit ran four. Run
`32544714689` completed in eleven seconds of wall clock across its three jobs.
Under per-job rounding that commit costs three minutes, and because it was a
merge to `main` it was the cheap case — a commit on a pull request branch cost
six.

The three jobs were never independent. They check out the same tree, install the
same Python, and run scripts from the same `tools/` directory. Splitting them
bought parallelism measured in seconds and multiplied the bill by three.

The trigger duplication is a plain defect and would be worth fixing at any price.
The job split is a trade, and the thing it bought is real: with three jobs, a
failure in `validate.py` still let the sync round-trip report, so one run showed
every broken thing rather than the first broken thing. That property is worth
keeping and does not require separate jobs to keep.

## Decision

Both repositories run **one job, on one run per commit.**

`push` narrows from `["**"]` to `[main]`. Branch work is covered by the
`pull_request` trigger; `main` is covered by `push`. A commit is verified once.

The jobs collapse to one — `The standard holds` here, `The kit holds` in the kit
— and every independent verification step within it carries `if: '!cancelled()'`,
so a failing step no longer prevents the ones after it from reporting. One run
still shows every failure. What no longer happens is paying for three checkouts
to learn it.

One step in each repository stays fail-fast, deliberately. In the kit,
`pip install --require-hashes` is the only genuine prerequisite — it is also the
assertion that `requirements.txt` stayed hashed, and a hash mismatch is not a
result worth burying under seven more failures.

**Branch protection selects required checks by job name, and both names change.**
The ruleset for this repository currently requires `Tie the standard to itself`,
`A synced project passes drift detection` and `Overlays vendor and lock`, as
recorded in ADR 0016's table. Those three names cease to exist when this merges.
The required-checks list must be updated to the single name `The standard holds`,
and the kit's to `The kit holds`. **This ADR replaces the check-name rows of ADR
0016's ruleset table and nothing else** — required approvals stay at zero, the
pull request stays required, force pushes stay blocked, and the reasoning for all
three is untouched.

That update happens in GitHub settings, by a person, and the ordering has teeth:
a pull request opened after this merges but before the ruleset is updated waits
forever on three checks that will never report again.

## Alternatives considered

**Narrow the triggers and keep the jobs split.** Rejected as half a fix. It
removes the 2x and leaves the 3x, and the 3x is the one buying nothing — the jobs
are not independent and their parallelism saves seconds.

**Consolidate the jobs and keep `push: ["**"]`.** Rejected for the same shape of
reason, and it is the worse half to keep: duplicate runs are pure waste, whereas
the job split at least bought failure visibility.

**Keep everything and run less often — `paths-ignore`, or manual dispatch.**
Rejected. It makes the gate conditional on a guess about which files matter, and
this repository's history is a catalogue of checks that were wrong about what
mattered. ADR 0014 exists because nothing enumerated the tree.

**`concurrency` with `cancel-in-progress`.** Considered and kept as a separate
question. It deduplicates *superseded* runs — a second push while the first is
still going — which is a different problem from two events on one commit, and at
eleven-second runs there is rarely anything in flight to cancel.

**Do nothing and buy more minutes.** Rejected on the grounds that the spend is
not buying verification. Forty-seven of the job executions counted above ran
against a commit that had already been verified by an identical job.

## Consequences

A commit on a pull request branch goes from six billed job executions to one here,
and from eight to one in the kit.

**Diagnostic parity is preserved but not identical.** With `if: '!cancelled()'`
every check still reports, so a run shows all failures rather than the first. The
one case that regresses is the kit's `pip install`: if hashed installation breaks,
the Python-dependent checks in that repository do not run at all, where before
`npm ci` and the hygiene checks lived in jobs that would have proceeded. That is
accepted — a broken `requirements.txt` is a stop-everything condition, and it is
named in the workflow rather than left to be discovered.

**Wall clock gets slightly worse.** Three parallel eleven-second jobs become one
serial job of roughly the same total work. On a gate this size the difference is
seconds and nobody is waiting on it. On a gate that grows to minutes, this
decision should be revisited rather than assumed.

**A push directly to `main` still runs the gate; a push to a branch with no open
pull request no longer does.** That is a real reduction in coverage and it is
intentional: an unreviewed branch nobody has proposed merging is not a thing this
repository needs to spend on. The moment a pull request opens, the gate runs.

**The required-checks list is now a thing that can go stale.** ADR 0016 already
recorded that the ruleset lives outside the tree where no assertion in
`validate.py` can reach it. This decision adds a second way for that external
configuration to be wrong — not merely turned off, but pointing at check names
that no longer exist. Nothing inside this repository detects either.

## Evidence

`.github/workflows/standard.yml` — one job, `push` on `main`, `if: '!cancelled()'`
on all eight verification steps.

**Duplicate runs — confirmed by API, 2026-08-23.** `GET /repos/deiotte/causeway-standard/actions/workflows/standard.yml/runs`,
last 30 runs: 20 distinct `head_sha` values, 9 carrying both a `push` and a
`pull_request` run. Same for `kit.yml`: 14 runs, 9 distinct commits, 5
duplicated. The run numbers are listed in Context and can be re-derived from the
same endpoint.

**Per-job rounding — GitHub's published billing rule, not verified here.** The
usage endpoint `GET /actions/runs/{id}/timing` returns `total_ms: 0` for every
job of every run sampled in both repositories, so the billed figure could not be
read from inside. The claim that rounding is per job rather than per run is taken
from GitHub's billing documentation and is the premise of the 3x and 4x
multipliers above. If that premise is wrong, the duplicate-run half of this
decision stands on its own and the job consolidation becomes a wash — it is still
correct, but for tidiness rather than for cost.

This is the second time a cost claim has entered this repository's record. The
first was in ADR 0014, asserted from a remark, and it was false — CI had in fact
run, green, in eleven seconds. It was corrected in `874271c`. The distinction
being drawn here is the lesson from that: what the API says is recorded as
confirmed, what the vendor documents is recorded as a premise, and which is which
is written down.

**The ruleset update is owed and is not verified by this ADR.** Like ADR 0016's
evidence, it can only be confirmed by a person reading Settings → Rules. Until
that happens, this repository's protection selects three checks that no longer
run.
