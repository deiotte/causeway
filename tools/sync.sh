#!/usr/bin/env bash
# sync.sh — vendor the Causeway standard into a consuming project.
#
#   ./sync.sh /path/to/project [--overlay <name>] [--require-release]
#
# Copies the standard in and writes .causeway-lock recording the version and
# per-file checksums. check-drift.sh verifies that lock in CI.
#
# Runs from a git checkout or from an extracted release archive, and neither is
# the degraded one. The archive is the ordinary route for a machine that is not
# a developer workstation: it needs tar or unzip, bash, sha256sum and coreutils,
# and it needs them only at install time. No git, no credential for a private
# repository, no network. See tools/build-archive.sh and ADR 0030.
#
# --require-release refuses to sync unless this checkout is a published release:
# clean tree, HEAD exactly at a tag, or a release statement that verifies — and
# in every case content that matches the bundle manifest. Use it in anything that
# builds for a real environment. Without it a sync from an arbitrary branch
# commit succeeds and writes a lock indistinguishable from a release pin — which
# is how a vendored copy came to be pinned to an unmerged pull request branch
# with nothing complaining. See ADR 0015.
#
# --overlay additionally vendors a platform overlay (overlays/<name>.md) and
# records the choice in the lock. Overlays are opt-in: a Go service has no
# business carrying the ServiceNow disposition table. See overlays/README.md.
#
# An installation either completes or changes nothing. ADR 0042.
#
#   1. Decide.  Arguments, overlay, source content, release proof, and the
#               --require-release refusal. Nothing in the target is touched.
#   2. Plan.    Every file this run would write, and every conflict in the
#               target that would stop it. Still nothing touched.
#   3. Stage.   The planned files and the lock are written to a staging
#               directory inside the target and checked against the source.
#   4. Apply.   Staged files move into place, the lock last. A failure here
#               restores what was overwritten and removes what was created.
#
# Until v2.3.1 the order was copy, then decide — so a refusal could exit 7 with
# the target half-updated and no new lock to say so.
#
# Exit 0 installed · 1 usage or source error · 7 not a release under
# --require-release · 9 target conflict · 10 apply failed and was rolled back.
set -euo pipefail

STANDARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$STANDARD_DIR/VERSION")"
RELEASED="$(cat "$STANDARD_DIR/RELEASED")"

TARGET=""
OVERLAY=""
REQUIRE_RELEASE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --overlay)        OVERLAY="${2:?--overlay needs a name}"; shift 2 ;;
    --overlay=*)      OVERLAY="${1#*=}"; shift ;;
    --require-release) REQUIRE_RELEASE=1; shift ;;
    -*)               echo "unknown option: $1" >&2; exit 1 ;;
    *)                TARGET="$1"; shift ;;
  esac
done
: "${TARGET:?usage: sync.sh /path/to/project [--overlay <name>] [--require-release]}"

