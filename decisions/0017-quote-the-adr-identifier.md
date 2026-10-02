---
adr: "0017"
title: Quote the ADR identifier, because YAML reads leading zeros as octal
status: Accepted
date: 2026-08-22
spine_rows: []
approver:
  name: Karl
  role: CTO
supersedes:
superseded_by:
---

## Context

Every ADR in this repository carried a zero-padded identifier written bare:

```yaml
adr: 0010
```

**YAML 1.1 reads a leading-zero integer as octal.** `0010` parses to **8**.
`0011` to 9, `0012` to 10, and so on — an error that begins at the tenth ADR and
grows by two with every release. `0008` and `0009` are not valid octal, so they
fall back to strings and appear correct, which is precisely why nothing looked
wrong until the tenth: the first nine were right, seven by arithmetic coincidence
and two by parse failure.

This is not a display quirk. `gate/checks.json` defines the `repo-decisions`
input class as *"The product repository's `decisions/` directory, with ADR
frontmatter **parsed**."* A conforming engine parses that frontmatter. Two of the
27 checks read the class — `named-approvers` and `shortform-closure` — and both
would see ADR 0016 as decision 14. Any engine correlating an approval to a
decision, or a closure to a row, would have been correlating it to the wrong one.

Three ADR templates ship inside the bundle with `adr: 0000`. Every project that
adopted this standard inherited the defect and would meet it at its own tenth
decision.

It was found by a human reading GitHub's rendered frontmatter table, which shows
the parsed value. It was reported, and the first investigation **confirmed the
numbering was sound** — because that investigation, like the validator, read the
file with a regular expression.

## Decision

The identifier is a quoted four-digit string:

```yaml
adr: "0010"
```

Quoted in all sixteen ADRs, all three bundled templates, and every conformance
fixture that carries frontmatter. The value is now a string of exactly the digits
in the filename, with one type across every ADR — where before the corpus held
seven integers that happened to be right, two strings, and seven integers that
were wrong.

`validate.py` **requires** the quoted form rather than tolerating it. An unquoted
`adr: 0017` fails the build with the reason, naming octal explicitly.

## Alternatives considered

**Drop the padding — `adr: 10`.** Rejected. It parses correctly, but the padded
form is what the filenames use, and a record whose identifier disagrees in shape
with the file carrying it invites exactly the class of mismatch this repository
keeps finding.

**Validate the parsed value instead of the written form.** Rejected, and the
reason is the whole lesson. Parsing here would mean adding a YAML library to the
standard's own gate, and more importantly it would check the consequence rather
than the cause: a bare `adr: 0017` that happened to parse to a number matching its
filename would pass, and the ambiguity would survive to bite the next reader.
Requiring the quotes removes the ambiguity at the source.

**Leave it and document the hazard.** Rejected. A documented trap in a bundled
template is a trap shipped to every adopter, with a note attached.

## Consequences

The bundle digest moves because the templates are vendored, so this is a release —
patch, since no row, check, threshold or artifact changed and the corrected values
are what every reader already believed them to be. Consumers re-sync to pick up
templates that do not carry the defect.

**The validator and a YAML parser disagreed for seven releases, and CI was green
throughout.** `validate.py` read `^adr:\s*(\d+)`, captured the characters `0010`,
and compared them to the filename. A regex reads characters; a parser reads
meaning. The check was not weak — it was answering a different question from the
one the engine contract asks, and no amount of running it more often would have
surfaced that.

Every conformance fixture used `adr: 0001`, which parses to 1 under any reading.
The fixtures could not have caught this, and a fixture set that only exercises
values below the point where a format breaks proves less than its count suggests.
That is a general caution about the eight fixtures, not a defect in them.

## Evidence

`tools/validate.py` §12 — the quoting requirement, with octal named in the failure
message so the next person does not have to derive it.

Made to fail before being trusted: reverting a single `adr:` to the bare form
fails with *"got 0010 — write adr: \"0010\". Unquoted leading-zero digits are
octal in YAML: 0010 parses as 8."* A correctly quoted but wrong number fails the
filename-match check instead, so the two failures stay distinguishable.

Confirmed with a real parser after the change: all sixteen ADRs load as the string
matching their filename. Before it, seven did not.
