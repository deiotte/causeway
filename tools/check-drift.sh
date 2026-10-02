#!/usr/bin/env bash
# check-drift.sh — fail the build if the vendored standard has been edited
# locally or has drifted from the pinned version.
#
# Run from the consuming project root. Exit 5 on drift.
set -uo pipefail

LOCK="${1:-.causeway-lock}"
[ -f "$LOCK" ] || { echo "no $LOCK — project has not been synced"; exit 5; }

VERSION="$(grep '^version=' "$LOCK" | cut -d= -f2)"
RELEASED="$(grep '^released=' "$LOCK" | cut -d= -f2 || true)"
DIGEST="$(grep '^digest=' "$LOCK" | cut -d= -f2- || true)"
TAG="$(grep '^tag=' "$LOCK" | cut -d= -f2- || true)"
PROOF="$(grep '^release_proof=' "$LOCK" | cut -d= -f2- || true)"

# Age is informational here. The gate decides what to do about it
# (standard-currency, gate-configuration.md §4) — this script only reports drift.
if [ -n "${RELEASED:-}" ] && AGE_S="$(date -d "$RELEASED" +%s 2>/dev/null)"; then
  AGE_DAYS=$(( ( $(date +%s) - AGE_S ) / 86400 ))
  echo "Causeway standard pinned at v$VERSION, released $RELEASED ($AGE_DAYS days ago)"
elif [ -z "${RELEASED:-}" ]; then
  echo "Causeway standard pinned at v$VERSION"
  echo "  note: no released= in $LOCK — lock predates standard v1.3.0."
  echo "        Re-run sync.sh so the gate can measure this copy's age."
else
  echo "Causeway standard pinned at v$VERSION, released $RELEASED"
fi

if [ -n "${TAG:-}" ]; then
  # Which evidence established the pin, not merely that one exists. A tag read
  # out of the publisher's own checkout and a signature verified against
  # bundle/allowed-signers are different claims, and a line that rendered them
  # identically would be flattening the more defensible one into the weaker.
  # Locks written before v1.14.0 carry no release_proof= and print as they
  # always did. See ADR 0030.
  case "${PROOF:-}" in
    signed-statement) echo "  release $TAG — pinned on a verified release signature" ;;
    git-tag)          echo "  release $TAG — pinned on a tag in the publisher's checkout" ;;
    *)                echo "  release $TAG" ;;
  esac
else
  # Not a failure. A project may legitimately track an unreleased commit while
  # a fix lands. It is reported because a lock with no tag cannot be told from a
  # release pin by looking, and the whole point of recording one is that the
  # absence should be visible too.
  echo "  note: no tag= in $LOCK — this copy was not synced from a published"
  echo "        release. Re-sync from a tagged checkout before shipping."
fi

if [ -n "${DIGEST:-}" ]; then
  echo "  bundle $DIGEST"
else
  echo "  note: no digest= in $LOCK — lock predates standard v1.6.0."
  echo "        Re-run sync.sh so the gate can verify this copy's provenance."
fi

FAILED=0
while read -r sum file; do
  # Header keys, not checksum lines. A key added to sync.sh and forgotten here
  # would be read as a checksum whose filename is empty, so tools/validate.sh
  # asserts the two lists agree.
  case "$sum" in version=*|released=*|digest=*|commit=*|tag=*|release_proof=*|synced=*|overlay=*) continue ;; esac
  [ -z "${file:-}" ] && continue
  if [ ! -f "$file" ]; then
    echo "  MISSING  $file"; FAILED=1; continue
  fi
  actual="$(sha256sum "$file" | cut -d' ' -f1)"
  if [ "$actual" != "$sum" ]; then
    echo "  DRIFTED  $file"; FAILED=1
  fi
done < "$LOCK"

if [ "$FAILED" -ne 0 ]; then
  cat <<'MSG'

The vendored standard differs from the pinned version.

If this was deliberate, it belongs upstream: open a PR against
causeway-standard, cut a new version, and re-sync. Local edits to a shared
standard are how the canonical copy goes missing.

If it was accidental, re-run sync.sh to restore.
MSG
  exit 5
fi

# ── Provenance: make the digest load-bearing ────────────────────────────────
#
# Until v1.8.0 this script printed `digest=` and never checked it. sync.sh read
# the digest out of bundle/manifest.json and copied it into the lock, and
# nothing ever recomputed it — so the one value that answers "is this copy ours"
# was decorative, while the per-file sums above answered only "has this copy
# been touched". The comment in sync.sh had said as much since v1.6.0.
#
# The digest is a sha256 over "<sum>  <path>" lines, sorted by path, one per
# bundle file. The manifest carries exactly those pairs, so the digest can be
# recomputed here — from the vendored manifest alone, with no network, no clone
# and no new dependency. That is what makes an offline signature over the digest
# worth verifying: without it, a signature would attest a number this end never
# derives for itself.
#
# What this proves and what it does not: recomputation catches a lock or a
# manifest edited by hand, a truncated file list, and any vendored file whose
# bytes no longer match what the manifest claims. It cannot catch a wholly
# self-consistent forgery, because anyone who can rewrite the files can also
# rewrite the manifest. Only the signature closes that, and only against the
# allowed-signers set. See tools/verify-release.sh.
MANIFEST="bundle/manifest.json"
PROV_FAILED=0

