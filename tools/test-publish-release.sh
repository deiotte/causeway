#!/usr/bin/env bash
# test-publish-release.sh — prove publish-release.sh contacts GitHub only when
# every precondition holds, and never leaves a partial release visible. ADR 0044.
#
#   ./tools/test-publish-release.sh
#
# `gh` is replaced by a stub on PATH that records each call and keeps a release
# state (absent, draft, published) in a file, so each case can assert both what
# was attempted and what a visitor to the release page would now see. The
# release under test is signed with a throwaway key. Offline.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$STANDARD_DIR/VERSION")"
BASE="causeway-$VERSION"
TAG="v$VERSION"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

# ── The stub ─────────────────────────────────────────────────────────────────
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "gh $*" >> "$GH_LOG"
state="$(cat "$GH_STATE")"
case "$*" in *"${GH_FAIL_ON:-@never@}"*) exit 1 ;; esac
case "$1 $2" in
  "release view")
    [ "$state" = absent ] && exit 1
    [ "$state" = draft ] && echo true || echo false ;;
  "release create")
    case "$*" in *--draft*) echo draft ;; *) echo published ;; esac > "$GH_STATE" ;;
  "release edit")
    case "$*" in
      *--draft=true*)  echo draft > "$GH_STATE" ;;
      *--draft=false*) echo published > "$GH_STATE" ;;
    esac ;;
  "release upload")
    [ "$state" = absent ] && exit 1
    # Assets uploaded while published would be visible one by one.
    [ "$state" = published ] && echo "VISIBLE-PARTIAL" >> "$GH_LOG"
    true ;;
esac
STUB
chmod +x "$WORK/bin/gh"
export PATH="$WORK/bin:$PATH"

# ── A signed release to publish ──────────────────────────────────────────────
# shellcheck source=tools/lib-throwaway-release.sh
. "$STANDARD_DIR/tools/lib-throwaway-release.sh"
make_throwaway_release "$STANDARD_DIR" "$WORK/release"
TREE="$WORK/release/tree/$BASE"
"$STANDARD_DIR/tools/test-release-archive.sh" --dist "$WORK/release/dist" >/dev/null \
  || { echo "the throwaway release did not pass acceptance — cannot test publishing"; exit 1; }

# Each case gets its own copy of the tree and the dist, a fresh log, and a
# starting state. run <name> <start-state> [publish args...]
setup() {
  rm -rf "$WORK/case"; mkdir -p "$WORK/case"
  cp -a "$TREE" "$WORK/case/tree"; cp -a "$WORK/release/dist" "$WORK/case/dist"
  export GH_LOG="$WORK/case/log" GH_STATE="$WORK/case/state"
  : > "$GH_LOG"; echo "$1" > "$GH_STATE"
}
publish() {
  RC=0
  "$STANDARD_DIR/tools/publish-release.sh" --root "$WORK/case/tree" "$@" \
    >"$WORK/case/out" 2>&1 || RC=$?
}
state() { cat "$GH_STATE"; }
calls() { wc -l < "$GH_LOG" | tr -d ' '; }

# A refused publish: exit 3, and GitHub never contacted.
expect_refused() {
  local name="$1"
  [ -n "${SHOW_REASONS:-}" ] && sed -n 2,4p "$WORK/case/out" | sed "s/^/            /"
  if [ "$RC" -eq 3 ] && [ "$(calls)" -eq 0 ]; then
    ok "$name: refused, and gh was never called"
  else
    bad "$name: refused, and gh was never called" "exit $RC, $(calls) gh call(s): $(head -2 "$GH_LOG" | tr '\n' ' ')"
  fi
}

echo "publish-release.sh — publish the verified set at once, or contact nothing"

# ── Publishing ───────────────────────────────────────────────────────────────

setup absent; publish --tag "$TAG" --dist "$WORK/case/dist"
if [ "$RC" -eq 0 ] && [ "$(state)" = published ] && ! grep -q VISIBLE-PARTIAL "$GH_LOG" \
   && grep -q -- "release create $TAG --draft" "$GH_LOG" \
   && [ "$(grep -c 'release upload' "$GH_LOG")" -eq 1 ] \
   && [ "$(grep 'release upload' "$GH_LOG" | tr ' ' '\n' | grep -c '^/')" -eq 6 ]; then
  ok "a new release is created as a draft, gets all six assets in one upload, then is published"
