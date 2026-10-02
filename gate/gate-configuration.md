# Causeway Gate Configuration

**Version:** 0.8
**Depends on:** Decision Spine v0.8 (gate profiles G0–G3, criticality class, † rows,
adoption horizon)
**Implements in:** any conforming engine — see §11 for the engine contract
**Machine-readable in:** `gate/profiles.json` (resolution + blocking matrix),
`gate/checks.json` (per-check specifications). See §11.

Decision Spine v0.3 defined four gate profiles as policy. This document turns
them into configuration the gate can actually execute, and adds the enforcement
mechanism for the promote-or-sunset rule, which until now was a stated policy
with nothing behind it.

---

## 1. Design rules

Three rules constrain everything below. They are the reason this is defensible
rather than merely automated.

**The profile is derived, never declared.** A system does not choose its gate
profile. The gate computes it from `tier` and `criticality_class` at run time.
If a team could set `gate_profile: "G0"` in a file they control, the entire
model is decorative.

**The gate reads files, not opinions.** Consistent with a files-as-truth
architecture, every check resolves against something on disk — `system.json`,
the ADR directory, the catalog record, the TA record. No check requires a human
to attest in the moment.

**Blocking behavior escalates with profile, check inventory does not.** The same
checks run at every profile. What changes is whether a failure blocks the build
or files a finding. This means a C3 sandbox app still *sees* what it would owe
at Mission tier, which makes promotion a known quantity rather than a surprise.

---

## 2. New and changed `system.json` fields

```jsonc
{
  "id": "example-system",
  "tier": "operational",          // existing: operational | mission | core

  // NEW — Decision Spine integration
  "criticality_class": "C2",      // C1 | C2 | C3. Set per SA-1.1.
  "criticality_authority": {
    "name": "Jane Doe",
    "role": "Product Owner",      // PO | Service Owner | Customer | Sponsor
    "declared": "2026-08-01"
  },

  "spine": {
    // CHANGED in v0.4 — was "version", a declaration. This records what the
    // system last closed against; what APPLIES is read from the vendored
    // gate/profiles.json. Missing => no adoption grace, every row owed now.
    "closed_against": "0.6",
    "closure_ref": "decisions/",  // where the gate looks for ADRs
    "last_review": "2026-08-01"
  },

  // NEW — promote-or-sunset enforcement
  "tactical_authorization": {
    "status": "active",           // none | active | expired | revoked
    "issued": "2026-06-01",
    "expires": "2026-09-01",
    "renewal_count": 1,           // 0 on first issue; +1 per renewal
    "tao": "John Smith",
    "sandbox_tenant": "sbx-example-01",
    "disposition_ref": null       // ADR path once promote-or-sunset is decided
  }
}
```

`gate_profile` is deliberately **absent**. It is computed, and written only into
the evidence receipt as an output. The applicable **spine version** is absent for
the same reason: it is read from the vendored `gate/profiles.json`, whose checksum
is in `.causeway-lock`, so a team cannot move it without failing `check-drift.sh`.
A version a team can assert in a file it controls is decorative, and it would be
the one field worth asserting falsely.

---

## 3. Profile resolution

```
resolve_profile(tier, criticality_class):
    operational + C3            -> G0
    operational + (C2 | C1)     -> G1
    mission     + C3            -> G1
    mission     + (C2 | C1)     -> G2
    core        + C3            -> G2
    core        + (C2 | C1)     -> G3
```

Missing `criticality_class` resolves to **C1**, not C3. An unclassified system
gets the strictest treatment until someone with authority says otherwise. This
is the single most important default in the file: the failure mode of the
opposite default is a mission-critical system quietly running at G0.

Missing `tier` is a hard error, not a default. Tier is a catalog fact and its
absence means the system is not registered.

Both inputs are read here and produced elsewhere. **How a system arrives at a
tier and a class** — the questions, the escalators that set C1 on their own, the
test the catalog applies, and what makes a declaration count as one — is
`skills/decision-spine/reference/placement.md`, in the design layer where
judgment belongs. Nothing in this document is affected by it: the gate reads two
values and cannot see the argument behind either, which is what open item 13
below is about.

---

## 4. Check inventory

`•` = blocks the build. `○` = files a finding, build continues. `–` = not run.
`○→•` = files a finding today, with promotion to blocking **decided** and scheduled
in §9 — distinct from a check whose promotion is merely proposed, which shows `○`.
`‡` marks a cell carrying a **modifier**: a stated condition under which it
downgrades to a finding. The *Modifiers* subsection below lists them.

| Check | Reads | G0 | G1 | G2 | G3 |
|---|---|---|---|---|---|
| **SBOM ingest & drift** (existing) | CycloneDX/SPDX | • | • | • | • |
| **Secrets scan** (existing) | repo | • | • | • | • |
| **Dependency provenance** — lockfile committed, integrity hashes, no build-time range resolution | lockfiles | • | • | • | • |
| **Install-script execution disabled** | ecosystem config | • | • | • | • |
| **800-53 mapped control checks** (existing) | profile/overlay | ○ | • | • | • |
| **Short-form closure** — 23 rows have ADRs | `decisions/` | •‡ | •‡ | •‡ | •‡ |
| **Class-scoped closure** — all `Applies` rows closed | `decisions/` | – | ○ | •‡ | •‡ |
| **One-way door closure** — 28 rows closed before production code | `decisions/` | ○ | •‡ | •‡ | •‡ |
| **Named-approver present** — 8 † rows carry a name | ADR frontmatter | • | • | • | • |
| **Waiver expiry** — no expired waivers | ADR frontmatter | • | • | • | • |
| **Waiver horizon** — none expiring ≤60 days | ADR frontmatter | ○ | ○ | ○ | ○ |
| **Tests accompany source changes** — a change touching source also touches tests | changed-file set | ○ | ○ | ○→•‡ | ○→•‡ |
| **Adoption horizon** — no newly-owed row expiring ≤60 days | `system.json` + spine | ○ | ○ | ○ | ○ |
| **Standard currency** — pinned standard not stale | `.causeway-lock` | ○ | ○ | ○ | ○ |
| **As-built notification** — declared exposure carries a notified name | ADR frontmatter | • | • | • | • |
| **Composition state declared** | `system.json` | • | • | • | • |
| **Sandbox tenant assigned** | `system.json` | – | • | – | – |
| **TA valid & unexpired** | TA record | – | • | – | – |
| **Promote-or-sunset** (§5) | TA record | – | • | – | – |
| **Control inheritance resolves** | inheritance graph | – | ○ | • | • |
| **Evidence pipeline emitting** | `evidence/sbom-runs/` | – | ○ | • | • |
| **Contract tests green** | CI | – | – | • | • |
| **DR plan of record exists** | `decisions/` | – | – | • | • |
| **DR drill within cadence** | drill record | – | – | ○ | • |
| **Exposure review current** | catalog record | – | – | – | • |
| **Promotion review current** | catalog record | – | – | – | • |
| **AO signature on SA-5.10** | ADR frontmatter | – | ○ | ○ | • |

