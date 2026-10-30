#!/usr/bin/env bash
# authorize-release.sh — may this tag be signed? ADR 0054, issue #37.
#
#   ./tools/authorize-release.sh --sha <commit> [--main <ref>] [--output <file>]
#   ./tools/authorize-release.sh --tag <tag>    [--main <ref>] [--output <file>]
#
# Run by release.yml from main's checkout, never from the candidate's: the code
# deciding whether a commit is trusted cannot come from that commit.
#
# Admits a release only when all of these hold:
#   - the tag is v<VERSION> of the commit it names, as the commit itself says
#   - the tag still points at that commit (it was not moved after the run began)
#   - the commit is an ancestor of main — so it went through main's pull-request
#     gate, and every script the release runs went through it too
#
# --sha is the commit release-candidate.yml ran on; --tag is a tag named by hand
# (workflow_dispatch). --main defaults to refs/remotes/origin/main.
#
# --output receives `tag=` and `sha=` lines (GitHub's step-output format) as soon
# as the tag is identified and stable, before the main check, so the workflow's
# withdrawal can turn a release shown for a refused tag back into a draft. A tag
# that cannot be identified writes nothing, so a run started by some other
# workflow of the same name cannot withdraw a release it does not name.
#
# Exit 0 authorized; 1 usage; 3 the tag is not a stable release of its commit;
# 4 the commit is not on main.
set -euo pipefail

SHA_IN=""; TAG_IN=""; MAIN="refs/remotes/origin/main"; OUTPUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --sha)    SHA_IN="${2:?--sha needs a commit}"; shift 2 ;;
    --tag)    TAG_IN="${2:?--tag needs a tag}"; shift 2 ;;
    --main)   MAIN="${2:?--main needs a ref}"; shift 2 ;;
    --output) OUTPUT="${2:?--output needs a file}"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
if { [ -n "$SHA_IN" ] && [ -n "$TAG_IN" ]; } || { [ -z "$SHA_IN" ] && [ -z "$TAG_IN" ]; }; then
  echo "usage: authorize-release.sh --sha <commit> | --tag <tag> [--main <ref>] [--output <file>]" >&2
  exit 1
fi

refuse() { echo "refused: $2" >&2; exit "$1"; }
commit_of() { git rev-parse -q --verify "$1^{commit}" 2>/dev/null || true; }

if [ -n "$TAG_IN" ]; then
  TAG="$TAG_IN"
  SHA="$(commit_of "refs/tags/$TAG")"
  [ -n "$SHA" ] || refuse 3 "no tag $TAG"
else
  SHA="$(commit_of "$SHA_IN")"
  [ -n "$SHA" ] || refuse 3 "commit $SHA_IN is not in this repository"
  VERSION="$(git show "$SHA:VERSION" 2>/dev/null)" || refuse 3 "$SHA has no VERSION"
  TAG="v$VERSION"
fi

case "$TAG" in
  v[0-9]*.[0-9]*.[0-9]*) ;;
  *) refuse 3 "$TAG is not a release tag" ;;
esac
case "$TAG" in
  *[!A-Za-z0-9.+-]*) refuse 3 "$TAG contains characters a release tag does not" ;;
esac
[ "$TAG" = "v$(git show "$SHA:VERSION" 2>/dev/null)" ] \
  || refuse 3 "$TAG does not match VERSION at $SHA"
CURRENT="$(commit_of "refs/tags/$TAG")"
[ "$CURRENT" = "$SHA" ] \
  || refuse 3 "tag $TAG points at ${CURRENT:-nothing}, not $SHA"

if [ -n "$OUTPUT" ]; then
  printf 'tag=%s\nsha=%s\n' "$TAG" "$SHA" >> "$OUTPUT"
fi

MAIN_SHA="$(commit_of "$MAIN")"
[ -n "$MAIN_SHA" ] || refuse 4 "$MAIN does not exist here — fetch main with its history"
git merge-base --is-ancestor "$SHA" "$MAIN_SHA" \
  || refuse 4 "$TAG ($SHA) is not on main — only reviewed code is signed"

echo "authorized $TAG ($SHA): a release of its own VERSION, on main"
