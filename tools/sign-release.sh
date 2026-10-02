#!/usr/bin/env bash
# sign-release.sh — sign the bundle digest of a published release.
#
#   ./tools/sign-release.sh --key <private-key> [--out <dir>]
#
# Produces a release statement and a detached SSH signature over it. The
# statement binds four facts that are otherwise only correlated by trust in the
# forge: the version, the release date, the bundle digest, and the commit and
# tag the digest was built from.
#
# Why sign the statement rather than the manifest: the manifest is inside the
# bundle and the digest covers it, so a signature over the manifest would be a
# signature over a file that changes with every release for reasons the
# signature cannot express. The statement is small, human-readable, and says in
# one place what a verifier needs to decide whether a vendored copy is ours.
#
# Why SSH and not GPG: `ssh-keygen -Y verify` needs one file of trusted keys and
# no keyring, no agent, no network and no transparency log. The first program to
# consume this standard delivers from a government-owned Azure DevOps instance
# where reaching a public log service is not a safe assumption. See ADR 0019.
#
# This runs in CI on a tag. It is not expected to be run by hand, and it refuses
# to sign anything that is not a published release, because a signature over an
# arbitrary commit is exactly the ambiguity ADR 0015 removed from the lock.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$STANDARD_DIR"

KEY=""
OUT="bundle"
NAMESPACE="causeway-release"

while [ $# -gt 0 ]; do
  case "$1" in
    --key)   KEY="${2:?--key needs a path}"; shift 2 ;;
    --key=*) KEY="${1#*=}"; shift ;;
    --out)   OUT="${2:?--out needs a directory}"; shift 2 ;;
    --out=*) OUT="${1#*=}"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
: "${KEY:?usage: sign-release.sh --key <private-key> [--out <dir>]}"
[ -f "$KEY" ] || { echo "no such key: $KEY" >&2; exit 1; }

command -v ssh-keygen >/dev/null 2>&1 || {
  echo "ssh-keygen not found — install openssh-client" >&2; exit 1; }

VERSION="$(cat VERSION)"
RELEASED="$(cat RELEASED)"

DIGEST="$(sed -n 's/.*"digest"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  bundle/manifest.json | head -1)"
[ -n "$DIGEST" ] || { echo "bundle/manifest.json has no digest" >&2; exit 1; }

# The manifest must describe the tree as it stands right now. Signing a stale
# manifest would attest a digest for content that is not what this tag holds.
./tools/build-bundle.sh --check >/dev/null || {
  echo "refusing to sign: bundle/manifest.json is stale" >&2; exit 6; }

[ -z "$(git status --porcelain)" ] || {
  echo "refusing to sign: working tree is dirty" >&2; exit 7; }

COMMIT="$(git rev-parse HEAD)"
TAG="$(git describe --exact-match --tags HEAD 2>/dev/null || true)"
[ -n "$TAG" ] || {
  echo "refusing to sign: HEAD is not at a tag." >&2
  echo "  A signature over an untagged commit says a release exists where none does." >&2
  exit 7; }

mkdir -p "$OUT"
STATEMENT="$OUT/release.statement"

# Field order is fixed and the format is line-oriented, so the statement a
# verifier parses is byte-identical to the one that was signed.
{
  echo "causeway-release-v1"
  echo "version=$VERSION"
  echo "released=$RELEASED"
  echo "digest=$DIGEST"
  echo "commit=$COMMIT"
  echo "tag=$TAG"
} > "$STATEMENT"

# -n binds the signature to a namespace, so a signature made for some other
# purpose with the same key cannot be replayed as a release attestation.
ssh-keygen -Y sign -f "$KEY" -n "$NAMESPACE" "$STATEMENT" >/dev/null

echo "signed $TAG"
echo "  $STATEMENT"
echo "  $STATEMENT.sig"
sed 's/^/    /' "$STATEMENT"
