#!/usr/bin/env bash
# test-authorize-release.sh — release.yml signs only a stable release tag on a
# commit that is already on main. ADR 0054, issue #37.
#
#   ./tools/test-authorize-release.sh
#
# A throwaway repository with a main branch, a reviewed release on it, and the
# attempts the red team described: a tag on an unreviewed branch commit, a tag
# that does not match VERSION, a tag moved after the run began, and a run
# started for a commit no release tag names. No key and no network; the signing
# key is never in reach of this test, which is the point of the job it guards.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTH="$STANDARD_DIR/tools/authorize-release.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

R="$WORK/repo"; mkdir -p "$R"; cd "$R"
g() { git -c user.name=t -c user.email=t@example.invalid "$@"; }
g init -q -b main
echo "1.0.0" > VERSION; g add VERSION; g commit -q -m "release 1.0.0"
GOOD="$(git rev-parse HEAD)"; g tag v1.0.0
echo "1.0.1" > VERSION; g commit -q -am "after the release"
# main is "origin/main" in the workflow; a local ref stands in for it here.
MAIN="refs/heads/main"

g checkout -q -b unreviewed
echo "1.1.0" > VERSION; echo "evil" > payload; g add -A; g commit -q -m "never reviewed"
OFF="$(git rev-parse HEAD)"; g tag v1.1.0
g checkout -q main

run() { # <expected-exit> <description> <args...>
  local want="$1" what="$2"; shift 2
  : > "$WORK/out"
  set +e; MSG="$(bash "$AUTH" --main "$MAIN" --output "$WORK/out" "$@" 2>&1)"; RC=$?; set -e
  [ "$RC" -eq "$want" ] && ok "$what" || bad "$what" "exit $RC (wanted $want): $MSG"
}

run 0 "a release tag on main, from the run's commit, is authorized" --sha "$GOOD"
grep -qx "tag=v1.0.0" "$WORK/out" && grep -qx "sha=$GOOD" "$WORK/out" \
  && ok "the authorized tag and commit are handed to the later jobs" \
  || bad "the authorized tag and commit are handed to the later jobs" "$(cat "$WORK/out")"

run 0 "the same release named by hand (workflow_dispatch) is authorized" --tag v1.0.0

run 4 "a tag on an unreviewed branch commit is refused" --sha "$OFF"
grep -qx "tag=v1.1.0" "$WORK/out" \
  && ok "a refused off-main tag is still named, so its release can be withdrawn" \
  || bad "a refused off-main tag is still named, so its release can be withdrawn"
run 4 "the off-main tag named by hand is refused too" --tag v1.1.0

g tag v9.9.9 "$GOOD"
run 3 "a tag that is not v<VERSION> of its commit is refused" --tag v9.9.9
[ ! -s "$WORK/out" ] && ok "an unidentified tag names nothing to withdraw" \
  || bad "an unidentified tag names nothing to withdraw" "$(cat "$WORK/out")"

AFTER="$(git rev-parse main)"
run 3 "a commit no release tag names is refused" --sha "$AFTER"

g tag -f v1.0.0 "$OFF" >/dev/null
run 3 "a tag moved after the run began is refused" --sha "$GOOD"
g tag -f v1.0.0 "$GOOD" >/dev/null

g tag 'v1.0.0;x' "$GOOD"
run 3 "a tag with shell metacharacters is refused" --tag 'v1.0.0;x'

run 3 "a commit that does not exist is refused" --sha 0000000000000000000000000000000000000000
run 4 "a missing main is refused, not assumed" --sha "$GOOD" --main refs/heads/nope
set +e; bash "$AUTH" >/dev/null 2>&1; RC=$?; set -e
[ "$RC" -eq 1 ] && ok "no --sha or --tag is a usage error" || bad "no --sha or --tag is a usage error" "exit $RC"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
