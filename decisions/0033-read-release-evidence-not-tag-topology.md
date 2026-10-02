---
adr: "0033"
title: Read release evidence, not tag topology
status: Accepted
date: 2026-09-19
spine_rows: []         # redefines a gate input; closes no design-layer row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A platform release record gains an input class and the fourth evidence
  source becomes readable — at which point the ranking should be re-read against what
  engines actually supply, rather than against what the standard can name.
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

`release_state` decides whether a repository has released. Two checks read it —
`oneway-closure`, whose row is literally *closed before first release tag*, and
`tests-with-source`, whose decided promotion to blocking at G2/G3 is gated on it —
and the `pre-release` modifier downgrades both from block to warn while it reads
`pre_release`.

Since v0.5 it has been defined as: *annotated tags matching the release pattern*.
Annotated only, on stated reasoning — *a lightweight tag is a moveable local label;
an annotated tag carries an author and a date and is what a release process
produces.*

Open item 8 has carried the bypass that follows ever since, along with the exact
condition for replacing it: *if the untagged G2/G3 set turns out not to be small,
the marker is wrong for both checks and should be replaced for both at once.*

**The condition was met twice, from directions that do not overlap.**

`overlays/servicenow.md` §8 reported the first at overlay 1.1: a platform that
versions applications in its own field has nothing for an engine to ask git about,
so the default there is `pre_release` permanently and by construction. That finding
sat in a document only that overlay's readers open for three releases; ADR 0026
built the relation vocabulary that carried it back, and item 8 recorded it as met
while leaving the remedy owed.

The second arrived in this repository, and it is the one the overlay could not have
found. Causeway has published nine releases. Every tag is lightweight, because they
are cut through the GitHub web interface, which creates lightweight tags and offers
no way to create any other kind — the same is true of GitHub Desktop, and the
feature request to change it is years old. So by its own marker, **the standard has
never released.** Neither has any project whose maintainer works in a browser.

That population is not incidental to Causeway. §1's entire argument about prepared
ground is aimed at people who are not going to open a terminal, the ServiceNow
overlay exists because citizen development is a first-class delivery model, and
`release_state` quietly excluded all of them from ever leaving `pre_release`.

## Forces

- **The condition item 8 set was met, and the remedy it required was named.**
  *Replaced for both checks at once rather than patched for one.* Not a judgment
  call this ADR had to make — a debt the register had already priced.
- **The rule was not buying the property it was defending.** `git tag -f` moves an
  annotated tag as easily as a lightweight one, and the tagger identity inside it
  is whatever local config said. `sync.sh` has said this in its own comments since
  v1.8.0: *a tag is a local, unauthenticated, rewritable label — `git tag v99.0.0`
  forges it in one command.* Annotation is metadata, not authentication. The filter
  excluded real releases and admitted forged ones.
- **The strongest evidence in the standard was not consulted at all.** Since v1.8.0
  a release carries an SSH-signed statement over the bundle digest, verifiable
  offline against a vendored anchor. `release_state` ignored it and read tag shape
  instead.
- **ADR 0030 already made this exact argument, one field over.** It found
  `--require-release` deriving release identity from `git describe` while the
  signature sat unread, and recorded the diagnosis as *the weaker proof was the
  mandatory one... that ordering was chronology rather than a decision.* The same
  sentence describes `release_state` without changing a word. Fixing one and not
  the other was an oversight, not a distinction.
- **The cost of fixing it is at its historical minimum.** No engine implements
  `repo-git`. The only engine lists it unsupported, so `oneway-closure`
  reports `unsupported` and `release_state` is computed by nothing, anywhere.
  Every day this waits, the change gets more expensive and never gets more correct.

## Decision

`release_state` returns a state **and a proof**, and establishes a release from any
of four sources, ranked by how much each proves:

