# Platform Overlay: ServiceNow

| | |
|---|---|
| **Overlay** | `overlays/servicenow` · machine-readable projection in `servicenow.json` |
| **Version** | 1.12 |
| **Ratified against** | Decision Spine v0.8 · Gate configuration v0.8 · Build DNA v1.13 |
| **Reconciled at** | Causeway 2.1.0. History, not a currency claim — the row above is what CI enforces. |
| **Applies to** | Development, configuration, and integration work delivered on a ServiceNow instance |
| **Governs** | Nothing. Causeway core governs. See `overlays/README.md`. |

---

> ## Reconciled in 1.1
>
> Core moved twice underneath this overlay, and neither change touched a
> disposition.
>
> **Spine v0.8 corrected SA-3.13's answer set.** `greenfield` was never a
> composition state — it answers a lifecycle question — and the row now reads
> *catalog-composed / wrapped / unmanaged* (ADR 0008). This overlay was already
> written in the correct vocabulary, which is part of how the row was caught. §4
> and §7 now say so explicitly, because the platform supplies two other things
> called a catalog and neither of them is the one that word means here.
>
> **Gate configuration v0.6 published the engine contract** (ADR 0009). Checks now
> declare the *input classes* they must be able to read, and a required check whose
> class an engine cannot supply resolves to `unsupported` — exit 4, blocked, nothing
> evaluated. That turns this overlay's quietest footnote into its sharpest finding:
> on ServiceNow the input-class handshake is a question about SA-8.8, and update-set-only
> delivery leaves five of the fourteen classes unsuppliable — six where the shop keeps
> no repository at all. §8 carries the map; §6 and open item 1 get the evidence they
> were waiting for.
>
> **No row's disposition changed. The counts in §2 and §5 are unmoved.**

> ## Ratified again at 1.2
>
> Causeway 1.6.2 moved no version this overlay depends on — the spine is still
> v0.8, the gate configuration still v0.6, Build DNA still 1.5 — so re-ratifying
> means confirming that and saying where it was confirmed, which is the new
> **Reconciled at** row. Nothing in the disposition table moved and nothing in it
> was going to.
>
> What 1.2 adds is `overlays/servicenow.json`: the same overlay, machine-readable.
> §1 also now states the posture the rest of the document has always assumed and
> never wrote down. Both exist for the same reason — see below.

> ## Ratified again at 1.9
>
> **Build DNA moved to 1.12** (ADR 0031), adding three rules to §8: a decision is
> recorded only when a readiness test says it is ready, an ADR states the forces that
> discriminated between its alternatives, and a superseding ADR classifies why it
> superseded. Causeway also gains an intake artifact — `templates/survey.md` and
> `skills/survey/` — upstream of the ADR seam.
>
> **No §7 row, and no disposition moved.** All three rules govern how a decision
> reaches the seam, and the seam is platform-neutral by construction: §8 has never
> had a ServiceNow disposition and does not acquire one here. A scoped application
> records its ADRs under the same discipline as a Go service, and the readiness test
> asks about this system's ground truth rather than about the platform.
>
> Worth naming, because it is the one place the platform touches this. The intake
> instrument's §S1 prompts include *what the target platform cannot do*, and on
> ServiceNow that prompt has more to find than on most targets — update-set-only
> delivery is exactly the kind of constraint that is knowable on day one and surfaces
> late. This overlay is a good source for those rows. Being a good source for a `GR-`
> row is not a disposition, so the table is unmoved and the counts in §2 and §5 are
> unmoved with it.

> ## Ratified again at 1.8
>
> **Build DNA moved to 1.11** (ADR 0030), adding one rule to §3: how a dependency
> arrives on the target machine is part of its design, and an install path may not
> assume a toolchain the target does not have. Causeway now publishes a signed,
> reproducible archive, and `sync.sh --require-release` is satisfied by verifying
> the release signature rather than by reading a git tag.
>
> **No §7 row, and no disposition moved.** The rule governs how a project obtains
> an upstream, and on this platform that question is already answered twice by rows
> this overlay has always carried — §8's input-class handshake for the shop that
> keeps no repository, and SA-8.8 for where an artifact came from.
>
> What changes is worth naming and is smaller than it looks. An update-set-only
> shop has no clone of anything by construction, which is why five of the fourteen
> input classes are unsuppliable there and why §8 reads the way it does. Such a
> shop can now obtain the standard the way it already obtains everything else it
> installs: as a file someone hands it. That makes an existing disposition cheaper
> to satisfy. It does not move the disposition, and it supplies no input class —
> a repository the shop still does not keep is still a repository an engine still
> cannot read.

> ## Ratified again at 1.6
>
> **Build DNA moved to 1.9** (ADR 0027), adding a correction rule to §8: a factual
> error in an accepted ADR is corrected by a later one, and the corrected ADR gains
> a `corrected_by` pointer in its frontmatter while its body stays untouched.
>
> **No §7 row.** The rule is about the ADR record's own shape and has no platform
> reading — a ServiceNow ADR is a file in the application repository like any other,
> and update-set-only delivery's lack of a repository is already declared against
> the index row rather than needing restating here. Re-ratified rather than
> reconciled, which is what 1.2 meant by the same word.
>
> Worth naming while it is cheap: this is the third Build DNA bump in three
> releases and the first with nothing to translate. ADR 0027 says the same thing
> from the core side — if a fourth arrives with no platform reading, the question to
> ask is about the guard's granularity, not about what row to invent.
>
> **No row's disposition changed. The counts in §2 and §5 are unmoved.**

> ## Reconciled in 1.5
>
> **Build DNA moved to 1.8** (ADR 0026), adding relations to the open-items index:
> an item may name a duplicate, a superseding item, an upstream item, the document
> that answered it, or a declared blocker, and the build enforces what each name
> promises.
>
> This overlay is the reason that rule reads the way it does. Three of its open
> items said *the finding belongs upstream* and only one of them named something
> that existed. Worse, §8's `release_state` analysis had been answering gate
> configuration open item 8's question since 1.1 — *on this platform the set is not
> small* — and nothing carried it back, so core's item read as unresolved for three
> releases while the answer sat in this document. Containment is why: an overlay may
> not change a check, so recording is all it can do, and recording into a document
> core does not read is indistinguishable from not recording at all.
>
> Core opened gate configuration items 11 and 12 so open items 5 and 6 have real
> upstream targets, and item 8 now carries this overlay's evidence with the remedy
> named and deferred to its own ADR. §7's index row gains the platform reading.
>
> **No row's disposition changed. The counts in §2 and §5 are unmoved.**

