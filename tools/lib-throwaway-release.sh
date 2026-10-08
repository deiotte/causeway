# lib-throwaway-release.sh — sourced, not run. Builds a signed release of this
# checkout under a key generated for the purpose and discarded with the caller's
# work directory, so tests can exercise the signed path end to end without the
# real release key. ADR 0044.
#
#   . tools/lib-throwaway-release.sh
#   make_throwaway_release <standard-dir> <out-dir>
#
# Leaves:
#   <out-dir>/tree/causeway-<version>/   the signed tree: an extracted archive
#                                        whose allowed-signers is the throwaway
#                                        key, manifest rebuilt to cover it, and
#                                        a statement signed with it
#   <out-dir>/dist/                      that tree archived the way a release
#                                        is: .tar.gz, .zip and both .sha256
#   <out-dir>/key, key.pub               the throwaway key
#
# The statement names tag v<version> and an all-zero commit: there is no real
# tag, and a test that needed one would be testing git rather than the release.
# Nothing here prints key material.

make_throwaway_release() {
  local std="$1" out="$2" version digest tree
  version="$(cat "$std/VERSION")"
  mkdir -p "$out/raw" "$out/tree" "$out/dist"

  "$std/tools/build-archive.sh" --out "$out/raw" >/dev/null 2>&1
  tar -xzf "$out/raw/causeway-$version.tar.gz" -C "$out/tree"
  tree="$out/tree/causeway-$version"

  ssh-keygen -q -t ed25519 -N '' -C throwaway -f "$out/key" </dev/null
  printf 'release@throwaway %s\n' "$(cut -d' ' -f1,2 "$out/key.pub")" \
    > "$tree/bundle/allowed-signers"

  # The archive carries neither builder; borrow them, then take them back out
  # so the tree is exactly what a consumer would extract.
  cp "$std/tools/build-bundle.sh" "$std/tools/build-archive.sh" "$tree/tools/"
  ( cd "$tree" && bash tools/build-bundle.sh >/dev/null )

  digest="$(sed -n 's/.*"digest"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$tree/bundle/manifest.json" | head -1)"
  printf 'causeway-release-v1\nversion=%s\nreleased=%s\ndigest=%s\ncommit=%s\ntag=v%s\n' \
    "$version" "$(cat "$tree/RELEASED")" "$digest" \
    "0000000000000000000000000000000000000000" "$version" \
    > "$tree/bundle/release.statement"
  ssh-keygen -q -Y sign -f "$out/key" -n causeway-release \
    "$tree/bundle/release.statement" >/dev/null 2>&1

  ( cd "$tree" && bash tools/build-archive.sh --out "$out/dist" >/dev/null )
  rm "$tree/tools/build-bundle.sh" "$tree/tools/build-archive.sh"
  rm -rf "$out/raw"
}
