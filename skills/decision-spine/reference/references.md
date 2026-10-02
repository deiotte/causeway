# Decision Spine — Reference Set

Sources behind each section. Attached at section level, not row level.

## Reference set

References are attached at **section level**, not row level. Row-level pointers
would be roughly ninety citations to maintain against editions that move; the
gain in precision does not pay for the maintenance.

All twenty-two entries below are ratified as of v0.6. No section carries a gap.
The count is of table rows; a few entries carry more than one document.

### Architecture and design

| Resource | Feeds | Use for |
|---|---|---|
| **C4 Model** (Simon Brown) | SA-1, SA-3, SA-4 | Context / container / component / code diagrams. Standard visual language across all three views. |
| **Domain-Driven Design** (Evans / Vernon) | SA-1.2 | Bounded contexts and context mapping. The source behind SA-1.2's vocabulary. |
| **Designing Data-Intensive Applications** (Kleppmann) | SA-2.1–2.3 | Storage paradigms, partitioning, replication, consistency models. Primary source for §2. |
| **Enterprise Integration Patterns** (Hohpe & Woolf) | SA-3 | Messaging, routing, transformation, DLQ, delivery semantics. Primary source for §3. |
| **Building Evolutionary Architectures** (Ford, Parsons, Kua) | SA-3.6–3.7, SA-9.1 | Contract evolution, fitness functions, lock-in as an architectural property. |
| **Twelve-Factor App** | SA-2, SA-3, SA-4, SA-6, SA-8 | Cloud-native application hygiene — config, state, backing services, disposability, parity. |

### Operations and reliability

| Resource | Feeds | Use for |
|---|---|---|
| **AWS & Azure Well-Architected** | SA-1, SA-2, SA-4, SA-5, SA-7 | Six-pillar sweep: operational excellence, security, reliability, performance, cost, sustainability. |
| **Google SRE Books** | SA-1, SA-6, SA-7, SA-8 | SLO/SLI/error budget mechanics, alerting, overload, cascading failure, release engineering. Primary source for §6. |
| **Release It!** (Nygard) | SA-3.9–3.11, SA-7.2 | Circuit breakers, bulkheads, backpressure, graceful degradation. The failure-pattern vocabulary. |
| **Accelerate** (Forsgren, Humble, Kim) | SA-8 | Delivery practice and the evidence for why the §8 rows matter. |
| **Team Topologies** (Skelton, Pais) | SA-1.11 | Ownership boundaries and Conway's-Law-aware team design. |
| **Cloud FinOps** (Storment & Fuller) | SA-1.10, SA-9.2 | Unit economics, cost attribution, egress cost modeling. |

### Security, authorization, and law

| Resource | Feeds | Use for |
|---|---|---|
| **NIST SP 800-207** | SA-5.2–5.3, SA-5.10 | Zero Trust: policy engine, PDP, PEP. |
| **NIST SP 800-37 · SP 800-53** | SA-5.9–5.10 | Control allocation, inheritance, common-control providers, boundary definition. |
| **NIST SP 800-161r1** | SA-5.8, SA-5.14 | Cyber supply chain risk management. The source behind treating a package registry as a supplier rather than as infrastructure. |
| **SLSA** (Supply-chain Levels for Software Artifacts) | SA-5.8, SA-5.14, SA-8.8 | Build provenance and integrity levels. The vocabulary for what an attestation actually asserts. |
| **DoD CIO cATO memo (Feb 2022) · OSCAL spec** | SA-5.11, SA-5.13 | The precedent Tactical Authorization rests on, and the evidence format. |
| **NARA General Records Schedules** | SA-2.9, SA-9.4 | Retention and disposition. Legal obligation, not preference. |
| **Section 508 / WCAG 2.1 AA** | SA-5.12 | Accessibility conformance standard. |
| **OWASP Top 10 for LLM Applications** | SA-5.15, SA-5.16 | Prompt injection, insecure output handling, sensitive information disclosure. The catalogue of what a generalized tool surface and an unredacted prompt actually expose. |
| **NIST AI RMF** (AI 100-1) · **Generative AI Profile** (AI 600-1) | SA-5.15, SA-5.16 | Govern / map / measure / manage. The source behind putting a named human on inference egress rather than leaving it to engineering discretion. |
| **NIST SP 800-122** | SA-2.12, SA-5.16 | PII confidentiality, de-identification, and what "removed" has to mean to count. |

