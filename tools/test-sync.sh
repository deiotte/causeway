#!/usr/bin/env bash
# test-sync.sh — prove that sync.sh either completes or changes nothing.
#
#   ./tools/test-sync.sh
#
# Every refusal sync.sh can reach before it writes is exercised against a target
# that already holds a project — custom AGENTS.md, an existing lock, project
# files — and the target is compared before and after, byte for byte. Then a
# signed release is installed with no git, and an apply failure is injected to
# prove the rollback. ADR 0042 and issue #9.
#
# The signed cases sign a throwaway copy of the standard with a key generated
# here and thrown away at exit. The real release key is never read, and nothing
# printed below contains private key material.
#
# Needs ssh-keygen. Offline: no network, no fetch.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$STANDARD_DIR/VERSION")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v ssh-keygen >/dev/null 2>&1 || {
  echo "ssh-keygen not found — install openssh-client" >&2; exit 1; }

PASS=0
FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

# Every path, its type, and every file's hash. Two equal snapshots mean the
# target is byte-identical and holds no new file, directory or leftover stage.
snap() { ( cd "$1" && find . -printf '%y %p\n' | LC_ALL=C sort \
           && find . -type f -exec sha256sum {} + | LC_ALL=C sort -k2 ); }

# A target that already belongs to somebody.
existing_project() {
  local p; p="$(mktemp -d "$WORK/project.XXXXXX")"
  printf '# Our own agent instructions\n' > "$p/AGENTS.md"
  printf 'version=0.0.1\ndigest=sha256:old\n' > "$p/.causeway-lock"
  printf '# Our project\n' > "$p/CLAUDE.md"
  mkdir -p "$p/src"; printf 'package main\n' > "$p/src/main.go"
  echo "$p"
}

# The run must exit with $1 and leave the target exactly as it found it.
expect_untouched() {
  local want="$1" name="$2" target="$3"; shift 3
  local before after rc=0
  before="$(snap "$target")"
  "$@" >"$WORK/out" 2>&1 || rc=$?
  after="$(snap "$target")"
  if [ "$rc" -ne "$want" ]; then
    bad "$name" "exit $rc, wanted $want — $(tail -3 "$WORK/out" | tr '\n' ' ')"
  elif [ "$before" != "$after" ]; then
    bad "$name" "exit $rc as wanted, but the target changed:"
    diff <(echo "$before") <(echo "$after") | sed 's/^/          /' | head -20 || true
  else
    ok "$name (exit $rc, target byte-identical)"
  fi
}

