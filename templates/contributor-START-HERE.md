# Contributing to [CALLSIGN] — start here

<!--
  SEEDED ONCE by tools/sync.sh as CONTRIBUTING.md, then owned by this project.
  Edit freely. Fill every [BRACKET] before you hand this to anyone — an on-ramp
  with placeholders still in it tells a new person they were not expected.

  Audience: someone comfortable with a terminal and git, who will do most of the
  work with an AI coding assistant, and who has never read the Causeway standard.
  Keep it under ~300 lines. It restates the Contributor floor from AGENTS.md in
  the order a new person meets it; it does not replace AGENTS.md, and where the
  two disagree AGENTS.md wins and this file has a bug.

  It lives at CONTRIBUTING.md on purpose: GitHub links that file from every new
  pull request and issue page, so a new contributor finds it without anybody
  having to tell them it exists. ADR 0035.
-->

Welcome. This page is the on-ramp. Read it top to bottom once — about twenty
minutes — and then pick a task from [WHERE TASKS LIVE: ROADMAP.md / the issue
tracker / ask NAME].

It assumes you know a terminal and git, and that an AI assistant will write a lot
of your code. It does **not** assume you know anything about the Causeway
standard this project is built under. You will by the end of the page, as much
as you need to.

**If you do not write software**, you are in the wrong file, and that is fine —
[`START-HERE.md`](START-HERE.md) is yours, and what you know is worth more to
this project than anything on this page.

---

## 1. What [CALLSIGN] is, in plain words

[Two or three short paragraphs. What does it do, for whom, and why does anybody
care? Write it for a smart friend who is not in the field. Then one line on what
it is *not*: not production yet, not for real data, not the final product —
whichever are true.]

## 2. What Causeway is, in one paragraph

This project follows a house standard called **Causeway**. The short version:
important decisions get written down with their reasons, changes arrive with
tests, anything that deviates from the standard says so on purpose, and the
amount of rigor is set by how bad a failure would be — not by how confident the
builder feels. The full text is [`AGENTS.md`](AGENTS.md). You do not need to read
it today. Section 5 below is the part of it you owe as a contributor, in order.

Your AI assistant reads `AGENTS.md` and `CLAUDE.md` automatically. **You** are
the one who has to notice when it drifts from them.

## 3. Words you will see everywhere

