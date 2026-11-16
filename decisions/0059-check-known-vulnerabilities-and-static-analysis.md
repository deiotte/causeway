---
adr: "0059"
title: Check known vulnerabilities against a remediation window, and static analysis for unjustified errors — two advisory gate checks
status: Proposed
date: 2026-11-16
spine_rows: []         # gate contract only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: After one warn cycle, most known-vulnerabilities findings are for components
  the build never loads, or most static-analysis errors are false positives — either
  means the input needs tightening before either check blocks anyone. Also revisit if
  an engine integrator reports that no scanner it can run produces first-seen dates.
approver:
  name:
  role: Maintainer review pending
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Causeway's gate blocks at every profile on four supply-chain facts: committed
secrets, SBOM drift, lockfile provenance and install-time execution. It says nothing
about two questions every security assessor asks first.

**Is anything we ship known to be vulnerable, and for how long?** SA-5.8 asks which
supply-chain controls run in CI and names "image scan" in its answer set, and
`sbom-drift` reads the inventory. Nothing compares that inventory to an advisory
database, and nothing says how long a known vulnerability may stay open. Without a
window, a scan is a report someone may or may not read.

**Did anyone look at the code itself?** SA-8.3 asks what gates the pipeline. Unit and
contract tests prove behavior someone thought to specify. Static analysis finds the
class of defect nobody specified — an injection, a path traversal, an unchecked
deserialization — and Causeway had no check for it.

## Forces

- **Blocking behavior is earned, not declared** (gate configuration §9). Every
  blocking check since v0.2 shipped warn-only for a cycle first. A new check that
  blocked on arrival would light up every repository at once, for reasons nobody has
  measured.
- **Counts measure the advisory database, not the team.** A vulnerability count rises
  when a database publishes, whether or not anyone did anything wrong. What shows a
  real gap is a known vulnerability left open past a deadline.
- **The windows already exist.** Federal practice sets them: CISA BOD 19-02 (15 days
  critical, 30 high, for internet-facing systems) and the FedRAMP continuous
  monitoring guidance (30 high, 90 moderate, 180 low). BOD 22-01 adds due dates for
  known-exploited vulnerabilities. A system under any of these should not have to
  reconcile a second number.
- **The standard names no tools.** Every check reads an input class, not a product.
  Scanners and analyzers change faster than a standard should.
- **A silenced finding is not a fixed one.** Suppressing a static-analysis result is
  often right. Suppressing it with no reason is how a real defect ships.

## Decision

**Gate configuration 0.9 adds two checks and two input classes. Both checks file
findings at every profile and block nowhere until a warn cycle earns it.**

- **`known-vulnerabilities`** reads `vuln-report` (advisory matches for the build's
  components, with severity, a known-exploited flag and a first-seen date) and
  `gate-config`. A match past its window fails; one inside its window is reported and
  passes. Default windows: critical 15 days, high 30, moderate 90, low 180. A
  known-exploited match takes the shorter of its window and the list's due date.
  `ato-gate.json` `vulnerability_windows` may shorten a window; lengthening one is a
  waiver ADR. A missing report is `unsupported`, never a pass. Spine row SA-5.8.
- **`static-analysis`** reads `sast-report` (SARIF 2.1.0). An error-level result fails
  unless it carries a suppression with a written justification. Warnings and notes
  never fail. Spine row SA-8.3.
- **Both are advisory everywhere** in `profiles.json`. Gate configuration §10 item 15
  records the decided direction — `known-vulnerabilities` blocking at G1 and above,
  `static-analysis` at G2 and above — and that the timing waits on the first cycle.
  §9 gains step 11.
- **The engine keeps first-seen dates** in the evidence store, from the first receipt
  that reported a match. Scanners do not remember them, and the window is meaningless
  without them.
- **The ServiceNow overlay** is re-ratified at 1.17. A platform vulnerability stays
  ServiceNow's, inherited; Instance Scan findings count once converted to SARIF.

No spine row moves. SA-5.8 already asks for scanning in CI and SA-8.3 already asks
what gates the pipeline; these checks verify answers those rows already owe.

## Alternatives considered

**Block on arrival.** Rejected for the §9 reason. The first pass across an existing
portfolio would fail almost everything, the remedy would be weeks of upgrades, and
teams would learn to waive the check before learning what it measures.

**A new spine row for a patch window.** Rejected for now. It would make the window a
decision every system records, which is attractive, but it moves the spine to 0.9,
adds a row every overlay must disposition, and starts an adoption horizon for every
system — all to record a number most systems will copy from the default. The window
lives in `ato-gate.json` and the SA-5.8 ADR. If systems start needing different
windows for reasons the default cannot express, a row earns its cost.

**Fail on any critical or high finding regardless of age.** Rejected. It turns every
advisory publication into a red build for every system that uses the component,
including the hours before a fix exists. That trains people to ignore the check.

**Name a scanner or analyzer.** Rejected. The standard names input classes, not
products, for every check it has. A system picks its tools under SA-5.8 and SA-8.3.

## Consequences

**Easier.** A system can show an assessor, from receipts, that no known vulnerability
outlived its window and no static-analysis error was silenced without a reason. A
vulnerability the team is waiting on has a dated, named waiver instead of a shrug.

**Harder.** An engine owes two new input classes and must remember first-seen dates.
Until one does, both checks report `unsupported` as findings, which is honest and
noisy.

**Declared gaps.**

- **Neither check blocks.** That is the decision, and §10 item 15 keeps it visible.
- **No engine supplies either class yet.** The same gap gate configuration item 11
  records for every class.
- **No conformance fixture covers either check.** The nine fixtures cover five checks;
  these two join the twenty-four with none.
- **Reachability is not measured.** A match in a component the build never calls fails
  the same as one on the request path. The revisit condition watches for this.

## Revisit if

The first warn cycle shows the findings are mostly unreachable components or false
positives, or no scanner an engine can run gives first-seen dates. The frontmatter
states both.

## Evidence

- `gate/checks.json`: the two checks, the two input classes, gate configuration 0.9.
- `gate/profiles.json`: both checks `warn` at G0–G3.
- `gate/gate-configuration.md`: §4 table rows and two subsections, §6
  `vulnerability_windows`, §9 step 11, §10 item 15, §11 counts; version 0.9.
- `decisions/open-items.json`: `gate-config-15`.
- `overlays/servicenow.md` and `.json`: ratified again at 1.17, with evidence for both
  checks and sources for both classes.
- `AGENTS.md` open item 6 and other count statements: 29 checks, 16 input classes.
  Build DNA 1.18 for that restatement alone.
