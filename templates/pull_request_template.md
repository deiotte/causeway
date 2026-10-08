<!--
  Seeded once by tools/sync.sh into .github/pull_request_template.md, then owned
  by this project. Keep the Causeway section; replace the bracketed project
  section with this project's own rules. ADR 0035.

  An unchecked box with one sentence saying why is a better PR than a checked
  box that is not true.
-->

## What and why

<!-- One or two sentences: what was asked, and why. Link the task or issue. -->

## How I checked it

<!-- Tests added or changed, and what you ran by hand. For a bug fix: did the new
     test fail before the fix? -->

## Causeway

- [ ] I know which gate profile this project builds under (`system.json` → `gate/profiles.json`)
- [ ] Changed behavior ships with tests, unhappy paths included; the suite passes locally with no network
- [ ] One prompt, one commit — or this is a declared spike: <!-- say so here -->
- [ ] A choice between real alternatives? → a new ADR in `decisions/` in this PR, with its row in `decisions/README.md`
- [ ] Opens or closes an open item? → `decisions/open-items.json` updated in this PR
- [ ] No vendored file edited; `tools/check-drift.sh` passes
- [ ] Deviates from the standard? → a row in the `CLAUDE.md` exceptions register, pointing at its ADR
- [ ] New dependency? → pinned exactly, justified here, checked against `rules/dependencies.md`
- [ ] No secrets, credentials, or real data anywhere in the diff
- [ ] Learned an environment quirk the hard way? → added to `CLAUDE.md` so the next session inherits it

## [CALLSIGN]

<!-- This project's own rules. Replace these examples with yours. -->

- [ ] [PROJECT RULE — e.g. "annotations stay append-only"]
- [ ] [DOCS — e.g. "README / ROADMAP updated if this changes what they say"]
