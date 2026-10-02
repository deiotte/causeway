#!/usr/bin/env bash
# verify-release.sh — verify that this copy of the standard is a signed release.
#
#   ./tools/verify-release.sh [--statement F] [--signature F]
#                             [--allowed-signers F] [--lock F]
#
# Run from a consuming project root, or from a checkout of the standard. Answers
# the one question check-drift.sh cannot: not "has this copy been touched" but
# "did the people who publish this standard attest these exact bytes".
#
# Offline by construction. No network, no keyring, no transparency log, no
# clone — one file of trusted public keys and two files that travel with the
# release. That is the property an air-gapped or egress-restricted consumer
# needs, and it is why this is SSH signing rather than a log-backed scheme.
#
# Exit 0 verified · 5 no signature material · 8 verification failed.
set -uo pipefail

STATEMENT="bundle/release.statement"
SIGNATURE=""
ALLOWED="bundle/allowed-signers"
LOCK=".causeway-lock"
NAMESPACE="causeway-release"

while [ $# -gt 0 ]; do
  case "$1" in
    --statement)       STATEMENT="${2:?}"; shift 2 ;;
    --statement=*)     STATEMENT="${1#*=}"; shift ;;
    --signature)       SIGNATURE="${2:?}"; shift 2 ;;
    --signature=*)     SIGNATURE="${1#*=}"; shift ;;
    --allowed-signers) ALLOWED="${2:?}"; shift 2 ;;
    --allowed-signers=*) ALLOWED="${1#*=}"; shift ;;
    --lock)            LOCK="${2:?}"; shift 2 ;;
    --lock=*)          LOCK="${1#*=}"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
[ -n "$SIGNATURE" ] || SIGNATURE="$STATEMENT.sig"

command -v ssh-keygen >/dev/null 2>&1 || {
  echo "ssh-keygen not found — install openssh-client" >&2; exit 5; }

# Absence is reported precisely rather than as a generic failure. A consumer
# that has not fetched the signature material is in a different position from
# one whose signature does not verify, and telling them apart is the difference
# between "go and get it" and "do not ship this".
missing=""
for f in "$STATEMENT" "$SIGNATURE" "$ALLOWED"; do
  [ -f "$f" ] || missing="$missing $f"
done
if [ -n "$missing" ]; then
  echo "no signature to verify — missing:$missing"
  echo ""
  echo "The statement and its .sig are published as assets on each GitHub"
  echo "release; bundle/allowed-signers travels with the standard and is"
  echo "covered by the bundle digest. Fetch the two release assets into"
  echo "bundle/ and run this again."
  exit 5
fi

# A trust anchor with no keys in it would make every verification below vacuous
# while looking like it passed.
KEYS="$(grep -cE '^[^#[:space:]]+[[:space:]]+(ssh|sk-ssh|sk-ecdsa|ecdsa)' "$ALLOWED" || true)"
if [ "$KEYS" -eq 0 ]; then
  echo "  $ALLOWED contains no usable keys — nothing would be trusted"
  exit 8
fi

# find-principals asks the allowed-signers file which identity, if any, made
# this signature. Looping over principals and trying each would report the last
# failure rather than the real one, and would accept a signature from any key in
# the file without ever naming which.
PRINCIPAL="$(ssh-keygen -Y find-principals -s "$SIGNATURE" -f "$ALLOWED" 2>/dev/null | head -1)"
if [ -z "$PRINCIPAL" ]; then
  echo "  signature was not made by any key in $ALLOWED"
  echo "  ($KEYS key(s) trusted)"
  exit 8
fi

if ! ssh-keygen -Y verify -f "$ALLOWED" -I "$PRINCIPAL" -n "$NAMESPACE" \
      -s "$SIGNATURE" < "$STATEMENT" >/dev/null 2>&1; then
  echo "  signature does not verify against $STATEMENT"
  echo "  signer $PRINCIPAL, namespace $NAMESPACE"
  exit 8
fi

# The signature proves the statement is authentic. It says nothing yet about
# whether the statement describes THIS copy — a valid signature over some other
# release verifies just as well, and pairing a real signature with the wrong
# content is the substitution this section exists to catch.
FMT="$(head -1 "$STATEMENT")"
if [ "$FMT" != "causeway-release-v1" ]; then
  echo "  unrecognised statement format: $FMT"
  exit 8
fi

field() { sed -n "s/^$1=//p" "$STATEMENT" | head -1; }
S_VERSION="$(field version)"
S_DIGEST="$(field digest)"
S_TAG="$(field tag)"
S_COMMIT="$(field commit)"

echo "signed release $S_TAG — v$S_VERSION"
echo "  signer  $PRINCIPAL"
echo "  digest  $S_DIGEST"
echo "  commit  $S_COMMIT"

FAILED=0

# Against the manifest, when this is a checkout or a synced project.
if [ -f "bundle/manifest.json" ]; then
  M_DIGEST="$(sed -n 's/.*"digest"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    bundle/manifest.json | head -1)"
  if [ "$M_DIGEST" != "$S_DIGEST" ]; then
    echo "  MISMATCH  bundle/manifest.json digest $M_DIGEST"
    FAILED=1
  else
    echo "  manifest agrees"
  fi
fi

# Against the lock, when this is a consuming project.
if [ -f "$LOCK" ]; then
  L_DIGEST="$(grep '^digest=' "$LOCK" | cut -d= -f2- || true)"
  L_TAG="$(grep '^tag=' "$LOCK" | cut -d= -f2- || true)"
  if [ -n "$L_DIGEST" ] && [ "$L_DIGEST" != "$S_DIGEST" ]; then
    echo "  MISMATCH  $LOCK digest $L_DIGEST"
    FAILED=1
  elif [ -n "$L_DIGEST" ]; then
    echo "  lock agrees"
  fi
  # A lock with no tag was not synced from a release, so a release signature
  # cannot be describing it however well it verifies.
  if [ -z "$L_TAG" ]; then
    echo "  note: $LOCK records no tag — this copy was not synced from a"
    echo "        published release, so this signature describes a release"
    echo "        this project is not actually pinned to."
    FAILED=1
  elif [ "$L_TAG" != "$S_TAG" ]; then
    echo "  MISMATCH  $LOCK pins $L_TAG, statement signs $S_TAG"
    FAILED=1
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  cat <<'MSG'

The signature is genuine but it does not describe this copy.

A valid signature over a different release verifies exactly as well as one over
this release. Check that the statement fetched alongside this project is the one
for the version in .causeway-lock, then re-run.
MSG
  exit 8
fi

echo "  verified"
