#!/usr/bin/env bash
# test-upgrade-starters.sh — a later release's starter changes reach a project
# without costing it its own edits. ADR 0046.
#
#   ./tools/test-upgrade-starters.sh
#
# A project is synced from this checkout, which records each starter's baseline.
# A "future" copy of the standard is then made with three templates changed, and
# its upgrade-starters.sh is run against the project, covering every outcome the
# script can reach. Offline.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }
snap() { ( cd "$1" && find . -printf '%y %p\n' | LC_ALL=C sort \
           && find . -type f -exec sha256sum {} + | LC_ALL=C sort -k2 ); }
state_of() { awk -v d="$2" '$2==d {print $1; exit}' "$1"; }
expect_state() {  # expect_state <label> <report> <file> <state>
  local got; got="$(state_of "$2" "$3")"
  [ "$got" = "$4" ] && ok "$1" || bad "$1" "$3 is '$got', wanted $4"
}

echo "upgrade-starters.sh — upstream improvements in, local edits kept"

# ── The project, and the release it is upgrading to ──────────────────────────

P="$WORK/project"; mkdir -p "$P"
bash "$STANDARD_DIR/tools/sync.sh" "$P" >/dev/null 2>&1

NEXT="$WORK/next"; mkdir -p "$NEXT"
( cd "$STANDARD_DIR" && tar --exclude=.git -cf - . ) | tar -xf - -C "$NEXT"
echo "9.9.9" > "$NEXT/VERSION"
# Upstream appends a section to the contributor guide and to the CLAUDE.md
# starter, and rewords the PR template's project heading.
printf '\n## 8. A section added upstream\n\nNew guidance.\n' >> "$NEXT/templates/contributor-START-HERE.md"
printf '\n## Added upstream\n' >> "$NEXT/templates/project-CLAUDE.md"
sed -i 's/^## \[CALLSIGN\]$/## [CALLSIGN] — rules only this project has/' "$NEXT/templates/pull_request_template.md"
grep -q 'rules only this project has' "$NEXT/templates/pull_request_template.md" \
  || { echo "test setup: the PR template heading moved; update this test"; exit 1; }

# The project fills in its names: the first line of the contributor guide (far
# from upstream's change) and the PR template heading (the line upstream changed).
sed -i '1s/\[CALLSIGN\]/Lantern/' "$P/CONTRIBUTING.md"
sed -i 's/^## \[CALLSIGN\]$/## Lantern/' "$P/.github/pull_request_template.md"
printf '* @lantern/engineering\n' > "$P/.github/CODEOWNERS"

# ── Same release: nothing to do ──────────────────────────────────────────────

bash "$STANDARD_DIR/tools/upgrade-starters.sh" "$P" --out "$WORK/r0" > "$WORK/r0.txt"
n_up="$(grep -c '^  up-to-date' "$WORK/r0.txt" || true)"
[ "$n_up" -eq 9 ] && ok "against the release it was seeded from, all nine starters are up-to-date" \
  || bad "against the release it was seeded from, all nine starters are up-to-date" "$n_up up-to-date"

# ── Report: says what would happen, writes nothing ───────────────────────────

before="$(snap "$P")"
bash "$NEXT/tools/upgrade-starters.sh" "$P" --out "$WORK/r1" > "$WORK/r1.txt"
[ "$before" = "$(snap "$P")" ] && ok "report mode changes nothing in the project" \
  || bad "report mode changes nothing in the project"
expect_state "an unedited starter whose template changed is clean" "$WORK/r1.txt" CLAUDE.md clean
expect_state "edits and upstream changes in different places merge" "$WORK/r1.txt" CONTRIBUTING.md merge
expect_state "edits and upstream changes on the same line conflict" "$WORK/r1.txt" .github/pull_request_template.md conflict
expect_state "an edited starter whose template did not change is up-to-date" "$WORK/r1.txt" .github/CODEOWNERS up-to-date
grep -q '^<<<<<<< yours' "$WORK/r1/.github/pull_request_template.md.conflict" \
  && grep -q '^>>>>>>> causeway v9.9.9' "$WORK/r1/.github/pull_request_template.md.conflict" \
  && ok "the conflict is written to the report with labelled markers" \
  || bad "the conflict is written to the report with labelled markers"
[ -f "$WORK/r1/CONTRIBUTING.md.diff" ] && [ -f "$WORK/r1/CLAUDE.md.diff" ] \
  && ok "each proposed change has a reviewable diff" || bad "each proposed change has a reviewable diff"
cp "$P/.github/pull_request_template.md" "$WORK/pr-before"
if bash "$NEXT/tools/upgrade-starters.sh" "$P" --out "$P/inside/report" >/dev/null 2>&1 \
   || [ -e "$P/inside" ]; then
  bad "--out inside the project is refused, and nothing is created"
else
  ok "--out inside the project is refused, and nothing is created"
fi

# ── Apply: clean and merge land, the conflict does not ───────────────────────

bash "$NEXT/tools/upgrade-starters.sh" "$P" --apply --out "$WORK/r2" > "$WORK/r2.txt"
cmp -s "$P/CLAUDE.md" "$NEXT/templates/project-CLAUDE.md" \
  && ok "apply replaces the unedited starter with the new template" \
  || bad "apply replaces the unedited starter with the new template"
head -1 "$P/CONTRIBUTING.md" | grep -q 'Lantern' && grep -q 'A section added upstream' "$P/CONTRIBUTING.md" \
  && ok "apply merges: the project's name and upstream's section are both there" \
  || bad "apply merges: the project's name and upstream's section are both there"
