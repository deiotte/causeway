# Conformance fixtures

Sample repositories with known-correct outcomes, and the outcomes themselves in
`expectations.json`.

The point is the direction of the dependency. These fixtures are written against
the standard, not against any engine. An engine passes conformance or it does
not, and when it does not, this directory is the arbiter — not a discussion about
what the check was probably meant to do.

## Running them

The standard cannot execute them. That is the whole design (`gate-configuration.md`
§1, §11). Conformance is run *by an engine*, against this directory:

```bash
# from the engine's repository, against a vendored or checked-out standard
<engine> causeway conform --standard /path/to/causeway
```

An engine claiming Causeway conformance at a version runs every fixture in scope
and matches `expect` exactly — the per-check verdicts, the exit code, and any
`evidence` keys the fixture pins.

## What a fixture is

A minimal product repository: a `system.json`, a `.causeway-lock`, a `decisions/`
directory, and whatever ecosystem files the check under test reads. Nothing in a
fixture is realistic beyond the check it exercises, and nothing in it is
accidental.

`g2-compliant` is the baseline — everything in scope passes. Every other fixture
is `g2-compliant` with exactly one thing changed, so a failure names its own
cause. When adding a fixture, copy the baseline and change one thing.

## Scope, stated honestly

`expectations.json` covers the **five checks in the Phase 1 vertical slice**, not
all 27. The five were chosen to exercise every input class the slice needs —
`repo-lock`, `repo-decisions`, `repo-manifests`, `system-record`, `repo-tree` —
rather than to be representative of the standard.

The remaining 22 get fixtures as engines implement them. A fixture with no engine
executing it is an untested assertion that reads like a guarantee, and shipping 27
of those would make this directory worse than empty.

## The pinned evaluation date

`evaluated_at` is `2026-08-09`, and an engine must evaluate the fixtures as though
that were today rather than reading the wall clock.

Two of these fixtures are date-sensitive: `stale-lock` asserts an age of 581 days,
and `g2-compliant` asserts a lock young enough to pass a 180-day threshold. Left
against a real clock, the first drifts and the second turns red roughly six months
after it was written, and a conformance suite that changes verdict on its own is
one people learn to ignore.

It has a second use. An engine that can be told what time it is can reproduce an
old receipt; one that reads the clock cannot. Accepting an evaluation date is
therefore a conformance requirement in itself, and this is where it gets tested.

## The two fixtures worth reading before the others

**`evaluator-error`** contains an ADR that is not valid UTF-8. The correct verdict
is `error`, and at G2 it blocks. Any of `pass`, `warn`, `advisory`,
`not_applicable` or `skip` is a conformance failure, which is why the fixture
states them as a prohibition rather than trusting the expectation alone.

This is the fixture that catches the most dangerous single behavior an engine can
have: reducing a check that crashed to a warning. A check that found no missing
approvers and a check that could not look are the same colour on a dashboard and
opposite facts about the system.

**`retired-composition-state`** sets `composition-state` to `greenfield` — the
value SA-3.13 carried before ADR 0008 reconciled it. An engine still accepting the
retired answer set passes this fixture, and passing it is the failure. It exists
because that drift survived several revisions in three files without anything
noticing, and a regression fixture is the only thing that makes a vocabulary
correction stay corrected.

## Values, and where formats break

Every fixture but one numbers its ADRs `0001`. That is the same value under every
parse, in every language, and a corpus that only exercises identifiers below the
first boundary cannot detect an engine that breaks at one.

**`adr-identifier-boundary`** closes three † rows with ADRs numbered `0008`,
`0009` and `0010`. Those three are not arbitrary. A leading-zero token read as
octal *fails* at 8 and 9 — falling back to a string, so the value survives by
accident — and silently *succeeds with the wrong value* at 10, where `0010`
becomes 8. All three sit in one directory so that a collision between a mis-parsed
`0010` and the literal `0008` is observable rather than latent.

Everything in that fixture passes. That is the discriminating direction: an engine
that cannot see `0010` reports a failure the standard does not expect, rather than
quietly agreeing with a fixture that was already failing.

The standard shipped this exact bug in its own decision record for seven releases
(ADR 0017), and the fixtures could not have caught it, because none of them used a
number where the format breaks.

**The general rule.** A check does not fail at a typical value; it fails at a
boundary. When a fixture exercises a field with a range — an identifier, a count,
a date, a version, a threshold — the value it carries should sit *past* the
nearest place the representation changes meaning, not comfortably inside it. A
fixture set whose values are all comfortable proves less than its count suggests.

## Adding a fixture

1. Copy `g2-compliant`. Change exactly one thing.
2. Add an entry to `expectations.json` naming every in-scope check, not only the
   one under test. A fixture that pins one verdict and leaves four unstated will
   pass an engine that broke the other four.
3. Say in `description` what the fixture is defending, in a sentence. The ones
   above are the model.
4. Choose values at a boundary, not in the middle of a range. See *Values, and
   where formats break* above — a fixture carrying a comfortable value tests the
   case that was never going to break.
5. Run `tools/validate.py`. It checks the fixture set and the expectations file
   agree, and that every check named in `expectations.json` exists in
   `gate/checks.json`.
