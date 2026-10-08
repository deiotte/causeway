# Changelog

Every release of the Causeway standard, newest first.

This file exists because a consumer deciding whether to re-sync had no way to
answer *what changed since the release I pinned* without reading every ADR in
`decisions/` and a git log. `check-drift.sh` tells a project that its copy moved; it does not
tell anyone what moving would cost. That is the question this file answers.

**What a version number means here.** `VERSION` is the release number of the
whole bundle and moves whenever anything in it moves. Build DNA, the Decision
Spine, and the gate configuration each carry their own version and move only
when their own content does — ADR 0012 decoupled them deliberately, so three
numbers advancing independently inside one release is the design and not drift.
Each entry below names all four where they moved.

**Compatibility.** A major bump changes what a conforming engine or a pinned
project owes. A minor bump adds content or capability without changing check
semantics, input contracts, verdicts, or the profile matrix. A patch bump
corrects the artifacts without changing what anyone owes.

Entries before v1.9.0 were reconstructed when this file was introduced. Each
change is placed by the value of `VERSION` at the commit that introduced it,
which is why a few land one release from where their own ADR text guesses. They
are accurate about what shipped and are not the release notes that were written
at the time, because none were.

---

## v2.9.0 — 2026-10-08

When a constraint changes, a project can find the decisions that rested on it. Minor —
one more vendored tool; no check, input contract, verdict or profile moved, and nothing
anyone owes changes. Build DNA stays at 1.13, the spine at 0.8, the gate configuration at
0.8. The bundle grows from 31 to 32 files.

- **`tools/impact.sh <ID>...`,** vendored into every project. Read-only, offline,
  advisory. It follows the references a project already records — ADR `forces` and
  `survey_rows`, and the Survey's Forces, Binds, Depends on and ADR columns — and lists
  each ADR a changed row reaches, labelled **direct** (cited, or reached through a `DEC-`
  row that cites or is bound by it), **indirect** (from a decision that depends on an
  affected one) or **inferred** (mentioned in text only — uncertain). Every entry says
  why, and shows the ADR's status and `revisit_if`. A superseded ADR points at the record
  in force; a corrected one names its correction. `--json` prints `causeway-impact-v1`.
  #17, ADR 0049.
- **`--check`** lists references that point nowhere — a force or `DEC-` row the Survey
  does not have, an ADR number not on disk — and counts accepted ADRs with no structured
  reference, which is how much of the record the tool cannot see.
- **It decides nothing.** No ADR is superseded or edited. The Survey skill says what to do
  with the list: read each ADR against the new constraint, and supersede what no longer
  holds with an S1 ADR. The ADR template's `revisit_if` comment says where it is shown.
- **`tools/test-impact.sh`, 23 cases,** run in CI and the release gate, built on a worked
  example: one constraint reaching five decisions at three levels through every kind of
  reference, and an unrelated constraint reaching only its own.

## v2.8.0 — 2026-10-08

A project can see who owes which practitioner an answer. Minor — one more vendored
tool and more header fields in the field-note template; no check, input contract,
verdict or profile moved, and nothing anyone owes changes. Build DNA stays at 1.13,
the spine at 0.8, the gate configuration at 0.8. The bundle grows from 30 to 31 files.

- **`tools/field-notes.sh`,** vendored into every project. Read-only, offline,
  advisory. It lists every open note (new, in-review, or reopened) oldest first with
  its age, owner, next action and source, and names every problem: a disposition with
  no recognised outcome, no `landed_at` or no date; an author not recorded as told, or
  recorded with no evidence of the telling; a note reopened after its disposition and
  still marked closed; an unreadable header or unknown status. It counts open,
  overdue, unassigned, disposed, median days to disposition, authors told with
  evidence, and reviewer minutes. `--json` prints `causeway-field-notes-v1`. #16, ADR 0048.
- **Overdue is the project's call.** `.causeway/field-notes.json`
  (`{"respond_within_days": 14}`) or `--target-days`. With no target there is no
  overdue, only ages.
- **The field-note template's header carries the reviewer's half:** `owner`,
  `next_action`, `disposition` (outcome, landed_at, date), `author_told` (date and
  evidence), `effort_minutes`, `reopened`, and an optional `source` for notes that
  arrived as issues. The prose Disposition block now holds what the author should
  read. Notes written before v2.8.0 are still read from their prose block.
- **`doctor.sh` gains one line,** `feedback.field_notes`: incomplete when notes exist
  and no target is chosen, or when any are late or carry a disposition problem.
- **The field-note skill, the field-notes README and ADOPTING.md** say how to record a
  disposition, reassignment and reopening, and where the numbers come from. A note
  stays an input: nothing writes it into the open-items index.
- **`tools/test-field-notes.sh`, 26 cases,** run in CI and the release gate.

## v2.7.0 — 2026-10-08

A project can see whether its placement was declared or defaulted. Minor —
`doctor.sh` reports more, and the placement procedure says what it reads; no check,
input contract, verdict or profile moved, and nothing anyone owes changes. Build DNA
stays at 1.13, the spine at 0.8, the gate configuration at 0.8. The bundle digest moves
because `VERSION`, `doctor.sh` and `placement.md` do.

- **`doctor.sh` names the placement state:** `declared` (a class and a complete
  authority), `asserted` (a class, no complete authority), `defaulted` (no class, so C1),
  or `tier-missing`, `tier-invalid`, `class-invalid`. It is in the report and in
  `--json` as `placement.state`. #15, ADR 0047.
- **It looks for the argument:** an accepted ADR listing SA-1.1, and one listing SA-1.14,
  in `spine_rows`. A superseded one does not count. The declaring role must be one of
  PO, Service Owner, Customer or Sponsor, and the date may not be in the future.
- **It checks the records agree:** `system.json` against the placement block in
  `CLAUDE.md`, and an unfilled block is reported.
- **It reads reclassification from git history.** A raise passes. A lowering is incomplete
  unless the current declaration is newer, names the same authority, and an accepted
  SA-1.1 ADR is dated on or after it. A first class after the default is not a lowering.
  A lowered tier is `unverified`: the catalog moves tiers, and doctor cannot see it.
  Without git, reclassification is `unverified`.
- **It says what a name is:** a recorded assertion of who declared it, never an
  authentication of their approval.
- **The placement procedure, the contributor starter and ADOPTING.md say so too,** and
  ADOPTING.md asks a first adopter for their placement state at the start and end of the
  quarter — the measurement gate configuration item 13 is waiting for. Item 13 stays
  open: the gate still cannot tell the two apart.
- **`tools/test-doctor.sh` grows to 47 cases,** 21 of them new: each state, the ADR and
  role rules, agreeing and disagreeing records, and seven histories — raised, lowered
  without a declaration, lowered properly, lowered by a different authority, lowered with
  no new ADR, a first declaration, and a lowered tier.

## v2.6.0 — 2026-10-08

A project can take a later release's starter improvements without losing its own
edits. Minor — `sync.sh` records one more thing when it seeds, and the archive ships
one more tool; no check, input contract, verdict or profile moved, and nothing anyone
owes changes. Build DNA stays at 1.13, the spine at 0.8, the gate configuration at 0.8.
The bundle digest moves because `VERSION` does.

