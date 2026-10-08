#!/usr/bin/env bash
# test-field-notes.sh — the field-note queue shows who owes whom an answer, and
# never calls a disposition done without its evidence. ADR 0048.
#
#   ./tools/test-field-notes.sh
#
# "Today" is pinned with CAUSEWAY_TODAY so every age below is exact. Offline.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export CAUSEWAY_TODAY=2026-10-08

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok    $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }
snap() { ( cd "$1" && find . -printf '%y %p\n' | LC_ALL=C sort \
           && find . -type f -exec sha256sum {} + | LC_ALL=C sort -k2 ); }

P="$WORK/project"; mkdir -p "$P"
bash "$STANDARD_DIR/tools/sync.sh" "$P" >/dev/null 2>&1

# note <number> <status> <date> [header lines...] — a note from the template.
note() {
  local num="$1" status="$2" date="$3" f="$P/domain/field-notes/$1-note.md"; shift 3
  sed -e "s/^note: \"0000\".*/note: \"$num\"/" -e "s/^date: YYYY-MM-DD/date: $date/" \
      -e "s/^title: .*/title: Note $num/" -e "s/^status: new .*/status: $status/" \
      "$STANDARD_DIR/templates/field-note.md" > "$f"
  local line; for line in "$@"; do
    python3 - "$f" "$line" <<'PY'
import sys, re
path, line = sys.argv[1], sys.argv[2]
key = line.split(":", 1)[0]
text = open(path).read()
head, rest = text.split("\n---\n", 1)
lines = head.split("\n")
# replace the key (and any indented children) or append before the closing ---
out, skip, done = [], False, False
for l in lines:
    if skip and (l.startswith("  ") or not l.strip()):
        continue
    skip = False
    if re.match(rf"^{re.escape(key)}:", l) and not done:
        out.extend(line.split("\\n")); done = True; skip = True
        continue
    out.append(l)
if not done:
    out.extend(line.split("\\n"))
open(path, "w").write("\n".join(out) + "\n---\n" + rest)
PY
  done
}
fn() { bash "$P/tools/field-notes.sh" --json "$@" "$P" > "$WORK/fn.json"; }
q() { python3 -c "import json;d=json.load(open('$WORK/fn.json'));print($1)"; }
has_problem() { python3 -c "import json,sys;d=json.load(open('$WORK/fn.json'))
sys.exit(0 if any(p['note']=='$1' and '$2' in p['problem'] for p in d['problems']) else 1)"; }

echo "field-notes.sh — who owes which practitioner an answer"

fn
[ "$(q "d['numbers']['notes']")" = 0 ] && [ "$(q "d['format']")" = causeway-field-notes-v1 ] \
  && ok "an empty register is empty, in the documented format" \
  || bad "an empty register is empty, in the documented format"

# ── The queue ────────────────────────────────────────────────────────────────

note 0001 new 2026-09-18
note 0002 in-review 2026-09-28 "owner: Bob Rivera" "next_action: Draft the test with Ana"
before="$(snap "$P")"
fn
[ "$before" = "$(snap "$P")" ] && ok "reading the queue changes nothing" || bad "reading the queue changes nothing"
[ "$(q "[n['note'] for n in d['queue']]")" = "['0001', '0002']" ] \
  && ok "open notes are queued oldest first" || bad "open notes are queued oldest first" "$(q "[n['note'] for n in d['queue']]")"
[ "$(q "d['queue'][0]['age_days']")" = 20 ] && [ "$(q "d['queue'][0]['owner']")" = "" ] \
  && [ "$(q "d['numbers']['unassigned']")" = 1 ] \
  && ok "a new note shows its age (20 days) and that nobody owns it" \
  || bad "a new note shows its age (20 days) and that nobody owns it"
[ "$(q "d['queue'][1]['next_action']")" = "Draft the test with Ana" ] \
  && ok "an owned note shows its owner's next action" || bad "an owned note shows its owner's next action"
[ "$(q "d['numbers']['overdue']")" = None ] \
  && ok "with no response target chosen, nothing is overdue — ages only" \
  || bad "with no response target chosen, nothing is overdue — ages only"

mkdir -p "$P/.causeway"; printf '{ "respond_within_days": 14 }\n' > "$P/.causeway/field-notes.json"
fn
[ "$(q "d['numbers']['overdue']")" = 1 ] && [ "$(q "d['queue'][0]['overdue']")" = True ] \
  && ok "against the project's 14-day target, the 20-day note is overdue" \
  || bad "against the project's 14-day target, the 20-day note is overdue"
fn --target-days 30
[ "$(q "d['numbers']['overdue']")" = 0 ] && ok "--target-days overrides the project's target" \
  || bad "--target-days overrides the project's target"

note 0001 in-review 2026-09-18 "owner: Cy Park"
fn
[ "$(q "d['queue'][0]['owner']")" = "Cy Park" ] && [ "$(q "d['queue'][0]['age_days']")" = 20 ] \
  && [ "$(q "d['queue'][0]['overdue']")" = True ] \
  && ok "a reassigned note shows its new owner, and reassigning does not reset its clock" \
  || bad "a reassigned note shows its new owner, and reassigning does not reset its clock"

# ── Dispositions ─────────────────────────────────────────────────────────────

GOOD_DISP='disposition:\n  outcome: test\n  landed_at: tests/cold_start_test.go\n  date: 2026-09-25'
GOOD_TOLD='author_told:\n  date: 2026-09-26\n  evidence: https://example.invalid/issues/12#comment-3'
note 0003 promoted 2026-09-15 "owner: Bob Rivera" "$GOOD_DISP" "$GOOD_TOLD" "effort_minutes: 45"
fn
has_problem 0003 "" && bad "a disposition with outcome, place, date and a told-with-evidence has no problem" \
  || ok "a disposition with outcome, place, date and a told-with-evidence has no problem"
[ "$(q "d['numbers']['median_days_to_disposition']")" = 10 ] \
  && [ "$(q "d['numbers']['authors_told_with_evidence']")" = 1 ] \
  && [ "$(q "d['numbers']['reviewer_minutes']")" = 45 ] \
  && ok "it counts: 10 days to disposition, author told with evidence, 45 reviewer minutes" \
  || bad "it counts: 10 days to disposition, author told with evidence, 45 reviewer minutes"

note 0004 closed 2026-09-15 'disposition:\n  outcome: already-handled\n  date: 2026-09-20' "$GOOD_TOLD"
fn
has_problem 0004 "no landed_at" && ok "closed as already handled still has to name where" \
  || bad "closed as already handled still has to name where"

note 0005 closed 2026-09-15 "$GOOD_DISP" 'author_told:\n  date: 2026-09-26'
fn
has_problem 0005 "no evidence" && ok "'told the author' with no evidence of the telling is a problem" \
  || bad "'told the author' with no evidence of the telling is a problem"

note 0006 closed 2026-09-15 "$GOOD_DISP"
fn
has_problem 0006 "not recorded as told" && ok "a disposition nobody told the author about is a problem" \
  || bad "a disposition nobody told the author about is a problem"

note 0007 closed 2026-09-15 'disposition:\n  outcome: shelved\n  landed_at: nowhere\n  date: 2026-09-20' "$GOOD_TOLD"
fn
has_problem 0007 "no recognised outcome" && ok "an outcome that is not one of the four is a problem" \
  || bad "an outcome that is not one of the four is a problem"

# ── Reopening ────────────────────────────────────────────────────────────────

note 0008 in-review 2026-08-01 "owner: Bob Rivera" "$GOOD_DISP" "reopened: [2026-10-01]"
fn
[ "$(q "[n['age_days'] for n in d['queue'] if n['note']=='0008'][0]")" = 7 ] \
  && ok "a reopened note is open again, aged from the day it was reopened" \
  || bad "a reopened note is open again, aged from the day it was reopened"
note 0009 closed 2026-08-01 "$GOOD_DISP" "$GOOD_TOLD" "reopened: [2026-10-01]"
fn
has_problem 0009 "still marked closed" && ok "a note reopened after its disposition but still marked closed is a problem" \
  || bad "a note reopened after its disposition but still marked closed is a problem"

# ── Older notes, and broken ones ─────────────────────────────────────────────

cat > "$P/domain/field-notes/0010-legacy.md" <<'MD'
---
note: "0010"
title: Written before v2.8.0
date: 2026-09-01
confidence: seen-it
status: closed
promoted_to: [ADR 0004]
---

## Disposition

- **Reviewed by:** Bob Rivera
- **Date:** 2026-09-10
- **Outcome:** ADR
- **Landed at:** ADR 0004
- **Told the author:** yes
MD
fn
[ "$(q "[n['landed_at'] for n in d['notes'] if n['note']=='0010'][0]")" = "ADR 0004" ] \
  && has_problem 0010 "no evidence" \
  && ok "an older note's prose disposition is read, and 'yes' without evidence is still flagged" \
  || bad "an older note's prose disposition is read, and 'yes' without evidence is still flagged"

printf 'no header here\n' > "$P/domain/field-notes/0011-broken.md"
note 0012 parked 2026-09-01
fn
python3 -c "import json;d=json.load(open('$WORK/fn.json'));assert any('0011-broken' in p['note'] for p in d['problems'])" \
  && ok "a note with no readable header is reported, not a crash" \
  || bad "a note with no readable header is reported, not a crash"
has_problem 0012 "is not new, in-review" && ok "an unknown status is a problem" || bad "an unknown status is a problem"

bash "$P/tools/field-notes.sh" "$P" > "$WORK/human.txt"
grep -q 'OVERDUE' "$WORK/human.txt" && grep -q 'Problems:' "$WORK/human.txt" \
  && ok "the human report shows the queue, what is overdue, and the problems" \
  || bad "the human report shows the queue, what is overdue, and the problems"

# ── Doctor's one line ────────────────────────────────────────────────────────

doc_status() { bash "$P/tools/doctor.sh" --json "$P" | python3 -c "import json,sys
print(next(f['status'] for f in json.load(sys.stdin)['findings'] if f['id']=='feedback.field_notes'))"; }
[ "$(doc_status)" = incomplete ] && ok "doctor reports overdue notes and disposition problems" \
  || bad "doctor reports overdue notes and disposition problems"
rm "$P/.causeway/field-notes.json"
[ "$(doc_status)" = incomplete ] && ok "doctor reports notes with no response target chosen" \
  || bad "doctor reports notes with no response target chosen"
rm "$P"/domain/field-notes/0*.md
note 0003 promoted 2026-09-15 "owner: Bob Rivera" "$GOOD_DISP" "$GOOD_TOLD"
printf '{ "respond_within_days": 14 }\n' > "$P/.causeway/field-notes.json"
[ "$(doc_status)" = ok ] && ok "doctor is satisfied when every note is answered and evidenced" \
  || bad "doctor is satisfied when every note is answered and evidenced"
rm "$P"/domain/field-notes/0*.md
[ "$(doc_status)" = ok ] && ok "doctor owes nothing when there are no notes" \
  || bad "doctor owes nothing when there are no notes"
grep -q 'open-items' "$STANDARD_DIR/tools/field-notes.sh" \
  && ! grep -qE "open\(['\"]decisions/open-items" "$STANDARD_DIR/tools/field-notes.sh" \
  && ok "field-notes.sh never writes a note into the open-items index" \
  || bad "field-notes.sh never writes a note into the open-items index"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
