#!/usr/bin/env bash
# test-check-register.sh — the register check passes a record that ties, and
# names each way one does not. ADR 0067.
#
#   ./tools/test-check-register.sh
#
# Builds a small consuming project whose record ties, proves it passes, then
# breaks it one way at a time and asserts the exit code and the message. Each
# break is one the check exists for; a break that stopped being reported would
# be a check that quietly stopped checking. Offline.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CHECK=(python3 -I "$STANDARD_DIR/tools/check-register.py" --standard "$STANDARD_DIR")

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

echo "check-register.py — the decision record ties, or says where it does not"

# ── A project whose record ties ──────────────────────────────────────────────
base() {
  local P="$1"
  rm -rf "$P"; mkdir -p "$P/decisions"
  cat > "$P/CLAUDE.md" <<'MD'
# A project

## Open items

1. **Pick the queue.** Waiting on load numbers.
MD
  cat > "$P/decisions/0001-run-on-the-fabric.md" <<'MD'
---
adr: "0001"
title: Run on the accredited fabric
status: Superseded
date: 2026-11-02
spine_rows: [SA-1.1, SA-4.1]
supersedes:
superseded_by: "0003"
supersession_cause:
corrects: []
corrected_by: ["0002"]
---
Runs where GR-1 says.
MD
  cat > "$P/decisions/0002-correct-the-region-count.md" <<'MD'
---
adr: "0002"
title: Correct the region count in 0001
status: Accepted
date: 2026-11-03
spine_rows: []
corrects: ["0001"]
corrected_by: []
---
Two regions, not three.
MD
  cat > "$P/decisions/0003-run-on-the-second-fabric.md" <<'MD'
---
adr: "0003"
title: Run on the second fabric
status: Accepted
date: 2026-11-04
spine_rows: [SA-1.1, SA-4.1]
supersedes: "0001"
superseded_by:
supersession_cause: S3   # a ground constraint nobody had written down
corrects: []
corrected_by: []
---
The first fabric lost its enclave.
MD
  cat > "$P/decisions/README.md" <<'MD'
# Decisions

## Index

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-run-on-the-fabric.md) | Run on the accredited fabric | Superseded |
| [0002](0002-correct-the-region-count.md) | Correct the region count | Accepted |
| [0003](0003-run-on-the-second-fabric.md) | Run on the second fabric | Accepted |

## Unused numbers

None yet.
MD
  cat > "$P/decisions/open-items.json" <<'JSON'
{
  "registers": { "project": { "document": "CLAUDE.md", "section": "Open items" } },
  "items": [
    { "id": "project-1", "register": "project", "number": 1, "title": "Pick the queue",
      "status": "open", "opened_by": "0003", "closed_by": null, "blocked_on": ["load-numbers"] }
  ],
  "counts": { "open": 1, "closed": 0, "total": 1 },
  "blockers": { "load-numbers": "Nobody has measured peak load yet." }
}
JSON
}

P="$WORK/p"
base "$P"
if out="$("${CHECK[@]}" "$P" 2>&1)"; then
  if echo "$out" | grep -q "the record ties"; then ok "a record that ties passes, with no warnings"
  else bad "a record that ties passes, with no warnings" "$out"; fi
else
  bad "a record that ties exits 0" "$out"
fi

json="$("${CHECK[@]}" "$P" --json)"
if python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["format"]=="causeway-register-v1" and d["adrs"]==3 and d["open_items"]=={"open":1,"closed":0,"total":1} and d["exit_code"]==0' "$json"; then
  ok "--json reports the ADR count and the derived open-item counts"
else
  bad "--json reports the ADR count and the derived open-item counts" "$json"
fi

# ── One break at a time. Each: a description, a mutation, the expected exit,
#    and a phrase the message must carry. ─────────────────────────────────────
expect() {
  local desc="$1" want_exit="$2" phrase="$3"; shift 3
  base "$P"
  ( cd "$P" && eval "$@" )
  local out code=0
  out="$("${CHECK[@]}" "$P" 2>&1)" || code=$?
  if [ "$code" -eq "$want_exit" ] && echo "$out" | grep -qF -- "$phrase"; then
    ok "$desc"
  else
    bad "$desc" "exit $code (wanted $want_exit); output: $(echo "$out" | tail -4)"
  fi
}

