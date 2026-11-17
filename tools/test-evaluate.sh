#!/usr/bin/env bash
# test-evaluate.sh — the reference evaluator matches every conformance fixture,
# counts spine coverage the way the spine defines it, and never reports a check it
# cannot run as anything but unsupported. ADR 0063.
#
#   ./tools/test-evaluate.sh
#
# Two halves. The conformance fixtures are the standard's own arbiter, so the
# first assertion is that all of them match. The rest run against a synthetic
# C3 project (G0 or G2 by tier) built here, so each closure count is known in
# advance from the spine table rather than read back from the tool. Offline.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
EVAL=(python3 -I "$STANDARD_DIR/tools/evaluate.py" --standard "$STANDARD_DIR")

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }
jq_() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))" "$@"; }

echo "evaluate.py — a slice of the gate, honestly labelled"

if out="$("${EVAL[@]}" --conform 2>&1)"; then
  ok "every conformance fixture matches expectations.json"
else
  bad "every conformance fixture matches expectations.json" "$(echo "$out" | grep -A3 FAIL | head -12)"
fi

# The spine's own numbers, derived independently of evaluate.py.
SPINE="$STANDARD_DIR/skills/decision-spine/reference/spine.md"
read -r N_SHORT N_ONEWAY <<<"$(python3 - "$SPINE" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read().split("## SA-1 · ", 1)[1].split("## The one-way doors", 1)[0]
rows = re.findall(r"^\|\s*SA-\d+\.\d+\s*(?:†\s*)?\|[^|]*\|[^|]*\|\s*([YN])\s*\|\s*(C1(?:[–-]C[23])?)\s*\|", t, re.M)
print(sum(1 for _, a in rows if a in ("C1–C3", "C1-C3")), sum(1 for y, _ in rows if y == "Y"))
PY
)"

P="$WORK/project"; mkdir -p "$P/decisions"
cat > "$P/system.json" <<'JSON'
{ "tier": "operational", "criticality_class": "C3", "composition-state": "wrapped",
  "spine": { "closed_against": "0.8" } }
JSON
printf 'version=3.0.0\nreleased=2026-11-01\n' > "$P/.causeway-lock"
cat > "$P/decisions/0001-run-on-the-fabric.md" <<'MD'
---
adr: "0001"
title: Run on the accredited fabric
status: Accepted
date: 2026-11-02
spine_rows: [SA-1.1, SA-4.1]
forces: [GR-1]
---
Runs where GR-1 says.
MD
cat > "$P/decisions/0002-waive-sa-1-11.md" <<'MD'
---
adr: "0002"
title: Waive SA-1.11
status: Waived
date: 2026-11-02
spine_rows: [SA-1.11]
waiver:
  expires: 2027-01-01
  accepted_by:
    name: Dana Reyes
    role: ISSM
---
Not now.
MD
cat > "$P/decisions/0003-still-proposed.md" <<'MD'
---
adr: "0003"
title: Not accepted yet
status: Proposed
date: 2026-11-02
spine_rows: [SA-2.1]
---
Proposed closes nothing.
MD

"${EVAL[@]}" "$P" --date 2026-11-17 --json > "$WORK/r.json" || true
[ "$(jq_ "$WORK/r.json" 'd["profile"]')" = G0 ] \
  && ok "the profile is derived from tier and class (operational · C3 → G0)" \
  || bad "the profile is derived from tier and class" "$(jq_ "$WORK/r.json" 'd.get("profile")')"

sf="$(jq_ "$WORK/r.json" 'd["checks"]["shortform-closure"]["evidence"]')"
want_scope="$N_SHORT"
python3 - "$WORK/r.json" "$N_SHORT" <<'PY' && ok "short form: in scope from the spine table, Accepted closes, Waived is waived, Proposed is open" || bad "short-form closure counts" "$sf"
import json, sys
ev = json.load(open(sys.argv[1]))["checks"]["shortform-closure"]["evidence"]
assert ev["rows_in_scope"] == int(sys.argv[2]), ev
assert ev["rows_closed"] == 2, ev                      # SA-1.1 and SA-4.1
assert ev["rows_waived"] == ["SA-1.11"], ev
assert "SA-2.1" in ev["open_rows"] and "SA-1.1" not in ev["open_rows"], ev
assert len(ev["open_rows"]) == int(sys.argv[2]) - 3, ev
PY

