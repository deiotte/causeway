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
# clean tree, HEAD exactly at a tag. Use it in anything that builds for a real
# environment. Without it a sync from an arbitrary branch commit succeeds and
# writes a lock indistinguishable from a release pin — which is how a vendored
# copy came to be pinned to an unmerged pull request branch with nothing
# complaining. See ADR 0015.
#
# --overlay additionally vendors a platform overlay (overlays/<name>.md) and
# records the choice in the lock. Overlays are opt-in: a Go service has no
# business carrying the ServiceNow disposition table. See overlays/README.md.
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

if [ -n "$OVERLAY" ] && [ ! -f "$STANDARD_DIR/overlays/$OVERLAY.md" ]; then
  echo "no such overlay: $OVERLAY" >&2
  echo "available:" >&2
  for o in "$STANDARD_DIR"/overlays/*.md; do
    b="$(basename "$o" .md)"; [ "$b" = "README" ] || echo "  $b" >&2
  done
  exit 1
fi

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

for f in "${VENDORED[@]}"; do
  mkdir -p "$TARGET/$(dirname "$f")"
  cp "$STANDARD_DIR/$f" "$TARGET/$f"
done

# Tool adapters land where each tool expects them.
cp "$STANDARD_DIR/adapters/CLAUDE.md" "$TARGET/CLAUDE.md.causeway"
cp "$STANDARD_DIR/adapters/GEMINI.md" "$TARGET/GEMINI.md"
mkdir -p "$TARGET/.cursor/rules" "$TARGET/.github"
cp "$STANDARD_DIR/adapters/.cursor/rules/causeway.mdc" "$TARGET/.cursor/rules/causeway.mdc"
cp "$STANDARD_DIR/adapters/copilot-instructions.md" "$TARGET/.github/copilot-instructions.md"

# The license travels with the copy (ADR 0037). Apache-2.0 asks anyone who
# redistributes the standard to pass on LICENSE and NOTICE, and vendoring is the
# first step of every redistribution, so the copy carries both from the start.
# Under bundle/, never the project root: the root LICENSE is the project's own
# and must not be clobbered. Overwritten on every sync, like the adapters.
mkdir -p "$TARGET/bundle"
cp "$STANDARD_DIR/LICENSE" "$TARGET/bundle/LICENSE"
cp "$STANDARD_DIR/NOTICE" "$TARGET/bundle/NOTICE"

# CLAUDE.md is the one file a project legitimately extends, so never clobber it.
if [ ! -f "$TARGET/CLAUDE.md" ]; then
  cp "$STANDARD_DIR/templates/project-CLAUDE.md" "$TARGET/CLAUDE.md"
  echo "  created CLAUDE.md from template — fill in the project specifics"
else
  echo "  CLAUDE.md exists, left alone (see CLAUDE.md.causeway for the current shim)"
fi

# The open-items index, seeded on the same terms as CLAUDE.md and for the same
# reason: sync.sh writes the shape once and the project owns the content. An
# index this script overwrote on every re-sync would lose every item the project
# had recorded, which is a more thorough version of the failure it exists to
# prevent. Build DNA §8 states the rule; ADR 0025 decided it.
mkdir -p "$TARGET/decisions"
if [ ! -f "$TARGET/decisions/open-items.json" ]; then
  cp "$STANDARD_DIR/templates/open-items.json" "$TARGET/decisions/open-items.json"
  echo "  created decisions/open-items.json from template — name your registers, drop the example item"
else
  echo "  decisions/open-items.json exists, left alone"
fi

# The register's own README, seeded on the same terms as the field-notes README
# and for the same reason: a directory that explains itself. Build DNA §8 says
# what the numbers mean and why an accepted record is never edited, deep in a
# document the Contributor floor does not ask anyone to read end to end; this
# puts the short version, and an index only the project can write, where a
# contributor copying in a template will actually see it. Never overwritten —
# the index by family and the unused-numbers list are the project's content by
# construction. ADR 0041.
if [ ! -f "$TARGET/decisions/README.md" ]; then
  cp "$STANDARD_DIR/templates/decisions-README.md" "$TARGET/decisions/README.md"
  echo "  created decisions/README.md from template — add each ADR to its index as you write it"
else
  echo "  decisions/README.md exists, left alone"
fi

# The practitioner front door, seeded on the same terms as CLAUDE.md: written
# once, then owned by the project. It carries [BRACKET] placeholders a project
# has to fill in — who reviews, who to ask, where the note template landed — so
# re-copying it over an edited one would reset exactly the names that make it
# usable. ADR 0028.
if [ ! -f "$TARGET/START-HERE.md" ]; then
  cp "$STANDARD_DIR/templates/practitioner-START-HERE.md" "$TARGET/START-HERE.md"
  echo "  created START-HERE.md from template — fill in the bracketed names before handing it to anyone"
else
  echo "  START-HERE.md exists, left alone"
fi

# The contributor front door, seeded on the same terms as START-HERE.md and for
# the same reason: it carries [BRACKET] placeholders — commands, names, the
# project's own rules — that only the project can fill. It lands at
# CONTRIBUTING.md rather than beside START-HERE.md because GitHub links that
# file from every new pull request and issue page, so a new developer finds it
# without anybody having to tell them it exists. ADR 0035.
if [ ! -f "$TARGET/CONTRIBUTING.md" ]; then
  cp "$STANDARD_DIR/templates/contributor-START-HERE.md" "$TARGET/CONTRIBUTING.md"
  echo "  created CONTRIBUTING.md from template — fill in the bracketed commands and names before handing it to anyone"
else
  echo "  CONTRIBUTING.md exists, left alone"
fi

# The browser-only capture path. A practitioner with no local checkout and no
# intention of getting one still has a way in, which is the difference between
# an on-ramp and an on-ramp for people who already have the tools.
mkdir -p "$TARGET/.github/ISSUE_TEMPLATE"
if [ ! -f "$TARGET/.github/ISSUE_TEMPLATE/field-note.yml" ]; then
  cp "$STANDARD_DIR/templates/field-note-issue-form.yml" \
     "$TARGET/.github/ISSUE_TEMPLATE/field-note.yml"
  echo "  created .github/ISSUE_TEMPLATE/field-note.yml — set the labels and assignee"
else
  echo "  .github/ISSUE_TEMPLATE/field-note.yml exists, left alone"
fi

# The corpus itself. Seeded with its own README rather than created empty, for
# two reasons: git tracks files and not directories, so an empty one does not
# survive a clone and the register would silently not exist; and a directory that
# explains itself tells the first practitioner they were expected.
mkdir -p "$TARGET/domain/field-notes"
if [ ! -f "$TARGET/domain/field-notes/README.md" ]; then
  cp "$STANDARD_DIR/templates/field-notes-README.md" \
     "$TARGET/domain/field-notes/README.md"
  echo "  created domain/field-notes/ — the register, with its README"
fi

# The reviewer map. Seeded once, then owned by the project, and deliberately
# shipped with @ORG/TEAM placeholders rather than a guess: a CODEOWNERS naming
# teams that do not exist nominates nobody and fails silently, which is the one
# failure mode a guardrail must not have.
#
# It is half a guardrail on its own. CODEOWNERS nominates reviewers; branch
# protection is what requires them, and that is a repository setting no script
# can write. The file says so at the top rather than leaving a project to find
# out at the first merge — the same shape ADR 0016 records for the gate.
mkdir -p "$TARGET/.github"
if [ ! -f "$TARGET/.github/CODEOWNERS" ]; then
  cp "$STANDARD_DIR/templates/CODEOWNERS" "$TARGET/.github/CODEOWNERS"
  echo "  created .github/CODEOWNERS — replace @ORG/TEAM, then require code-owner review on the default branch"
else
  echo "  .github/CODEOWNERS exists, left alone"
fi

# The pull request checklist. The Contributor floor restated as boxes a
# reviewer can see ticked or not, plus a section the project replaces with its
# own rules. Seeded once and owned thereafter, like CODEOWNERS. ADR 0035.
if [ ! -f "$TARGET/.github/pull_request_template.md" ]; then
  cp "$STANDARD_DIR/templates/pull_request_template.md" \
     "$TARGET/.github/pull_request_template.md"
  echo "  created .github/pull_request_template.md — replace the bracketed project section with this project's rules"
else
  echo "  .github/pull_request_template.md exists, left alone"
fi

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
  mkdir -p "$TARGET/bundle"
  cp "$STANDARD_DIR/bundle/release.statement"     "$TARGET/bundle/release.statement"
  cp "$STANDARD_DIR/bundle/release.statement.sig" "$TARGET/bundle/release.statement.sig"
  echo "  copied bundle/release.statement and .sig — tools/verify-release.sh can"
  echo "        now run in this project's CI with no network"
fi

# Write the lock.
#
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
          echo "  WARNING: bundle/release.statement verifies but signs v$S_VERSION,"
          echo "           and this copy says v$VERSION. Not treating it as a release."
        fi
        ;;
      5)
        # Material absent or ssh-keygen missing. Said plainly, because "cannot
        # check" and "checked and it failed" are different positions and only
        # one of them means do not ship this.
        echo "  note: cannot check the release signature here — ssh-keygen is"
        echo "        missing, or the statement and .sig are not in this copy."
        ;;
      *)
        echo "  WARNING: bundle/release.statement is present and does NOT verify."
        echo "           Run tools/verify-release.sh in the standard directory to"
        echo "           see why. Not treating this copy as a release."
        ;;
    esac
  fi
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
else
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
  if [ "$DIRTY" -eq 1 ]; then
    echo "            The working tree is dirty. Commit or stash, then check out a tag." >&2
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
} > "$TARGET/.causeway-lock"

echo "wrote .causeway-lock ($BUNDLE_DIGEST)"
echo "Add tools/check-drift.sh to CI. Unpinned standards go missing."
