---
adr: "0045"
title: Diagnose adoption without evaluating it — a read-only doctor every project gets
status: Accepted
date: 2026-10-08
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: An adopter reports a finding doctor got wrong in either direction — incomplete
  on something done, or ok on something missing — or asks for doctor's result to block a
  merge. The first is a bug; the second is the warn-cycle evidence this ADR declined to
  invent, and the decision to block belongs to a gate check, not here.
approver:
  name: Karl Deiotte
  role: Maintainer
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

A successful sync and a clean drift check prove the standard is present and unedited.
They say nothing about whether a project is ready to build under it. Issue #12
reproduced the gap: a disposable sync passed `check-drift.sh` with no `system.json`,
`@ORG/TEAM` placeholders in `CODEOWNERS`, and an existing `CLAUDE.md` that never
imported the standard. Every one of those is something ADOPTING.md's "building under
it" column requires, and the only way to find them was to read that column, the
contributor guide and the placement procedure and check by hand.

`sync.sh` cannot do these things for a project. Placement is decided by whoever owns
the consequences; reviewers, CI and the evaluator are the project's choices. What a
tool can do is say which of them are still missing, precisely enough to act on.

The gate is a separate thing. An external evaluator reads `gate/checks.json` and
produces a verdict. A diagnostic that looked like a verdict would be read as one.

## Forces

- **"Installed" is being read as "adopted."** The drift check is the only thing a
  consumer runs, and it is green on a project that has adopted nothing.
- **A finding has to be actionable.** "Not ready" is not a finding. The file, the
  reason it matters and the fix are.
- **Some of it cannot be checked from files.** Branch protection and required checks
  are repository settings. A tool that reported them as fine because it could not see
  them would be the "check that can only pass" this repository keeps removing.
- **Placement must not be defaulted into existence.** A tool that offered a tier or a
  class to clear its own finding would be the quickest route to a C3 nobody declared.
- **New obligations need a warn cycle** (Build DNA open item 10, gate configuration).
  Nothing here may block a merge on its first release.
- **The consumer's machine may be offline,** and may lack python3.

## Decision

**`tools/doctor.sh`** is vendored into every project, checksummed in the lock and
covered by the bundle digest, like `check-drift.sh`. It is read-only and offline, and it
always exits `0`; only a usage error exits `1`.

Each finding has an id, a status, a subject (the file or setting), why it matters, and
a remedy:

- `ok` — checked here, and it holds.
- `incomplete` — checked here, and something is missing.
- `unverified` — cannot be checked from the files here. Never counted as passing.

| Area | What doctor checks |
|---|---|
| Install | `.causeway-lock` exists; `check-drift.sh` passes; the lock names a release (`tag=` and a `release_proof` other than `none`) |
| Placement | `system.json` exists and is JSON; `tier` is operational, mission or core; `criticality_class` is C1–C3; `criticality_authority` has a name, role and ISO date. The derived profile is reported, labelled derived. A missing class is incomplete, because the gate's C1 is a default, not a declaration. Without python3, placement is `unverified`. |
| Instructions | `CLAUDE.md` imports `@AGENTS.md` (or links to it); the Gemini, Copilot and Cursor files point at `AGENTS.md`. A reference being present is all that is claimed. |
| Starters | `CLAUDE.md`, `CONTRIBUTING.md`, `START-HERE.md` and the PR template carry no `[ALL-CAPS]` placeholders; `open-items.json` no longer holds the template's example item |
| Reviewers | `CODEOWNERS` exists and names no `@ORG/` team. Whether code-owner review is required: `unverified`. |
| CI | A CI file in a known location runs `check-drift.sh`. Whether that check is required: `unverified`. |
| Evaluator | `CLAUDE.md` has a `**Gate evaluator:**` line that is not the placeholder |

The summary keeps four states apart: **installed**, **integrity** (verified, failed or
unable), **adoption** (incomplete, complete-except-unverified, or not-installed) and
**evaluated**, which is always "not determined by doctor". `--json` prints the same
findings as a `causeway-doctor-v1` document.

**`templates/project-CLAUDE.md`** gains a `Gate evaluator` line in its placement block.
ADOPTING.md already asks for "an engine that evaluates `gate/checks.json`, or an honest
record that you have none yet"; until now the record had no place to live. Existing
projects add the line when doctor asks; nothing else reads it.

`sync.sh` ends by pointing at doctor, and ADOPTING.md's *How to start* runs it as step 2.

**`tools/test-doctor.sh`** runs in standard CI and in the release gate. A fresh sync must
be incomplete on exactly ten things. A project installed from a signed release and
configured by hand must be incomplete on none, with both repository settings
unverified. Then there is one case per kind of finding, every run must leave the project
byte-identical, and the script must call nothing that reaches the network.

## Alternatives considered

- **Make it a gate check.** It would block on its first release, with no warn cycle and
  no evidence about false positives. Adoption is also not a property of a commit the way
  a gate check is. If adopters want it to block, they will say so, and the revisit
  trigger is where that lands.
- **Query GitHub for branch protection.** It needs a token and a network, and it covers
  only one host. `unverified` with the manual check is honest everywhere; an opt-in
  remote mode can come later if adopters ask.
- **Fill in defaults.** Offering `"tier": "operational"` to clear a finding is the
  failure the placement procedure exists to prevent.
- **Write it in Python.** Cleaner, and it would make python3 a prerequisite for the
  whole diagnosis. As written, only the `system.json` read needs it, and its absence is
  reported as `unverified`.
- **Add a `system.json` field for the evaluator.** That is a schema change to a file the
  gate reads, which is a gate configuration decision. A line in `CLAUDE.md` is where the
  project already records the rest of its placement.

## Consequences

The bundle grows from 29 to 30 files and the digest moves. The README's statements of
both had been stale since v2.3.1 and are corrected here, along with its drift-check
example (26 of 28, now 28 of 30).

A project that runs doctor learns, in one place, what ADOPTING.md asks of it. A
"complete" result means only that everything doctor can see from files holds. The
unverified settings still need a person to look, and the gate still needs an evaluator.

The placeholder check is a heuristic: an `[ALL-CAPS]` token. A project that writes
`[NOTE]` in its own prose will see a finding it can ignore, and mixed-case template
prompts such as `[One or two sentences…]` are not caught. Both are tolerable for an
advisory tool, and both are the kind of report the revisit trigger asks for.

## Revisit if

See the frontmatter.

## Evidence

- `tools/test-doctor.sh`: 26 passed. On a fresh sync the incomplete set is exactly
  `ci.drift gate.evaluator install.release placement.system_json reviewers.codeowners`
  plus the four starter files and `open-items.json`.
- A fresh sync into an empty directory: drift verified, adoption incomplete — 6 ok, 10
  incomplete, 2 unverified. This is issue #12's reproduction, now visible.
- `validate.py`, `build-bundle.sh --check`, `render-adapters.sh`, `test-sync.sh`,
  `test-release-archive.sh --throwaway` and `test-publish-release.sh` pass with doctor
  vendored and archived.
