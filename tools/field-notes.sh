#!/usr/bin/env bash
# field-notes.sh — the field-note queue: who owes which practitioner an answer.
#
#   ./tools/field-notes.sh [--json] [--target-days N] [project-dir]
#
# Read-only and offline. Advisory: exits 0 whatever it finds, 1 for a usage
# error, 2 when python3 is missing. ADR 0048.
#
# Every field note reaches a disposition and its author is told which (Build DNA,
# the Practitioner role). Nothing showed whether that was happening. This reads
# domain/field-notes/*.md and reports:
#
#   the queue      every open note (new, in-review, or reopened), oldest first:
#                  age, owner, next action, source
#   the problems   a note closed with no outcome or no place it landed; an
#                  author recorded as told with no evidence of the telling, or
#                  not told at all; a note reopened after its disposition and
#                  still marked closed; a note whose header cannot be read
#   the numbers    open, overdue, unassigned, disposed, median days from note
#                  to disposition, authors told with evidence, reviewer minutes
#
# Overdue is measured against a response target the project chooses, in
# .causeway/field-notes.json ({"respond_within_days": 14}) or --target-days.
# With no target there is no overdue — only ages. The standard does not pick the
# number: a threshold invented before anyone has run the process is a number
# invented to have one (Build DNA open item 6).
#
# A field note is an input, not an open item. Nothing here writes to
# decisions/open-items.json; a note earns a row there only when the ADR that read
# it leaves something open.
set -uo pipefail

JSON=0
TARGET=""
PROJECT="."
while [ $# -gt 0 ]; do
  case "$1" in
    --json)        JSON=1; shift ;;
    --target-days) TARGET="${2:?--target-days needs a number}"; shift 2 ;;
    -h|--help)     sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)            echo "unknown option: $1" >&2; exit 1 ;;
    *)             PROJECT="$1"; shift ;;
  esac
done
[ -d "$PROJECT" ] || { echo "not a directory: $PROJECT" >&2; exit 1; }
case "$TARGET" in ''|*[!0-9]*) [ -z "$TARGET" ] || { echo "--target-days must be a whole number" >&2; exit 1; } ;; esac
command -v python3 >/dev/null 2>&1 || { echo "field-notes.sh needs python3 to read note headers" >&2; exit 2; }

cd "$PROJECT" || exit 1
FN_JSON="$JSON" FN_TARGET="$TARGET" FN_TODAY="${CAUSEWAY_TODAY:-}" exec python3 - <<'PY'
import datetime, glob, json, os, re, statistics

today = (datetime.date.fromisoformat(os.environ["FN_TODAY"]) if os.environ.get("FN_TODAY")
         else datetime.date.today())
OPEN, DISPOSED = ("new", "in-review"), ("promoted", "closed")
OUTCOMES = {"adr", "test", "constraint", "claude.md constraint", "`claude.md` constraint",
            "already-handled", "closed as already handled", "already handled"}

# ── A small reader for the note header ─────────────────────────────────────────
# Enough YAML for the template: scalars, [inline, lists], "- item" lists, and one
# level of nested mapping. Comments after an unquoted value are dropped.
def scalar(v):
    v = v.strip()
    if not v or v.startswith("#"):
        return ""
    if v[0] in "\"'":
        q = v[0]; end = v.find(q, 1)
        return v[1:end] if end > 0 else v[1:]
    v = re.sub(r"\s+#.*$", "", v).strip()
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        return [scalar(x) for x in inner.split(",")] if inner else []
    return v

def header(text):
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    if not m:
        return None
    out, cur, cur_list = {}, None, None
    for raw in m.group(1).splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip())
        line = raw.strip()
        if indent == 0:
            cur_list = None
            k, _, v = line.partition(":")
            v = scalar(v)
            if v == "":
                out[k.strip()] = {}; cur = k.strip()
            else:
                out[k.strip()] = v; cur = None
        elif line.startswith("- ") and cur is not None:
            if not isinstance(out[cur], list):
                out[cur] = []
            out[cur].append(scalar(line[2:]))
        elif cur is not None and isinstance(out[cur], dict):
            k, _, v = line.partition(":")
            out[cur][k.strip()] = scalar(v)
    return out

# Notes written before ADR 0048 carry their disposition only in the prose block.
def prose_disposition(text):
    def field(name):
        m = re.search(rf"^\s*-\s*\*\*{name}:\*\*\s*(.*)$", text, re.M)
        v = m.group(1).strip() if m else ""
        return "" if v.startswith("<") or v in ("ADR | test | `CLAUDE.md` constraint | closed as already handled",
                                                  "yes / no") else v
    return {"reviewed_by": field("Reviewed by"), "date": field("Date"), "outcome": field("Outcome"),
            "landed_at": field("Landed at"), "told": field("Told the author")}

def as_date(v):
    try:
        return datetime.date.fromisoformat(str(v).strip())
    except Exception:
        return None

target = os.environ.get("FN_TARGET") or None
if target is None:
    try:
        target = json.load(open(".causeway/field-notes.json")).get("respond_within_days")
    except Exception:
        target = None
target = int(target) if str(target or "").isdigit() else None

