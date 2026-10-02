---
adr: "0011"
title: Reconcile the ServiceNow overlay, and make overlay staleness a build failure
status: Accepted
date: 2026-08-10
spine_rows: [SA-3.13, SA-8.8]
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

`overlays/servicenow.md` was ratified against Decision Spine v0.7 and gate
configuration v0.5. Two releases later the spine is v0.8 and the gate
configuration is v0.6, and nothing in the repository noticed. The overlay was
shipping, vendored, checksummed and digested into the bundle, describing a
version of core that no longer exists.

Two core changes reached into it.

**Spine v0.8 corrected SA-3.13's answer set** (ADR 0008). The overlay's row note
read *a Store app you configured is `wrapped`, not `greenfield`* — written against
the correct vocabulary while the spine row was still wrong, which ADR 0008 cites as
independent evidence that the row was the outlier. Once the row moved, the note was
arguing against a value that no longer exists, and it left the platform's real
hazard unsaid: ServiceNow supplies two things called a catalog — the Service
Catalog and the Store — and neither is the catalog `catalog-composed` means.

**Gate configuration v0.6 published the engine contract** (ADR 0009), which is the
change that actually mattered here. Checks now declare the input classes they must
be able to read, and a required check whose class an engine cannot supply resolves
to `unsupported`: exit 4, blocked, nothing evaluated. The overlay had already found
this consequence and understated it, as a footnote about two checks that "cannot
read an update-set-only repository." Under the contract it is not two checks. Six
of the fourteen input classes are `repo-*`, ServiceNow artifacts are rows in `sys_*`
tables, and update-set-only delivery leaves an engine unable to supply five of the
six — all six where there is no repository at all. Ten of the 16 checks blocking at
G2 read one. Seven of the nine at G0 do.

Reconciling also surfaced three counts in core prose that were wrong at v1.6.0:
`README.md` and `gate-configuration.md` §11 both quantified the repository-reading
checks at 14 where `checks.json` says 17, and §11 described the input classes as
five named "and eleven others" where there are nine. The numbers were true of a
draft inventory and nothing recounted them when checks moved — the same failure
mode as ADR 0008, one layer up.

## Decision

The overlay is reconciled and becomes version 1.1, ratified against spine v0.8 and
gate configuration v0.6. **No row's disposition changed and the published counts
are unmoved** — the containment rule in `overlays/README.md` still reads zero rows
added, retired, or reclassified.

What changed is what the overlay says about core:

- SA-3.13 carries the corrected answer set and names the catalog collision. §7's
  Build DNA translation says the same thing where a reader looking for process
  rules will find it.
- §8 gains an input-class map — what supplies each of the fourteen classes on this
  platform, with source control and without — and the profile-by-profile arithmetic
  of what an instance-only engine cannot execute.
- §8 records that `release_state` derives from annotated git tags, which a
  ServiceNow shop does not cut, so this platform sits at `pre_release` by
  construction. Core names that bypass and holds it acceptable while the untagged
  set stays small; the overlay supplies the evidence that here it is the norm.
- §6 and open item 1 carry the sharpened SA-8.8 case. It remains an open item. An
  overlay may not change a one-way flag, and this one still does not.
- Open items 5 and 6 record what nobody has verified: no conformance fixture is
  ServiceNow-shaped, and no engine has declared its input classes against this
  platform.

The prose counts in `README.md` and `gate-configuration.md` §11 are corrected to
17 and nine.

**`validate.py` gains two sections.** §13 ties every overlay to the spine: it
dispositions each row exactly once and no invented ones, its published totals match
its own table, and the versions in its header match the spine and gate
configuration the standard actually ships. §14 derives the three prose counts from
`checks.json`. Both fail the build.

Version 1.6.1. Patch, because no consumer owes anything new — no row, no check, no
threshold moved. The version moves at all because the overlay is inside the digested
bundle, and two copies of different bytes calling themselves 1.6.0 is the thing the
digest exists to prevent.

## Alternatives considered

**Reconcile the text and skip the guards.** Rejected on the evidence in front of
us. The overlay went stale silently across two releases; nothing about doing it by
hand this time makes the next reader more likely to catch it. ADR 0010's argument
applies unchanged — a rule the standard states about itself and does not check is a
rule it discovers broken later.

**Warn on overlay staleness rather than fail.** Rejected. A warning in a CI job
nobody reads is how the current gap persisted, and it is the same shape as the
`unsupported`-as-warning failure that gate configuration §11 exists to prevent.
Reconciliation is cheap when a release forces it: most core revisions change no
disposition and the work is confirming that and moving a header.

**Let the overlay assert the SA-8.8 one-way flag, since the arithmetic now
supports it.** Rejected, and it is worth recording that the temptation got
stronger. The containment rules are what keep an overlay from forking the spine,
and they do not have an exception for a platform whose evidence is good. The
finding goes upstream as open item 1 with its numbers attached.

**Bump the minor version.** Rejected. Every release so far has been a minor bump
because every release so far added an obligation. This one does not, and spending
1.7.0 on a reconciliation would make the version number stop carrying information.

## Consequences

Overlays are now load-bearing on the release. A spine or gate configuration bump
fails the build until every overlay's header moves, which forces the question *did
this change a disposition* at the moment someone can still answer it cheaply. That
cost is real and it is the point: the alternative is what just happened.

The ServiceNow overlay's central finding is now the engine contract rather than the
disposition table. §2's headline — the platform decides far less than it builds —
still holds, but the thing a shop most needs to check before adopting is whether
its delivery model lets an engine read it at all. Adoption step 6 exists for that
and is deliberately placed before wiring the definition of green.

Three prose counts in core are correct and stay correct. The guard that keeps them
that way is prose-shaped, so a rewrite of those sentences will fail the build until
the regex moves with them. That is a known cost and a small one against a number
that was wrong in two documents at once.

Writing a new overlay now costs a `validate.py` run rather than a careful read. The
Power Platform overlay `overlays/README.md` contemplates inherits the guards on the
day it lands.

## Evidence

`./tools/validate.py` — 364 checks, including 13 new ones across §13 and §14. Each
new guard was confirmed to fail on a seeded defect: a stale header version, a
dropped disposition row, a mis-published count, a drifted prose count, and an
`overlays/README` row out of step with the overlay it lists.

`./tools/build-bundle.sh` — regenerated; the bundle digest moves with the overlay's
bytes.