[ -d "$TARGET" ] || { echo "not a directory: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

if [ -n "$OVERLAY" ] && [ ! -f "$STANDARD_DIR/overlays/$OVERLAY.md" ]; then
  echo "no such overlay: $OVERLAY" >&2
  echo "available:" >&2
  for o in "$STANDARD_DIR"/overlays/*.md; do
    b="$(basename "$o" .md)"; [ "$b" = "README" ] || echo "  $b" >&2
  done
  exit 1
fi

# Prerequisites, checked before anything else needs them rather than discovered
# halfway through a copy.
for tool in sha256sum sed sort awk cmp mktemp cp mv; do
  command -v "$tool" >/dev/null 2>&1 || { echo "missing prerequisite: $tool" >&2; exit 1; }
done

# Best-effort guard: the gate's standard-currency check is only as honest as
# RELEASED, and nothing forces it to move when VERSION does. Needs git, so a
# tarball mirror silently skips it — see gate-configuration.md §10 item 6.
if command -v git >/dev/null 2>&1 && git -C "$STANDARD_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  version_touched="$(git -C "$STANDARD_DIR" log -1 --format=%cs -- VERSION 2>/dev/null || true)"
  if [ -n "$version_touched" ] && [[ "$RELEASED" < "$version_touched" ]]; then
    echo "  WARNING: RELEASED ($RELEASED) predates the last change to VERSION ($version_touched)."
    echo "           Update RELEASED with the version bump, or standard-currency"
    echo "           will measure this copy as older than it is."
  fi
fi

echo "Causeway standard v$VERSION ($RELEASED) -> $TARGET"
[ -n "$OVERLAY" ] && echo "  platform overlay: $OVERLAY"

# Files vendored verbatim. Anything not on this list is the project's own.
VENDORED=(
  "AGENTS.md"
  "skills/decision-spine/SKILL.md"
  "skills/decision-spine/reference/spine.md"
  "skills/decision-spine/reference/gate-profiles.md"
  # Vendored for the same reason spine.md is: it is read at the moment a project
  # has no placement yet, which is the moment nothing else in the copy can help.
  "skills/decision-spine/reference/placement.md"
  "skills/decision-spine/reference/references.md"
  # The practitioner capture path, vendored so an agent in a consuming project
  # reads the same interview rules and the same note shape the standard ships.
  # A project whose agent invented its own interview would be collecting
  # something it called a field note and the promotion table could not read.
  "skills/field-note/SKILL.md"
  # The intake instrument. Vendored for the reason the field-note skill is: a
  # project whose agent invented its own Survey would still be producing something
  # it called one, and the ADR fields that cite its row IDs would be reading a
  # different artifact than the one the readiness test was written against.
  "skills/survey/SKILL.md"
  "gate/profiles.json"
  "gate/checks.json"
  "gate/gate-configuration.md"
  "bundle/manifest.json"
  "templates/adr-template.md"
  "templates/adr-waiver-template.md"
  "templates/adr-retroactive-template.md"
  "templates/survey.md"
  "templates/field-note.md"
  "rules/security.md"
  "rules/secrets.md"
  "rules/database.md"
  "rules/tests.md"
  "rules/dependencies.md"
  "rules/inference.md"
  # The consumer-facing drift check itself. sync.sh has printed "Add
  # check-drift.sh to CI" since v1.0 and never shipped the script, so the
  # instruction could only be followed by someone who also had a clone of the
  # standard. Vendored and checksummed like everything else — a drift checker a
  # project can edit is a project deciding its own drift policy.
  "tools/check-drift.sh"
  # The release verifier travels with the standard for the same reason the drift
  # checker does: a consumer told to verify a signature and not given the tool
  # can only follow the instruction by cloning the standard, which is the step
  # vendoring exists to remove.
  "tools/verify-release.sh"
  # The adoption diagnostic. Vendored for the reason the drift checker is: it
  # runs in the consuming project, and a project told to run it and not given
  # it could only follow the instruction with a clone of the standard. ADR 0045.
  "tools/doctor.sh"
  # The field-note queue: who owes which practitioner an answer. Vendored for
  # the reason doctor.sh is — it runs in the consuming project. ADR 0048.
  "tools/field-notes.sh"
  # Which accepted decisions rest on a constraint that just changed. ADR 0049.
  "tools/impact.sh"
)

# The trust anchor for release signatures. Vendored so a consuming project can
# verify a release offline, with no clone of the standard and no network — the
# whole point of choosing SSH signing over a log-backed scheme (ADR 0019).
#
# Issued at v1.8.0. The anchor is in BUNDLE_FILES in build-bundle.sh, so it is
# covered by the bundle digest: a trust anchor that could be swapped without
# moving the digest would not be one. validate.py checks both halves stayed
# together, in either direction.
#
# Still appended conditionally rather than listed in VENDORED above. The
# condition is no longer "not issued yet" — it is a checkout that does not have
# the file, which a consumer can reach by syncing from a tag cut before v1.8.0.
# Warning and continuing is right there: the copy is unsigned-verifiable, not
# broken, and check-drift.sh still covers everything else in it.
if [ -f "$STANDARD_DIR/bundle/allowed-signers" ]; then
  VENDORED+=("bundle/allowed-signers")
else
  echo "  note: no bundle/allowed-signers in this checkout — it predates v1.8.0,"
  echo "        where release signing was issued. verify-release.sh will have no"
  echo "        trust anchor in this project. Re-sync from v1.8.0 or later."
fi

# The overlay is vendored and checksummed like everything else. An overlay a
# project can edit is a project deciding its own dispositions, and dispositions
# are the one thing in here that looks like it grants relief.
# The .json is the same overlay, machine-readable. It ships with the prose
# rather than on request: a project that vendored only the markdown would have
# to parse it to get the dispositions, which is the reimplementation this file
# exists to prevent.
if [ -n "$OVERLAY" ]; then
  VENDORED+=("overlays/$OVERLAY.md")
  [ -f "$STANDARD_DIR/overlays/$OVERLAY.json" ] && VENDORED+=("overlays/$OVERLAY.json")
fi

missing_src=""
for f in "${VENDORED[@]}"; do
  [ -f "$STANDARD_DIR/$f" ] || missing_src="$missing_src $f"
done
if [ -n "$missing_src" ]; then
  echo "  ERROR: this copy of the standard is incomplete — missing:$missing_src" >&2
  exit 1
fi

# ── 1. Decide ────────────────────────────────────────────────────────────────

# `digest=` is the provenance half and `commit=` locates it upstream. The
# per-file checksums below prove the vendored copy is internally consistent —
# that nobody edited it locally — and they cannot prove it came from us, because
# a local recalculation is exactly what an edited copy would also produce. The
# digest is the value an engine checks against a published release, and the two
# answer different questions: check-drift.sh asks "has this copy been touched",
# the digest asks "is this copy ours".
BUNDLE_DIGEST="$(sed -n 's/.*"digest"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$STANDARD_DIR/bundle/manifest.json" | head -1)"
if [ -z "$BUNDLE_DIGEST" ]; then
  echo "  ERROR: bundle/manifest.json has no digest — run ./tools/build-bundle.sh" >&2
  exit 1
fi

# Does the content on disk match the manifest it is about to be pinned under?
#
# A release proof names a digest. It says nothing about the files beside it: a
# genuine statement and an untouched manifest verify exactly as well next to an
# edited AGENTS.md, and until v2.3.1 that copy installed under --require-release
# as a signed release. So every file the manifest lists is hashed here, and the
# digest is recomputed from those lines the way build-bundle.sh computes it — an
# edited manifest that kept its old digest field fails the second half.
CONTENT_OK=1
CONTENT_PROBLEMS=()
MANIFEST_LINES="$(sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)"[[:space:]]*,[[:space:]]*"sha256"[[:space:]]*:[[:space:]]*"\([0-9a-f]*\)".*/\2  \1/p' \
  "$STANDARD_DIR/bundle/manifest.json")"
if [ -z "$MANIFEST_LINES" ]; then
  CONTENT_OK=0
  CONTENT_PROBLEMS+=("bundle/manifest.json lists no files")
else
  while IFS= read -r line; do
    want="${line%%  *}"
    path="${line#*  }"
    if [ ! -f "$STANDARD_DIR/$path" ]; then
      CONTENT_OK=0; CONTENT_PROBLEMS+=("missing  $path")
    elif [ "$(sha256sum "$STANDARD_DIR/$path" | cut -d' ' -f1)" != "$want" ]; then
      CONTENT_OK=0; CONTENT_PROBLEMS+=("changed  $path")
    fi
  done <<< "$MANIFEST_LINES"
  RECOMPUTED="sha256:$(printf '%s\n' "$MANIFEST_LINES" | LC_ALL=C sort -k2 | sha256sum | cut -d' ' -f1)"
  if [ "$RECOMPUTED" != "$BUNDLE_DIGEST" ]; then
    CONTENT_OK=0
    CONTENT_PROBLEMS+=("digest   bundle/manifest.json says $BUNDLE_DIGEST, its own entries hash to $RECOMPUTED")
  fi
fi

# Provenance: which commit, and whether that commit is a published release.
#
# `commit=` alone cannot answer the second question. A lock naming an arbitrary
# branch commit and a lock naming a released one are the same four lines, so a
# reader cannot tell a deliberate pin from an accidental one. `tag=` is the
# missing half: present only when this checkout sits exactly on a tag, absent
# when it does not, and never inferred.
COMMIT=""
TAG=""
DIRTY=0
IS_RELEASE=0
HAS_GIT=0
RELEASE_PROOF="none"
if command -v git >/dev/null 2>&1 && git -C "$STANDARD_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  HAS_GIT=1
  COMMIT="$(git -C "$STANDARD_DIR" rev-parse HEAD 2>/dev/null || true)"
  # --exact-match: a tag reachable from HEAD is not the same as HEAD being that
  # release. describe without it would happily name the last tag before this
  # commit and make every later commit look released.
  TAG="$(git -C "$STANDARD_DIR" describe --exact-match --tags HEAD 2>/dev/null || true)"
  if [ -n "$(git -C "$STANDARD_DIR" status --porcelain 2>/dev/null)" ]; then
    DIRTY=1
    TAG=""
    COMMIT="${COMMIT}-dirty"
  fi
  if [ -n "$TAG" ]; then
    IS_RELEASE=1
    RELEASE_PROOF="git-tag"
  fi
fi

# No git, or git that cannot name a release: ask the signature instead.
#
# This is not a weaker check standing in for a stronger one. It is the stronger
# one. `git describe --exact-match` proves that some local clone has a tag
# pointing at HEAD, and a tag is a local, unauthenticated, rewritable label —
# `git tag v99.0.0` forges it in one command, and a mirror can ship whatever
# tags it likes. The signed statement proves that a key in bundle/allowed-signers
# attested this exact bundle digest under the causeway-release namespace, and it
# proves it with no network, no keyring and no clone.
#
# So the ordering here is not preference, it is history: git went first because
# it was what existed in v1.0, and the better evidence was added in v1.8.0 and
# left optional. Either one establishes a release; the lock records which. ADR 0030.
SIG_STATE=""
if [ "$IS_RELEASE" -ne 1 ] && [ "$DIRTY" -ne 1 ]; then
  STATEMENT="$STANDARD_DIR/bundle/release.statement"
  if [ -f "$STATEMENT" ] && [ -f "$STATEMENT.sig" ] \
     && [ -f "$STANDARD_DIR/bundle/allowed-signers" ]; then
    # --lock /dev/null: verify-release.sh compares a statement against a
    # consuming project's .causeway-lock whenever it finds one, and the lock
    # this run is about to write is not there to compare against. /dev/null is
    # not a regular file, so the comparison is skipped rather than run against
    # whatever lock happens to be in the directory sync was invoked from.
    VERIFY_RC=0
    VERIFY_OUT="$( cd "$STANDARD_DIR" \
      && bash tools/verify-release.sh --lock /dev/null 2>&1 )" || VERIFY_RC=$?
    case "$VERIFY_RC" in
      0)
        S_VERSION="$(sed -n 's/^version=//p' "$STATEMENT" | head -1)"
        S_TAG="$(sed -n 's/^tag=//p' "$STATEMENT" | head -1)"
        S_COMMIT="$(sed -n 's/^commit=//p' "$STATEMENT" | head -1)"
        if [ -n "$S_TAG" ] && [ "$S_VERSION" = "$VERSION" ]; then
          TAG="$S_TAG"
          COMMIT="$S_COMMIT"
          IS_RELEASE=1
          RELEASE_PROOF="signed-statement"
        else
          # A statement that verifies but describes a different version is the
          # substitution verify-release.sh warns about, arriving one layer up.
          SIG_STATE="other-version"
          echo "  WARNING: bundle/release.statement verifies but signs v$S_VERSION,"
          echo "           and this copy says v$VERSION. Not treating it as a release."
        fi
        ;;
      5)
        # Material absent or ssh-keygen missing. Said plainly, because "cannot
        # check" and "checked and it failed" are different positions and only
        # one of them means do not ship this.
        SIG_STATE="unavailable"
        echo "  note: cannot check the release signature here — ssh-keygen is"
        echo "        missing, or the statement and .sig are not in this copy."
        ;;
      *)
        SIG_STATE="invalid"
        echo "  WARNING: bundle/release.statement is present and does NOT verify."
        echo "           Run tools/verify-release.sh in the standard directory to"
        echo "           see why. Not treating this copy as a release."
        ;;
    esac
  fi