Two things worth noticing in that table. The security floor blocks at *every*
profile — secrets, SBOM drift, dependency provenance, install-script execution,
named approvers, waiver expiry, as-built notification — and even a
citizen-developer sandbox app cannot get under it. And the one-way-door check is
`○` at G0 rather than `–`: a sandbox app sees the finding, it just isn't stopped
by it.

### Modifiers

A modifier is a stated condition under which a blocking cell files a finding
instead. There are two. Both are marked `‡` in the inventory so the table does not
read as more absolute than the checks are, and both are named in `profiles.json` so
the machine-readable artifact carries what the prose does. A modifier never turns a
finding into a block and never adds a check — that is the property that keeps the
receipt adding up.

| Modifier | Applies to | Downgrades while |
|---|---|---|
| **Adoption horizon** | `shortform-closure`, `oneway-closure`, `class-scoped-closure` | the unclosed row is inside its horizon |
| **Pre-release** | `tests-with-source`, once promoted | the repository has no release tag |

**The adoption horizon** (Decision Spine, *Adoption and version drift*) downgrades
a row that is unclosed *and* still inside its horizon. It is a modifier rather than
a fourth closure check on purpose: a newly-owed row must appear once, in the check
that already owns it, or the same row is counted twice and the receipt stops adding
up.

**Pre-release** downgrades `tests-with-source` while `release_state` is
`pre_release`. New in v0.5, and inert until the promotion in §9 step 8 engages,
since a modifier on a warning changes nothing.

### `release_state` — the lifecycle marker both checks read

`oneway-closure` carried the phrase "before first release tag" from v0.1 to v0.7,
and that term was defined nowhere in this document or the spine. The spine states
the rule — *close every one-way row before writing production code* — and leaves
the gate to resolve it against something on disk, which is the correct seam. What
the gate never did was write down the resolution. v0.5 defined this primitive to
be that resolution, and `tests-with-source` reads it rather than inventing a second
lifecycle concept beside it.

**`oneway-closure` no longer reads it, and v0.8 established that it never did.**
The resolution the gate wrote down was the wrong one: the spine's deadline is
production code, not a release, and this check's blocking column — warn at G0,
block at G1 and above — was already the machine-readable form of it, because a
Tactical Authorization and a sandbox tenant mean a deployed system. The phrase was
a leftover describing a deadline the design layer never set, and `release_state`
appeared in that check's evidence without ever reaching its verdict. Open item 9
asked which half of the gate was right and the answer was neither. See ADR 0034.

So this primitive now has exactly one consumer: `tests-with-source`, whose
promotion genuinely turns on *has this shipped yet*. That was always the reuse
that fit.

**Redefined in v0.7.** Through v0.6 this read annotated git tags and nothing else.
Open item 8 recorded the bypass that follows and set the condition for replacing
it; the condition was met twice, from two directions, and the remedy is below.
See ADR 0033.

```
release_state(repo) -> (state, proof):

    Any one of the following establishes a release. They are ordered by how much
    they prove. First match wins, and the proof is recorded beside the state.

    1. signed-statement   bundle/release.statement verifies against
                          bundle/allowed-signers under the causeway-release
                          namespace and names this commit
    2. annotated-tag      an annotated tag matching
                          ato-gate.json spine.release_tag_pattern
                          (default: ^v?[0-9]+\.[0-9]+\.[0-9]+)
    3. lightweight-tag    a lightweight tag matching the same pattern
    4. platform-record    a release record the platform publishes outside git.
                          No input class supplies this yet — open item 14.

    none of the above:    return (PRE_RELEASE, none)
```

Four properties, and they are why this is a marker rather than a field:

1. **It is derived, never declared.** A team cannot set `pre_release: true` in a
   file it controls. §1's first design rule would make that decorative, and a
   lifecycle flag is precisely the field worth asserting falsely. This survives
   the redefinition intact: every source above is evidence somebody else
   produced, and `spine.release_tag_pattern` names *where an engine looks*, not
   what it finds there.
2. **The evidence is ranked, and the rank is recorded.** A signed statement proves
   a key named in the vendored trust anchor attested this exact bundle. A tag
   proves a label exists in some clone. Both establish a release and they are not
   the same claim, so the receipt carries `release_proof` alongside
   `release_state` — the same vocabulary `.causeway-lock` already uses for the same
   distinction (ADR 0030). A marker that could not say how well evidenced it was
   flattened the strongest evidence in the standard and the weakest into one bit.
3. **Tag topology is not a security property, and v0.6 treated it as one.** The
   old rule read *annotated only* on the reasoning that a lightweight tag is a
   moveable local label. So is an annotated one: `git tag -f` moves either kind,
   the tagger identity in an annotated tag is whatever local config said, and
   `sync.sh` has said in its own comments since v1.8.0 that a tag of any kind is
   "a local, unauthenticated, rewritable label — `git tag v99.0.0` forges it in
   one command." Filtering on annotation excluded real releases and admitted
   forged ones. It was never buying the property it was defending.
4. **It is monotonic in practice, not by construction.** Deleting every release
   tag returns a repository to `pre_release`. Nothing here prevents that. The
   receipt records `release_state` on every run, so the transition is legible in
   the evidence trail even though it is not blocked.

**This defined the term, and deliberately did not change `oneway-closure`'s
behavior.** That check has blocked at G1 and above since v0.1, and v0.5 declined to
touch it on the reasoning that changing a blocking check for every system that has
never released deserved its own decision. That was the right call for the wrong
reason: the question it recorded as open item 9 assumed the check's *row* set a
release-tag deadline. It does not — the spine sets it at production code, in four
places. Item 9 closed at v0.8 as a correction rather than a choice, and the blocking
column it worried about turned out to have been correct since v0.1.

