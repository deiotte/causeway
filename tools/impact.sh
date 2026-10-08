#!/usr/bin/env bash
# impact.sh — which accepted decisions to re-read when a constraint changes.
#
#   ./tools/impact.sh <ID>... [--survey FILE] [--json] [project-dir]
#   ./tools/impact.sh --check  [--survey FILE] [--json] [project-dir]
#
# Read-only and offline. Advisory: exits 0, 1 for a usage error, 2 when python3
# is missing. ADR 0049.
#
# A constraint changes — a deployment environment is newly permitted, a data
# release rule tightens — and the decisions justified by the old one need
# another look. The Survey gives every row a permanent ID, and an ADR copies the
# IDs that discriminated into `forces` and the DEC- row it came from into
# `survey_rows`. This follows those references, and only says what they say:
#
#   direct     the ADR cites the ID in `forces`; or came from a DEC- row whose
#              Forces column cites it; or from a DEC- row the ID's own Binds
#              column names
#   indirect   the ADR came from a DEC- row that Depends on an affected one
#   inferred   the ADR mentions the ID in its text and cites it nowhere
#              structured — uncertain, and labelled so
#
# For each, the ADR's status and its `revisit_if`. A superseded ADR is followed
# to the record now in force; a corrected one is named with its correction.
# Nothing is superseded or edited here: whether a decision changes is a person's
# call, made in a new ADR.
#
# --check reports only the references that point nowhere — a force the Survey
# does not have, a DEC- row that does not exist, an ADR number not on disk — and
# how many accepted ADRs carry no structured reference at all, which is how much
# of the record this cannot see.
#
# The Survey is found at survey.md, SURVEY.md, docs/survey.md or
# decisions/survey.md, or named with --survey. Without one, only ADR frontmatter
# and text are read.
set -uo pipefail

JSON=0; CHECK=0; SURVEY=""; PROJECT="."; IDS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --json)   JSON=1; shift ;;
    --check)  CHECK=1; shift ;;
    --survey) SURVEY="${2:?--survey needs a file}"; shift 2 ;;
    -h|--help) sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)       echo "unknown option: $1" >&2; exit 1 ;;
    *)        if [[ "$1" =~ ^[A-Z]+-[0-9]+$ ]]; then IDS+=("$1"); else PROJECT="$1"; fi; shift ;;
  esac
done
[ -d "$PROJECT" ] || { echo "not a directory: $PROJECT" >&2; exit 1; }
if [ "$CHECK" -eq 0 ] && [ "${#IDS[@]}" -eq 0 ]; then
  echo "usage: impact.sh <ID>... | --check   [--survey FILE] [--json] [project-dir]" >&2; exit 1
fi
command -v python3 >/dev/null 2>&1 || { echo "impact.sh needs python3" >&2; exit 2; }
if [ -n "$SURVEY" ]; then
  [ -f "$SURVEY" ] || { echo "no such survey: $SURVEY" >&2; exit 1; }
  SURVEY="$(cd "$(dirname "$SURVEY")" && pwd)/$(basename "$SURVEY")"
fi

cd "$PROJECT" || exit 1
IM_JSON="$JSON" IM_CHECK="$CHECK" IM_SURVEY="$SURVEY" IM_IDS="${IDS[*]:-}" exec python3 - <<'PY'
import glob, json, os, re

ID = re.compile(r"\b([A-Z]{2,5}-\d+)\b")
ids = os.environ["IM_IDS"].split()

# ── The Survey's tables ──────────────────────────────────────────────────────
survey_path = os.environ["IM_SURVEY"] or next(
    (p for p in ("survey.md", "SURVEY.md", "docs/survey.md", "decisions/survey.md") if os.path.isfile(p)), "")
rows = {}            # ID -> {column: text}
if survey_path:
    header = None
    for line in open(survey_path, encoding="utf-8"):
        if not line.lstrip().startswith("|"):
            header = None if line.strip() else header
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells and cells[0] == "ID":
            header = cells
        elif header and cells and re.fullmatch(r"[A-Z]{2,5}-\d+", cells[0]) and not set(cells[0]) <= set("-|"):
            rows[cells[0]] = {header[i] if i < len(header) else str(i): c for i, c in enumerate(cells)}

