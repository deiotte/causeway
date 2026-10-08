#!/usr/bin/env bash
# upgrade-starters.sh — offer this release's starter improvements to a project
# that already owns its starters. ADR 0046.
#
#   ./tools/upgrade-starters.sh /path/to/project [--out <dir>]     report only
#   ./tools/upgrade-starters.sh /path/to/project --apply            apply the clean ones
#   ./tools/upgrade-starters.sh /path/to/project --accept <file>... record a hand merge
#
# Run it from the release you are upgrading to, the way you run sync.sh. sync.sh
# seeds a starter once and never touches it again, because the project's names,
# commands, ADR index and reviewers are in it. That keeps a project's edits safe
# and leaves it no way to learn what a later template improved. This compares
# three versions of each starter:
#
#   base     the template as it was seeded (.causeway/starters/<file>.base)
#   yours    the project's file now
#   theirs   this release's template
#
# and says, per file:
#
#   up-to-date    the template has not changed since it was seeded
#   clean         you never edited it; theirs replaces it
#   merge         both changed, in different places; a three-way merge is clean
#   conflict      both changed the same lines. Never applied: the merge with
#                 markers is written to the report directory for you to resolve
#   adopt         no baseline was recorded, but your file is this release's
#                 template exactly, so the baseline can be recorded
#   manual        no baseline was recorded (seeded before v2.6.0) and your file
#                 differs: there is nothing to merge against. The diff is in the
#                 report directory; merge by hand, then --accept
#   absent        the project does not have this file (sync.sh would seed it)
#
# Report mode writes nothing to the project: proposed files, diffs and conflict
# files go to --out (a new temporary directory by default). --apply writes only
# clean, merge and adopt, and records each one's new baseline. --accept records
# this release's template as the baseline for files you merged by hand — it
# changes no file of yours. Running it again after an apply reports up-to-date.
#
# Needs diff3 (GNU diffutils). Offline. Exit 0, or 1 for a usage error.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$STANDARD_DIR/VERSION")"

# Every starter sync.sh seeds, as template:project-path. validate.py checks this
# list against sync.sh's plan_seed calls, so the two cannot drift apart.
STARTERS=(
  "templates/project-CLAUDE.md:CLAUDE.md"
  "templates/open-items.json:decisions/open-items.json"
  "templates/decisions-README.md:decisions/README.md"
  "templates/practitioner-START-HERE.md:START-HERE.md"
  "templates/contributor-START-HERE.md:CONTRIBUTING.md"
  "templates/field-note-issue-form.yml:.github/ISSUE_TEMPLATE/field-note.yml"
  "templates/field-notes-README.md:domain/field-notes/README.md"
  "templates/CODEOWNERS:.github/CODEOWNERS"
  "templates/pull_request_template.md:.github/pull_request_template.md"
)

TARGET=""
OUT=""
MODE=report
ACCEPT=()
while [ $# -gt 0 ]; do
  case "$1" in
    --apply)  MODE=apply; shift ;;
    --accept) MODE=accept; shift
              while [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; do
                if [ -z "$TARGET" ]; then TARGET="$1"; else ACCEPT+=("$1"); fi; shift
              done ;;
    --out)    OUT="${2:?--out needs a directory}"; shift 2 ;;
    -*)       echo "unknown option: $1" >&2; exit 1 ;;
    *)        TARGET="$1"; shift ;;
  esac