**The bypass this section carried from v0.5 to v0.6 is closed.** It read: *a
system that never tags a release never leaves `pre_release`*, held tolerable
while the untagged G2/G3 set stayed small, and named its own replacement
condition — *if that set turns out not to be small, the marker is wrong for both
checks and should be replaced for both at once.*

The set is not small, and two independent instances say so. `overlays/servicenow.md`
§8 reported the first: a platform that versions applications in its own field has
nothing for an engine to ask git about, so the default there is `pre_release`
permanently and by construction. The second is this repository. Causeway has
published nine releases, every one of them tagged through the GitHub web interface,
which creates lightweight tags and offers no way to create any other kind. By its
own marker the standard has never released, and neither has any project whose
maintainer works in a browser — a population Causeway explicitly serves, since §1's
whole argument about prepared ground is aimed at people who are not going to open
a terminal.

Replaced for both checks at once, as the condition required. What remains open is
narrower and is the fourth source above: a platform that publishes versions outside
git still has no input class an engine can read. That is open item 14, and it is an
input-contract question rather than a marker question — which is the distinction
this replacement was able to draw only after the marker stopped being the problem.

### Adoption horizon — the arithmetic

```
row_status(system, row):
    applies  = spine_version(vendored gate/profiles.json)   # authoritative
    closed   = system.json spine.closed_against             # history, may be absent

    if closed is absent:            return OWED_NOW         # no grace. strictest default.
    if row existed at `closed`:     return OWED_NOW
                                                            # newly owed below
    horizon = 180 if row.one_way else (180 if class == "C1" else 365)
    deadline = release_date(version that added row) + horizon

    if today <= deadline:           return FINDING(deadline)
    else:                           return OWED_NOW
```

Three details decide whether this bites or becomes a way to defer forever:

1. **`applies` is read from the vendored file, never from `system.json`.**
   `gate/profiles.json` is checksummed in `.causeway-lock`, so moving it fails
   `check-drift.sh` before it reaches this function.
2. **The clock is anchored to the revision's release date**, not to the sync date.
   Re-syncing, forking a branch, or re-running CI does not move a deadline — the
   same property `renewal_count` has, for the same reason.
3. **A missing `spine.closed_against` yields no grace.** This is the loud default,
   and the portfolio backfill in §9 step 1 is where the noise gets absorbed.
   Reading a missing field as "current" would make the grace period self-service.

`adoption-horizon-60d` mirrors `waiver-horizon-60d` exactly: surface anything
expiring within 60 days, at every profile, so the deadline arrives as a sequence of
warnings rather than as a build failure nobody saw coming.

### `standard-currency` — age, not distance

A project can pin an old standard and never receive a new row. `check-drift.sh`
does not catch it: it verifies the vendored copy against *its own pin* and never
asks whether the pin is current. Without this check the adoption horizon has an
opt-out consisting of doing nothing, which is the cheapest kind.

The check measures the pinned copy's **age**, not its distance behind the current
release. Age is computable from `.causeway-lock` alone — no network, no upstream
reference, no assumption that the standard's repository is reachable. That matters
because a large share of this work targets environments where it isn't, and it is
the same constraint that made ADR 0001 reject both submodules and package-manager
distribution.

`standard_currency_check(lock)`

- Read `released=` from `.causeway-lock`, written by `sync.sh` from the standard's
  `RELEASED` file at sync time.
- **Finding** when `today - released > 180 days`.
- **Configuration error (exit 4)** when `released=` is absent — an old lock
  predating v0.4. Re-syncing writes it.
- It says nothing about *which* version is current, because it cannot know. A
  project 400 days old might be one release behind or six.

Warn-only at every profile in v0.4, unchanged in v0.5. Blocking past 365 days is
the *proposed* destination and is recorded in §9 step 10 and §10 item 5, not
encoded here: the frozen-ATO and air-gapped-release-train cases are legitimate and
nobody has counted them yet. `tests-with-source` took the same discipline and has
now come out the other side of it, so its destination is decided and carried in
`profiles.json` as `promotes_to`. This one has not, which is why it stays prose —
and why the inventory shows it `○` rather than `○→•`. When it does block, §6
exclusions are the escape hatch, dated like every other one.

### `as-built-notification` — why this one blocks

When a revision adds a one-way row to a system already in production, the ADR
closing it states the as-built answer (Decision Spine, *Adoption and version
drift*). Where that answer declares ongoing unrecoverable exposure, the ISSM is
notified and the ADR records it:

```yaml
as_built:
  answer: "Unredacted case records sent to a commercial provider since 2025-12-01."
  exposure: true            # ongoing, unrecoverable
  notified:
    name: "Dana Reyes"      # a person, not a role
    role: ISSM
    date: 2026-08-08
```

`as_built_notification_check(decisions)` blocks when any ADR carries
`as_built.exposure: true` without a complete `notified` block. Unlike the other two
checks added in v0.4, the destination here is known rather than guessed, so it
blocks in the inventory from the start and gets only the §9 warn-only cycle that
every new check gets. The waiver that would excuse it has to read "a live
unrecoverable disclosure is recorded in our decision log and nobody was told,"
which is the same test that made `install-scripts` non-waiverable.

The check verifies that a name and a date exist. It cannot verify that the
conversation happened — nothing file-based can. What it removes is the failure
where the disclosure is written down honestly and then sits in a repository.

### Ecosystem checks — what they read

Both new checks **discover** the ecosystems in play from the manifests present in
the repo. Neither reads a declaration, for the same reason the gate profile is
derived: a posture a team can assert in a file it controls is decorative. The
declaration is the ADR under SA-5.14; these two checks verify it was implemented.

`dependency_provenance_check(repo)`

- Every discovered manifest has a committed lockfile alongside it.
- The lockfile carries integrity hashes for every resolved entry.
- No dependency resolves from a floating range at build time.
- **N/A** when the repo declares no third-party dependencies. Vendored trees
  count as resolved and pass on the vendored content, not on a lockfile.

`install_script_check(repo)`

- npm / yarn / pnpm: `ignore-scripts=true` present in a committed `.npmrc` or
  equivalent, **and** the CI invocation passes `--ignore-scripts` explicitly.
  Both, because either one alone is a single edit away from silence.
- pip: installs resolve to wheels; no sdist executing `setup.py` at install.
- No `curl | sh` or equivalent unverified bootstrap in a build step.
- **N/A** for ecosystems with no install-time execution — Go modules, Maven,
  NuGet. An N/A here is the check reporting that SA-5.14 was answered well.

