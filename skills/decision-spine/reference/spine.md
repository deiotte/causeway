# Decision Spine

**Version:** 0.8 (Causeway-coupled)
**Layer:** Design. See Build DNA (`AGENTS.md`) for the process layer.
**Seam:** Every decision here lands in an ADR. That is the only point where the
design layer and the process layer touch.

**Correction in v0.8.** SA-3.13's answer set read *Greenfield / wrapped /
composed* and disagreed with Build DNA §4, which has named the three composition
states *catalog-composed / wrapped / unmanaged* since v1.0. The row was mixing two
axes: greenfield-versus-brownfield is a **lifecycle** question, and §4's opening
sentence is where it belongs. Composition state answers a different question —
*what is this system made of* — and has three values, none of which is greenfield.
The row is the outlier and the row is what moved. `composition-state` blocks at
every profile, so an answer set that disagreed with the document defining it was a
blocking check with no single source of truth. See ADR 0008.

**Changes from v0.6:** No rows added or changed; counts are unmoved. *Adoption and
version drift* is now a normative section rather than an open question — the
adoption horizon is ratified, `spine.closed_against` replaces the declared
`spine.version`, and retroactively added one-way rows close on the as-built
answer. Carried unratified since v0.4; see ADR 0005.

**Changes from v0.5:** SA-5.15 and SA-5.16 added — the inference boundary.
SA-5.15 is the tool surface a model is given; SA-5.16 is what crosses to a
third-party provider, one-way, named-approver, in the short form. Three
references ratified for them (OWASP Top 10 for LLM Applications, NIST AI RMF
with its Generative AI Profile, NIST SP 800-122). See ADR 0004.

**Correction in v0.6.** The reference set's stated total disagreed with its own
table — "eighteen resources" against nineteen entries. Same species as the v0.5
correction and handled the same way: the table is authoritative, so the total is
restated from it and counted in entries, some of which carry more than one
document.

**v0.8 counts, derived from the table:** 94 rows · 28 one-way doors · 23 in the
short form · 89 in scope at C2 · 8 named-approver rows, 4 of them in the short
form · 22 reference entries. Unchanged from v0.6 — v0.7 was a governance revision
and v0.8 corrects one answer set, so no system owes a new row for either and the
adoption horizon has nothing to bite on.

**Changes from v0.4:** SA-5.14 added — package ecosystem and registry posture,
one-way, in the short form. Two references ratified for it (NIST SP 800-161r1,
SLSA). See ADR 0002.

**Correction in v0.5.** v0.4's published counts disagreed with its own `Applies`
column. SA-9.3 was marked `C1–C3` but omitted from the short-form list, and the
short form's † count was stated as four where the table yields three. The column
is authoritative — the short form *is* the `C1–C3` filter — so SA-9.3 joins the
list and the counts are restated from the table rather than from the prose. A
C3 system that closed the published twenty owes SA-9.3 at its next review.

**Changes from v0.3:** All ten proposed references ratified; every section now
carries a source and no gap markers remain. Gate profile implementation moved to
its own document (`causeway-gate-configuration.md`), which also carries the
promote-or-sunset enforcement mechanism.

---

## What this is

The Decision Spine is the complete set of decision surfaces a system has to
close. It is not a checklist of good practices, not a review form, and not a
document outline — it is the index those three things are generated *from*.

Each row is a question with a finite answer set. A row is closed when a decision
exists, an ADR records it, and evidence exists that the decision was
implemented. "We thought about it" does not close a row.

## The three views

One spine, three projections. Never blend them into a single working document.

| View | Consumer | Moment | Output |
|---|---|---|---|
| **Decision Register** | Architect | During design | Decision + ADR ref per row |
| **Review Checklist** | Reviewer / gate | At a milestone | Pass / fail / waived + finding |
| **SAD Outline** | Reader, evaluator, customer | At delivery | Narrative sections |

## Two independent axes

The spine and Causeway classify a system on different axes. Do not conflate them.

| | Causeway Tier (SA-1.14) | Criticality Class (SA-1.1) |
|---|---|---|
| **Question** | Where does it live and how is it governed? | How much does failure cost? |
| **Values** | Core / Mission / Operational | C1 / C2 / C3 |
| **Set by** | Causeway catalog placement | Product/Service Owner, Customer, or Sponsor |
| **Controls** | Which gate profile runs | How many spine rows apply |

An Operational-tier citizen-developer app can be C1. A Core-tier shared service
can be C3. Assume nothing from one axis about the other.

## How to read the columns

**ID** — Stable forever. Never renumber. New items take the next free number in
their section even when that puts them out of logical order (SA-1.14 is the
proof — it belongs conceptually beside SA-1.1 and will never move). Retired
items are struck through, not deleted.

**†** — A named-approver row. See *Authority*, below.

**One-way** — `Y` marks a decision that is expensive or impossible to reverse
once built. Close every `Y` row before writing production code. There are 28.
They are the actual architecture; everything else is engineering.

Two shapes of irreversibility live in that column and both count. Most `Y` rows
are expensive to unbuild — a partition key, an async substrate, a tenancy model.
A few are irreversible because of what they disclose rather than what they cost:
SA-2.11 and SA-5.16 are closed the moment data lands somewhere you do not
control, and no later decision retrieves it.

