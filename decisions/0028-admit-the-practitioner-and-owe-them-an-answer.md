---
adr: "0028"
title: Admit the practitioner, and owe them an answer
status: Accepted
date: 2026-09-11
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
corrects: []
corrected_by: []
---

## Context

Every artifact this standard defines is authored by someone who can read a
repository. An ADR, a spine row, a gate check, a waiver, a receipt — each one
assumes its author is a software person, and none of them says so, because until
now nothing needed it said. That is a coherent boundary for an engineering
governance contract and it has a cost the standard has never named.

The cost is that the facts a decision is made against do not live with the people
making the decision.

A practitioner with thirty years in a specialized environment knows what fails in
the field and how early, what the written rule means once it has met practice for
a decade, and which two cases look identical and are not. None of that is
derivable from the code, by anyone, at any level of skill. Today it reaches the
build through a developer's paraphrase or it does not reach it at all, and the
paraphrase reliably drops the conditional — the *unless it is the fourth quarter*,
the *only when the upstream feed is late* — which was the half worth having.

The tempting response is to hand them the standard. That fails, and the reason is
worth stating precisely rather than treating as a matter of taste. `AGENTS.md` is
just under seven hundred lines. The README opens with a bundle digest. Neither
document is badly written; both are written for somebody else. A practitioner
reads four paragraphs, concludes the work is not for them, and is drawing a
correct inference from the evidence in front of them. What arrives in the repo is
then selected for tolerance of process rather than for depth of knowledge, which
inverts the entire point.

The shape of the answer was already here, aimed one role over. The Reader floor
is a single sentence — read the project's `CLAUDE.md`, that is the whole
obligation — and it works because it asks for nothing the reader has no use for.
The same generosity, extended to somebody who is contributing something more
valuable than code, is the whole of this change.

There is a second half to the problem and it is the half that actually kills
these efforts. Collecting expertise is easy and answering it is not. An
organization that collects and does not answer gets exactly one round of
contributions, because the people who wrote the first round are precisely the
people sharp enough to notice that nothing happened, and they will quietly stop.
That failure is invisible from the inside — the notes stop arriving and it looks
like disinterest. A capture mechanism without a matching disposition obligation
is a suggestion box, and a suggestion box is how an organization finds out two
years late that it had been told.

## Decision

Causeway admits a fourth adoption role, gives it an artifact, and binds the
answer it is owed.

**The Practitioner role enters Build DNA, which moves to 1.10.** Its floor is the
project's `START-HERE.md` and it owes `AGENTS.md` nothing. That exemption is
deliberate and is the load-bearing part: a contract that made subject-matter
expertise pass a reading test would collect less of it, from fewer people, later.
Three of the four roles remain a ladder of increasing obligation; this one is
beside the ladder rather than on it.

**A field note is the artifact, and it is the ADR's twin.** An ADR records a
decision somebody made. A field note records a fact about the world that a
decision will have to survive. Five prompts, in the practitioner's language, with
one structural field that carries real weight: `confidence` is `seen-it`,
`fairly-sure`, or `suspect`, and it is never upgraded — not in the note and not on
the way into an ADR built on it. All three are useful; recording them as the same
claim is the one move in this path that does damage downstream.

**`skills/field-note/` governs the interview, and its first rule is that the agent
does not supply the content.** An agent can write a plausible field note from a
single sentence of prompt, and doing so captures the model's priors wearing a
practitioner's name — worse than no note, because it will be trusted. The skill
is therefore written mostly as constraints on the interviewer rather than as a
format.

**Four surfaces are seeded into consuming projects, and none of them requires a
terminal.** `START-HERE.md` is the front door. A GitHub issue form is the path for
somebody on a phone between meetings. `domain/field-notes/` is the register, and
it ships with its own README because git tracks files rather than directories and
a register that does not survive a clone is not a register. `.github/CODEOWNERS`
is the guardrail, and it is shipped saying out loud that it is half of one: it
nominates reviewers and branch protection is what requires them, which is a
repository setting no script can write. That is the shape ADR 0016 already
records for the gate, and a practitioner given write access under an unenforced
CODEOWNERS can merge their own note.

**A note is an input, not an index entry, until it leaves something open.** The
project's `decisions/open-items.json` already has the vocabulary a disposition
wants — status, the ADR that opened a row, the ADR that closed it, and an
`answered_by` edge naming the document that settled a question. What it must not
become is a second numbering of the note directory. So a note earns a row when
the ADR that read it declined part of its question or deferred a guard, and not
before; a note closed against a document that already answers it is an
`answered_by` edge; and a note whose promotion left nothing open needs no row,
because the register of notes already records it. This is the rule the ServiceNow
overlay states one artifact over for skip records and Instance Scan findings, and
it is stated here for the same reason: the thing worth tracking was never the
note, it was the answer somebody owed.

**The reciprocal obligation is stated in the role, not in a guide.** Every note
reaches one of four dispositions — an ADR, a test, a `CLAUDE.md` constraint, or
closed against the place it is already handled — and its author is told which.
Closed is a real outcome and still names where, because the author is the one
person qualified to confirm the existing handling is right, and that confirmation
is frequently worth more than the note would have been. Putting this in Build DNA
rather than in the skill is the point: it is an obligation the repository's
maintainer takes on, in the document that states what maintainers owe.

## Alternatives considered

**Teach them the standard.** The honest version of this costs a practitioner a
week and produces a worse contributor than the afternoon they would otherwise
have spent telling somebody what they know. It also puts the cost on the person
with the least slack and the most irreplaceable input.

