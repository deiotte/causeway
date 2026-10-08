#!/usr/bin/env bash
# doctor.sh — what is still missing before this project is built under Causeway.
#
#   ./tools/doctor.sh [--json] [project-dir]
#
# Run from a consuming project's root (or name it). Read-only and offline: it
# writes nothing and contacts nothing. ADR 0045.
#
# A clean sync and a clean drift check prove the standard is present and
# unedited. They do not prove a project is ready to build under it — a project
# with no system.json, placeholder reviewers and a CLAUDE.md that never imports
# the standard passes both. This lists what ADOPTING.md's "building under it"
# column still asks for, one finding at a time:
#
#   ok           checked here, and it holds
#   incomplete   checked here, and something is missing — with the remedy
#   unverified   cannot be checked from the files here (a repository setting, or
#                a tool this machine lacks). Never counted as passing.
#
# It does not evaluate the gate, and it never claims a verdict. A project can be
# installed, integrity-checked and fully adopted, and still not evaluated.
#
# Advisory: exits 0 whatever it finds; 1 only for a usage error. --json prints
# the same findings as one JSON document (format "causeway-doctor-v1").
set -uo pipefail

JSON=0
PROJECT="."
while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON=1; shift ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 1 ;;
    *) PROJECT="$1"; shift ;;
  esac
done
[ -d "$PROJECT" ] || { echo "not a directory: $PROJECT" >&2; exit 1; }
cd "$PROJECT" || exit 1

IDS=(); STATUSES=(); SUBJECTS=(); WHYS=(); REMEDIES=()
finding() { IDS+=("$1"); STATUSES+=("$2"); SUBJECTS+=("$3"); WHYS+=("$4"); REMEDIES+=("${5:-}"); }

# Placeholders the seeded starters ship with: [ALL-CAPS] tokens, and @ORG/ teams.
placeholders() { grep -nE '\[[A-Z][A-Z0-9 /_.,:–-]{2,}\]' "$1" 2>/dev/null | head -3 | cut -c1-70; }

# ── Installed ────────────────────────────────────────────────────────────────

INSTALLED=0
if [ -f .causeway-lock ]; then
  INSTALLED=1
  finding install.lock ok ".causeway-lock" "The standard is pinned at v$(sed -n 's/^version=//p' .causeway-lock | head -1)."
else
  finding install.lock incomplete ".causeway-lock" \
    "Nothing pins the standard, so nothing can say which version this project follows." \
    "Run tools/sync.sh from a Causeway release: sync.sh /path/to/project --require-release"
fi

INTEGRITY="unable"
if [ "$INSTALLED" -eq 1 ] && [ -f tools/check-drift.sh ]; then
  if bash tools/check-drift.sh >/dev/null 2>&1; then
    INTEGRITY="verified"
    finding install.integrity ok "tools/check-drift.sh" "Every vendored file hashes as the lock recorded."
  else
    INTEGRITY="failed"
    finding install.integrity incomplete "tools/check-drift.sh" \
      "A vendored file no longer matches the lock: the standard here has been edited or is incomplete." \
      "Run tools/check-drift.sh to see which file. Re-sync to restore it; a change you meant goes upstream."
  fi
elif [ "$INSTALLED" -eq 1 ]; then
  finding install.integrity incomplete "tools/check-drift.sh" \
    "The drift checker is missing, so nothing can tell whether the vendored standard was edited." \
    "Re-sync from a release; check-drift.sh is vendored with the standard."
fi

if [ "$INSTALLED" -eq 1 ]; then
  proof="$(sed -n 's/^release_proof=//p' .causeway-lock | head -1)"
  tag="$(sed -n 's/^tag=//p' .causeway-lock | head -1)"
  if [ -n "$tag" ] && [ -n "$proof" ] && [ "$proof" != "none" ]; then
    finding install.release ok ".causeway-lock" "Pinned to release $tag ($proof)."
  else
    finding install.release incomplete ".causeway-lock" \
      "The pin names no published release: it was synced from a development copy." \
      "Before anything ships, re-sync from a release archive or tag with --require-release."
  fi
fi

