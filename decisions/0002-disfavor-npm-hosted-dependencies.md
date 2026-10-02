---
adr: "0002"
title: Treat the package registry as inside the authorization boundary, and disfavor npm
status: Accepted
date: 2026-08-05
spine_rows: [SA-5.14, SA-5.8]
approver:
  name: Karl
  role: Contract CTO
supersedes:
superseded_by:
---

## Context

The standard already treats the software supply chain as a control surface: SBOM
on every build, drift as a merge-blocker, SA-5.8 for supply-chain controls in CI.
All of it verifies what a build *produced*. None of it governs which registries a
project is permitted to trust in the first place, and that is the half where the
incidents actually happen.

Package ecosystems are not equivalent, and the difference is structural rather
than cultural:

- **Install-time execution.** npm lifecycle scripts run arbitrary code on
  install, before any human has read what arrived. PyPI sdists do the same
  through `setup.py`. Go modules, Maven Central, and NuGet do not.
- **Transitive surface.** An ordinary front end resolves to hundreds of distinct
  publishers. Every one of them is an account that can be taken over.
- **Publisher integrity.** Publishing is self-service and token-based. The
  dominant npm incident shape is maintainer-account compromise, and recent
  campaigns are self-propagating: the malicious install harvests credentials
  from the machine it lands on and publishes itself onward through packages
  that machine could push to.
- **Enclave reachability.** npm is not reachable from the air-gapped and IL5/IL6
  environments a large share of our work targets. ADR 0001 already rejected npm
  as a distribution channel for this repository on exactly that ground.

The compromise lands on developer laptops and CI runners — inside the
authorization boundary, holding credentials, with network egress. Treating that
as a build-tooling detail rather than an architectural decision is the gap.

## Decision

**A package registry is inside the authorization boundary.** Ecosystem choice is
an architectural decision with a stated default, recorded per system, and
verified in CI.

1. **Build DNA §5 gains "The registry is inside the boundary."** It states the
   five properties an ecosystem is judged on, names npm as the worst-scoring
   mainstream ecosystem on four of them, and sets the default: where the choice
   is genuinely open, the option that does not depend on npm wins. It is a §2-
   style default with an owned exception, not a prohibition.
2. **Spine SA-5.14** — *which package ecosystems and registries may this system
   depend on, and what executes at install time?* One-way, C1–C3, in the short
   form. Spine goes to v0.5.
3. **`rules/dependencies.md`** carries the mechanics, path-scoped to manifests
   and lockfiles so it costs nothing until someone touches one.
3a. **A count correction rides along.** Recounting the table to place SA-5.14
   found that v0.4's published figures disagreed with its own `Applies` column:
   SA-9.3 was marked `C1–C3` but left out of the short-form list, and the short
   form's † count read four where the table yields three. The column is
   authoritative, so SA-9.3 joins the list and every count is now derived from
   the table. v0.5 is 92 rows · 27 one-way · 22 short form · 87 at C2.
4. **Two new universal gate blockers** — dependency provenance (committed
   lockfile, integrity hashes, no build-time range resolution) and install-script
   execution disabled. Both discover ecosystems from the repo rather than reading
   a declaration, and both resolve N/A for ecosystems that cannot fail them.
5. **Four architectural consequences** are stated in §5 so that "prefer
   alternatives" has something behind it: npm stays on the build side of the
   boundary and out of the production image; packages get the §3 wrapper
   treatment so dropping one is an afternoon; new services prefer runtimes with
   a standard library big enough to say no; publishers get counted, not packages.

## Alternatives considered

**Ban npm outright.** Rejected, and not narrowly. Anything with a browser front
end depends on npm, so a ban would be either unenforceable or a lie — and a
standard that states a rule everyone routes around loses authority on the rules
that matter. The owned-deviation pattern from §2 is the mechanism this repository
already uses for exactly this shape of problem.

**Leave it as guidance in §5 and add no spine row.** Rejected: §9 is explicit
that this document gates nothing. Without SA-5.14 there is no ADR trigger, no
gate hook, and no artifact anyone can point at — the standard would be naming its
single most-exploited surface and doing nothing about it.

**Widen SA-5.8 instead of adding a row.** Rejected: SA-5.8 asks what CI enforces
and is correctly marked not-one-way. Ecosystem choice *is* one-way. Folding two
different reversibility properties into one row makes the one-way-door list wrong,
and that list is the part of the spine people actually act on.

**Make install scripts a waiverable finding rather than a blocker.** Rejected on
reading the waiver back: it would have to say "arbitrary third-party code may
execute on our CI runners until a date." Nobody signs that sentence. If a check
cannot produce a waiver anyone would accept, it is a blocker.

**Name specific compromised packages.** Rejected: it dates the document. The
properties are durable; the incident list is a slide, not a standard.

## Consequences

- Every system now owes an ecosystem posture, and most existing ones have an
  ecosystem they never declared. SA-5.14 is the row that exercises the spine's
  version-drift policy for the first time — expect the backfill to be noisy and
  expect it to find at least one repo installing with scripts enabled in CI.
- Node repositories will fail the install-script check on first run. The remedy
  is a committed `.npmrc` and a CI flag, not a rewrite. Implementation order §9
  step 4 runs both new checks warn-only for one cycle for this reason.
- Front-end work gets slightly more expensive at the seam: shipping static assets
  rather than a Node runtime is a deliberate build step someone has to own.
- A C3 system that closed the published twenty short-form rows now owes SA-9.3
  as well as SA-5.14. That is the correction landing, not new scope, and it is
  due at the next review rather than immediately.
- The standard's own bias is now on the record. When someone chooses Go over Node
  for a service, this is the document they cite, and when someone chooses Node
  anyway, this is the document that tells them what they owe.
- Spine v0.5, gate configuration v0.2, standard v1.1.0. Consuming projects pick
  it up by re-syncing.

## Evidence

`AGENTS.md` §5 · `skills/decision-spine/reference/spine.md` SA-5.14 ·
`rules/dependencies.md` · `gate/profiles.json` (`dependency-provenance`,
`install-scripts`) · `gate/gate-configuration.md` §4 · per-project ADRs closing
SA-5.14.
