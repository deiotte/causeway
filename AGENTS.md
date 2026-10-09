# Build DNA

**Version:** 1.14 — document of record
**Layer:** Process. See `skills/decision-spine/` for the design layer.
**Seam:** §8 (ADR discipline). Every Decision Spine row lands in an ADR governed
by the rules in this document. That is the only place the two layers touch.
**Ships as:** `AGENTS.md` in the build-standard repo, imported by each project's
`CLAUDE.md` via `@AGENTS.md`.

---

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

---

## 1. North star — Causeway

**Causeway** governs. Velocity comes from prepared ground, not from skipped
steps: a catalog of pre-authorized components, tiered governance, and time-boxed
authorization for work at the edge. Building on the causeway is fast because the
ground was inspected in advance. Stepping off it is a deliberate, visible act
with a named approver — not an accident and not a shortcut.

Implications that the rest of this document exists to serve:

- Composition from the catalog is the default. Bespoke is the exception, and
  exceptions are owned (§8).
- Tier placement — Core, Mission, Operational — is a catalog fact, not a
  self-assessment.
- Criticality is a separate axis from tier, set by whoever owns the
  consequences. See Decision Spine SA-1.1 and SA-1.14.
- **How a system arrives at either** — the tests, the escalators, the
  declaration, and the rules for changing one later — is
  `skills/decision-spine/reference/placement.md`. It is the first thing a new
  build owes and the last thing anybody writes down, which is the wrong order
  and the reason that file exists.
- **Someone else's platform is prepared ground you did not prepare.** Building on
  ServiceNow, Power Platform, or Salesforce inherits a body of decisions, and
  which ones is not obvious from the outside — the answer is written down in a
  **platform overlay** (`overlays/`). An overlay relocates the standard into
  native mechanics. It never reduces what is owed, and a row the platform answers
  still closes with an ADR.

## 2. Microservices by default, or explain yourself

Services are the default decomposition. Independent deployability, independent
scaling, and blast-radius containment are worth the operational cost in most of
what we build.

**Deviation is allowed and expected.** It is not allowed silently. A project that
deviates records an ADR stating the rationale, what is preserved, and the
condition under which the decision is revisited. The exceptions register in the
project `CLAUDE.md` carries a pointer to it.

The canonical worked example: an appliance that deviates to a modular monolith
because the target is a fixed-hardware, air-gapped box with no local operations
staff.
Every additional process is another failure mode and another thing to accredit.
Service-shaped internal boundaries are preserved — separate crates, explicit
interfaces, no shared mutable state — they are simply not process boundaries.
That is what an owned deviation looks like: the seams still exist.

## 3. Modularity and the vendor-agnostic adapter pattern

External services are reached **through an adapter behind a canonical interface,
only**. No vendor SDK calls in handler code. That is how lock-in and untestable
edges get in.

- Define the canonical schema first, from the domain, not from the vendor's
  response shape.
- One adapter per vendor. Adapters translate; they do not carry domain logic.
- Swapping a vendor should touch one directory.
- Third-party *packages* earn the same treatment for the same reason (§5). The
  boundary that lets you swap a vendor is the boundary that lets you drop a
  compromised dependency.

Long-term thinking is a first-class concern here, not a virtue signal: the
adapter boundary is what makes Decision Spine SA-3.8 and SA-9.1 answerable at
all.

### Pin upstream. Never silently fork.

Everything the project did not write arrives at a version, and the version is
part of the design. A dependency, a base image, a vendored standard, a schema
someone else publishes — the question is always the same one: *which copy, and
how would anyone know if it moved?*

- **Pin exactly.** A range is a decision deferred to whoever builds next, and
  the build that reproduces today is the only one you can debug.
- **A local edit to someone else's code is a fork**, whether or not anyone calls
  it one. The patch that is faster than upstreaming is also the patch that gets
  silently dropped at the next bump, and the second time it is written the
  reason has been forgotten.
- **Fork deliberately or not at all.** A real fork is fine — vendored, named,
  owned, with an ADR saying what diverged and what would end the divergence.
  What is not fine is a fork nobody declared, because nobody can pin it, patch
  it, or drop it under incident pressure.
