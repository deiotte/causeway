#!/usr/bin/env bash
# test-impact.sh — when a constraint changes, the decisions that rest on it are
# found, each with the reason and how sure the link is; the rest are not. ADR 0049.
#
#   ./tools/test-impact.sh
#
# The worked example. A project's Survey has two constraints:
#
#   GR-1  Deploy only inside the on-prem enclave     binds DEC-1, DEC-2
#   GR-2  Keep audit records for seven years         binds DEC-3
#
# and its decisions rest on them in every way the tool distinguishes:
#
#   0001  hosting            DEC-1, forces [GR-1]            direct
#   0002  secrets store      DEC-2 (Survey says GR-1)        direct, via the Survey; corrected by 0008
#   0003  retention store    DEC-3, forces [GR-2]            unaffected by GR-1
#   0004  log pipeline       DEC-4, depends on DEC-1         indirect
#   0005  backups            no forces; mentions GR-1        inferred
#   0006  cache              forces [GR-1], superseded by 0007
#
# GR-1 is then "changed" — a cloud region is newly permitted — and the tool must
# name 0001, 0002, 0004, 0005 and 0006 (pointing at 0007), each at the right
# level, and leave 0003 alone. Offline.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }
snap() { ( cd "$1" && find . -type f -exec sha256sum {} + | LC_ALL=C sort -k2 ); }

P="$WORK/project"; mkdir -p "$P/decisions" "$P/docs"
cp "$STANDARD_DIR/tools/impact.sh" "$WORK/impact.sh"

cat > "$P/docs/survey.md" <<'MD'
# Survey — Lantern

## S1 Ground

| ID | Constraint | Source | Verified how | Binds |
|---|---|---|---|---|
| GR-1 | Deploy only inside the on-prem enclave | ATO boundary | read the ATO letter | DEC-1, DEC-2 |
| GR-2 | Keep audit records for seven years | Records schedule | counsel confirmed | DEC-3 |

## S2.1 Capabilities

| ID | Capability | Actor | Trigger | Success is | Volume/rate | Priority |
|---|---|---|---|---|---|---|
| LD-1 | Ship logs to the SOC | ops | every event | under 5 min | 2k/s | must |

## S3.1 Invariants

| ID | Invariant | Enforced where | Checked how |
|---|---|---|---|
| IV-1 | Key material never leaves the HSM in clear | HSM policy | quarterly audit |

## S4.2 Decision inventory

| ID | Decision | Alternatives | Forces (spec IDs) | Spine row | Door | Depends on | Verdict | ADR |
|---|---|---|---|---|---|---|---|---|
| DEC-1 | Hosting | VMs, k8s | GR-1 | SA-4.7 | one-way | — | READY | ADR-0001 |
| DEC-2 | Secrets store | Vault, HSM | IV-1 | SA-5.7 | one-way | — | READY | ADR-0002 |
| DEC-3 | Retention store | WORM, S3 | GR-2 | SA-6.1 | one-way | — | READY | ADR-0003 |
| DEC-4 | Log pipeline | Fluent, Vector | LD-1 | SA-7.2 | two-way | DEC-1 | READY | ADR-0004 |
MD

adr() {  # adr <num> <title> <status> <forces> <survey_rows> <revisit_if> [extra frontmatter] [body]
  cat > "$P/decisions/$1-$(echo "$2" | tr ' A-Z' '-a-z').md" <<MD
---
adr: "$1"
title: $2
status: $3
date: 2026-09-01
spine_rows: [SA-0.0]
survey_rows: $5
forces: $4
door: two-way
revisit_if: $6
${7:-}
---

## Context

${8:-Nothing more.}
MD
}
adr 0001 "Host on enclave VMs" Accepted "[GR-1]" "[DEC-1]" "A cloud region is approved for this system"
adr 0002 "Keep secrets in the enclave HSM" Accepted "[IV-1]" "[DEC-2]" "The HSM leaves the enclave" "corrected_by: [\"0008\"]"
adr 0003 "Retain audit records on WORM storage" Accepted "[GR-2]" "[DEC-3]" "The records schedule changes"
adr 0004 "Ship logs with Vector" Accepted "[LD-1]" "[DEC-4]" "The SOC changes intake"
adr 0005 "Back up to the second enclave rack" Accepted "[]" "[]" "Rack two is retired" "" \
  "Written before forces existed. Backups stay on-prem because of GR-1."
adr 0006 "Cache in Redis on the VMs" Superseded "[GR-1]" "[]" "Memory pressure" "superseded_by: \"0007\""
adr 0007 "Cache in-process" Accepted "[]" "[]" "Instances exceed four"
adr 0008 "Correct the HSM model number in 0002" Accepted "[]" "[]" "Never" "corrects: [\"0002\"]"