- **`sync.sh` records each starter's baseline when it seeds it:** the template exactly
  as seeded, under `.causeway/starters/<file>.base`, and a line in
  `.causeway/starters.txt` naming its checksum, template and release. Outside the lock
  and outside `check-drift.sh`, because the starter is the project's. Written in the
  same all-or-nothing install as everything else; a re-sync that seeds nothing leaves
  them untouched. #11, ADR 0046.
- **`tools/upgrade-starters.sh`,** run from the release being upgraded to. For each of
  the nine starters it compares the baseline, the project's file and the new template,
  and reports `up-to-date`, `clean`, `merge` (a clean three-way merge with `diff3`),
  `conflict`, `adopt`, `manual` or `absent`. Report mode writes nothing to the project
  — proposals, diffs and conflict files go to a report directory outside it.
  `--apply` writes only `clean`, `merge` and `adopt`, and moves their baselines;
  conflicts are never written into a project file. `--accept <file>` records a hand
  merge. Running it again after an apply reports `up-to-date`.
- **Projects synced before v2.6.0 have no baselines.** Their starters come back
  `manual` — a diff to review and `--accept` — unless the file is exactly the new
  template, which is `adopt`. Nothing is guessed.
- **`ADOPTING.md` walks through an upgrade** in eight steps.
- **`tools/test-upgrade-starters.sh`, 28 cases,** run in CI and the release gate,
  against a "future" release with three templates changed. **`validate.py` §22** fails
  if the upgrader's starter list and `sync.sh`'s seeded files ever differ.

## v2.5.0 — 2026-10-08

A project can ask what adopting the standard still needs. Minor — one more vendored
tool, so the bundle grows from 29 to 30 files; no check, input contract, verdict or
profile moved, and nothing anyone owes changes. Build DNA stays at 1.13, the spine at
0.8, the gate configuration at 0.8.

- **`tools/doctor.sh`,** vendored into every project. Read-only, offline, advisory
  (always exits 0). It checks the pin, runs the drift check, and looks for: a release
  pin, a `system.json` with a valid tier, criticality class and declaring authority,
  a `CLAUDE.md` that imports `@AGENTS.md`, the Gemini, Copilot and Cursor shims
  pointing at it, `[PLACEHOLDER]` text left in the seeded starters, the template's
  example item in `open-items.json`, `@ORG/` teams in `CODEOWNERS`, a CI file that runs
  `check-drift.sh`, and a recorded gate evaluator. Each finding is `ok`, `incomplete`
  (with the file and the fix) or `unverified` — branch protection and required
  checks are repository settings no file records, and are never counted as passing.
  The summary keeps installed, integrity, adoption and evaluation apart, and never
  claims the last. `--json` prints the same as `causeway-doctor-v1`. #12, ADR 0045.
- **It reports placement and never chooses it.** A missing `system.json` points at
  the placement procedure; a missing class is called a default rather than a
  declaration; the derived profile is shown, labelled derived.
- **`templates/project-CLAUDE.md` gains a `Gate evaluator` line,** where ADOPTING.md's
  "an engine, or an honest record that you have none yet" now has a place to live.
- **`sync.sh` ends by pointing at it,** and ADOPTING.md's *How to start* runs it as
  step 2.
- **`tools/test-doctor.sh`, 26 cases,** run in CI and in the release gate: a fresh sync
  is incomplete on exactly ten things, a configured project installed from a signed
  release on none, one case per kind of finding, every run leaves the project
  byte-identical, and the script calls nothing that reaches the network.
- **README:** the bundle count and digest it called current had been stale since
  v2.3.1, and the drift-check example said 26 of 28; both now match the artifacts.

## v2.4.1 — 2026-10-08

A release is published only after everything before it passed. Patch — the release
workflow and its tools change; nothing a consuming project vendors, runs or owes
changes. Build DNA stays at 1.13, the spine at 0.8, the gate configuration at 0.8.
The bundle digest moves because `VERSION` does.