| Proof | Reads |
|---|---|
| `signed-statement` | `bundle/release.statement` verifies against `bundle/allowed-signers` under the `causeway-release` namespace and names this commit |
| `annotated-tag` | an annotated tag matching `spine.release_tag_pattern` |
| `lightweight-tag` | a lightweight tag matching the same pattern |
| `platform-record` | a release record published outside git — **no input class supplies this**, open item 14 |

First match wins. The receipt records `release_proof` beside `release_state`, using
the vocabulary `.causeway-lock` already carries for the same distinction (ADR 0030).

`annotated_only` is removed from `gate/profiles.json`. The `repo-git` input class
now reads tags of either kind. Item 8 closes; item 14 opens for the platform case,
related to item 11 rather than merged with it.

## Alternatives considered

**Drop `annotated_only` and stop.** Three lines, and it would have unblocked every
browser-based maintainer including this repository's. Rejected because item 8's own
terms forbid it: *replaced for both at once rather than patched for one*, and a
patch that fixes the git-based half leaves the ServiceNow half exactly where overlay
1.1 found it. It would also have left the signed statement unread for a third
release, which is the part that has been wrong longest.

**Keep the requirement; ship a `workflow_dispatch` release workflow.** A Run-workflow
button creates a genuine annotated tag through the API, entirely in a browser, and
nothing in the standard changes. Rejected on what it concedes: it makes every
consumer build a tool to satisfy a rule that was not defending a property, and it
does nothing for a platform with no git. Tooling around a wrong requirement is how a
wrong requirement survives. The workflow may still be worth having — it is just not
the answer to this.

**Let a system declare its release state.** Cheapest for every consumer and
immediately fatal: §1's first design rule is that a marker a team can assert in a
file it controls is decorative, and a lifecycle flag is precisely the field worth
asserting falsely. Naming *where to look* stays declarable, which is what
`spine.release_tag_pattern` has always been and what `platform-record` will be.

**Invent the platform input class now.** It would close item 8 completely rather
than splitting it. Rejected because nobody has run it: what a ServiceNow application
version field looks like to an engine is unknown to this document, by the overlay's
own admission, and an input contract written against an imagined artifact is the
defect `unsupported` exists to prevent. Declared as a gap with an item, per §8.

## Consequences

**Major, and this is what makes it major.** A conforming engine that read annotated
tags no longer conforms. A project whose release was invisible may now read
`released`, which withdraws the `pre-release` modifier and lets `oneway-closure`
block where it previously warned. Nothing about that is cosmetic, and the version
says so.

**Live impact today is zero**, and the two facts are not in tension. No engine
implements `repo-git`, so no receipt anywhere currently carries a `release_state` this
changes. The contract moved; no verdict did. That is the entire argument for doing it
now rather than after the first engine ships one.

**The warn cycle belongs at implementation, not here.** §9 requires one before new
blocking behavior engages, and a consumer will experience a check that warned and
now blocks. But no check was added, no profile cell moved, and no threshold changed
— an input was corrected, and the block that follows is the behavior `oneway-closure`
has specified since v0.1 finally reaching the systems it always described. The
obligation lands on the first engine to implement `repo-git`: ship it warn-only for
one cycle. Stated here because that engine will read this document and not this
paragraph's absence.

**Causeway can now describe its own releases.** Nine of them retroactively, which is
a small thing and worth naming, because a standard whose own marker said it had
never shipped was going to keep producing findings like this one.

## Revisit if

A platform release record gains an input class. The ranking above was written
against what the standard can *name*, and the fourth row is currently a name with
nothing behind it; once an engine actually supplies one, the order deserves
re-reading against what engines supply rather than against what this document can
imagine.

## Evidence

`gate/gate-configuration.md` §4 (`release_state`, four properties, the closed
bypass) and §10 items 8 and 14. `gate/profiles.json` `release_state.evidence` and
the removal of `annotated_only`. `gate/checks.json` `repo-git`.
`overlays/servicenow.md` §8 and open item 3, re-ratified at 1.11 against gate
configuration v0.7. `decisions/open-items.json`.
