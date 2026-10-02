# Gate Profiles — Skill Reference

Summary for answering gate questions. The executable spec is `gate/gate-configuration.md`.

## Resolution

The profile is **derived from tier x class, never declared**. A system does not
choose its profile.

|            | C3 | C2 | C1 |
|------------|----|----|----|
| Operational| G0 | G1 | G1 |
| Mission    | G1 | G2 | G2 |
| Core       | G2 | G3 | G3 |

Missing `criticality_class` resolves to **C1**, not C3. Missing `tier` is a hard
error — the system is not registered.

This file is about what the two values *do*. Where they come from — the four
questions, the escalators, the tier test, the declaration, and how a placement
changes — is `reference/placement.md`. A profile question asked by somebody who
has not been placed yet is a placement question wearing a gate costume.

## Profiles

- **G0 Sandbox** — C3 short form closed, secrets scan, dependency provenance,
  classification declared. Fully automated, no human in the loop.
- **G1 Tactical** — G0 plus one-way doors in scope, plus a Tactical Authorization
  with duration and revocation trigger, plus named approvers on any dagger rows.
- **G2 Mission** — full spine for the class. Control inheritance verified,
  evidence pipeline emitting, contract tests green, DR plan of record.
- **G3 Core** — G2 plus what is owed to other people's systems: exposure review,
  promotion review, DR drill within cadence, AO signature on the boundary.

## Universal blockers

The security floor blocks at every profile, G0 included: secrets scan, SBOM
drift, dependency provenance, install-script execution, named-approver presence,
waiver expiry. Even a citizen-developer sandbox app cannot get under it.

`install-scripts` resolves N/A for ecosystems that have no install-time
execution — which is the point of preferring them (Spine SA-5.14).

## Promote-or-sunset

Operational + C1 only. `renewal_count` on the TA record:

- `0` — original authorization. Pass.
- `1` — first renewal. **Warn**: a promote-or-sunset decision is due before next expiry.
- `>=2` — **Block** unless `disposition_ref` points at an ADR with status `Accepted`.

Sunset counts as a disposition. The rule is "decide," not "promote."

## Exit codes

`0` pass · `1` blocking check failed · `2` expired waiver or exclusion ·
`3` promote-or-sunset block · `4` configuration error
