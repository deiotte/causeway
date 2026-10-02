# Field notes

<!--
  Seeded once by tools/sync.sh, then owned by this project. It also exists so
  this directory is committable at all: git tracks files, not directories, and a
  register that vanishes on clone is not a register.
-->

One file per note. One thing you know per note.

New here and not a developer? Read [`START-HERE.md`](../../START-HERE.md) at the
top of this repository instead. It is written for you and it is shorter than this
directory will be.

## Writing one

Easiest path: go to [claude.ai/code](https://claude.ai/code), open this project,
say what you know, and ask for a field note. It will interview you, write the
file, and open the pull request. You do not have to touch anything here.

By hand: copy the template, take the next number, fill in the five prompts.

```
cp templates/field-note.md domain/field-notes/0001-short-title.md
```

Leave the Disposition block empty. The reviewer owns it. A note that marks its
own homework is not being reviewed.

## Reading them

| Field | What it tells you |
|---|---|
| `confidence` | `seen-it`, `fairly-sure`, or `suspect`. Never upgrade one, here or on the way into an ADR. |
| `status` | `new`, `in-review`, `promoted`, `closed`. |
| `promoted_to` | Where it landed: an ADR, a test, a `CLAUDE.md` line, or the place it was already handled. |

`status: new` sitting here for weeks is the process failing, and it is the first
thing worth reporting. Every note reaches a disposition and its author gets told
which — including "already handled", which is a real outcome and still names
where. The author is the one person qualified to check that the existing handling
is actually right.

A register nobody answers teaches the people who filled it to stop.
