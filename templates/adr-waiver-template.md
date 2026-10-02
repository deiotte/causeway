---
adr: "0000"
title: Waive <SA-0.0> — <short reason>
status: Waived
date: YYYY-MM-DD
spine_rows: [SA-0.0]
waiver:
  expires: YYYY-MM-DD     # REQUIRED. Max 180 days for C1, 365 for C2-C3.
  accepted_by:
    name:                 # a person, not a role
    role:
  review_trigger:         # the event that forces this earlier than expiry
---

## Why not now

What information is missing, or what makes this decision premature.

## Risk accepted

What breaks if the eventual answer turns out to be the wrong one. Be specific;
this is the paragraph someone reads after it goes wrong.

## What would close it

The concrete thing that has to happen for this to become a real decision.

---
<!--
An expired waiver is a gate failure, identical to an unclosed row.
Extension is a NEW ADR that supersedes this one and states why the original
estimate was wrong. Never edit the expiry date in place.
-->