**Applies** — Which criticality classes must close the row.

| Class | Meaning |
|---|---|
| **C1** | Failure is a mission failure or a reportable event. |
| **C2** | Failure degrades work; survivable for hours. |
| **C3** | Failure is an annoyance. Prototypes, internal tools, most Operational-tier builds. |

`C1–C3` = the 23-row short form, required of everything. `C1–C2` = C3 may skip.
`C1` = mission-critical only.

The three meanings above are index entries, not the test. **How a system arrives
at its class — and at its tier — is `reference/placement.md`:** four questions,
five escalators that set C1 on their own, the tier test the catalog applies, what
the declaration has to contain, and the rules for changing one later.

**Evidence** — What a reviewer looks at to confirm the row is closed. If you
can't name the artifact, the row isn't closed.

---

## Authority

**Default.** Decisions and waivers are approved at the level that sets SA-1.1 —
the Product Owner, Service Owner, Customer, or Sponsor. This does not vary by
section. Rigor varies by class, not by which chapter a row happens to live in.

**Named-approver rows.** Eight rows additionally require a single accountable
individual, by name, who approves or denies both the decision and any waiver of
it. Not a role. Not a board. A person.

| Row | Decision | Approver |
|---|---|---|
| SA-1.8 † | Highest data classification handled | Data owner / original classification authority |
| SA-1.9 † | Authorization path | AO |
| SA-2.11 † | Where data may physically reside | AO or data owner |
| SA-5.7 † | Key custody | AO or ISSM |
| SA-5.10 † | Authorization boundary | AO |
| SA-5.13 † | Tactical Authorization | AO |
| SA-5.16 † | What crosses the inference boundary | Data owner, countersigned by the ISSM where the answer is anything but "nothing" |
| SA-9.4 † | Data disposition at decommission | Records officer |

The test for membership: *is there a person who personally answers for this in
an inquiry?* If yes, name them. If no, the default authority is enough.

The approver's name is recorded in the ADR, not in a separate system. If the
named individual changes, that is a superseding ADR — the chain of who accepted
what, and when, stays readable.

---

## Waivers

A waiver is an ADR. There is no separate waiver form, register, or ticket type.

An open row that cannot be decided yet gets an ADR with status `Waived` and
these required fields:

| Field | Rule |
|---|---|
| **Row ID** | The spine row being waived |
| **Why not now** | What information is missing, or what makes the decision premature |
| **Risk accepted** | What breaks if the eventual answer is the wrong one |
| **Expiry date** | Mandatory. Maximum 180 days for C1, 365 for C2–C3. No open-ended waivers. |
| **Accepted by** | Default authority, or the named approver for a † row |
| **Review trigger** | The event that forces the decision earlier than expiry |

Mechanics:

1. An unexpired waiver satisfies the row at gate time. The gate passes.
2. An **expired waiver is a gate failure**, same as an unclosed row. It cannot
   be extended silently — extension is a new ADR that supersedes the first and
   states why the original estimate was wrong.
3. Waivers surface in every review between now and expiry. That's the point:
   the decision to defer stays visible instead of rotting.

This is what makes the spine tolerable in practice. "Not yet" is a legitimate
answer. "Never asked" is not.

---

## Adoption and version drift

A revision of this document does not change what a system owes today. It starts a
clock. The mechanism is the **adoption horizon**, and it is the waiver instrument
above issued automatically rather than a second instrument to learn.

**Which version applies is derived, never declared.** The spine in force for a
system is the one in its vendored copy — `gate/profiles.json`, whose checksum sits
in `.causeway-lock` and which therefore cannot be edited without failing
`check-drift.sh`. `system.json` records `spine.closed_against`, and that field is
history: the version the system last closed against. It is an input to the
arithmetic below, never an exemption from it. A system with no
`spine.closed_against` has closed against nothing on record and gets **no adoption
grace** — the same strictest-default reasoning that resolves a missing criticality
class to C1, and the correct behavior for a newly registered system under the
identical rule.

**Rows added by a revision enter as findings, carrying a deadline.** The deadline
is the revision's release date plus a horizon:

| Row added | Horizon |
|---|---|
| Applies at C2 or C3 | 365 days |
| Applies at C1 | 180 days |
| **One-way, any class** | **180 days** |

Those are the maximum waiver terms from the section above, reused rather than
reinvented — a revision effectively issues every existing system a waiver against
its new rows, on terms the standard already permits. One-way rows take the shorter
horizon regardless of class because a C3 system with an open one-way row
accumulates the same unrecoverable exposure a C1 system does. Class governs how
much rigor a row gets. It does not govern how fast a door closes.

Mechanics:

1. **The clock starts at the revision's release date**, not at the date a project
   syncs to it. A sync-anchored clock is one a project resets by not syncing —
   the same reasoning that puts `renewal_count` on the TA record rather than on
   the build.
2. Inside the horizon an unclosed new row is a **finding**. On expiry it becomes
   an ordinary unclosed row and blocks wherever the profile already says it
   blocks. Nothing new blocks; the row rejoins checks that already existed.
