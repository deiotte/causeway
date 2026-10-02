---
adr: "0000"
title: <SA-0.0> as built — <short statement of the actual answer>
status: Accepted        # Accepted once the as-built answer is recorded. Not Proposed.
date: YYYY-MM-DD
spine_rows: [SA-0.0]
adoption:
  added_in: 0.0         # spine version that added this row
  closed_against: 0.0   # spine version this system had closed against
  horizon: YYYY-MM-DD   # release date of added_in + 180 or 365. When it starts blocking.
approver:               # required if the row is a dagger row
  name:
  role:
as_built:
  answer: >             # REQUIRED. What the system has ACTUALLY been doing.
  since: YYYY-MM-DD     # when the current behavior started, as near as it can be dated
  exposure:             # true if ongoing and unrecoverable. Blocks without `notified`.
  notified:             # REQUIRED when exposure is true
    name:               # a person, not a role
    role:               # ISSM, or the data owner where they hold it
    date: YYYY-MM-DD
supersedes:
superseded_by:
---

<!--
  Use this template ONLY when a spine revision added a ONE-WAY row to a system
  that is already running. The door is already shut, so this ADR records what
  was decided by default, not what you would choose today.

  If the row is not one-way, or the system is not yet built, use adr-template.md.
-->

## As built

What the system has actually been doing, in plain terms, with dates. Not the
intended behavior and not the corrected behavior — those go below. A reader who
knows nothing about this system should finish this section knowing exactly what
has been happening and for how long.

## How it came to be this way

The row did not exist when this was built. Say what the decision looked like at
the time — usually it was not a decision at all, it was a default. This section
exists so the record is accurate rather than accusatory; a decision nobody made
should read as a decision nobody made.

## Exposure

Is anything ongoing and unrecoverable? Answer plainly.

If yes: what has left the boundary, over what period, to whom, and what is the
smallest true statement of what cannot be undone. This is the paragraph the ISSM
reads, and the `as_built.notified` fields above record that they read it. This is
not a design discussion — the disclosure has already happened and the question is
who knows.

If no: say why not, and what would have to be true for the answer to change.

## Going forward

The decision from here. This is the only forward-looking section, and it does not
substitute for the three above.

## Evidence

Where a reviewer confirms both halves: that the as-built answer is accurate, and
that the going-forward decision is implemented.

---
<!--
An `exposure: true` with no complete `notified` block is a blocking gate failure
at every profile (as-built-notification, gate-configuration.md §4). The check
verifies a name and a date exist. It cannot verify the conversation happened —
that part is on you.
-->
