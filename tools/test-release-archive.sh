#!/usr/bin/env bash
# test-release-archive.sh — install a release archive the way a consumer does,
# and refuse to call it releasable unless every case below holds. ADR 0044.
#
#   ./tools/test-release-archive.sh --dist <dir>     the archives in <dir>
#   ./tools/test-release-archive.sh --throwaway      a copy of this checkout,
#                                                    signed with a throwaway key
#
# The release workflow runs the first form against the artifacts it is about to
# publish, after signing and before uploading. The standard's own CI runs the
# second on every pull request, so the test is exercised long before a release
# depends on it.
#
# On success with --dist, writes <dir>/.accepted holding the sha256 of the
# tarball that passed. tools/publish-release.sh will not publish an archive that
# file does not name: the bytes that were tested are the bytes that ship.
#
# Needs ssh-keygen, tar, unzip, sha256sum. Offline. Prints no key material.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$STANDARD_DIR/VERSION")"
BASE="causeway-$VERSION"

MODE=""
DIST=""
case "${1:-}" in
  --dist)      MODE=dist; DIST="${2:?--dist needs a directory}" ;;
  --throwaway) MODE=throwaway ;;
  *) echo "usage: test-release-archive.sh --dist <dir> | --throwaway" >&2; exit 1 ;;
esac

for t in ssh-keygen tar unzip sha256sum; do
  command -v "$t" >/dev/null 2>&1 || { echo "missing prerequisite: $t" >&2; exit 1; }
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "$MODE" = "throwaway" ]; then
  # shellcheck source=tools/lib-throwaway-release.sh
  . "$STANDARD_DIR/tools/lib-throwaway-release.sh"
  make_throwaway_release "$STANDARD_DIR" "$WORK/release"
  DIST="$WORK/release/dist"
fi
DIST="$(cd "$DIST" && pwd)"
rm -f "$DIST/.accepted"

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

# A PATH holding everything on this machine except the named tools.
path_without() {
  local dir; dir="$(mktemp -d "$WORK/path.XXXXXX")"
  local d f b t skip
  for d in /usr/local/bin /usr/bin /bin /usr/sbin /sbin; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      b="$(basename "$f")"; skip=0
      for t in "$@"; do case "$b" in "$t"|"$t"-*) skip=1 ;; esac; done
      [ "$skip" -eq 1 ] && continue
      [ -e "$dir/$b" ] || ln -s "$f" "$dir/$b" 2>/dev/null || true
    done
  done
  echo "$dir"
}
NOGIT="$(path_without git)"
NOGIT_NOSSH="$(path_without git ssh-keygen)"

echo "release archive $BASE — installs as a consumer would, or does not ship"

# ── The artifacts ────────────────────────────────────────────────────────────

for f in "$BASE.tar.gz" "$BASE.tar.gz.sha256" "$BASE.zip" "$BASE.zip.sha256"; do
  [ -f "$DIST/$f" ] || { bad "the release set is complete" "missing $f"; }
done
[ "$FAIL" -eq 0 ] && ok "the release set is complete: both archives and both checksums"
[ "$FAIL" -eq 0 ] || { echo ""; echo "$PASS passed, $FAIL failed"; exit 1; }

( cd "$DIST" && sha256sum -c "$BASE.tar.gz.sha256" "$BASE.zip.sha256" >/dev/null 2>&1 ) \
  && ok "both archives match their published checksums" \
  || bad "both archives match their published checksums"

mkdir -p "$WORK/tgz" "$WORK/zip"
tar -xzf "$DIST/$BASE.tar.gz" -C "$WORK/tgz"
unzip -q "$DIST/$BASE.zip" -d "$WORK/zip"
diff -r "$WORK/tgz" "$WORK/zip" >/dev/null 2>&1 \
  && ok "the .tar.gz and the .zip hold the same files" \
  || bad "the .tar.gz and the .zip hold the same files"
[ -x "$WORK/zip/$BASE/tools/sync.sh" ] \
  && ok "the .zip keeps the installer executable" \
  || bad "the .zip keeps the installer executable"

STD="$WORK/tgz/$BASE"
if [ -f "$STD/bundle/release.statement" ] && [ -f "$STD/bundle/release.statement.sig" ]; then
  ok "the archive carries its release statement and signature"
else
  bad "the archive carries its release statement and signature"
fi
S_TAG="$(sed -n 's/^tag=//p' "$STD/bundle/release.statement" 2>/dev/null | head -1 || true)"
S_DIGEST="$(sed -n 's/^digest=//p' "$STD/bundle/release.statement" 2>/dev/null | head -1 || true)"
[ "$S_TAG" = "v$VERSION" ] && ok "the statement signs v$VERSION" \
  || bad "the statement signs v$VERSION" "it names '${S_TAG}'"

# ── The install a consumer runs: no git, --require-release ───────────────────

P="$(mktemp -d "$WORK/project.XXXXXX")"
if PATH="$NOGIT" bash "$STD/tools/sync.sh" "$P" --require-release >"$WORK/out" 2>&1; then
  ok "sync.sh --require-release installs it with no git"
else
  bad "sync.sh --require-release installs it with no git" "$(tail -4 "$WORK/out" | tr '\n' ' ')"
fi
grep -qx 'release_proof=signed-statement' "$P/.causeway-lock" 2>/dev/null \
  && grep -qx "tag=$S_TAG" "$P/.causeway-lock" \
  && grep -qx "digest=$S_DIGEST" "$P/.causeway-lock" \
  && ok "the lock pins the signed release: proof, tag and digest" \
  || bad "the lock pins the signed release: proof, tag and digest"
( cd "$P" && PATH="$NOGIT" bash tools/check-drift.sh >/dev/null 2>&1 ) \
  && ok "the installed project passes its drift check" \
  || bad "the installed project passes its drift check"
( cd "$P" && PATH="$NOGIT" bash tools/verify-release.sh >/dev/null 2>&1 ) \
  && ok "the installed project verifies the signature offline" \
  || bad "the installed project verifies the signature offline"

# ── The same install, refused when it should be ──────────────────────────────

refused() {
  local name="$1" std="$2" path="$3" p rc=0
  p="$(mktemp -d "$WORK/refused.XXXXXX")"
  PATH="$path" bash "$std/tools/sync.sh" "$p" --require-release >"$WORK/out" 2>&1 || rc=$?
  if [ "$rc" -eq 7 ] && [ -z "$(ls -A "$p")" ]; then
    ok "$name is refused, and nothing is written"
  else
    bad "$name is refused, and nothing is written" "exit $rc; $(ls -A "$p" | head -3 | tr '\n' ' ')"
  fi
}

cp -a "$STD" "$WORK/badsig"
printf 'tampered\n' >> "$WORK/badsig/bundle/release.statement"
refused "an altered statement" "$WORK/badsig" "$NOGIT"

cp -a "$STD" "$WORK/altered"
printf '\n# an edit nobody signed\n' >> "$WORK/altered/AGENTS.md"
refused "content altered beside a genuine signature" "$WORK/altered" "$NOGIT"

refused "an install with no ssh-keygen to verify with" "$STD" "$NOGIT_NOSSH"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

if [ "$MODE" = "dist" ]; then
  sha256sum "$DIST/$BASE.tar.gz" | cut -d' ' -f1 > "$DIST/.accepted"
  echo "accepted: $(cat "$DIST/.accepted")  $BASE.tar.gz"
fi