3. **TA renewal, promotion, and reclassification force adoption immediately.**
   The horizon is a ceiling, not a schedule.
4. **Needing longer is a waiver** — named acceptor, expiry, review trigger —
   superseding the automatic horizon. "No open-ended waivers" therefore covers
   version drift without a further rule.

**A retroactively added one-way row does not close on an intended answer.** The
door is already shut. For a system already running, the row's value is disclosure
rather than choice, so the ADR states what the system has *actually* been doing.
Where that as-built answer reveals ongoing unrecoverable exposure, the ISSM is
notified and the notification is recorded in the ADR by name and date. "We have
been sending unredacted PII to a commercial provider for eight months" is the
deliverable in that case, and it starts an incident rather than a design
discussion.

Worked example, and the one this policy was ratified against. A C2 system closed
against v0.5 picks up SA-5.15 and SA-5.16 when it syncs a standard carrying v0.6,
released 2026-08-08. SA-5.15 applies at C2, so it is owed by **2027-08-08**.
SA-5.16 is one-way, so the class term does not apply and it is owed by
**2027-02-04**. Both are findings today. Neither blocks today. Both are visible in
every gate run between now and those dates, which is the entire point.

---

## Gate profiles

Three Causeway tiers by three criticality classes is nine combinations, which is
more than anyone will maintain or remember. Four profiles, collapsed on one rule:

> **The gate is set by the more demanding of the two axes.**

| | C3 | C2 | C1 |
|---|---|---|---|
| **Operational** | G0 | G1 | G1 |
| **Mission** | G1 | G2 | G2 |
| **Core** | G2 | G3 | G3 |

**G0 · Sandbox.** C3 short form closed, secrets scan clean, dependency
provenance recorded, classification declared. Fully automated, no human in the
loop, minutes to run.

**G1 · Tactical.** G0, plus the one-way doors in scope for the class, plus a
Tactical Authorization carrying duration and revocation trigger, plus named
approver signatures on any † rows in scope. Time-bounded by construction.

**G2 · Mission.** Full spine for the class. Control inheritance verified,
evidence pipeline emitting, contract tests passing, DR plan of record.

**G3 · Core.** G2, plus what is owed to *other people's systems*: exposure
review, promotion review, DR drill evidence within cadence, AO signature on the
authorization boundary.

Two consequences of the diagonal, both deliberate:

- **Operational + C1 lands in G1**, which looks light for a mission-critical
  system. It is correct because Operational tier is time-bounded by design: a C1
  system should not live there permanently. The rule that makes this honest —
  **Operational + C1 forces a promote-or-sunset decision at TA expiry. No third
  renewal.** Either it earns Mission tier and G2, or it is retired.
- **Core + C3 lands in G2**, which looks heavy for something low-criticality. It
  is correct because at Core tier other systems inherit from you, so your blast
  radius is not your own criticality. Core tier is never cheap.

---

## SA-1 · Context & Constraints

Close this section first. It sets the constraints every later section inherits
and contains six one-way doors.

**SA-1.1 authority note:** Criticality class is set by the Product Owner,
Service Owner, Customer, or Sponsor — never by the delivery team alone. Whoever
sets the class controls how much rigor applies, so that authority sits with
whoever owns the consequences.

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-1.1 | What is the criticality class? | C1 / C2 / C3 | Y | C1–C3 | Class declaration signed by PO/SO/Customer/Sponsor |
| SA-1.2 | What are the bounded contexts and where are their seams? | Named context list | Y | C1–C2 | Context map |
| SA-1.3 | What is the availability target? | 99.5 / 99.9 / 99.95 / 99.99 | N | C1–C2 | SLO definition |
| SA-1.4 | What is the latency budget? | p95 and p99 per critical path | N | C1–C2 | SLO definition |
| SA-1.5 | What throughput must it sustain? | Baseline RPS / peak / burst shape | N | C1–C2 | Load model |
| SA-1.6 | What is the error budget policy and who spends it? | Budget + freeze trigger + owner | N | C1 | Error budget policy |
| SA-1.7 | What is the tenancy model? | Silo / pool / bridge | Y | C1–C2 | ADR |
| SA-1.8 † | What is the highest data classification handled? | Public / CUI / classified level | Y | C1–C3 | Classification memo |
| SA-1.9 † | What authorization path applies? | None / ATO / cATO / Tactical Authorization / FedRAMP / reciprocity | Y | C1–C2 | Authorization strategy |
| SA-1.10 | What is the cost envelope and unit of account? | Ceiling + cost-per-what | N | C1–C2 | Unit economics model |
| SA-1.11 | Who owns this system in production? | Named team + on-call boundary | N | C1–C3 | Ownership record |
| SA-1.12 | What is the expected first bottleneck? | Compute / IO / memory / network / human | N | C1–C2 | Scaling analysis |
| SA-1.13 | What is the growth curve over 3 years? | Users, data volume, request volume | N | C1–C2 | Growth projection |
| SA-1.14 | What is the Causeway tier? | Core / Mission / Operational | Y | C1–C3 | Catalog record |