# ── Placement ────────────────────────────────────────────────────────────────
#
# Reported, never chosen. A placement is decided by whoever owns the
# consequences; a doctor that offered a default would be the quickest way to a
# C3 nobody declared.

PLACEMENT_REMEDY="Placement is decided by whoever owns the consequences, not filled in to clear this finding. Procedure: skills/decision-spine/reference/placement.md"
# One word for where this project stands, carried into --json so that a
# portfolio's doctor results can be counted: declared, asserted, defaulted,
# tier-missing, tier-invalid, class-invalid, unreadable, no-system-json or
# unverified. That count is the measurement gate configuration §10 item 13 says
# the placement-argued check is waiting for. ADR 0047.
PLACEMENT_STATE="no-system-json"; P_TIER=""; P_CLASS=""
if [ ! -f system.json ]; then
  finding placement.system_json incomplete "system.json" \
    "No placement: tier and criticality are what the gate profile is derived from, and the gate assumes C1 without them." \
    "$PLACEMENT_REMEDY"
elif ! command -v python3 >/dev/null 2>&1; then
  PLACEMENT_STATE="unverified"
  finding placement.system_json unverified "system.json" \
    "python3 is not available here to read system.json." \
    "Run doctor.sh on a machine with python3, or check tier, criticality_class and criticality_authority by hand."