> ## Reconciled in 1.4
>
> **Build DNA moved to 1.7** (ADR 0025), which adds one rule to §8: an ADR that
> opens or closes an open item records it in the project's open-items index. §7
> carries the translation and it is a short row with one trap in it.
>
> The trap is that this platform already has three things shaped like an open-item
> register — the customization ledger, skip records at upgrade, and Instance Scan
> findings — and none of them is this one. A ledger row is a deviation somebody
> owns. A skip record is an input: it becomes an index item when an ADR reads it
> and leaves something open, and not before. Merging any of them into the index
> produces a list where *open* means four different things.
>
> The declared gap is the familiar one. Update-set-only delivery has no repository
> to keep the index in, which is the same absent surface that leaves five input
> classes unsuppliable in §8. This overlay names it rather than nominating a table
> to stand in for a file.
>
> **No row's disposition changed. The counts in §2 and §5 are unmoved.**

> ## Reconciled in 1.3
>
> **Build DNA moved to 1.6** (ADR 0022) and this overlay did not notice for a
> release. The header above names three versions, and `validate.py` checked two
> of them — the spine and the gate configuration — so Build DNA could move
> underneath the overlay without the build saying so. It now checks all three,
> in the prose header and in `servicenow.json`, and this note is what moving the
> header cost (ADR 0024).
>
> 1.6 added five things and changed no section number: an adoption contract,
> pin-upstream-never-fork under §3, an offline build-and-test rule under §6,
> declared gaps under §8, and profile resolution under §9. §7 carries the
> platform translation of each. Two of them are worth reading rather than
> skimming. The offline rule cannot be taken literally on a platform whose test
> runner is the instance, and §7 says what the honest version is instead of
> pretending the instance is a local cache. The declared-gap rule turns out to
> be a rule this overlay was already implementing three times over — every N/A
> cell in §8, the input-class map, and the ledger row that has no ADR yet — and
> it now says so.
>
> **No row's disposition changed. The counts in §2 and §5 are unmoved.**

## 1. Platform posture

ServiceNow is itself a causeway. A pre-authorized, vendor-maintained paved road is
the product, and adopting it means inheriting a body of decisions that would
otherwise be yours to make: compute, network topology, base observability, HA/DR,
patching. That inheritance is real and this overlay records it, so *why is there no
decision for X?* always has an answer on file.

The corollary is the platform's central risk. **Every step off the paved road is
easy to take and expensive to keep.** Modified out-of-box artifacts, global-scope
scripts, and quietly load-bearing citizen apps are ServiceNow's native failure
modes, and none of them announces itself. This overlay exists to make each one a
visible, owned, expiring decision rather than an accident discovered at upgrade.

### The posture, stated

**ServiceNow is the human work surface. It is not where Causeway's semantics get
reimplemented.**

Everything in this document follows from that sentence, and until 1.2 it was
implied rather than written. The platform is extraordinarily good at holding the
work — the request, the approval, the assignment, the change record, the service
owner. It is also a place where a determined team can rebuild anything, including
a second copy of the gate: a table of "spine rows", a flow that computes a
profile, a business rule deciding whether a system is compliant. That work always
looks like progress and it always ends the same way, with two definitions of
closed that agree until the day they do not.

The division that holds:

- **Causeway defines** what must be true — the rows, the answer sets, the profile
  resolution, the check specifications.
- **An engine determines** whether it is true and preserves the proof.
- **ServiceNow carries the human work** and is a source of evidence like any other
  system of record: ATF results, Instance Scan findings, the TA record, the
  application version, the service owner.

A ServiceNow implementation may read and display any of this. It may not decide
it. The concrete test is whether a value the gate acts on can be edited on the
instance by someone with a role — if it can, the instance is deciding, and the
receipt is describing the instance's opinion rather than the system's state. This
is the same reasoning that makes `release_state` derived rather than declared and
gate profiles resolved rather than chosen, applied to a platform where writing
the second implementation is unusually easy.

`overlays/servicenow.json` exists to make the honest path cheaper than the other
one. A team that has to parse this document to get its dispositions will end up
retyping them into a table on the instance; a team handed the mapping in a file
does not.

## 2. The headline, which is not what you would guess

The intuition going in was that a platform this large answers most of the spine.
Dispositioning all 94 rows says otherwise:

| Disposition | Rows | Share |
|---|---|---|
| **I** — Inherited | 11 | 12% |
| **S** — Shared | 39 | 41% |
| **P** — Project-answered | 44 | 47% |
| **Total** | **94** | |

**Of the 23 rows in the C3 short form — the ones every system owes regardless of
class — exactly one is inherited.** That is SA-4.1, execution fabric.

The gap between the intuition and the number is the difference between *I do not
have to build it* and *I do not have to decide it*. ServiceNow builds an enormous
amount for you. It decides very little. Encryption at rest exists, and which
columns get it, who holds the keys, and whose name is on that choice are still
three open questions. That pattern is what produces 39 shared rows: the mechanism
arrives, the decision does not.

The practical consequence for a team adopting this: **do not budget less spine work
because the platform is managed.** Budget the same work, in a different shape.
Fewer rows will require you to design a mechanism; more will require you to
document a choice you did not realize you were making.

## 3. The worked example: an inherited row that still closes

SA-4.1 is *what is the execution fabric?* On ServiceNow the answer is vendor-operated
SaaS. There is no alternative to weigh, no configuration to pick. It disposes to `I`.

It is also one-way and in the short form, which means a C3 sandbox app owes it.
Both things are true at once, and the resolution is the rule in `overlays/README.md`:
inherited is a closure state. The ADR is four lines and a citation. It is not
optional, and a register showing SA-4.1 as blank because "the platform handles it"
has an open one-way short-form row, which `oneway-closure` blocks on at G1 and above.

If that reads as bureaucratic for a row with one possible answer, consider what the
ADR is actually for: it is the artifact that tells a reviewer in 2029 that this
system runs somewhere nobody on the delivery team controls, and that no one ever
evaluated an alternative. That is worth four lines.

## 4. Row-level disposition

All 94 rows. `†` marks a named-approver row — the name is still required whatever
the disposition says. `→` marks a row whose answer set is given platform vocabulary
in §6.

### SA-1 · Context & Constraints

