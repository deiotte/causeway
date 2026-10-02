---
note: "0000"              # next number in domain/field-notes/. Quoted, four digits.
title: <what you know, in one line>
author:
  name:
  role:
  years_in_the_work:      # the credential that matters here. Not a formality.
date: YYYY-MM-DD
confidence: seen-it       # seen-it | fairly-sure | suspect
status: new               # new | in-review | promoted | closed
promoted_to: []           # filled in by the reviewer, never by the author
---

<!--
  A FIELD NOTE is one thing a practitioner knows, written the way they would say
  it out loud. It is the ADR's twin: same discipline, none of the vocabulary.
  An ADR records a decision somebody made. A field note records a fact about the
  world that a decision will have to survive.

  Prose, not bullets, wherever you have a choice. A story survives being
  re-read by a stranger in a year. A bullet list does not.

  Five prompts. Answer what you can. An unanswered prompt is information too —
  leave it and say why, rather than filling it with something you do not believe.
-->

## What happens

The situation, concretely. Where you are, what you are doing, what the system is
doing. Write it as one specific occurrence you actually remember rather than as
a general description — the specific one carries detail the general one loses,
and the general version is easy to reconstruct from it later.

## What goes wrong

The failure. Be exact about the moment it goes wrong, which is usually earlier
and quieter than the moment somebody notices.

If it has gone wrong more than once, say how many times and whether the cause
was the same each time.

## What it should do instead

The correct behavior. If the correct behavior depends on something — a
condition, a threshold, who is asking, what time of year it is — that dependency
is the valuable half of this note. Say it even if you cannot make it precise.

"It depends, and here is what it depends on" is a complete and useful answer.
"It depends" alone is not.

## How you would know it was wrong

The tell. If the system handed you an answer, what would make you distrust it
without checking anything else?

This is the prompt that most often turns into an automated test, because it is
the only one written from the outside. Spend your time here.

## What it costs when it is missed

The consequence, in whatever unit is real: money, time, a reportable event, a
safety margin, somebody's afternoon, a finding at audit. An estimate with a
stated basis beats a blank, and beats a confident number with no basis.

This is not paperwork. It is how your note gets ranked against everything else
competing for the same week of engineering time, and a note with this section
empty ranks last by default.

---

## Disposition

<!--
  REVIEWER FILLS THIS IN. The author never does.

  Every note reaches one of the four outcomes below and the author is told
  which. A note that sits here with no disposition is the failure this whole
  path exists to prevent: expertise collected, acknowledged, and then not used.
  The person who wrote it will notice, and they will be right to stop writing
  them.
-->

- **Reviewed by:**
- **Date:**
- **Outcome:** ADR | test | `CLAUDE.md` constraint | closed as already handled
- **Landed at:** <ADR number, test path, file and section, or where it was already handled>
- **Told the author:** yes / no

> Closed as already handled is a real outcome, not a polite no. It still needs a
> `Landed at`, because the author is the one person qualified to check that the
> existing handling is actually correct — and that check is worth more than the
> note would have been.