else
  while IFS='|' read -r id status subject why remedy; do
    if [ "$id" = "@state" ]; then
      PLACEMENT_STATE="$status"; P_TIER="$subject"; P_CLASS="$why"; continue
    fi
    [ -n "$id" ] && finding "$id" "$status" "$subject" "$why" "${remedy//@PLACEMENT@/$PLACEMENT_REMEDY}"
  done < <(python3 - <<'PY'
import datetime, glob, json, os, re, subprocess

def out(i, s, subj, why, rem=""):
    print("|".join(str(x).replace("|", "/").replace("\n", " ") for x in (i, s, subj, why, rem)))

CLASSES = ("C1", "C2", "C3")
TIERS = ("operational", "mission", "core")
STRICTER = {"C1": 0, "C2": 1, "C3": 2}             # lower is stricter
TIER_RANK = {"operational": 0, "mission": 1, "core": 2}
ROLES = {"po", "product owner", "service owner", "customer", "sponsor"}
ASSERTION = ("A name in a file is a recorded assertion: it says who is on record as "
             "declaring this, and does not authenticate that person's approval.")
ADR_REMEDY = ("Write the placement ADR: the four answers, the escalator if one fired, the "
              "class nearly chosen and why not, and the revisit condition. List the row in "
              "its spine_rows. placement.md, The declaration.")

try:
    d = json.load(open("system.json"))
except Exception as e:
    out("@state", "unreadable", "", "")
    out("placement.system_json", "incomplete", "system.json",
        f"system.json is not valid JSON ({type(e).__name__}), so no evaluator can read it.",
        "Fix the syntax. The fields are in gate/gate-configuration.md §2.")
    raise SystemExit
if not isinstance(d, dict):
    out("@state", "unreadable", "", "")
    out("placement.system_json", "incomplete", "system.json", "system.json is not a JSON object.",
        "See gate/gate-configuration.md §2 for its shape.")
    raise SystemExit
try:
    matrix = json.load(open("gate/profiles.json"))["resolution"]["matrix"]
except Exception:
    matrix = {}

tier, cls, auth = d.get("tier"), d.get("criticality_class"), d.get("criticality_authority")

def authority_gaps(a):
    if not isinstance(a, dict):
        return ["name", "role", "declared"]
    gaps = [k for k in ("name", "role", "declared") if not str(a.get(k) or "").strip()]
    if "role" not in gaps and str(a["role"]).strip().lower() not in ROLES:
        gaps.append(f"role ({a['role']!r} is not PO, Service Owner, Customer or Sponsor)")
    if "declared" not in gaps:
        try:
            if datetime.date.fromisoformat(str(a["declared"])) > datetime.date.today():
                gaps.append("declared (a date in the future)")
        except ValueError:
            gaps.append("declared (not a YYYY-MM-DD date)")
    return gaps

# ── The fields, one at a time ──
if tier in TIERS:
    out("placement.tier", "ok", "system.json: tier", f"tier is {tier}.")
elif tier is None:
    out("placement.tier", "incomplete", "system.json: tier",
        "No tier. The gate requires one; without it no profile can be derived.", "@PLACEMENT@")
else:
    out("placement.tier", "incomplete", "system.json: tier",
        f"tier {tier!r} is not operational, mission or core.", "@PLACEMENT@")
if cls in CLASSES:
    out("placement.criticality", "ok", "system.json: criticality_class", f"criticality_class is {cls}.")
elif cls is None:
    out("placement.criticality", "incomplete", "system.json: criticality_class",
        "No criticality class. The gate treats this as C1, the strictest — which is a default, not a declaration.",
        "@PLACEMENT@")
else:
    out("placement.criticality", "incomplete", "system.json: criticality_class",
        f"criticality_class {cls!r} is not C1, C2 or C3.", "@PLACEMENT@")
gaps = authority_gaps(auth) if cls in CLASSES else []
if cls in CLASSES:
    if gaps:
        out("placement.authority", "incomplete", "system.json: criticality_authority",
            "A class with no complete declaring authority cannot be told apart from one somebody typed: "
            + ", ".join(gaps) + ".",
            "Record who declared it: name, role (PO, Service Owner, Customer or Sponsor) and date. See placement.md, The declaration.")
    else:
        out("placement.authority", "ok", "system.json: criticality_authority",
            f"Declared by {auth['name']} ({auth['role']}) on {auth['declared']}. {ASSERTION}")

# ── The state, in one word ──
if tier is None:
    state = "tier-missing"
elif tier not in TIERS:
    state = "tier-invalid"
elif cls is None:
    state = "defaulted"
elif cls not in CLASSES:
    state = "class-invalid"
elif gaps:
    state = "asserted"
else:
    state = "declared"
out("@state", state, tier if tier in TIERS else "", cls if cls in CLASSES else "")
STATE_WHY = {
    "declared": f"Declared: {cls}, by a named authority with a role and a date. {ASSERTION}",
    "asserted": f"Asserted: {cls} is set, and nobody is completely on record as declaring it. To the gate this is identical to a declaration; to a reviewer it is a value somebody typed.",
    "defaulted": "Defaulted: no class, so the gate runs this system at C1. Strict, which is the point of the default — and not a declaration: nothing records that anyone decided it.",
    "class-invalid": f"criticality_class {cls!r} is not a class, so the gate cannot use it.",
    "tier-missing": "No tier, so no profile can be derived at all.",
    "tier-invalid": f"tier {tier!r} is not a tier, so no profile can be derived at all.",
}
out("placement.state", "ok" if state == "declared" else "incomplete", f"placement: {state}",
    STATE_WHY[state], "" if state == "declared" else "@PLACEMENT@")

if tier in matrix:
    prof = matrix[tier].get(cls if cls in CLASSES else "C1")
    if prof:
        note = "" if cls in CLASSES else " (criticality defaulted to C1)"
        out("placement.profile", "ok", "gate/profiles.json",
            f"Derived gate profile: {prof}{note}. Derived, never declared.")

# ── The ADRs that carry the argument ──
def adrs_closing(row):
    found = []
    for path in sorted(glob.glob("decisions/*.md")):
        try:
            text = open(path, encoding="utf-8").read()
        except Exception:
            continue
        m = re.match(r"---\n(.*?)\n---", text, re.S)
        if not m:
            continue
        fm = m.group(1)
        rows = re.search(r"^spine_rows:\s*(\[[^\]\n]*\]|(?:\n\s*-\s*.*)+)", fm, re.M)
        status = re.search(r"^status:\s*(\S+)", fm, re.M)
        date = re.search(r"^date:\s*(\S+)", fm, re.M)
        if not rows or not re.search(rf"\b{re.escape(row)}\b(?!\.\d)", rows.group(1)):
            continue
        if status and status.group(1) in ("Superseded", "Deprecated", "Proposed"):
            continue
        found.append((path, date.group(1) if date else ""))
    return found

sa11, sa114 = adrs_closing("SA-1.1"), adrs_closing("SA-1.14")
if cls in CLASSES:
    if sa11:
        out("placement.adr_class", "ok", sa11[-1][0], "Closes SA-1.1: the argument for the class is on record.")
    else:
        arg = ("system.json's $criticality states an argument, but SA-1.1 closes in an ADR"
               if str(d.get("$criticality") or "").strip() else
               "and system.json has no $criticality argument either")
        out("placement.adr_class", "incomplete", "decisions/: SA-1.1",
            f"No accepted ADR closes SA-1.1, so the class has no recorded argument — {arg}.", ADR_REMEDY)
if tier in TIERS:
    if sa114:
        out("placement.adr_tier", "ok", sa114[-1][0], "Closes SA-1.14: the argument for the tier is on record.")
    else:
        out("placement.adr_tier", "incomplete", "decisions/: SA-1.14",
            "No accepted ADR closes SA-1.14, so the tier has no recorded argument.", ADR_REMEDY)

# ── The other record: CLAUDE.md's placement block ──
try:
    claude = open("CLAUDE.md", encoding="utf-8").read()
except Exception:
    claude = ""
ct = re.search(r"^\s*-\s*\*\*Tier:\*\*\s*(.+?)\s*$", claude, re.M)
cc = re.search(r"^\s*-\s*\*\*Criticality class:\*\*\s*(.+?)\s*$", claude, re.M)
if ct or cc:
    shown = [x.group(1) for x in (ct, cc) if x]
    if any("|" in v for v in shown):
        out("placement.records_agree", "incomplete", "CLAUDE.md: Causeway placement",
            "The placement block still shows the template's choices, so the record an agent reads first says nothing.",
            "Write the tier and class there, matching system.json, with each one's why line.")
    else:
        disagree = []
        if ct and tier in TIERS and ct.group(1).split()[0].lower().strip("*`") != tier:
            disagree.append(f"tier: system.json {tier}, CLAUDE.md {ct.group(1)}")
        if cc and cls in CLASSES and cc.group(1).split()[0].upper().strip("*`") != cls:
            disagree.append(f"class: system.json {cls}, CLAUDE.md {cc.group(1)}")
        if disagree:
            out("placement.records_agree", "incomplete", "CLAUDE.md vs system.json",
                "The two placement records disagree — " + "; ".join(disagree)
                + ". The gate reads system.json; an agent reads CLAUDE.md.",
                "Find out which one is the declaration, and correct the other. A lowering needs a new declaration (placement.md, Reclassification).")
        else:
            out("placement.records_agree", "ok", "CLAUDE.md vs system.json", "The placement records agree.")

# ── Reclassification, read from history ──
def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True)