**Keep routing everything through a developer interview.** This is the status
quo, so its failure modes are observed rather than predicted: it is a paraphrase
chain, the developer is a bottleneck, and the developer cannot reliably tell
which of the practitioner's sentences was the expensive one, because identifying
that is itself the domain expertise.

**Let practitioners write ADRs, with a gentler template.** Rejected on the seam.
An ADR records a decision somebody had the authority to make, and it reads as
settled. A practitioner has a fact, sometimes a suspected one. Filing a
`suspect`-grade observation in a document that reads as settled is exactly the
laundering the `confidence` field exists to prevent, and it would also put §8's
immutability rules in front of someone who came here to describe a failure they
watched.

**Make the disposition obligation a gate check now.** The check is easy to write
and the threshold is not: any age limit chosen before anybody has run the process
is a number invented to have one. It also has no honest home in the 27: a
register going stale is a condition of a repository over time, not a property of
a proposed change.

**Open the disposition gap as its own item.** Drafted, then withdrawn before it
shipped. Build DNA open item 6 already asks this question — the standard states a
rule about the index, nothing checks it in a consuming project, the candidate
check exists, and it wants one adopter's evidence — and a note left at `status:
new` is an index row nobody moved. The argument for a second item was that notes
are a different artifact from ADR open items, and the input-not-entry rule above
is what dissolves it: a note that matters to the index is already an index row,
opened by the ADR that read it. Two numbers for one question is how a register
comes to disagree with itself, which is the failure ADR 0025 exists to prevent,
so item 6 gains the clause instead and the second number was never published.

**Ship the on-ramp outside the standard.** Faster, and it drifts inside three
releases. More to the point, a role the standard does not name is a courtesy
rather than a role, and courtesies are withdrawn under schedule pressure exactly
when the expertise is most needed.

## Consequences

Build DNA is 1.10. The ServiceNow overlay is reconciled to it and moves to 1.7
rather than having its version field bumped: the platform has the densest
concentration of this role anywhere Causeway runs and the least room for it, so
§7 gains a real translation. Two platform traps are named — native surfaces that
look like field notes and are inputs rather than entries, and a note being a
property of the application rather than the instance — and one declared gap,
which is that update-set-only delivery has no repository, so it has no front
door, no register and no pull request. That is the same missing surface already
declared for the open-items index, and this overlay declines to nominate a table
to stand in for it.

The consumer bundle goes from 24 files to 26. The skill and the note template are
digested because a project that quietly edited either one would still be
producing something it called a field note while the promotion rules read a
different artifact. The four seeded surfaces are declared ungoverned in
`bundle/scope.json`, on the same terms as `templates/project-CLAUDE.md`: each
carries per-project names, labels, links or teams, and pinning them would make
every correctly filled-in copy read as drift. CODEOWNERS ships with `@ORG/TEAM`
placeholders rather than a guess for the same reason it is shipped at all: a
reviewer map naming teams that do not exist nominates nobody and fails silently,
which is the one failure mode a guardrail must not have.

The maintainer inherits a standing obligation. This is a real cost and it is the
half that lapses quietly, which is why it is written into the role and opened as
Build DNA open item 8 rather than asserted as free.

One open item is opened and none is closed by this ADR. Item 8 is the
Practitioner floor's unmeasured cost, which is the first floor with a second
party — half an hour of a practitioner's time buys a standing obligation from
somebody else, and neither number has been observed. Item 6 is amended rather
than joined by a sibling: it now covers field-note dispositions, and its
candidate check gains one clause about an undisposed note, with the age the part
that needs an adopter.

One finding arrived on the way and is recorded because it is this repository's
recurring shape, one register over. The bundle file count is stated three times in
the README and was checked by nothing. This change is the first in the
repository's history to move that number, and all three statements went stale in a
single commit. Nothing had caught it because the count had been 24 since the
bundle existed, and every restatement had therefore been accidentally correct for
its whole life. A number that has never moved is not a verified number; it is an
untested one. It is anchored in `PROSE_COUNTS` now, which is where every other
derived number in this repository already lives.

What this does not do: no gate check reads a field note, a disposition, or the
register, and `validate.py` is the standard's own validator and does not ship
(item 6). No project that did not author this standard has run the path (item 8). The interview quality rests on a skill rather than on anything
enforceable, and a shop delivering by update set has no repository to put any of
it in. Nothing here can turn on branch protection, so the guardrail CODEOWNERS
half-describes is completed by a human in repository settings or not at all.

## Evidence

- `AGENTS.md` — Adoption section, the Practitioner role; the cost paragraph under
  *What this contract is not*; open items 8 and 9.
- `skills/field-note/SKILL.md` — the interview constraints and the promotion
  table.
- `templates/field-note.md`, `templates/practitioner-START-HERE.md`,
  `templates/field-note-issue-form.yml`, `templates/field-notes-README.md`,
  `templates/CODEOWNERS`.
- `tools/sync.sh` — two vendored entries, four seed-once blocks.
- `tools/build-bundle.sh` and `bundle/manifest.json` — 26 digested files.
- `bundle/scope.json` — four ungoverned declarations with their reasons.
- `overlays/servicenow.md` §7 — the Practitioner translation and its declared gap.
- `tools/validate.py` — the `bundle file count` entry in `PROSE_COUNTS`.
- `decisions/open-items.json` — item `build-dna-8`; `build-dna-6` unchanged in
  the index and amended in the prose register it points at.
