# Managed policy — what a project records, and how it finds it

Build DNA's layering puts **managed policy** above everything else:

```
managed policy          non-negotiable org floor (ATO/CSfC, secrets handling)
  └── AGENTS.md         the portable Build DNA core
        └── CLAUDE.md   per project
```

Specific wins everywhere else in that diagram. Managed policy is the exception: it is
never overridden by the standard or by the project. This document says what a project
has to write down for that rule to mean anything. ADR 0050.

**Causeway does not supply the policy and cannot.** It belongs to the organization that
adopts the standard: its security office, its authorizing official, its records and
legal obligations. Causeway defines the *reference* a project keeps to that policy, so
that an engineer, an agent and an evaluator can all find the same policy, at the same
version, and tell an obligation from a preference.

---

## Three kinds of requirement, and where each one lives

A project meets requirements from three places. Mixing them up is how a team "fixes" a
customer obligation or relaxes an organizational one without knowing it.

| Kind | Who owns it | Who can grant an exception | Where the project records it |
|---|---|---|---|
| **Managed policy** — the organization's own floor | The policy authority (a CISO's office, an AO, records management) | **Only** the authority the policy names for exceptions | `.causeway/policy.json`, below |
| **Customer constraint** — a contract clause, an ATO boundary, a customer's environment | The customer | The customer, in writing | A Survey `GR-` row with its Source (`templates/survey.md` S1) |
| **Project default** — Causeway's defaults and the project's own choices | The project | The project, by ADR | `CLAUDE.md`, ADRs, the exceptions register |

The test for which one you have: **who would have to sign to change it?** If the project
can change it by writing an ADR, it is a project default. If only the customer can, it is
a customer constraint. If only someone in your own organization outside the project can,
it is managed policy.

A customer's policy that your organization adopts as its own becomes managed policy.
Until then it is a customer constraint, even if it reads like a policy.

---

## The policy reference

A project records its managed policy in **`.causeway/policy.json`**. The template is
`templates/managed-policy.json`. The file is the project's: it is not vendored, not in the
lock, and nothing re-seeds it.

```json
{
  "format": "causeway-managed-policy-v1",
  "policies": [
    {
      "id": "acme-secops-baseline",
      "title": "ACME Security Operations Baseline",
      "authority": { "name": "ACME Office of the CISO", "contact": "policy@acme.example" },
      "version": "4.2",
      "effective": "2026-07-01",
      "review_by": "2027-07-01",
      "applies_because": "The system processes CUI inside the ACME enclave.",
      "precedence": 1,
      "source": "https://policy.acme.example/secops/4.2",
      "copy": "policy/acme-secops-baseline-4.2.pdf",
      "sha256": "<sha256 of the copy>",
      "exception_authority": { "name": "J. Rivera", "role": "Authorizing Official" }
    }
  ],
  "exceptions": [],
  "none": null
}
```

| Field | What it records | Why |
|---|---|---|
| `id`, `title`, `version` | Which policy, at which version | A policy with no version cannot be pinned, so nobody can say which text the project was built against |
| `authority` | Who issues it, and how to reach them | The policy authority is not the project, and the reference has to say who it is |
| `effective`, `review_by` | When this version took effect; when the project must check for a newer one | A pin nobody revisits is a pin to an old policy |
| `applies_because` | Why this policy binds this system | Applicability is the first thing an assessor asks, and the answer is usually one sentence |
| `precedence` | Where it ranks among this project's managed policies (1 is highest) | Only matters when two of them disagree. Every managed policy ranks above Causeway and the project regardless |
| `source` | Where the authoritative text lives online | The place to check for a newer version |
| `copy`, `sha256` | A copy committed in the repository, and its hash | The pin. A copy in the repository is readable offline and in an enclave, and the hash says it is the version recorded |
| `exception_authority` | The person, by name and role, who can approve an exception to this policy | Build DNA §8: a role is not a name |

**Offline, or not committable.** A project that builds with no network (Build DNA §6)
reads the committed `copy`. A policy that may not be committed — classified, licensed,
too large — sets `copy` to `null`, keeps `sha256` of the copy it holds, and adds `held_at`
saying where that copy lives. That pin can be recorded, and it cannot be verified from
the repository; doctor reports it `unverified`, never `ok`.

