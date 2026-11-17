# Build DNA — Layering, and what you owe by role

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## Layering

Broad to specific. Specific wins, except that managed policy is never overridden.

```
managed policy          non-negotiable org floor (ATO/CSfC, secrets handling)
  └── AGENTS.md         this document — the portable Build DNA core
        └── CLAUDE.md   per project: stack, commands, constraints, exceptions
              └── .claude/rules/*.md   path-scoped, glob-frontmatter, auto-loaded
```

**Managed policy is the organization's, never Causeway's.** The standard cannot
supply it. What a project owes is a *reference* to it in `.causeway/policy.json`:
which policy, which version, who issues it, why it applies, a pinned copy, and the
person who alone can grant an exception — or a recorded reason why none applies.
`skills/decision-spine/reference/managed-policy.md` is the contract, including how to
tell a managed policy from a customer constraint and from a project default. Who would
have to sign to change it is the test. A deviation from Causeway is the project's to
record. An exception to managed policy is not the project's to grant.

Rule of thumb throughout: **eyebrow-raiser → a document. Merge-blocker → a gate.**
Prose here is guidance. Anything that must not be bypassable lives in CI, hooks,
or the managed tier, and this document points at it rather than restating it.

---

## Adoption — what you owe, by role

Vendoring the standard is not adopting it, and adopting it is not reading it end
to end. There are four roles here, and each one has a floor. Nobody should have
to read all of this to do any of it.

Find your role, do that, stop. The next role's obligations are not yours until
you take the next role. Three of the four are a ladder of increasing obligation.
The fourth is beside it, not on it.

### Practitioner — you know the work and you do not write software

Your floor is the project's `START-HERE.md`. You owe this document nothing, and
that is deliberate rather than a kindness: a contract that made subject-matter
expertise pass a reading test would collect less of it, from fewer people, later.

You are here because a standard is only as good as the facts its decisions are
made against, and those facts do not live with the people writing the decisions.
The most expensive knowledge on any project is what goes wrong in the field, what
the written rule means once it meets practice, and which two cases look identical
and are not. None of that is derivable from the code by anyone, at any level of
skill.

What you produce is a **field note**: one thing you know, in your language, in the
shape `templates/field-note.md` gives it. `skills/field-note/` governs how a note
is taken and how it is promoted. Two rules are yours:

1. **One note, one thing.** A note carrying several ideas gets read as none.
2. **Label how sure you are.** `seen-it`, `fairly-sure`, and `suspect` are all
   useful and they are not the same claim. Recording them as the same thing is
   the one move here that does downstream damage.

You do not write ADRs, close spine rows, or read §2 through §9. A note becomes an
ADR by a maintainer's hand, and the ADR names you.

**This role has a reciprocal obligation, and it belongs to whoever owns the
repository.** Every field note reaches one of four dispositions — an ADR, a test,
a `CLAUDE.md` constraint, or closed against the place it is already handled — and
its author is told which. Closed is a real outcome and still names where, because
the author is the one person qualified to confirm that the existing handling is
right. A register nobody answers teaches the people who filled it to stop filling
it, and it teaches them faster than any other failure in this document.

### Reader — you are changing nothing yet

Read the project's `CLAUDE.md`. That is the whole obligation.

It imports this document, names the stack and the commands, carries the
environment constraints that will otherwise waste an afternoon, and holds the
exceptions register. If something here contradicts it, the project file wins —
that is what the layering diagram means — and the contradiction should already
have an ADR behind it in `decisions/`.

You do not need the spine, the gate configuration, or this document's §2 through
§8 to read code or run the thing.

### Contributor — you are about to change code

Everything above, plus five things, in this order:

1. **Know which gate you are building under.** Tier and criticality are in
   `system.json`; the profile is derived from them and never declared. See §9.
   A G3 system and a G0 system are the same catalog of checks and a different
   answer to *does this block*.
2. **Read the exceptions register before you assume a default.** A project that
   deviates has already written down why. Rediscovering the deviation and
   "fixing" it is the most expensive way to read that table.
3. **One prompt, one commit** (§7), and **tests ship with the behavior** (§6).
   These are the two rules a reviewer will notice you skipped.
4. **A contested choice needs an ADR** (§8). If you found yourself weighing a
   real alternative, that weighing is the artifact, not the code that came out
   of it.
5. **Do not edit vendored files.** The standard lives in your repository as a
   pinned copy and `check-drift.sh` fails the build if it moved. That friction
   is deliberate (§3). Changes go upstream.

You are not expected to close spine rows. That is the maintainer's ledger.

### Maintainer — you own the repository's adoption

Everything above, plus the ledger:

- **Keep the pin current.** Re-sync when the standard moves; `standard-currency`
  measures your copy against `RELEASED`, not against the distance in versions.
  A system that genuinely cannot re-sync takes a dated gate exclusion and says
  why.
- **Close the register, not the easy rows.** One-way doors close before
  production code. Rows added after your system shipped close against the
  adoption horizon, retroactively and honestly (§8).
- **Waivers expire.** An expired waiver is a gate failure, which is the point.
  Diary the review trigger; do not discover it at a gate.
- **Name the approvers.** Eight rows require a named individual (§8). A role is
  not a name and a team is not a person.
- **Own the deviations.** Every row in the exceptions register points at an ADR,
  and the ADR says what would have to change for the deviation to end.

### What this contract is not

It is not a maturity model and there is no score. A project with one deviation
it owns is in better shape than a project with none it can find.

It is also not a promise that adoption is free. The honest cost of the
Contributor floor is an afternoon; the Maintainer floor is a standing
obligation. Anyone told otherwise will discover the difference at a gate, and
will be right to be annoyed about it.

The Practitioner floor is the one that looks free and is not, and the cost has
moved rather than disappeared. A practitioner spends half an hour per note. The
maintainer inherits a disposition for every one of them, and that is a standing
obligation of the same kind as the ledger — taken on deliberately, because the
alternative is a suggestion box, and a suggestion box is how an organization
discovers two years late that it was told.
