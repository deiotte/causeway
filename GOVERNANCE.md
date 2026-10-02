# Governance

How Causeway is maintained, who decides what, and what happens if that person
stops. The reasoning is [ADR 0038](decisions/0038-govern-as-a-single-maintainer-in-public.md);
this file is the part you act on.

## Who maintains it

| Role | Who | Holds |
|---|---|---|
| Maintainer | Karl Deiotte ([@deiotte](https://github.com/deiotte)) | Review authority, merge authority, release authority, and the release signing key |

There is one maintainer. That is a fact about the project today, not a design
goal, and the rest of this file is written so that it does not have to stay true.

## How the standard changes

The standard is normative text, so a change to it is a decision, and decisions here
are made the way the standard tells everyone else to make them.

1. **Open an issue.** Say what is wrong or missing and what you know that the text
   does not. Field experience is the most valuable thing you can bring — see
   *Contributing* below.
2. **The maintainer decides whether it is a decision.** Most issues are
   corrections, and a correction is just a fix. Anything with a real alternative
   gets an ADR in `decisions/`, by Build DNA §8.
3. **The ADR is the record.** It names the alternatives, the forces that decided
   between them, and the issue it came from. If your issue shaped it, it says so.
4. **The change ships in a release.** `VERSION`, `RELEASED` and `CHANGELOG.md` move
   together, and the release is signed (ADR 0019) and published as a reproducible
   archive (ADR 0030).

The standard's own CI — `tools/validate.py` and the steps in
`.github/workflows/standard.yml` — must be green before anything merges. The
maintainer's approval does not substitute for it.

## Contributing

Issues are open to anyone. Pull requests are not accepted from outside the
maintainer yet. [CONTRIBUTING.md](CONTRIBUTING.md) says why and what to do instead.

## Security

Report a vulnerability privately, never in a public issue. [SECURITY.md](SECURITY.md)
says how and what is in scope.

## Precedence

Causeway's layering diagram (Build DNA, *Layering*) puts a **managed policy** tier
above it: the organization's own non-negotiable floor, which Causeway never
overrides. Causeway does not supply that tier and cannot. It belongs to whoever
adopts the standard — their security office, their authorizing official, their
legal and records obligations. Where an adopter's managed policy and Causeway
disagree, the managed policy wins, and the adopter records the deviation in its
own exceptions register.

What Causeway still owes is a description of what a managed policy tier should
contain and how a project finds it. That is Build DNA open item 1, and it stays
open.

## Continuity

If the maintainer stops maintaining Causeway — by choice or otherwise — this is
what remains true:

- **Every release keeps working.** A release is a signed archive that installs
  with no network and no access to this repository (ADR 0030). Nothing a consuming
  project relies on depends on this repository staying up.
- **Anyone may continue the work.** The Apache-2.0 license allows a fork, and a
  fork is how this would continue. It should take a different name and say which
  Causeway release it started from (`NOTICE`, ADR 0037).
- **A successor is not yet named.** That is a declared gap, not an oversight. When
  a second maintainer exists, they are added to the table above by an ADR that
  also records how release-signing authority is shared or transferred.

Issue [#5](https://github.com/deiotte/causeway/issues/5) tracks the
open half of this.
