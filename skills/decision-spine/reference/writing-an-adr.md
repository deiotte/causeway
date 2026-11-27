# Writing an ADR

How to write the record once the decision is ready to be recorded. Build DNA §8
says what an ADR must carry and `templates/adr-template.md` gives it its shape;
this file is about the part neither can enforce, which is whether the record is
true. The `causeway-adr-author` agent follows it, and so should anyone writing
one by hand. ADR 0068.

The rules came from an adopting project that had been writing ADRs in its own
house style before it pinned Causeway, and whose records were the most useful
anyone reviewing the fleet had read. Three habits made the difference: the record
never described the system as doing something it did not do, its consequences
included the ones its authors disliked, and every path it cited was checked.

## Before writing a word

1. **Is it ready?** Where a Survey exists, only a `READY` row becomes an argued
   ADR (Build DNA 8.2). A `BLOCKED` or `PROBE` row records its blocker or its
   probe instead. A row with nothing to decide closes with a coverage ADR (8.8),
   which is four lines and no alternatives.
2. **Read the register.** `decisions/README.md` for the index and the families,
   and the highest number in `decisions/`. Read two ADRs near the one you are
   writing, so the new one sounds like the register it joins.
3. **Read the code the decision touches.** Find the modules, configuration and
   tests it governs and read them. An ADR that describes the system inaccurately
   is worse than none, because the next reader trusts it.
4. **Read what it must not contradict.** The project's `CLAUDE.md` (its
   constraints, its exceptions register, its domain facts), any architecture
   document it names as the source of truth, and the Survey rows the decision
   rests on. If the decision contradicts one of them, the ADR says so in its
   Context. Diverging quietly is how a project ends up with two answers.

## The number and the name

- **Next number: the highest in `decisions/`, plus one.** Never reuse one, even
  for a record that was later superseded. A number skipped on purpose gets a line
  under *Unused numbers* in `decisions/README.md`.
- **Quote it:** `adr: "0012"`. YAML reads an unquoted leading zero as octal.
- **The title names the decision, not the topic.**
  `0012-queue-on-the-broker-the-platform-runs.md` beats `0012-queueing.md`. A
  reader scanning the index should learn what was decided without opening it.
- **One register.** ADRs go in `decisions/` (Build DNA 8.1). A project that also
  keeps records somewhere else, from before it adopted, has two answers to "what
  did we decide", and the gate reads only one of them. Write new records here,
  and bring old ones over with the `causeway-backfill` skill.

## Status is a claim about the tree

`Accepted` is written in the pull request that carries the decision, and the
approver's merge is the approval (Build DNA 8.7). That makes the status a claim
about what the repository will hold once the pull request merges, so hold it to
that:

- **Never describe the system as doing something it does not do.** If the code
  that implements the decision is in this pull request or already on the default
  branch, cite it in *Evidence*. If it is not built yet, which is normal for a
  one-way door that has to close before production code, *Evidence* says
  **not yet built** and names what will show it: the open item, the probe, the
  test that does not exist yet. An Accepted ADR whose *Evidence* points at code
  that is not there is the failure this rule exists for.
- **Write `Proposed` only when the approver asks to hold it open**, and then give
  it a section headed *Open questions before this can be Accepted*: what has to be
  true, and who can make it true. A Proposed record with no such section is a
  decision nobody can finish.

## The sections that carry the weight

- **Context explains the forces, not the solution.** What constraint, physical
  fact, schedule pressure or contradiction made this hard? The reader should feel
  the pressure before reading the answer. Cite the Survey rows by ID in `forces`
  (`GR-`, `DEC-`, `TH-`, a policy clause); a decision justified by preference is
  reopened by the next preference (8.3).
- **Alternatives are real.** At least one option a reasonable engineer would
  have picked, and the specific reason it lost *here*. A coverage ADR is the one
  record allowed to have none.
- **Consequences include the ones you dislike.** What this costs, what it
  forecloses, what breaks if the assumption under it turns out wrong. An ADR
  with only upsides is marketing, and anyone with judgement will discount the
  whole register for it. The **Security** line is required and "None" is an
  answer; a blank is not.
- **Revisit if names a condition someone could check.** "If sustained load
  exceeds 10k messages a second" is a revisit condition. "If our needs change" is
  not.
- **Evidence cites paths, ideally with line ranges, and every one exists.**
  Check each path before you finish. A reference to a file that was renamed is a
  pointer that survived the thing it pointed at.
- **Plain, declarative prose.** Active voice, short paragraphs, no hedging that
  hides what was decided. Tables for option comparisons and field layouts, and
  not much else.

## In the same pull request

- A row in the `decisions/README.md` index, under its family.
- If the ADR opens or closes an open item, the row in
  `decisions/open-items.json` and the recomputed counts (8.11).
- **Superseding:** the new record names `supersedes` and a `supersession_cause`
  (S1–S5, 8.4); the old one gets `superseded_by` and status `Superseded`. Its
  body is not edited. Every spine row the old record closed is re-closed by the
  new one or by another live ADR.
- **Correcting a fact:** the new record names `corrects`, the old one gains
  `corrected_by`. The wrong sentence stays; the pointer is what a reader needs.
- If a document elsewhere covers the same ground, point the two at each other.

Then run `python3 tools/check-register.py`. It finds the half of a supersession
that was written one way, the row the spine does not have, the count nobody
recomputed. It cannot tell you whether the argument is any good; the reviewer
does that, and the sections above are what they will read for.