hist = None
try:
    if git("rev-parse", "--is-inside-work-tree").stdout.strip() == "true":
        hist = []
        for line in git("log", "--format=%H %cs", "--", "system.json").stdout.splitlines():
            sha, day = line.split()
            try:
                hist.append((sha[:10], day, json.loads(git("show", f"{sha}:system.json").stdout)))
            except Exception:
                pass
except FileNotFoundError:
    hist = None

if hist is None:
    out("placement.reclassification", "unverified", "system.json history",
        "No git history here, so a change of class or tier cannot be checked against the rules for changing one.",
        "Run doctor.sh in the project's git checkout.")
elif cls in CLASSES:
    prev = next((h for h in hist if isinstance(h[2], dict) and h[2].get("criticality_class") != cls), None)
    pcls = prev[2].get("criticality_class") if prev else None
    if prev is None:
        out("placement.reclassification", "ok", "system.json history", f"{cls} is the only class in this file's history.")
    elif pcls not in CLASSES:
        out("placement.reclassification", "ok", "system.json history",
            f"{cls} is the first class declared (as of {prev[0]} there was none, so the gate ran at C1). "
            "A first declaration answers the four questions; it is not a lowering.")
    elif STRICTER[cls] < STRICTER[pcls]:
        out("placement.reclassification", "ok", "system.json history",
            f"Raised from {pcls} to {cls}. Up is immediate and needs no ceremony; rows newly owed close against the adoption horizon.")
    else:
        pa = prev[2].get("criticality_authority") if isinstance(prev[2].get("criticality_authority"), dict) else {}
        problems = []
        if gaps:
            problems.append("the current declaration is incomplete")
        else:
            if str(auth["declared"]) <= str(pa.get("declared") or ""):
                problems.append(f"the declaration date ({auth['declared']}) is not newer than the one for {pcls} ({pa.get('declared') or 'none'})")
            if pa.get("name") and (str(pa.get("name")).strip(), str(pa.get("role")).strip().lower()) != (str(auth["name"]).strip(), str(auth["role"]).strip().lower()):
                problems.append(f"it is declared by {auth['name']} ({auth['role']}), and {pcls} was declared by {pa.get('name')} ({pa.get('role')}) — a lowering needs the same authority")
            if not any(day >= str(auth["declared"]) for _, day in sa11):
                problems.append("no accepted SA-1.1 ADR is dated on or after the new declaration")
        if problems:
            out("placement.reclassification", "incomplete", "system.json history",
                f"Lowered from {pcls} (as of {prev[0]}) to {cls}, and " + "; ".join(problems) + ". "
                "Down needs a new declaration from the same authority, against the same four questions, about a change in the world.",
                "Record the new declaration and its ADR (placement.md, Reclassification), or restore " + pcls + ". Doctor does not supply the authority.")
        else:
            out("placement.reclassification", "ok", "system.json history",
                f"Lowered from {pcls} to {cls} with a new declaration by the same authority on {auth['declared']}, and an ADR on record. "
                "Down is never retroactive: rows owed while it was " + pcls + " stay owed.")
    ptier = next((h[2].get("tier") for h in hist if isinstance(h[2], dict) and h[2].get("tier") != tier), None)
    if ptier in TIERS and tier in TIERS and TIER_RANK[tier] < TIER_RANK[ptier]:
        out("placement.tier_change", "unverified", "system.json history",
            f"Tier lowered from {ptier} to {tier}. Tier moves by catalog placement, not by declaration, and doctor cannot see the catalog.",
            "Confirm the catalog placed it there, and cite that in the SA-1.14 ADR.")