| ID | D | Note |
|---|---|---|
| SA-1.1 | P | Unchanged. The platform says nothing about what failure costs. |
| SA-1.2 | P | Bounded contexts become scopes. Closing this first is what makes SA-3.1 answerable rather than arbitrary. |
| SA-1.3 | S | Bounded above by the instance SLA. Cite it; the target is still yours. |
| SA-1.4 | S | Bounded by transaction quotas and by ACL evaluation cost on the critical path. |
| SA-1.5 | S | Same bound. Peak *shape* matters more than baseline here — quotas bite per transaction. |
| SA-1.6 | P | — |
| SA-1.7 | P → | Domain separation. One-way. |
| SA-1.8 † | P | Unchanged. |
| SA-1.9 † | S | The instance's authorization is inherited and cited. Whether this app rides it is yours. |
| SA-1.10 | P | License units are the unit of account. Custom tables, integration transactions, and license-bearing features all land here. |
| SA-1.11 | P | Evidence can be the service-owner record in the instance rather than a separate document. |
| SA-1.12 | S | Usually the platform: a quota, ACL evaluation, or a synchronous integration. Rarely compute. |
| SA-1.13 | P | Table growth drives license posture. This row feeds SA-1.10. |
| SA-1.14 | P | Unchanged. |

### SA-2 · Data & Persistence

| ID | D | Note |
|---|---|---|
| SA-2.1 | S → | Table strategy. One-way, short form. The single highest-consequence decision on this platform. |
| SA-2.2 | I | Platform-managed. There is no shard control to exercise. |
| SA-2.3 | I | One transactional store, strong consistency. Where async breaks that assumption, the answer is at SA-3.4. |
| SA-2.4 | S | Column adds are online. Type changes and reference re-pointing are not. |
| SA-2.5 | S | Platform caching is inherited. Cache-heavy patterns you build are yours. |
| SA-2.6 | I | Sessions are platform-managed. |
| SA-2.7 | I | Instance-level. State held in flight by an integration is a separate answer at SA-7.2. |
| SA-2.8 | S | Backups are platform. Clone cadence, and what a clone preserves, are yours — see SA-8.2. |
| SA-2.9 | P | Short form. Table rotation, archiving, destruction. Nothing here has a safe default. |
| SA-2.10 | S | `sys_audit` exists. Which tables it covers, and whether the audit record is readable by the roles it audits, are yours. |
| SA-2.11 † | S | Instance datacenter is an instance-owner fact — cite it. Integration egress destinations are yours. |
| SA-2.12 | P | Short form. Covers what you put in tables *and* what reaches `syslog` — see SA-6.8. |

### SA-3 · Application & Integration

| ID | D | Note |
|---|---|---|
| SA-3.1 | P → | Scope model. One-way. Build DNA §2, translated. |
| SA-3.2 | S | Table API, Scripted REST, or GraphQL. The choice constrains SA-3.6. |
| SA-3.3 | S | Event queue, scheduled jobs, MID Server, or Flow. **None of these is a durable broker.** Name which one, and name what it does not guarantee. |
| SA-3.4 | P | The platform gives you no idempotency. Import-set coalesce is a matching rule, not a delivery guarantee. This is where ServiceNow integrations actually fail. |
| SA-3.5 | P | Event-queue ordering is not guaranteed across workers. Say what you need before you find out. |
| SA-3.6 | P | — |
| SA-3.7 | P | — |
| SA-3.8 | P → | Integration pattern and adapter boundary. One-way. Build DNA §3, translated: a spoke is a vendor SDK. |
| SA-3.9 | P | Platform REST calls ship with defaults. A default is not a decision, and this row is `P` rather than `S` for that reason. |
| SA-3.10 | P | There is no DLQ. An error table with a triage owner and a replay path is something you build. |
| SA-3.11 | S | Bounded by quotas rather than by your design, which is not the same as handled. |
| SA-3.12 | S | Inbound rate-limit rules exist. Outbound is yours. |
| SA-3.13 | P | Short form. Answer set corrected in spine v0.8 — `catalog-composed` · `wrapped` · `unmanaged`. A Store app you configured is `wrapped`. **The Store is not the Causeway catalog and neither is the Service Catalog**, so `catalog-composed` is rarer here than the word suggests. See §8. |
| SA-3.14 | P | — |

### SA-4 · Infrastructure & Network

| ID | D | Note |
|---|---|---|
| SA-4.1 | I | Vendor-operated SaaS. One-way, short form — still closes with an ADR. See §3. |
| SA-4.2 | I | Instance pair, vendor-operated. Cite the datacenter pair. |
| SA-4.3 | I | — |
| SA-4.4 | I | There is no mesh to decide about. C1 only. |
| SA-4.5 | S | Instance networking is inherited. **MID Server placement and its egress are yours**, and are the one place you own network posture on this platform. |
| SA-4.6 | S | Source-controlled scoped apps are the nearest thing to IaC here. Coupled to SA-8.8. |
| SA-4.7 | P | Short form, one-way. **Plugin and spoke availability differs by instance class.** Gov and FedRAMP-authorized instances do not carry everything the commercial documentation describes. Verify per dependency; do not assume. |
| SA-4.8 | S | Instance certificates are platform. Certificates for mutual-auth integrations are yours to own and rotate. |

### SA-5 · Security & Identity

| ID | D | Note |
|---|---|---|
| SA-5.1 | S | Platform supplies SAML/OIDC. The federation path and the **local-account fallback** are yours. The fallback is the part that gets forgotten. |
| SA-5.2 | P | ACLs and roles are the mechanism, not the model. The most-gotten-wrong row on this platform: name where enforcement happens and what a role actually grants. |
| SA-5.3 | S | — |
| SA-5.4 | S | Connection & Credential aliases carry the mechanism. Lifetime and rotation are yours. |
| SA-5.5 | P | Short form. Credential store or alias — never a system property, never a script include. |
| SA-5.6 | S | Inbound TLS is platform. Outbound integration TLS posture is yours. |
| SA-5.7 † | S | Platform encryption at rest is inherited. Column-level encryption and key-management options are decisions with real cost. The name is still required. |
| SA-5.8 | P | Short form. **Store apps and third-party spokes are supply chain.** Reads together with SA-5.14. |
| SA-5.9 | S | §4 of this document *is* this row's artifact. Cite it alongside the instance's authorization package. |
| SA-5.10 † | S | The instance boundary is inherited and cited. Where this app sits inside it, and what it reaches outside it, is yours. |
| SA-5.11 | S | — |
| SA-5.12 | S | Short form. The platform UI carries a vendor conformance report — cite it. **Custom UI pages, portal widgets, and UI Builder pages are not covered by it** and are yours. |
| SA-5.13 † | P | — |
| SA-5.14 | P → | Short form, one-way. Store apps, third-party spokes, and any npm build sitting behind a portal widget or UI Builder page. |
| SA-5.15 | P | Now Assist skills and any LLM spoke are a tool surface. A skill with generalized table access is a generalized interface, and the row's answer set already covers it. |
| SA-5.16 † | P | Short form, one-way. **Now Assist and every LLM spoke send record data to a provider.** Answer this before enabling the feature, not after. |

