---
adr: "0052"
title: Configure from a page built from .env.example — vendor the setup tool, and make the four field lessons rules
status: Accepted
date: 2026-10-17
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A second adopter reports the page unusable on its desktop or its stack, or
  reports that the Makefile-help convention the target list depends on does not fit
  how it documents targets. Either is Build DNA open item 11's evidence, and the
  second says the target list needs its own declaration rather than a convention.
approver:
  name: Karl Deiotte
  role: Maintainer
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

Every project the standard has touched tells a new person the same thing on day
one: copy `.env.example` to `.env`, then go and edit it. The instruction is
cheap to write and expensive to follow. The person following it has not read the
codebase, does not know which of thirty values matter today, and cannot tell a
dev default that is fine from one the README says to rotate. Build DNA §7 says
constraints go in the file, not in the chat; the configuration contract was in
the file and the act of satisfying it was still a chat — with a README, with a
colleague, or with the maintainer.

The first adopter's sponsor put it less politely: *I'm sick of "go edit your env
shit". When I run the service, I want a page where I enter the values. It's a
function of config, setup, run.* That is a requirement, and it is the same
requirement §6 makes of tests: the project does the thing, it does not describe
the thing.

The adopter built it in its own repository first, as `tools/setup/`, and used it
for real before anything moved here. Three workshop runs by the sponsor, each
one on a machine the author never saw, produced four failures that were each a
rule nobody had written down:

1. `sudo make setup` launched a browser as root with no desktop session; it
   crashed in a loop and the one line that mattered, the URL, scrolled away.
2. The `.env` it wrote belonged to root, mode 600; the person who typed the
   command could not read their own file.
3. A fresh unpack got fresh secrets from the page while docker still held the
   previous run's volumes, named after the compose project rather than the
   folder. The identity provider died at startup with the old database password
   and nothing said why.
4. The clean the page offered loaded the base compose file alone, so `down -v`
   left the demo overlay's databases behind with their old passwords, and four
   nodes died at their first database login.

None of these is specific to that project. All four are what happens when a
person runs any compose-based project the way a person does. That is the
evidence this record rests on, and it is one project's.

## Forces

- **The contract already exists.** `.env.example` is, in every project that has
  one, the documented list of every value the stack consumes. A tool that reads
  it has nothing to maintain; a tool that keeps its own list has a fork of the
  contract, and §3 says what happens to forks. This decided the design: the page
  is built from the example file, and from nothing else.
- **No second list anywhere.** The same force applies to the targets the page
  runs. A project's Makefile already documents its targets with `## help`
  comments; the page reads those. A project that wants fewer, or in another
  order, says so in one variable in the same file.
- **Nothing installed, nothing leaves the machine.** The tool is stdlib Python,
  binds to the loopback address only, and requires a per-session token on every
  write. §5's registry rule and §6's offline rule both hold; a setup tool that
  needed `pip install` on the machine being set up would have failed the person
  it was for.
- **CI must not notice.** There is no terminal in CI, so there is no page; the
  example is copied as before and the build is unchanged. A tool that changed
  what CI does would be a different decision with a different blast radius.
- **The rules came from the field, not from design.** Each of the four items in
  the context is a fix for something that happened. That is the right provenance
  for a rule in this document and the wrong sample size for a default, which is
  why Build DNA open item 11 exists alongside the rule.

## Decision

Build DNA §6 gains *Configure, set up, run — one page, not a file hunt*. A project's
`.env.example` is its configuration contract and the only one. The first run opens
a local page built from it; secrets are generated, not pasted; Save writes `.env`;
the same page runs the project's documented `make` targets and shows docker's own
view of the stack coming up. Stale state is named before it bites, and the
project's `clean` deletes every volume of the compose project, overlays included.
A setup path that cannot be followed — as root, over SSH, with no desktop — is a
bug in the tool, not an error by the person.

`tools/setup/` ships with the standard and is vendored into every project by
`sync.sh`: `setup.py`, `env_schema.py`, their two test files and the README that
says how to wire the Makefile. All five are in the bundle digest, so a project
that edits its copy is told so by `check-drift.sh`, the same as every other
vendored tool. The tool reads `.env.example`, `.env` and the Makefile and nothing
else. The standard's own CI runs its tests.

## Alternatives considered

- **Leave it in the README.** "Copy and edit" with better prose. Rejected: the
  evidence is that the prose was already fine and the person still could not
  follow it on a machine the author had not seen. A description is not a
  function of the build.
- **A terminal wizard.** Prompts in the shell, no browser. Rejected on two
  counts: the sponsor's requirement was a page, stated three times; and a wizard
  cannot show a stack coming up or offer a clean before a save, which turned out
  to be where the failures were.
- **A secrets manager, or vault injection.** The right answer for a deployment
  and the wrong one for a developer's first run, which is the moment this
  decision is about. §5 keeps the vault for runtime; nothing here changes that.
  The page writes one gitignored file on one disk.
- **A per-project page.** Let each project build its own. Rejected: the first
  adopter's page already reads nothing project-specific, and the four field rules
  are not project-specific either. A second project would rediscover all four.
- **Declare the target list in a config file.** A JSON or YAML list of the
  targets the page may run. Rejected for now: the Makefile already documents its
  targets, and a second file is a second list. `SETUP_TARGETS` in the Makefile
  covers a project that wants fewer; a project whose Makefile documents nothing
  gets an empty run card, which is honest. Open item 11 names this as the case
  that would reopen it.

## Consequences

Easier: a new person configures any project that vendors the standard from one
page, with secrets generated, and the first thing that would have failed is
named before it does. A project adds a variable to its example and is done.

Harder: a project's `clean` target now carries an obligation — delete every
volume of the compose project, overlays included — that the first adopter's did
not meet until its third field run. The README says how. The Makefile-help
convention is now load-bearing for the run card; a project that documents
targets another way sets `SETUP_TARGETS`.

Committed to: five more files in the bundle (34 → 39), vendored and digested;
their tests in the standard's CI; and the evidence obligation in Build DNA open
item 11, which this record opens.

## Revisit if

A second adopter reports the page unusable on its desktop or its stack, or that
the Makefile-help convention does not fit how it documents targets. The first is
the evidence item 11 waits on; the second says the target list needs a
declaration rather than a convention.

## Evidence

- `tools/setup/` in this repository; `tools/sync.sh` VENDORED, `tools/build-bundle.sh`
  BUNDLE_FILES and `tools/build-archive.sh` ARCHIVE_FILES name all five files.
- `.github/workflows/standard.yml` runs `tools/setup/test_*.py`.
- The first adopter's record: DISE pull requests #143 (the page and the realm
  placeholders it made possible), #144 (root and the browser; the `sudo`
  hand-back), #145 (volumes from a previous run; the seed's own field failure),
  #146 (`clean` and overlay volumes). Each carries the field report that caused it.