PY
)
fi

# ── Agent instructions ───────────────────────────────────────────────────────
#
# A reference being present is checked. Whether an agent reads it is not
# something any file can show (Build DNA open item 9).

if [ ! -f CLAUDE.md ] && [ ! -L CLAUDE.md ]; then
  finding instructions.claude incomplete "CLAUDE.md" \
    "No CLAUDE.md, so Claude Code is not pointed at the standard." \
    "Re-run tools/sync.sh, which seeds one, or create it with the line @AGENTS.md."
elif [ "$(readlink -f CLAUDE.md 2>/dev/null)" = "$(readlink -f AGENTS.md 2>/dev/null)" ] \
     || grep -qE '^[[:space:]]*@(\./)?AGENTS\.md[[:space:]]*$' CLAUDE.md; then
  finding instructions.claude ok "CLAUDE.md" "Imports the standard (@AGENTS.md)."
else
  finding instructions.claude incomplete "CLAUDE.md" \
    "CLAUDE.md does not import the standard, so the standard is on disk and not in the agent's instructions." \
    "Add a line reading @AGENTS.md. CLAUDE.md.causeway shows the full shim."
fi

for f in GEMINI.md .github/copilot-instructions.md .cursor/rules/causeway.mdc; do
  if [ -L "$f" ] && [ "$(readlink -f "$f")" = "$(readlink -f AGENTS.md 2>/dev/null)" ]; then
    finding "instructions.$(basename "$f")" ok "$f" "Links to AGENTS.md."
  elif [ -f "$f" ] && grep -q '^<!-- causeway:begin' "$f" && grep -q 'AGENTS.md' "$f"; then
    finding "instructions.$(basename "$f")" ok "$f" "Holds the Causeway section pointing at AGENTS.md."
  elif [ -f "$f" ] && grep -q 'AGENTS.md' "$f"; then
    finding "instructions.$(basename "$f")" ok "$f" "Points at AGENTS.md (no Causeway markers; an older sync wrote it)."
  else
    finding "instructions.$(basename "$f")" incomplete "$f" \
      "This tool's instructions do not point at AGENTS.md." \
      "Re-run tools/sync.sh; it adds a marked Causeway section and keeps your own text (ADR 0043)."
  fi