An `install-scripts` failure is exit code 1 like any other blocking check. It is
not a waiverable finding at any profile: a waiver would have to say "arbitrary
third-party code may execute on our CI runners until a date," and nobody who
reads that sentence signs it.

### `tests-with-source` — what it measures, and what it does not

Build DNA §7 asks for one prompt, one commit. This gate does not check that and
cannot: an agent can produce a single commit from six prompts and nothing in the
diff says so. Commit granularity is a review property, not a CI property, and
asserting otherwise would put a decorative check in the one file whose first
design rule is that nothing here is decorative.

What CI can see is the changed-file set.

`tests_with_source_check(changeset)`

- Partition the changed files into source, test, and neither.
- Generated and vendored paths count as neither, read from the same exclusion
  list the coverage tooling already uses. A regenerated client is not a behavior
  change somebody declined to test.
- **N/A** when no source files changed. Documentation, configuration, and
  dependency manifests on their own do not trip it.
- Subtract from the source set the two mechanically provable non-changes:
  **pure deletions**, and **renames git scores at 100% similarity**. What remains
  is `source_effective`.
- **N/A** when `source_effective` is empty.
- **Finding** when `source_effective` is non-empty and the test set is empty.
- It evaluates the whole proposed change, not each commit. Squashing to satisfy
  §7 must not change the verdict, or the two rules would pull against each other.

**The two subtractions are new in v0.5, and they are why this can promote without
a portfolio cycle behind it.** A pure deletion cannot be accompanied by a test —
nobody writes a test for code they are removing — and a deletion that orphans a
live test fails the suite on its own, which is a better signal than this check
could produce. A 100%-similarity rename is git asserting the content did not
change, so there is nothing to test that was not already tested. Neither exclusion
requires a judgment call, and neither can be gamed without editing content, at
which point the similarity score drops and the file returns to the source set.

Subtract those two and what remains is *source added or modified, no test touched*
— which is the §6 bar restated. That is the argument for promoting this check, and
it is a claim about the check's definition rather than a claim about the portfolio.
v0.3 deferred the promotion to a false-positive rate, and named the three cases that
made the rate uncertain: **pure deletions, dependency bumps, and pure moves.** The
definition above disposes of all three. Dependency bumps were already N/A under the
manifest rule unless they force a source change, and a source change a dependency
bump forces is behavior that owes a test like any other.

**One case survives the tightening, and it is written down here rather than
discovered later.** Moving a file means updating whatever imports it, and those
edits are ordinary source modifications — not deletions, not 100% renames. So a
pure relocation still fires. Separating it from a real change requires semantic
analysis, which is more machinery than this check is worth. How often it happens is
the one number the warn cycle in §9 step 8 exists to produce, and a finding carrying
a non-zero `excluded.renames_100` in the receipt is its signature.

**Blocking behavior.** Warn at G0 and G1 permanently: a sandbox app and a
time-boxed tactical build see the finding and are not stopped by it. Block at G2
and G3, modified by `release_state` — warn while the repository is `pre_release`,
block once it has cut a release. A system still being built has not yet made the
promise this check enforces; a system that has shipped has.

The pre-release modifier reuses the marker `oneway-closure` already reads rather
than introducing a lifecycle field, for the reason in §1. It is also narrower than
either alternative that was available. Pushing the promotion down to G3 alone would
use profile as a proxy for lifecycle, and profile is derived from tier and class —
*where a system lives* and *what its failure costs*. Neither of those is *has this
shipped yet*, and hanging the deferral on them would exempt every mission-tier system
permanently in order to relieve the ones still under construction. A declared flag
would exempt whoever wanted to be exempt.

The promotion is **decided** in v0.5 and **engages** after the warn cycle in §9
step 8. Until then `profiles.json` carries it as `promotes_to` rather than as the
active value, so a project re-syncing to this revision does not acquire a new
blocking check the moment it pulls. Rows get an adoption horizon; checks get a warn
cycle. Shipping a promoted check as immediately active would be the check-shaped
version of the failure ADR 0005 rejected — a revision that blocks a portfolio on
arrival makes revising the standard an act of sabotage.

---

## 5. Promote-or-sunset enforcement

The rule from the spine: **Operational + C1 forces a promote-or-sunset decision
at TA expiry. No third renewal.**

The mechanism is `renewal_count` on the TA record, which the gate reads and the
TA issuance workflow increments. It is enforced entirely in existing surfaces —
no new store, no new service.

```
promote_or_sunset_check(system):
    if tier != "operational" or criticality_class != "C1":
        return SKIP

    n = tactical_authorization.renewal_count

    if n == 0:                       # original authorization
        return PASS

    if n == 1:                       # first renewal
        return WARN(
          "Second TA term. A promote-or-sunset decision is due before "
          "the next expiry. Record it as an ADR and reference it in "
          "tactical_authorization.disposition_ref."
        )

    if n >= 2:                       # second renewal requested or active
        if disposition_ref is null:
            return BLOCK(
              "Third TA term requires a recorded disposition. Either a "
              "promotion record to mission tier, or a sunset ADR with a "
              "date. No further renewals will issue."
            )
        return PASS
```

Three details that make this bite rather than becoming a rubber stamp:

1. **The counter lives on the TA record, not the build.** Rebuilding, forking a
   branch, or re-running CI does not reset it. Only issuing a new TA moves it,
   and that is a TAO action.
2. **`disposition_ref` must resolve to a real ADR** with status `Accepted`, not
   `Proposed`. A promotion plan that has not been accepted is not a disposition.
3. **Sunset is a legitimate disposition.** The rule is not "promote or die" — it
   is "decide." A sunset ADR with a date closes the check cleanly and is often
   the correct answer for a tactical app that did its job.

The warning at `n == 1` is the load-bearing part. By the time a system is
blocked at `n >= 2` it has been told twice, in CI, with the exact remedy named.

---

## 6. Per-system `ato-gate.json`

The gate profile is derived, but per-system tuning still has a legitimate home —
paths, thresholds, and named exclusions.

