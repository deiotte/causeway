---
description: Application security rules — input, authorization, output, errors, outbound calls
globs: ["src/**", "app/**", "lib/**", "**/api/**", "**/handlers/**", "**/routes/**", "**/controllers/**", "**/views/**", "**/templates/**", "**/middleware/**", "**/auth/**"]
---

# Security rules — application code

The checks that block live in CI: the secrets scan, dependency provenance, and,
advisory for now, known vulnerabilities and static analysis (`gate/checks.json`).
This file is what to hold yourself to before any of them runs. OWASP ASVS is the
fuller checklist; these are the items that go wrong most often in code an agent
writes quickly.

## Every input

- **Validate at the boundary, against an allowlist.** Type, length, range, format,
  and the set of values that are allowed. Rejecting what is unexpected is safer than
  stripping what is known to be bad.
- **Never build a query, command, path or template from a string.** Parameterized
  queries, argument arrays, a fixed base directory with the name checked against it,
  and templates that escape by default. Concatenation is the bug, whatever the input
  looked like in testing.
- **Uploaded files and parsed documents are input too.** Size limits, type checked by
  content and not by extension, and no deserializer that can instantiate arbitrary
  types.

## Every request

- **Authorization is checked on every request, at the enforcement point the system
  chose** (Spine SA-5.2), not in the UI and not only on the first page. A route with
  no check is a route anyone can call.
- **Check the object, not just the role.** "Signed in" and "is an editor" do not
  answer "may edit *this* record". Access to another user's record by changing an ID
  in the URL is the most common serious flaw in business applications.
- **Deny by default.** A new route, field or action starts closed.
- **Sessions and tokens**: short-lived, revocable, sent only over TLS, never in a URL.
  Cookies are `Secure`, `HttpOnly` and `SameSite`. State-changing requests are
  protected against cross-site request forgery.

## Every output

- **Encode for where the data lands**: HTML, attribute, JavaScript, URL, SQL, shell
  and log each have their own escaping. The framework's default escaping is the
  control; turning it off for one field is a review comment.
- **Errors tell the caller what to do, not how the system works.** No stack traces,
  query text, file paths or internal IDs in a response. Log the detail; return a
  correlation ID.
- **Logs never hold a secret, a token, a password or a full record** of personal
  data (Spine SA-6.8). "Log the request body to debug" is how they end up there.

## Every outbound call

- Timeout and retry with exponential backoff plus jitter.
- Idempotency key on anything a retry could double-fire.
- **A URL built from input is a request someone else chose.** Allowlist the hosts a
  server-side request may reach, or a caller can point it at internal services.
- Through an adapter behind the canonical interface only (AGENTS.md §3). No vendor
  SDK calls in handler code — that is how lock-in and untestable edges get in.

## Cryptography

- **Use the platform's or a well-known library's high-level API.** No hand-rolled
  crypto, no custom token formats, no ECB, no MD5 or SHA-1 for anything that matters.
- Passwords are hashed with a password hashing function (Argon2id, scrypt, bcrypt),
  never encrypted and never a plain hash.
- Randomness for anything security-relevant comes from the cryptographic generator,
  not the general-purpose one.

## Static analysis

- **Run an analyzer in CI and keep its results as SARIF**; the `static-analysis`
  check reads them (gate configuration §4).
- **Fix an error-level result, or suppress it with a reason a reviewer can read.** A
  suppression with no justification is counted as unresolved. Turning a rule off for
  the whole repository is a waiver and needs an ADR.

## Before "done" on a security-relevant change

- Ships with tests including unhappy paths (401 / 403 / 422 / timeout), and at least
  one test that tries the abuse the change defends against and fails. Where the
  Survey has a `TH-` row for it, that test is the row's evidence.
- API test suite green before handoff.
- If the change touches authentication, authorization, sessions, cryptography, file
  handling, or a trust boundary, say so in the pull request so it gets a reviewer
  who will read it for that.

<!-- Eyebrow-raisers live here. True merge-blockers (the scan, the control check) live in CI. -->