**References:** C4 Model (context and container levels → SA-1.2) · Domain-Driven Design, Evans or Vernon (SA-1.2 — the source behind the bounded-context language) · Google SRE Book ch. 3–4 (SLO/SLI/error budget → SA-1.3–1.6) · Well-Architected cost pillar and Cloud FinOps (SA-1.10) · Team Topologies (SA-1.11)

## SA-2 · Data & Persistence

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-2.1 | What storage paradigm per bounded context? | Relational / document / KV / graph / time-series / object | Y | C1–C3 | ADR + access-pattern table |
| SA-2.2 | What is the partition or shard key? | Named key + rationale | Y | C1–C2 | Data model |
| SA-2.3 | What consistency model does each store provide and require? | Strong / eventual / tunable | Y | C1–C2 | ADR |
| SA-2.4 | How do schemas change without downtime? | Expand-contract / versioned / offline window | N | C1–C2 | Migration runbook |
| SA-2.5 | What is cached, where, and how is it invalidated? | TTL / write-through / write-behind / cache-aside / none | N | C1–C2 | Cache policy |
| SA-2.6 | Are application tiers stateless? | Yes / no + where state lives | N | C1–C2 | ADR |
| SA-2.7 | What are RPO and RTO? | Minutes/hours per data class | N | C1–C2 | Continuity plan |
| SA-2.8 | What is the backup mechanism and restore drill cadence? | PITR / snapshot / log ship + drill schedule | N | C1–C2 | Last successful restore test |
| SA-2.9 | What are retention, purge, and legal hold rules? | Per data class | N | C1–C3 | Records schedule |
| SA-2.10 | What is audited, and is the audit log immutable? | Event list + write-once guarantee | N | C1–C2 | Audit spec |
| SA-2.11 † | Where may data physically reside? | Region / enclave / sovereignty constraint | Y | C1–C2 | ADR |
| SA-2.12 | How is PII/CUI minimized, masked, or tokenized? | Field-level treatment table | N | C1–C3 | Data handling spec |

**References:** Designing Data-Intensive Applications, Kleppmann (SA-2.1–2.3 — primary source for storage paradigm, partitioning, and consistency) · Twelve-Factor IV (backing services) and VI (stateless processes → SA-2.6) · Well-Architected reliability pillar (SA-2.7–2.8) · NARA General Records Schedules (SA-2.9 — legal obligation, not preference) · NIST SP 800-122 (SA-2.12 — the field-level treatment table SA-5.16 reads from)

## SA-3 · Application & Integration

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-3.1 | What is the architecture pattern? | Modular monolith / microservices / EDA / hybrid | Y | C1–C2 | ADR (with the owned exception if not microservices) |
| SA-3.2 | What synchronous protocol between services? | REST / gRPC / GraphQL | N | C1–C2 | Interface spec |
| SA-3.3 | What asynchronous substrate and topology? | Queue / log / bus + product class | Y | C1–C2 | ADR |
| SA-3.4 | What delivery semantics, and where do idempotency keys live? | At-most / at-least / effectively-once + key strategy | Y | C1–C2 | ADR |
| SA-3.5 | What ordering guarantee and dedupe window? | Per-key / global / none + window | Y | C1–C2 | ADR |
| SA-3.6 | What is the API versioning and deprecation policy? | Scheme + support window | Y | C1–C2 | API policy |
| SA-3.7 | What backward-compatibility guarantee do consumers get? | Stated guarantee + contract test suite | N | C1–C2 | Contract tests passing |
| SA-3.8 | Where is the canonical schema / adapter boundary? | Named boundary per external vendor | Y | C1–C2 | Adapter spec |
| SA-3.9 | What is the timeout, retry, and circuit-breaker policy? | Timeout budget + backoff + jitter + breaker thresholds | N | C1–C2 | Resilience config |
| SA-3.10 | What happens to unprocessable messages? | DLQ + triage owner + replay path | N | C1–C2 | DLQ runbook |
| SA-3.11 | How is backpressure handled? | Bounded queues / shed / block / spill | N | C1–C2 | ADR |
| SA-3.12 | What is the rate limit and quota model? | Per-caller / per-tenant limits | N | C1–C2 | Gateway config |
| SA-3.13 | What is the Causeway composition state? | Catalog-composed / wrapped / unmanaged | N | C1–C3 | Catalog record |
| SA-3.14 | What is the promotion and exposure path? | Target tier for promotion / what it exposes outward / neither | N | C1–C2 | Promotion plan |

**References:** Enterprise Integration Patterns (SA-3.3–3.5, 3.10–3.11 — primary source for this section) · Building Evolutionary Architectures, Ford et al. (SA-3.6–3.7 — contract evolution and fitness functions) · Release It!, Nygard (SA-3.9–3.11 — circuit breakers, bulkheads, backpressure) · Twelve-Factor (backing services, disposability, concurrency) · C4 component level (SA-3.1)