### SA-6 · Observability & Operations

| ID | D | Note |
|---|---|---|
| SA-6.1 | S | — |
| SA-6.2 | P | — |
| SA-6.3 | S | — |
| SA-6.4 | S | `syslog` rotates, and retention there is shorter than most teams assume. Check the number before relying on it for anything. |
| SA-6.5 | S | — |
| SA-6.6 | S | Routing beyond email usually means a license-bearing product. That cost lands at SA-1.10. |
| SA-6.7 | P | — |
| SA-6.8 | P | Logging a record object writes record data into a table with broad read access. This row is not theoretical here — it is the most common quiet spill on the platform. |

### SA-7 · Resilience & Continuity

| ID | D | Note |
|---|---|---|
| SA-7.1 | S | Scope and domain are the blast-radius units you actually control. |
| SA-7.2 | P | What the app does when an integration is down. The platform has no opinion and no default. |
| SA-7.3 | P | — |
| SA-7.4 | I | Instance-level, vendor-operated. |
| SA-7.5 | I | C1 only. Vendor-run. |
| SA-7.6 | I | C1 only. Not available to you. |
| SA-7.7 | S | Quota headroom, not compute headroom. |

### SA-8 · Delivery & Environments

| ID | D | Note |
|---|---|---|
| SA-8.1 | S | Instances exist; **parity is the gap.** Sub-production instances are clones of varying age with integrations pointed at test endpoints, or at nothing. |
| SA-8.2 | P | Short form. **A clone carries production data.** Clone exclusions and data preservers are the mechanism; deciding what must never reach sub-production is the row. |
| SA-8.3 | P | ATF is the mechanism. Coverage of business rules, flows, and ACLs is the decision. |
| SA-8.4 | S | Back-out depends on SA-8.8. An update set backs out; a customized out-of-box record often does not, cleanly. |
| SA-8.5 | S | The platform is frequently the change-control system of record for the whole organization. Say whether this app's own changes ride it. |
| SA-8.6 | S | System properties are the flag mechanism, and they are editable in production by role. Say who holds that role. |
| SA-8.7 | P | Short form. Derived, never declared. See §7. |
| SA-8.8 | S → | Source control versus update sets. |
| SA-8.9 | P | — |

### SA-9 · Lifecycle & Exit

Every row here is `P`, and this section is sharper on a proprietary platform than
anywhere else. It is also the section teams skip first.

| ID | D | Note |
|---|---|---|
| SA-9.1 | P | Every out-of-box customization is a lock-in purchase. This row carries the *policy*; the exceptions register carries the per-artifact instances. |
| SA-9.2 | P | Table export is easy. **Exporting the logic is not.** Flows, business rules, client scripts, and ACLs do not leave. Say so in the exit plan rather than discovering it during one. |
| SA-9.3 | P | Short form. |
| SA-9.4 † | P | Short form. |
| SA-9.5 | P | — |
| SA-9.6 | P | The app repository, not the instance. |

## 5. Counts

| | |
|---|---|
| Rows dispositioned | 94 of 94 |
| Inherited / Shared / Project-answered | 11 / 39 / 44 |
| Short-form rows inherited | 1 of 23 (SA-4.1) |
| Named-approver rows, all dispositions | 8 of 8 still require a name |
| One-way rows given platform vocabulary in §6 | 5 of 28 |
| Checks reading at least one `repo-*` input class | 17 of 27 |
| Of those, blocking at G2 | 10 of 16 |
| Input classes an update-set-only shop cannot supply | 5 of 14, or 6 with no documentation repository either |
| Rows added, retired, or reclassified by this overlay | **0** |

That last line is the containment rule holding. If a future revision of this
overlay cannot keep it at zero, the change belongs in the spine.

## 6. Platform vocabulary for one-way answer sets

The spine has 28 one-way doors. ServiceNow changes the *answer set* for five of
them. These are not new doors and they carry no new numbering — they are the
existing rows, said in the platform's language.

Everything here closes by ADR before build begins, because that is what the spine
already says about one-way rows.

**SA-3.1 · Architecture pattern → scope model.** One-way.

> `scoped application` (default) · `global scope` · `multiple scoped apps with
> declared cross-scope privileges` · `Store app extended in place`

Build DNA §2 translated: **scoped application by default, global scope by
decision.** Same inversion, native mechanics. Moving logic between scopes after
dependencies form is a rebuild rather than a refactor, which is what makes it
one-way. Global scope is a legitimate, recorded deviation with an ADR, not a
prohibition.

**SA-2.1 · Storage paradigm → table strategy.** One-way, short form.

> `extend Task` · `extend cmdb_ci` · `extend another out-of-box table` · `new
> custom table` · `data held outside the platform and integrated`

The highest-consequence decision on this platform, and the one most often made by
whoever created the first table. Extension inherits behaviour — assignment,
approvals, SLAs, the whole apparatus — that cannot be bolted on afterwards. Custom
tables do not inherit it and carry a license class that compounds per table, which
is why this row closes jointly with SA-1.10 rather than after it.

**SA-1.7 · Tenancy model → domain separation.** One-way.

> `no domain separation` (default) · `domain separation` · `separate instance`

The spine's tenancy row wearing a badge. Retrofitting domain separation into a
populated instance is among the most expensive operations this platform offers, and
the decision is usually made by not making it.

**SA-3.8 · Adapter boundary → integration pattern.** One-way.

> `IntegrationHub spoke` · `Scripted REST API` · `Table API consumed directly` ·
> `MID Server` (JDBC, file, or on-prem HTTP) · `import set with transform map`

Each locks in a credential model, error semantics, and license posture, and
changing pattern later means re-testing every consumer. Build DNA §3 applies
without modification: **a spoke is a vendor SDK.** The canonical schema is defined
from your domain, the spoke sits behind an adapter, and swapping it touches one
place. A flow that calls a spoke directly from business logic is the handler-code
SDK call §3 exists to prevent, in a different costume.

**SA-5.14 · Package ecosystem → what you install.** One-way, short form.

> `ServiceNow Store applications` · `third-party spokes` · `npm behind a portal
> widget or UI Builder build` · `none`

Store apps and spokes are third-party code running inside your authorization
boundary with your data. Build DNA §5's reasoning transfers whole. The npm clause
matters more than it looks: portal widgets and UI Builder pages have a JavaScript
build, that build has a lockfile and install scripts, and `dependency-provenance`
and `install-scripts` both block at every profile.

### One near-miss, recorded rather than smuggled in