[ "$(jq_ "$WORK/r.json" 'd["checks"]["oneway-closure"]["evidence"]["rows_in_scope"]')" = "$N_ONEWAY" ] \
  && ok "one-way closure scopes every one-way row ($N_ONEWAY)" \
  || bad "one-way closure scopes every one-way row" "$(jq_ "$WORK/r.json" 'd["checks"]["oneway-closure"]["evidence"]')"

[ "$(jq_ "$WORK/r.json" 'd["checks"]["shortform-closure"]["verdict"]')" = fail ] \
  && [ "$(jq_ "$WORK/r.json" 'd["checks"]["oneway-closure"]["verdict"]')" = advisory ] \
  && [ "$(jq_ "$WORK/r.json" 'd["checks"]["class-scoped-closure"]["verdict"]')" = not_run ] \
  && ok "the profile cell decides the verdict: block → fail, warn → advisory, skip → not_run" \
  || bad "the profile cell decides the verdict" "$(jq_ "$WORK/r.json" '{k: v["verdict"] for k, v in d["checks"].items()}')"

bad_v="$(jq_ "$WORK/r.json" '[k for k, v in d["checks"].items() if k not in ("standard-currency","named-approvers","dependency-provenance","composition-state","install-scripts","shortform-closure","oneway-closure","class-scoped-closure") and v["verdict"] not in ("unsupported","not_run")]')"
[ "$bad_v" = "[]" ] \
  && ok "a check this file does not implement is unsupported or not run, never pass" \
  || bad "a check this file does not implement is unsupported or not run, never pass" "$bad_v"

[ "$(jq_ "$WORK/r.json" 'd["exit_code"]')" = 4 ] \
  && ok "a blocking check it cannot run makes the run exit 4, as gate-configuration §8 says" \
  || bad "a blocking check it cannot run makes the run exit 4" "$(jq_ "$WORK/r.json" 'd["exit_code"]')"

"${EVAL[@]}" "$P" --date 2026-11-17 --advisory >/dev/null \
  && ok "--advisory reports the same and exits 0, for a warn cycle in CI" \
  || bad "--advisory reports the same and exits 0"

"${EVAL[@]}" "$P" --date 2026-11-17 --coverage > "$WORK/cov.txt"
grep -q "shortform-closure.*2/$N_SHORT closed, 1 waived" "$WORK/cov.txt" \
  && ok "--coverage prints closed/in-scope per closure check" \
  || bad "--coverage prints closed/in-scope per closure check" "$(cat "$WORK/cov.txt")"

# An expired waiver is an open row and exit 2 where the check blocks.
sed -i 's/expires: 2027-01-01/expires: 2026-11-01/' "$P/decisions/0002-waive-sa-1-11.md"
"${EVAL[@]}" "$P" --date 2026-11-17 --json > "$WORK/r2.json" || true
python3 - "$WORK/r2.json" <<'PY' && ok "an expired waiver reopens its row and is reported as one" || bad "an expired waiver reopens its row"
import json, sys
ev = json.load(open(sys.argv[1]))["checks"]["shortform-closure"]["evidence"]
assert "SA-1.11" in ev["open_rows"] and ev.get("expired_waivers") == ["SA-1.11"], ev
PY

# An older closed_against needs the adoption-horizon arithmetic this file does
# not implement: unsupported, with the reason, and the counts still reported.
sed -i 's/"closed_against": "0.8"/"closed_against": "0.6"/' "$P/system.json"
"${EVAL[@]}" "$P" --date 2026-11-17 --json > "$WORK/r3.json" || true
python3 - "$WORK/r3.json" <<'PY' && ok "an older closed_against is unsupported, not guessed, and still counted" || bad "an older closed_against is unsupported"
import json, sys
c = json.load(open(sys.argv[1]))["checks"]["shortform-closure"]
assert c["verdict"] == "unsupported" and "open item 12" in c["evidence"]["reason"], c
assert c["evidence"]["rows_closed"] == 2, c
PY

rm "$P/system.json"
"${EVAL[@]}" "$P" --date 2026-11-17 >/dev/null 2>&1 && rc=0 || rc=$?
[ "$rc" = 4 ] && ok "no system.json is a configuration error, exit 4" \
  || bad "no system.json is a configuration error, exit 4" "exit $rc"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
