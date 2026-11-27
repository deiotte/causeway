# Build DNA — Open items

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

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
   `tests.md`, `dependencies.md`, `inference.md`, and `agent-workspace.md` ship.
   The pattern still wants a rule for the CI surface itself — the pipeline is the highest-value
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
   project gets the template, the rule, and no check — the gate has 29 checks and
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
   Field evidence, v3.0.0: an adopting project answered this item for
   itself. Its `scripts/check-decisions.py` derives `decisions/open-items.json`
   from ADR frontmatter with `--write` and fails CI when the committed file
   disagrees, and it is the only adopted project whose counts never drifted. That
   is not the prose parsing this item feared: the derivation reads frontmatter,
   which is structured by construction. It is the strongest candidate for this
   item's check and wants a second project before it is promoted upstream.
   v3.1.0 ships that candidate as a tool rather than a gate check (ADR 0067):
   `tools/check-register.py` reads a consuming project's ADRs and index and
   reports what does not tie, and doctor reports its result as
   `decisions.register` without failing on it. Run against the adopted projects
   for that ADR, it found a fault in the standard's own starters: the seeded index
   named a register heading the seeded `CLAUDE.md` did not have. Still owed before
   this item closes: a second project running it in CI for a release, a number in
   `checks.json`, the clause that every ADR naming an open item has a row, and the
   field-note age clause.
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
9. **A pointer is not discovery — closed in 2.0.** Nothing auto-discovers `skills/`; an agent
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
   **Resolution (ADR 0062).** The candidate fix shipped: `sync.sh` installs a
   pointer skill for each shipped skill at `.claude/skills/causeway-<name>/SKILL.md`,
   where Claude Code discovers skills on its own and reads their `description` to
   decide when one applies. The pointer names the vendored skill, so the vendored
   copy stays the single source. The item was right that a named path is not
   discovery. It was wrong to wait for a practitioner session as the evidence: the
   three adopted projects surveyed for v3.0.0 had no `.claude/` directory at all,
   which is the bug observed three times rather than once. The other three tools
   still learn of skills from their adapters, and that half is unchanged.
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
11. **The setup page has one adopter's evidence.** §6's *Configure, set up, run*
   rests on one project, one maintainer, three field runs on one Linux
   workstation (ADR 0052). The four rules it states are each a fix for something
   that happened there, which is the right provenance for a rule and the wrong
   sample size for a default. Unobserved: a macOS or Windows desktop launching
   the browser, a project whose compose project name comes from the directory
   rather than `name:`, a Makefile that documents nothing (the page would offer
   nothing), and a secret the `PASSWORD|SECRET|TOKEN|KEY|CREDENTIAL` heuristic
   misses — a value that should have been generated and was pasted instead. The
   item closes against a second adopter's report, the same shape items 4 and 8
   wait on, or a field note that names a case the four rules do not cover.
12. **The reference evaluator covers a slice, not the contract.** `tools/evaluate.py`
   (ADR 0063) implements the five checks the conformance fixtures pin and the three
   closure checks, and reports every other check as `unsupported`. It does not
   implement the adoption-horizon arithmetic: where `system.json` records a
   `closed_against` older than the vendored spine, it cannot tell a newly added row
   inside its horizon from one that is owed, so the three closure checks report
   `unsupported` rather than guess. It also takes no waiver into account yet. The
   item closes when the horizon arithmetic and waiver reading land with fixtures
   of their own, which is the shape `conformance/README.md` asks of every check.
13. **A second ADR register cannot be read.** One adopting project keeps 73
   architecture ADRs in a separate concept-documents register, declared on purpose, so the spine, `impact.sh`
   and the evaluator see none of them. The backfill skill (ADR 0064) works around
   it by writing coverage ADRs in `decisions/` that cite the external record by its
   own ID, which is duplicated effort and the reason this is open. The candidate is
   a `system.json` field declaring an external register and a mapping file from its
   IDs to spine rows. It wants that project's backfill run first, so the mapping is
   designed against a real register rather than an imagined one.
