# Build DNA — §2 Microservices by default

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## 2. Microservices by default, or explain yourself

Services are the default decomposition. Independent deployability, independent
scaling, and blast-radius containment are worth the operational cost in most of
what we build.

**Deviation is allowed and expected.** It is not allowed silently. A project that
deviates records an ADR stating the rationale, what is preserved, and the
condition under which the decision is revisited. The exceptions register in the
project `CLAUDE.md` carries a pointer to it.

The canonical worked example: an appliance that deviates to a modular monolith
because the target is a fixed-hardware, air-gapped box with no local operations
staff.
Every additional process is another failure mode and another thing to accredit.
Service-shaped internal boundaries are preserved — separate crates, explicit
interfaces, no shared mutable state — they are simply not process boundaries.
That is what an owned deviation looks like: the seams still exist.
