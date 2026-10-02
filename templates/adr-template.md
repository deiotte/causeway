---
adr: "0000"
title: <short imperative title — the decision, not the topic>
status: Proposed        # Proposed | Accepted | Deferred | Waived | Deprecated | Superseded
date: YYYY-MM-DD
spine_rows: [SA-0.0]    # design-layer rows this ADR closes. Required.
survey_rows: []         # the Survey DEC- row this came from. Optional; copied, not authored.
forces: []              # the Survey rows that discriminated (GR-/LD-/IV-/FM-). Optional.
door:                   # one-way | two-way. Read from the spine row's One-way column.
revisit_if:             # the condition that would legitimately reopen this
approver:               # required only for the eight dagger rows
  name:
  role:
supersedes:
superseded_by:
supersession_cause:     # S1..S5 — required when supersedes is non-empty. See AGENTS.md §8.
corrects: []            # ADRs whose factual errors this one corrects
corrected_by: []        # filled in later, by the ADR that corrects this one
---

## Context

What forces are in play. What makes this a real decision rather than an obvious one.

## Forces

> The specific rows that made one alternative better **here**. Where a Survey exists,
> cite its IDs and copy them from the `DEC-` row rather than re-deriving them. A
> decision justified only by general preference has no forces, and will be reopened by
> the first person with a different preference.

- `GR-n` — 
- `IV-n` — 

## Decision

What we are doing. Present tense, active voice, one paragraph.

## Alternatives considered

What else was on the table and why it lost. An ADR with no alternatives is a note,
not a decision record.

## Consequences

What becomes easier. What becomes harder. What we are now committed to.

## Revisit if

> The condition under which reopening this is legitimate rather than churn. Naming it
> is what lets a future reader tell the difference. "If throughput exceeds 10k/s" is a
> revisit condition. "If we change our minds" is not.

## Evidence

Where a reviewer looks to confirm this was actually implemented.