fi

# A release proof over content that does not match is not a release. The tag or
# the signature still names the release these bytes claim to be; the bytes are
# not it, and the lock must not say they are.
if [ "$CONTENT_OK" -ne 1 ]; then
  echo "  WARNING: this copy does not match its own bundle manifest:"
  for p in "${CONTENT_PROBLEMS[@]}"; do echo "             $p"; done
  if [ "$IS_RELEASE" -eq 1 ]; then
    echo "           ${TAG} names a release; these bytes are not it."
  fi
  IS_RELEASE=0
  TAG=""
  RELEASE_PROOF="none"
fi

if [ "$DIRTY" -eq 1 ]; then
  echo "  WARNING: syncing from a dirty working tree. The digest in this lock"
  echo "           will not match any published release."
elif [ "$IS_RELEASE" -eq 1 ]; then
  if [ "$RELEASE_PROOF" = "signed-statement" ]; then
    echo "  release: $TAG — verified signature, offline"
  else
    echo "  release: $TAG — tag at HEAD"
  fi
elif [ "$CONTENT_OK" -eq 1 ]; then
  echo "  WARNING: this copy is not a published release."
  if [ "$HAS_GIT" -eq 1 ]; then
    echo "           No tag at HEAD, and no verified release statement either."
  else
    echo "           No git history to read, and no verified release statement"
    echo "           in bundle/ to read instead."
  fi
  echo "           The lock will record a copy with no tag beside it. That is"
  echo "           fine for development and wrong for anything that ships."
  echo "           Use --require-release to make this a hard failure."