expect "an ADR with no frontmatter is a violation" 1 "the gate reads frontmatter" \
  'printf "# Just prose\n" > decisions/0004-prose.md; echo "| [0004](0004-prose.md) |" >> decisions/README.md'
expect "an unquoted number is named as the octal trap" 1 "YAML reads 0010 as 8" \
  "sed -i 's/^adr: \"0002\"/adr: 0002x/' decisions/0002-correct-the-region-count.md"
expect "an adr field that disagrees with the filename is a violation" 1 "but the filename says 0002" \
  "sed -i 's/^adr: \"0002\"/adr: \"0009\"/' decisions/0002-correct-the-region-count.md"
expect "a status outside the six is a violation" 1 "is not one of Proposed" \
  "sed -i 's/^status: Accepted/status: Approved/' decisions/0002-correct-the-region-count.md"
expect "a row the spine does not have is a violation" 1 "SA-99.1 is not a row in the vendored spine" \
  "sed -i 's/^spine_rows: \[\]/spine_rows: [SA-99.1]/' decisions/0002-correct-the-region-count.md"
expect "a supersession named one way only is a violation" 1 "does not name 0003 in superseded_by" \
  "sed -i 's/^superseded_by: \"0003\"/superseded_by:/; s/^status: Superseded/status: Accepted/' decisions/0001-run-on-the-fabric.md"
expect "a superseded_by on a record still Accepted is a violation" 1 "not Superseded" \
  "sed -i 's/^status: Superseded/status: Accepted/' decisions/0001-run-on-the-fabric.md"
expect "a supersession with no cause is a violation" 1 "must be one of S1–S5" \
  "sed -i 's/^supersession_cause: S3.*/supersession_cause:/' decisions/0003-run-on-the-second-fabric.md"
expect "a supersession that drops a row is a violation" 1 "drops its rows ['SA-4.1']" \
  "sed -i 's/^spine_rows: \[SA-1.1, SA-4.1\]/spine_rows: [SA-1.1]/' decisions/0003-run-on-the-second-fabric.md"
expect "a correction named one way only is a violation" 1 "does not list 0002 in corrected_by" \
  "sed -i 's/^corrected_by: \[\"0002\"\]/corrected_by: []/' decisions/0001-run-on-the-fabric.md"
expect "an open item naming an ADR nobody wrote is a violation" 1 "opened_by names ADR 0042" \
  "sed -i 's/\"opened_by\": \"0003\"/\"opened_by\": \"0042\"/' decisions/open-items.json"
expect "a count nobody recomputed is a violation" 1 "counts say" \
  "sed -i 's/\"open\": 1, \"closed\": 0, \"total\": 1/\"open\": 2, \"closed\": 0, \"total\": 2/' decisions/open-items.json"
expect "an item closed by nothing is a violation" 1 "closed by nothing" \
  "sed -i 's/\"status\": \"open\"/\"status\": \"closed\"/; s/\"open\": 1, \"closed\": 0/\"open\": 0, \"closed\": 1/' decisions/open-items.json"
expect "a register whose heading moved is a violation" 1 "no longer has" \
  "sed -i 's/^## Open items/## Backlog/' CLAUDE.md"
expect "a blocker nothing declares is a violation" 1 "which blockers does not declare" \
  "sed -i 's/\"load-numbers\"\]/\"budget\"]/' decisions/open-items.json"

expect "a skipped number with no Unused line is a warning, not a failure" 0 "0004 is skipped" \
  "sed 's/^adr: \"0003\"/adr: \"0005\"/' decisions/0003-run-on-the-second-fabric.md > decisions/0005-x.md; echo '| [0005](0005-x.md) |' >> decisions/README.md; sed -i 's/^spine_rows: .*/spine_rows: []/; s/^supersedes: .*/supersedes:/' decisions/0005-x.md"
expect "an ADR missing from the index is a warning" 0 "has no row linking 0002" \
  "sed -i '/0002-correct/d' decisions/README.md"
expect "two live ADRs on one row is a warning" 0 "SA-1.1 is also closed by ADR 0002" \
  "sed -i 's/^spine_rows: \[\]/spine_rows: [SA-1.1]/' decisions/0002-correct-the-region-count.md"