| Term | Meaning |
|---|---|
| **ADR** | Architecture Decision Record. A short file in `decisions/` explaining one decision and what else was on the table. Numbered, never edited after acceptance — a later ADR supersedes it instead. |
| **Tier** | Where this system sits in the catalog: `core`, `mission`, or `operational`. A catalog fact, not an opinion. |
| **Criticality class** | How bad a failure is: `C1` (mission failure or a reportable event), `C2` (degrades work), `C3` (an annoyance). Set by whoever owns the consequences. |
| **Gate profile** | `G0`–`G3`. Derived from tier and criticality, never chosen. It decides whether a check is skipped, a warning, or a merge-blocker. |
| **Decision Spine** | The list of design questions a system owes an answer to. Each question is a *row* with an ID like `SA-5.14`. |
| **One-way door** | A decision that is expensive or impossible to reverse. These get closed before production code, not after. |
| **Vendored file** | A file copied in from the standard and pinned in `.causeway-lock`. **Do not edit these.** |
| **Drift** | A vendored file that no longer matches the lock. `tools/check-drift.sh` fails the build on it. |
| **Exceptions register** | The table in `CLAUDE.md` listing every place this project deviates from the standard on purpose, each with its ADR. |
| **Waiver** | A decision deliberately put off, with an expiry date and a named person who accepted the risk. An expired waiver fails the gate. |
| **Field note** | Something a domain expert knows, written down in their words. Lives in `domain/field-notes/`. Treat these as facts your code has to survive. |
| **Open item** | A known gap somebody wrote down rather than hid. Tracked in `decisions/open-items.json`. |
| **Adapter** | The only place vendor SDK calls are allowed. Handler code talks to a canonical interface; the adapter translates. |
| [PROJECT TERM] | [Add this project's own vocabulary here. Every word a new person would have to ask about.] |

## 4. Get it running, step by step

You need [LANGUAGE AND VERSION], [OTHER TOOLS], and git. [Say what you do *not*
need, too — "no Docker, no Node" saves somebody an hour.]

**Step 1 — Clone.**
```bash
git clone [REPO URL]
cd [DIRECTORY]
```

**Step 2 — Set up the environment.**
```bash
[e.g. python3 -m venv .venv && source .venv/bin/activate]
```

**Step 3 — Install dependencies.** These resolve from [WHERE: a lockfile, an
internal mirror]. If this step needs a credential or a VPN, say so here.
```bash
[install command]
```

**Step 4 — Run the tests before you change anything.** This proves your setup
works. The suite makes no network calls (AGENTS.md §6), so it should pass on a
plane.
```bash
[test command]
```
Expected: [N tests pass, and what warnings are normal]. If anything fails
**before you have changed code**, stop and ask — that is a setup problem, not
yours to fix.

**Step 5 — Check the standard has not drifted.**
```bash
bash tools/check-drift.sh
```
Expected: it exits `0`. If it does not, somebody edited a vendored file. Tell
[NAME]; do not "fix" it by editing the file back yourself.

**Step 6 — Run the thing.**
```bash
[run command]
```
[What should you see? Where do you point a browser? What is the five-minute
demo that shows what the project is for?]

## 5. Before your first change: the five things you owe

This is the Contributor floor from `AGENTS.md`, in the order you meet it.

**1. Know which gate you are building under.** Open `system.json` and read two
fields, `tier` and `criticality_class`. Look them up in `gate/profiles.json` to
get the profile. That is the whole job.
- If `criticality_class` is missing, assume **C1** — the strictest.
- If `system.json` does not exist yet, **do not write one.** Placement is a
  decision for whoever owns the consequences, not a field to fill in. Tell
  [NAME], and point them at `skills/decision-spine/reference/placement.md`.

This project today: **tier** [TIER] · **class** [CLASS] · **profile** [G0–G3].

**2. Read the exceptions register** in `CLAUDE.md` before you assume a default.
If something here looks "wrong" against the standard, check that table first —
it may be wrong on purpose, with an ADR saying why. Rediscovering a deliberate
deviation and "fixing" it is the most expensive way to read that table.

**3. One prompt, one commit; tests ship with the behavior.** One request to your
assistant produces one commit you could revert on its own. New or changed
behavior arrives with tests in the same change, including the unhappy paths —
bad input, 401/403, timeouts. These are the two things a reviewer will notice
you skipped. (Exploring? Declare it as a spike in the branch name or PR body,
and rewrite it into clean commits before it merges.)

**4. A contested choice needs an ADR.** If you or your assistant weighed a real
alternative — this library or that one, this data shape or that one — that
weighing is the artifact. Copy `templates/adr-template.md` to `decisions/` with
the next number, fill it in, add a row to `decisions/README.md`, and put all of
it in the same PR as the code.

**5. Do not edit vendored files.** `AGENTS.md`, `skills/`, `gate/`, `rules/`,
`templates/`, and `tools/check-drift.sh` came from the standard and are pinned.
If one of them is wrong, the change goes upstream to the standard, not here.

## 6. The rules you cannot break

The Causeway-wide ones. If a change would break one of these, stop and talk to
[NAME] first.

1. **No secrets in the repository.** Not in code, not in config, not in a test
   fixture. Secrets come from [VAULT / SECRET STORE] at runtime.
2. **Tests make no network calls.** External services are faked behind the
   adapter. A test that needs the internet is testing the internet.
3. **Vendor SDKs only inside adapters.** Never in handler code.
4. **Every new dependency is a decision.** Pin it exactly, justify it in the PR,
   and check it against `rules/dependencies.md`. Ask whether the standard
   library can do it first.
5. **Never skip, loosen, or delete a failing test to get green.** Find out why it
   fails.

The ones specific to this project:

6. [PROJECT RULE — e.g. "annotations are append-only". Link the ADR that made it
   a rule.]
7. [PROJECT RULE]

## 7. Where things live

```
AGENTS.md          the standard (vendored — do not edit)
CLAUDE.md          this project's stack, commands, constraints, exceptions
CONTRIBUTING.md    this file
START-HERE.md      the on-ramp for people who know the work and do not write code
system.json        tier and criticality — the gate is derived from these
decisions/         ADRs, their README index, and open-items.json
domain/field-notes/  what the practitioners know
skills/ gate/ rules/ templates/ tools/   vendored from the standard
[PROJECT DIRECTORIES — one line each: what lives there and where to start reading]
```

**A good way to learn the code:** [pick one user-visible action, find where it
enters the code, and follow it down. Ask your assistant to walk you through each
hop and explain it.]

## 8. How to work a task with an AI assistant

**Step 1 — Pick one task.** Start with one marked [GOOD-FIRST-TASK LABEL]. Tell
[NAME] which one, so two people are not on it.

**Step 2 — Make a branch.**
```bash
git checkout [DEFAULT BRANCH] && git pull
git checkout -b yourname/short-description
```

**Step 3 — Have the assistant read before it writes.** Ask for a plan, not code:

> Read CLAUDE.md, CONTRIBUTING.md, and the files this task touches. Tell me which
> gate profile this project is under, explain the problem back to me, and propose
> a plan. Say whether any part of it needs an ADR. Don't write code yet.

Read the plan. If you do not understand part of it, ask it to explain — that is
the point, not a failure. If the plan adds a dependency, changes a data shape,
touches a vendored file, or picks between real alternatives, check it against
sections 5 and 6 above.

**Step 4 — Test first when you can.** For a bug, ask for a failing test that
reproduces it *before* the fix. See it fail, fix it, see it pass. That is the
strongest evidence you can put in a PR.

**Step 5 — Run everything before you push.**
```bash
[test command]
[lint command]
bash tools/check-drift.sh
```

**Step 6 — Review the diff yourself.** `git diff [DEFAULT BRANCH]` — read every
line. Then ask the assistant *"what could be wrong with this change?"* and *"does
this break anything in CONTRIBUTING.md sections 5 and 6?"* A human owns every
merge, and the name on the PR answers for the code, whoever typed it.

**Step 7 — Open a PR.** The template has a checklist. Fill it in honestly — an
unchecked box with a sentence explaining why is a better PR than a checked box
that is not true. [NAME / TEAM] reviews and merges.

### Tips for working with the assistant here

- **One task per session.** Big mixed PRs are hard to review and impossible to
  revert cleanly.
- **If it proposes a new library,** ask whether the standard library can do it.
- **If it wants to "clean up" unrelated code,** say no. Note it as a task idea.
- **If a test fails and it suggests skipping or loosening the test,** say no.
- **If it learns something about the environment the hard way** — a tool that
  behaves oddly, a platform limit — that belongs in `CLAUDE.md` under
  *Environment constraints*, so the next session does not learn it again.
- **If you are stuck for more than an hour,** ask [NAME]. That is normal.

## 9. Reading list, in order

1. This page.
2. `CLAUDE.md` — the stack, the commands, the constraints, the exceptions.
3. [The one or two ADRs everything else in this project builds on.]
4. [The data contract or schema, if there is one.]
5. The ADRs your task touches. You do not need to read all of them up front.
6. `AGENTS.md` — when you are curious, or when a reviewer points you at a
   section. Not before your first PR.

---

*[Your project's easter egg can live here — AGENTS.md §10 says it has to live
somewhere.]* 🐂