done

# ── Starter files the project owns ───────────────────────────────────────────

for f in CLAUDE.md CONTRIBUTING.md START-HERE.md .github/pull_request_template.md; do
  [ -f "$f" ] || continue
  p="$(placeholders "$f")"
  if [ -n "$p" ]; then
    finding "starter.$(basename "$f")" incomplete "$f" \
      "Still carries template placeholders, so a reader meets blanks: $(echo "$p" | head -1)" \
      "Replace every [BRACKETED] placeholder with this project's names, commands and rules."
  else
    finding "starter.$(basename "$f")" ok "$f" "No template placeholders left."
  fi
done

if [ -f decisions/open-items.json ]; then
  if grep -q 'REPLACE — delete this example' decisions/open-items.json; then
    finding starter.open_items incomplete "decisions/open-items.json" \
      "Still holds the template's example item, so its counts describe the template rather than this project." \
      "Delete the example, name your registers, and add your own items (Build DNA §8)."
  else
    finding starter.open_items ok "decisions/open-items.json" "The template example has been replaced."
  fi
fi

# ── Reviewers ────────────────────────────────────────────────────────────────

CO=""
for c in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do [ -f "$c" ] && { CO="$c"; break; }; done
if [ -z "$CO" ]; then
  finding reviewers.codeowners incomplete ".github/CODEOWNERS" \
    "No reviewer map, so nobody is nominated to review a change or a field note." \
    "Re-run tools/sync.sh to seed one, then name real teams."
elif grep -v '^[[:space:]]*#' "$CO" | grep -q '@ORG/'; then
  finding reviewers.codeowners incomplete "$CO" \
    "Still names @ORG/... placeholder teams, which nominate nobody and fail silently." \
    "Replace every @ORG/TEAM with a real user or team."
else
  finding reviewers.codeowners ok "$CO" "Names real reviewers."
fi
finding reviewers.required unverified "repository setting: branch protection" \
  "CODEOWNERS only nominates. Whether code-owner review is required is a repository setting no file here records." \
  "Check the default branch requires a pull request and code-owner review, then try merging without one."

# ── CI ───────────────────────────────────────────────────────────────────────

CI_FILES=()
for c in .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml azure-pipelines.yml \
         Jenkinsfile .circleci/config.yml bitbucket-pipelines.yml; do
  [ -f "$c" ] && CI_FILES+=("$c")
done
if [ "${#CI_FILES[@]}" -eq 0 ]; then
  finding ci.drift incomplete "CI configuration" \
    "No CI configuration in any location doctor knows, so nothing runs the drift check on a change." \
    "Add a CI job that runs tools/check-drift.sh on every pull request."
elif grep -l 'check-drift.sh' "${CI_FILES[@]}" >/dev/null 2>&1; then
  finding ci.drift ok "$(grep -l 'check-drift.sh' "${CI_FILES[@]}" | head -1)" "CI runs tools/check-drift.sh."
else
  finding ci.drift incomplete "${CI_FILES[0]}" \
    "CI exists but does not run tools/check-drift.sh, so an edited standard merges unnoticed." \
    "Add a step that runs tools/check-drift.sh."
fi
finding ci.required unverified "repository setting: required checks" \
  "Whether the drift check is required to pass before merge is a repository setting no file here records." \
  "Make the CI job that runs check-drift.sh a required status check on the default branch."

# ── Gate evaluator ───────────────────────────────────────────────────────────
#
# ADOPTING.md asks for an engine that evaluates gate/checks.json, or an honest
# record that there is none yet. The record lives in CLAUDE.md's placement block.