run() { bash "$WORK/impact.sh" --json "$@" "$P" > "$WORK/out.json"; }
level_of() { python3 -c "import json
d=json.load(open('$WORK/out.json'))
print(next((e['level'] for r in d['impact'] if r['id']=='$1' for e in r['adrs'] if e['adr']=='$2'), 'absent'))"; }
field_of() { python3 -c "import json
d=json.load(open('$WORK/out.json'))
e=next(e for r in d['impact'] if r['id']=='$1' for e in r['adrs'] if e['adr']=='$2')
print(e.get('$3'))"; }

echo "impact.sh — which decisions to re-read when a constraint changes"

before="$(snap "$P")"
run GR-1
[ "$before" = "$(snap "$P")" ] && ok "it changes nothing — no ADR is superseded or edited" \
  || bad "it changes nothing — no ADR is superseded or edited"
python3 -c "import json;assert json.load(open('$WORK/out.json'))['format']=='causeway-impact-v1'" \
  && ok "--json is the documented format" || bad "--json is the documented format"

[ "$(level_of GR-1 0001)" = direct ] && ok "0001 cites GR-1 in forces: direct" \
  || bad "0001 cites GR-1 in forces: direct" "$(level_of GR-1 0001)"
[ "$(level_of GR-1 0002)" = direct ] && ok "0002 cites only IV-1, but came from DEC-2, which GR-1 binds: direct, via the Survey" \
  || bad "0002 cites only IV-1, but came from DEC-2, which GR-1 binds: direct, via the Survey" "$(level_of GR-1 0002)"
[ "$(level_of GR-1 0004)" = indirect ] && ok "0004 came from DEC-4, which depends on DEC-1: indirect" \
  || bad "0004 came from DEC-4, which depends on DEC-1: indirect" "$(level_of GR-1 0004)"
[ "$(level_of GR-1 0005)" = inferred ] && ok "0005 only mentions GR-1 in prose: inferred, and labelled uncertain" \
  || bad "0005 only mentions GR-1 in prose: inferred, and labelled uncertain" "$(level_of GR-1 0005)"
[ "$(level_of GR-1 0003)" = absent ] && ok "0003 rests on GR-2 alone and is left out" \
  || bad "0003 rests on GR-2 alone and is left out" "$(level_of GR-1 0003)"
[ "$(field_of GR-1 0001 revisit_if)" = "A cloud region is approved for this system" ] \
  && ok "each affected ADR shows its revisit_if" || bad "each affected ADR shows its revisit_if"
[ "$(field_of GR-1 0006 read_instead)" = 0007 ] && ok "a superseded ADR points at the record in force (0006 → 0007)" \
  || bad "a superseded ADR points at the record in force (0006 → 0007)"
[ "$(field_of GR-1 0002 corrected_by)" = "['0008']" ] && ok "a corrected ADR is named with its correction" \
  || bad "a corrected ADR is named with its correction"
python3 -c "import json
d=json.load(open('$WORK/out.json'))
e=next(e for e in d['impact'][0]['adrs'] if e['adr']=='0002')
assert any('DEC-2' in w and 'binds' in w for w in e['why'])" \
  && ok "every relationship says why it holds" || bad "every relationship says why it holds"

run GR-2
python3 -c "import json
d=json.load(open('$WORK/out.json'));assert [e['adr'] for e in d['impact'][0]['adrs']]==['0003']" \
  && ok "the unrelated constraint GR-2 reaches 0003 and nothing else" \
  || bad "the unrelated constraint GR-2 reaches 0003 and nothing else"

run GR-1 GR-2
[ "$(python3 -c "import json;print(len(json.load(open('$WORK/out.json'))['impact']))")" = 2 ] \
  && ok "several changed constraints are reported one by one" || bad "several changed constraints are reported one by one"

bash "$WORK/impact.sh" GR-1 "$P" > "$WORK/human.txt"
grep -q '\[  direct\] ADR 0001' "$WORK/human.txt" && grep -q '\[inferred\] ADR 0005' "$WORK/human.txt" \
  && grep -q 'Nothing was changed' "$WORK/human.txt" \
  && ok "the human report labels every level and says nothing changed" \
  || bad "the human report labels every level and says nothing changed"

# ── What it cannot see, and what points nowhere ──────────────────────────────

run --check
[ "$(python3 -c "import json;print(json.load(open('$WORK/out.json'))['unlinked_accepted_adrs'])")" = "['0005', '0007', '0008']" ] \
  && ok "accepted ADRs with no structured reference are counted, not guessed at" \
  || bad "accepted ADRs with no structured reference are counted, not guessed at"
[ "$(python3 -c "import json;print(len(json.load(open('$WORK/out.json'))['broken']))")" = 0 ] \
  && ok "a consistent record has no broken references" || bad "a consistent record has no broken references"

adr 0009 "Pick a queue" Accepted "[GR-9]" "[DEC-9]" "Load doubles"
printf '| DEC-5 | Metrics | a, b | GR-1 | SA-7.1 | two-way | — | READY | ADR-0099 |\n' >> "$P/docs/survey.md"
sed -i 's/^superseded_by: "0007"/superseded_by: "0077"/' "$P/decisions/0006-cache-in-redis-on-the-vms.md"
run --check
for want in "forces cites GR-9" "survey_rows cites DEC-9" "names ADR 0099" "points at ADR 0077"; do
  python3 -c "import json,sys
d=json.load(open('$WORK/out.json'));sys.exit(0 if any('$want' in b['problem'] for b in d['broken']) else 1)" \
    && ok "broken reference found: $want" || bad "broken reference found: $want"
done

# Without a Survey, frontmatter and text still work; Survey-only links do not.
mv "$P/docs/survey.md" "$WORK/survey.md"
run GR-1
[ "$(level_of GR-1 0001)" = direct ] && [ "$(level_of GR-1 0002)" = absent ] \
  && ok "with no Survey, forces still count and Survey-only links are honestly absent" \
  || bad "with no Survey, forces still count and Survey-only links are honestly absent"
run GR-1 --survey "$WORK/survey.md"
[ "$(level_of GR-1 0002)" = direct ] && ok "--survey names a Survey kept somewhere else" \
  || bad "--survey names a Survey kept somewhere else"

bash "$WORK/impact.sh" "$P" >/dev/null 2>&1 && bad "no ID and no --check is a usage error" \
  || ok "no ID and no --check is a usage error"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
