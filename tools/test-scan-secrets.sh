#!/usr/bin/env bash
# test-scan-secrets.sh — the credential scan finds provider-shaped secrets in
# the tree and in history, never prints them, and honours only exact, named,
# live suppressions. ADR 0054.
#
#   ./tools/test-scan-secrets.sh
#
# Every fixture is synthetic and assembled at runtime from pieces, so this file
# does not itself match a rule and the repository scan stays clean without a
# suppression. The AWS value is the example key AWS publishes in its own
# documentation. Offline; git is used only to build a throwaway history.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN="$STANDARD_DIR/tools/scan-secrets.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

AWS_ID="AKIA""IOSFODNN7EXAMPLE"
GH_TOKEN_FIXTURE="ghp""_$(printf 'x%.0s' $(seq 36))"
KEY_HEADER="-----BEGIN OPENSSH ""PRIVATE KEY-----"
fp() { printf '%s' "$1" | sha256sum | cut -d' ' -f1; }

scan() { # <dir> <args...> → sets OUT and RC
  set +e; OUT="$(python3 -I "$SCAN" --root "$@" 2>&1)"; RC=$?; set -e
}
leaks() { # true if OUT contains any fixture value
  case "$OUT" in *"$AWS_ID"*|*"$GH_TOKEN_FIXTURE"*|*"$KEY_HEADER"*) return 0 ;; esac
  return 1
}
repo() { # <dir>
  mkdir -p "$1"; git -C "$1" init -q
  git -C "$1" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m init
}
commit() { git -C "$1" add -A; git -C "$1" -c user.name=t -c user.email=t@example.invalid commit -q -m "$2"; }

# ── a clean tree passes ─────────────────────────────────────────────────────
R="$WORK/clean"; repo "$R"; echo "nothing to see" > "$R/README.md"; commit "$R" readme
scan "$R"; [ "$RC" -eq 0 ] && ok "a clean tree and history pass" || bad "a clean tree and history pass" "$OUT"

# ── each fixture is found, and never echoed ─────────────────────────────────
for pair in "aws-access-key-id:id = $AWS_ID" "github-token:token: $GH_TOKEN_FIXTURE" "private-key:$KEY_HEADER"; do
  rule="${pair%%:*}"; body="${pair#*:}"
  R="$WORK/$rule"; repo "$R"; printf 'line one\n%s\n' "$body" > "$R/notes.md"; commit "$R" add
  scan "$R" --tree
  if [ "$RC" -eq 1 ] && grep -q "FOUND  $rule .* notes.md:2" <<<"$OUT"; then
    ok "$rule is found at its line"
  else
    bad "$rule is found at its line" "$OUT"
  fi
  leaks && bad "$rule: the value is not printed" "$OUT" || ok "$rule: the value is not printed"
done

# ── binary content is not scanned ───────────────────────────────────────────
R="$WORK/binary"; repo "$R"; printf '\0\0%s' "$AWS_ID" > "$R/blob.bin"; commit "$R" bin
scan "$R" --tree; [ "$RC" -eq 0 ] && ok "binary files are skipped" || bad "binary files are skipped" "$OUT"

# ── history: deleted from the tree is not deleted from history ─────────────
R="$WORK/history"; repo "$R"; echo "id = $AWS_ID" > "$R/config.txt"; commit "$R" oops
rm "$R/config.txt"; commit "$R" "remove it"
scan "$R" --tree;    [ "$RC" -eq 0 ] && ok "the current tree is clean after deletion" || bad "the current tree is clean after deletion" "$OUT"
scan "$R" --history
[ "$RC" -eq 1 ] && grep -q "config.txt:1 (blob" <<<"$OUT" \
  && ok "history still finds the deleted credential" || bad "history still finds the deleted credential" "$OUT"
leaks && bad "history: the value is not printed" "$OUT" || ok "history: the value is not printed"
scan "$R"; [ "$RC" -eq 1 ] && ok "the default scans history too" || bad "the default scans history too" "$OUT"

# ── no git: the tree is still scanned ───────────────────────────────────────
R="$WORK/nogit"; mkdir -p "$R"; echo "id = $AWS_ID" > "$R/a.txt"
scan "$R"; [ "$RC" -eq 1 ] && ok "a directory with no git is scanned as files" || bad "a directory with no git is scanned as files" "$OUT"
scan "$R" --history; [ "$RC" -eq 2 ] && ok "--history without git is an error, not a pass" || bad "--history without git is an error, not a pass" "$OUT"

# ── suppressions: exact, named, explained, live ─────────────────────────────
R="$WORK/allow"; mkdir -p "$R"; echo "id = $AWS_ID" > "$R/fixture.txt"
allow() { printf '{"suppressions": [%s]}\n' "$1" > "$WORK/allow.json"; }
GOOD="{\"rule\":\"aws-access-key-id\",\"path\":\"fixture.txt\",\"fingerprint\":\"$(fp "$AWS_ID")\",\"reason\":\"AWS documentation example key\",\"accepted_by\":\"Test Person\"}"

allow "$GOOD"; scan "$R" --tree --allow "$WORK/allow.json"
[ "$RC" -eq 0 ] && ok "an exact, explained, named suppression is honoured" || bad "an exact, explained, named suppression is honoured" "$OUT"

allow "${GOOD/\"Test Person\"/\"\"}"; scan "$R" --tree --allow "$WORK/allow.json"
[ "$RC" -eq 2 ] && ok "a suppression with nobody accepting it is refused" || bad "a suppression with nobody accepting it is refused" "$OUT"

allow "${GOOD/\"AWS documentation example key\"/\"\"}"; scan "$R" --tree --allow "$WORK/allow.json"
[ "$RC" -eq 2 ] && ok "a suppression with no reason is refused" || bad "a suppression with no reason is refused" "$OUT"

allow "${GOOD/\"fixture.txt\"/\"*.txt\"}"; scan "$R" --tree --allow "$WORK/allow.json"
[ "$RC" -eq 2 ] && ok "a pattern path is refused: suppressions are exact" || bad "a pattern path is refused: suppressions are exact" "$OUT"

allow "${GOOD/$(fp "$AWS_ID")/$(fp other)}"; scan "$R" --tree --allow "$WORK/allow.json"
[ "$RC" -eq 1 ] && grep -q "FOUND" <<<"$OUT" && grep -q "STALE" <<<"$OUT" \
  && ok "a different fingerprint suppresses nothing, and is stale" || bad "a different fingerprint suppresses nothing, and is stale" "$OUT"

rm "$R/fixture.txt"; allow "$GOOD"; scan "$R" --tree --allow "$WORK/allow.json"
[ "$RC" -eq 1 ] && grep -q "STALE" <<<"$OUT" \
  && ok "a suppression that outlived its finding fails" || bad "a suppression that outlived its finding fails" "$OUT"

# ── this repository ─────────────────────────────────────────────────────────
scan "$STANDARD_DIR"; [ "$RC" -eq 0 ] && ok "this repository's tree and history are clean" \
  || bad "this repository's tree and history are clean" "$OUT"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