def col(row, *names):
    for k, v in row.items():
        if any(k.lower().startswith(n) for n in names):
            return v
    return ""

def adr_num(text):
    m = re.search(r"(\d{4})", text or "")
    return m.group(1) if m else None

dec_forces = {i: set(ID.findall(col(r, "forces"))) for i, r in rows.items() if i.startswith("DEC-")}
dec_depends = {i: set(x for x in ID.findall(col(r, "depends")) if x.startswith("DEC-"))
               for i, r in rows.items() if i.startswith("DEC-")}
dec_adr = {i: adr_num(col(r, "adr")) for i, r in rows.items() if i.startswith("DEC-")}
binds = {i: set(x for x in ID.findall(col(r, "binds")) if x.startswith("DEC-"))
         for i, r in rows.items() if not i.startswith("DEC-")}

# ── The ADRs ─────────────────────────────────────────────────────────────────
def scalar(v):
    v = re.sub(r"\s+#.*$", "", v.strip()).strip()
    if v.startswith("#"):
        return ""
    if v[:1] in "\"'" and len(v) > 1:
        return v[1:-1] if v[-1] == v[0] else v[1:]
    return v

def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    if not m:
        return None, text
    fm, key, out = m.group(1), None, {}
    for line in fm.splitlines():
        if re.match(r"^[A-Za-z_]+:", line):
            key, _, v = line.partition(":")
            out[key] = scalar(v)
        elif key and line.startswith((" ", "\t")) and line.strip():
            out[key] = (out[key] + " " + line.strip()) if isinstance(out[key], str) else out[key]
    return out, text[m.end():]

def idlist(v):
    return set(ID.findall(v or ""))

adrs = {}
for path in sorted(glob.glob("decisions/[0-9][0-9][0-9][0-9]-*.md")):
    text = open(path, encoding="utf-8").read()
    fm, body = frontmatter(text)
    if fm is None:
        continue
    num = adr_num(fm.get("adr") or os.path.basename(path))
    adrs[num] = {
        "adr": num, "path": path, "title": fm.get("title", ""), "status": fm.get("status", ""),
        "forces": sorted(idlist(fm.get("forces"))), "survey_rows": sorted(idlist(fm.get("survey_rows"))),
        "revisit_if": fm.get("revisit_if", ""), "superseded_by": adr_num(fm.get("superseded_by")),
        "corrected_by": sorted(set(re.findall(r"\d{4}", fm.get("corrected_by") or ""))),
        "body_ids": idlist(body),
    }

def in_force(num, seen=()):
    """Follow superseded_by to the record now in force."""
    a = adrs.get(num)
    if not a or not a["superseded_by"] or a["superseded_by"] in seen:
        return num
    return in_force(a["superseded_by"], seen + (num,))

# ── Broken references, and what cannot be seen ──────────────────────────────
broken = []
if rows:
    for a in adrs.values():
        for f in a["forces"]:
            if f not in rows:
                broken.append({"where": a["path"], "problem": f"forces cites {f}, which the Survey does not have"})
        for d in a["survey_rows"]:
            if d not in rows:
                broken.append({"where": a["path"], "problem": f"survey_rows cites {d}, which the Survey does not have"})
    for d, n in dec_adr.items():
        if n and n not in adrs:
            broken.append({"where": survey_path, "problem": f"{d} names ADR {n}, which is not in decisions/"})
    for g, decs in binds.items():
        for d in decs:
            if d not in rows:
                broken.append({"where": survey_path, "problem": f"{g} binds {d}, which the Survey does not have"})
for a in adrs.values():
    for ref in ([a["superseded_by"]] if a["superseded_by"] else []) + a["corrected_by"]:
        if ref not in adrs:
            broken.append({"where": a["path"], "problem": f"points at ADR {ref}, which is not in decisions/"})
unlinked = sorted(n for n, a in adrs.items()
                  if a["status"] == "Accepted" and not a["forces"] and not a["survey_rows"])

# ── Impact ───────────────────────────────────────────────────────────────────
def adrs_from_dec(dec):
    found = {n for n, a in adrs.items() if dec in a["survey_rows"]}
    if dec_adr.get(dec) in adrs:
        found.add(dec_adr[dec])
    return found

