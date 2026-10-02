---
adr: "0003"
title: Bind one commit to one prompt, and gate only the part CI can see
status: Accepted
date: 2026-08-08
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

AI writes a large share of what we ship, and §7 already says the standard is
unchanged by that. What §7 did not say is what a commit is supposed to be once
the author is an agent.

The observed failure has two shapes and they are opposites. An agent left to work
produces a run of commits nobody can bisect — three of them are the model finding
its footing and one is the change. A developer moving fast batches six unrelated
prompts into a single commit, and the revert unit becomes six things at once.
Both destroy the same property: the ability to read the history and recover what
a change was trying to do. That property is what makes a revert a decision rather
than a gamble, and it is worth more in agent-built code than in hand-written
code, because there is no author to ask.

This is unambiguously process. It applies to every task, on every system, at
every tier, and it is cheap to keep in always-on context — which is the test
`README.md` states for what belongs in `AGENTS.md` rather than in the spine.

## Decision

**One prompt produces one commit.** Build DNA §7 gains a subsection stating the
rule, its escape hatch, and its enforcement honestly.

1. **The rule.** The unit of work is the prompt; the unit of review and revert is
   the commit; they are the same size. Squash an agent's exploratory commits
   before the PR. Never batch unrelated prompts into one commit.
2. **The escape hatch is written in, not implied.** The rule is suspended for
   spikes and parallel design, and the suspension ends when the branch becomes
   something that will merge. Either the work is rewritten into prompt-sized
   commits before the PR opens, or the spike branch is deleted and the answer is
   rebuilt deliberately.
3. **The exemption is declared** in the PR body or the branch name. An
   undeclared exemption is indistinguishable from the rule being ignored.
4. **The gate does not check commit granularity**, and §7 says so in the text.
   CI cannot see it: one commit from six prompts leaves no trace in the diff.
5. **`tests-with-source` lands instead**, warn-only at every profile — a finding
   when the changed-file set touches source and touches no tests. It is named for
   what it measures. Its promotion to blocking at G2 and G3 is deferred to a
   measured false-positive rate (gate configuration §9 step 8, open item 5).
6. **A version-header correction rides along.** `AGENTS.md` carried "Version:
   1.0" while the repository was at 1.1.0 — ADR 0002 changed §5 without moving
   it. The header now reads 1.2 and states that it tracks `VERSION`, so the
   document of record cannot quietly disagree with the thing projects pin to.

## Alternatives considered

**Put it in the spine instead.** Rejected on the seam test. A spine row asks what
*this system* decided and closes in a per-system ADR; commit granularity is not a
property of a system, it is a property of how we work. Every project would answer
it identically, which is the signature of a process rule wearing a design row's
clothes.

**Skip the escape hatch and write the rule clean.** Rejected because the rule
would be dead within a month. Spikes and parallel design are real work and they
are already a recognized lane — the same reasoning that makes G1 time-boxed
rather than prohibited. A rule with no legitimate exit gets ignored in the case
it does not fit, and the ignoring generalizes.

**Gate commit granularity directly** — one commit per PR, or a commit-message
convention CI can parse. Rejected twice over. It measures nothing: an agent can
emit one commit from six prompts and pass. And it is trivially satisfiable by
squashing everything at the end, which produces exactly the unreviewable
mega-diff the rule exists to prevent. A check that can be satisfied by doing the
wrong thing is worse than no check.

**Make `tests-with-source` blocking now.** Rejected as premature. Its
false-positive rate is unmeasured, and the honest candidates — pure deletions,
dependency bumps, behavior-preserving refactors — are common enough that guessing
wrong teaches people to route around the gate. §4's own design rule is that
blocking behavior escalates with profile; nothing says it has to escalate before
the evidence exists.

**Say nothing and let review catch it.** Rejected as the status quo that produced
the observation. Review catches a bad commit only when a reviewer already knows
what the commit was supposed to be, which is the thing that went missing.

## Consequences

- Agent sessions get slightly more deliberate at the end: someone squashes before
  the PR opens. That is a minute of work against a history that stays bisectable.
- The exemption creates a small, visible category of PRs that declare themselves
  as spikes. If that category grows past a handful, the rule is wrong or the work
  is not what we think it is — either way the declaration is what makes it
  visible.
- `tests-with-source` will fire on legitimate PRs from day one. It is warn-only
  precisely so that this is data rather than an obstacle, and §9 step 8 is where
  the data gets used.
- The standard now states a rule it cannot enforce and says so in the same
  breath. That is §9 working as designed; the alternative — a decorative check
  that appears to enforce it — is the failure mode §9 exists to prevent.
- Standard v1.2.0, gate configuration v0.3.

## Evidence

`AGENTS.md` §7 (*One prompt, one commit*) · `gate/gate-configuration.md` §4
(`tests-with-source`), §9 step 8, §10 item 5 · `gate/profiles.json`
(`tests-with-source`) · `VERSION`.
