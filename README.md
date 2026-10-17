# Causeway

**Build software whose constraints and reasoning survive the next change.**

Causeway is a repository-based engineering standard for people who build software with humans and AI coding agents. It gives a project a durable record of what must be true, why important choices were made, what would justify changing them, and what evidence a release owes.

Working code leaves questions unanswered. Can the data leave this environment? Why is this a monolith? Who accepted this risk? What else changes if the customer changes that requirement? A new contributor can read the code and still have none of those answers. A new AI session can confidently undo a choice whose reason lived only in an old chat.

Causeway puts those answers beside the code, links them, and defines checks that a separate evaluator can apply. You do more explicit thinking and recordkeeping up front so future work has something reliable to build on.

**Status:** the standard, installer, diagnostics, change-impact tool, and conformance fixtures are implemented. This repository does not ship the product gate evaluator. Reduced rework, faster delivery, and successful independent adoption remain unmeasured.

## Why develop this way?

Because generating another implementation is often easier than recovering the conditions that made the existing implementation appropriate.

Causeway targets recurring sources of avoidable rework:

| What goes wrong | What Causeway adds | What you can inspect later |
|---|---|---|
| An agent builds against an assumption nobody confirmed | Structured intake separates constraints, assumptions, open questions, and decisions needing an experiment | The source of a constraint and the unresolved work dependent on it |
| A later contributor reverses a deliberate design choice | Architectural decision records (ADRs) preserve alternatives, deciding constraints, and revisit conditions | Why the choice won here, and what would make it stop being appropriate |
| A changed requirement has consequences nobody can enumerate | Stable constraint IDs link to decisions; `impact.sh` follows the recorded relationships | A review list with direct, indirect, and uncertain links |
| A team remembers the happy path and misses consequential obligations | A scoped decision inventory covers architecture, data, security, delivery, and operations | Which applicable decisions have records, which are open, and which have dated waivers |
| “CI is green” conceals missing evaluation | A gate contract specifies check inputs, verdicts, blocking behavior, and evidence receipts | What was evaluated, what failed, and what could not be evaluated—when a conforming engine is connected |
| Field experience never reaches the design | Field notes carry ownership and a recorded disposition | Who owes an answer and where the knowledge landed |

These are mechanisms and intended benefits. Their presence does not establish that a team saves time overall. The records must be maintained, the references must be meaningful, and consequential controls must be enforced outside agent instructions.

## A change that shows the point

A team builds a service that must run inside an on-premises enclave. That constraint is recorded as `GR-1`. Hosting and secrets decisions cite it; the logging decision depends on the hosting decision. A separate retention decision rests on a records schedule.

Later, the customer permits an approved cloud region. Before asking an agent to migrate the service, the team runs:

```bash
bash tools/impact.sh GR-1
```

Causeway follows the recorded links and identifies decisions to re-read, including their reasons and revisit conditions. It distinguishes a direct citation from a dependent decision and from a mention found only in prose. The retention decision stays out of the result when it has no recorded connection to `GR-1`.

