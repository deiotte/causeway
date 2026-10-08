#!/usr/bin/env bash
# build-archive.sh — produce the release archive a consumer installs from.
#
#   ./tools/build-archive.sh [--out <dir>]
#
# Writes causeway-<version>.tar.gz, causeway-<version>.zip, and a .sha256
# beside each. The archive contains everything tools/sync.sh reads and nothing
# else: the bundle, the templates and adapters sync writes, the three consumer
# tools, the trust anchor, and — when a release has been signed — the release
# statement and its signature.
#
# Why this exists. Until v1.14.0 the only documented way to obtain the standard
# was `git clone`, and the quickstart said so. That puts three requirements on
# every machine that installs the standard: git, credentials for a private
# repository, and network reachability at install time. None of the three is a
# property of the standard; all three are properties of one convenient way of
# moving bytes. The first program to consume Causeway delivers into environments
# that have none of them — which is the same premise ADR 0019 used to choose SSH
# signing over a log-backed scheme, applied to acquisition rather than to trust.
#
# What the archive changes, stated precisely: it separates acquisition from
# installation. One machine that has git, credentials and egress fetches one
# file. That file then installs on any number of machines that have none of
# those things, over any transport that moves a file. It does not make a private
# repository public and it does not remove authentication — the first fetch is
# still authenticated. It removes the *per-machine* enrollment, which is the
# part that scales with the fleet.
#
# Determinism is load-bearing, for the same reason it is in build-bundle.sh and
# for one more. The same reason: a digest that changes for reasons unrelated to
# content is a digest nobody can check. The additional one: an archive that
# travels by USB stick and file share arrives over a transport with no integrity
# of its own, so `sha256sum -c` at the far end is the only thing standing
# between a consumer and a truncated copy — and a checksum is worth publishing
# only if anyone can rebuild the bytes it describes. Files are staged with
# normalized modes and a fixed mtime taken from RELEASED, sorted by name, owned
# by 0:0, and gzipped with -n so no timestamp enters the header.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$STANDARD_DIR"

OUT="dist"
while [ $# -gt 0 ]; do
  case "$1" in
    --out)   OUT="${2:?--out needs a directory}"; shift 2 ;;
    --out=*) OUT="${1#*=}"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

VERSION="$(cat VERSION)"
RELEASED="$(cat RELEASED)"
BASE="causeway-$VERSION"

# GNU tar, explicitly. bsdtar has no --sort, so on macOS this would silently
# produce an archive whose entry order follows readdir — still a valid archive,
# and no longer the bytes the published checksum describes. A tool that quietly
# degrades the one property it exists to provide is the "check that can only
# pass" this repository keeps finding in its own scripts.
if ! tar --version 2>/dev/null | head -1 | grep -qi 'gnu tar'; then
  echo "build-archive.sh needs GNU tar (--sort, --mtime, --numeric-owner)." >&2
  echo "  macOS: brew install gnu-tar, then run with PATH=\"\$(brew --prefix)/opt/gnu-tar/libexec/gnubin:\$PATH\"" >&2
  exit 1
fi
command -v python3 >/dev/null 2>&1 || {
  echo "build-archive.sh needs python3 for the deterministic zip writer" >&2; exit 1; }

# Everything sync.sh reads out of $STANDARD_DIR. Kept honest by tools/validate.py
# §19, which parses sync.sh and fails when it reads a path this list does not
# ship — because the symptom of getting that wrong appears only in a consumer,
# on a machine with no git and no way to fetch the missing file.
#
# What is deliberately absent: README.md, CHANGELOG.md, decisions/,
# conformance/, bundle/scope.json, .github/, and the four tools that publish
# rather than install (build-bundle.sh, build-archive.sh, sign-release.sh,
# render-adapters.sh, validate.py). A consumer installing the standard does not
# need this repository's own decision record or the machinery that builds it,
# and shipping them would invite a reader to treat Causeway's ADRs as theirs.
ARCHIVE_FILES=(
  "LICENSE"
  "NOTICE"
  "VERSION"
  "RELEASED"
  "AGENTS.md"
  "gate/profiles.json"
  "gate/checks.json"
  "gate/gate-configuration.md"
  "skills/decision-spine/SKILL.md"
  "skills/decision-spine/reference/spine.md"
  "skills/decision-spine/reference/gate-profiles.md"
  "skills/decision-spine/reference/placement.md"
  "skills/decision-spine/reference/references.md"
  "skills/field-note/SKILL.md"
  "skills/survey/SKILL.md"
  "rules/security.md"
  "rules/secrets.md"
  "rules/database.md"
  "rules/tests.md"
  "rules/dependencies.md"
  "rules/inference.md"
  "templates/adr-template.md"
  "templates/adr-waiver-template.md"
  "templates/adr-retroactive-template.md"
  "templates/survey.md"
  "templates/field-note.md"
  "templates/field-note-issue-form.yml"
  "templates/field-notes-README.md"
  "templates/decisions-README.md"
  "templates/open-items.json"
  "templates/practitioner-START-HERE.md"
  "templates/contributor-START-HERE.md"
  "templates/pull_request_template.md"
  "templates/project-CLAUDE.md"
  "templates/CODEOWNERS"
  "adapters/CLAUDE.md"
  "adapters/GEMINI.md"
  "adapters/copilot-instructions.md"
  "adapters/.cursor/rules/causeway.mdc"
  "bundle/manifest.json"
  "bundle/allowed-signers"
  "tools/sync.sh"
  "tools/check-drift.sh"
  "tools/verify-release.sh"
)