## SA-4 · Infrastructure & Network

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-4.1 | What is the execution fabric? | Bare metal / VM / containers / k8s / serverless | Y | C1–C3 | ADR |
| SA-4.2 | What is the region and AZ topology? | Single-AZ / multi-AZ / multi-region | Y | C1–C2 | Topology diagram |
| SA-4.3 | What sits at the edge? | Reverse proxy / API gateway / WAF / CDN | N | C1–C2 | Network diagram |
| SA-4.4 | Service mesh: yes or no? | Yes + product class / no + what replaces it | N | C1 | ADR |
| SA-4.5 | How is the internal network segmented and egress-filtered? | Subnet/VLAN plan + default-deny egress | N | C1–C2 | Network policy |
| SA-4.6 | Is 100% of infrastructure declared as code? | Yes + tool / no + owned exception | N | C1–C2 | IaC repo + drift report |
| SA-4.7 | Which managed services are dependencies, and are they available in the target enclave? | Per-service availability in GCC High / IL5 / IL6 / air-gap | Y | C1–C3 | Enclave availability matrix |
| SA-4.8 | Who owns DNS, certificates, and PKI? | Named owner + rotation mechanism | N | C1–C2 | Cert inventory |

**References:** Well-Architected (all six pillars land here) · Twelve-Factor III (config) and X (dev/prod parity) · C4 deployment diagrams

## SA-5 · Security & Identity

Rows SA-5.9 through SA-5.13 are where this section stops being generic. They
produce authorization-package evidence.

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-5.1 | What is the human identity provider and federation path? | IdP + protocol (OIDC / SAML) | Y | C1–C3 | ADR |
| SA-5.2 | What is the authorization model and where is it enforced? | RBAC / ABAC / ReBAC + enforcement point | Y | C1–C3 | Policy spec |
| SA-5.3 | How do workloads authenticate to each other? | mTLS / SPIFFE / signed tokens / network trust | Y | C1–C2 | ADR |
| SA-5.4 | What is the credential lifetime and rotation mechanism? | TTL per credential class + rotation automation | N | C1–C2 | Rotation evidence |
| SA-5.5 | Where do secrets live at runtime? | Vault / KMS-backed / platform secret store | N | C1–C3 | Zero-hardcoded-secret scan |
| SA-5.6 | What is required in transit? | TLS version + mutual auth scope | N | C1–C3 | Config + scan |
| SA-5.7 † | What is encrypted at rest, and who holds the keys? | Storage / field-level + CSP-managed / BYOK / HYOK | Y | C1–C3 | Key custody ADR |
| SA-5.8 | What supply-chain controls are enforced in CI? | SBOM + image scan + provenance attestation | N | C1–C3 | Pipeline gate results |
| SA-5.9 | Which controls are inherited, and from which provider? | Control allocation table | N | C1–C2 | Inheritance map |
| SA-5.10 † | Where is the authorization boundary drawn? | Named boundary + what's inside/outside | Y | C1–C2 | Boundary diagram |
| SA-5.11 | How is control evidence generated and kept current? | Manual / scheduled / continuous (OSCAL) | N | C1–C2 | Evidence pipeline |
| SA-5.12 | Does the system have a UI, and what is its 508 posture? | N/A / conformant / ACR with exceptions | N | C1–C3 | Accessibility conformance report |
| SA-5.13 † | Does Tactical Authorization apply, and under what conditions? | N/A / applies + duration + revocation trigger | N | C1–C2 | TA record |
| SA-5.14 | Which package ecosystems and registries may this system depend on, and what executes at install time? | Ecosystem list + registry or mirror + install-script posture | Y | C1–C3 | Ecosystem posture ADR + committed lockfile + install-script config |
| SA-5.15 | What tool surface does inference get, and is any of it a generalized query or execution interface? | No inference path / task-specific tools only / generalized interface + owned exception | N | C1–C2 | Tool inventory with per-tool parameter contract + ADR for any generalized interface |
| SA-5.16 † | What crosses the inference boundary, and what is removed before it does? | No inference path / in-boundary inference only / redacted or tokenized pre-call / cleared to send unmodified | Y | C1–C3 | Redaction spec + call-site data-flow evidence + data-owner signature |

**SA-5.14 note.** The registry is inside the authorization boundary — it
executes code on developer laptops and CI runners (Build DNA §5). The row is
one-way because a codebase does not change ecosystems cheaply, and it is in the
short form because a compromised dependency is cleaned up by people outside the
delivery team. The standard's default is the option that does not depend on npm;
using npm is a legitimate, common, and *recorded* deviation. `rules/dependencies.md`
carries the floor that applies once it is.

**SA-5.15 and SA-5.16 note — the inference boundary.** A third-party model
provider sits outside the authorization boundary (SA-5.10) and holds logs you
cannot read, retain, or purge. Two decisions follow from that, and they are
different decisions. Both answer *no inference path* for a system that never
calls a model, and that answer closes them.

*SA-5.15 is about capability.* A model that can call `run_sql(query)` holds the
authority of whoever wrote the connection string, and every prompt reaching it —
including text that arrived from a user, a document, or an upstream system — is
an input to that authority. Task-specific tools with typed parameters remove
that class of injection by construction rather than by filtering: there is no
free-text field for an attacker to smuggle a query through. The cost is real and
belongs in the ADR — the tool surface is hand-maintained, it grows with the
product, and a question nobody wrote a tool for cannot be answered. That trade is
the decision, which is why the row is not one-way: a tool surface is expensive to
widen or narrow later, but it is reversible engineering. It sits at C1–C2 because
a C3 system has no production data to lose (SA-8.2), and a C3 system that does
has misdeclared at SA-1.1.