This behavior is exercised in [`tools/test-impact.sh`](https://github.com/deiotte/causeway/blob/main/tools/test-impact.sh): its synthetic example reaches hosting, secrets, logging, backups, and a superseded cache decision while leaving the unrelated retention decision out. The review reproduced all 23 test assertions.

The tool does not discover unrecorded dependencies, inspect the implementation for every consequence, approve cloud use, or rewrite the architecture. It produces a defensible starting point for human review. An ADR without useful links remains a blind spot.

The same record helps before a change: the next coding session can read the project constraints and accepted decisions instead of reconstructing them from conversation history. Instructions guide that session; they do not guarantee it follows them.

## What the workflow asks you to do

1. **Surface the facts before choosing a design.** The Survey records purpose, boundaries, workload, invariants, failure responses, and unknowns. Decisions become `READY`, `BLOCKED`, `PROBE`, or `NOT-A-DECISION`. A missing measurement can become a bounded experiment instead of an invented certainty.
2. **Establish what this system owes.** Its architectural role and failure consequences determine the applicable decision scope and gate profile. A person with authority declares the placement; the delivery team does not simply select an easier gate.
3. **Record important choices and their reasons.** ADRs identify alternatives, the constraints that distinguished them, consequences, evidence, and conditions for reconsideration. Applicable Decision Spine rows need ADR closure; waivers name an owner and expiry.
4. **Build with shared instructions and reviewable changes.** The standard provides engineering defaults. Project files hold the actual stack, commands, constraints, and owned exceptions. Tests and review establish behavior; prose instructions alone do not.
5. **Evaluate the product and keep the evidence.** A separate engine consumes the gate contract and available product inputs. People retain design, risk-acceptance, and release authority.
6. **Keep the record useful as reality changes.** Revisit affected decisions, disposition field notes, review waivers, and deliberately update the pinned standard.

This fits inside an existing development process. An ADR can explain a Scrum increment's architectural choice; CI can enforce a check during a pull request; a field note can inform the backlog. Causeway adds a common record and contract across those activities.

## When the overhead earns consideration

Causeway is most relevant when a project will outlive its current conversation or builders, has constraints that are easy to violate silently, or must explain consequential choices to another party. Examples include software handed between coding agents, systems delivered into restricted environments, and projects where data handling or operational failure matters.

An established team already maintaining equivalent decisions, instructions, evidence, and enforcement should compare Causeway's additional value against migration and duplicate upkeep. Existing engineering practice can already provide these capabilities; Causeway packages one particular approach.

A disposable script, a small bug fix, or an exploratory spike usually needs less process. The Survey explicitly excludes those cases. You can borrow a rule or template without claiming full adoption.

**The cost is real.** Maintainers own placement, decision coverage, exceptions, waivers, pin updates, field-note answers, and evaluator integration. The standard estimates an afternoon for contributor onboarding and half an hour per field note; those are estimates awaiting outside-adopter measurements. Maintainer workload has no established monthly figure. The C3 short form still scopes 23 decision rows; C2 scopes 89 and C1 scopes 94. Those are coverage rows, not measured hours or necessarily separate ADR files.

Causeway also has architectural opinions: services by default, vendor adapters, and a preference for avoiding npm where the choice is open. A modular monolith is a documented example of an owned deviation. Adopting the standard means accepting or explicitly addressing its defaults. Organizational policy takes precedence, and only its actual authority can grant an exception to it.

## Try the shipped tools on Linux

This example installs the published **v2.10.0** archive into an empty, disposable project. Acquisition needs internet access; installation and the diagnostics run offline. Use Bash, Python 3, GNU command-line utilities, tar, curl, and OpenSSH with signing support.

```bash
mkdir causeway-trial
cd causeway-trial

curl -fLO https://github.com/deiotte/causeway/releases/download/v2.10.0/causeway-2.10.0.tar.gz
curl -fLO https://github.com/deiotte/causeway/releases/download/v2.10.0/causeway-2.10.0.tar.gz.sha256
sha256sum -c causeway-2.10.0.tar.gz.sha256
tar -xzf causeway-2.10.0.tar.gz

mkdir project
bash causeway-2.10.0/tools/sync.sh "$PWD/project" --require-release
cd project
bash tools/check-drift.sh
bash tools/verify-release.sh
bash tools/doctor.sh --json
```

The review downloaded and exercised this release. The checksum and signature verified; the drift check verified 32 members of what was then a 34-file bundle, with the two optional ServiceNow files absent (the 39-file consumer bundle at this release adds the setup tool's five files, which that review predates). Doctor reported:

```json
{
  "installed": true,
  "integrity": "verified",
  "adoption": "incomplete",
  "evaluated": "not-determined-by-doctor"
}
```

These are distinct states. You have installed a standard; you have not supplied your project's constraints, decisions, reviewers, policy reference, evaluator, or merge enforcement. Doctor lists missing setup and remedies. It is advisory and exits zero even with findings; it is not a CI pass/fail gate.

The signature verifies against the bundled public key. Establish trust in that key independently if the delivery channel is untrusted. The checksum detects a mismatch with its sidecar; the sidecar alone does not authenticate the publisher.

### Exercise the decision-impact example

The source repository carries the fuller synthetic example described above:

```bash
git clone --branch v2.10.0 --depth 1 https://github.com/deiotte/causeway.git causeway-source
cd causeway-source
bash tools/test-impact.sh
```

Expected: **23 passed, 0 failed**, covering direct and dependent links, uncertain prose references, unrelated decisions, supersession, corrections, and broken references. This tests the instrument on synthetic records. It does not measure a real project's avoided rework.

In a project with its own Survey and ADRs, `bash tools/impact.sh GR-1` lists recorded impacts and `bash tools/impact.sh --check` reports broken references and accepted ADRs without structured links. Both are advisory; findings do not produce a failing exit status. Use your project's actual constraint ID.

## Adopt deliberately

Trying the tools or borrowing a template creates no adoption obligation. Building under Causeway requires maintaining the pin, declaring placement, filling the project-owned starters, recording decisions and exceptions, and integrating evaluation—or explicitly recording that no evaluator is connected yet. Record absence honestly; that does not satisfy a required check.

Start with one real project and an owner willing to maintain its record. Read the role-specific floor in [`AGENTS.md`](https://github.com/deiotte/causeway/blob/main/AGENTS.md), then follow [`ADOPTING.md`](https://github.com/deiotte/causeway/blob/main/ADOPTING.md). Practitioners contribute field knowledge; contributors change code; maintainers own adoption. Everyone does not need to read everything.

For an existing repository, review the instruction-file integration procedure before installation. Sync refuses to overwrite an unrelated `AGENTS.md`, preserves an existing `CLAUDE.md`, and manages marked sections in the Gemini, Copilot, and Cursor adapters. Project-owned starters are seeded once; `upgrade-starters.sh` offers later template changes through comparison and three-way merging. Conflicts require review.

Put `check-drift.sh` in CI, connect the chosen evaluator, and configure the actual repository's required checks and review policy. A file naming reviewers does not enable branch protection. Neither the installer nor doctor configures it for you.

Measure the trial: onboarding effort, monthly upkeep, a decision the intake changed, a later requirement change, false findings, and whether another contributor can explain the design without reconstructing old chats. [`ADOPTING.md`](https://github.com/deiotte/causeway/blob/main/ADOPTING.md) defines the requested outside-adopter measures.

## What ships, and where its authority stops

| Area | Implemented here | Boundary |
|---|---|---|
| Intake and design | Survey, 94-row Decision Spine, ADR and waiver templates | Humans and agents apply the methods; semantic correctness is not automatically established |
| Shared engineering instructions | Build DNA, topic rules, coding-tool pointers | Instructions cannot enforce agent behavior or approve a release |
| Distribution | Manifest, pinning, drift detection, signed-release verification, installer, starter upgrades | Integrity checks cover specified surfaces; handled rollback does not establish crash-atomic installation |
| Ongoing maintenance | Adoption doctor, constraint-impact reports, field-note queue | Advisory reports depend on the records supplied; no automatic disposition or design change |
| Product evaluation | 27 check definitions, 14 input classes, four profiles, eight verdicts, receipt contract | The executable evaluator and evidence infrastructure belong elsewhere |
| Evaluator conformance | 9 fixtures over 5 checks | They do not establish compatibility across all 27 checks |
| ServiceNow | Optional responsibility/evidence mapping and JSON projection; overlay 1.14 | No ServiceNow connector, ATF runner, Instance Scan collector, or complete evidence-to-receipt integration |

Profiles derive from architectural tier and criticality, rather than being selected independently. The current Decision Spine is 0.8 and gate configuration is 0.8. Required checks that cannot execute must not be represented as success. `tests-with-source` remains advisory at every profile.

Named approvers are required records on eight decision rows. A person's name in a file does not authenticate approval. An evidence reference does not establish the evidence is adequate. A green standard-validation run does not validate a consuming product or establish an ATO, accreditation, security, or production readiness.

## Evidence and remaining validation

Review date: **2026-10-15**. Source: [`6b0ec1d`](https://github.com/deiotte/causeway/commit/6b0ec1ddf30d5a5b833558e52e9b9b82f6c28135), also tagged [`v2.10.0`](https://github.com/deiotte/causeway/releases/tag/v2.10.0). The release was published on 2026-10-10 UTC; its `RELEASED` value is 2026-10-09.

| Locally executed evidence | Result | What it supports |
|---|---|---|
| `tools/validate.py` | 770 assertions passed | Internal agreement among the standard's artifacts and guarded references |
| Bundle and adapter checks | Passed | Manifest reproduction and shipped skill pointers |
| Sync / doctor / starter-upgrade suites | 32 / 62 / 28 passed; no failures | Covered installation, preservation, diagnostics, and upgrade cases |
| Field-note / impact suites | 26 / 23 passed; no failures | Covered queue and decision-reference behavior |
| Throwaway signed-archive / stub publication suites | 13 / 12 passed; no failures | Covered signature/tampering refusals and publication orchestration; no production key-custody assurance |
| Published archive installation | Checksum, signature, installation, and drift verification passed | This release's actual consumer installation path |

No external product evaluator was run in this review. Independent team outcomes, evaluator coverage of the complete contract, and the return on recordkeeping remain unestablished. The standard's index records 32 open items across four registers; tracked gaps are not closed controls.

Release signatures attest the declared contract bundle identity. The bundle digest does not cover the whole archive: installer code, adapters, and several project-owned starters sit outside it. Run drift verification as well as signature verification. Operational key lifecycle, receipt storage, access controls, retention, and replay need their own implementation and evidence.

## Repository map

| Path | Purpose |
|---|---|
| `AGENTS.md` | Engineering defaults and role obligations |
| `rules/` | Topic-specific engineering guidance |
| `skills/` | Survey, Decision Spine, placement, policy references, and field-note methods |
| `templates/` | Project starters, Survey, ADRs, waivers, and field notes |
| `gate/` | Product evaluator contract |
| `conformance/` | Bounded evaluator compatibility fixtures |
| `tools/` | Installation, diagnostics, impact analysis, upgrades, the setup page, validation, and tests |
| `overlays/` | Platform-specific responsibility and evidence mappings |
| `adapters/` | Coding-tool instruction pointers |
| `bundle/` | Manifest, scope declaration, and release trust anchor |
| `decisions/` | Causeway's own decisions and open-items index |
| `ADOPTING.md` | Adoption workflow and trial measures |
| `CHANGELOG.md` | Changes between releases |

## Contributing and license

Issues and field experience are welcome. External pull requests are not currently accepted; see [`CONTRIBUTING.md`](https://github.com/deiotte/causeway/blob/main/CONTRIBUTING.md). Maintainer authority and continuity are recorded in [`GOVERNANCE.md`](https://github.com/deiotte/causeway/blob/main/GOVERNANCE.md). Report vulnerabilities through [`SECURITY.md`](https://github.com/deiotte/causeway/blob/main/SECURITY.md).

Licensed under [Apache-2.0](https://github.com/deiotte/causeway/blob/main/LICENSE), with attribution in [NOTICE](https://github.com/deiotte/causeway/blob/main/NOTICE).