- **No step runs after a failure.** The release workflow's archive steps carried
  `if: '!cancelled()'`, which runs a step even when an earlier one failed, so an
  archive could be attached to a release whose signature had not verified or whose
  archive did not reproduce (#13). Every step now needs every step before it.
- **Missing signing prerequisites stop the release.** They used to produce a warning
  and an unsigned archive published as the official release. There is no unsigned
  official release; a development archive is `tools/build-archive.sh` on a
  workstation.
- **The release re-runs the source gate** — `validate.py`, the bundle and adapter
  checks, and every test script — on the tagged commit, and checks the tag names
  `VERSION`.
- **`tools/test-release-archive.sh`** installs the archive about to be published the
  way a consumer does: checksums, `.tar.gz` and `.zip` agree, statement inside,
  `sync.sh --require-release` with no git, the lock pins the signed release, drift
  and signature verify in the project. Then an altered statement, altered content and
  a missing `ssh-keygen` are each refused with nothing written. It writes
  `dist/.accepted` naming the tarball that passed.
- **`tools/publish-release.sh`** is the only step that changes a release. It
  re-checks everything locally — tag, signature, checksums, the statement inside the
  archive, and that `.accepted` names this tarball — before contacting GitHub at all.
  The release is a draft while its six assets upload in one call, then published.
  `--withdraw`, run when any step failed, turns a visible release back into a draft.
- **Tested without GitHub.** `tools/test-publish-release.sh` runs the publisher
  against a stub `gh` and proves that seven kinds of bad input reach GitHub zero
  times, a failed upload leaves a draft, and withdraw uploads nothing. Standard CI
  runs it, and the archive test against a throwaway-signed copy, on every pull request.
- **`validate.py` guards the workflow's shape:** no step condition but the
  withdrawal's overrides success, no `gh release` call outside the publisher, and
  the gates appear in order.

## v2.4.0 — 2026-10-08

A sync keeps what a project already told its agents. Minor — `sync.sh` changes what
it writes into an existing project, and a project with its own `AGENTS.md` that used
to have it silently replaced is now refused instead; no check, input contract,
verdict or profile moved, and nothing anyone owes changes. Build DNA stays at 1.13,
the spine at 0.8, the gate configuration at 0.8. The bundle digest moves because
`VERSION` does.

- **`AGENTS.md` is replaced only when it is Causeway's** — listed in the previous lock
  or identical to the standard. A project's own `AGENTS.md` is a conflict, exit `9`,
  with the command to move it aside. An `AGENTS.md` the lock lists but that was edited
  since is still restored, as `check-drift.sh` has always said it would be, and the
  sync now says so. ADR 0043, #10.
- **`GEMINI.md`, `.github/copilot-instructions.md` and `.cursor/rules/causeway.mdc`
  hold a marked section,** between `<!-- causeway:begin … -->` and
  `<!-- causeway:end -->`. A fresh install writes the section alone. An existing file
  keeps its text with the section appended; a re-sync rewrites only the section, so it
  never appears twice. A bare shim an earlier sync wrote becomes exactly what a fresh
  install writes. A symlink to `AGENTS.md` is left alone. Damaged markers are a
  conflict.
- **`CLAUDE.md` is still never edited,** and a sync now warns when it does not import
  the standard with `@AGENTS.md`.
- **`ADOPTING.md` says how to install over existing instructions,** and how to recover
  files a pre-2.4.0 sync overwrote.
- **`tools/test-sync.sh` grows to 32 cases;** the fifteen new ones cover a customized
  file for every adapter, a project's own `AGENTS.md`, re-sync idempotence, damaged
  markers, legacy shims, symlinks and drift. Ten fail against v2.3.1.

## v2.3.1 — 2026-10-08

An installation completes or changes nothing. Patch — `sync.sh` fixes the order it
works in and stops calling a tampered copy a release; no check, input contract,
verdict or profile moved, and nothing anyone owes changes. Build DNA stays at 1.13,
the spine at 0.8, the gate configuration at 0.8. The bundle digest moves because
`VERSION` does.

- **`sync.sh` decides before it writes.** It used to copy the standard into the target
  and then evaluate `--require-release`, so a refusal exited `7` with files already
  overwritten and no new lock (#9). It now runs in four phases — decide, plan, stage,
  apply — and only the last touches the target. Staged files are renamed into place
  with the lock last; a failure restores what was overwritten and removes what was
  created. ADR 0042.
- **Two new exit codes.** `9` for a target conflict — a symlink, a directory where a
  file goes, a file where a directory goes, or an unwritable path — reported all at
  once before anything moves. `10` for an apply that failed and was rolled back.
- **A release proof must match the bytes.** Every file in `bundle/manifest.json` is
  hashed and the digest recomputed. A copy that does not match loses its release
  proof: `--require-release` refuses it, and without the flag it installs as a
  development copy with a warning. Previously an extracted archive with a genuine
  signature and an edited `AGENTS.md` installed as `release_proof=signed-statement`.
- **`tools/test-sync.sh`,** run in CI: seventeen cases against a target that already
  holds a project, each refusal required to leave it byte-identical, plus a signed
  no-git install using a throwaway key. Twelve of the seventeen fail against the
  previous `sync.sh`.
- **Not changed:** a successful sync still replaces `AGENTS.md` and the tool adapters
  in an existing project. That is #10.

## v2.3.0 — 2026-10-07

The decision register explains itself. Minor — `sync.sh` seeds one more project-owned
file and the archive ships one more template; no check, input contract, verdict or
profile moved, and nothing anyone owes changes. Build DNA stays at 1.13, the spine at
0.8, the gate configuration at 0.8. The bundle digest moves because `VERSION` does, so
a pinned project re-syncs to pick it up.

- **`sync.sh` seeds `decisions/README.md`,** from `templates/decisions-README.md`, on
  the terms it seeds `domain/field-notes/README.md`: written once if absent, never
  overwritten, declared ungoverned, carried in the archive. The file is the short form
  of Build DNA §8 — how to write an ADR, what the numbers mean, what immutability
  permits and forbids, how to read the frontmatter, where an ADR's leftovers go — and
  it ends in two sections only the project can write: an index by family, and a list
  of unused numbers with the reason each was skipped. Until now the directory arrived
  with an open-items index and no explanation of the records the items point at, and
  a consuming project wrote the file itself. ADR 0041.
- **This repository's own `decisions/` gets the same README, filled in.** Every ADR
  since 0001, grouped into nine families. The grouping is a judgment; the rows are
  checked.
- **Three validator checks guard the index:** every ADR on disk is linked from the
  README, every ADR link in it resolves, and every skipped number is named in it. The
  third passes on nothing today, and the ADR says so rather than calling it verified.
- **The contributor templates point at it.** `contributor-START-HERE.md` and the pull
  request template now say an ADR lands in the same pull request as its index row.

## v2.2.0 — 2026-10-02

The first public release. Minor — `sync.sh` gains the license copy and the archive
ships two more files; no check, input contract, verdict or profile moved, and
nothing anyone owes changes. Build DNA stays at 1.13, the spine at 0.8, the gate
configuration at 0.8. The bundle digest moves, so a pinned project re-syncs to pick
it up.

- **New release-signing key.** The private half of the key ADR 0019 issued could not
  be recovered, so the trust anchor in `bundle/allowed-signers` is replaced before
  anything is signed with it in public. New fingerprint
  `SHA256:dsW8+Y3vfNpf7GJ4cNwzZWPz7MoeANQtjiZEFmW5iVY`. No published release was ever
  signed by the old key in this repository, so no consumer has to re-anchor. ADR 0040.
- **Published from a fresh history, as `deiotte/causeway`.** The public repository
  starts at this release; the history before it stays private in
  `deiotte/causeway-standard`, which keeps its name. Issues are renumbered —
  #29 through #34 become #1 through #6 — and every link to them in the tree is
  rewritten, including one in ADR 0030 and two in this file. Links to commits, workflow runs and release
  tags that exist only in the old history are unlinked. README's install path no
  longer assumes an authenticated account. ADR 0039.

- **Other projects' names are redacted from the tree.** Every reference to another
  project, program, or non-public artifact is replaced by the category it stood
  for — "the reference engine", "a consuming project", "an air-gapped appliance".
  Eight accepted ADRs carried such passages and are edited in place, which §8
  normally forbids; ADR 0036 records the rule each replacement had to pass, lists
  every one, and explains why supersession was the wrong tool. Build DNA §10 no
  longer lists callsigns, and the pre-v1.0 migration note is removed.
- **The git history is not redacted.** ADR 0036 makes publishing from a fresh
  history, or rewriting this one, a precondition of making the repository public.
- **Licensed under Apache-2.0.** `LICENSE` and `NOTICE` at the root. `sync.sh` now
  writes `bundle/LICENSE` and `bundle/NOTICE` into every consuming project — never
  the project root, where the consumer's own license lives — and the release
  archive ships both. Neither is digested, so this part moves no pin. ADR 0037
  weighs MIT, a CC BY 4.0 split, copyleft, public domain and the Community
  Specification License, and records why each lost.
- **Governance is written down.** `GOVERNANCE.md`, `CONTRIBUTING.md`, `SECURITY.md`,
  `.github/CODEOWNERS` and a field-note issue form for this repository. Issues are
  open to anyone and every one gets a disposition; pull requests are maintainer-only
  for now; the managed policy tier is scoped to the adopter and Build DNA item 1
  stays open; continuity is stated as what survives without the maintainer. None of
  it is vendored. ADR 0038.
- **A first adopter has somewhere to start.** `ADOPTING.md` separates trying the
  standard from building under it, lists the measurements Build DNA open items 4,
  6, 8, 9 and 10 are waiting on, and says what an adopter gets back. An *Adopter
  report* issue form collects them. Neither is vendored.

Also gives the Contributor role a front door (ADR 0035). On its own that change is
seeds only — nothing vendored moves, and it left the bundle digest unchanged. Build DNA, the spine and the
gate configuration stay where they are.

- **`sync.sh` seeds `CONTRIBUTING.md` and `.github/pull_request_template.md`,** on the
  terms it already seeds `START-HERE.md`: written once if absent, owned by the
  project after that. The first walks the Contributor floor in the order a new
  developer meets it — setup with expected results, the gate, the five obligations,
  the rules, a loop for working a task with an AI assistant. The second restates the
  floor as a checklist a reviewer can see. Both carry `[BRACKET]` placeholders.
  `CONTRIBUTING.md` because GitHub links it from every new pull request, which is
  discovery that does not depend on anybody reading a pointer. ADR 0035.
- **`templates/project-CLAUDE.md` and `templates/practitioner-START-HERE.md` point at
  it.** The practitioner template had been sending developers to `CLAUDE.md`, a
  reference card that was never written for arriving.
- **No `system.json` stub.** Considered and declined: a stub with values is a
  placement nobody declared. The front door says what to do when the file is
  missing instead.

## v2.1.0 — 2026-09-19

Closes gate configuration open item 9 by measuring the one-way deadline against the
spine instead of against a release. Minor — the input contract moved, and only
downward, so every engine that could run the affected check still can and no
system's verdict changes. Gate configuration 0.7 → 0.8; ServiceNow overlay 1.11 →
1.12, re-ratified. Build DNA stays at 1.13 and the spine at 0.8.

- **Item 9 asked which of two readings of the gate was right, and the deadline was
  never the gate's to set.** `oneway-closure` has blocked at G1 and above since
  v0.1 while its question read *closed before the first release tag*. The design
  layer says otherwise in four places — `spine.md`'s One-way column, its one-way
  doors section, `AGENTS.md`'s Maintainer floor and the decision-spine skill — and
  all four say **before writing production code**. §4 had already recorded that the
  release-tag term was "defined nowhere in this document or the spine." The item's
  own opening line mis-cited its subject: *its row reads 28 rows closed before
  first release tag*, and the row reads nothing of the kind.
- **The blocking column was correct the whole time.** *Production code exists* is
  not a file, which is why the gate needed a readable form — and the profile
  already was one. G1 requires a Tactical Authorization and a sandbox tenant, which
  is what a deployed system looks like from disk. Warn at G0, block above, is the
  spine's deadline compiled. Nobody had to add a second, worse proxy on top of it.
- **So the correction runs the other way.** The question string moved to meet the
  blocking column rather than the reverse. `oneway-closure` now asks *Are all 28
  one-way rows closed?*, stops declaring `repo-git`, and stops listing
  `release_state` in its evidence — a marker it had carried since v0.5 and never
  reached a verdict through, its `modifiers` being `["adoption-horizon"]` and never
  `pre-release`. Blocking column and modifier untouched. ADR 0034.
- **A platform with no git can now run it.** On `repo-decisions` and
  `system-record` alone. Before this, an engine that could read an ADR register but
  had no tags reported `unsupported` on a check about whether ADRs exist — exit 4,
  a blocked deployment, for want of a value the check would not have consulted.
- **Open item 14 narrows and leaves the critical path.** `tests-with-source` is now
  the only consumer of `release_state`; it warns at all four profiles and its
  promotion has not engaged. A platform release record is still owed and is no
  longer blocking anybody, which is the difference between owed and urgent.
- **`engine_contract` stays at 1, with a note saying why.** Contract numbers move
  when a check's meaning changes. This check's verdict logic has not moved since
  v0.1; what moved is its declared input set, downward. An engine still declaring
  `repo-git` conforms and runs everything it ran before — it is declaring a
  capability one fewer check needs, and nothing is owed for that.
- **If you are pinned to 2.0.0.** Nothing re-evaluates. The only behavioural
  difference is that an engine without `repo-git` stops reporting `unsupported` for
  `oneway-closure` and starts reporting a verdict — which is the point.

---

## v2.0.0 — 2026-09-19

Redefines `release_state` to read release evidence rather than tag topology. **Major
— a conforming engine that read annotated tags no longer conforms, and a project
whose release was invisible may block where it warned.** Gate configuration 0.6 →
0.7; ServiceNow overlay 1.10 → 1.11, re-ratified. Build DNA stays at 1.13 and the
spine at 0.8; neither moved.

- **The marker was filtering on a property it was not buying.** `release_state` read
  *annotated tags only*, on the reasoning that a lightweight tag is a moveable local
  label. So is an annotated one — `git tag -f` moves either kind, and the tagger
  identity inside an annotated tag is whatever local config said. `sync.sh` has said
  exactly this in its own comments since v1.8.0. The filter excluded real releases
  and admitted forged ones.
- **It also ignored the strongest evidence in the standard.** Since v1.8.0 a release
  carries an SSH-signed statement over the bundle digest, verifiable offline against
  a vendored anchor. `release_state` did not consult it and read tag shape instead.
  ADR 0030 diagnosed this exact ordering for `--require-release` — *the weaker proof
  was the mandatory one; that ordering was chronology rather than a decision* — and
  the same sentence described `release_state` without changing a word.
- **Open item 8's replacement condition was met twice.** The item required replacement
  *if the untagged G2/G3 set turns out not to be small*. `overlays/servicenow.md` §8
  reported the first instance at overlay 1.1: a platform versioning applications
  outside git has nothing for an engine to ask git about. The second is this
  repository — nine published releases, every tag lightweight, because they are cut
  through the GitHub web interface, which creates no other kind. By its own marker
  the standard had never released, and neither had any project whose maintainer works
  in a browser.
- **`release_state` now returns a state and a proof.** Four sources, ranked by what
  each proves: `signed-statement`, `annotated-tag`, `lightweight-tag`,
  `platform-record`. First match wins; `release_proof` is recorded beside the state,
  in the vocabulary `.causeway-lock` already carries for the same distinction.
  `annotated_only` is gone from `gate/profiles.json`, and `repo-git` reads tags of
  either kind. ADR 0033.
- **What stayed open got smaller and moved.** The fourth source has no input class
  behind it: an application version field is not a git object of any kind. That is
  new item 14, related to item 11 rather than merged with it, and it is the first
  time this platform's version problem has had an upstream item of its own rather
  than a sentence inside a marker's definition. `overlays/servicenow.md` open item 3
  is narrowed and re-pointed at it.
- **Observed impact today is zero, and that is the argument for the timing.** No
  engine implements `repo-git` — the only one reports it unsupported — so no
  receipt anywhere carries a `release_state` this changes. The contract moved; no
  verdict did. The §9 warn cycle lands on the first engine to implement `repo-git`,
  which should ship it advisory for one cycle; that obligation is stated in ADR 0033
  rather than left to be inferred from its absence.
- **If you are pinned to 1.x.** Nothing you have breaks and nothing re-evaluates,
  because nothing implemented the input. Re-syncing gets the new definition and a
  `release_proof` field that no engine populates yet. The version is major because
  the contract changed, not because a build will.

---

## v1.16.0 — 2026-09-19

Says how a system arrives at the two values everything else derives from. Minor —
a reference document and its routing are added; no check contract, verdict, input
class, or profile cell moves. Build DNA 1.12 → 1.13; ServiceNow overlay 1.9 → 1.10,
re-ratified with one row added and no disposition moved. Spine and gate
configuration are unchanged at 0.8 and 0.6.

- **`tier` and `criticality_class` drive every number in the standard and the
  standard defined neither.** The class had three one-line meanings inside a
  paragraph about how to read a table column; tier had nothing, because "a catalog
  fact" answers who decides and not what they decide on. Both documents that
  consume the values open by telling the reader to read them out of `system.json`,
  which is correct for a placed system and silent for the one being built.
  `skills/decision-spine/reference/placement.md` is the procedure: four questions,
  five facts that set C1 on their own, the inheritance test that separates Core
  from Mission, the declaration, and the reclassification rules. ADR 0032.
- **The loud default was being spent silently.** A missing class resolves to C1,
  which is right, and nothing can tell a C1 somebody declared from a C1 nobody did
  — §3 never reads `criticality_authority`. The document makes the declaration a
  described artifact so that its absence becomes describable. Counting it is gate
  configuration open item 13.
- **Nothing enforces it, on purpose.** `placement-argued` is named as a candidate
  check and deferred, for the reason `survey-present` was in 1.15.0: §9 requires a
  warn cycle before blocking behavior engages, and a warn cycle needs a portfolio
  that has run the procedure. None has. This release adds no blocking check.
- **Routing, not a second copy.** Build DNA §1 and §9, the Decision Spine skill,
  `gate-profiles.md`, `spine.md`, gate configuration §3, the Survey skill and
  template, and `templates/project-CLAUDE.md` all point at the one file. The
  Survey keeps its two triage questions and now cites them as a route to a
  *proposal*; `placement.md` quotes them under the same label.
- **`templates/project-CLAUDE.md` gains a *why* line under each axis.** A consuming
  project has been arguing both axes in `$tier` and `$criticality` siblings its gate does not
  read, and in a *Causeway placement* block, since it adopted the standard. That
  practice was invented in a consuming repository because this one had nowhere to
  put it; it is now in the template every project starts from.
- **Correction: the C3 short form is 23 rows, not 22.** `reference/spine.md` said
  22 in its `Applies` paragraph and 23 everywhere else — in its own short-form
  section four hundred lines below, in the skill's scope table, in
  `gate/checks.json`, and in the ServiceNow overlay. The sentence went stale when
  SA-5.16 joined the form at Spine v0.6 and survived every release since, because
  every other statement of the number was right, so nothing ever disagreed.
  `tools/validate.py` §16 now anchors it. No system owes a different set of rows;
  the `Applies` column was always authoritative and always said 23.

---

## v1.15.0 — 2026-09-18

Adds intake: a structured Survey upstream of the ADR seam, plus the ADR fields it
feeds. Minor — capability is added, and no check contract, verdict, input class, or
profile cell moves. Build DNA 1.11 → 1.12; ServiceNow overlay 1.8 → 1.9, re-ratified
with no disposition moved. Spine and gate configuration are unchanged at 0.8 and 0.6.

- **Nothing in Causeway sat upstream of the moment an ADR gets written.** §8 governed
  how a record is written once you had one, the Decision Spine enumerated which rows
  must close, and the gate checked that they did — all three beginning at the seam.
  The observed failure was ADR churn: records amended or invalidated within days,
  in three recurring shapes that more rigor at write time cannot reach, because the
  missing input was information. `skills/survey/` and `templates/survey.md` are the
  intake instrument; ADR 0031.
- **`templates/adr-template.md` gains five fields.** `survey_rows`, `forces`, `door`,
  and `revisit_if` are optional; `supersession_cause` is required when `supersedes` is
  non-empty. The quoted `adr:` identifier (ADR 0017) and the `corrects`/`corrected_by`
  pair (ADR 0027) are unchanged — the fields are additive and nothing was replaced.
- **Build DNA §8 gains three rules.** A decision is recorded only when a readiness
  test says it is ready; an ADR states the forces that discriminated; a superseding
  ADR classifies why, S1–S5. The thirty ADRs written before this release carry no
  `forces` and are not backfilled — the requirement attaches going forward, the way
  `tests-with-source` attaches.
- **The enforcement is deliberately not here.** `survey-present` and
  `adr-forces-nonempty` are named as candidate checks and deferred. §9 of the gate
  configuration requires a warn cycle before any new blocking behavior engages, and a
  warn cycle needs something to measure; the measurement is the cause-code
  distribution these rules start collecting, which does not exist yet. Build DNA open
  item 10 carries it, blocked on `gate-check-decision`.
- **Two vocabulary collisions were settled before shipping rather than after.** The
  Survey's exit criteria are not called a gate — the gate is the machine-readable
  contract in `gate/` with its own verdicts and exit codes, and ADR 0008 is this
  repository already paying once for two things sharing a name. And an ADR's `door`
  is read from the Decision Spine's `One-way` column rather than authored beside it,
  so a record cannot call a decision two-way on a row the Spine marks `Y`.
- **Bundle 26 → 28 files**, digest moved. A consuming project re-syncs to pick up the
  instrument; `check-drift.sh` will report the old lock as stale, which is the
  mechanism working. The two new files are vendored, digested, and carried in the
  release archive — `validate.py` §19 caught the archive omission during this change,
  which is the guard ADR 0030 added doing its job.
- **Two stale README numbers found along the way**, both unanchored prose and both
  wrong before this release touched them. The layer table had claimed Build DNA 1.10
  since the 1.11 bump, and the implementation table had claimed ServiceNow overlay 1.7
  since 1.8. Neither is guarded: §16 anchors derived counts and the ratification guard
  reads `AGENTS.md` and the overlay headers, so a version restated in a README table
  is checked by nothing. Corrected to 1.12 and 1.9. A third anchor pair is the obvious
  fix and is not made here — it would be a guard written in the same commit as the
  bump it was meant to catch.

`main` carries 1.15.0 with no `v1.15.0` tag or release published. That gap is limit 7
and issue #3, reopened by this bump exactly as predicted.

---

## v1.14.0 — 2026-09-16

Publishes an installable archive and lets a verified release signature stand as
proof of a release. Minor: capability is added, and no check contract, verdict,
input class, or profile moves.

- **The only documented way to obtain the standard was a clone of a private
  repository.** That needs git, a credential enrolled on each machine, and the
  network up at install time — the three things missing from the machines this
  standard was built for. Build DNA §6 requires consuming projects to build
  offline, ADR 0019 chose SSH signing so an air-gapped consumer could verify a
  release, and `verify-release.sh` opens with "no network, no keyring, no clone".
  All of it assumed a consumer who had somehow already got the bytes. ADR 0030.
- **`--require-release` could not be satisfied without git, and said so by
  printing a `git checkout` command into a directory with no git in it.** The
  flag Build DNA tells you to use for anything that ships derived release
  identity from `git describe --exact-match`, so on a machine without git the
  answer was exit `7` and an instruction that cannot be followed.
- **The weaker proof was the mandatory one.** `git describe` proves a local clone
  has a tag at `HEAD`, and a tag is a local, rewritable label that `git tag
  v99.0.0` forges in one command. The signed statement proves a key named in
  `bundle/allowed-signers` attested this exact bundle digest. That ordering was
  chronology rather than a decision — git was what v1.0 had, signing arrived in
  v1.8.0, and nothing went back to ask which one the flag should read. Either now
  establishes a release, and `.causeway-lock` records which in a new
  `release_proof=` line whose value is `git-tag`, `signed-statement`, or `none`.
- **`tools/build-archive.sh` publishes `.tar.gz`, `.zip`, and a `.sha256` for
  each.** Byte-reproducible — staged modes, sorted entries, `mtime` from
  `RELEASED`, owner `0:0`, `gzip -n` — and carrying the release statement and its
  signature *inside* the archive, so the bytes, the statement naming their digest,
  the signature, and the anchor that verifies it are one file. CI builds it twice
  and compares byte for byte.
- **The signature material travels into the consuming project.** `sync.sh` copies
  `release.statement` and its `.sig` in beside the anchor it already vendored, so
  `verify-release.sh` — vendored since v1.8.0 with nothing to verify — runs in
  that project's CI with no network and no GitHub credential. The documented way
  to give it something had been `gh release download`: a network call, a
  credential, and a third tool, in a project that vendored the standard precisely
  so it would need none of the three.
- **CI installs from an extracted archive with `git` removed from `PATH`** and
  asserts the pin it writes is identical to the one a clone produces. A new
  validator section fails the build when a file `sync.sh` reads is missing from
  the archive — a failure that can otherwise surface only on a machine with no
  way to fetch what is missing.
- **Build DNA moves to 1.11**, adding one rule to §3: how a dependency arrives on
  the target machine is part of its design, and an install path may not assume a
  toolchain the target does not have. The ServiceNow overlay is re-ratified at
  1.8 against it; no disposition moved, and no input class became suppliable.
- Two things this does not close. A substituted archive is self-consistent by the
  same design that makes it self-contained — its statement verifies against its
  own anchor — and an archive install makes the signature the only release
  evidence, because there is no tag to read as a second signal. Both reduce to the
  anchor fingerprint needing one confirmation through a channel that is not the
  archive, and to a key lifecycle that still does not exist. Gate configuration
  §10 item 10 and issue #4, both already open; no new item is filed, because a
  second entry for one gap is what relations were added to catch.

**If you are pinned to v1.13.1.** Nothing you have breaks. Re-syncing gets a lock
carrying `release_proof=`, the release statement and signature in your `bundle/`,
and a drift check that reports which evidence backs the pin. A `check-drift.sh`
from before this release reads the new header key as a checksum line with no
filename and skips it, so an old vendored checker keeps working. This is the
first release to carry an archive asset — `v1.9.2` predates them — so installing
without git needs `v1.14.0` or later, or `./tools/build-archive.sh` run from a
checkout.

## v1.13.1 — 2026-09-11

Makes the `field-note` skill reachable. Patch: corrects the adapters a consumer
receives and moves no check contract, verdict, input class or profile.

- **A skill shipped and was unreachable.** Nothing auto-discovers `skills/` — an
  agent learns a skill exists because the tool adapter it reads names the path.
  `v1.13.0` added `skills/field-note/` and all four adapters still listed one
  skill, so the skill was vendored, checksummed in every lock, and invisible to
  the mechanism that invokes it. A practitioner following `START-HERE.md` would
  have met an agent that had never been told it existed, and it would have
  written a plausible note from its own priors rather than saying so. ADR 0029.
- **`render-adapters.sh` now fails when a skill is not named in every adapter.**
  It checked that each adapter carried a generated marker and pointed at
  `AGENTS.md`, and both were true throughout. The check was answering a different
  question. It is a substring test on the skill path, not a match against the
  shims' prose, because the four legitimately say different things in different
  voices and binding that wording is the failure ADR 0020 records.
- **Same shape as the bundle count one release earlier.** A derived list restated
  in four documents, accurate for as long as the underlying set never moved, and
  wrong within one commit of it moving. Two instances in consecutive releases is
  why this is a check rather than a resolution to be more careful.
- One open item: Build DNA 9, a pointer is not discovery. The guard checks that
  the pointer exists and cannot check that an agent read the shim, honored it, or
  recognized the moment. The candidate fix — ship each skill where its tool
  already looks — is larger than the bug that surfaced it. It takes the number
  held briefly and unpublished during ADR 0028; `v1.13.0` shipped the register
  ending at item 8, so no reader has seen a different item 9.

**If you are pinned to v1.13.0.** Re-sync to get adapters that name the skill.
Without it the practitioner path is present in your repository and will not be
invoked, which is the one failure here that produces output rather than an error.

---

## v1.13.0 — 2026-09-11

Admits a fourth adoption role — the Practitioner, who knows the work and does
not write software — gives it an artifact and a capture path, and binds the
answer it is owed. Minor: adds content and two bundle files, and changes nothing
a conforming engine or a pinned project already owes. Build DNA moves to 1.10
and the ServiceNow overlay to 1.7.

- **The Practitioner role enters Build DNA (1.10).** Its floor is the project's
  `START-HERE.md` and it owes `AGENTS.md` nothing. A contract that made
  subject-matter expertise pass a reading test would collect less of it, from
  fewer people, later. ADR 0028.
- **Field notes are the artifact, and they are the ADR's twin.** An ADR records a
  decision somebody made; a field note records a fact about the world a decision
  has to survive. Five prompts, one structural field — `confidence` is `seen-it`,
  `fairly-sure` or `suspect`, and it is never upgraded on the way into an ADR.
  `templates/field-note.md`.
- **`skills/field-note/` governs the interview, and its first rule constrains the
  interviewer.** An agent can write a plausible field note from one sentence of
  prompt, which captures the model's priors wearing a practitioner's name. The
  skill supplies structure; the practitioner supplies every fact.
- **Four surfaces are seeded into a consuming project and none needs a
  terminal.** `sync.sh` writes `START-HERE.md`, a GitHub issue form at
  `.github/ISSUE_TEMPLATE/field-note.yml`, the register at `domain/field-notes/`
  with its own README, and `.github/CODEOWNERS` — seeded once and thereafter
  owned by the project, on the same terms as `CLAUDE.md`.
- **CODEOWNERS ships saying it is half a guardrail.** It nominates reviewers;
  branch protection is what requires them, and no script can write a repository
  setting. Until both are on, a practitioner with write access can merge their
  own note — the shape ADR 0016 already records for the gate.
- **The disposition obligation is in the role, not in a guide.** Every note
  reaches an ADR, a test, a `CLAUDE.md` constraint, or closure against where it
  is already handled, and its author is told which. Collection without
  disposition is a suggestion box, and it gets exactly one round.
- **The ServiceNow overlay is reconciled rather than bumped (1.7).** §7 gains a
  Practitioner translation: the platform has the densest concentration of this
  role and the least room for it. Two traps named — incidents, problem records
  and demand records are inputs rather than entries, and a note belongs to the
  application rather than the instance — and one declared gap: update-set-only
  delivery has no repository, so no front door, no register, no pull request.
- **The consumer bundle goes from 24 files to 26.** The note template and the
  skill are digested, because a project quietly editing either would still be
  producing something it called a field note while the promotion rules read a
  different artifact.
- **The bundle file count is anchored.** It is stated three times in the README
  and was checked by nothing. This release is the first change in the
  repository's history to move it, and all three statements went stale in one
  commit. A number that has never moved is not verified; it is untested.
- **A note is an input, not an index entry, until it leaves something open.** The
  project's `decisions/open-items.json` already carries the vocabulary a
  disposition wants, and must not become a second numbering of the note
  directory. A note earns a row when the ADR that read it left something open;
  one closed against a document that answers it is an `answered_by` edge; one
  whose promotion left nothing open needs no row. Same rule the ServiceNow
  overlay states for skip records and Instance Scan findings.
- One open item, none closed here: Build DNA 8, the Practitioner floor is
  unmeasured and is the first floor with a second party. Build DNA 6 is amended
  rather than joined by a sibling — it already asked whether anything enforces
  the index in a consuming project, and an undisposed note is an index row nobody
  moved.

**If you are pinned to v1.12.0 or earlier.** Re-syncing adds the practitioner
path and changes nothing you already owe. There is no new check, no changed
verdict and no profile movement. A project with no practitioners can re-sync and
ignore the three seeded files; a project with practitioners fills in the
bracketed names in `START-HERE.md` before handing it to anyone, because an
on-ramp still carrying `[NAME]` tells a new person they were not expected, and
replaces `@ORG/TEAM` in `.github/CODEOWNERS` before relying on it.

---

## v1.12.0 — 2026-09-03

Corrects six derived counts ADRs 0025 and 0026 stated wrong, anchors the index's
own sentences about itself, and gives the ADR contract a forward pointer for a
correction. Minor: `corrected_by` changes what an ADR carries.

- **Six wrong counts, all derivable from `decisions/open-items.json` in the same
  commit.** ADR 0025 said six registers (there are four) and fifteen null
  attributions (21). ADR 0026 said five items carry an edge (six), six carry a
  blocker (eleven), and three share `first-adopter-evidence` (four). ADR 0027.
- "Six registers" came from a draft that counted two README lists ADR 0025 then
  explicitly declined to index. The number survived the decision that falsified it,
  reached the index's `$attribution`, and shipped from there into the ADR.
- The index's self-descriptions are now anchored: null attributions, total items
  and registers all derive, checked the way §16 checks the README. Replaying the
  original error fails the build; so does deleting the sentence.
- **Build DNA 1.9.** §8 gains a correction rule: a factual error in an accepted ADR
  is corrected by a later ADR, and the corrected one gains `corrected_by` in its
  frontmatter while its body stays untouched. Immutability protects the argument,
  which is not what a wrong count is. `corrects` and `corrected_by` are mutual and
  both directions are checked. ADRs 0025 and 0026 carry the pointer.
- Two out-of-record references retracted: ADR 0025 stated a consuming project's
  counts as a finding rather than as the report it was, and ADR 0026 cited a plan
  that exists in no repository.
- Build DNA open item 7 opens — nothing checks a count stated in an ADR — with the
  candidate design recorded rather than left to be re-derived. 29 open items.
- `tools/validate.py` 562 assertions to 572.
- Overlay re-ratified at 1.6 against Build DNA 1.9, with **no §7 row**: the rule is
  about the ADR record's shape and has no platform reading. Third Build DNA bump in
  three releases and the first with nothing to translate — named on both sides, so
  that a fourth prompts a question about the guard's granularity rather than an
  invented row.
- Gate configuration stays at v0.6 and the spine at v0.8. The gate still has 27
  checks with unchanged semantics, inputs and profile matrix.

## v1.11.0 — 2026-09-03

Makes the relations between open items real and enforces what each kind promises.
Minor: consumers inherit the vocabulary and one more rule in Build DNA §8.

- v1.10.0's index made every item countable and stopped there. A full sweep of the
  27 found eight entangled across registers, none of which a count can see. ADR 0026.
- Five relation types, each with an invariant the build enforces: `duplicate_of`
  (mutual, both halves same status), `superseded_by` (target closes, this closes),
  `upstream_of` (targets exist, cross registers, re-read on closure), `answered_by`
  (names a document and heading outside this register, both must exist), and
  `blocked_on` (declared keys, checked in both directions).
- **`spine-1` closes**, by the relation rather than a fresh argument: it was
  superseded by `build-dna-2`, which ADR 0021 closed at Build DNA 1.6, and the spine
  kept asking for the same Drive diff for two releases after. Closed in place with
  its number — the spine's first closure that does not renumber, and the section
  gains the numbering-stability note the gate configuration has had since v0.5.
- **`gate-config-8` stays open and its question changes.** `overlays/servicenow.md`
  §8 has answered it since overlay 1.1 — *on this platform the untagged G2/G3 set is
  not small* — with nothing carrying it back. The `answered_by` edge carries it, and
  the item now records that its condition is met. The remedy changes what an engine
  reads, so it is deferred to its own ADR rather than decided here.
- **Gate configuration items 11 and 12 open**, so overlay open items 6 and 5 have
  upstream targets that exist: no engine has declared its input classes against any
  platform, and `expectations.json` cannot say that an engine lacks one. Both were
  already in the overlay saying the finding belonged upstream, with nowhere to go.
- Build DNA 1.8. §8 gains *Relations between items*, with two usage rules: a finding
  that belongs upstream names the item it belongs to and opens one if none exists,
  and a relation is not a merge.
- `tools/validate.py` §18. 540 assertions to 562.
- Overlay re-ratified at 1.5 against Build DNA 1.8 — ADR 0024's guard firing for the
  second release running. §7's index row gains the platform reading: containment
  means an overlay may only record what it finds about core, so an `upstream_of`
  edge with a real target is the difference between a finding that is owned and one
  that is merely written down. No disposition moved.
- Gate configuration stays at v0.6 and the spine at v0.8. Neither changed
  normatively; §10 and *Open questions* are registers, not contracts. The gate still
  has 27 checks with unchanged semantics, inputs and profile matrix.

## v1.10.0 — 2026-09-03

Indexes the open items ADRs leave behind, and checks the index against the four
registers that carry them. Minor: consumers owe one file they did not owe before,
seeded for them, and no check reads it.

- `decisions/open-items.json` is new and carries every numbered open item in the
  repository — 33 items, 27 open, 6 closed, across Build DNA, the gate
  configuration, the ServiceNow overlay and the spine. The index owns each item's
  state: status, the ADR that opened it, the ADR that closed it, the version each
  happened in. The prose entry keeps its number and its argument. ADR 0025.
- **`gate/gate-configuration.md` open item 10 was not in §10.** ADR 0009 appended
  it to the end of §11 and ADR 0019 and ADR 0023 both amended it there, the second
  describing it as sitting in §10. The register showed nine items for eleven
  releases. The item is relocated with its number and text unchanged; the gate
  configuration version does not move, because nothing normative did.
- Build DNA 1.7. §8 gains *The open-items index* between the exceptions register
  and declared gaps, with five rules: numbers stay stable and closed items keep
  their entry, every register is declared, the index is hand-maintained rather
  than generated, an item cites ADRs that exist, and every stated count derives.
  Open item 6 opens and records what is not enforced.
- `tools/validate.py` §17 checks the index against the prose: the numbers in each
  register match the index exactly, the closed marker agrees with the status,
  every ADR an item names exists, a closed item names both its ADR and its
  version, no open item already names a closing ADR, the counts derive, and the
  README's stated count matches. 515 assertions to 540.
- `templates/open-items.json` ships and `tools/sync.sh` seeds it once into
  `decisions/open-items.json`, never overwriting an existing one — the same terms
  as `CLAUDE.md`. Both new files are declared in `bundle/scope.json`.
- Overlay re-ratified at 1.4 against Build DNA 1.7, forced by ADR 0024's guard on
  its first Build DNA bump. §7 gains one row: the index is not the customization
  ledger, skip records and Instance Scan findings are inputs to it rather than
  entries in it, and it is a property of the application rather than the instance.
  Update-set-only delivery has no repository to keep it in, declared rather than
  papered over. No disposition moved.
- Gate configuration stays at v0.6 and the spine at v0.8. Neither changed. The
  gate still has 27 checks with unchanged semantics, inputs and profile matrix.

## v1.9.2 — 2026-09-02

Reconciles the ServiceNow overlay to Build DNA 1.6, and guards the field that
let it drift. Patch: nothing normative changed and no consumer owes anything new.

- The overlay's header and `servicenow.json` said Build DNA 1.5 through v1.9.0
  and v1.9.1. `validate.py` compared the spine and gate-configuration versions
  an overlay claims and never read the third; it now reads all three, in the
  prose header and in the projection, and fails the build when Build DNA moves
  underneath an overlay. ADR 0024.
- Overlay re-ratified at 1.3 against Build DNA 1.6. §7 gains one translation
  row per 1.6 addition — adoption contract, pin-upstream, the offline test
  path, declared gaps, profile resolution. The offline row is the one worth
  reading: ATF runs on an instance, so the rule is translated as *reaches
  nothing beyond the instance under test* and declares that a scoped app has no
  offline build in §6's sense. No disposition moved.
- Overlay open item 5 corrected: nine fixtures, not eight, and not every one
  carries a lockfile.
- Gate configuration stays at v0.6 and the spine at v0.8. Neither changed.

Closes README development priority #2 and the second half of credibility gap #3.

## v1.9.1 — 2026-08-30

Reconciles the signing-state prose with the signing state, and guards it. Patch:
nothing normative changed and no consumer owes anything new.

- `tools/sync.sh` and `gate/gate-configuration.md` open item 10 both still said
  no signing key or signature existed. ADR 0019 issued the key at v1.8.0, so
  both had been false for two releases — and `gate-configuration.md` is inside
  the digested bundle, so every consuming project vendored a document telling it
  the standard does not sign its releases, beside the trust anchor and the
  verifier. Corrected; item 10 half-closed in place, keeping its number, since
  rotation and revocation genuinely still do not exist.
- `validate.py` §13 gains guard (e): when the trust anchor exists, no scanned
  document may claim signing is unissued; when it does not, `sync.sh` must say
  so. Matching is windowed, in ADR 0020's sense — the four existing signing
  guards all checked the mechanism and none read a word of the prose describing
  it, which is how the machinery got turned on without anything noticing four
  documents still said it was off. ADR 0023.
- Gate configuration stays at v0.6. No check, threshold, profile, input class or
  receipt field moved, and bumping it would force a ServiceNow overlay
  re-ratification to record that nothing changed.

Closes README credibility gap #2 and development priority #2.

## v1.9.0 — 2026-08-30

Build DNA 1.6. No check semantics, input contract, verdict, or profile changed;
a project that re-syncs owes nothing new to the gate.

**Build DNA 1.5 → 1.6** (`AGENTS.md`)

- The reconciliation notice is retired. This repository is the document of
  record without contradiction, closing the standing conflict between the notice
  ("if a repo copy exists, it wins") and ADR 0001 ("this repository wins"), which
  had shipped together in the same bundle across thirteen releases, v1.0.0
  through v1.8.0. Open item 2 closes. See ADR 0021.
- **Adoption contract** — a new section giving Reader, Contributor, and
  Maintainer an explicit floor. The standard had a 180-day adoption horizon and
  no statement of what adoption entails.
- **§3 — pin upstream, never silently fork.** The rule the standard already
  enforces on itself through `.causeway-lock` and `check-drift.sh`, stated
  generally for a project's own upstreams.
- **§6 — the build and the test path reach nothing.** Air-gap treated as a build
  constraint rather than only a deployment one: no network in the test path,
  dependencies from a populated local cache, contract tests named and kept out
  of the merge gate.
- **§8 — declared gaps.** Names one rule that already had four implementations:
  `Waived` ADRs, retroactive ADRs, the `unsupported` verdict, and the overlay's
  refusal to invent evidence. A requirement that cannot be satisfied is
  published with its blocker, never omitted.
- **§9 — resolve the gate profile before writing.** The routing step existed
  only in the `decision-spine` skill, so an agent reading `CLAUDE.md → AGENTS.md`
  never reached it.
- Open items 4 and 5 added: the adoption contract is unmeasured, and nothing
  enforces the offline test path.

Section numbers §1–§10 are unchanged. `overlays/README.md` and the ServiceNow
overlay reference Build DNA sections by number, so the new material lands as
subsections rather than as renumbered sections.

**Repository**

- This file.
- ADR 0021 (document of record), ADR 0022 (Build DNA 1.6).

## Between v1.8.0 and v1.9.0 — no release

`VERSION` never read 1.8.1 and no such release exists. `tools/validate.py` and
`README.md` are outside the digested bundle, so the prose-guard fix in ADR 0020
changed no bundled file and the v1.8.0 digest still described the bundle exactly.
Recorded here because the repository changed and a reader tracing the history
should not have to conclude an entry is missing.

- Prose-count guards bind to the claim rather than to one exact sentence, after
  a third README rewrite turned `main` red with every guarded number correct.
  See ADR 0020.

## v1.8.0 — 2026-08-24

Release signing. Spine v0.8, gate configuration v0.6.

- Releases are signed with SSH and verified offline against a vendored trust
  anchor, `bundle/allowed-signers`; no network, keyring, or transparency log is
  required to verify. ADR 0019.
- The release workflow publishes and verifies `release.statement` and
  `release.statement.sig`. Verification is available and not yet enforced.

## v1.7.2 — 2026-08-22

- `adr:` frontmatter must be a quoted four-digit string. YAML 1.1 read our
  numbering as octal, so every ADR from `0010` onward parsed to the wrong
  integer while a regex-based check read the digits and saw nothing wrong. The
  two disagreed for seven releases. ADR 0017.
- `RELEASED` gains a guard: it may not predate the last commit that touched
  `VERSION`.
- CI runs the gate once per commit in one job. ADR 0018.
- A conformance fixture covering values past the point the format breaks.

## v1.7.1 — 2026-08-21

- `.causeway-lock` records which release a vendored copy was synced from.
  ADR 0015.
- Required status checks rather than required approvals on `main`, while the
  repository has a single maintainer. ADR 0016.

## v1.7.0 — 2026-08-10

- The ServiceNow overlay ships a machine-readable projection alongside the
  normative prose, validated against it. Overlay re-ratified at 1.2. ADR 0013.
- `bundle/scope.json`: every tracked path is either digested by the manifest or
  declared ungoverned with a reason. Added after an entire second product was
  committed to this repository and CI stayed green, because no guard had ever
  looked at the tree as a whole. ADR 0014.

## v1.6.2 — 2026-08-10

- The Build DNA version is decoupled from `VERSION`. A field that always equals
  `VERSION` is `VERSION` with extra steps; Build DNA now moves when Build DNA
  moves. ADR 0012.

## v1.6.1 — 2026-08-10

- ServiceNow overlay reconciled against spine v0.8 and gate configuration v0.6.
  ADR 0011.

## v1.6.0 — 2026-08-09

- The engine contract is published: input classes, verdict vocabulary, the
  `unsupported` verdict, receipt requirements, and version compatibility.
  ADR 0009.
- CI adopted for the standard itself. ADR 0010.
- The composition-state vocabulary reconciled across the spine, `checks.json`
  and Build DNA §4. ADR 0008.
- `tools/check-drift.sh` is vendored into consuming projects rather than
  described to them.

## v1.5.0 and earlier

Reconstructed from `decisions/0001`–`0007`, each placed by the value of
`VERSION` at the commit that introduced it: adoption of this repository as the
document of record and its distribution model (ADR 0001, v1.0.0), the
npm-disfavoring dependency posture (ADR 0002, v1.1.0), one prompt / one commit
(ADR 0003, v1.2.0), the inference boundary (ADR 0004, v1.2.0), the adoption
horizon (ADR 0005, v1.3.0), `tests-with-source` promotion (ADR 0006, v1.4.0),
and platform overlays (ADR 0007, v1.5.0).