else
  bad "a new release is created as a draft, gets all six assets in one upload, then is published" \
      "exit $RC, state $(state); $(tr '\n' ' ' < "$GH_LOG")"
fi

setup published; publish --tag "$TAG" --dist "$WORK/case/dist"
if [ "$RC" -eq 0 ] && [ "$(state)" = published ] && ! grep -q VISIBLE-PARTIAL "$GH_LOG" \
   && [ "$(sed -n 2p "$GH_LOG")" = "gh release edit $TAG --draft=true" ]; then
  ok "a release published from the web is hidden while its assets change, then republished"
else
  bad "a release published from the web is hidden while its assets change, then republished" \
      "exit $RC, state $(state); $(tr '\n' ' ' < "$GH_LOG")"
fi

setup absent; GH_FAIL_ON="release upload" publish --tag "$TAG" --dist "$WORK/case/dist"
if [ "$RC" -eq 4 ] && [ "$(state)" = draft ] && ! grep -q -- '--draft=false' "$GH_LOG"; then
  ok "a failed upload leaves the release a draft, never published partial"
else
  bad "a failed upload leaves the release a draft, never published partial" \
      "exit $RC, state $(state)"
fi

# ── Refusals: nothing reaches GitHub ─────────────────────────────────────────

setup absent; rm "$WORK/case/dist/.accepted"; publish --tag "$TAG" --dist "$WORK/case/dist"
expect_refused "an archive the acceptance test never passed"

setup absent
printf 'x' >> "$WORK/case/dist/$BASE.tar.gz"
( cd "$WORK/case/dist" && sha256sum "$BASE.tar.gz" > "$BASE.tar.gz.sha256" )
publish --tag "$TAG" --dist "$WORK/case/dist"
expect_refused "a tarball changed after acceptance, checksum regenerated to match"

setup absent; printf 'x' >> "$WORK/case/dist/$BASE.zip"; publish --tag "$TAG" --dist "$WORK/case/dist"
expect_refused "a zip that does not match its checksum"

setup absent; printf 'tampered\n' >> "$WORK/case/tree/bundle/release.statement"
publish --tag "$TAG" --dist "$WORK/case/dist"
expect_refused "a statement that does not verify"

setup absent; rm "$WORK/case/tree/bundle/release.statement.sig"
publish --tag "$TAG" --dist "$WORK/case/dist"
expect_refused "a missing signature"

setup absent; publish --tag "v0.0.0" --dist "$WORK/case/dist"
expect_refused "a tag that is not this tree's version"

# An archive built before signing: the tree is signed, the archive is not, and
# .accepted is forged to name it. The statement check still catches it.
setup absent
rm "$WORK/case/dist/"*
cp "$STANDARD_DIR/tools/build-archive.sh" "$WORK/case/tree/tools/"
mv "$WORK/case/tree/bundle/release.statement" "$WORK/case/stmt"
mv "$WORK/case/tree/bundle/release.statement.sig" "$WORK/case/sig"
( cd "$WORK/case/tree" && bash tools/build-archive.sh --out "$WORK/case/dist" >/dev/null )
mv "$WORK/case/stmt" "$WORK/case/tree/bundle/release.statement"
mv "$WORK/case/sig" "$WORK/case/tree/bundle/release.statement.sig"
rm "$WORK/case/tree/tools/build-archive.sh"
sha256sum "$WORK/case/dist/$BASE.tar.gz" | cut -d' ' -f1 > "$WORK/case/dist/.accepted"
publish --tag "$TAG" --dist "$WORK/case/dist"
expect_refused "an archive built before signing, with acceptance forged"

# ── The failure policy ───────────────────────────────────────────────────────

setup published; publish --tag "$TAG" --withdraw
if [ "$RC" -eq 0 ] && [ "$(state)" = draft ] && ! grep -q 'release upload' "$GH_LOG"; then
  ok "withdraw turns a published release into a draft and uploads nothing"
else
  bad "withdraw turns a published release into a draft and uploads nothing" "exit $RC, state $(state)"
fi

setup absent; publish --tag "$TAG" --withdraw
if [ "$RC" -eq 0 ] && [ "$(state)" = absent ] && ! grep -qE 'release (create|edit|upload)' "$GH_LOG"; then
  ok "withdraw with no release creates nothing"
else
  bad "withdraw with no release creates nothing" "exit $RC, state $(state)"
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