```jsonc
{
  "spine": {
    "decisions_dir": "decisions/",
    "adr_status_accepted": ["Accepted", "Waived"],
    "waiver_horizon_days": 60,
    // Overrides the default in profiles.json. Matched against annotated tags
    // only. See §4, release_state.
    "release_tag_pattern": "^release-[0-9]{4}\\.[0-9]{2}$"
  },
  "named_approvers": {
    "SA-1.8":  { "name": "...", "role": "Data Owner" },
    "SA-1.9":  { "name": "...", "role": "AO" },
    "SA-2.11": { "name": "...", "role": "AO" },
    "SA-5.7":  { "name": "...", "role": "ISSM" },
    "SA-5.10": { "name": "...", "role": "AO" },
    "SA-5.13": { "name": "...", "role": "AO" },
    "SA-5.16": { "name": "...", "role": "Data Owner" },
    "SA-9.4":  { "name": "...", "role": "Records Officer" }
  },
  "exclusions": [
    { "check": "contract-tests", "reason": "...", "expires": "2026-12-31" }
  ]
}
```

Exclusions carry mandatory expiry dates for the same reason waivers do. An
exclusion without an expiry is a permanent silent downgrade of the gate, which
is the failure mode this whole model exists to prevent.

A system that genuinely cannot re-sync — a frozen ATO, an air-gapped release
train on a fixed cadence — excludes `standard-currency` here, dated, rather than
getting a special case in the check. Needing longer on a *row* is a waiver ADR;
needing longer on the *standard* is an exclusion. Both carry an expiry and a
name, which is the only property that matters.

`tests-with-source` is excludable here on the same terms, and unlike
`install-scripts` the sentence it commits somebody to is one a person can actually
sign: *source changes may ship without accompanying tests until a date*.
Uncomfortable, which is correct, and the legitimate cases are real — most often a
repository whose test suite lives in a different repository, where the check is
measuring the wrong changed-file set rather than catching anything. That this route
is cheap and dated is also what makes the `release_state` bypass in §4 tolerable: a
team that wants relief has an option costing less than never cutting a release.

`release_tag_pattern` is per-system rather than universal because release naming is
a house convention and a gate that only recognizes semver would read a calendar-tagged
repository as permanently pre-release. It is a pattern, not a state: a project can
tell the gate what its releases look like, and cannot tell it whether one happened.

---

## 7. Evidence receipt additions

The receipt written to `evidence/sbom-runs/<timestamp>.json` gains a `causeway`
block, so an AO reading the receipt can reconstruct why the gate behaved as it
did without access to the repo:

```jsonc
"causeway": {
  "tier": "operational",
  "criticality_class": "C2",
  "gate_profile": "G1",           // derived at run time
  "release_state": "released",    // derived at run time — pre_release | released
  "spine_version": "0.7",         // applies — from the vendored profiles.json
  "spine_closed_against": "0.5",  // history — from system.json
  "rows_in_scope": 89,            // C2 scope at spine v0.7
  "rows_closed": 86,
  "rows_waived": 3,
  "rows_in_adoption": 2,          // newly owed, inside horizon. NOT counted as closed.
  "adoption_expiring_60d": 0,
  "waivers_expiring_60d": 1,
  "named_approvers_present": true,
  "standard_age_days": 12,
  "ta_renewal_count": 1,
  "promote_or_sunset": "WARN",
  "tests_with_source": {
    "verdict": "finding",         // pass | na | finding | block
    "reason": "source-without-tests",   // na: no-source | all-excluded
    "source_effective": 3,
    "excluded": { "deletions": 0, "renames_100": 2 }
  }
}
```

This is the artifact that makes the model auditable. The gate's reasoning is
recorded alongside its verdict, dated, immutable.

Both spine versions are emitted because either one alone is misleading. `0.7`
without `0.5` reads as though the system closed against the current spine;
`0.5` without `0.7` hides that a newer one is in force. The gap between them is
the number an AO actually wants, and `rows_in_adoption` is its consequence —
rows this system owes, does not yet have, and is not yet blocked on. They are
deliberately excluded from `rows_closed`: a row inside its horizon is unclosed
with a date, and a receipt that folded the two together would report a system as
complete on the strength of a deadline it has not met.

`release_state` is emitted for the same reason `gate_profile` is. It is derived at
run time and it changes what the run enforced, so a receipt without it cannot be
read back. It is also the portfolio query that keeps the §4 bypass visible: a G2 or
G3 system reporting `pre_release` has never cut a release, which is either a fact
worth knowing or a system worth asking about.

**`tests_with_source` is the counter open item 4 asked for, and it is narrower than
what that item requested.** A receipt cannot produce a false-positive rate. Only a
human reading a specific change can call a finding wrong, and nothing file-based
will ever do that — the same limit `as-built-notification` runs into, stated for the
same reason. What these fields produce is a **fire rate and an exclusion mix**: how
often the check fires, and how much of the changeset the two subtractions accounted
for when it did. That is a weaker instrument and it is useful in one specific way. A
finding carrying a non-zero `renames_100` is the file-relocation case §4 predicts
will survive the tightening. If those dominate, the definition is wrong in exactly
the place the document said it might be, and the remedy is another definitional
change rather than a rollback.

---

## 8. Exit codes

| Code | Meaning |
|---|---|
| 0 | Pass. Findings may exist. |
| 1 | Blocking check failed. |
| 2 | Expired waiver or expired exclusion. Distinct from 1 so dashboards can separate rot from regression. |
| 3 | Promote-or-sunset block. Distinct because the remedy is a governance action, not a code change. |
| 4 | Configuration error — missing tier, unresolvable decisions directory, malformed TA record, a `.causeway-lock` with no `released=` (a lock predating v0.4; re-sync writes it), or a **required check the engine cannot execute** (§11). |

These are the gate's codes and an engine implementing this document emits exactly
them. An engine with its own three-code scheme is not a partial implementation of
this table, it is a different table: the collision that matters is an engine using
`2` for *fatal error* while this document uses it for *expired waiver*, which
inverts the meaning of the one code written to be readable without the report.
Codes 2, 3 and 4 exist so a caller can act on them differently, so an integration
that collapses everything above `1` into a single failure bucket has discarded the
distinction rather than implemented it.

`5` is deliberately unused here. `check-drift.sh` exits `5` on vendored-copy
drift, and it runs before the gate rather than inside it.

**Precedence, when a run triggers more than one.** `4` › `3` › `2` › `1` › `0`.

`4` outranks everything because a run that could not be configured or could not
execute a required check has not evaluated the system, and its other results are
not trustworthy enough to report. The rest descend by how far the remedy sits
from the code: a governance disposition, then expiry housekeeping, then a fix.
Undefined precedence is how two conforming engines return different codes for the
same repository, so it is stated here rather than left to whoever writes the
first `if`.

