#!/usr/bin/env bash
# test-doctor.sh — doctor.sh reports what is missing, and only what is missing.
#
#   ./tools/test-doctor.sh
#
# A freshly synced project must come back incomplete on exactly the things a
# sync cannot do for it; a deliberately configured one, installed from a signed
# release, must come back with nothing incomplete and the repository settings
# still unverified. Between those, one case per kind of finding. Every run is
# checked to have changed nothing in the project. ADR 0045. Offline.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$STANDARD_DIR/VERSION")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

snap() { ( cd "$1" && find . -printf '%y %p\n' | LC_ALL=C sort \
           && find . -type f -exec sha256sum {} + | LC_ALL=C sort -k2 ); }

# Run doctor on $1 with --json, require it changed nothing and exited 0, and
# leave the result in $WORK/doc.json. Extra args go before the directory.
doctor() {
  local p="$1"; shift
  local before after rc=0
  before="$(snap "$p")"
  "$@" bash "$p/tools/doctor.sh" --json "$p" > "$WORK/doc.json" 2>"$WORK/doc.err" || rc=$?
  after="$(snap "$p")"
  [ "$rc" -eq 0 ] || bad "doctor exits 0 (advisory)" "exit $rc: $(head -2 "$WORK/doc.err")"
  [ "$before" = "$after" ] || bad "doctor changed nothing in the project"
}
status() { python3 -c "import json,sys
d=json.load(open('$WORK/doc.json'))
print(next((f['status'] for f in d['findings'] if f['id']=='$1'),'absent'))"; }
state() { python3 -c "import json;print(json.load(open('$WORK/doc.json'))['states']['$1'])"; }
expect() {  # expect <label> <id> <status>
  local got; got="$(status "$2")"
  [ "$got" = "$3" ] && ok "$1" || bad "$1" "$2 is $got, wanted $3"
}

echo "doctor.sh — what is still missing, and nothing that is not"

# ── A fresh sync: installed, intact, and not adopted ─────────────────────────

P="$(mktemp -d "$WORK/fresh.XXXXXX")"
bash "$STANDARD_DIR/tools/sync.sh" "$P" >/dev/null 2>&1
doctor "$P"
python3 -c "import json;d=json.load(open('$WORK/doc.json'));assert d['format']=='causeway-doctor-v1'" \
  && ok "--json is valid JSON in the documented format" \
  || bad "--json is valid JSON in the documented format"
[ "$(state installed)" = True ] && [ "$(state integrity)" = verified ] \
  && [ "$(state adoption)" = incomplete ] && [ "$(state evaluated)" = not-determined-by-doctor ] \
  && ok "a fresh sync is installed and intact, adoption incomplete, evaluation not claimed" \
  || bad "a fresh sync is installed and intact, adoption incomplete, evaluation not claimed"
fresh_incomplete="$(python3 -c "import json
print(' '.join(sorted(f['id'] for f in json.load(open('$WORK/doc.json'))['findings'] if f['status']=='incomplete')))")"
want="ci.drift gate.evaluator install.release placement.system_json reviewers.codeowners starter.CLAUDE.md starter.CONTRIBUTING.md starter.START-HERE.md starter.open_items starter.pull_request_template.md"
[ "$fresh_incomplete" = "$want" ] \
  && ok "a fresh sync is incomplete on exactly the ten things a sync cannot do" \
  || bad "a fresh sync is incomplete on exactly the ten things a sync cannot do" "got: $fresh_incomplete"
expect "branch protection is unverified, never passed" reviewers.required unverified
expect "required checks are unverified, never passed" ci.required unverified
python3 -c "import json
for f in json.load(open('$WORK/doc.json'))['findings']:
    if f['status']!='ok': assert f['subject'] and f['why'] and f['remedy'], f['id']" \
  && ok "every finding that is not ok names its subject, why, and a remedy" \
  || bad "every finding that is not ok names its subject, why, and a remedy"
bash "$P/tools/doctor.sh" "$P" > "$WORK/human.txt"
grep -q 'INCOMPLETE  system.json' "$WORK/human.txt" && grep -q 'evaluated:   not determined' "$WORK/human.txt" \
  && ok "the human report says the same, and does not claim a verdict" \
  || bad "the human report says the same, and does not claim a verdict"
[ ! -e "$P/system.json" ] && ok "doctor never writes a placement for you" \
  || bad "doctor never writes a placement for you"

# ── A deliberately configured project, installed from a signed release ───────

# shellcheck source=tools/lib-throwaway-release.sh
. "$STANDARD_DIR/tools/lib-throwaway-release.sh"
make_throwaway_release "$STANDARD_DIR" "$WORK/release" >/dev/null 2>&1
P="$(mktemp -d "$WORK/configured.XXXXXX")"
bash "$WORK/release/tree/causeway-$VERSION/tools/sync.sh" "$P" --require-release >/dev/null 2>&1
cat > "$P/system.json" <<'JSON'
{ "id": "lantern", "tier": "mission", "criticality_class": "C2",
  "criticality_authority": { "name": "Ada Ops", "role": "Service Owner", "declared": "2026-10-01" } }
JSON
printf '# Project: Lantern\n\n@AGENTS.md\n\n- **Gate evaluator:** none yet — evaluated by hand at review until an engine is chosen\n' > "$P/CLAUDE.md"
printf '# Contributing to Lantern\n' > "$P/CONTRIBUTING.md"
printf '# Lantern — start here\n' > "$P/START-HERE.md"
printf '## Lantern\n- [ ] tests\n' > "$P/.github/pull_request_template.md"
printf '* @lantern/engineering\n' > "$P/.github/CODEOWNERS"
printf '{ "registers": [] }\n' > "$P/decisions/open-items.json"
mkdir -p "$P/.github/workflows"
printf 'jobs:\n  drift:\n    steps:\n      - run: bash tools/check-drift.sh\n' > "$P/.github/workflows/ci.yml"
doctor "$P"
n_inc="$(python3 -c "import json;print(json.load(open('$WORK/doc.json'))['counts']['incomplete'])")"
[ "$n_inc" = 0 ] && [ "$(state adoption)" = complete-except-unverified ] \
  && ok "a configured project has nothing incomplete; the settings stay unverified" \
  || bad "a configured project has nothing incomplete; the settings stay unverified" \
         "$(python3 -c "import json;print([f['id'] for f in json.load(open('$WORK/doc.json'))['findings'] if f['status']=='incomplete'])")"
expect "a signed-release pin is recognized" install.release ok
grep -q 'Derived gate profile: G2' "$WORK/doc.json" \
  && ok "the gate profile is derived and reported (mission, C2 → G2)" \
  || bad "the gate profile is derived and reported (mission, C2 → G2)"
expect "the - [ ] checkbox in a PR template is not a placeholder" starter.pull_request_template.md ok

# ── One case per kind of finding ─────────────────────────────────────────────

C="$WORK/configured"; cp -a "$P" "$C"
reset() { rm -rf "$WORK/case"; cp -a "$C" "$WORK/case"; P="$WORK/case"; }

reset; printf '{ "tier": "core" }\n' > "$P/system.json"; doctor "$P"
expect "missing criticality is incomplete — a default is not a declaration" placement.criticality incomplete
grep -q 'criticality defaulted to C1' "$WORK/doc.json" \
  && ok "and the profile says it was derived from the C1 default" \
  || bad "and the profile says it was derived from the C1 default"

reset; printf '{ "tier": "platinum", "criticality_class": "C2" }\n' > "$P/system.json"; doctor "$P"
expect "an unknown tier is incomplete" placement.tier incomplete

reset; printf '{ "tier": "core", \n' > "$P/system.json"; doctor "$P"
expect "system.json that is not JSON is incomplete" placement.system_json incomplete

reset
printf '{ "tier": "core", "criticality_class": "C1", "criticality_authority": { "name": "A", "role": "Sponsor" } }\n' \
  > "$P/system.json"
doctor "$P"
expect "a class with no declared date has an incomplete authority" placement.authority incomplete

reset; printf '\n# local edit\n' >> "$P/gate/profiles.json"; doctor "$P"
expect "an edited vendored file fails integrity" install.integrity incomplete
[ "$(state integrity)" = failed ] && ok "and the integrity state says failed" \
  || bad "and the integrity state says failed"

reset; printf '# Project: Lantern\n' > "$P/CLAUDE.md"; doctor "$P"
expect "a CLAUDE.md that does not import the standard is incomplete" instructions.claude incomplete

reset; printf '* @ORG/ENGINEERING\n' > "$P/.github/CODEOWNERS"; doctor "$P"
expect "placeholder reviewers are incomplete" reviewers.codeowners incomplete

reset; printf 'jobs: {}\n' > "$P/.github/workflows/ci.yml"; doctor "$P"
expect "CI that does not run the drift check is incomplete" ci.drift incomplete

reset; sed -i 's/.*Gate evaluator.*/- **Gate evaluator:** [ENGINE AND VERSION]/' "$P/CLAUDE.md"; doctor "$P"
expect "a placeholder evaluator line is incomplete" gate.evaluator incomplete

# Without python3, system.json cannot be read: unverified, not passed.
NOPY="$(mktemp -d "$WORK/nopy.XXXXXX")"
for d in /usr/local/bin /usr/bin /bin; do
  for f in "$d"/*; do
    b="$(basename "$f")"; case "$b" in python*) continue ;; esac
    [ -e "$NOPY/$b" ] || ln -s "$f" "$NOPY/$b" 2>/dev/null || true
  done
done
reset; doctor "$P" env PATH="$NOPY"
expect "with no python3, placement is unverified rather than passed" placement.system_json unverified

E="$(mktemp -d "$WORK/empty.XXXXXX")"
cp "$STANDARD_DIR/tools/doctor.sh" "$WORK/doctor-standalone.sh"
bash "$WORK/doctor-standalone.sh" --json "$E" > "$WORK/doc.json"
[ "$(state installed)" = False ] && [ "$(state adoption)" = not-installed ] \
  && ok "a project with no lock is reported not installed" \
  || bad "a project with no lock is reported not installed"

if grep -nE '\b(curl|wget|gh|nc|ssh)\b[^-]|git (fetch|pull|clone|ls-remote)' "$STANDARD_DIR/tools/doctor.sh" \
   | grep -v '^[0-9]*:[[:space:]]*#' >/dev/null; then
  bad "doctor.sh calls nothing that reaches the network"
else
  ok "doctor.sh calls nothing that reaches the network"
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