if [ ! -f "$MANIFEST" ]; then
  echo "  note: no $MANIFEST in this copy — cannot verify the digest, only"
  echo "        report it. Re-run sync.sh against v1.8.0 or later."
else
  # Deliberately coupled to build-bundle.sh's emit_manifest, which writes one
  # entry per line in a fixed shape. tools/validate.py asserts this sed parses
  # the committed manifest to exactly the same set a JSON parser does, so the
  # coupling fails loudly upstream rather than silently here.
  MAN_LINES="$(sed -n 's/^[[:space:]]*{ "path": "\([^"]*\)", "sha256": "\([^"]*\)" }.*$/\2  \1/p' \
    "$MANIFEST" | LC_ALL=C sort -k2)"
  MAN_DIGEST="$(sed -n 's/.*"digest"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST" | head -1)"

  # A parser that quietly yields nothing would make every check below vacuous.
  ENTRIES="$(grep -c '"path"' "$MANIFEST" || true)"
  PARSED="$(printf '%s' "$MAN_LINES" | grep -c . || true)"
  if [ "$ENTRIES" -eq 0 ] || [ "$PARSED" -ne "$ENTRIES" ]; then
    echo "  MANIFEST  unparseable: $ENTRIES entries, $PARSED parsed"
    PROV_FAILED=1
  else
    CALC="sha256:$(printf '%s\n' "$MAN_LINES" | sha256sum | cut -d' ' -f1)"
    if [ "$CALC" != "$MAN_DIGEST" ]; then
      echo "  MANIFEST  digest does not match its own file list"
      echo "            claims   $MAN_DIGEST"
      echo "            computes $CALC"
      PROV_FAILED=1
    fi
    if [ -n "${DIGEST:-}" ] && [ "$DIGEST" != "$MAN_DIGEST" ]; then
      echo "  MANIFEST  lock digest does not match the vendored manifest"
      echo "            lock     $DIGEST"
      echo "            manifest $MAN_DIGEST"
      PROV_FAILED=1
    fi

    # Every bundle file this copy actually has must hash to what the manifest
    # says. A project vendors a subset — no VERSION or RELEASED, and only the
    # overlays it opted into — so absence is normal and is counted, not ignored.
    CHECKED=0
    ABSENT=""
    while read -r sum path; do
      [ -z "${path:-}" ] && continue
      if [ -f "$path" ]; then
        actual="$(sha256sum "$path" | cut -d' ' -f1)"
        if [ "$actual" != "$sum" ]; then
          echo "  FORGED   $path does not match the manifest"
          PROV_FAILED=1
        fi
        CHECKED=$((CHECKED + 1))
      else
        # VERSION and RELEASED are never vendored, but the lock carries their
        # exact contents in its own header, so they can be rebuilt and checked
        # rather than written off. Two files is the whole gap and closing it
        # means the digest is verified against every byte it covers.
        rebuilt=""
        case "$path" in
          VERSION)  [ -n "${VERSION:-}" ]  && rebuilt="$VERSION" ;;
          RELEASED) [ -n "${RELEASED:-}" ] && rebuilt="$RELEASED" ;;
        esac
        if [ -n "$rebuilt" ]; then
          actual="$(printf '%s\n' "$rebuilt" | sha256sum | cut -d' ' -f1)"
          if [ "$actual" != "$sum" ]; then
            echo "  FORGED   $path (rebuilt from the lock) does not match the manifest"
            PROV_FAILED=1
          fi
          CHECKED=$((CHECKED + 1))
        else
          ABSENT="$ABSENT $path"
        fi
      fi
    done <<EOF
$MAN_LINES
EOF

    if [ "$PROV_FAILED" -eq 0 ]; then
      echo "  digest verified — $CHECKED of $ENTRIES bundle files hash as published"
      [ -n "$ABSENT" ] && echo "  not vendored here:$ABSENT"
    fi
  fi
fi

if [ "$PROV_FAILED" -ne 0 ]; then
  cat <<'MSG'

The vendored copy is internally consistent but its provenance does not hold.

The per-file checksums in .causeway-lock agree with the files on disk, so
nothing was edited after the sync — but the bundle manifest does not describe
the bytes that are here, or the lock does not agree with the manifest. That is
not local drift. Either this copy did not come from a published release, or the
lock or manifest was rewritten.

Re-sync from a tagged checkout:
    ./tools/sync.sh /path/to/project --require-release

Then verify the release signature:
    ./tools/verify-release.sh
MSG
  exit 8
fi

# The signature material travels into the project from v1.14.0, so the next
# step is available rather than merely advisable. Saying so here is the whole
# difference between a consumer who verifies once at adoption and one who
# verifies on every build: the second only happens if something tells them it
# costs nothing.
if [ -f "bundle/release.statement" ] && [ -f "bundle/release.statement.sig" ]; then
  if [ "${PROOF:-}" != "signed-statement" ]; then
    echo "  signature material present — ./tools/verify-release.sh checks it offline"
  fi
elif [ -n "${TAG:-}" ]; then
  echo "  note: no bundle/release.statement in this project — verify-release.sh"
  echo "        has nothing to check. Re-sync from a published release archive,"
  echo "        which carries the statement and its signature inside it."
fi

echo "  no drift"