---

## 9. Implementation order

1. **Add the fields.** `criticality_class`, `criticality_authority`, `spine`,
   and the TA extensions in `system.json`. Backfill `criticality_class` across
   the existing portfolio — expect this to be the slow part, because it requires
   a named human per system, which is the point. **v0.4 adds
   `spine.closed_against` to the same backfill**, and it is the cheaper half: it
   asks which spine version a system closed against, which is a repository fact
   rather than a judgment, and it can be read off the dates in `decisions/`.
   Systems left unbackfilled get no adoption grace and will say so loudly, the
   same way unclassified systems resolve to C1.
2. **Implement `resolve_profile`.** Pure function, trivially testable, no I/O.
   Write the nine-case table as the test.
3. **Emit the receipt block** with everything in warn-only mode. Run it across
   the portfolio and read the results before enforcing anything.
4. **Turn on the universal blockers** at all profiles. Dependency provenance and
   install-script execution are new in v0.2 — run them warn-only for one cycle
   first, because the first pass across an existing portfolio will light up every
   Node repo at once and the remedy is a config change per repo, not a rewrite.
5. **Turn on class-scoped and one-way-door closure** by profile.
6. **Implement promote-or-sunset**, warn stage first, one full TA cycle before
   the block engages.
7. **Wire G3 checks** — exposure and promotion review — last. They depend on
   catalog records that need their own review cadence defined.
8. **Roll out `tests-with-source`.** Decided in v0.5: blocking at G2 and G3, once
   the repository has cut a release. Ship the tightened definition — the two
   subtractions in §4 — warn-only for one cycle first, like every other new
   blocking behavior, then flip `promotes_to` into the active values in
   `profiles.json`. The cycle is **not** deciding whether to promote; §4 settles
   that from the check's definition. It measures one number: how often a finding
   arrives alongside a non-zero `excluded.renames_100`, which is the
   file-relocation case §4 predicts will survive. If that is most of what fires,
   tighten the definition again before engaging the block. Shipping a check that
   fires on relocations is how people learn to route around a gate, and that costs
   more than the check is worth.
9. **Turn on `as-built-notification`** after one warn-only cycle, like every new
   blocking check. It fires on almost nothing today — it needs a retroactive
   one-way row *and* a declared exposure — so the cycle is cheap and its purpose
   is to catch frontmatter-shape mistakes before they block anyone.
10. **Decide `standard-currency`.** Warn-only at 180 days in v0.4. After one
    cycle, either promote it to blocking past 365 days or leave it advisory. The
    number that decides it is how many systems are legitimately frozen, which
    nobody has counted; §6 exclusions are the intended answer for those, and if
    the exclusion list turns out longer than the violation list the check is
    measuring the wrong thing.

Steps 1 and 3 are the whole risk. If the portfolio backfill in step 1 stalls,
the default in §3 means every unbackfilled system resolves to C1 and gets the
strictest gate. That is the correct behavior and it will also be loud.

---

## 10. Open items

**Numbers are stable from v0.5.** A closed item keeps its number and its entry,
marked closed with the resolution — the rule the spine already applies to row IDs,
for the same reason. Renumbering on close is how ADR 0003's pointer to "§10 item 5"
came to reference a different item than the one it closed. Once is enough.

**Item 10 was relocated into this section in standard v1.10.0.** ADR 0009 opened
it and appended it to the end of §11; ADR 0019 and ADR 0023 both amended it in
place, and ADR 0023 described it as keeping "its number per the rule §10 states
for itself" while the item sat two hundred lines outside §10. Anyone who counted
this register got nine. The item keeps its number and its text; only its position
moved. `decisions/open-items.json` is now the thing that counts, and the count is
checked. See ADR 0025.

1. **Who increments `renewal_count`?** Specified here as a TAO action in the TA
   issuance workflow. If TA issuance is not yet a workflow in the engine, this is a
   manual field and the counter is only as trustworthy as the process.
2. **Catalog items themselves.** A catalog item is a system too. Does it get a
   criticality class and a gate profile, or does it inherit the strictest class
   among its consumers? The second is more correct and more expensive.
3. **Portfolio rollup.** The existing tier-stratified dashboards should probably
   stratify by gate profile instead — four buckets rather than three, and the
   buckets map to actual rigor rather than to catalog placement.
4. **`tests-with-source` promotion — closed in v0.5.** Promoted to blocking at G2
   and G3 behind the `pre-release` modifier, decided on the check's definition
   rather than on a portfolio number: the two subtractions in §4 dispose of the
   three cases that made the rate uncertain. The receipt gains a counter, but a
   narrower one than this item demanded — a fire rate and an exclusion mix, because
   a false-positive rate is not something a receipt can compute. The item was right
   that an advisory check with no counter behind it stays advisory by default; it
   was wrong that the counter had to come first. See ADR 0006 and §9 step 8.
5. **`standard-currency` promotion.** See §9 step 10. Same trap item 4 named: an
   advisory check with no counter behind it stays advisory by default rather than
   by decision. Item 4's escape does **not** transfer — its promotion turned on
   tightening a definition until the residual was defensible, and staleness has no
   equivalent subtraction. The number here is how many systems are legitimately
   frozen, and it still has to be counted.
6. **`RELEASED` has no guard — closed in v0.6.** The item was right that the gap
   was upstream of several others, and the fix was the CI it asked for rather than
   the release check. `tools/validate.py` compares `RELEASED` against the last
   commit that touched `VERSION` and fails the build when it has fallen behind;
   the workflow checks out full history so the comparison is possible. The
   best-effort warning in `sync.sh` stays, because it helps a developer before the
   push, but it is no longer the only thing standing between a stale date and
   every consuming project's staleness measurement. The tarball-mirror case the
   item named is now covered too — the guard runs in the repository that
   publishes, not in the copy that consumes. See ADR 0010.
7. **Does the tightened `tests-with-source` definition hold?** §4 predicts one
   surviving false positive: a file relocation whose import updates read as
   ordinary source changes. Nothing has measured it, because the receipt fields
   that would are new in v0.5. The warn cycle in §9 step 8 produces the number and
   the block should not engage on schedule if relocations are most of what fires.
   This is item 4's successor and deliberately narrower — item 4 asked whether to
   promote at all, this one asks whether one named exclusion is missing.