fi

if [ "$REQUIRE_RELEASE" -eq 1 ] && [ "$IS_RELEASE" -ne 1 ]; then
  echo "" >&2
  echo "  REFUSING: --require-release was given and this is not a release." >&2
  echo "            Nothing in $TARGET was changed." >&2
  if [ "$CONTENT_OK" -ne 1 ]; then
    echo "            The files above do not match bundle/manifest.json, so no" >&2
    echo "            tag or signature can make this copy the release it names." >&2
    echo "            Get a fresh copy of the release and do not edit it." >&2
  elif [ "$DIRTY" -eq 1 ]; then
    echo "            The working tree is dirty. Commit or stash, then check out a tag." >&2
  elif [ "$SIG_STATE" = "invalid" ]; then
    echo "            The release signature in bundle/ does not verify. Do not" >&2
    echo "            install this copy; get the release again from its source." >&2
  elif [ "$SIG_STATE" = "unavailable" ] && [ "$HAS_GIT" -ne 1 ]; then
    echo "            The release signature could not be checked — ssh-keygen" >&2
    echo "            is not installed here. Install openssh-client and re-run." >&2
  elif [ "$HAS_GIT" -eq 1 ]; then
    echo "            HEAD is not at a tag. Check out a published release:" >&2
    echo "                git -C \"$STANDARD_DIR\" checkout v$VERSION" >&2
  else
    # Until v1.14.0 this branch did not exist and the git advice above was
    # printed unconditionally — telling someone who had just extracted a tarball
    # to run git checkout inside it. An instruction that cannot be followed is
    # worse than no instruction: it reads as the reader's fault.
    echo "            This copy has no git history, and bundle/ has no release" >&2
    echo "            statement that verifies — so nothing here can say which" >&2
    echo "            release these bytes are." >&2
    echo "" >&2
    echo "            You are installing from an archive built before a release" >&2
    echo "            was signed, or from one whose signature material was" >&2
    echo "            stripped. Get a published archive — the statement and its" >&2
    echo "            signature travel inside it:" >&2
    echo "" >&2
    echo "                causeway-$VERSION.tar.gz   (or .zip)" >&2
    echo "                from the release page, verified with its .sha256" >&2
    echo "" >&2
    echo "            then re-run this from the extracted directory." >&2
  fi
  exit 7
fi

# ── 2. Plan ──────────────────────────────────────────────────────────────────
#
# PLAN_SRC[i] is written to PLAN_DST[i], relative to the target. "Always" files
# are replaced on every sync; "seed" files are written only when absent and then
# belong to the project. Messages are held until the apply succeeds, so nothing
# claims to have created a file that a refusal or a rollback then did not.

PLAN_SRC=()
PLAN_DST=()
NOTES=()
CONFLICTS=()

# Files this run generates rather than copies — the merged instruction files
# below. Outside the target: planning still writes nothing there.
GEN="$(mktemp -d)"
STAGE=""
trap 'rm -rf "$GEN"' EXIT

plan_always() { PLAN_SRC+=("$1"); PLAN_DST+=("$2"); }

# A seeded starter also records its baseline: the template exactly as seeded,
# under .causeway/starters/, and a line in .causeway/starters.txt. That is what
# lets tools/upgrade-starters.sh tell the project's edits from upstream's later,
# three ways. Outside the lock on purpose: the starter is the project's, so its
# baseline is the project's too, and check-drift.sh has no business with either.
# ADR 0046.
SEEDED=()
plan_seed() {
  if [ -e "$TARGET/$2" ] || [ -L "$TARGET/$2" ]; then
    NOTES+=("${4-  $2 exists, left alone}")
  else
    PLAN_SRC+=("$1"); PLAN_DST+=("$2"); NOTES+=("$3")
    plan_always "$1" ".causeway/starters/$2.base"
    SEEDED+=("$(sha_of "$1")  $2  ${1#"$STANDARD_DIR"/}  v$VERSION")
  fi
}

sha_of() { sha256sum "$1" | cut -d' ' -f1; }

# Does this path, if it is a symlink, resolve to the target's AGENTS.md? A
# project that links GEMINI.md or CLAUDE.md to AGENTS.md has already pointed
# that tool at the standard, by the most direct means there is.
links_to_agents() {
  [ -L "$TARGET/$1" ] || return 1
  [ "$(readlink -f "$TARGET/$1" 2>/dev/null)" = "$(readlink -f "$TARGET/AGENTS.md" 2>/dev/null)" ]
}