report = []
for target in ids:
    hits = {}      # adr -> list of (level, why)
    def add(n, level, why):
        hits.setdefault(n, []).append((level, why))
    for n, a in adrs.items():
        if target in a["forces"]:
            add(n, "direct", f"cites {target} in forces")
    affected_decs = set()
    for d, fs in dec_forces.items():
        if target in fs:
            affected_decs.add(d)
            for n in adrs_from_dec(d):
                add(n, "direct", f"came from {d}, whose forces include {target}")
    for d in binds.get(target, set()):
        affected_decs.add(d)
        for n in adrs_from_dec(d):
            add(n, "direct", f"came from {d}, which {target} binds")
    frontier = set(affected_decs)
    while frontier:
        nxt = set()
        for d, deps in dec_depends.items():
            if deps & frontier and d not in affected_decs:
                affected_decs.add(d); nxt.add(d)
                for n in adrs_from_dec(d):
                    add(n, "indirect", f"came from {d}, which depends on {', '.join(sorted(deps & frontier))}")
        frontier = nxt
    for n, a in adrs.items():
        if n not in hits and target in a["body_ids"]:
            add(n, "inferred", f"mentions {target} in its text, and cites it nowhere structured")
    rank = {"direct": 0, "indirect": 1, "inferred": 2}
    entries = []
    for n, reasons in hits.items():
        a = adrs[n]
        level = min((r[0] for r in reasons), key=rank.get)
        e = {"adr": n, "title": a["title"], "path": a["path"], "status": a["status"], "level": level,
             "why": [r[1] for r in reasons], "revisit_if": a["revisit_if"]}
        if a["status"] in ("Superseded", "Deprecated"):
            cur = in_force(n)
            e["read_instead"] = cur if cur != n else None
        if a["corrected_by"]:
            e["corrected_by"] = a["corrected_by"]
        entries.append(e)
    entries.sort(key=lambda e: (rank[e["level"]], e["adr"]))
    report.append({"id": target, "in_survey": target in rows if rows else None,
                   "survey_row": rows.get(target, {}), "decisions": sorted(affected_decs), "adrs": entries})

if os.environ["IM_JSON"] == "1":
    print(json.dumps({"format": "causeway-impact-v1", "survey": survey_path or None,
                      "adrs_read": len(adrs), "impact": report, "broken": broken,
                      "unlinked_accepted_adrs": unlinked}, indent=2))
    raise SystemExit(0)

print(f"Decision impact — {os.getcwd()}")
print(f"  survey: {survey_path or 'none found — reading ADR frontmatter and text only'}  ·  {len(adrs)} ADRs read")
for r in report:
    print()
    where = ("" if r["in_survey"] is None else
             "" if r["in_survey"] else "  (not a row in the Survey)")
    desc = next((v for k, v in r["survey_row"].items() if k not in ("ID",) and v), "")
    print(f"  {r['id']}{where}{' — ' + desc if desc else ''}")
    if r["decisions"]:
        print(f"    Survey decisions affected: {', '.join(r['decisions'])}")
    if not r["adrs"]:
        print("    No ADR cites or mentions it.")
    for e in r["adrs"]:
        print(f"    [{e['level']:>8}] ADR {e['adr']} ({e['status'] or 'no status'}) — {e['title']}")
        for w in e["why"]:
            print(f"               {w}")
        if e.get("read_instead"):
            print(f"               superseded — the record in force is ADR {e['read_instead']}")
        if e.get("corrected_by"):
            print(f"               corrected by ADR {', '.join(e['corrected_by'])} — read them together")
        print(f"               revisit_if: {e['revisit_if'] or '(none stated)'}")
if broken or os.environ["IM_CHECK"] == "1":
    print()
    print("  References that point nowhere:" if broken else "  No broken references.")
    for b in broken:
        print(f"    {b['where']}: {b['problem']}")
print()
print(f"  {len(unlinked)} accepted ADR(s) cite no forces and no survey_rows; this cannot see their constraints"
      + (f": {', '.join(unlinked)}" if unlinked and len(unlinked) <= 12 else "."))
print("  Nothing was changed. Whether a decision changes is decided in a new ADR.")
PY