- **The gap between pinned and current is a number someone owns.** Pinning is
  not freezing. A pin nobody revisits is how a project arrives at a five-year-old
  transitive dependency with a CVE and no upgrade path.

The standard holds itself to this and is the worked example. Causeway is
vendored into a project, recorded in `.causeway-lock`, and `check-drift.sh`
exits `5` when a governed file no longer matches what was synced. A project
cannot quietly redefine the standard it claims to follow — not because editing
is forbidden, but because the edit is visible and has to go upstream or become
a declared deviation. Apply to your own upstreams what the standard applies to
itself.

### How it arrives is part of the design

Pinning answers *which copy*. This answers *how the copy gets onto the machine*,
and it is the half that stays unstated until somebody is standing in front of a
machine that cannot follow the instructions.

- **The install path may not assume the target's toolchain.** `git clone`, `npm
  install`, `pip install` from a private index — all fine on a workstation, and
  all quietly assuming the same three things: the tool is installed here, a
  credential for it is enrolled here, and the network is up right now. An install
  that needs all three works on every machine you tested it on and on none of the
  ones you ship to.
- **Separate acquisition from installation.** One machine that has the tool, the
  credential and the egress fetches one artifact. That artifact then installs on
  every machine that has none of them. The authenticated step happens once
  instead of once per machine, and that is the difference that scales — not
  convenience, arithmetic.
- **Publish an archive, and publish the same bytes every time.** Sorted entries,
  pinned timestamps, no uid, no build host. A checksum beside a
  non-reproducible artifact describes one build rather than one release, and the
  first person to try reproducing it is the one who finds out.
- **An artifact that travels by hand carries its own integrity.** A tarball
  arriving on a USB stick, an internal share, or an artifact repository has
  crossed a boundary with no transport security in it. The attestation has to be
  *inside* the artifact and checkable with what is also inside it. A signature
  that requires fetching a second file gets skipped on the first day fetching is
  inconvenient, which is the day it mattered.
- **The offline install path is the one the release publishes**, not the one an
  appendix describes. Same rule as §6, same reason: a degraded mode that is never
  the default has not been tested, it has been described.

The standard is the worked example here, and it is a late one. From v1.0 to
v1.13.1 the only documented way to get Causeway was a clone of a private
repository — while §6 above required consuming projects to build with no network
at all, and ADR 0019 chose SSH release signing specifically so an air-gapped
consumer could verify a release offline. Both of those assume a consumer who has
somehow already got the bytes, and nothing in the standard said how. Worse,
`sync.sh --require-release` — the flag this document tells you to use for
anything that ships — derived *is this a release* from `git describe`, so on a
machine without git it could not be satisfied at all, and said so by printing a
`git checkout` command into a directory with no git in it.

v1.14.0 publishes a signed, reproducible archive and `--require-release` is met
by verifying the release signature instead. ADR 0030 records it, including what
it does not do: it does not make a private repository public, and the first
fetch is still authenticated. What it removes is the per-machine enrollment.

## 4. Brownfield is the normal case

Greenfield is the exception. The standard has to survive contact with systems
that predate it.

Three honest states, matching the Causeway composition states:

- **Catalog-composed** — built from the catalog. The paved road.
- **Wrapped** — legacy or COTS brought under monitoring without a rewrite.
  Legitimate, permanent if need be, and visibly labeled.
- **Unmanaged** — registered but not yet under continuous monitoring. A backlog
  item, not a resting state.

Wrapping is a real answer. Pretending a wrapped system is catalog-composed is
not.

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

**npm scores worst among the mainstream ecosystems on the first four**, and that
is a record rather than a prediction: lifecycle scripts run on install by
default, an ordinary front end trusts hundreds of distinct publishers,
publishing is self-service, and the dominant incident shape is
maintainer-account takeover — lately including worms that harvest credentials
from the machines they install on and republish themselves onward. PyPI shares
the install-time execution problem. Go modules, Maven Central, and NuGet do not
execute code on install, and Go publishes to a checksum transparency log.

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

## 6. Testable, reliable, observable

The bar, stated as things that are true before "done":

- **Testable** — new or changed behavior ships with tests, including the unhappy
  paths (401/403/422/timeout). Green before handoff, not after review.
- **Reliable** — failure modes are designed, not discovered. Circuit breakers,
  bounded queues, defined degradation.
- **Observable** — structured logs carrying trace and span IDs, metrics on the
  golden signals, traces across service boundaries. A system nobody can see
  inside of is not finished.

### The build and the test path reach nothing

Air-gapped delivery is treated everywhere else in this document as a property of
the *target* — SA-4.7 asks which managed services exist in the enclave, §5 lets
IL5 and IL6 settle the registry argument outright. It is also a property of the
**build**, and that half has been assumed rather than stated.

- **The test suite makes no network calls.** Not to a registry, not to a vendor
  sandbox, not to a public API that is *usually* up. A test that reaches the
  network tests the network, and it fails on the day you most need a green
  build. External behavior is a fake behind the §3 adapter boundary; that seam
  already exists, and this is most of what it is for.
- **Dependencies resolve from a local, populated cache.** A build that needs the
  internet is a build that does not run in the enclave it ships to. Discovering
  that during accreditation is discovering it late.
- **The offline path is the one that runs in CI**, not a documented fallback
  nobody exercises. A degraded mode that is never the default has not been
  tested; it has been described.
- **Contract tests against a live upstream are legitimate and separate.** Run
  them, name them, keep them out of the path that gates a merge. Something real
  has to talk to the vendor eventually — it just is not the suite that decides
  whether this commit lands.

The reason this belongs here rather than in a deployment guide: it stops being
achievable the moment it stops being cheap. Retrofitting an offline build onto a
suite with three hundred incidental network calls is a project. Never letting the
first one in is a rule.

## 7. Building with AI, under human oversight

AI writes a great deal of what we ship. The standard is unchanged by that; what
changes is where the human attention goes.

- **A human owns every merge.** Authorship is not the question; accountability
  is. The name on the PR answers for the code.
- **Constraints go in the file, not in the chat.** Environment quirks belong in
  the project `CLAUDE.md` so every agent and every human inherits them. The
  canonical example: GCC High Power Automate has no Variable actions — use
  Compose. That belongs in the file the agent reads, permanently, not in the
  head of whoever hit it first.
- **Agents read the standard before they write.** A session that starts by
  reading `CLAUDE.md` and stating its plan produces reviewable work. One that
  starts by generating does not.
- **Generated code gets the same bar.** Tests, ADRs, adapter boundaries. No
  exemption for speed.
- **What the system does with a model is a design decision, not this document's.**
  Which tools a model may call and what data may cross to a provider are
  per-system architecture, closed at Spine SA-5.15 and SA-5.16. This section
  governs how *we* work with AI; those rows govern what a *system* is allowed to
  do with it. Putting either one in the other's file is the seam failure §9
  warns about.

### One prompt, one commit

The unit of work is the prompt. The unit of review and the unit of revert is the
commit. Keep them the same size and the history stays readable as a record of
intent; let them drift and no one can answer *what was this change trying to do*
from the repository alone.

- **One prompt produces one commit.** A message saying what was asked and a diff
  showing what that cost is the smallest complete record an agent-built change
  can leave behind.
- **Squash before the PR, not after.** Six commits of an agent finding its
  footing are six commits nobody can bisect. Collapse them while you still
  remember which one mattered.
- **Never batch unrelated prompts into one commit.** Three fixes in one diff
  means reverting any of them reverts all three, and the reviewer reads none of
  them closely.

**Suspended for spikes and parallel design.** Exploratory work is exempt while it
is exploratory — a spike, a throwaway branch, two designs built side by side to
see which survives. The exemption ends the moment the branch becomes something
that will merge, and that transition is the whole rule: the work that ships gets
rewritten into prompt-sized commits before the PR opens, or the spike branch is
deleted and the answer is rebuilt deliberately.

Declare the exemption where someone will see it — the PR body, or the branch
name. An escape hatch nobody declares is indistinguishable from the rule being
ignored, and a rule that cannot tell those two apart is dead inside a month.

Consistent with §9, the gate does not check this. It cannot: an agent can produce
one commit from six prompts and nothing in the diff says so. Commit granularity
is a review property, not a CI property. What CI can see is whether a change that
touched behavior also touched tests — which is the §6 bar this rule mostly exists
to keep honest — so `tests-with-source` is named for what it measures rather than
for the rule it accompanies. It files a finding at every profile today, and its
decided destination is blocking at G2 and G3 once a system has cut its first
release: a system still being built has not yet made the promise it enforces. The
spike exemption above needs no equivalent there and does not get one — the check
evaluates a proposed change, so a spike branch that never opens a PR never reaches
it, and one that does has already been rewritten. See `gate/gate-configuration.md`
§4.

## 8. ADR discipline — the seam

This section is where the process layer meets the design layer. Every Decision
Spine row closes here or it does not close.

- Every decision with a real alternative gets an ADR in `decisions/`.
- **A decision is recorded only when it is ready to be recorded.** Where the project
  ran a Survey (`skills/survey/`), only a `DEC-` row with verdict **READY** becomes an
  ADR. `BLOCKED` and `PROBE` rows get their dependency or their probe recorded instead;
  a `NOT-A-DECISION` row gets neither, because an ADR on an uncontested default dilutes
  the register and teaches people to skim it. Readiness is the four-part test in
  `templates/survey.md` §S4.1, not a feeling about whether the conversation is finished.
- **An ADR states the forces that discriminated between its alternatives.** Where a
  Survey exists these are its row IDs, copied into `forces` from the `DEC-` row rather
  than re-derived at writing time — if a force has to be invented to fill the field,
  the row was not READY. An ADR justified only by preference will be reopened by the
  first person with a different preference, and that reopening is indistinguishable
  from churn.
- ADRs are **numbered, immutable, and superseded rather than edited**.
- **A superseding ADR classifies why, in `supersession_cause`.** S1 (outside
  information changed) and S2 (learned by building) are healthy. S3 (a constraint we
  already had and never surfaced), S4 (decided before an upstream decision closed), and
  S5 (never actually contested) are intake defects, and each names the step that was
  skipped. The code is assigned when the superseding record is written, while the
  reason is still in the room — not reconstructed at a retro. The codes are a defect
  class reviewed at retro, never an accusation attached to the ADR: a team that reads
  them as blame stops recording them honestly, and then the only signal that says
  whether intake is improving is gone.
- **A factual error in an accepted ADR is corrected by a later ADR, and the
  corrected one gains `corrected_by` in its frontmatter.** The body is not edited.
  Immutability protects the argument, and an argument is not what a wrong count is;
  what it cannot protect is a reader who has no way to reach the correction.
  Frontmatter is the mutable half by construction — `superseded_by` cannot be known
  when an ADR is written, and neither can this — so the pointer costs nothing the
  rule was defending. `corrects` and `corrected_by` are mutual, and the build checks
  both directions.
- Status: `Proposed | Accepted | Deferred | Waived | Deprecated | Superseded`.
- **Waived is a first-class status** and carries mandatory fields: the spine row
  ID, why not now, risk accepted, expiry date, who accepted it, and the review
  trigger. No open-ended waivers. An expired waiver is a gate failure.
- Eight spine rows require a **named individual** as approver, recorded in the
  ADR: SA-1.8, SA-1.9, SA-2.11, SA-5.7, SA-5.10, SA-5.13, SA-5.16, SA-9.4.
- **Code that encodes a contested choice without an ADR is incomplete.**

### Closing a row that arrived after the system did

The spine gets revised, and a revision can add a row to a system that is already
in production. Where that row is **one-way**, the ADR closing it is a different
document from the one a new system writes, because the door is already shut.

- **State the as-built answer.** What the system has actually been doing, with
  dates — not what you would choose today. A decision made by default is still
  the decision that got made, and the record should say so.
- **Where the as-built answer is an ongoing unrecoverable exposure, the ISSM is
  notified and the ADR records the name and the date.** The disclosure has
  already happened; the only open question is who knows about it. A live
  exposure written down honestly and left sitting in a repository is the failure
  this rule exists to prevent, and it is a blocking gate failure.
- **Going forward is the last section, not the first.** An ADR that opens with
  the corrected design has quietly answered a different question than the one the
  row asked.

`templates/adr-retroactive-template.md` carries the shape. The deadline these
close against is the adoption horizon — design layer, in the spine.

The exceptions register in each project's `CLAUDE.md` is the index into the ADRs
that record deviations from this standard. A deviation nobody can find is a
deviation nobody owns.

### The open-items index

**An ADR that opens or closes an open item records it in the project's open-items
index. The index holds the item's state; the prose entry holds its argument.**

An ADR does not only close a spine row. It leaves things behind — a question it
declined to answer, a guard it deferred, a gap it published under the rule below —
and each of those lands as a numbered item in whatever document the ADR was
amending. That document is the right home for the *argument*. An open item is a
paragraph of reasoning with a number on it, and reasoning does not belong in JSON.

It is the wrong home for the *state*. Items accumulate across several documents,
each list numbered independently, each item closed in place by a later ADR that
says so in its own prose and nowhere else. Nothing counts them. The failure is not
that any one item is wrong — it is that nobody can say how many are open without
reading every register end to end, so the number stated at the front door goes
stale, and the next ADR inherits the stale number and restates it.

That is not hypothetical. Causeway lost one of its own: gate configuration open
item 10 was appended to the end of §11 and stayed there through three ADRs, two of
which amended it in place and one of which described it as sitting in §10. The
register showed nine items. Nothing disagreed, because nothing was counting.

So the two halves are split:

| The index holds | The prose entry holds |
|---|---|
| `status` — `open` or `closed` | Why the item exists |
| The ADR that opened it and the ADR that closed it | What closing it would take |
| The version each of those happened in | What the item was right and wrong about |
| Which register it belongs to, and its number | The resolution, written in when it closes |

Five rules govern it:

- **Numbers stay stable and a closed item keeps its entry.** The index does not
  replace that rule; it is how the rule finally gets checked. A closed item keeps
  its number, its prose entry, and its row in the index.
- **Every register is declared in the index.** A numbered open-item list the index
  does not name is a register nothing counts, which is the state this rule ends.
- **The index is hand-maintained, not generated.** Deriving it would mean parsing
  the prose, and prose that gets parsed starts being written for the parser. The
  index is edited by the commit that edits the entry — same change, same review.
- **An item cites its ADRs by number, and they exist.** `opened_by` and `closed_by`
  name real records in `decisions/`. An item that closed by nothing lapsed rather
  than closed, and telling those apart is most of why this is written down.
- **Every stated count derives from the index.** Wherever a document says how many
  items are open, that number comes from here and a check says so.

#### Relations between items

Counting items is not enough. The registers are separate documents; the questions
in them are not. An item can be a duplicate of one in another register, or already
settled by one, or a finding whose resolution belongs somewhere else entirely.
None of that is a counting error, so a count cannot find it, and none of it is
visible to a reader with one register open — which is every reader.

**An item names its relationship to items in other registers, and the build
enforces what the name promises.**

| Relation | What it promises |
|---|---|
| `duplicate_of` | The same question in another register. Mutual, and both halves carry the same status — you cannot close half a duplicate. |
| `superseded_by` | Another item settled this one's question. When that item closes, this one closes. |
| `upstream_of` | The resolution belongs to another register's item. Targets cross registers and must exist; when one closes, this item is re-read against it. |
| `answered_by` | A document outside this register answered the question this item asks. Names the document and the heading, and both must still be there. |
| `blocked_on` | Keys from a declared vocabulary, so *several items are waiting on the same thing* is a fact somebody can query rather than a pattern somebody noticed. |

Two rules about using them:

- **A finding that belongs upstream names the item it belongs to.** Where no such
  item exists, open one. *The finding belongs upstream* with no target is a finding
  with no owner, and it reads as tracked when it is not — worse than an untracked
  one, which at least looks the way it is.
- **A relation is not a merge.** Two registers may legitimately ask the same
  question at different layers and close it on different arguments. The edge
  records that they are the same question; it does not decide which register owns
  it, and collapsing them into one item would.

`templates/open-items.json` carries the shape. `sync.sh` seeds it once and then it
is the project's file, the way `CLAUDE.md` is.

An open item is a declared gap that outlived the ADR that declared it, which is
the rule immediately below. The index is what keeps it declared.

### Declared gaps

**A requirement that cannot be satisfied is published with its blocker. It is
never omitted.**

This is one rule with four existing implementations, and naming it once is
overdue — each mechanism below was built for its own reason, and nothing said
they were the same idea.

| Where | The mechanism | What it refuses to let you do |
|---|---|---|
| ADRs (§8) | `Waived` status, with expiry, risk accepted, and a named acceptor | Leave a row open by saying nothing about it |
| ADRs (§8) | The retroactive ADR: as-built answer first, corrected design last | Answer the question you wish the row had asked |
| The gate | `unsupported` as a verdict distinct from `pass` and `fail` | Report "could not evaluate" as success |
| Overlays | "Where a check cannot read anything on this platform, say so plainly rather than inventing an artifact" | Manufacture evidence to fill a cell |

The shape is the same every time. A gap that is written down has an owner, a
date, and an argument. A gap that is omitted has none of those, and it does not
stop existing — it stops being *tracked*, which is strictly worse, because the
system now looks complete to everyone who reads it.

Applied to work in flight, this is a rule about what you hand back:

- **Ship the blocker with the deliverable.** A control you could not implement,
  a check you could not make pass, a row you could not close — say which, say
  why, and say what would unblock it. Deliver the rest complete.
- **Name the blocker precisely enough to act on.** "Not feasible" is not a
  blocker. "Requires a key custody decision nobody has made; SA-5.7; blocked on
  a named approver" is.
- **Silence reads as done.** Anyone who omits a gap has made a claim about the
  system whether or not they meant to, and it is the one claim they had no
  evidence for.

The declaration is not the fix and does not pretend to be. It is the difference
between a known gap and an unknown one, and every control regime we build
against — a gate, an ATO, an assessor, an incident review — is built on that
distinction.

## 9. Guidance versus enforcement

This document does not gate anything. That is deliberate and worth stating
plainly, because a standard that pretends to be a control is worse than one that
knows it isn't.

| Belongs here | Belongs in a gate |
|---|---|
| Judgment, defaults, vocabulary, worked examples | Secrets scanning |
| "Why we do it this way" | SBOM drift |
| Deviation and exception process | Spine row closure and waiver expiry |
| Anything a good engineer should weigh | Named-approver presence |

The gate configuration lives in `gate/gate-configuration.md`. When the two
disagree, the gate is authoritative and this document has a bug.

### Know which gate you are building under, before you write

The same catalog of checks runs at every profile. What changes is whether a
result is skipped, advisory, or blocking — so "does the standard require this"
has no answer until you know the profile, and an agent or engineer who starts
generating before resolving it is guessing at the bar.

Resolve it in this order, and it is a one-minute job:

1. **Read `system.json`** for `tier` and `criticality_class`. Both are in the
   repository precisely so nobody has to ask.
2. **The profile is derived from those two, never declared.** The matrix is in
   `gate/profiles.json` and `skills/decision-spine/reference/gate-profiles.md`.
   A project that writes its own profile into a file has answered a question it
   was not asked; `gate/profiles.json` is authoritative and vendored.
3. **Missing criticality means C1**, the strictest class. The failure mode of
   assuming C3 is a mission-critical system reviewed as a prototype. The failure
   mode of assuming C1 is a slightly longer conversation.

Tier is a catalog fact and criticality is set by whoever owns the consequences
(§1). Neither is a self-assessment, and a project that finds itself arguing its
way down a tier is having the wrong argument in the wrong document.

**And if the fields are not there, step 1 has no answer to read.** That is the
normal case at the start of a build, and it is a different job: you are not
resolving a placement, you are producing one. The procedure is
`skills/decision-spine/reference/placement.md` — four questions about what a
failure costs, five facts that set C1 on their own, the test the catalog applies
for tier, and what the declaration has to contain to count as one. Run it before
the first design decision, because the class is what says how many of them are
owed an ADR.

Note what that file is not: it is not a way to argue a placement down. The
escalators only escalate, the tier test asks who inherits from you and nothing
else, and the whole document routes the *authority* question back to §1. Its
purpose is to stop C1 being reached by silence. A system classified C1 and a
system nobody classified produce the same gate and are not the same system, and
only one of them can tell you why.

The `decision-spine` skill does this resolution as its first step and is the
faster path when one is available. This section exists so the instruction is
also in the file every project imports — a routing step that lives only in a
tool is a routing step that does not happen when the tool is not loaded.

## 10. The fun clause (non-negotiable, ironically)

This work is supposed to be *fun*. A team enjoying the build ships better work,
and you can feel the difference from the outside.

- **Every project carries an easter egg** — small, harmless, intentional
  personality tucked where a curious person would find it. A `--motd`, a
  comment, an ASCII something, a test fixture named after an inside joke.
  Tasteful, never in the way of the mission, never in the security boundary.
  It is a signature: *a human who cared built this.*
- **Names have character.** We don't ship `service-2`. We ship things with
  callsigns. The bar is set — you are reading one. Live up to it.
- **Keep it human.** Clear over clever. Kind in review. Light in the
  back-and-forth. The standard is high *because* we take the work seriously and
  ourselves a little less so.

> *If you've read this far and there's no easter egg in your project yet, that's
> your first finding. Go fix it.* 🐂

---

## Open items

**Numbers are stable.** A closed item keeps its number and its entry, marked
closed with the resolution — the rule `gate/gate-configuration.md` §10 already
applies, for the reason recorded there: renumbering on close is how a pointer
comes to reference a different item than the one it closed.

1. **Managed policy tier — closed in 1.14.** Referenced in the layering diagram
   and never drafted. It is the only tier a developer cannot override, which made
   it the one that most needed to exist. The item was right that the tier needed
   a definition. It was wrong only in implying Causeway could draft the tier
   itself: the policy is the organization's, and what the standard owed was the
   contract for referencing it. `skills/decision-spine/reference/managed-policy.md`
   is that contract: identity and version, authority, applicability, effective and
   review dates, a pinned offline copy, precedence, who alone grants an exception,
   and how a conflict between policy, customer and project is recorded.
   `tools/doctor.sh` checks the reference; no gate check reads it. See ADR 0050.
2. **Reconciliation — closed in 1.6.** The notice this item pointed at is
   retired and the question is settled: this repository is the document of
   record, as ADR 0001 decided and ADR 0021 now states without contradiction.
   The item was right that a standard whose canonical text is missing cannot be
   inherited from safely. It was wrong to keep waiting: the notice said a repo
   copy would win if one were found, ADR 0001 said this one wins, and both
   claims shipped in the same bundle across thirteen releases, v1.0.0 through
   v1.8.0. Adoption retired the
   reconstruction risk, exactly as the notice's own last sentence predicted.
   See ADR 0021.
3. **`.claude/rules/` set.** `security.md`, `secrets.md`, `database.md`,
   `tests.md`, `dependencies.md`, and `inference.md` ship. The pattern still
   wants a rule for the CI surface itself — the pipeline is the highest-value
   target in the supply chain and nothing path-scoped currently covers it.
4. **The adoption contract is unmeasured.** The Contributor floor is claimed to
   cost an afternoon and the Maintainer floor to be a standing obligation. Both
   numbers are estimates by the people who wrote the standard, which is the
   weakest possible source. They want a first adopter who did not author this.
5. **Nothing enforces the offline test path.** §6 states it as a rule and no
   check reads it. A suite that reaches the network is visible in CI only where
   CI has no egress, and ours does. This is a candidate gate check, not a
   settled one — the honest version needs a way to distinguish a contract test
   that is allowed to reach a vendor from a unit test that is not.
6. **Nothing enforces the index in a consuming project, and that now covers
   field-note dispositions too.** §8 states the rule and `tools/validate.py`
   checks this repository's own index against its own four registers. A consuming
   project gets the template, the rule, and no check — the gate has 27 checks and
   none of them reads `decisions/open-items.json`, because an index is a
   discipline before it is a control and promoting it to a blocking check on its
   first release would be deciding that before anyone has run it. This is the same
   shape as item 5 and it is recorded for the same reason: a rule the standard
   states and does not check is a rule it discovers broken later. The candidate
   check exists — *every ADR that names an open item has a matching row, and every
   count in the repository derives* — and it needs one adopter's evidence before it
   earns a number in `checks.json`.
   The Practitioner role's disposition obligation is the same item and was briefly
   written as a separate one. It is not separate: a note left at `status: new` is
   an index row nobody moved, the rule is stated and unchecked in exactly the same
   way, and `validate.py` is the standard's own validator and does not ship. Two
   numbers for one question is how a register comes to disagree with itself, which
   is the failure ADR 0025 exists to prevent, so the second number was withdrawn
   before it shipped rather than opened and immediately related. The candidate
   check gains one clause — *no note sits undisposed past an age this project
   chose* — and the age is the part that needs an adopter, because one picked
   before anybody has run the process is a threshold invented to have one.
   There is a second reason this is one item and not two, and it is the more
   durable one. Where field notes belong in an index at all is settled by the rule
   the ServiceNow overlay already states for skip records and Instance Scan
   findings: **a note is an input, not an entry.** It earns a row when the ADR
   that read it leaves something open, and not before. A register of every note
   ever written is a second numbering of the note directory, and the thing worth
   checking was never the note. It was the answer somebody owed.
7. **Nothing checks a count stated in an ADR.** Every derived count in a living
   document is anchored — the README's, and the index's own sentences about itself.
   An ADR's are not, and ADRs 0025 and 0026 shipped six wrong ones between them,
   each derivable from a file in the same commit. The difficulty is real rather
   than an oversight: an ADR is a dated record, its counts are true as of its
   date, and a guard that compared them to the current artifacts would fail
   forever the moment the next item opened. The candidate is narrow — record the
   index version an ADR derived its numbers at, and check only the ADR whose
   version matches the tree being validated, which is exactly the one being added
   in that commit. It is written down here rather than built, because it wants one
   more release of evidence about whether ADRs keep stating counts at all now that
   the index exists to point at instead.
8. **The Practitioner floor is unmeasured, and it is the floor with a second
   party.** The other three cost what they cost to the person paying. This one
   spends half an hour of a practitioner's time and buys a standing disposition
   obligation from a maintainer, and neither number has been observed — the
   half-hour is an estimate by the people who designed the form, which is the
   weakest possible source, and the disposition load depends entirely on a note
   rate nobody has seen. The specific risk is not that the estimate is wrong. It
   is that the reciprocal obligation is the half that lapses quietly: notes keep
   arriving, dispositions fall behind, and the failure is invisible until the
   practitioners stop writing, at which point it looks like disinterest and is
   not. This wants one project that did not author the standard, running it for
   one quarter, reporting both numbers.
9. **A pointer is not discovery.** Nothing auto-discovers `skills/`; an agent
   learns a skill exists because the tool adapter it reads names the path, and
   `render-adapters.sh` now fails when one does not (ADR 0029). That guard checks
   only that the pointer is present. It cannot check that an agent read the shim,
   honored it, or recognized the moment the skill was for, and those are the three
   ways a named skill still goes uninvoked. The candidate fix is real and larger
   than the bug that surfaced it: ship the skills where each tool already looks —
   `.claude/skills/` for Claude, and whatever the equivalent is for the other
   three — so discovery does not depend on prose being obeyed. That is a change to
   how `decision-spine` has worked since it existed, and deciding it on one bug's
   evidence is the trade this item declines to make yet. It wants the first
   practitioner session that did not go through an author of this standard.
   This item takes the number a second disposition item held briefly and
   unpublished during ADR 0028. `v1.13.0` shipped this register ending at item 8,
   so no reader has seen a different item 9 and §8's numbering promise is intact.
10. **Intake is stated and unenforced.** §8 now requires a READY verdict before a
   decision is recorded, a non-empty `forces` list, and a `supersession_cause` on
   every superseding ADR. Nothing checks any of the three. `survey-present` and
   `adr-forces-nonempty` are named as candidate checks in ADR 0031 and deliberately
   deferred: the gate configuration requires a warn cycle before any new blocking
   behavior engages, and a warn cycle needs something to measure. The measurement is
   the cause-code distribution these rules start collecting, which does not exist
   yet — so promoting either check now would be deciding on the strength of one
   field run of the instrument, on a build that has not been built. The thirty ADRs
   written before this release carry no `forces` and are not backfilled; the
   requirement attaches going forward, the way `tests-with-source` attaches. What
   this item is waiting for is the first surveyed build to supersede something, and
   then enough of them to tell an S3 habit from an S1 accident.