cmp -s "$P/.github/pull_request_template.md" "$WORK/pr-before" \
  && ! grep -q '<<<<<<<' "$P/.github/pull_request_template.md" \
  && ok "apply never writes a conflict into the project's file" \
  || bad "apply never writes a conflict into the project's file"
grep -q '@lantern/engineering' "$P/.github/CODEOWNERS" \
  && ok "the project's reviewers are untouched" || bad "the project's reviewers are untouched"
awk '$2=="CONTRIBUTING.md" {print $4}' "$P/.causeway/starters.txt" | grep -qx 'v9.9.9' \
  && cmp -s "$P/.causeway/starters/CONTRIBUTING.md.base" "$NEXT/templates/contributor-START-HERE.md" \
  && ok "an applied file's baseline moves to the new release" \
  || bad "an applied file's baseline moves to the new release"
awk '$2==".github/pull_request_template.md" {print $4}' "$P/.causeway/starters.txt" | grep -qvx 'v9.9.9' \
  && ok "a conflicted file's baseline stays where it was" \
  || bad "a conflicted file's baseline stays where it was"

# ── Again: repeat application is stable ──────────────────────────────────────

before="$(snap "$P")"
bash "$NEXT/tools/upgrade-starters.sh" "$P" --apply --out "$WORK/r3" > "$WORK/r3.txt"
expect_state "applying again reports the applied file up-to-date" "$WORK/r3.txt" CONTRIBUTING.md up-to-date
expect_state "and the conflict is still a conflict" "$WORK/r3.txt" .github/pull_request_template.md conflict
[ "$before" = "$(snap "$P")" ] && ok "a second apply changes nothing" \
  || bad "a second apply changes nothing"

# ── Resolve by hand, then accept ─────────────────────────────────────────────

sed -i 's/^## Lantern$/## Lantern — rules only this project has/' "$P/.github/pull_request_template.md"
cp "$P/.github/pull_request_template.md" "$WORK/pr-resolved"
bash "$NEXT/tools/upgrade-starters.sh" "$P" --accept .github/pull_request_template.md > /dev/null
cmp -s "$P/.github/pull_request_template.md" "$WORK/pr-resolved" \
  && ok "--accept changes no file of the project's" || bad "--accept changes no file of the project's"
bash "$NEXT/tools/upgrade-starters.sh" "$P" --out "$WORK/r4" > "$WORK/r4.txt"
expect_state "after --accept, the hand-merged file is up-to-date" "$WORK/r4.txt" .github/pull_request_template.md up-to-date
bash "$NEXT/tools/upgrade-starters.sh" "$P" --accept NOT-A-STARTER.md >/dev/null 2>&1 \
  && bad "--accept refuses a file that is not a starter" || ok "--accept refuses a file that is not a starter"

# ── No baseline: a project synced before baselines existed ───────────────────

Q="$WORK/legacy"; mkdir -p "$Q"
bash "$STANDARD_DIR/tools/sync.sh" "$Q" >/dev/null 2>&1
rm -rf "$Q/.causeway" "$Q/START-HERE.md"
cp "$NEXT/templates/project-CLAUDE.md" "$Q/CLAUDE.md"
sed -i '1s/\[CALLSIGN\]/Lantern/' "$Q/CONTRIBUTING.md"
bash "$NEXT/tools/upgrade-starters.sh" "$Q" --out "$WORK/r5" > "$WORK/r5.txt"
expect_state "with no baseline, a file identical to the new template can be adopted" "$WORK/r5.txt" CLAUDE.md adopt
expect_state "with no baseline, an edited file is manual review, never guessed" "$WORK/r5.txt" CONTRIBUTING.md manual
expect_state "a starter the project does not have is reported absent" "$WORK/r5.txt" START-HERE.md absent
[ -f "$WORK/r5/CONTRIBUTING.md.diff" ] && ok "manual review gets a diff to work from" \
  || bad "manual review gets a diff to work from"
cp "$Q/CONTRIBUTING.md" "$WORK/legacy-contrib"
bash "$NEXT/tools/upgrade-starters.sh" "$Q" --apply --out "$WORK/r6" > /dev/null
cmp -s "$Q/CONTRIBUTING.md" "$WORK/legacy-contrib" \
  && [ -f "$Q/.causeway/starters/CLAUDE.md.base" ] && [ ! -f "$Q/.causeway/starters/CONTRIBUTING.md.base" ] \
  && ok "apply records the adopted baseline and leaves the manual file alone" \
  || bad "apply records the adopted baseline and leaves the manual file alone"

# ── sync.sh keeps the baselines honest ───────────────────────────────────────

before="$(snap "$P" | grep -v '\.causeway-lock$')"
bash "$STANDARD_DIR/tools/sync.sh" "$P" >/dev/null 2>&1
[ "$before" = "$(snap "$P" | grep -v '\.causeway-lock$')" ] \
  && ok "re-syncing an established project leaves its baselines alone" \
  || bad "re-syncing an established project leaves its baselines alone"
rm "$P/START-HERE.md"
bash "$STANDARD_DIR/tools/sync.sh" "$P" >/dev/null 2>&1
[ "$(grep -c ' START-HERE.md ' "$P/.causeway/starters.txt")" -eq 1 ] \
  && [ "$(grep -vc '^#' "$P/.causeway/starters.txt")" -eq 9 ] \
  && ok "re-seeding one starter replaces its line and keeps the other eight" \
  || bad "re-seeding one starter replaces its line and keeps the other eight"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