ev=""
[ -f CLAUDE.md ] && ev="$(grep -m1 -E '^[[:space:]]*-[[:space:]]*\*\*Gate evaluator:\*\*' CLAUDE.md)"
if [ -z "$ev" ]; then
  finding gate.evaluator incomplete "CLAUDE.md: Gate evaluator" \
    "Nothing records which engine evaluates gate/checks.json for this project, or that none does yet." \
    "Add to CLAUDE.md's placement block:  - **Gate evaluator:** <engine and version>  — or: none yet, and why."
elif echo "$ev" | grep -qE '\[[A-Z]|<engine'; then
  finding gate.evaluator incomplete "CLAUDE.md: Gate evaluator" \
    "The Gate evaluator line is still the template placeholder." \
    "Name the engine and version, or write: none yet, and why."
else
  finding gate.evaluator ok "CLAUDE.md: Gate evaluator" \
    "Recorded:$(echo "$ev" | sed 's/.*\*\*Gate evaluator:\*\*//' | cut -c1-80)"
fi

# ── Report ───────────────────────────────────────────────────────────────────

n_ok=0; n_inc=0; n_unv=0
for s in "${STATUSES[@]}"; do
  case "$s" in ok) n_ok=$((n_ok+1));; incomplete) n_inc=$((n_inc+1));; unverified) n_unv=$((n_unv+1));; esac
done
if [ "$n_inc" -gt 0 ]; then ADOPTION="incomplete"; else ADOPTION="complete-except-unverified"; fi
[ "$INSTALLED" -eq 1 ] || ADOPTION="not-installed"

if [ "$JSON" -eq 1 ]; then
  esc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/ }"; printf '%s' "$s"; }
  printf '{\n  "format": "causeway-doctor-v1",\n'
  printf '  "standard_version": "%s",\n' "$(esc "$(sed -n 's/^version=//p' .causeway-lock 2>/dev/null | head -1)")"
  printf '  "states": {\n'
  printf '    "installed": %s,\n' "$([ "$INSTALLED" -eq 1 ] && echo true || echo false)"
  printf '    "integrity": "%s",\n' "$INTEGRITY"
  printf '    "adoption": "%s",\n' "$ADOPTION"
  printf '    "evaluated": "not-determined-by-doctor"\n  },\n'
  printf '  "placement": { "state": "%s", "tier": "%s", "criticality_class": "%s" },\n' \
    "$PLACEMENT_STATE" "$(esc "$P_TIER")" "$(esc "$P_CLASS")"
  printf '  "counts": { "ok": %d, "incomplete": %d, "unverified": %d },\n' "$n_ok" "$n_inc" "$n_unv"
  printf '  "findings": [\n'
  for i in "${!IDS[@]}"; do
    [ "$i" -gt 0 ] && printf ',\n'
    printf '    { "id": "%s", "status": "%s", "subject": "%s", "why": "%s", "remedy": "%s" }' \
      "$(esc "${IDS[$i]}")" "$(esc "${STATUSES[$i]}")" "$(esc "${SUBJECTS[$i]}")" \
      "$(esc "${WHYS[$i]}")" "$(esc "${REMEDIES[$i]}")"
  done
  printf '\n  ]\n}\n'
  exit 0
fi

echo "Causeway doctor — $(pwd)"
echo ""
for i in "${!IDS[@]}"; do
  case "${STATUSES[$i]}" in
    ok)         mark="ok        " ;;
    incomplete) mark="INCOMPLETE" ;;
    *)          mark="unverified" ;;
  esac
  echo "  $mark  ${SUBJECTS[$i]}"
  if [ "${STATUSES[$i]}" != ok ]; then
    echo "              why: ${WHYS[$i]}"
    [ -n "${REMEDIES[$i]}" ] && echo "              fix: ${REMEDIES[$i]}"
  fi
done
echo ""
echo "  installed:   $([ "$INSTALLED" -eq 1 ] && echo yes || echo no)"
echo "  integrity:   $INTEGRITY"
echo "  placement:   $PLACEMENT_STATE"
echo "  adoption:    $ADOPTION  ($n_ok ok, $n_inc incomplete, $n_unv unverified)"
echo "  evaluated:   not determined here — doctor checks setup, not the gate."
echo "               Run your evaluator against gate/checks.json for a verdict."
exit 0