# Overlays, all of them. sync.sh vendors the one a project asks for, so the
# archive has to carry every one a project could ask for — a --overlay that
# worked from a clone and failed from an archive would make the archive a
# second-class path, which is the thing this change exists to end.
while IFS= read -r o; do
  [ "$(basename "$o" .md)" = "README" ] || ARCHIVE_FILES+=("$o")
done < <(find overlays -name '*.md' | LC_ALL=C sort)
while IFS= read -r o; do
  ARCHIVE_FILES+=("$o")
done < <(find overlays -name '*.json' | LC_ALL=C sort)

# The signature material, when this tree has been signed. Carried *inside* the
# archive rather than published beside it, so that the whole trust chain is one
# file: the bytes, the statement naming their digest, the signature over that
# statement, and the anchor the signature verifies against. A consumer who has
# to fetch a second and third file to check the first will, on the day it is
# inconvenient, check nothing.
#
# The statement cannot be covered by the bundle digest — it contains that digest
# — so its integrity comes from the signature alone, which is the correct
# mechanism and not a gap.
SIGNED=0
if [ -f "bundle/release.statement" ] && [ -f "bundle/release.statement.sig" ]; then
  ARCHIVE_FILES+=("bundle/release.statement" "bundle/release.statement.sig")
  SIGNED=1
fi

for f in "${ARCHIVE_FILES[@]}"; do
  [ -f "$f" ] || { echo "archive: missing file: $f" >&2; exit 1; }
done

EPOCH="$(date -u -d "$RELEASED" +%s 2>/dev/null)" || {
  echo "archive: RELEASED ($RELEASED) is not a date this tar can pin an mtime to" >&2
  exit 1; }

# Stage with normalized modes. Git stores one bit of mode and the working tree
# supplies the rest from whatever umask was in effect, and bundle/release.statement
# is written by a signing step that runs under `umask 077` — so the modes on
# disk are not a property of the release. Normalizing here makes them one.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
for f in "${ARCHIVE_FILES[@]}"; do
  mkdir -p "$STAGE/$BASE/$(dirname "$f")"
  cp "$f" "$STAGE/$BASE/$f"
  case "$f" in
    *.sh) chmod 755 "$STAGE/$BASE/$f" ;;
    *)    chmod 644 "$STAGE/$BASE/$f" ;;
  esac
done

mkdir -p "$OUT"
OUT_ABS="$(cd "$OUT" && pwd)"

tar --format=gnu \
    --sort=name \
    --numeric-owner --owner=0 --group=0 \
    --mtime="@$EPOCH" \
    -C "$STAGE" -cf - "$BASE" \
  | gzip -9n > "$OUT_ABS/$BASE.tar.gz"

# zip, because a machine that can open an archive by double-clicking it needs
# no instructions, and because Windows before 10 1803 has no tar. Written
# through python3 rather than `zip` for the same reason tar is pinned to GNU:
# the zip(1) command has no way to fix entry order or timestamps, so the one
# property the checksum depends on would be left to the filesystem.
python3 - "$STAGE" "$OUT_ABS/$BASE.zip" "$BASE" <<'PY'
import os, sys, zipfile

stage, out, base = sys.argv[1], sys.argv[2], sys.argv[3]

# The zip format stores MS-DOS timestamps: two-second granularity, no timezone,
# and no representation for anything before 1980. RELEASED cannot be encoded
# faithfully, so rather than encode it approximately every entry gets the epoch
# of the format itself. A constant is honest; a rounded date is a date someone
# will later read as meaningful.
DOS_EPOCH = (1980, 1, 1, 0, 0, 0)

paths = []
for dirpath, dirnames, filenames in os.walk(os.path.join(stage, base)):
    dirnames.sort()
    for name in sorted(filenames):
        full = os.path.join(dirpath, name)
        paths.append((os.path.relpath(full, stage), full))
paths.sort()

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for arcname, full in paths:
        info = zipfile.ZipInfo(arcname.replace(os.sep, "/"), date_time=DOS_EPOCH)
        info.compress_type = zipfile.ZIP_DEFLATED
        # create_system 3 marks the entry as Unix, which is what makes the mode
        # in external_attr mean anything to unzip. Without it the executable bit
        # on the three tools is dropped and `./sync.sh` fails on extraction.
        info.create_system = 3
        mode = 0o755 if arcname.endswith(".sh") else 0o644
        info.external_attr = (0o100000 | mode) << 16
        with open(full, "rb") as fh:
            z.writestr(info, fh.read())
PY

( cd "$OUT_ABS" && sha256sum "$BASE.tar.gz" > "$BASE.tar.gz.sha256" )
( cd "$OUT_ABS" && sha256sum "$BASE.zip"    > "$BASE.zip.sha256" )

echo "Causeway archive v$VERSION ($RELEASED) — ${#ARCHIVE_FILES[@]} files"
if [ "$SIGNED" -eq 1 ]; then
  echo "  signed: release.statement and .sig are inside the archive"
else
  echo "  NOTE: this tree carries no bundle/release.statement — the archive is"
  echo "        unsigned, and a consumer installing from it cannot satisfy"
  echo "        --require-release. Run tools/sign-release.sh first, or publish"
  echo "        from the release workflow, which signs before it archives."
fi
for a in "$BASE.tar.gz" "$BASE.zip"; do
  echo "  $OUT/$a  $(cut -d' ' -f1 < "$OUT_ABS/$a.sha256")"
done
