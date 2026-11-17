# Build DNA — §6 Testable, reliable, observable

> **The argument, not the rule.** This file is part of Build DNA 2.0. The rules an
> agent loads every session are the numbered card in `AGENTS.md`; this file is the
> reasoning, history and worked examples behind them, read when a task touches the
> section. If the two ever disagree, that is a bug: the card says what is required,
> and this file says why. ADR 0061.

## 6. Testable, reliable, observable

The bar, stated as things that are true before "done":

- **Testable** — new or changed behavior ships with tests, including the unhappy
  paths (401/403/422/timeout). Green before handoff, not after review.
- **Reliable** — failure modes are designed, not discovered. Circuit breakers,
  bounded queues, defined degradation.
- **Observable** — structured logs carrying trace and span IDs, metrics on the
  golden signals, traces across service boundaries. A system nobody can see
  inside of is not finished.

### The build and the test path reach nothing

Air-gapped delivery is treated everywhere else in this document as a property of
the *target* — SA-4.7 asks which managed services exist in the enclave, §5 lets
IL5 and IL6 settle the registry argument outright. It is also a property of the
**build**, and that half has been assumed rather than stated.

- **The test suite makes no network calls.** Not to a registry, not to a vendor
  sandbox, not to a public API that is *usually* up. A test that reaches the
  network tests the network, and it fails on the day you most need a green
  build. External behavior is a fake behind the §3 adapter boundary; that seam
  already exists, and this is most of what it is for.
- **Dependencies resolve from a local, populated cache.** A build that needs the
  internet is a build that does not run in the enclave it ships to. Discovering
  that during accreditation is discovering it late.
- **The offline path is the one that runs in CI**, not a documented fallback
  nobody exercises. A degraded mode that is never the default has not been
  tested; it has been described.
- **Contract tests against a live upstream are legitimate and separate.** Run
  them, name them, keep them out of the path that gates a merge. Something real
  has to talk to the vendor eventually — it just is not the suite that decides
  whether this commit lands.

The reason this belongs here rather than in a deployment guide: it stops being
achievable the moment it stops being cheap. Retrofitting an offline build onto a
suite with three hundred incidental network calls is a project. Never letting the
first one in is a rule.

### Configure, set up, run — one page, not a file hunt

"Copy `.env.example` to `.env` and edit it" is an instruction, and the person
holding it is the one least equipped to follow it: they have not read the
codebase, they do not know which of thirty values matter, and the README that
tells them to rotate the dev secrets does not say how. The result is a
hand-edited file that is wrong in a way nothing reports, on a machine the author
of the README never saw. Configuration is a function of the build — configure,
set up, run — and it gets the same treatment as a test: it is a thing the project
does, not a thing the project describes.

- **`.env.example` is the configuration contract, and it is the only one.** Every
  value the stack consumes is in it, grouped under `# --- Title ---` headers,
  with a comment that says what it is for. A value that is not there does not
  exist. A second list of the same variables, in a wizard, a wiki or a script,
  is a fork of the contract, and §3 says what happens to forks.
- **The first run opens a page built from that file.** `make setup` — and `make
  up` on a machine with no `.env` — serves a local form on the loopback address,
  one field per variable, grouped and explained the way the example already is.
  Secrets are generated, not pasted from a README. Save writes `.env`. The same
  page runs the project's documented `make` targets and shows the stack coming
  up. Add a variable to the example and it appears on the page; there is no
  second place to maintain. `tools/setup/` is vendored for this, and reads
  nothing but `.env.example`, `.env` and the Makefile.
- **Stale state is named before it bites.** A database keeps the password it was
  created with, and so does an identity realm imported on first boot. A fresh
  `.env` against volumes from an earlier run fails at the first service that
  logs in, with nothing on screen to say why. The page says why, before Save,
  and offers the clean. The project's `clean` target deletes every volume of the
  compose project, overlays included; `down -v` on the base file alone does not.
- **A setup path that cannot be followed is a bug, not a user error.** Launched
  as root, the browser must not be; written as root, the file must still belong
  to the person who typed the command; run over SSH, the URL is what gets
  printed. Each of these was found by a person running the project the way a
  person does, and each is now a rule with a test behind it.

What this is not: a secrets manager, a remote console, or a deployment tool. It
writes one gitignored file on one disk and runs the targets a person would have
typed. In CI there is no terminal, so there is no page; the example is copied
and the build is unchanged. ADR 0052 records the decision and names the first
adopter, whose four field reports are the four rules above.
