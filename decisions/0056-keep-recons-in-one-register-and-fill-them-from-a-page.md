---
adr: "0056"
title: Keep every Recon in one private register, and fill it in from an offline page built from the template
status: Proposed
date: 2026-11-04
spine_rows: []         # process layer only; closes no design row
survey_rows: []
forces: []             # not Survey rows — see the Forces section
door: two-way
revisit_if: A team that runs Recons reports that the register went unsearched — the
  same problem was reconned twice and the second team never found the first — or that
  records were kept somewhere other than the register because the page was too hard
  to use. Also revisit if a second capture surface (an issue form, a docs connector)
  is proposed, because each surface is one more place the template's shape can fork.
approver:
  name:
  role: Maintainer review pending
supersedes:
superseded_by:
supersession_cause:
corrects: []
corrected_by: []
---

## Context

ADR 0055 added the Recon: a two-page record of a first session with a problem owner,
which decides whether there is anything to build. It said what goes in the record. It
did not say where the record goes, and the gap matters most in the case the Recon
exists for.

A Recon that ends in **go** has an obvious home: the new project repository. A Recon
that ends in **no-go** has none. The only places available were a repository created
to hold it, a chat transcript, or nobody's disk. A repository per denial is a
graveyard nobody searches. A chat transcript is the place the Survey already rules out:
"a spec that lives only in chat scrollback is not a spec." Nobody's disk is the default,
and it means the template's own instruction, that a no-go's one line is "what the next
person who walks this route starts from," cannot be followed.

The maintainer raised the question on 2026-11-04, together with a proposed answer: a
single-page HTML intake whose output is pasted into an AI chat with the other
artifacts when a project repository is stood up. The capture half of that proposal is
adopted here. The storage half is not: the chat is a step, not a home.

## Forces

- **A no-go has to be findable, or it was not worth writing.** Its value is to the
  next team with the same problem. That team searches one place or none.
- **The people running Recons often cannot install anything.** Discovery happens on
  borrowed machines, in offices, with whatever is there. Build DNA §3 says an install
  path may not assume the target's toolchain. A page that opens from a file in any
  browser assumes nothing.
- **A form that restates the template is a fork of it.** Build DNA §6 states this for
  the setup page: one contract, no second list. ADR 0052 built that page to read
  `.env.example` and nothing else, for exactly this reason. The same rule applies
  here, and ADR 0055 made the template's IDs something the Survey reads.
- **A Recon is sensitive.** It describes a real office, its systems, its pain and its
  data. Spine SA-5.16 governs what crosses to a model. A record whose own R2 forbids
  pasting real data into a model "to see whether the idea has legs" cannot then be
  pasted anywhere without the same check.
- **Causeway is public.** ADR 0037 published it under Apache-2.0. Nothing that
  describes an adopter's problem belongs in it.

## Decision

**Every Recon lives in one private register per team. It is filled in with an
offline page that is built from the template and carries it.**

- **The register.** One private repository, or one folder in one, holding every
  Recon, go and no-go alike, one file per Recon, with an index. `templates/recons-README.md`
  seeds it. A team copies it once and owns it. `sync.sh` does not seed it, because the
  register is not a project. A Recon never gets a repository of its own and never
  goes in the Causeway repository.
- **Go and no-go.** On a go, the project repository gets a copy as `recon.md`, the
  record's new `Project repository` header field and the register's index link to it,
  and the Survey starts from it. On a no-go, the register entry is the whole record.
  No-go records are never deleted.
- **The page.** `tools/recon/recon.html` is one file: no network, no install, nothing
  fetched. It shows each blockquote in the template as guidance and each
  `{{prompt}}` as a field. Tables gain an add-row button that continues the ID
  sequence. Work autosaves in the browser. **Copy markdown** and **Download .md**
  produce the record with the guidance left out and unfilled prompts left visible, and
  a counter shows how many remain.
