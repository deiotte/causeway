---
description: Dependency and package-registry rules
globs: ["**/package.json", "**/package-lock.json", "**/yarn.lock", "**/pnpm-lock.yaml", "**/.npmrc", "**/requirements*.txt", "**/pyproject.toml", "**/Pipfile*", "**/go.mod", "**/go.sum", "**/Cargo.toml", "**/Cargo.lock", "**/*.csproj", "**/pom.xml", "**/build.gradle*", "**/Dockerfile*"]
---

# Dependencies

The registry is inside the authorization boundary (AGENTS.md §5). Adding a
dependency is a trust decision about every publisher in its transitive graph,
made on behalf of every machine that will ever install it.

## Adding one

- **Prefer the option that does not depend on npm** where the choice is open.
  The ecosystem posture for this system is recorded under Spine SA-5.14 — read
  it before adding to a manifest it doesn't cover.
- A new **direct** dependency is a review decision, not a lockfile diff nobody
  reads. Name what it does, what it would take to drop it, and what it pulls in.
- **Count publishers, not packages.** Something you could write in a day bought
  a day of work and an unbounded trust relationship.
- Anything reached from more than a handful of call sites goes behind a thin
  first-party interface (AGENTS.md §3). That wrapper is the incident plan.
- Check enclave reachability before you commit to it (Spine SA-4.7). A package
  that cannot be mirrored into the target environment is not available to you.

## Install-time execution

Install scripts are the difference between a bad dependency and a compromised
laptop. They run before anyone has read a line of what arrived.

- **`ignore-scripts=true` in a committed `.npmrc`**, and `--ignore-scripts`
  passed explicitly in CI. If a package genuinely needs a build step, invoke it
  by name, deliberately, after review.
- Same posture for `pip` — install from wheels, never resolve an sdist that runs
  `setup.py` at install time.
- No `curl | sh` bootstrap in any build step. Pin the artifact, verify the hash.

## Pinning and provenance

- Lockfile committed, with integrity hashes. No exceptions.
- **`npm ci`, never `npm install`, in CI.** A range resolved at build time means
  the build is not reproducible and the compromise window is every build.
- Install through the internal mirror with an allowlist and a quarantine window.
  Most malicious versions are yanked within hours; a cooldown turns most of this
  attack class into somebody else's incident report.
- SBOM on every build; drift from the authorized state fails the build
  (Spine SA-5.8). That gate already exists — don't route around it.

## Runtime

- **Node belongs on the build side of the boundary, not the run side.** Compile
  the front end to static assets and ship those. If the production image has no
  package manager and no Node, a compromised dependency cannot open an outbound
  connection from inside the boundary.
- No dependency installation at container start or at runtime. Ever. The image
  is the artifact; installing at boot makes provenance unprovable.

<!-- Eyebrow-raisers live here. The blockers — lockfile provenance, install-script
     posture, SBOM drift — run in CI. See gate/gate-configuration.md §4. -->