*SA-5.16 is about data*, and it is one-way for the same reason SA-2.11 is.
Residency and inference egress fail identically: once the bytes land somewhere
you do not control, no downstream control gets them back, and a retention
setting in a vendor console is a promise about the future rather than a remedy
for what already shipped. Redaction has to happen before the call — a filter on
the response is theater. The row is in the short form because a spill is cleaned
up by people outside the delivery team, and it carries a named approver because
"acceptable to send" is a data-owner judgment about classification, not an
engineering judgment about convenience. *Cleared to send unmodified* is a real
and often correct answer; it is simply one that someone signs.

`rules/inference.md` carries the floor for both, path-scoped to tool definitions
and inference call sites.

**References:** NIST SP 800-207 (PE/PDP/PEP → SA-5.2–5.3, SA-5.10) · NIST SP 800-37 and SP 800-53 (SA-5.9–5.10 — control allocation, inheritance, common-control providers) · NIST SP 800-161r1 (SA-5.8, SA-5.14 — C-SCRM, the source behind treating the registry as a supplier) · SLSA (SA-5.8, SA-5.14, SA-8.8 — build provenance levels) · DoD CIO cATO memo, Feb 2022 (SA-5.11, SA-5.13 — the precedent Tactical Authorization rests on) · OSCAL specification (SA-5.11 — evidence format) · Section 508 / WCAG 2.1 AA (SA-5.12) · OWASP Top 10 for LLM Applications (SA-5.15, SA-5.16 — the injection and disclosure classes these two rows exist to close) · NIST AI RMF, AI 100-1, with the Generative AI Profile, AI 600-1 (SA-5.15, SA-5.16 — govern/map/measure/manage, and the source behind putting a named human on inference egress) · NIST SP 800-122 (SA-5.16, SA-2.12 — PII confidentiality and de-identification) · Well-Architected security pillar

## SA-6 · Observability & Operations

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-6.1 | What is the telemetry standard and collector topology? | OTel-native / vendor agent / hybrid | N | C1–C2 | Telemetry architecture |
| SA-6.2 | What SLIs measure the SA-1 targets? | One SLI per target in SA-1.3–1.5 | N | C1–C2 | SLI definitions traced to SLOs |
| SA-6.3 | What metrics are emitted? | Golden signals + domain metrics | N | C1–C2 | Metric catalog |
| SA-6.4 | What is the log structure, correlation, and retention? | Structured format + trace/span ID + retention | N | C1–C2 | Logging standard |
| SA-6.5 | What is traced and at what sampling rate? | Coverage scope + sampling policy | N | C1–C2 | Trace coverage report |
| SA-6.6 | What pages a human vs. files a ticket? | Alert routing policy | N | C1–C2 | Alert policy |
| SA-6.7 | What is the on-call model and runbook requirement? | Rotation + runbook-per-alert rule | N | C1 | Runbook index |
| SA-6.8 | What classification does telemetry carry? | Log/trace data classification + scrubbing | N | C1–C2 | Scrubbing config |

**References:** Google SRE Books — *SRE* ch. 6 (four golden signals), *SRE Workbook* ch. 2 and 4 (SLO implementation, alerting on SLOs). Treat as the primary source for this section. · Twelve-Factor XI (logs as event streams → SA-6.4)

## SA-7 · Resilience & Continuity

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-7.1 | What is the blast radius boundary? | AZ / cell / tenant pod / worker pool | Y | C1–C2 | Cell design |
| SA-7.2 | What degrades gracefully, and how? | Fallback behavior per dependency | N | C1–C2 | Degradation matrix |
| SA-7.3 | Which dependencies are critical vs. optional? | Dependency criticality map | N | C1–C2 | Dependency map |
| SA-7.4 | What is the DR posture? | Backup-restore / active-passive / active-active | Y | C1–C2 | DR plan |
| SA-7.5 | What triggers failover, and how often is it drilled? | Trigger + drill cadence | N | C1 | Last drill record |
| SA-7.6 | Is failure injected deliberately, and at what scope? | None / staging / production | N | C1 | Chaos results |
| SA-7.7 | What capacity headroom is maintained? | Saturation threshold + scaling policy | N | C1–C2 | Capacity plan |

**References:** Release It!, Nygard (SA-7.2 — graceful degradation and the failure-pattern vocabulary) · Well-Architected reliability pillar · Google SRE Book ch. 21–22 (overload, cascading failures)