**No managed policy.** A project with none records that, with the reason, in place of an
empty file:

```json
{ "format": "causeway-managed-policy-v1", "policies": [], "exceptions": [],
  "none": "Personal research project; no organization's policy applies." }
```

Silence and "none" are different claims. Silence means nobody checked.

---

## When requirements conflict

**Managed policy against Causeway.** The policy wins, always, with no exception request
needed. The project records the deviation from *Causeway* like any other: an ADR, and a
row in `CLAUDE.md`'s exceptions register, citing the policy `id`, version and clause. The
project owns that record because the deviation is from the standard, which the project
can deviate from.

**The project against managed policy.** The project cannot grant itself this. Only the
policy's `exception_authority` can. An exception is recorded in `exceptions`:

```json
{
  "policy": "acme-secops-baseline",
  "clause": "§3.4 — MFA on every service account",
  "adr": "0012",
  "approved_by": { "name": "J. Rivera", "role": "Authorizing Official" },
  "approved_on": "2026-09-01",
  "expires": "2027-03-01",
  "evidence": "https://grc.acme.example/exceptions/1187"
}
```

It needs the ADR that argues it, the approver by name and role, the date, an expiry, and
a link to where the approval itself lives. That link is usually the organization's GRC
or ticketing system, because the approval is the authority's record, not the project's.
An exception with no expiry is a permanent change to the policy made by the wrong
person. Build DNA §8 already refuses open-ended waivers, and this is the same rule one
tier up.

**Customer constraint against managed policy.** Neither side can resolve it alone. The
project records both, opens an `OPEN-` row in the Survey naming both authorities, and
builds nothing that depends on the answer until one of them changes. Causeway takes no
side.

**Two managed policies against each other.** `precedence` says which the project follows
while the authorities resolve it, and the project records the conflict in an ADR naming
both. `precedence` describes the project's reading; it does not overrule either authority.

---

## A worked example

Lantern is a mission-tier service that ACME builds for a federal customer.

| Requirement | Kind | Recorded |
|---|---|---|
| "Every service account uses MFA" — ACME SecOps Baseline 4.2 §3.4 | Managed policy | `.causeway/policy.json`, `acme-secops-baseline`, pinned to the committed copy |
| "Data stays in the customer's GovCloud tenant" — contract clause H.12 | Customer constraint | Survey `GR-1`, Source: contract H.12 |
| "Services by default; deviate with an ADR" — Build DNA §2 | Project default | Causeway. Lantern runs as a modular monolith under ADR 0004, listed in the exceptions register |
| "Use Go for new services" — Lantern's own choice | Project default | ADR 0002 |

The batch importer's service account cannot use MFA, because the customer's scheduler
cannot present a second factor. That is a request against managed policy, so Lantern
cannot approve it. The AO named as the policy's `exception_authority` approves a
six-month exception, recorded with its GRC link. ADR 0012 argues the compensating
control. When the exception expires, `tools/doctor.sh` reports it, and the choice is
renew, or fix the scheduler.

The monolith is a deviation from Causeway, which Lantern owns. Its ADR is enough.
GovCloud is the customer's, and moving it would need the customer.

---

## What a tool can check, and what it cannot

`tools/doctor.sh` reads `.causeway/policy.json` and reports, advisory as everything it
reports:

| Checked | Not checked — guidance only |
|---|---|
| The file exists and is the documented format, or records `none` with a reason | Whether the policy applies, or whether "none" is true |
| Each policy has id, title, version, authority, effective date, review date, applicability and an exception authority with name and role | Whether the authority is the right one |
| The committed copy exists and matches its `sha256`; a held copy is `unverified` | Whether the copy is the authority's current version — `review_by` exists for that |
| `review_by` is not past | Whether the project complies with the policy's content |
| Each exception names its policy, clause, ADR, approver and evidence, the approver's role matches the policy's exception authority, the ADR exists, and it has not expired | Whether the approver actually approved it. A name in a file is a recorded assertion, not an authentication |

A gate evaluator may read the same file. No gate check does today. Making one block is a
gate configuration decision with its own warn cycle, as for every other check.