**SA-8.8 · Source control versus update sets** *reads* like a one-way door and is
not one in the spine. It is `N` at SA-8.8 and at SA-4.6, and this overlay may not
change that — see the containment rules.

The tension is real and worth stating. Update-set-only delivery determines whether
the work can ever be diffed, reviewed, or drift-checked, and years of it are
genuinely expensive to unwind.

The gate consequence used to read as a footnote about two checks. Gate
configuration v0.6 made it the largest fact in this document. Under the engine
contract, **update-set-only delivery is not a repository the gate reads poorly, it
is a set of input classes an engine cannot supply at all** — and a required check
whose input class is unsupported exits 4 rather than filing a finding. With no
repository, ten of the 16 checks blocking at G2 are unsupported, and seven of the
nine at G0. With a documentation repository carrying `decisions/` and nothing else,
it is three at G2 — the ones that have to read code. The detail is in §8; the
summary is that a shop delivering only update sets does not get a partial gate
result, it gets a configuration error.

So the overlay's position is a strong default — **source-controlled scoped
applications**, with update-set-only delivery recorded as a deviation — and the
observation that if this should be a one-way door, that is a spine change and
belongs upstream with the gate consequence as its evidence. That evidence is now
considerably stronger than it was when this section was written, and it is still
open item 1 rather than something legislated locally.

## 7. Build DNA translations

Core process rules in platform-native terms. Same defaults, same
deviation-by-ADR shape.

| Build DNA | ServiceNow |
|---|---|
| Adoption — Practitioner, Reader, Contributor, Maintainer | Same four floors, and the platform blurs the line the contract draws. **Changing code includes changing a flow, a business rule, or a configured out-of-box artifact**, so the Contributor floor applies to App Engine Studio work as it does to a scoped-app engineer: know the profile from `system.json`, read the customization ledger before you modify an artifact that is already on it, do not edit vendored files. The Maintainer's ledger is the customization ledger below plus the pin — and on this platform the pin has two halves, the vendored standard and the installed Store and spoke versions. |
| Adoption — the Practitioner floor | **The densest concentration of this role anywhere Causeway runs, and the platform has the least room for it.** A ServiceNow instance is surrounded by process owners, service desk leads, and HR, finance and facilities functional experts who know precisely what the system must get right and have never opened a repository. Two platform-specific ways to get this wrong. First, **the platform has native surfaces that look like field notes and are not**: an incident, a problem record, catalog item feedback, a demand record. Same rule as the open-items row below — **they are inputs, not entries.** A demand record becomes a field note when a practitioner is interviewed and states what they know; harvesting the queue into `domain/field-notes/` produces volume and captures nothing, because the thing worth having was never written down in the ticket. Second, **a note is a property of the application, not of the instance**, for the same reason the index and the profile are. **Declared gap:** update-set-only delivery has no repository, so it has no `START-HERE.md`, no `domain/field-notes/`, and no pull request for a practitioner to land in — the same missing surface that leaves five input classes unsuppliable in §8 and the index homeless in the row below. This overlay declares it rather than nominating a table to stand in. The browser issue form needs a repository too; what an update-set-only shop actually has is the interview, and a note written somewhere a person chose. That is worse and it is not nothing. |
| §2 Microservices by default, monolith by decision | **Scoped application by default, global scope by decision.** |
| §3 Vendor-agnostic adapter pattern | **A spoke is a vendor SDK.** Canonical schema from the domain, spoke behind an adapter, no spoke called from a business rule or flow step carrying domain logic. |
| §3 Pin upstream, never silently fork | Store apps, spokes and plugins arrive at a version; **record the installed version in the inventory `dependency-provenance` reads**, not in a wiki. **A modified out-of-box artifact is a fork**, whether or not anyone calls it one — the customization ledger row with its ADR is the declared fork §3 permits, and a skip record at upgrade is the undeclared one surfacing. The gap between pinned and current is measured here in family releases, and the instance upgrade cadence is set by the vendor, so it is a number someone owns rather than one they choose. |
| §4 Brownfield is the normal case | Maps directly, and the three states are the whole answer set — spine v0.8 removed `greenfield`, which was answering the lifecycle question §4 opens with rather than the composition question. A configured Store app is `wrapped`. An app inherited from an analyst who left is `unmanaged` until someone owns it. **`catalog-composed` means the Causeway catalog**, not the Service Catalog and not the Store. |
| §5 The registry is inside the boundary | The Store is a registry. So is every spoke publisher. So is npm, if a widget build exists. |
| §6 Definition of green | **ATF suite passing, Instance Scan clean, and zero unacknowledged skip records.** A build with failing ATF or an unread Instance Scan finding is red, whatever the demo looked like. |
| §6 The build and the test path reach nothing | Cannot be taken literally: ATF runs *on an instance*, so the test path reaches the instance under test by construction. The honest translation is **the merge-gating suite reaches nothing beyond that instance** — no live spoke, no vendor sandbox, no production integration; integration surfaces are mocked, which is what the `contract-tests` row in §8 already asks of ATF. Contract tests against a live spoke are legitimate, named, and kept out of the gate, exactly as core says. The local-cache clause applies in full to a widget or UI Builder npm build and has no equivalent for platform artifacts, because a Store install is not a build step. **Declared gap:** a scoped application has no offline build in §6's sense — the instance is the build environment — and this overlay says so rather than inventing one. |
| §7 One prompt, one commit | Applies to the app repository. Update-set-only delivery makes it unobservable — see §6. |
| §8 Exceptions register | Doubles as the **customization ledger**: one row per modified out-of-box artifact, each with an ADR and a revisit date. At upgrade, *what did we touch* already exists instead of being archaeology. |
| §8 Thin project files | The app's `CLAUDE.md` carries instance URLs per environment, scope name, table inventory with license class, integration endpoints, and its exceptions rows. Everything else is imported. |
| §8 The open-items index | **A separate register from the customization ledger, and merging them loses both.** A ledger row is a deviation somebody owns; an open item is a question an ADR declined to answer. The platform has two native surfaces that look like open items and are not — **skip records at upgrade and Instance Scan findings are inputs, not entries**: a finding becomes an index item only when an ADR reads it and leaves something open, and until then it belongs in the queue it came from. One platform-specific way to get this wrong: **the index is a property of the application, not of the instance.** Eleven inherited-row ADRs are identical across every app on an instance (open item 7), so an instance-wide index is a tempting economy, and it makes an item's status ambiguous the first time two apps disagree about it — the same error §9's row warns about for profiles, one register over. **Declared gap:** update-set-only delivery has no repository to keep `decisions/open-items.json` in, which is the same missing surface that leaves five input classes unsuppliable in §8, and this overlay declares it rather than nominating a table to stand in. **Relations are the only mechanism this overlay has for a finding about core.** The containment rules say an overlay may not change a row, a flag or a check, so when §10 concludes something about core the overlay can record it and nothing else — and three of its eight items said *the finding belongs upstream* while two of them had no upstream item to name. That is the platform-specific shape of the rule: on a platform whose overlay is forbidden from fixing what it finds, an `upstream_of` edge with a real target is the difference between a finding that is owned and one that is merely written down. Standard v1.11.0 opened gate configuration items 11 and 12 to be those targets. |
| §8 Declared gaps | This overlay is core's fourth named implementation of the rule and applies it three more times. **Every N/A in §8 is a verdict reached by reading, published with its reason**, never a platform exemption. The input-class map is a declared gap in bulk: update-set-only delivery leaves five classes unsuppliable and the answer is `unsupported`, not a manufactured artifact. And §9 step 3's *no ADR yet is acceptable, no row is not* is the same rule applied to the ledger — a modification with a row and no argument is a tracked gap; one with neither is an unknown one. |
| §9 Know which gate you are building under | Same three steps, same order: read `system.json`, derive the profile from `gate/profiles.json`, treat missing criticality as C1. The platform adds one thing to get wrong: **the profile is a property of the application, not of the instance or the tooling that built it.** App Engine Studio work does not land at G1 by being citizen development; it lands wherever tier × criticality put it, which §8 says once and step 2 of §9 warns about — this is the step where a utility script turns out to be C1. |
| §9 Producing a placement, when there is none to read | Core's fourth step routes to `skills/decision-spine/reference/placement.md`, and it translates without change — the four questions, the five escalators and the tier test are about consequence and inheritance, neither of which is platform-specific. What is platform-specific is **where the answers are found: the class tracks the table, not the interface.** A record producer with eleven fields that writes to a task table, `cmdb_ci`, or anything a flow downstream reads as authoritative has the reach and the detection profile of the records it writes, not of the form somebody filled in. The instance is full of small applications whose UI says C3 and whose target table says otherwise, and reading the interface is the single most reliable way to under-place work here. The tier test lands the same way: the CMDB is the catalog, and an app is Core when another app's controls are counted on the strength of its records — not when a lot of apps query it. **Declared gap:** update-set-only delivery has no `system.json` to carry `criticality_authority`, so the declaration lives wherever that app's ledger lives, and this overlay names the gap rather than nominating a table to hold it. |
| §10 The fun clause | Unchanged. Yes, in ITSM. Especially in ITSM. |