- **Built from the template, never beside it.** `tools/recon/build_page.py` embeds
  `templates/recon.md` into the page, and the page parses that text when it opens.
  `tools/validate.py` and CI fail when the shipped page does not match the template.
  The template gains one convention to make this work: **every blockquote is
  guidance, and everything else is the record.** Its guidance paragraphs moved into
  blockquotes accordingly, and no field changed meaning.
- **The chat is a step.** The page offers **Copy for an AI review**: the record plus
  instructions to list gaps, unsourced numbers and estimate lines resting on assumed
  rows, and not to invent answers or renumber. The button stays disabled until the
  user ticks that the model they are pasting into is authorized for the data. Whatever
  the review produces goes back into the file.
- **Shipped like the template.** The page is vendored, digested and archived. The
  register README is archived, so a team without git can get it from a release. The
  page's source, builder and tests are this repository's machinery and are declared
  in `bundle/scope.json`.

## Alternatives considered

**One repository per Recon.** Rejected. A no-go would leave a repository whose only
content is a denial, and the search a later team needs would span every repository
the organization owns.

**The chat as the record.** This was the proposal's storage half. Rejected for the
Survey's reason: scrollback is not a spec. It is also not searchable by the next team,
not confirmable by the problem owner, and governed by whatever data policy the chat
provider has. The chat stays as a review step.

**A GitHub issue form in the register.** It is attractive because the team already
uses GitHub's website, and the field-note path works this way (ADR 0028). Rejected for
now: issue forms flatten tables, and R1 through R6 are mostly tables whose IDs must
survive. An issue form would be a second capture surface, and every surface is one
more place the shape can fork. Named in *Revisit if*.

**A hand-written HTML form.** Faster to write. Rejected: it is the second contract §6
forbids, and it would drift the first time the template changed.

**A page that fetches the template from the network.** It would need no build step.
Rejected: the page must work on a machine with no network, and a page that fetches
cannot prove which version of the template it rendered.

## Consequences

**Easier.** A no-go has a home and a reader. A Recon can be filled in during the
meeting on any machine with a browser. The record that comes out has no guidance to
delete and shows exactly which prompts are still open. An agent asked to review one
gets instructions that match the template.

**Harder.** The template now has a structural rule, blockquote means guidance, and
a contributor who writes a rule as a plain paragraph puts it into every record. The
page rebuild is one more step after a template edit. CI requires node to test the
page's logic, and fails rather than skips when node is missing.

**Declared gaps.**

- **The page does not re-open a saved record.** It autosaves in one browser. After
  that, the record is edited as markdown on GitHub. Importing markdown back into the
  form is possible and is not built, because nobody has asked for it yet.
- **The register is unchecked.** No tool reads it. The index is hand-maintained, like
  `decisions/README.md` in a consuming project, and it rots the same way when nobody
  updates it.
- **Authorization is an honor-system checkbox.** The page cannot know what a model is
  authorized for. The checkbox makes the question unavoidable, but it does not answer it.

## Revisit if

The same problem was reconned twice because the register went unsearched. Records were
kept outside the register because the page was too hard to use. Or someone proposes a
second capture surface. The first two mean the register is not doing its job. The
third needs the same built-from-the-template rule applied to it, or it should not ship.

## Evidence

- `templates/recon.md`: the *Where it lives* and *How to fill it in* guidance, the
  `Project repository` header field, the blockquote convention, and a fill line under
  each section that previously had only guidance.
- `templates/recons-README.md`: the register's rules, the GitHub-website steps, and
  the index.
- `tools/recon/recon.src.html`, `tools/recon/build_page.py`, `tools/recon/recon.html`.
- `tools/recon/test_recon_page.py`: structural tests (page current, template embedded
  verbatim, no network references, rectangular tables), plus core-logic tests under node.
- `tools/validate.py` §23 and the *Recon page* step in `.github/workflows/standard.yml`.
- `skills/survey/SKILL.md`: *Where a Recon lives* and *Filling it in*.
- `tools/sync.sh`, `tools/build-bundle.sh`, `tools/build-archive.sh`, `bundle/scope.json`.
