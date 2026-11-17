# Build DNA — §9 Guidance versus enforcement

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## 9. Guidance versus enforcement

This document does not gate anything. That is deliberate and worth stating
plainly, because a standard that pretends to be a control is worse than one that
knows it isn't.

| Belongs here | Belongs in a gate |
|---|---|
| Judgment, defaults, vocabulary, worked examples | Secrets scanning |
| "Why we do it this way" | SBOM drift |
| Deviation and exception process | Spine row closure and waiver expiry |
| Anything a good engineer should weigh | Named-approver presence |

The gate configuration lives in `gate/gate-configuration.md`. When the two
disagree, the gate is authoritative and this document has a bug.

### Know which gate you are building under, before you write

The same catalog of checks runs at every profile. What changes is whether a
result is skipped, advisory, or blocking — so "does the standard require this"
has no answer until you know the profile, and an agent or engineer who starts
generating before resolving it is guessing at the bar.

Resolve it in this order, and it is a one-minute job:

1. **Read `system.json`** for `tier` and `criticality_class`. Both are in the
   repository precisely so nobody has to ask.
2. **The profile is derived from those two, never declared.** The matrix is in
   `gate/profiles.json` and `skills/decision-spine/reference/gate-profiles.md`.
   A project that writes its own profile into a file has answered a question it
   was not asked; `gate/profiles.json` is authoritative and vendored.
3. **Missing criticality means C1**, the strictest class. The failure mode of
   assuming C3 is a mission-critical system reviewed as a prototype. The failure
   mode of assuming C1 is a slightly longer conversation.

Tier is a catalog fact and criticality is set by whoever owns the consequences
(§1). Neither is a self-assessment, and a project that finds itself arguing its
way down a tier is having the wrong argument in the wrong document.

**And if the fields are not there, step 1 has no answer to read.** That is the
normal case at the start of a build, and it is a different job: you are not
resolving a placement, you are producing one. The procedure is
`skills/decision-spine/reference/placement.md` — four questions about what a
failure costs, five facts that set C1 on their own, the test the catalog applies
for tier, and what the declaration has to contain to count as one. Run it before
the first design decision, because the class is what says how many of them are
owed an ADR.

Note what that file is not: it is not a way to argue a placement down. The
escalators only escalate, the tier test asks who inherits from you and nothing
else, and the whole document routes the *authority* question back to §1. Its
purpose is to stop C1 being reached by silence. A system classified C1 and a
system nobody classified produce the same gate and are not the same system, and
only one of them can tell you why.

The `decision-spine` skill does this resolution as its first step and is the
faster path when one is available. This section exists so the instruction is
also in the file every project imports — a routing step that lives only in a
tool is a routing step that does not happen when the tool is not loaded.