The customization ledger is the row that earns this table. Every ServiceNow shop
eventually discovers what it modified by reading skip records during an upgrade
window. A ledger written at the time of the change turns that from an archaeology
exercise into a list somebody already owns.

## 8. Gate mechanics

**Profiles are derived from tier × criticality, never chosen.** G1 is not "the
citizen-developer lane" by definition — it is where operational-tier C1/C2 work and
mission-tier C3 work land. Citizen development usually resolves there. It does not
get to.

| Profile | Concretely |
|---|---|
| **G0 · Sandbox** | Personal developer instance or a designated sandbox. No production data, no production integrations, and no path to production without re-deriving the profile. |
| **G1 · Tactical** | Where App Engine Studio work typically lands. Tactical Authorization recorded per the spine, with duration and revocation trigger. App in its own scope on a sub-production or fenced footprint. |
| **G2 · Mission** | Full class-scoped spine closed. Source-controlled scoped app, ATF coverage on business rules and flows, Instance Scan clean, exceptions register current. |
| **G3 · Core** | G2 plus what is owed to other people's systems. Applies to work touching platform core, shared ITSM flows, or the CMDB schema — which at this tier is most of what matters. |

**Promote-or-sunset** is unchanged and is narrower than it is usually described: it
fires at **operational tier and C1 only**, on `renewal_count` in the TA record. Two
terms warn, the third blocks without a recorded disposition. Sunset is a legitimate
disposition and is often the right one for a tactical app that did its job.

That mechanism is the answer to the platform's signature disease — the app an
analyst built in an afternoon that the mission now depends on. It either graduates,
with its doors closed retroactively and on the record, or it dies on a scheduled
date. **Quietly load-bearing stops being an available state.**

### Where each check finds its evidence

The table below is the curated subset — checks whose evidence is not obvious on
this platform, or where the obvious answer is wrong. **`servicenow.json` carries a
platform evidence statement for all 27**, with the input classes each one reads,
so an engine integrator does not have to infer the other sixteen from silence.
`validate.py` fails the build if the JSON and `checks.json` disagree about what a
check reads.

| Check | Reads, on ServiceNow |
|---|---|
| `secrets-scan` | Script includes, business rules, and system properties. Credential aliases are the correct answer; a password in a property is the failure this catches. |
| `dependency-provenance` | Store app and spoke inventory with pinned versions. Plus the lockfile for any widget or UI Builder build. |
| `install-scripts` | N/A for platform artifacts — nothing executes on install. Applies in full to a widget build's npm install. **N/A is a verdict reached by reading**, not a platform exemption — see below. |
| `sbom-drift` | Application version manifest plus the spoke inventory. |
| `tests-with-source` | The app repository's changed-file set, with ATF definitions as the test partition. **Under update-set-only delivery the `repo-changeset` class cannot be supplied at all** — see below and §6. |
| `contract-tests` | ATF suites covering integration surfaces, with mocked endpoints. |
| `composition-state` | `system.json`, as everywhere. The values are `catalog-composed`, `wrapped`, `unmanaged` — spine v0.8, ADR 0008. A configured Store app is `wrapped`; **the Store is a registry, not the catalog this check means**, and neither is the Service Catalog. Engine contract 2 as of standard 1.6.0: an engine still reporting contract 1 is reading the pre-1.6.0 answer set. |
| `standard-currency` | `released=` in the app repository's `.causeway-lock`. Two different failures worth telling apart: no repository at all means the `repo-lock` class is unsupported, and since this check only ever warns, that files a finding rather than blocking. A lock that exists *without* `released=` is a configuration error — exit 4 — and re-syncing writes the line. |
| `shortform-closure`, `oneway-closure`, `class-scoped-closure` | `decisions/` in the app repository — **including the inherited-row ADRs**. This is where a register that skipped its `I` rows fails. |
| `ao-signature-sa510` | The ADR, not the instance. The platform models service ownership; it does not model an AO. |

### `release_state` on a platform that does not tag