## SA-8 · Delivery & Environments

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-8.1 | What environments exist, and how close is each to production? | Env inventory + parity gaps | N | C1–C2 | Environment matrix |
| SA-8.2 | Where does realistic test data come from? | Synthetic generation / masked subset / hand-built | N | C1–C3 | Test data pipeline (no prod PII) |
| SA-8.3 | What tests exist, and what gates the pipeline? | Unit / integration / e2e / contract + coverage floor | N | C1–C2 | CI gate config |
| SA-8.4 | What is the deployment strategy and rollback trigger? | Blue-green / canary / rolling + automated trigger | N | C1–C2 | Deploy config |
| SA-8.5 | What is the release cadence and change-control path? | Cadence + CCB/CAB requirement | N | C1–C2 | Change process |
| SA-8.6 | How is runtime behavior changed without a deploy? | Feature flags / config service / none | N | C1–C2 | Flag inventory |
| SA-8.7 | Which gate profile applies, and does the system pass it? | G0 / G1 / G2 / G3 — derived, never declared (see `gate/gate-configuration.md`) | N | C1–C3 | Gate run receipt |
| SA-8.8 | How do artifacts get promoted, and is provenance preserved? | Promotion path + signing | N | C1–C2 | Signed artifact chain |
| SA-8.9 | Does this system contribute components back to the catalog? | Yes + which / no | N | C1–C2 | Catalog contribution record |

**References:** Accelerate, Forsgren/Humble/Kim (SA-8 — the evidence for why these rows matter) · Twelve-Factor V (build/release/run) and X (dev/prod parity) · Google SRE Book ch. 8 (release engineering)

## SA-9 · Lifecycle & Exit

The section everyone skips, and the one that costs the most when skipped.

| ID | Decision | Answer set | One-way | Applies | Evidence |
|---|---|---|---|---|---|
| SA-9.1 | What is the lock-in tolerance per managed dependency? | Acceptable / hedge / avoid, per service | N | C1–C2 | Lock-in assessment |
| SA-9.2 | If we had to leave, how would data come out? | Export format + effort + egress cost | N | C1–C2 | Exit plan |
| SA-9.3 | What conditions mean this system should be retired? | Named sunset criteria | N | C1–C3 | Sunset criteria |
| SA-9.4 † | At decommission, what happens to the data? | Migrate / archive / destroy + verification | N | C1–C3 | Disposition plan |
| SA-9.5 | Where is the documentation of record, and who owns it? | Location + named owner | N | C1–C2 | Doc index |
| SA-9.6 | Where is the ADR index for this system? | Repo path | N | C1–C2 | ADR index |

**References:** NARA General Records Schedules (SA-9.4 — disposition is a legal obligation) · Building Evolutionary Architectures (SA-9.1 — lock-in as an architectural property) · Cloud FinOps (SA-9.2 — egress cost modeling)

---

## The one-way doors

Twenty-eight rows. If you close nothing else before code, close these.

SA-1.1 · SA-1.2 · SA-1.7 · SA-1.8 † · SA-1.9 † · SA-1.14 · SA-2.1 · SA-2.2 ·
SA-2.3 · SA-2.11 † · SA-3.1 · SA-3.3 · SA-3.4 · SA-3.5 · SA-3.6 · SA-3.8 ·
SA-4.1 · SA-4.2 · SA-4.7 · SA-5.1 · SA-5.2 · SA-5.3 · SA-5.7 † · SA-5.10 † ·
SA-5.14 · SA-5.16 † · SA-7.1 · SA-7.4

---

## C3 short form

Twenty-three rows. Required of every system regardless of class — this *is* the
`C1–C3` filter, not a summary of it. A C3 system that closes these twenty-three
is done with the spine.

The selection principle: keep every row where a wrong answer creates a problem
someone *outside* the delivery team has to clean up — a spill, an audit finding,
an orphaned system, an unauthorized dependency. Drop every row whose blast
radius stops at the team that built it.

| # | ID | Short question |
|---|---|---|
| 1 | SA-1.1 | Criticality class |
| 2 | SA-1.8 † | Highest data classification |
| 3 | SA-1.11 | Production owner |
| 4 | SA-1.14 | Causeway tier |
| 5 | SA-2.1 | Storage paradigm |
| 6 | SA-2.9 | Retention and purge |
| 7 | SA-2.12 | PII/CUI treatment |
| 8 | SA-3.13 | Composition state |
| 9 | SA-4.1 | Execution fabric |
| 10 | SA-4.7 | Enclave availability of dependencies |
| 11 | SA-5.1 | Identity provider |
| 12 | SA-5.2 | Authorization model |
| 13 | SA-5.5 | Runtime secrets |
| 14 | SA-5.6 | Transit encryption |
| 15 | SA-5.7 † | At-rest encryption and key custody |
| 16 | SA-5.8 | Supply-chain controls in CI |
| 17 | SA-5.12 | 508 posture |
| 18 | SA-5.14 | Package ecosystem and registry posture |
| 19 | SA-5.16 † | What crosses the inference boundary |
| 20 | SA-8.2 | Test data source |
| 21 | SA-8.7 | Gate profile and result |
| 22 | SA-9.3 | Sunset criteria |
| 23 | SA-9.4 † | Data disposition at decommission |

Eleven of the twenty-eight one-way doors are in the short form. The other
seventeen are absent because a C3 system that outgrows its class should
re-declare at SA-1.1 and pick up the full spine — the escape hatch is
reclassification, not partial rigor.