8. **Nothing verifies a release tag was cut honestly — closed in v0.7.** `release_state` reads
   annotated tags, and a system that never tags one never leaves `pre_release`,
   which now defers `tests-with-source`. The receipt makes the anomaly queryable
   and §6 makes the honest route cheaper, but neither is a control. If the "G2/G3
   and never released" set is not small, the marker is wrong for both checks that
   read it and should be replaced for both at once rather than patched for one.

   **The condition is met, and the item stays open.** `overlays/servicenow.md` §8
   answers the question this item asks: on ServiceNow the untagged G2/G3 set is not
   small, and it is not small by construction — `release_state` derives from
   annotated git tags, and a platform that versions applications in its own
   application version field has nothing for an engine to read. The overlay states
   this as its own contribution and has since overlay 1.1; nothing carried it back
   here for three releases, which is the failure `decisions/open-items.json` was
   built to end and did not catch until relations were added to it. By this item's
   own terms the marker is now wrong for both checks that read it. What is left is
   the remedy, which changes what an engine reads and is therefore a decision with
   its own ADR rather than a correction. See ADR 0026.

   **Closed in v0.7.** §4 now reads release evidence rather than tag topology: a
   verified signed statement, an annotated tag, a lightweight tag, or a platform
   record, ranked, with the proof recorded beside the state. The remedy took two
   years of evidence and three releases of carry-back to assemble and eleven lines
   to write, which is the usual ratio.

   A second instance arrived before it shipped and is worth recording, because it
   is the one the overlay could not have found. This repository publishes releases
   through the GitHub web interface, which creates lightweight tags and cannot
   create any other kind — so Causeway's own nine releases read as `pre_release`
   under its own marker. The first instance was a platform with no git. The second
   was a human who does not use a terminal. A rule that excludes both was not
   defending a property; §4 property 3 says which property it turned out not to be
   defending. See ADR 0033.
9. **Is `oneway-closure` blocking pre-release systems it should only warn? —
   closed in v0.8.** The item asked which of two defensible readings was right and
   assumed both were readings of the gate. Neither was. It opens *its row reads 28
   rows closed before first release tag* — and the row does not read that. The
   spine's One-way column and its rule say **before writing production code**, and
   so do `spine.md`'s one-way section, `AGENTS.md`'s Maintainer floor and the
   decision-spine skill. Four statements in the design layer, one contradicting
   phrase in this document's check inventory and in `checks.json`.

   So the block was never firing early. It was answering the spine's deadline, and
   the profile was already the proxy: a system at G1 holds a Tactical Authorization
   and a sandbox tenant, which is what *production code exists* looks like to
   something that reads files. Warn at G0, block above, is that rule compiled.

   Closed as a correction, not a choice, and the correction runs the other way from
   the one the item expected — the question string moved to meet the blocking
   column rather than the reverse. `oneway-closure` now asks *Are all 28 one-way
   rows closed?*, stops declaring `repo-git`, and stops listing `release_state` as
   evidence it never read. No system's verdict changes. Its own last sentence is
   what closed it: *whichever way it resolves, the row and the blocking column
   should say the same thing.* They do now. See ADR 0034.
10. **A digest proves consistency, not authenticity.** v0.6 gives the bundle a
    content digest and writes it into `.causeway-lock`, so an engine can record
    exactly which bytes it evaluated. That is the useful half. The half still
    missing is somewhere trusted to compare it against: a locally recalculated
    digest is exactly what a locally edited copy would also produce, so the value
    proves the copy is internally consistent and cannot prove it is ours. Closing
    it needs a signature over the digest, which needs a key, a holder, a rotation
    policy and a revocation story — none of which should be invented in a gate
    configuration document. The digest is a precondition for signing rather than
    a substitute for it, which is why it shipped first. See ADR 0009.

    **Half-closed at standard v1.8.0.** The signature and the key now exist:
    releases carry a `release.statement` signed with SSH over the digest, and
    `bundle/allowed-signers` is the vendored trust anchor, itself covered by the
    digest so it cannot be swapped silently. A consumer can verify offline with
    no network and no keyring. See ADR 0019.

    The rotation policy and the revocation story still do not exist, and no gate
    requires a consumer to verify. So the item stays open on the half it named
    last: this is somewhere trusted to compare the digest against, without yet
    being somewhere that stays trustworthy when a key is lost. The gate
    configuration version does not move for this note — nothing normative here
    changed, and a version that moves for a status correction empties the field,
    which is ADR 0012's reasoning applied to this document.

11. **No engine has declared its input classes against any platform.** §11 publishes
    the contract and asks an engine to declare which of the 14 input classes it can
    supply. None has. `overlays/servicenow.md` open item 6 has recorded the platform
    half of this since overlay 1.1 and said the finding belonged upstream; there was
    no upstream item to send it to, so it stayed in a document only that overlay's
    readers open. Which classes an engine supplies is a question about the contract
    this section publishes, not about any one platform. Opened in standard v1.11.0
    by ADR 0026.

12. **`expectations.json` cannot say that an engine lacks an input class.** The
    conformance format pins a fixture's expected verdicts and has no way to express
    the case the engine contract makes most interesting: a system whose engine
    cannot supply a required class, where the correct outcome is `unsupported` and
    exit 4 rather than any finding. `overlays/servicenow.md` open item 5 names this
    exactly and calls it a core contribution needing its own ADR — and, like item
    11, had nowhere to send it. It is a conformance-schema decision, and until it is
    made the exit-4 arithmetic in that overlay's §8 is derived from `checks.json`
    rather than observed. Opened in standard v1.11.0 by ADR 0026.

13. **A declared placement and a defaulted one are byte-identical to the gate.**
    §3 resolves the profile from `tier` and `criticality_class` and never reads
    `criticality_authority`, so a system whose sponsor declared C1 and a system
    nobody ever classified produce the same profile, the same rows, and the same
    receipt. The C1 default is correct and is also the loudest thing in the
    configuration, and its loudness is spent silently: nothing can tell the two
    apart, so nothing can count how often the portfolio is running on the default.
    `placement-argued` — `criticality_authority` carries a name and a date, and
    the ADR closing SA-1.1 exists — is the candidate check, and pricing it needs a
    warn cycle, which needs a portfolio that has run the procedure at least once.
    None has; `skills/decision-spine/reference/placement.md` is the procedure and
    shipped in standard v1.16.0 with no check attached, per §9's rule that
    blocking behavior is earned rather than declared. Opened in standard v1.16.0
    by ADR 0032.