`oneway-closure` and `tests-with-source` both read `release_state`, and gate
configuration §4 derives it from annotated tags matching `^v?[0-9]+\.[0-9]+\.[0-9]+`
in the product repository. A ServiceNow shop that reached source control at all did
so for diffs and reviews, and versions its applications through the platform's own
application version field — which no engine can see from git. **The default here is
`pre_release`, permanently, and it is the default by construction rather than by
oversight.**

Core already names this bypass and holds it acceptable while the set of untagged
G2/G3 systems stays small, adding that if the set turns out not to be small the
marker is wrong for both checks. This overlay's contribution is the evidence: on
this platform the set is not small, because nothing in the delivery path asks git
for a version. Two remedies, both cheap — tag the app repository at each published
application version, or set `spine.release_tag_pattern` in `ato-gate.json` to
whatever the shop actually writes. Pick one at adoption step 6, rather than finding
out after a year of green builds that the marker was inert.

**`oneway-closure` came off this list at gate configuration v0.8.** It never read
`release_state` to reach a verdict — the marker sat in its evidence and its blocking
column answered the spine's *before production code* deadline directly. ADR 0034
removed the declaration, so on this platform the check now runs on `repo-decisions`
and `system-record`: a source-controlled scoped app is evaluated against its ADR
register with no tags involved, and an update-set-only shop is blocked by the six
`repo-*` classes in the table above rather than by a seventh it never needed. What
reads `release_state` here is `tests-with-source`, and only that.

**Carried back and answered at gate configuration v0.7.** Core's item 8 took this
overlay's evidence, collected a second instance of its own, and replaced the marker:
`release_state` now reads ranked release evidence rather than annotated tags. Two of
the four sources are reachable from a source-controlled scoped app — a lightweight
tag now counts, which is what most shops' repositories actually carry — so the two
remedies above are no longer the only routes off `pre_release` and the first of them
got cheaper.

What did not close is the case this overlay actually described. An application
version field is not a git object of any kind, and core's fourth evidence source
names exactly that and has no input class behind it. Core open item 14 now carries
it, which is the first time this platform's version problem has had an upstream item
of its own rather than a sentence inside a marker's definition. **Declared gap:** on
an update-set-only shop, none of the four sources is reachable and the honest state
remains `pre_release` — unchanged by v0.7, and now visible as a missing input class
rather than as a marker that was wrong for everybody.

### What an engine must be able to read here

Gate configuration v0.6 publishes the engine contract. Each check in
`gate/checks.json` names the **input classes** it must be able to read; an engine
declares the classes it can supply; a required check whose class is unsupported
resolves to `unsupported`, exits `4`, and blocks. Not a finding — nothing was
evaluated, so nothing may be blessed.

That mechanic lands harder here than anywhere else the standard has been pointed.
Six of the fourteen classes are `repo-*`, and on this platform the artifacts are
rows in `sys_*` tables unless somebody decided otherwise. **On ServiceNow the
input-class handshake is a question about SA-8.8**, and most shops answered it the
day the first update set shipped.

| Input class | Source-controlled scoped app | Update-set-only delivery |
|---|---|---|
| `repo-decisions` | `decisions/` in the app repository | Only if a documentation repository exists. Frequently it does not. |
| `repo-tree` | App source — script includes, business rules, client scripts, widget code | **Nothing.** The artifacts are records, and no engine reads records as a working tree. |
| `repo-manifests` | The widget or UI Builder build's `package.json` and lockfile | **Nothing.** |
| `repo-changeset` | `git diff` against the base | **Nothing.** An update set is a payload, not a diff. |
| `repo-lock` | `.causeway-lock` in the app repository | **Nothing.** |
| `repo-git` | The app repository's annotated tags | **Nothing.** |
| `system-record` | The portfolio record. Not `cmdb_ci_service`, unless someone decided it was and wrote that down. | Same |
| `gate-config` | `ato-gate.json`, wherever the org keeps it | Same |
| `ta-record` | The Tactical Authorization record — see the G1 row above | Same |
| `catalog` | **The Causeway catalog.** Not the Service Catalog, not the Store. | Same |
| `evidence-store` | Emitted receipts | Same |
| `ci-results` | ATF results and Instance Scan findings — §7's definition of green | Same |
| `sbom`, `baseline` | Application version manifest plus the pinned spoke inventory | Same |

Three consequences, in ascending order of how much they cost.

**`not_applicable` is a verdict, not an exemption.** The `install-scripts` row
above says N/A for platform artifacts, and that remains true — but N/A is a verdict
an engine reaches *by reading manifests and finding no ecosystem with install-time
execution*. An engine that cannot supply `repo-manifests` does not get to conclude
N/A. It reports `unsupported`, and because both `install-scripts` and
`dependency-provenance` block at every profile, the run exits 4. The platform not
having a thing is not the same as the gate having confirmed it.

**Exit 4 outranks exit 3.** Gate configuration v0.6 fixes the precedence at
`4 › 3 › 2 › 1 › 0`. A tactical app whose TA has lapsed *and* whose engine cannot
read a repository reports the configuration error, not the promote-or-sunset block.
The governance conversation this platform most needs to have is the one that gets
hidden by an unreadable engine.

**An instance-only engine blocks at G0.** Ten of the 27 checks read no `repo-*`
class at all. Those ten are executable against the portfolio record, the TA record,
the catalog and the evidence store — and they are not enough at any profile:

| Profile | Blocking checks | Of those, needing a `repo-*` class |
|---|---|---|
| G0 · Sandbox | 9 | 7 |
| G1 · Tactical | 14 | 9 |
| G2 · Mission | 16 | 10 |
| G3 · Core | 20 | 12 |

An engine that reads the instance and the portfolio record but no repository is
not partway to running Causeway on ServiceNow. It is exit 4 at every profile,
starting with the sandbox.

The half-measure is worth naming because it is what a shop will reach for first. A
documentation-only repository — `decisions/`, the vendored standard, its
`.causeway-lock` — supplies `repo-decisions`, `repo-lock` and `repo-git`, which
leaves three of the G2 blockers unsupported rather than ten: `secrets-scan`,
`dependency-provenance` and `install-scripts`, all of which need to read code.
That is real progress and it is also where the trap is. Point an engine's
`repo-tree` at that repository and `secrets-scan` passes, having scanned a tree
with no application in it; let it read that repository's tags and `release_state`
describes the documentation's lifecycle rather than the app's. **An input class
supplied from the wrong tree is worse than one that is missing**, because missing
blocks and wrong reports green. If the app's source is not in the repository, do
not declare the classes that read source.

## 9. Adopting this on a shop that already has production sprawl

Order matters. Step 4 is what makes the rest survivable.

