# Adopting Causeway — and the one thing we are asking for

Causeway has been used by the person who wrote it. That is the weakest evidence a
standard can have, and the standard says so about itself: several of its own open
items cannot close until a project that did **not** write Causeway runs it and
reports what happened.

This page is for that project. It says which kind of adoption you are doing, what
we are asking you to measure, and what you get back.

## First: which kind of use is this?

Two kinds of use look the same from the outside and owe different things.

| | **Trying it** | **Building under it** |
|---|---|---|
| What it is | Reading it, running the install path in a scratch directory, borrowing a rule or a template | A real project vendors Causeway, pins it, and is built and reviewed under it |
| What you owe | Nothing | The four role floors in `AGENTS.md` *Adoption*, starting with the one you hold |
| Pin and drift check | Optional | Required — `.causeway-lock`, and `check-drift.sh` in CI |
| `system.json` with tier and criticality | Optional | Required before the first design decision (`skills/decision-spine/reference/placement.md`) |
| A gate | None | An engine that evaluates `gate/checks.json`, or an honest record that you have none yet |
| Deviations | Yours to make silently | Each one an ADR, indexed in your `CLAUDE.md` exceptions register |
| Can you call it "Causeway-governed" | No | Yes, at the version you pinned |

Both are welcome. Only the second produces the evidence below.

## What we are asking a first adopter to measure

One real project. One quarter. These numbers, as honestly as you can get them.
Every one of them is currently an estimate by the people who wrote the standard.

| Measure | Why it matters | The open item it closes |
|---|---|---|
| **How long the Contributor floor took** — from a developer first opening the seeded `CONTRIBUTING.md` to their first merged change under the standard | The standard claims *an afternoon* | Build DNA 4 |
| **What the Maintainer floor costs per month** — pin upkeep, waiver reviews, closing spine rows | The standard claims *a standing obligation* and gives no size | Build DNA 4 |
| **Field notes written, and how long each took a practitioner** | The standard claims *half an hour per note* | Build DNA 8 |
| **Maintainer time to disposition a note, and how many waited more than two weeks** | The reciprocal obligation is the half most likely to lapse quietly | Build DNA 8, and the age threshold in item 6 |
| **Did your AI agent find and use the skills without being told?** — Survey, Decision Spine, field note | A pointer in an adapter file is not discovery | Build DNA 9 |
| **Supersessions and their cause codes** — every ADR you superseded, and which of S1–S5 it was | The only signal for whether the Survey's intake rules prevent churn | Build DNA 10 |
| **Your placement state over the quarter** — `placement.state` from `tools/doctor.sh --json` at the start and at the end, and every lowering it flagged with how it was resolved | Nothing counts how much of a portfolio runs on the C1 default, or how often a lowering skips its declaration | Gate configuration 13 |
| **What broke** — a rule you could not follow as written, a check that fired wrong, an instruction that assumed something about your environment | Everything else | Whichever item it turns out to be |

You do not need all of it. A report that answers two rows honestly is worth more
than one that answers every row with guesses.

You do not need to name your organization, your customer, or your system. Describe
its shape — tier, criticality class, platform, team size — and that is enough.

## How to start

1. **Install from a release**, following *Try the distribution path* in
   [README.md](README.md). Use `--require-release` for anything you mean to keep.
2. **Run `tools/doctor.sh`** in the project. It lists what the "building under it"
   column above still needs — placement, reviewers, CI, the evaluator record, the
   starter placeholders — each with the file to change and the fix. It changes
   nothing, and a repository setting it cannot read offline is reported as
   unverified, never as done. Run it again whenever you think you are finished.
3. **Read your role's floor** in `AGENTS.md` *Adoption*, and stop there.
4. **Place the system** before the first design decision:
   `skills/decision-spine/reference/placement.md`.
5. **Keep notes as you go.** The numbers above are cheap to record in the moment
   and expensive to reconstruct at the end of a quarter.
6. **Report** with the **Adopter report** issue form — once at the end, or as you
   go. Partial reports are welcome.

## Installing into a project that already has agent instructions

Since 2.4.0, `sync.sh` keeps what a project already wrote for its agents
([ADR 0043](decisions/0043-keep-a-projects-own-agent-instructions.md)):

