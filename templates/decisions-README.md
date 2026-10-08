# Decisions

<!--
  Seeded once by tools/sync.sh, then owned by this project. It also exists so
  this directory is committable before the first ADR lands: git tracks files,
  not directories, and a register that is not there yet is a register nobody
  starts.
-->

One decision per file. One file per decision.

New here? [`CONTRIBUTING.md`](../CONTRIBUTING.md) is the walk-through. The rules
are Build DNA §8 in [`AGENTS.md`](../AGENTS.md); this file is the short version,
plus the index at the bottom, which is the part only this project can write.

## Writing one

Copy the template, take the next number, fill it in, and add a row to the index
below — in the same pull request as the code that encodes the decision.

```
cp templates/adr-template.md decisions/0001-short-imperative-title.md
```

Three templates, one per shape of decision:

| You are recording | Template |
|---|---|
| A choice between real alternatives | [`adr-template.md`](../templates/adr-template.md) |
| A row you are deliberately not closing yet | [`adr-waiver-template.md`](../templates/adr-waiver-template.md) — expiry, risk accepted, a named acceptor |
| A row the spine added after this system shipped | [`adr-retroactive-template.md`](../templates/adr-retroactive-template.md) — as-built answer first, corrected design last |

Quote the number in the frontmatter: `adr: "0010"`, never `adr: 0010`. YAML
reads an unquoted leading zero as octal, so `0010` parses as 8 and nothing
complains. Causeway ADR 0017 learned that the slow way.

## Numbering

- **Four digits, zero-padded, next free number.** `0001`, `0002`, and so on. The
  number is an identity, not a rank.
- **Never reused and never renumbered.** Other ADRs, the open-items index, the
  exceptions register in `CLAUDE.md` and comments in code all point at these
  numbers. Renumbering is how a pointer comes to name a different decision than
  the one it cited.
- **A skipped number is allowed and stays skipped.** Two branches take the same
  number and one is abandoned; a draft is withdrawn before it merges. Do not close
  the gap. Record it under *Unused numbers* below with one line saying why, so the
  next reader does not go looking for a file that was never there.

## Immutability

An accepted ADR is a record of what was decided and why, as of its date. Its body
is not edited. What you do instead depends on what changed:

| What happened | What to do |
|---|---|
| You changed your mind | A new ADR with `supersedes:` naming the old one and a `supersession_cause:` (S1–S5, Build DNA §8). Set the old one's `superseded_by:` and its status to `Superseded`. |
| The old ADR states a fact that was wrong | A new ADR with `corrects:` naming it. Set the old one's `corrected_by:`. The wrong sentence stays; the pointer to the right one is what a reader needs. |
| A waiver expired or the risk changed | A new ADR closes the row, or a new waiver with a new expiry. An expired waiver is a gate failure, which is the point. |
| A typo, a broken link, a formatting slip | Fix it. Immutability protects the argument, not the markdown. |

Frontmatter is the mutable half by construction: `status`, `superseded_by` and
`corrected_by` cannot be known when an ADR is written, so filling them in later
is the design and not a breach.

## Reading one

| Field | What it tells you |
|---|---|
| `status` | `Proposed`, `Accepted`, `Deferred`, `Waived`, `Deprecated`, `Superseded`. Only `Accepted` is a decision in force. |
| `spine_rows` | The Decision Spine rows this closes. Empty is legitimate for a process-only decision; say so in a comment. |
| `door` | `one-way` or `two-way`, read from the spine row. One-way doors close before production code. |
| `approver` | A named person, required on the eight † rows. A role is not a name. |
| `forces` | The Survey rows that made one alternative win *here*. An ADR with no forces is one preference away from being reopened. |
| `revisit_if` | The condition under which reopening this is legitimate rather than churn. |

## What an ADR leaves behind

An ADR that declines a question, defers a guard, or publishes a gap opens an
**open item**. The item's argument lives in prose, in the document it belongs to.
Its state lives in [`open-items.json`](open-items.json). If your ADR opens or
closes one, edit the index in the same pull request. Build DNA §8 has the rules;
the short version is that nobody can say how many items are open by reading
prose, and the index is what counts.

## Index

By family, not by number: the number says when, the family says what it is about.
One row per ADR, added in the pull request that adds the file. A superseded ADR
keeps its row and gains a pointer.

Nothing checks this index in a consuming project yet — the same gap Build DNA
open item 6 records for `open-items.json`. A row missing here is a decision
nobody can find from the front, and the reviewer is the check.

### [FAMILY — e.g. "Data model", "Integration boundary", "Platform"]

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-short-imperative-title.md) | [Title, as written in the frontmatter] | Accepted |

### [FAMILY]

| ADR | Decision | Status |
|---|---|---|
| | | |

## Unused numbers

None yet. When a number is skipped, it gets a line here: the number, and why.
