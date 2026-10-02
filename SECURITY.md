# Security policy

## Reporting a vulnerability

**Do not open a public issue.** Report it privately through GitHub: on this
repository's **Security** tab, choose **Report a vulnerability**. Only the
maintainer sees the report.

Include what you found, how to reproduce it, and which release or commit you
were looking at (`VERSION` and the `digest=` line of your `.causeway-lock` are
the fastest way to say that).

There is one maintainer. A report is acknowledged as soon as they see it, and the
aim is within seven days. A fix ships as a signed release; the advisory credits
you unless you ask it not to.

## What is in scope

Causeway is mostly text, but some of that text is code that runs on your machine
or in your CI, and some of it is a security control in its own right.

| In scope | Examples |
|---|---|
| The distribution path | `tools/sync.sh`, `tools/check-drift.sh`, `tools/verify-release.sh`, `tools/build-archive.sh` — anything that lets a tampered or downgraded copy install or pass a drift check |
| Release integrity | The signing workflow, `bundle/allowed-signers`, the release statement and its verification — anything that lets a forged release verify |
| The gate contract | A check in `gate/checks.json` whose specified behavior would pass a system it should block |
| The normative text | A rule in `AGENTS.md`, `rules/`, the spine or an overlay that, followed as written, produces an insecure system |

The last row is unusual and intentional. A standard whose advice is wrong is a
vulnerability in every system that follows it, so a report that a rule is unsafe
is a security report, not a style comment.

## What is not in scope

A product that adopted Causeway. Report a vulnerability in that product to the
people who build it. If the product is vulnerable *because* it followed this
standard, that part is in scope here, and we want to hear it.

## Supported versions

The latest release. Consuming projects pin exactly, so a fix reaches them when
they re-sync; `check-drift.sh` and the `standard-currency` check tell them a newer
release exists.