| File | What sync does when it already exists |
|---|---|
| `AGENTS.md` | Replaces it only if it is Causeway's — listed in the previous `.causeway-lock`, or identical to the standard. Otherwise it **refuses** (exit `9`) and changes nothing. |
| `GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/causeway.mdc` | Keeps your text and adds one marked section between `<!-- causeway:begin … -->` and `<!-- causeway:end -->`. A re-sync rewrites only that section. A symlink to `AGENTS.md` is left alone. |
| `CLAUDE.md` | Never edits it. Warns when it does not import the standard with an `@AGENTS.md` line. |

If sync refuses because of your own `AGENTS.md`:

1. Move it aside: `mv AGENTS.md AGENTS.project.md`
2. Re-run `sync.sh`. It now installs the standard at `AGENTS.md`.
3. In `CLAUDE.md`, import both, the standard first:
   ```
   @AGENTS.md
   @AGENTS.project.md
   ```
4. Tools that read `AGENTS.md` directly (Codex, for example) will now read the
   standard. If they also need your instructions, add a line to them in your own
   part of `GEMINI.md`, or wherever that tool looks.

**Recovering files an older sync overwrote.** Before 2.4.0, sync replaced
`AGENTS.md`, `GEMINI.md`, `.github/copilot-instructions.md` and
`.cursor/rules/causeway.mdc` outright. If your project had its own and they were
committed, git still has them:

1. Find the commit that last held your version, for example
   `git log --oneline -- GEMINI.md`. The commit *before* the sync is the one.
2. Write it beside the current file, not over it:
   `git show <commit>:GEMINI.md > GEMINI.recovered.md`
3. Copy your own text from the recovered file into `GEMINI.md`, *outside* the
   Causeway markers. Do the same for each file. For `AGENTS.md`, use the
   `AGENTS.project.md` steps above instead.
4. Re-run `sync.sh`, and check that each file still holds your text once and the
   Causeway section once. Then delete the `.recovered` files.

Files that were never committed are not recoverable this way.

## Upgrading the starter files you own

`sync.sh` seeds `CLAUDE.md`, `CONTRIBUTING.md`, `START-HERE.md`, the decisions
README, the open-items index, `CODEOWNERS`, the PR template and the field-note form
once, and never touches them again — they are yours. When a later release improves
one of those templates, `tools/upgrade-starters.sh` offers the improvement without
undoing your edits ([ADR 0046](decisions/0046-offer-starter-upgrades-three-ways.md)).
Since 2.6.0, sync records the template each starter was seeded from under
`.causeway/starters/`; commit that directory with the rest of the project.

1. Get the new release, as for any re-sync.
2. From the new release, see what it would change. This writes nothing to the project:
   ```
   ./causeway-<new>/tools/upgrade-starters.sh /path/to/project
   ```
3. Read the report. Each starter is one of:
   - **up-to-date** — nothing changed upstream.
   - **clean** — you never edited it; the new template replaces it.
   - **merge** — you both changed it, in different places; the merge is clean.
   - **conflict** — you both changed the same lines. Never applied.
   - **adopt** — no baseline yet, but your file is exactly the new template.
   - **manual** — no baseline yet (seeded before 2.6.0) and your file differs.
   - **absent** — the project does not have it.
4. Open the `.diff` files in the report directory it names, and check each proposal.
5. Apply the clean, merge and adopt ones:
   ```
   ./causeway-<new>/tools/upgrade-starters.sh /path/to/project --apply
   ```
6. For each **conflict**, open the `.conflict` file in the report directory, copy the
   parts you want into your own file, then record that you have:
   ```
   ./causeway-<new>/tools/upgrade-starters.sh /path/to/project --accept <file>
   ```
   Do the same for each **manual** file, working from its `.diff`. `--accept` changes
   none of your files; it only records the new template as that file's baseline.
7. Run step 2 again. Everything you applied or accepted now reads **up-to-date**.
8. Review the result with `git diff` and commit it, including `.causeway/`.

## What you get back

- **An answer to everything you send**, on the same terms the standard puts on its
  own adopters: each item becomes an ADR, a fix, a change to a rule or template, or
  is closed with a pointer to where it is already handled.
- **Credit.** Where your report decides something, the ADR that decides it says so.
  Name or shape only, your choice.
- **Someone reading closely.** A first adopter's report is the most important
  input this project can receive, and it will be treated that way.

## If you are thinking about it

Open an ordinary issue that says so, or reach the maintainer through their GitHub
profile. A conversation before you start is fine, and it is often where the most
useful findings come from.