Note that four of the twenty-three are † rows. A C3 sandbox app still needs a
named human on classification, key custody, disposition, and whatever it sends
to a model it does not run. That is the floor. The fourth is there because the
prototype is where this one actually goes wrong: production data pasted into a
commercial model to see whether the idea has legs is a spill, and it is a spill
whether or not the thing it was proving ever ships.

---

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

## Packaging

Ships as **one skill**, not three.

The skill's job is not to print a table. It is to make the judgment call that a
human would otherwise make badly:

1. **Pick the view.** Decision Register during design, Review Checklist at a
   gate, SAD Outline at delivery. Choosing correctly *is* the skill; a user who
   already knew which view they wanted would not need it.
2. **Filter by class and tier.** Read SA-1.1 and SA-1.14, apply the `Applies`
   column and the gate matrix, and never show a C3 team 94 rows.
3. **Enforce the ADR seam.** A decision without an ADR reference is not closed.
   The skill says so rather than accepting prose.
4. **Surface waivers by expiry.** Anything expiring inside 60 days gets raised
   unprompted. Anything expired is a hard fail.
5. **Escalate † rows.** Never let a named-approver row close without a name.

Three separate skills would force the user to pick a view before they have the
information needed to pick correctly, which inverts the whole point.

---

## Open questions for v0.9

**Numbers are stable from v0.8.** A closed question keeps its number and its entry,
marked closed with the resolution — the rule `gate/gate-configuration.md` §10 states
for itself, adopted here. The two closures above carry no number because they
predate it and were closed by renumbering; retrofitting numbers onto them now would
be the third numbering scheme this document's own row IDs exist to avoid. Question 1
below is the first closed in place. See ADR 0026.

**Closed at v0.8: SA-3.13's answer set.** The row read *Greenfield / wrapped /
composed* against Build DNA §4's *catalog-composed / wrapped / unmanaged*, and
`composition-state` blocks at all four profiles on that set. Two axes had been
folded into one row — greenfield-versus-brownfield is lifecycle, composition state
is what the system is made of. Build DNA is now the stated source of truth for
vocabulary and the spine cites rather than defines it; where the two disagree, the
spine moves. The standard's own CI checks the three sources agree on every push,
which is the part that keeps it closed. See ADR 0008.

**Closed at v0.7: spine version drift.** Carried since v0.4 and deferred twice.
The standing proposal — applies to newly registered systems, forced on existing
ones at the next TA renewal or promotion — could not be ratified once the check
inventory was read against it: `ta-valid` and `promote-or-sunset` run at G1 only,
so the forcing function reached roughly a quarter of the portfolio and never
reached G3 at all, core tier having nothing above it to be promoted into. The
systems other systems inherit from were the ones it could never touch. Replaced by
the adoption horizon, above. See ADR 0005.

1. **Build DNA reconciliation — closed at v0.8.** The question asked for a diff
   of `build-dna-v1.0.md` against whatever repo copy still existed, on the premise
   that a canonical `AGENTS.md` unretrievable from Drive left the design layer
   citing a document it could not produce. ADR 0021 settled it in the process
   layer: this repository is the document of record, ADR 0001 said so, and waiting
   for a Drive copy to win a comparison was the error rather than the remedy. Build
   DNA's own open item 2 closed on that argument at 1.6. This row kept waiting for
   the same diff for two more releases, because nothing connected a closed item in
   one register to an open one in another. That connection now exists and this is
   the first thing it closed. See ADR 0021 and ADR 0026.
2. **Gate implementation.** The four profiles now have a configuration spec.
   Steps 1 and 3 of its implementation order are the risk — portfolio backfill
   of `criticality_class` requires a named human per system, and v0.7 adds
   `spine.closed_against` to the same backfill.
3. **Catalog items as systems.** A catalog item needs a criticality class too,
   or it inherits the strictest class among its consumers. The second is more
   correct and more expensive.
4. **The fourth library entry.** Design layer and process layer are documented.
   Anything added next should be scoped against those two first, so it doesn't
   turn out to be a third view of something that already exists. v0.6 is the
   first iteration that ran the test deliberately — one candidate landed in
   `AGENTS.md`, two landed here, and the sorting question was answered before
   anything was written rather than after.
5. **Where AI-system rows stop.** SA-5.15 and SA-5.16 cover the boundary: what
   the model can reach and what reaches the model. They say nothing about
   evaluation, non-determinism as a reliability property, model version pinning,
   or what an SLO means for a component whose output distribution moves under
   you. Those are real decision surfaces and they are not in this spine. The
   question is whether they are spine rows, an SA-10 section, or a separate
   instrument — and the honest answer today is that we have not built enough of
   them to know.
6. **Does the adoption horizon survive its first expiry?** Nothing expires until
   2027-02-04, when SA-5.16 starts blocking on systems that closed against v0.5.
   The horizon is ratified on the argument that a dated finding converts to
   action before it converts to a block. That is a claim about behavior, and it
   has not been tested once. If the February date arrives with a queue of
   last-minute waivers, the horizon is a deferral mechanism wearing a deadline
   and should be shortened or replaced rather than re-extended.
