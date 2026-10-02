---
adr: "0020"
title: Anchor the prose-count guards to the claim rather than to the sentence
status: Accepted
date: 2026-08-30
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

`main` was red for four days. `tools/validate.py` reported three failures on
v1.8.0, all of the same shape:

```
FAIL  README conformance coverage sentence not found
FAIL  README product-repository count sentence not found
FAIL  README self-validation assertion count sentence not found
      the guard needs updating with the prose
```

Every number those guards protect was **correct**. The README said 9 fixtures
over 5 checks, 17 of 27 checks reading the product repository, and 476
assertions — all three derived exactly right from `expectations.json`,
`checks.json` and the run itself. What changed was the wording. The guards were
pinned to one exact sentence each:

```python
r"why (\w+) of the (\d+) checks read the \*product repository\*"
r"\*\*(\d+)\*\* conformance fixtures, exercising \*\*(\d+)\*\* of the (\d+) checks"
r"\*\*(\d+)\*\* self-validation assertions"
```

A rewrite that kept every fact and changed the phrasing failed all three.

This is the third occurrence. The v1.7.0 rewrite dropped the product-repository
sentence and went red; PR #11 fixed it by **restoring the sentence** — two added
lines, one verbatim regex feed. The v1.8.0 rewrite did the same thing to three
guards at once.

The pattern is the finding. A guard that cannot distinguish *this number went
stale* from *this sentence was rephrased* reports the second as the first, and
the cheapest route to green is to type the blessed sentence back. Its own
failure message says so: "the guard needs updating with the prose." Two of the
three recorded fixes were prose restorations. The guard had started governing
the wording rather than the fact, and the wording is the part nobody should have
to freeze.

Worth separating from a second, real failure the same commit exposed: it reached
`main` as a direct upload, unreviewed, past the required status check ADR 0016
configured. That is repository governance, not validation, and it is out of
scope here.

## Decision

The prose-count guards bind to the **claim**, not to the sentence.

An anchor is the smallest span that identifies which count is being made —
`N of the M checks read` — carrying no decoration. Every numeric match must
agree with the artifacts, and at least one must exist. Anchors are declared in
one table, `PROSE_COUNTS`, in the sense `bundle/scope.json` means declared: a
count nothing anchors is a count nothing governs.

Three properties follow, and each is the fix to one half of the old behavior:

- **Restating a count is free, and helps.** The README says 27 five times; each
  one is now checked. Under the old guard four of the five were invisible, so
  the rewrite that broke the build could equally have introduced a wrong number
  in any of them and passed.
- **A match whose captured token is not a number is skipped.** `lack conformance
  fixtures` is prose an anchor happened to span, not a claim. That is what lets
  anchors be loose enough to survive a rewrite without going silent.
- **Losing a count is still a failure, and a distinct one.** It names the derived
  value, so the remedy is visible: state the count, or add an anchor when the
  wording is right and the pattern is not.

The two product-repository guards collapse into one claim over two documents,
because a single decoration-free anchor spans both `README.md` and
`gate/gate-configuration.md` as they are written today. That collapse is the
whole of the mechanism's effect on the assertion count: a clean run of the old
code would have made 476, the new mechanism makes 475, and this ADR's own
well-formedness checks take the committed total to 482.

No prose was edited to make this pass. That is the test: the anchors match Karl's
v1.8.0 rewrite as committed, and the three failures clear without touching a word
he wrote. The only README change is the self-validation count, which moved
because the validator's own arithmetic changed.

## Alternatives considered

**Restore the sentences, again.** The status quo, and it is what happened twice
before. Rejected on the third occurrence: it is not a fix, it is a payment, and
the price goes up each time the README is rewritten. It also quietly inverts
authorship — the standard's front door ends up phrased to satisfy a regex in a
file its readers never open.

**Drop the guards.** Honest, and wrong. The guards exist because three prose
counts were wrong at v1.6.0 — 14 for what is 17, eleven for what is nine — and
nobody noticed. The failure mode they catch is real and recurring. What was
wrong is the binding, not the intent.

**Generate the numbers into the README from a template.** The airtight version:
no hand-typed count can drift if none is hand-typed. Rejected as the wrong shape
for this document. The README is the repository's front door, written to be read
and rewritten; putting it behind a build step makes editing it a tooling task and
would have prevented the v1.8.0 rewrite that is, on the merits, a better README.
Reconsider if the count of guarded numbers grows past what one table can hold.

**A machine-readable stats block the prose cites.** Rejected for now on the same
ground, plus one of its own: it moves the number out of the sentence a reader
sees, so a wrong number in the prose beside it would no longer be checked at all.

## Consequences

The README can be rewritten freely as long as its counts stay true, which is the
property the guards were always meant to have.

Rewrites that fall outside every anchor still fail — deliberately. The response
is a one-line anchor in `PROSE_COUNTS`, and the failure message says so. That is
a real ongoing cost and it is the honest one: the alternative is a guard that
goes quiet, and a quiet guard is how the v1.6.0 counts got wrong in the first
place.

`checked` remains self-referential: adding a check changes the number the README
must state. This ADR does not fix that, and the assertion-count guard keeps its
own code path because `checked` is not final until every other check has run.

Anchors are now a reviewable surface. A loosened anchor is a weakened guard, and
it should be read as one in review.

This is a `tools/` and `README.md` change. Both are outside the digested bundle
per `bundle/scope.json`, so no bundled file moved, the digest is unchanged, and
no release is required. Consumers are unaffected.

## Evidence

`tools/validate.py` §16, `PROSE_COUNTS` and the loop below it.

`./tools/validate.py` — 482 passed, clean, with no prose edited except the
self-validation count. Seven of the 482 are this ADR's own frontmatter checks.

The guard was deliberately made to fail, three ways:

| Mutation | Result |
|---|---|
| `Seventeen` → `Sixteen` in README | `FAIL … agrees with the artifacts in all 2 places it is stated` — `README.md: 'Sixteen of the 27 checks read' — the artifacts say (17, 27)` |
| Count removed from both documents | `FAIL … is no longer stated in prose` — names `(17, 27)` and the remedy |
| Sentence rewritten, number kept true | `checks passed — the standard ties to itself` |

The third row is the case that broke `main`, and it is the one that now passes.
