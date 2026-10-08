#!/usr/bin/env bash
# publish-release.sh — the only step that changes a GitHub release. ADR 0044.
#
#   ./tools/publish-release.sh --tag <tag> --dist <dir> [--root <dir>]
#   ./tools/publish-release.sh --tag <tag> --withdraw
#
# Publishing re-checks everything it can check locally before it contacts
# GitHub at all, then makes the asset set appear at once:
#
#   1. Preconditions, offline. The tag is v$VERSION. The release statement
#      verifies against bundle/allowed-signers, signs this tag and version, and
#      is byte-identical to the one inside the archive. Both archives match their
#      checksums. And <dir>/.accepted — written by test-release-archive.sh only
#      when every consumer case passed — names this exact tarball. Any failure
#      exits 3 and nothing is sent.
#   2. The release is a draft while its assets change: created as one if it does
#      not exist, turned back into one if a maintainer published it from the web
#      interface before this ran.
#   3. All six assets are uploaded in one call.
#   4. Only then is the draft published.
#
# A gh failure after step 2 exits 4 and leaves the release a draft: hidden, and
# never published with part of its assets.
#
# --withdraw is the failure policy. The workflow runs it when any earlier step
# failed: a release that is published becomes a draft, so nobody downloads a
# release whose evidence did not hold. It uploads nothing.
#
# Exit 0 published or withdrawn · 1 usage · 3 a precondition failed, GitHub
# not contacted · 4 GitHub refused partway, release left a draft.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG=""
DIST=""
WITHDRAW=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tag)      TAG="${2:?--tag needs a value}"; shift 2 ;;
    --dist)     DIST="${2:?--dist needs a directory}"; shift 2 ;;
    --root)     ROOT="$(cd "${2:?--root needs a directory}" && pwd)"; shift 2 ;;
    --withdraw) WITHDRAW=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
[ -n "$TAG" ] || { echo "usage: publish-release.sh --tag <tag> (--dist <dir> | --withdraw)" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh not found" >&2; exit 1; }

# The release's state: absent, draft, or published.
release_state() {
  local d
  if ! d="$(gh release view "$TAG" --json isDraft -q .isDraft 2>/dev/null)"; then
    echo absent
  elif [ "$d" = "true" ]; then
    echo draft
  else
    echo published
  fi
}

if [ "$WITHDRAW" -eq 1 ]; then
  case "$(release_state)" in
    absent)    echo "withdraw: no release $TAG exists; nothing was published" ;;
    draft)     echo "withdraw: release $TAG is already a draft; nothing is visible" ;;
    published)
      gh release edit "$TAG" --draft=true >/dev/null
      echo "withdraw: release $TAG was published and is now a DRAFT."
      echo "          An earlier step failed, so its assets are not the verified set."
      ;;
  esac
  exit 0
fi

[ -n "$DIST" ] || { echo "publish needs --dist <dir>" >&2; exit 1; }
DIST="$(cd "$DIST" && pwd)"
VERSION="$(cat "$ROOT/VERSION")"
BASE="causeway-$VERSION"
STATEMENT="$ROOT/bundle/release.statement"
ASSETS=(
  "$DIST/$BASE.tar.gz" "$DIST/$BASE.tar.gz.sha256"
  "$DIST/$BASE.zip"    "$DIST/$BASE.zip.sha256"
  "$STATEMENT"         "$STATEMENT.sig"
)

# ── 1. Preconditions. Nothing below this block runs unless all of them hold. ──
PROBLEMS=()
[ "$TAG" = "v$VERSION" ] || PROBLEMS+=("tag $TAG is not v$VERSION, the version this tree carries")
for a in "${ASSETS[@]}"; do
  [ -f "$a" ] || PROBLEMS+=("missing ${a#"$ROOT"/}")
done
if [ "${#PROBLEMS[@]}" -eq 0 ]; then
  ( cd "$ROOT" && bash tools/verify-release.sh --lock /dev/null >/dev/null 2>&1 ) \
    || PROBLEMS+=("bundle/release.statement does not verify against bundle/allowed-signers")
  [ "$(sed -n 's/^tag=//p' "$STATEMENT" | head -1)" = "$TAG" ] \
    || PROBLEMS+=("the statement does not sign $TAG")
  [ "$(sed -n 's/^version=//p' "$STATEMENT" | head -1)" = "$VERSION" ] \
    || PROBLEMS+=("the statement does not sign version $VERSION")
  ( cd "$DIST" && sha256sum -c "$BASE.tar.gz.sha256" "$BASE.zip.sha256" >/dev/null 2>&1 ) \
    || PROBLEMS+=("an archive does not match its checksum")
  if ! tar -xzOf "$DIST/$BASE.tar.gz" "$BASE/bundle/release.statement" 2>/dev/null \
       | cmp -s - "$STATEMENT"; then
    PROBLEMS+=("the archive does not carry this release statement — it was built before signing")
  fi
  if [ ! -f "$DIST/.accepted" ]; then
    PROBLEMS+=("no $DIST/.accepted — tools/test-release-archive.sh has not passed this archive")
  elif [ "$(cat "$DIST/.accepted")" != "$(sha256sum "$DIST/$BASE.tar.gz" | cut -d' ' -f1)" ]; then
    PROBLEMS+=("the tarball changed after tools/test-release-archive.sh accepted it")
  fi
fi
if [ "${#PROBLEMS[@]}" -gt 0 ]; then
  echo "REFUSING to publish $TAG. GitHub was not contacted." >&2
  printf '  %s\n' "${PROBLEMS[@]}" >&2
  exit 3
fi
echo "publish $TAG: every precondition holds"

# ── 2-4. Draft, upload everything, publish. ──
fail_draft() {
  echo "FAILED publishing $TAG at: $1" >&2
  echo "  The release is left a DRAFT. Nothing partial is visible. Re-run the" >&2
  echo "  release workflow for $TAG once the cause is fixed." >&2
  exit 4
}
case "$(release_state)" in
  absent)
    gh release create "$TAG" --draft --verify-tag --title "$TAG" --notes "Causeway $TAG" \
      >/dev/null || fail_draft "creating the draft release" ;;
  published)
    gh release edit "$TAG" --draft=true >/dev/null || fail_draft "hiding the release while assets change" ;;
  draft) ;;
esac
gh release upload "$TAG" "${ASSETS[@]}" --clobber >/dev/null || fail_draft "uploading the assets"
gh release edit "$TAG" --draft=false >/dev/null || fail_draft "publishing the draft"
echo "published $TAG with ${#ASSETS[@]} assets"