1. **Inventory.** Every scoped app, global customization, and modified out-of-box
   artifact currently in production. Instance Scan and the skip-record set do most
   of this for you, which is the one place the platform helps with governance.
2. **Declare.** The service owner assigns tier and criticality per app; gates
   derive. Expect surprises — this is the step where a utility script turns out to
   be C1.
3. **Backfill the ledger.** Every existing out-of-box modification becomes an
   exceptions-register row. No ADR yet is acceptable. **No row is not.**
4. **Grandfather through G1.** Anything landing at G2 or above that cannot meet it
   today enters a Tactical Authorization with an expiry. The promote-or-sunset
   clock starts now rather than someday. Skipping this step means step 5 arrives as
   a wall.
5. **Close doors going forward.** New work opens with the §6 rows closed before
   build.
6. **Check the engine can read you.** Compare the delivery model you actually have
   against the input-class map in §8, and get the engine's declared classes in
   writing. This costs an afternoon and it is the one step whose answer can
   invalidate the plan: an engine that cannot supply `repo-tree` on an
   update-set-only shop returns exit 4 at G0, and learning that during the first
   production release is the expensive way to learn it.
7. **Wire the definition of green.** ATF and Instance Scan in the pipeline, and
   `check-drift.sh` alongside them — `sync.sh` vendors the script itself as of
   standard 1.6.0, so it arrives with the rest rather than needing a clone of the
   standard to find. Re-sync anything whose `.causeway-lock` carries no `digest=`
   line; that lock predates 1.6.0 and an engine cannot say which bytes it evaluated
   against.

One thing to set expectations on before starting: **the inherited-row ADRs are the
cheapest part of this and they will feel like the most pointless.** Eleven rows,
four lines each, written once. Teams skip them, and then their register shows gaps
where the honest answer was available for free.

## 10. Open items

1. **Should SA-8.8 be one-way?** §6 makes the case and declines to act on it, because
   an overlay may not change a flag. The evidence a spine change would need got
   stronger in standard 1.6.0 and is now the strongest thing in this document: under
   the engine contract, update-set-only delivery costs an engine five input classes
   and usually a sixth, which takes out 10 of the 16 checks blocking at G2 and 7 of
   the 9 blocking at G0 — three at G2 even for a shop that keeps a documentation
   repository. The result is exit 4, configuration error, nothing evaluated, rather
   than a set of findings a team could work through. A row whose answer determines
   whether the gate can run at all has the shape of a one-way door, and the case is
   now arithmetic rather than argument.
2. **Instance-class dependency availability is asserted, not verified.** SA-4.7's
   note says plugin and spoke availability differs between commercial and
   government instances. That is true and this overlay does not carry the matrix,
   because the matrix is per-instance and dated. A team on a gov instance owes the
   verification, not this document.
3. **`tests-with-source` on this platform is untested.** Its promotion to blocking
   at G2/G3 behind the pre-release modifier was *decided* in standard v1.4.0 and has
   not engaged — it warns at all four profiles until one warn cycle on the v0.5
   definition completes. Whether an ATF definition file registers as a test file in a
   source-controlled scoped app is a question about the exclusion list, and nobody
   has run it against a real ServiceNow repository. When it does engage, the
   modifier that would soften it reads `release_state`, which §8 argues is stuck at
   `pre_release` on this platform — so the promotion may arrive and change nothing,
   which is a worse outcome than blocking. First adopter finds out; the finding
   belongs upstream.

   **Narrowed at overlay 1.11.** Gate configuration v0.7 made a lightweight tag
   count, so a source-controlled scoped app that tags its repository at all now
   leaves `pre_release` and the promotion would reach it. The concern survives
   unchanged for update-set-only delivery, where no source of release evidence is
   reachable — core open item 14. The question is now about a smaller set than it
   was, and it is still the first adopter who finds out.
4. **Now Assist is moving faster than this overlay.** SA-5.15 and SA-5.16 are
   dispositioned `P` and that will not change, but the platform's inference surface
   is being extended release over release. The rows are the right rows; the
   vocabulary in them will age.
5. **Nothing conformance-tests this platform's shape.** `conformance/` ships nine
   fixtures and every one of them is shaped like a conventional product repository
   — a package manifest, a lockfile or its deliberate absence — the shape the
   standard was written against. There is no fixture representing a ServiceNow
   system, and in particular none representing the case §8 says is the interesting
   one: a system whose engine cannot supply the `repo-*` classes. Until one exists,
   the exit-4 arithmetic above is derived from `checks.json` rather than observed.
   Building it is a core contribution, not an overlay one, and it needs one thing
   the format cannot currently express — **`expectations.json` has no way to say
   "the engine evaluating this fixture cannot supply class X"**, which is the whole
   point of the fixture. That is a conformance-schema decision and it deserves its
   own ADR rather than arriving as a side effect of an overlay revision.
6. **No engine has declared itself against this platform.** The first engine
   exists and the contract is one release old. Which input classes it supplies for a
   ServiceNow-shaped system is unknown to this document, and the honest reading of
   §8 is *here is what an engine would have to declare*, not *here is what one
   does*. First adopter finds out; the finding belongs upstream.
7. **The inherited-row ADRs are written once per project and should be written
   once.** §9 asks every adopting team to produce eleven short ADRs whose content is
   identical across every application on the same instance — the execution fabric,
   the instance pair, the HA/DR posture. That is the right answer under today's
   mechanics and an obviously wasteful one. What would fix it is a **centrally
   inheritable platform baseline**: an instance-level artifact the catalog knows
   about, which a project inherits and `inheritance-resolves` follows to a provider,
   leaving the project to record only its deviations. It is not an overlay change —
   it touches the catalog, the inheritance graph and probably `shortform-closure` —
   and it is the single largest cost reduction available to a shop adopting this on
   more than three applications.
8. **Platform-impact escalation is described, not derived.** The G3 row says the
   profile applies to work touching platform core, shared ITSM flows or the CMDB
   schema, and that sentence is doing work a rule should do. Profiles derive from
   tier × criticality and are never chosen, so *this change touches the CMDB, it
   escalates* has nowhere to live in the current resolution matrix — it is a
   property of a change rather than of a system. Either it becomes a modifier with
   a stated input class, or it stays advice and this overlay should say plainly
   that it is advice. Recorded rather than decided, because inventing a
   change-scoped escalation locally is exactly the fork the containment rules
   exist to prevent.

---

*Causeway core governs. This overlay relocates it into ServiceNow's native
mechanics and changes nothing about what is owed. Where this document and core
conflict, core wins and the conflict is a defect here — file it.*