# ── Agent instructions in a project that already has some. ADR 0043. ──
#
# AGENTS.md is the standard itself, vendored and checksummed. An existing one is
# Causeway's when the previous lock lists it — then this sync replaces it, and
# says so if it had been edited, because check-drift.sh tells anyone who edited
# it by accident to re-run sync to restore it. It is also Causeway's when it is
# byte-identical to the one being installed. Anything else is the project's own
# file, written before Causeway arrived, and this sync refuses rather than
# replace it: the standard has to live at AGENTS.md, and only the project can
# decide where its own instructions move to.
PREV_LOCK="$TARGET/.causeway-lock"
if [ -f "$TARGET/AGENTS.md" ] && [ ! -L "$TARGET/AGENTS.md" ] \
   && ! cmp -s "$TARGET/AGENTS.md" "$STANDARD_DIR/AGENTS.md"; then
  locked=""
  if [ -f "$PREV_LOCK" ] && [ ! -L "$PREV_LOCK" ]; then
    locked="$(sed -n 's/^\([0-9a-f]\{64\}\)  AGENTS\.md$/\1/p' "$PREV_LOCK" | head -1)"
  fi
  if [ -z "$locked" ]; then
    CONFLICTS+=("AGENTS.md holds instructions Causeway did not write. Causeway vendors
  the standard at AGENTS.md and will not replace a project's own file. Move
  yours aside, re-run, then import both from CLAUDE.md:
      mv AGENTS.md AGENTS.project.md")
  elif [ "$(sha_of "$TARGET/AGENTS.md")" != "$locked" ]; then
    NOTES+=("  WARNING: AGENTS.md had been edited since the last sync. It is the vendored")
    NOTES+=("           standard, so the edit was drift; it has been restored. If the edit")
    NOTES+=("           was meant, recover it from version control and take it upstream.")
  fi
fi

for f in "${VENDORED[@]}"; do
  plan_always "$STANDARD_DIR/$f" "$f"
done

# CLAUDE.md.causeway is a reference copy no tool reads, under a name only
# Causeway uses. Replaced every time.
plan_always "$STANDARD_DIR/adapters/CLAUDE.md" "CLAUDE.md.causeway"

# The other three adapters are files a project may already have written for
# itself, so Causeway owns a marked section of each rather than the file:
#
#   <!-- causeway:begin ... -->
#   (the shim)
#   <!-- causeway:end -->
#
# Absent: the file is written holding just the section. Present with the
# markers: only the section is replaced, so a re-sync never duplicates it and
# everything outside it is the project's. Present without them: if it is the
# shim exactly as an earlier sync wrote it, it becomes the section; otherwise it
# is the project's content, kept byte for byte, with the section appended. A
# symlink to AGENTS.md is left alone. Damaged markers are a conflict — guessing
# where a section ends is how a sync deletes somebody's instructions.
MARK_BEGIN='<!-- causeway:begin — managed by Causeway tools/sync.sh. Edits between these markers are replaced on every sync; keep your own instructions outside them. -->'
MARK_END='<!-- causeway:end -->'

# Split an adapter into the frontmatter a tool needs at the top (.mdc only) and
# the body that goes inside the markers.
adapter_head() { if [ "${1##*.}" = "mdc" ]; then awk 'NR==1&&/^---$/{f=1} f{print} f&&NR>1&&/^---$/{exit}' "$1"; fi; }
adapter_body() {
  if [ "${1##*.}" = "mdc" ]; then
    awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{f=0;b=1;next} !f&&b{print}' "$1" | sed '/./,$!d'
  else
    cat "$1"
  fi
}

plan_managed() {
  local src="$1" rel="$2" dst="$TARGET/$2" out
  out="$GEN/$(printf '%s' "$rel" | tr '/' '_')"
  local section="$GEN/section"
  { echo "$MARK_BEGIN"; adapter_body "$src"; echo "$MARK_END"; } > "$section"

  if links_to_agents "$rel"; then
    NOTES+=("  $rel links to AGENTS.md, left alone")
    return
  fi
  if [ -L "$dst" ] || { [ -e "$dst" ] && [ ! -f "$dst" ]; }; then
    # Not ours to interpret; the conflict check below names it.
    plan_always "$src" "$rel"; return
  fi

  if [ ! -e "$dst" ] || cmp -s "$dst" "$src"; then
    # Absent, or the bare shim an earlier sync wrote: the file becomes the section.
    { adapter_head "$src"; [ "${src##*.}" = "mdc" ] && echo; cat "$section"; } > "$out"
    [ -e "$dst" ] && NOTES+=("  $rel was an earlier Causeway shim; now a marked section")
    plan_always "$out" "$rel"
    return
  fi

  local begins ends
  begins="$(grep -c '^<!-- causeway:begin' "$dst" || true)"
  ends="$(grep -cx '<!-- causeway:end -->' "$dst" || true)"
  if [ "$begins" -eq 0 ] && [ "$ends" -eq 0 ]; then
    # The project's own file. Kept exactly; the section goes after it.
    { cat "$dst"; [ -z "$(tail -c1 "$dst")" ] || echo; echo; cat "$section"; } > "$out"
    if grep -q 'GENERATED by tools/render-adapters.sh' "$dst"; then
      NOTES+=("  $rel: kept, and the Causeway section appended. It also holds an older")
      NOTES+=("        Causeway shim — if you never edited that text, delete it above the section.")
    else
      NOTES+=("  $rel: your instructions kept, the Causeway section appended after them")
    fi
  elif [ "$begins" -eq 1 ] && [ "$ends" -eq 1 ] \
       && [ "$(grep -n '^<!-- causeway:begin' "$dst" | cut -d: -f1)" -lt \
            "$(grep -nx '<!-- causeway:end -->' "$dst" | cut -d: -f1)" ]; then
    awk -v sec="$section" '
      /^<!-- causeway:begin/ { while ((getline l < sec) > 0) print l; skip=1; next }
      skip && $0 == "<!-- causeway:end -->" { skip=0; next }
      !skip { print }' "$dst" > "$out"
  else
    CONFLICTS+=("$rel has damaged Causeway markers ($begins begin, $ends end). Repair or
  remove them so exactly one marked section remains, then re-run.")
    return
  fi
  plan_always "$out" "$rel"
}

plan_managed "$STANDARD_DIR/adapters/GEMINI.md" "GEMINI.md"
plan_managed "$STANDARD_DIR/adapters/.cursor/rules/causeway.mdc" ".cursor/rules/causeway.mdc"
plan_managed "$STANDARD_DIR/adapters/copilot-instructions.md" ".github/copilot-instructions.md"

# The license travels with the copy (ADR 0037). Apache-2.0 asks anyone who
# redistributes the standard to pass on LICENSE and NOTICE, and vendoring is the
# first step of every redistribution, so the copy carries both from the start.
# Under bundle/, never the project root: the root LICENSE is the project's own
# and must not be clobbered. Overwritten on every sync, like the adapters.
plan_always "$STANDARD_DIR/LICENSE" "bundle/LICENSE"
plan_always "$STANDARD_DIR/NOTICE" "bundle/NOTICE"

# CLAUDE.md is the one file a project legitimately extends, so never clobber it.
plan_seed "$STANDARD_DIR/templates/project-CLAUDE.md" "CLAUDE.md" \
  "  created CLAUDE.md from template — fill in the project specifics" \
  "  CLAUDE.md exists, left alone (see CLAUDE.md.causeway for the current shim)"

# A CLAUDE.md the project wrote is never edited, and so it may never have been
# pointed at the standard. Claude Code reads an import line; one that is missing
# means the standard is on disk and not in the agent's instructions. Said here,
# because a sync that succeeds quietly reads as an adoption that worked. This
# checks for the reference only — it cannot show that any agent read or obeyed it.
if [ -f "$TARGET/CLAUDE.md" ] && ! links_to_agents "CLAUDE.md" \
   && ! grep -qE '^[[:space:]]*@(\./)?AGENTS\.md[[:space:]]*$' "$TARGET/CLAUDE.md"; then
  NOTES+=("  WARNING: CLAUDE.md does not import the standard. Add this line to it:")
  NOTES+=("               @AGENTS.md")
  NOTES+=("           CLAUDE.md.causeway shows the current shim in full.")
fi

# The open-items index, seeded on the same terms as CLAUDE.md and for the same
# reason: sync.sh writes the shape once and the project owns the content. An
# index this script overwrote on every re-sync would lose every item the project
# had recorded, which is a more thorough version of the failure it exists to
# prevent. Build DNA §8 states the rule; ADR 0025 decided it.
plan_seed "$STANDARD_DIR/templates/open-items.json" "decisions/open-items.json" \
  "  created decisions/open-items.json from template — name your registers, drop the example item"

# The register's own README, seeded on the same terms as the field-notes README
# and for the same reason: a directory that explains itself. Build DNA §8 says
# what the numbers mean and why an accepted record is never edited, deep in a
# document the Contributor floor does not ask anyone to read end to end; this
# puts the short version, and an index only the project can write, where a
# contributor copying in a template will actually see it. Never overwritten —
# the index by family and the unused-numbers list are the project's content by
# construction. ADR 0041.
plan_seed "$STANDARD_DIR/templates/decisions-README.md" "decisions/README.md" \
  "  created decisions/README.md from template — add each ADR to its index as you write it"

# The practitioner front door, seeded on the same terms as CLAUDE.md: written
# once, then owned by the project. It carries [BRACKET] placeholders a project
# has to fill in — who reviews, who to ask, where the note template landed — so
# re-copying it over an edited one would reset exactly the names that make it
# usable. ADR 0028.
plan_seed "$STANDARD_DIR/templates/practitioner-START-HERE.md" "START-HERE.md" \
  "  created START-HERE.md from template — fill in the bracketed names before handing it to anyone"

# The contributor front door, seeded on the same terms as START-HERE.md and for
# the same reason: it carries [BRACKET] placeholders — commands, names, the
# project's own rules — that only the project can fill. It lands at
# CONTRIBUTING.md rather than beside START-HERE.md because GitHub links that
# file from every new pull request and issue page, so a new developer finds it
# without anybody having to tell them it exists. ADR 0035.
plan_seed "$STANDARD_DIR/templates/contributor-START-HERE.md" "CONTRIBUTING.md" \
  "  created CONTRIBUTING.md from template — fill in the bracketed commands and names before handing it to anyone"

# The browser-only capture path. A practitioner with no local checkout and no
# intention of getting one still has a way in, which is the difference between
# an on-ramp and an on-ramp for people who already have the tools.
plan_seed "$STANDARD_DIR/templates/field-note-issue-form.yml" ".github/ISSUE_TEMPLATE/field-note.yml" \
  "  created .github/ISSUE_TEMPLATE/field-note.yml — set the labels and assignee"

# The corpus itself. Seeded with its own README rather than created empty, for
# two reasons: git tracks files and not directories, so an empty one does not
# survive a clone and the register would silently not exist; and a directory that
# explains itself tells the first practitioner they were expected.
plan_seed "$STANDARD_DIR/templates/field-notes-README.md" "domain/field-notes/README.md" \
  "  created domain/field-notes/ — the register, with its README" ""

# The reviewer map. Seeded once, then owned by the project, and deliberately
# shipped with @ORG/TEAM placeholders rather than a guess: a CODEOWNERS naming
# teams that do not exist nominates nobody and fails silently, which is the one
# failure mode a guardrail must not have.
#
# It is half a guardrail on its own. CODEOWNERS nominates reviewers; branch
# protection is what requires them, and that is a repository setting no script
# can write. The file says so at the top rather than leaving a project to find
# out at the first merge — the same shape ADR 0016 records for the gate.
plan_seed "$STANDARD_DIR/templates/CODEOWNERS" ".github/CODEOWNERS" \
  "  created .github/CODEOWNERS — replace @ORG/TEAM, then require code-owner review on the default branch"

# The pull request checklist. The Contributor floor restated as boxes a
# reviewer can see ticked or not, plus a section the project replaces with its
# own rules. Seeded once and owned thereafter, like CODEOWNERS. ADR 0035.
plan_seed "$STANDARD_DIR/templates/pull_request_template.md" ".github/pull_request_template.md" \
  "  created .github/pull_request_template.md — replace the bracketed project section with this project's rules"

# The signature material, when this copy has it.
#
# Deliberately not in VENDORED and deliberately not checksummed in the lock. The
# statement names the bundle digest, so the digest cannot cover the statement
# without covering itself; and a checksum in the lock would prove only that the
# file had not changed since sync, which is the weaker half of what the
# signature already proves against a key.
#
# Copied because verify-release.sh is vendored and, until v1.14.0, had nothing
# to verify. The documented way to give it something was `gh release download`
# — a network call, a GitHub credential and a third tool, in the CI of a project
# whose reason for vendoring the standard was not to need any of the three. A
# project that receives these two files can answer "are these bytes the
# publisher's" forever, on an isolated network, with no clone.
if [ -f "$STANDARD_DIR/bundle/release.statement" ] \
   && [ -f "$STANDARD_DIR/bundle/release.statement.sig" ]; then
  plan_always "$STANDARD_DIR/bundle/release.statement"     "bundle/release.statement"
  plan_always "$STANDARD_DIR/bundle/release.statement.sig" "bundle/release.statement.sig"
  NOTES+=("  copied bundle/release.statement and .sig — tools/verify-release.sh can")
  NOTES+=("        now run in this project's CI with no network")
fi

# The baseline index: every line already there, except those this run replaces
# by seeding the same file again, then the new ones. Untouched when nothing was
# seeded, so a re-sync of an established project leaves it byte-identical.
if [ "${#SEEDED[@]}" -gt 0 ]; then
  {
    if [ -f "$TARGET/.causeway/starters.txt" ]; then
      while IFS= read -r line; do
        dst="$(echo "$line" | awk '{print $2}')"
        keep=1
        for s in "${SEEDED[@]}"; do [ "$(echo "$s" | awk '{print $2}')" = "$dst" ] && keep=0; done
        [ "$keep" -eq 1 ] && echo "$line"
      done < <(grep -v '^#' "$TARGET/.causeway/starters.txt")
    fi
    printf '%s\n' "${SEEDED[@]}"
  } | { echo "# sha256-of-baseline  project-file  template  seeded-from — tools/upgrade-starters.sh reads this. ADR 0046."; LC_ALL=C sort -k2; } \
    > "$GEN/starters.txt"
  plan_always "$GEN/starters.txt" ".causeway/starters.txt"
fi

# The lock is planned like any other file, and applied last.
LOCK_DST=".causeway-lock"

# Target conflicts. Every destination must be a regular file or absent, every
# parent must be a directory or absent, and nothing on the way may be a symlink:
# writing through one would put the standard somewhere outside the project, and
# replacing one would silently change what the project had pointed it at.
# Reported together, so one run names every conflict instead of the first.
check_dst() {
  local rel="$1" path="$TARGET/$1" parent
  if [ -L "$path" ]; then
    CONFLICTS+=("$rel is a symlink")
  elif [ -e "$path" ] && [ ! -f "$path" ]; then
    CONFLICTS+=("$rel exists and is not a regular file")
  elif [ -f "$path" ] && [ ! -w "$path" ]; then
    CONFLICTS+=("$rel is not writable")
  fi
  parent="$(dirname "$rel")"
  while [ "$parent" != "." ]; do
    if [ -L "$TARGET/$parent" ]; then
      CONFLICTS+=("$parent/ is a symlink (needed for $rel)"); break
    elif [ -e "$TARGET/$parent" ] && [ ! -d "$TARGET/$parent" ]; then
      CONFLICTS+=("$parent exists and is not a directory (needed for $rel)"); break
    elif [ -d "$TARGET/$parent" ]; then
      [ -w "$TARGET/$parent" ] || CONFLICTS+=("$parent/ is not writable (needed for $rel)")
      break
    fi
    parent="$(dirname "$parent")"
  done
}
[ -w "$TARGET" ] || CONFLICTS+=("$TARGET is not writable")
for d in "${PLAN_DST[@]}" "$LOCK_DST"; do check_dst "$d"; done

if [ "${#CONFLICTS[@]}" -gt 0 ]; then
  echo "" >&2
  echo "  REFUSING: the target has conflicts this sync will not write through." >&2
  echo "            Nothing in $TARGET was changed." >&2
  # De-duplicated: a read-only parent is named once, not once per file under it.
  printf '%s\n' "${CONFLICTS[@]}" | awk '!seen[$0]++' | sed 's/^/              /' >&2
  exit 9
fi

# ── 3. Stage ─────────────────────────────────────────────────────────────────
#
# Inside the target, so the apply below is a rename on one filesystem rather
# than a copy that can stop halfway through a file. Removed on every exit.
STAGE="$(mktemp -d "$TARGET/.causeway-sync.XXXXXX")"
APPLIED_DST=()     # destinations already moved into place, in order
CREATED_DIRS=()    # directories this run created, outermost first
ROLLBACK_OK=1
rollback() {
  local i rel
  for (( i=${#APPLIED_DST[@]}-1; i>=0; i-- )); do
    rel="${APPLIED_DST[$i]}"
    if [ -f "$STAGE/backup/$rel" ]; then
      mv -f "$STAGE/backup/$rel" "$TARGET/$rel" \
        || { echo "  could not restore $rel" >&2; ROLLBACK_OK=0; }
    else
      rm -f "$TARGET/$rel" || { echo "  could not remove $rel" >&2; ROLLBACK_OK=0; }
    fi
  done
  for (( i=${#CREATED_DIRS[@]}-1; i>=0; i-- )); do
    rmdir "$TARGET/${CREATED_DIRS[$i]}" 2>/dev/null || true
  done
}
# A rollback that could not finish keeps the stage: it holds the only copy of
# whatever it failed to put back.
cleanup() {
  rm -rf "$GEN"
  if [ "$ROLLBACK_OK" -eq 1 ]; then
    rm -rf "$STAGE"
  else
    echo "  Rollback was incomplete. Originals are kept in $STAGE/backup" >&2
  fi
}
trap cleanup EXIT

for i in "${!PLAN_DST[@]}"; do
  mkdir -p "$STAGE/new/$(dirname "${PLAN_DST[$i]}")"
  cp "${PLAN_SRC[$i]}" "$STAGE/new/${PLAN_DST[$i]}"
done

# Write the lock, into the stage. Its checksums are taken from the source; the
# check after it proves the staged copies are those same bytes.
{
  echo "version=$VERSION"
  echo "released=$RELEASED"
  echo "digest=$BUNDLE_DIGEST"
  [ -n "$COMMIT" ] && echo "commit=$COMMIT"
  [ -n "$TAG" ] && echo "tag=$TAG"
  # How the release above was established, or `none`. Written unconditionally,
  # including when it is `none`: a field that appears only on success makes its
  # absence something a reader has to notice rather than something they can
  # read. `tag=` learned that lesson in ADR 0015 and this is the same lesson
  # one field over — a git-tag pin and a signature-verified pin are not the same
  # claim, and a lock that rendered them identically would be hiding the one
  # difference an auditor is entitled to.
  echo "release_proof=$RELEASE_PROOF"
  echo "synced=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [ -n "$OVERLAY" ] && echo "overlay=$OVERLAY"
  for f in "${VENDORED[@]}"; do
    echo "$(sha256sum "$STANDARD_DIR/$f" | cut -d' ' -f1)  $f"
  done
} > "$STAGE/new/$LOCK_DST"

# Validate the stage before touching the target: every planned file is there,
# byte-identical to its source.
for i in "${!PLAN_DST[@]}"; do
  if ! cmp -s "${PLAN_SRC[$i]}" "$STAGE/new/${PLAN_DST[$i]}"; then
    echo "  ERROR: staged ${PLAN_DST[$i]} does not match its source. Nothing in" >&2
    echo "         $TARGET was changed." >&2
    exit 1
  fi
done

# ── 4. Apply ─────────────────────────────────────────────────────────────────
#
# CAUSEWAY_SYNC_FAIL_AFTER=N makes the apply fail after N files have moved. It
# exists for the standard's own CI, which has no other honest way to prove the
# rollback below runs — a failure the preflight could foresee would have been
# refused there instead. Unset, it does nothing.
FAIL_AFTER="${CAUSEWAY_SYNC_FAIL_AFTER:-}"

apply_one() {
  local rel="$1" dir
  dir="$(dirname "$rel")"
  if [ "$dir" != "." ] && [ ! -d "$TARGET/$dir" ]; then
    local parts=() p="$dir"
    while [ "$p" != "." ] && [ ! -d "$TARGET/$p" ]; do parts=("$p" "${parts[@]}"); p="$(dirname "$p")"; done
    for p in "${parts[@]}"; do
      mkdir "$TARGET/$p" || return 1
      CREATED_DIRS+=("$p")
    done
  fi
  if [ -f "$TARGET/$rel" ]; then
    mkdir -p "$STAGE/backup/$dir" || return 1
    cp -p "$TARGET/$rel" "$STAGE/backup/$rel" || return 1
  fi
  if [ -n "$FAIL_AFTER" ] && [ "${#APPLIED_DST[@]}" -ge "$FAIL_AFTER" ]; then
    echo "  CAUSEWAY_SYNC_FAIL_AFTER=$FAIL_AFTER: failing on purpose at $rel" >&2
    return 1
  fi
  mv -f "$STAGE/new/$rel" "$TARGET/$rel" || return 1
  APPLIED_DST+=("$rel")
}

for d in "${PLAN_DST[@]}" "$LOCK_DST"; do
  if ! apply_one "$d"; then
    echo "" >&2
    echo "  FAILED applying $d. Rolling back: restoring overwritten files and" >&2
    echo "  removing created ones, so $TARGET is as it was before this run." >&2
    rollback
    exit 10
  fi
done

for n in "${NOTES[@]}"; do [ -n "$n" ] && echo "$n"; done
echo "wrote .causeway-lock ($BUNDLE_DIGEST)"
echo "Add tools/check-drift.sh to CI. Unpinned standards go missing."
echo "Run tools/doctor.sh to see what adopting it still needs."