expect "an item that lapsed with no reason is a violation" 1 "lapsed must say why" \
  "sed -i 's/\"status\": \"open\"/\"status\": \"closed\", \"lapsed\": \"\"/; s/\"open\": 1, \"closed\": 0/\"open\": 0, \"closed\": 1/' decisions/open-items.json"
expect "an open item that says it lapsed is a violation" 1 "says it lapsed but is open" \
  "sed -i 's/\"status\": \"open\"/\"status\": \"open\", \"lapsed\": \"Nobody needs a queue now.\"/' decisions/open-items.json"
expect "an item that lapsed and names a closing ADR is a violation" 1 "it closed or it lapsed" \
  "sed -i 's/\"status\": \"open\"/\"status\": \"closed\", \"lapsed\": \"Nobody needs a queue now.\"/; s/\"closed_by\": null/\"closed_by\": \"0003\"/; s/\"open\": 1, \"closed\": 0/\"open\": 0, \"closed\": 1/' decisions/open-items.json"

expect "the template's example left in the index is a warning" 0 "REPLACE example" \
  "sed -i 's/\"Pick the queue\"/\"REPLACE — delete this example\"/' decisions/open-items.json"

# ── Records that tie, written the ways people write them ────────────────────
clean() {
  local desc="$1"; shift
  base "$P"
  ( cd "$P" && eval "$@" )
  local out code=0
  out="$("${CHECK[@]}" "$P" 2>&1)" || code=$?
  if [ "$code" -eq 0 ] && echo "$out" | grep -q "the record ties"; then ok "$desc"
  else bad "$desc" "exit $code; output: $(echo "$out" | tail -4)"; fi
}

skip_to_0009() {
  sed 's/^adr: "0003"/adr: "0009"/; s/^spine_rows: .*/spine_rows: []/; s/^supersedes: .*/supersedes:/' \
    decisions/0003-run-on-the-second-fabric.md > decisions/0009-x.md
  echo '| [0009](0009-x.md) |' >> decisions/README.md
}
clean "a range under Unused numbers covers every number in it (0004 to 0008)" \
  "skip_to_0009; sed -i 's/^None yet\./0004 to 0008: written elsewhere before adoption./' decisions/README.md"
clean "a range with a dash covers every number in it (0004-0008)" \
  "skip_to_0009; sed -i 's/^None yet\./0004–0008 were never written./' decisions/README.md"
clean "single numbers and a range mix (0004, 0005 and 0006 to 0008)" \
  "skip_to_0009; sed -i 's/^None yet\./0004, 0005 and 0006 to 0008 were never written./' decisions/README.md"
expect "a range that stops short still warns on the number past it" 0 "0008 is skipped" \
  "skip_to_0009; sed -i 's/^None yet\./0004 to 0007 were never written./' decisions/README.md"
clean "a closed item that says why it lapsed ties" \
  "sed -i 's/\"status\": \"open\"/\"status\": \"closed\", \"lapsed\": \"The queue was retired with the service.\"/; s/\"open\": 1, \"closed\": 0/\"open\": 0, \"closed\": 1/' decisions/open-items.json"
clean "a correction that restates the rows of the record it corrects is not a duplicate" \
  "sed -i 's/^status: Superseded/status: Accepted/; s/^superseded_by: \"0003\"/superseded_by:/' decisions/0001-run-on-the-fabric.md; sed -i 's/^spine_rows: \[\]/spine_rows: [SA-1.1, SA-4.1]/' decisions/0002-correct-the-region-count.md; rm decisions/0003-run-on-the-second-fabric.md; sed -i '/0003-run/d' decisions/README.md; sed -i 's/\"opened_by\": \"0003\"/\"opened_by\": \"0001\"/' decisions/open-items.json"

base "$P"; sed -i '/0002-correct/d' "$P/decisions/README.md"
code=0; "${CHECK[@]}" "$P" --strict >/dev/null 2>&1 || code=$?
[ "$code" -eq 1 ] && ok "--strict makes a warning fail" || bad "--strict makes a warning fail" "exit $code"

code=0; "${CHECK[@]}" "$WORK/nowhere" >/dev/null 2>&1 || code=$?
[ "$code" -eq 4 ] && ok "a directory with no decisions/ is a configuration error (4)" \
  || bad "a directory with no decisions/ is a configuration error (4)" "exit $code"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
