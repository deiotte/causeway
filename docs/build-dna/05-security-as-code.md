# Build DNA — §5 Security and compliance as code

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## 5. Security and compliance as code

Controls are implemented, evidenced, and verified by machine. Not asserted in a
document that goes stale the week after it is signed.

- Secrets are injected at runtime from a vault. Zero hardcoded credentials, and
  the scan is a merge-blocker, not a review comment.
- SBOM on every build. Drift from authorized state fails the build.
- Control evidence emits continuously into dated receipts (OSCAL where the
  customer consumes it).
- Timeouts and retries with backoff on every outbound call. Idempotency on
  anything a retry could double-fire.

### The registry is inside the boundary

A package registry is not a convenience the build happens to use. It is a
third-party input that executes code on developer laptops and CI runners, which
puts it inside the authorization boundary whether or not the boundary diagram
admits it. Ecosystem choice is therefore an architectural decision with a
default, not a consequence of who wrote the first file. Spine row **SA-5.14** is
where a project records its answer, and it is a one-way door.

Judge an ecosystem on properties, not on taste:

| Property | The question |
|---|---|
| **Install-time execution** | Does installing a package run arbitrary code before anyone has read it? |
| **Transitive surface** | How many distinct publishers must be trusted to install one thing? |
| **Publisher integrity** | How does a maintainer account get taken over, and what reaches consumers when it does? |
| **Immutability** | Can a published version change in place, and is there an append-only log proving it didn't? |
| **Enclave reachability** | Is the registry reachable from the target environment, or does a mirror quietly fork the trust decision? (SA-4.7) |

**npm scores worst among the mainstream ecosystems on the first four**, and
every clause of that claim is checkable against the registries' own
documentation rather than against anyone's memory of an incident —
`rules/dependencies.md` *Sources* lists where. Lifecycle scripts run on install
by default, and the setting that stops them is opt-in. A published version
cannot be altered in place, but it can be unpublished for a period, so the
record is not append-only. Publishing is self-service, and an ordinary front end
trusts hundreds of distinct publishers; count yours with `npm ls --all`. The
dominant incident shape is maintainer-account takeover — lately including worms
that harvest credentials from the machines they install on and republish
themselves onward — and the OpenSSF malicious-packages dataset is where to
count that by ecosystem rather than by headline. PyPI shares the install-time
execution problem for source distributions only: a wheel installs without
running anything, an sdist runs its build backend. Go modules, Maven Central,
and NuGet do not execute package code on install; Maven Central and NuGet
refuse to alter a published version, and Go records every module version's
hash in a checksum transparency log.

**The default is the option that does not depend on npm.** Where the choice is
genuinely open — a new service, a build tool, a library, a component small
enough to write ourselves — the non-npm option wins. As in §2, this is a default
with an owned exception, not a prohibition. Deviating is expected. Deviating
silently is not.

Architect so the answer is cheap when — not if — a package is compromised:

- **Keep npm on the build side of the boundary, never the run side.** A front
  end compiles to static assets; ship those. With no Node in the production
  image, a compromised dependency is a build-integrity problem the signing chain
  already covers (SA-8.8), not an outbound connection from inside the boundary.
- **Wrap packages the way §3 wraps vendors.** The mitigation for a compromised
  dependency is dropping it. One called from two hundred files cannot be dropped
  under incident pressure; one behind a thin first-party interface is an
  afternoon.
- **Prefer runtimes with a standard library big enough to say no.** Choosing Go,
  Rust, .NET, or the JVM for a new service is choosing a dependency count that
  fits in a reviewer's head. That is a security property, not an aesthetic.
- **Count publishers, not packages.** A dependency you could have written in a
  day bought a day of work and an unbounded trust relationship.
- **Air-gapped, IL5, and IL6 targets settle the argument by themselves.** A
  registry unreachable from the target environment was never a dependency you
  actually had (SA-4.7).

For anything with a browser front end, npm is usually unavoidable. That is a
deviation and an owned one: it closes under SA-5.14 and holds the floor in
`rules/dependencies.md` — no install-time script execution, committed lockfile,
internal mirror with a quarantine window.