14. **A platform that publishes versions outside git has no input class for it.**
    §4's fourth release-evidence source names a platform release record and no
    engine can read one, because no input class supplies it. `repo-git` is git
    metadata by definition and the platform case is the one it cannot cover —
    `overlays/servicenow.md` §8 has described an application version field no
    engine can see since overlay 1.1. Splitting this out is what let item 8 close:
    the marker was wrong for every consumer and is now right for the git-based
    ones, and what is left is an input contract rather than a lifecycle definition.
    It is the same question as item 11 one layer down — that one asks which classes
    an engine supplies, this one asks for a class that does not exist to supply —
    so they are related rather than merged. Opened in gate configuration v0.7 by
    ADR 0033.

    **Narrowed in v0.8.** When this opened, two checks read `release_state` and one
    of them blocked at G1 and above, so a platform with no git was locked out of
    `oneway-closure` — a check about whether ADRs exist in `decisions/` — by an
    input it never used. Item 9's closure removed that: `oneway-closure` declares
    neither `repo-git` nor `release_state`, and a platform with no git can run it
    on `repo-decisions` and `system-record` alone. What is left needing a platform
    release record is `tests-with-source`, which warns at all four profiles and
    whose promotion has not engaged. The item is the same question and it is no
    longer on anybody's critical path, which is the difference between owed and
    urgent. See ADR 0034.

**Closed in v0.4: `spine.version` drift.** Item 4 through v0.3, carried unratified
since Decision Spine v0.4. The standing recommendation — forced at the next TA
renewal or promotion — did not survive being read against §4: `ta-valid` and
`promote-or-sunset` run at G1 only, so it reached about a quarter of the portfolio
and never reached G3, core tier having nothing above it to be promoted into.
Replaced by the adoption horizon in Decision Spine v0.7 and the three checks added
here. See ADR 0005.

It carries no number in the list above because v0.4 closed it by renumbering, which
is the practice the note at the top of this section ends. Left as prose rather than
retrofitted into a slot, since inventing a number for it now would be a third
numbering scheme in three revisions.

---

## 11. The engine contract

Everything above describes behavior. This section describes the artifact an
engine consumes to produce it, and what happens when the engine and the standard
disagree about what is possible.

The standard does not execute. It never has — §1's second design rule says the
gate reads files, and something else has to do the reading. Until v0.6 the
handoff to that something else was prose: this document named an engine in its
header and left a reader to infer the rest. That is a contract in the sense that
a conversation is a contract.

### What the standard publishes

Three machine-readable artifacts, vendored and checksummed like everything else.

| Artifact | Answers |
|---|---|
| `gate/profiles.json` | Where each check blocks. Resolution matrix, blocking matrix, modifiers. |
| `gate/checks.json` | What each check means, what input it needs, what evidence it owes. |
| `bundle/manifest.json` | Which exact bytes of the above a given evaluation ran against. |

`checks.json` is the new one and it carries the part that was never written down:
for each of the 27 checks, a stable id, the question it answers in a sentence, its
applicability rule, its waiver eligibility and form, the evidence keys it
contributes to the receipt, its control mappings, its spine rows, remediation
text, the version that introduced it, and an **engine contract number**.

The stable id is the contract. `named-approvers` means one thing forever. An
engine maps that id to whatever code it likes; the standard neither knows nor
cares what language it is written in. This is what lets the standard be
implementation-independent without being unimplementable.

### Input classes, and why the handshake is not per-check

The obvious capability handshake is a list: the engine declares which check ids it
supports, the standard compares. It works, and it makes every new check a
negotiation — the standard adds `dr-plan-of-record`, every engine declares it,
nothing about the engine actually changed because it could already read
`decisions/`.

`checks.json` declares **input classes** instead. Each check names what it must be
able to read: `repo-decisions`, `repo-manifests`, `repo-changeset`, `system-record`,
`ta-record`, and nine others. An engine declares the classes it can supply.

```yaml
engine:
  name: example-engine
  version: 0.9.0
supports_input_classes:
  - system-record
  - gate-config
  - sbom
  - baseline
  - ta-record
  - catalog
  - evidence-store
  - repo-lock
  - repo-decisions
  - repo-tree
  - repo-manifests
```

That engine can execute every check reading only those classes, including checks
written after it shipped. It cannot execute `tests-with-source`, because it does
not declare `repo-changeset`. The gap is legible before anything runs, it is
stated in terms of a capability rather than a list, and closing it once unlocks
every check that reads the changed-file set rather than one.

The classes also make the largest integration cost visible at the top rather than
at the bottom. Seventeen of the 27 checks read one of the six `repo-*` classes.
An engine evaluating portfolio records and SBOMs is not most of the way to
executing this standard, whatever its check count suggests, and an input-class
declaration says so in one line.

### `unsupported` is not a warning

When a check is **blocking at the resolved profile** and the engine cannot supply
one of its input classes, the result is:

```
unsupported-required-check  →  exit code 4  →  deployment blocked
```

Exit 4 rather than 1 because nothing was evaluated and nothing failed. The remedy
is to upgrade the engine or pin a standard the engine can execute — a
configuration action, which is what code 4 has always meant. Reporting it as a
finding would let a profile silently outrun its engine, which is the specific
failure this section exists to prevent: a new blocking check arrives, no engine
implements it, and every system reports clean.

Where the check is **advisory** at the resolved profile, `unsupported` files a
finding and records the missing class in the receipt. An engine that cannot run an
advisory check has not blessed anything.

### Version compatibility

A profile may declare `min_engine_contract` per check. The engine declares a
contract number per check it implements. A mismatch is `unsupported`, resolved by
the rule above.

Contract numbers move when a check's **meaning** changes, not when its
implementation does. `composition-state` moved to contract 2 in standard 1.6.0
because its valid value set changed (ADR 0008); an engine reporting contract 1 is
reading the old answer set and will pass a system the standard now fails. Fixing a
bug in how a check parses a lockfile does not move the number.

### What the engine owes back

One artifact: the receipt in §7, extended with the fields this section makes
possible — the bundle digest it evaluated against, its own name and version, its
declared input classes, and per-check `engine_contract`. A receipt without those
cannot be replayed, because nothing in it says what was actually run.

The receipt is the whole of the return contract. The standard has no opinion on
dashboards, briefing packs, OSCAL export, or ticketing, and it should not acquire
one — those are engine concerns built on top of the receipt, and an engine that
does them well is why this separation is worth having.