notes, problems = [], []
for path in sorted(glob.glob("domain/field-notes/*.md")):
    if os.path.basename(path).lower() == "readme.md":
        continue
    text = open(path, encoding="utf-8").read()
    try:
        h = header(text)
    except Exception as e:
        h = None
    if h is None:
        problems.append({"note": path, "problem": "no readable header; the note cannot be queued"})
        continue
    num, status = str(h.get("note") or "?"), str(h.get("status") or "").strip()
    written = as_date(h.get("date"))
    reopened = [d for d in (as_date(x) for x in (h.get("reopened") or []) if x) if d]
    disp = h.get("disposition") if isinstance(h.get("disposition"), dict) else {}
    told = h.get("author_told") if isinstance(h.get("author_told"), dict) else {}
    legacy = prose_disposition(text)
    outcome = str(disp.get("outcome") or legacy["outcome"]).strip()
    landed = str(disp.get("landed_at") or legacy["landed_at"]).strip()
    disp_date = as_date(disp.get("date") or legacy["date"])
    owner = str(h.get("owner") or legacy["reviewed_by"] or "").strip()
    effort = h.get("effort_minutes")
    effort = int(effort) if str(effort or "").isdigit() else None
    n = {"note": num, "path": path, "title": str(h.get("title") or ""), "status": status,
         "owner": owner, "next_action": str(h.get("next_action") or "").strip(),
         "source": str(h.get("source") or "").strip() or path,
         "written": str(written or ""), "reopened": [str(d) for d in reopened],
         "outcome": outcome, "landed_at": landed, "disposed_on": str(disp_date or ""),
         "told_on": str(told.get("date") or ""), "told_evidence": str(told.get("evidence") or "").strip(),
         "effort_minutes": effort}
    if not written:
        problems.append({"note": num, "problem": "no date, so its age cannot be known"})
    if status in OPEN:
        start = max([written] + reopened) if written else None
        n["age_days"] = (today - start).days if start else None
        n["overdue"] = bool(target is not None and n["age_days"] is not None and n["age_days"] > target)
        if reopened and disp_date and max(reopened) > disp_date:
            n["reopened_after"] = str(disp_date)
    elif status in DISPOSED:
        if not outcome or outcome.lower() not in OUTCOMES:
            problems.append({"note": num, "problem": f"marked {status} with no recognised outcome "
                             "(adr, test, constraint or already-handled)"})
        if not landed:
            problems.append({"note": num, "problem": f"marked {status} with no landed_at: the answer cannot be found, "
                             "and 'already handled' still names where"})
        if not disp_date:
            problems.append({"note": num, "problem": f"marked {status} with no disposition date"})
        if reopened and disp_date and max(reopened) > disp_date:
            problems.append({"note": num, "problem": f"reopened on {max(reopened)}, after its disposition, and still marked {status}"})
        if not n["told_on"] and legacy["told"].lower() not in ("yes",):
            problems.append({"note": num, "problem": "disposed, and its author is not recorded as told"})
        elif not n["told_evidence"]:
            problems.append({"note": num, "problem": "the author is recorded as told with no evidence of the telling "
                             "(a link to the comment, message or meeting note)"})
        if written and disp_date:
            n["days_to_disposition"] = (disp_date - written).days
    else:
        problems.append({"note": num, "problem": f"status {status!r} is not new, in-review, promoted or closed"})
    notes.append(n)

queue = sorted([n for n in notes if n["status"] in OPEN],
               key=lambda n: -(n["age_days"] if n.get("age_days") is not None else -1))
disposed = [n for n in notes if n["status"] in DISPOSED]
dtimes = [n["days_to_disposition"] for n in disposed if n.get("days_to_disposition") is not None]
efforts = [n["effort_minutes"] for n in notes if n["effort_minutes"] is not None]
numbers = {
    "notes": len(notes), "open": len(queue),
    "overdue": sum(1 for n in queue if n.get("overdue")) if target is not None else None,
    "unassigned": sum(1 for n in queue if not n["owner"]),
    "disposed": len(disposed),
    "median_days_to_disposition": statistics.median(dtimes) if dtimes else None,
    "authors_told_with_evidence": sum(1 for n in disposed if n["told_on"] and n["told_evidence"]),
    "reviewer_minutes": sum(efforts) if efforts else None,
    "notes_with_effort_recorded": len(efforts),
}

if os.environ.get("FN_JSON") == "1":
    print(json.dumps({"format": "causeway-field-notes-v1", "as_of": str(today),
                      "respond_within_days": target, "numbers": numbers,
                      "queue": queue, "problems": problems, "notes": notes}, indent=2))
    raise SystemExit(0)

print(f"Field notes — {os.getcwd()}  (as of {today})")
print(f"  response target: {f'{target} days' if target is not None else 'none chosen — ages only, nothing is overdue'}")
print()
if queue:
    print("  Open, oldest first:")
    for n in queue:
        age = f"{n['age_days']}d" if n.get("age_days") is not None else "?d"
        flag = " OVERDUE" if n.get("overdue") else ""
        print(f"    {n['note']:>5}  {age:>5}{flag}  {n['owner'] or 'UNASSIGNED'}  — {n['title']}")
        print(f"           next: {n['next_action'] or '(none recorded)'}   source: {n['source']}")
        if n.get("reopened"):
            print(f"           reopened: {', '.join(n['reopened'])}")
else:
    print("  No open notes.")
print()
if problems:
    print("  Problems:")
    for p in problems:
        print(f"    {p['note']:>5}  {p['problem']}")
    print()
med = numbers["median_days_to_disposition"]
print(f"  {numbers['open']} open"
      + (f", {numbers['overdue']} overdue" if numbers['overdue'] is not None else "")
      + f", {numbers['unassigned']} unassigned · {numbers['disposed']} disposed"
      + (f", median {med} days to disposition" if med is not None else "")
      + f" · {numbers['authors_told_with_evidence']} of {numbers['disposed']} authors told with evidence"
      + (f" · {numbers['reviewer_minutes']} reviewer minutes over {numbers['notes_with_effort_recorded']} notes"
         if numbers['reviewer_minutes'] is not None else ""))
PY