# A PATH holding everything on this machine except the named tools.
path_without() {
  local dir; dir="$(mktemp -d "$WORK/path.XXXXXX")"
  local d f b skip
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

echo "sync.sh — an installation completes or changes nothing"

# ── From this checkout ───────────────────────────────────────────────────────

# The reproduced defect: an untagged source with --require-release overwrote an
# existing AGENTS.md, created gate files, and exited 7 with no new lock. Run from
# a clean copy with no tag, so the case holds whatever state this tree is in.
UNTAGGED="$WORK/untagged"
mkdir -p "$UNTAGGED"
( cd "$STANDARD_DIR" && tar --exclude=.git -cf - . ) | tar -xf - -C "$UNTAGGED"
git -C "$UNTAGGED" init -q
git -C "$UNTAGGED" add -A
git -C "$UNTAGGED" -c user.name=test -c user.email=test@invalid \
  -c commit.gpgsign=false commit -q -m untagged
P="$(existing_project)"
expect_untouched 7 "a clean, untagged source under --require-release is refused" \
  "$P" bash "$UNTAGGED/tools/sync.sh" "$P" --require-release

P="$(existing_project)"
expect_untouched 1 "an unknown overlay is refused" \
  "$P" bash "$STANDARD_DIR/tools/sync.sh" "$P" --overlay no-such-platform

P="$(existing_project)"
rm "$P/AGENTS.md"; mkdir "$P/AGENTS.md"
expect_untouched 9 "a destination that is a directory is a conflict" \
  "$P" bash "$STANDARD_DIR/tools/sync.sh" "$P"

P="$(existing_project)"
printf 'not a directory\n' > "$P/gate"
expect_untouched 9 "a parent that is a file is a conflict" \
  "$P" bash "$STANDARD_DIR/tools/sync.sh" "$P"

P="$(existing_project)"
OUTSIDE="$(mktemp -d "$WORK/outside.XXXXXX")"
ln -s "$OUTSIDE" "$P/rules"
expect_untouched 9 "a symlinked directory is a conflict" \
  "$P" bash "$STANDARD_DIR/tools/sync.sh" "$P"
[ -z "$(ls -A "$OUTSIDE")" ] && ok "nothing was written through the symlink" \
  || bad "nothing was written through the symlink" "$(ls -A "$OUTSIDE")"

# An apply that fails partway must put back what it overwrote and remove what it
# created — including the directories — and leave no stage behind.
for n in 0 5 30; do
  P="$(existing_project)"
  expect_untouched 10 "apply failing after $n files is rolled back" \
    "$P" env CAUSEWAY_SYNC_FAIL_AFTER="$n" bash "$STANDARD_DIR/tools/sync.sh" "$P"
done

# A complete install writes the lock, and a second one is idempotent: same
# files, project-owned files left alone, no stage left behind.
P="$(mktemp -d "$WORK/fresh.XXXXXX")"
if bash "$STANDARD_DIR/tools/sync.sh" "$P" >"$WORK/out" 2>&1 \
   && [ -f "$P/.causeway-lock" ] \
   && ( cd "$P" && bash tools/check-drift.sh >/dev/null ); then
  ok "a fresh install completes and passes its drift check"
else
  bad "a fresh install completes and passes its drift check" "$(tail -3 "$WORK/out")"
fi
printf '\n# edited by the project\n' >> "$P/CLAUDE.md"
before="$(snap "$P" | grep -v '\.causeway-lock$')"
bash "$STANDARD_DIR/tools/sync.sh" "$P" >/dev/null 2>&1
after="$(snap "$P" | grep -v '\.causeway-lock$')"
[ "$before" = "$after" ] && ok "a re-sync is idempotent and keeps project-owned files" \
  || bad "a re-sync is idempotent and keeps project-owned files"
ls -A "$P" | grep -q '^\.causeway-sync\.' \
  && bad "no staging directory is left behind" || ok "no staging directory is left behind"

# ── From a signed archive, with no git ───────────────────────────────────────
#
# A release as a consumer receives it: extracted, no history, statement and
# signature inside. Signed here with a throwaway key that the copy's own
# allowed-signers trusts, and its manifest rebuilt so the anchor is covered.

"$STANDARD_DIR/tools/build-archive.sh" --out "$WORK/dist" >/dev/null 2>&1
signed_copy() {
  local dest="$1"
  mkdir -p "$dest"
  tar -xzf "$WORK/dist/causeway-$VERSION.tar.gz" -C "$dest"
  dest="$dest/causeway-$VERSION"
  [ -f "$WORK/key" ] || ssh-keygen -q -t ed25519 -N '' -C test -f "$WORK/key"
  printf 'release@test %s\n' \
    "$(cut -d' ' -f1,2 "$WORK/key.pub")" > "$dest/bundle/allowed-signers"
  cp "$STANDARD_DIR/tools/build-bundle.sh" "$dest/tools/build-bundle.sh"
  ( cd "$dest" && bash tools/build-bundle.sh >/dev/null )
  rm "$dest/tools/build-bundle.sh"
  local digest
  digest="$(sed -n 's/.*"digest"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$dest/bundle/manifest.json" | head -1)"
  printf 'causeway-release-v1\nversion=%s\nreleased=%s\ndigest=%s\ncommit=%s\ntag=v%s\n' \
    "$VERSION" "$(cat "$dest/RELEASED")" "$digest" "0000000000000000000000000000000000000000" \
    "$VERSION" > "$dest/bundle/release.statement"
  ssh-keygen -q -Y sign -f "$WORK/key" -n causeway-release \
    "$dest/bundle/release.statement" >/dev/null 2>&1
  echo "$dest"
}

S="$(signed_copy "$WORK/signed-good")"
P="$(existing_project)"
if PATH="$NOGIT" bash "$S/tools/sync.sh" "$P" --require-release >"$WORK/out" 2>&1 \
   && grep -q '^release_proof=signed-statement$' "$P/.causeway-lock" \
   && grep -q "^tag=v$VERSION$" "$P/.causeway-lock" \
   && ( cd "$P" && PATH="$NOGIT" bash tools/check-drift.sh >/dev/null ) \
   && ( cd "$P" && PATH="$NOGIT" bash tools/verify-release.sh >/dev/null ); then
  ok "a signed archive installs with no git, and verifies in the project"
else
  bad "a signed archive installs with no git, and verifies in the project" \
      "$(tail -5 "$WORK/out" | tr '\n' ' ')"
fi

S="$(signed_copy "$WORK/signed-badsig")"
printf 'tampered\n' >> "$S/bundle/release.statement"
P="$(existing_project)"
expect_untouched 7 "an invalid signature is refused" \
  "$P" env PATH="$NOGIT" bash "$S/tools/sync.sh" "$P" --require-release

S="$(signed_copy "$WORK/signed-altered")"
printf '\n# an edit nobody signed\n' >> "$S/AGENTS.md"
P="$(existing_project)"
expect_untouched 7 "altered covered content beside a genuine signature is refused" \
  "$P" env PATH="$NOGIT" bash "$S/tools/sync.sh" "$P" --require-release

S="$(signed_copy "$WORK/signed-manifest")"
# The edit is carried into the manifest's own entry, so every file matches its
# line and only the recomputed digest can notice.
old="$(sha256sum "$S/AGENTS.md" | cut -d' ' -f1)"
printf '\n# an edit, and a manifest updated to hide it\n' >> "$S/AGENTS.md"
new="$(sha256sum "$S/AGENTS.md" | cut -d' ' -f1)"
sed -i "s/$old/$new/" "$S/bundle/manifest.json"
P="$(existing_project)"
expect_untouched 7 "a manifest edited under an unchanged digest is refused" \
  "$P" env PATH="$NOGIT" bash "$S/tools/sync.sh" "$P" --require-release

S="$(signed_copy "$WORK/signed-noverifier")"
P="$(existing_project)"
expect_untouched 7 "no ssh-keygen to verify with is refused" \
  "$P" env PATH="$NOGIT_NOSSH" bash "$S/tools/sync.sh" "$P" --require-release

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
