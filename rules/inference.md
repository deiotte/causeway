---
description: Inference boundary — tool surface and pre-inference data handling
globs: ["**/tools/**", "**/tool_defs/**", "**/*_tool.*", "**/*_tools.*", "**/mcp/**", "**/agents/**", "**/prompts/**", "**/llm/**", "**/inference/**"]
---

# Inference boundary

A model provider you do not run sits outside the authorization boundary (Spine
SA-5.10) and holds logs you cannot read, retain, or purge. Everything below
follows from that one fact. If this system has no inference path, both rows close
`No inference path` and none of this applies.

## The tool surface

The posture for this system is recorded under Spine SA-5.15. Read it before
adding a tool.

- **Task-specific tools, not a generalized interface.**
  `get_order_status(order_id)` is a tool. `run_sql(query)` is a database session
  with a language model holding the credentials.
- **Typed parameters, and nothing that reconstitutes a query language.** An
  `order_id` is a string with a shape you can validate. A `where_clause`, a
  `filter_expression`, a `path`, or a `command` is the generalized interface
  wearing a costume.
- **Every prompt is untrusted input.** Text arriving from a user, a document, a
  webhook, or an upstream system reaches the model, and the model calls the
  tools. Design as if the caller is hostile, because sometimes the caller is a
  paragraph inside a PDF.
- **Least privilege per tool, enforced below the tool.** The credential a tool
  holds is scoped to what that tool does, and authorization is checked at the
  same enforcement point as any other caller (Spine SA-5.2). Being invoked by a
  model is not a role.
- **The tool is the validation boundary.** Check arguments inside the tool
  against the same rules a hand-written endpoint would apply. A parameter is not
  safe because a model produced it.
- **Writes are narrower than reads.** A tool that changes state names the entity
  and the transition. If it takes a payload the model composed freely, it is a
  generalized interface with better manners.
- **A generalized interface is an owned exception**, in the §2 sense. Ad-hoc
  analytics over a read replica is the honest case for one. It closes under
  SA-5.15 with the boundary named: read-only credential, separate replica, no
  PII in scope, statement timeout, query log retained.

## Before the call

The posture for this system is recorded under Spine SA-5.16. It is a one-way
door and it carries a named approver — the data owner, not the delivery team.

- **Redact before inference, never after.** A filter on the response does nothing
  about what is already in the provider's logs. This is the whole row: the
  control has to sit upstream of the call or it is not a control.
- **Strip or tokenize PII and CUI at the call site** per the field-level
  treatment table (Spine SA-2.12). If the model needs to refer to a person, it
  refers to a token you resolve on the way back.
- **Everything assembled into context is a data flow.** A retrieved document, a
  pasted email thread, a database row, a stack trace, and a system prompt all
  cross the boundary exactly the way a request body does. Whatever governs them
  elsewhere governs them here.
- **Never send secrets.** Not in a prompt, not in a system message, not in a tool
  result, not in an error the model is shown. Same rule as everywhere else
  (`rules/secrets.md`), same scan.
- **Log what left, not only what came back.** An incident starts with *what
  crossed the boundary, and when*. If reconstructing that takes a week, the
  disclosure timeline is already blown.
- **Failing closed is the default.** If redaction cannot run — the classifier is
  down, the field is unrecognized, the schema changed — the call does not go.
  Degrading to "send it unredacted" turns an outage into a spill.

<!-- Eyebrow-raisers live here. Closure of SA-5.15 and SA-5.16 is verified by the
     spine-closure checks in CI; see gate/gate-configuration.md §4. -->
