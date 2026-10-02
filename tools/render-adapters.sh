#!/usr/bin/env bash
# render-adapters.sh — regenerate the per-tool shims from AGENTS.md.
#
# The shims are pointers, not copies: AGENTS.md is the single source and each
# tool gets the smallest file that makes it read AGENTS.md. Regenerate after any
# change to §1-§10 headings or to the skills directory.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Adapters are hand-maintained pointers in this version and do not embed"
echo "AGENTS.md content, so regeneration is a no-op check."
echo
for f in adapters/CLAUDE.md adapters/GEMINI.md adapters/copilot-instructions.md adapters/.cursor/rules/causeway.mdc; do
  grep -q "GENERATED" "$f" || { echo "MISSING generated marker: $f" >&2; exit 1; }
  grep -q "AGENTS.md" "$f" || { echo "adapter does not point at AGENTS.md: $f" >&2; exit 1; }
  echo "  ok  $f"
done
# Every skill the standard ships is named in every adapter.
#
# The adapters are how an agent in a consuming project learns a skill exists —
# nothing auto-discovers `skills/`, the shim points at it. So a skill missing
# from an adapter ships and is never invoked, which is indistinguishable from
# not shipping it.
#
# That is exactly what happened to `skills/field-note/`. It was added in v1.13.0
# with its template, its seeded surfaces and a front door telling a practitioner
# to go ask an agent for a field note, and all four adapters still listed one
# skill. The checks above passed, because they ask whether each adapter has a
# generated marker and points at AGENTS.md, and both were true the whole time.
#
# Same shape as the bundle file count one release earlier (ADR 0028): a derived
# list restated in several places, correct for as long as the underlying set
# never moved, and wrong within one commit of it moving. Two instances in
# consecutive releases is why this is a check and not a habit. ADR 0029.
echo
missing=0
for skill in skills/*/; do
  name="$(basename "$skill")"
  [ -f "$skill/SKILL.md" ] || { echo "no SKILL.md in $skill" >&2; missing=1; continue; }
  for f in adapters/CLAUDE.md adapters/GEMINI.md adapters/copilot-instructions.md adapters/.cursor/rules/causeway.mdc; do
    if grep -q "skills/$name/" "$f"; then
      echo "  ok  $f names skills/$name/"
    else
      echo "MISSING: $f does not name skills/$name/" >&2
      missing=1
    fi
  done
done
if [ "$missing" -ne 0 ]; then
  echo >&2
  echo "An adapter that does not name a skill is a skill no agent will invoke." >&2
  echo "Add the pointer, or delete the skill." >&2
  exit 1
fi

echo
echo "If an adapter ever embeds standard content rather than pointing at it,"
echo "replace this script with a real renderer before that content can drift."
