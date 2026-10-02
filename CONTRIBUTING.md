# Contributing to Causeway

Thank you for looking. This file is about contributing to **the standard itself**.

If you are working *in a project that adopted Causeway*, you want that project's
own `CONTRIBUTING.md` instead. `sync.sh` seeds one from
`templates/contributor-START-HERE.md`, and it is the right front door for that job.

## What helps most

In order of how much it moves the standard forward:

1. **Use it on a real project and tell us what happened.** Several of the
   standard's open items wait on exactly one thing: a project that did not write
   Causeway running it and reporting back. Use the **Adopter report** issue form.
   [ADOPTING.md](ADOPTING.md) says what we are asking for and what we will do with
   it.
2. **Tell us something you know from the field.** A rule that breaks on contact
   with practice, two cases the text treats as one, a failure it does not see
   coming. Use the **Field note** issue form. You do not need to write software to
   do this, and it is often the most valuable thing anyone sends.
3. **Report something wrong.** A contradiction, a count that does not add up, a
   script that fails, an instruction that cannot be followed. An ordinary issue is
   fine.
4. **Report a vulnerability privately.** See [SECURITY.md](SECURITY.md). Never in a
   public issue.

## Why pull requests are closed for now

Pull requests from outside the maintainer are not accepted yet. That is not a
judgment about your patch. It is three facts about the project today:

- **A change to the standard is a decision.** Most of the value in a change is the
  ADR that argues it, and an ADR records who made the decision and on what
  evidence. The maintainer writes those and names you in them when your issue
  shaped the decision.
- **The license gets harder to change once anyone else holds copyright in it.**
  See ADR 0037, *Consequences*. That is fine to accept deliberately and wrong to
  accept by accident.
- **There is one maintainer.** An open pull-request queue that nobody answers is
  worse than a closed one. Build DNA says the same about a field-note register
  nobody dispositions.

[ADR 0038](decisions/0038-govern-as-a-single-maintainer-in-public.md) records this
decision and the condition that reopens it.

## What happens to your issue

Every issue gets an answer. It ends in one of four places, the same four
dispositions Build DNA gives a field note: an ADR, a fix, a change to a rule or
template, or closed with a pointer to where it is already handled. If it is
closed, the pointer is there so you can tell us we were wrong.

## Licensing

By submitting an issue, a field note, or any other material, you agree it may be
used in the standard under the [Apache License 2.0](LICENSE), the same terms the
standard is published under.