done
[ -n "$TARGET" ] && [ -d "$TARGET" ] || {
  echo "usage: upgrade-starters.sh /path/to/project [--apply | --accept <file>... | --out <dir>]" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
command -v diff3 >/dev/null 2>&1 || { echo "upgrade-starters.sh needs diff3 (GNU diffutils)" >&2; exit 1; }

INDEX="$TARGET/.causeway/starters.txt"
sha_of() { sha256sum "$1" | cut -d' ' -f1; }
template_for() {
  local s; for s in "${STARTERS[@]}"; do [ "${s#*:}" = "$1" ] && { echo "${s%%:*}"; return; }; done
}
base_version() { [ -f "$INDEX" ] && awk -v d="$1" '$2==d {print $4}' "$INDEX" | tail -1; }

# Record theirs as the baseline for <dest>: copy the template under
# .causeway/starters/ and rewrite its index line. Writes to the project.
record_baseline() {
  local dest="$1" tmpl="$2" tmp
  mkdir -p "$TARGET/.causeway/starters/$(dirname "$dest")"
  tmp="$(mktemp "$TARGET/.causeway/.base.XXXXXX")"
  cp "$STANDARD_DIR/$tmpl" "$tmp" && mv -f "$tmp" "$TARGET/.causeway/starters/$dest.base"
  tmp="$(mktemp "$TARGET/.causeway/.index.XXXXXX")"
  {
    echo "# sha256-of-baseline  project-file  template  seeded-from — tools/upgrade-starters.sh reads this. ADR 0046."
    { [ -f "$INDEX" ] && grep -v '^#' "$INDEX" | awk -v d="$dest" '$2!=d'
      echo "$(sha_of "$STANDARD_DIR/$tmpl")  $dest  $tmpl  v$VERSION"; } | LC_ALL=C sort -k2
  } > "$tmp"
  mv -f "$tmp" "$INDEX"
}

# ── --accept: record a hand merge ────────────────────────────────────────────
if [ "$MODE" = accept ]; then
  [ "${#ACCEPT[@]}" -gt 0 ] || { echo "--accept needs at least one project file" >&2; exit 1; }
  for dest in "${ACCEPT[@]}"; do
    tmpl="$(template_for "$dest")"
    [ -n "$tmpl" ] || { echo "not a Causeway starter: $dest" >&2; exit 1; }
    [ -f "$TARGET/$dest" ] || { echo "no such file in the project: $dest" >&2; exit 1; }
  done
  mkdir -p "$TARGET/.causeway"
  for dest in "${ACCEPT[@]}"; do
    record_baseline "$dest" "$(template_for "$dest")"
    echo "  accepted  $dest — baseline is now v$VERSION; your file was not changed"
  done
  exit 0
fi

# ── Report (and --apply) ─────────────────────────────────────────────────────
# Checked before anything is created: refusing an --out inside the project after
# making the directory would be a refusal that wrote.
if [ -n "$OUT" ]; then
  case "$OUT" in /*) ;; *) OUT="$(pwd)/$OUT" ;; esac
  probe="$OUT"; while [ ! -d "$probe" ]; do probe="$(dirname "$probe")"; done
  case "$(cd "$probe" && pwd)/${OUT#"$probe"}/" in
    "$TARGET"/*) echo "--out must be outside the project" >&2; exit 1 ;;
  esac
  mkdir -p "$OUT"
else
  OUT="$(mktemp -d "${TMPDIR:-/tmp}/causeway-upgrade.XXXXXX")"
fi
OUT="$(cd "$OUT" && pwd)"

DESTS=(); STATES=(); NOTES=()
note() { DESTS+=("$1"); STATES+=("$2"); NOTES+=("$3"); }

for s in "${STARTERS[@]}"; do
  tmpl="${s%%:*}"; dest="${s#*:}"
  yours="$TARGET/$dest"; theirs="$STANDARD_DIR/$tmpl"; base="$TARGET/.causeway/starters/$dest.base"
  if [ ! -f "$yours" ]; then
    note "$dest" absent "not in this project; sync.sh would seed it"; continue
  fi
  mkdir -p "$OUT/$(dirname "$dest")"
  if [ ! -f "$base" ]; then
    if cmp -s "$yours" "$theirs"; then
      note "$dest" adopt "identical to v$VERSION's template; its baseline can be recorded"
    else
      diff -u --label "yours/$dest" --label "v$VERSION/$tmpl" "$yours" "$theirs" > "$OUT/$dest.diff" || true
      note "$dest" manual "no baseline recorded, so your edits cannot be told from upstream's. Review $OUT/$dest.diff, merge by hand, then --accept $dest"
    fi
    continue
  fi
  bv="$(base_version "$dest")"; bv="${bv:-unknown}"
  if cmp -s "$base" "$theirs"; then
    note "$dest" up-to-date "template unchanged since $bv"
  elif cmp -s "$yours" "$base"; then
    cp "$theirs" "$OUT/$dest.proposed"
    diff -u --label "yours/$dest" --label "proposed/$dest" "$yours" "$theirs" > "$OUT/$dest.diff" || true
    note "$dest" clean "never edited here; v$VERSION's template replaces it ($bv → v$VERSION)"
  else
    rc=0
    diff3 -m -L "yours" -L "base $bv" -L "causeway v$VERSION" "$yours" "$base" "$theirs" \
      > "$OUT/$dest.merged" || rc=$?
    if [ "$rc" -eq 0 ]; then
      mv "$OUT/$dest.merged" "$OUT/$dest.proposed"
      diff -u --label "yours/$dest" --label "proposed/$dest" "$yours" "$OUT/$dest.proposed" > "$OUT/$dest.diff" || true
      note "$dest" merge "your edits and v$VERSION's changes merge cleanly ($bv → v$VERSION)"
    elif [ "$rc" -eq 1 ]; then
      mv "$OUT/$dest.merged" "$OUT/$dest.conflict"
      n="$(grep -c '^<<<<<<< ' "$OUT/$dest.conflict" || true)"
      note "$dest" conflict "$n conflicting region(s). Resolve $OUT/$dest.conflict into your file, then --accept $dest"
    else
      echo "diff3 failed on $dest" >&2; exit 1
    fi
  fi
done

if [ "$MODE" = apply ]; then
  mkdir -p "$TARGET/.causeway"
  for i in "${!DESTS[@]}"; do
    dest="${DESTS[$i]}"; tmpl="$(template_for "$dest")"
    case "${STATES[$i]}" in
      clean|merge)
        tmp="$(mktemp "$TARGET/.causeway/.apply.XXXXXX")"
        cp "$OUT/$dest.proposed" "$tmp" && chmod --reference="$TARGET/$dest" "$tmp" 2>/dev/null || true
        mv -f "$tmp" "$TARGET/$dest"
        record_baseline "$dest" "$tmpl"
        STATES[$i]="applied-${STATES[$i]}" ;;
      adopt)
        record_baseline "$dest" "$tmpl"
        STATES[$i]="applied-adopt" ;;
    esac
  done
fi

echo "Causeway starters — v$VERSION against $TARGET"
echo ""
pending=0
for i in "${!DESTS[@]}"; do
  printf '  %-15s %s\n' "${STATES[$i]}" "${DESTS[$i]}"
  printf '  %-15s %s\n' "" "${NOTES[$i]}"
  case "${STATES[$i]}" in clean|merge|adopt|conflict|manual) pending=$((pending+1)) ;; esac
done
echo ""
echo "  report: $OUT"
if [ "$MODE" = report ] && [ "$pending" -gt 0 ]; then
  echo "  Nothing was changed. Review the .diff files, then run with --apply to take"
  echo "  the clean, merge and adopt ones. conflict and manual are never applied."
elif [ "$MODE" = apply ]; then
  echo "  Applied clean, merge and adopt. conflict and manual are left for you."
fi
exit 0
