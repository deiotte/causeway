#!/usr/bin/env python3
"""
validate.py — tick-and-tie the standard against itself.

Run from anywhere; resolves the standard root from its own location.

    ./tools/validate.py

Every check here exists because the same class of drift already happened at
least once. `composition-state` blocked at four profiles for several revisions
with three different answer sets in three files, and nothing noticed because
nothing was looking. The document was consistent with itself in prose and
inconsistent in fact.

This is the standard's own gate. It is deliberately not the same code as the
consumer-facing `check-drift.sh`: that script verifies a *vendored copy* against
its pin and must stay dependency-free because it runs in other people's CI.
This one verifies the *source of truth* against itself and may assume python3.

Exit 0 clean, 1 on any failure. Every failure prints what disagreed with what.
"""
from __future__ import annotations

import collections
import fnmatch
import json
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

failures: list[str] = []
checked = 0


def fail(what: str, detail: str = "") -> None:
    failures.append(f"{what}\n      {detail}" if detail else what)


def ok(_what: str) -> None:
    global checked
    checked += 1


def check(label: str, condition: bool, detail: str = "") -> None:
    ok(label) if condition else fail(label, detail)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def load(path: str) -> dict:
    return json.loads(read(path))


# ── Load ────────────────────────────────────────────────────────────────────

try:
    profiles = load("gate/profiles.json")
    checks = load("gate/checks.json")
    manifest = load("bundle/manifest.json")
except (OSError, json.JSONDecodeError) as e:
    print(f"FATAL: cannot load a required artifact: {e}", file=sys.stderr)
    sys.exit(1)

version = read("VERSION").strip()
released = read("RELEASED").strip()
gate_config = read("gate/gate-configuration.md")
agents = read("AGENTS.md")
spine = read("skills/decision-spine/reference/spine.md")
sync_sh = read("tools/sync.sh")
drift_sh = read("tools/check-drift.sh")

profile_ids = [c["id"] for c in profiles["checks"]]
spec_ids = [c["id"] for c in checks["checks"]]
specs = {c["id"]: c for c in checks["checks"]}


# ── 1. Identity and uniqueness ──────────────────────────────────────────────

check("profiles.json check ids are unique",
      len(profile_ids) == len(set(profile_ids)),
      f"{len(profile_ids)} entries, {len(set(profile_ids))} distinct")

check("checks.json check ids are unique",
      len(spec_ids) == len(set(spec_ids)),
      f"{len(spec_ids)} entries, {len(set(spec_ids))} distinct")

only_profiles = sorted(set(profile_ids) - set(spec_ids))
only_specs = sorted(set(spec_ids) - set(profile_ids))
check("every check has both a blocking matrix and a specification",
      not only_profiles and not only_specs,
      f"in profiles.json only: {only_profiles or 'none'} · "
      f"in checks.json only: {only_specs or 'none'}")


# ── 2. The prose table ties to the machine-readable inventory ───────────────

# Scoped to §4's inventory table. The Modifiers table below it also starts its
# rows with `| **`, so an unscoped match counts two rows that are not checks.
inventory = gate_config.split("## 4. Check inventory", 1)
if len(inventory) < 2:
    fail("gate-configuration.md §4 not found")
else:
    inventory_table = inventory[1].split("### Modifiers", 1)[0]
    table_rows = re.findall(r"^\| \*\*.+\|\s*$", inventory_table, re.MULTILINE)
    check("gate-configuration §4 table row count matches profiles.json",
          len(table_rows) == len(profile_ids),
          f"prose table has {len(table_rows)} rows, profiles.json has {len(profile_ids)} checks")


# ── 3. Modifiers resolve ────────────────────────────────────────────────────

declared_modifiers = set(profiles.get("modifiers", {})) - {"$comment"}

for entry in profiles["checks"]:
    for mod in entry.get("modifiers", []):
        check(f"profiles.json modifier '{mod}' on {entry['id']} is declared",
              mod in declared_modifiers,
              f"declared modifiers: {sorted(declared_modifiers)}")
    promotes = entry.get("promotes_to") or {}
    for mod in promotes.get("modifiers", []):
        check(f"profiles.json promotes_to modifier '{mod}' on {entry['id']} is declared",
              mod in declared_modifiers,
              f"declared modifiers: {sorted(declared_modifiers)}")

for spec in checks["checks"]:
    for mod in spec.get("modifiers", []):
        check(f"checks.json modifier '{mod}' on {spec['id']} is declared",
              mod in declared_modifiers,
              f"declared modifiers: {sorted(declared_modifiers)}")


# ── 4. Input classes resolve ────────────────────────────────────────────────

declared_classes = set(checks.get("input_classes", {})) - {"$comment"}
check("input_classes are declared", bool(declared_classes))

for spec in checks["checks"]:
    unknown = [c for c in spec.get("inputs", []) if c not in declared_classes]
    check(f"{spec['id']} input classes are declared",
          not unknown,
          f"unknown: {unknown}")
    check(f"{spec['id']} declares at least one input class",
          bool(spec.get("inputs")))


# ── 5. Waiver and verdict vocabulary ────────────────────────────────────────

waiver_forms = set(checks.get("waiver_forms", {}))
for spec in checks["checks"]:
    form = spec.get("waiver_form")
    check(f"{spec['id']} waiver_form is declared",
          form in waiver_forms,
          f"got {form!r}, declared: {sorted(waiver_forms)}")
    check(f"{spec['id']} waiverable agrees with waiver_form",
          spec.get("waiverable") is not (form == "none"),
          f"waiverable={spec.get('waiverable')} but waiver_form={form!r}")

exit_codes = set(int(k) for k in profiles.get("exit_codes", {}))
for spec in checks["checks"]:
    check(f"{spec['id']} exit_code is in the declared set",
          spec.get("exit_code") in exit_codes,
          f"got {spec.get('exit_code')}, declared: {sorted(exit_codes)}")


# ── 6. Composition vocabulary — the ADR 0008 regression guard ───────────────

section4 = agents.split("## 4. Brownfield is the normal case", 1)
if len(section4) < 2:
    fail("AGENTS.md §4 not found")
else:
    body = section4[1].split("\n## ", 1)[0]
    agents_states = [m.lower() for m in re.findall(r"^- \*\*([A-Za-z-]+)\*\*", body, re.MULTILINE)]

    spine_row = re.search(r"^\| SA-3\.13 \|[^|]*\|([^|]*)\|", spine, re.MULTILINE)
    spine_states = ([s.strip().lower() for s in spine_row.group(1).split("/")]
                    if spine_row else [])

    spec_states = [s.lower() for s in specs.get("composition-state", {}).get("valid_values", [])]

    check("AGENTS.md §4 names three composition states",
          len(agents_states) == 3, f"got {agents_states}")
    check("spine SA-3.13 answer set matches AGENTS.md §4",
          spine_states == agents_states,
          f"spine: {spine_states}\n      agents: {agents_states}")
    check("checks.json composition-state valid_values matches AGENTS.md §4",
          spec_states == agents_states,
          f"checks.json: {spec_states}\n      agents: {agents_states}")


# ── 7. Version consistency across the artifacts ─────────────────────────────

gate_version = re.search(r"^\*\*Version:\*\* (.+)$", gate_config, re.MULTILINE)
gate_version = gate_version.group(1).strip() if gate_version else ""

spine_version_hdr = re.search(r"^\*\*Version:\*\* ([0-9.]+)", spine, re.MULTILINE)
spine_version_hdr = spine_version_hdr.group(1) if spine_version_hdr else ""

# Build DNA's own version, read the same way. It moves independently of VERSION
# (ADR 0012) and an overlay is ratified against it by name (overlays/README.md),
# so it is a version core ships and an overlay can fall behind — which is what
# happened between 1.5 and 1.6: the guards below checked the spine and the gate
# configuration and never read this field, so the overlay stayed green for a
# release while describing a Build DNA that no longer shipped. ADR 0024.
build_dna_version = re.search(r"^\*\*Version:\*\* ([0-9.]+)", agents, re.MULTILINE)
build_dna_version = build_dna_version.group(1) if build_dna_version else ""

check("checks.json standard_version matches VERSION",
      checks["standard_version"] == version,
      f"checks.json {checks['standard_version']} vs VERSION {version}")
check("checks.json spine_version matches profiles.json",
      checks["spine_version"] == profiles["spine_version"],
      f"checks.json {checks['spine_version']} vs profiles.json {profiles['spine_version']}")
check("profiles.json spine_version matches the spine header",
      profiles["spine_version"] == spine_version_hdr,
      f"profiles.json {profiles['spine_version']} vs spine.md {spine_version_hdr}")
check("checks.json gate_config_version matches gate-configuration.md",
      checks["gate_config_version"] == gate_version,
      f"checks.json {checks['gate_config_version']} vs gate-configuration.md {gate_version}")
check("gate-configuration.md depends on the current spine version",
      f"Decision Spine v{spine_version_hdr}" in gate_config,
      f"expected 'Decision Spine v{spine_version_hdr}' in the header")
check("bundle manifest version matches VERSION",
      manifest["standard"]["version"] == version,
      f"manifest {manifest['standard']['version']} vs VERSION {version}")

# Build DNA versions independently of VERSION — ADR 0012 withdrew the coupling
# ADR 0003 asserted, because a process standard that bumps to say nothing in it
# changed has an empty field. What stays enforceable is that the field exists and
# parses: this document is read in other people's repositories long after it was
# vendored, and an unversioned document of record is ADR 0001's problem.
check("AGENTS.md declares a parseable document version",
      bool(re.search(r"^\*\*Version:\*\* [0-9]+\.[0-9]+", agents, re.MULTILINE)),
      "expected a '**Version:** N.N' line in the header")


# ── 8. Spine counts tie to the table ────────────────────────────────────────

# Scoped to the nine section tables. The Authority section cross-lists the eight
# † rows and the short-form and one-way sections list subsets, so an unscoped
# match reads those repeats as duplicate definitions.
_body = spine.split("## SA-1 · ", 1)
if len(_body) < 2:
    fail("spine.md SA-1 section not found")
    row_ids: list[str] = []
else:
    _tables = _body[1].split("## The one-way doors", 1)[0]
    row_ids = re.findall(r"^\| (SA-[0-9]+\.[0-9]+)", _tables, re.MULTILINE)
unique_rows = sorted(set(row_ids))
claimed = re.search(r"\*\*v[0-9.]+ counts, derived from the table:\*\* (\d+) rows", spine)
if claimed:
    check("spine header row count matches the table",
          int(claimed.group(1)) == len(unique_rows),
          f"header claims {claimed.group(1)}, table has {len(unique_rows)} distinct row ids")
else:
    fail("spine header has no derived count line")

check("spine row ids are unique",
      len(row_ids) == len(unique_rows),
      f"{len(row_ids)} row lines, {len(unique_rows)} distinct ids")

named_rows = set(profiles.get("named_approver_rows", []))
spec_named = set(specs.get("named-approvers", {}).get("spine_rows", []))
check("named-approvers spine_rows match profiles.json named_approver_rows",
      named_rows == spec_named,
      f"profiles.json: {sorted(named_rows)}\n      checks.json: {sorted(spec_named)}")

missing_rows = sorted(r for r in named_rows if r not in set(unique_rows))
check("every named-approver row exists in the spine table",
      not missing_rows, f"missing: {missing_rows}")

for spec in checks["checks"]:
    unknown = [r for r in spec.get("spine_rows", []) if r not in set(unique_rows)]
    check(f"{spec['id']} spine_rows exist in the spine table",
          not unknown, f"unknown rows: {unknown}")


# ── 9. RELEASED honesty — closes open item 6 ────────────────────────────────

try:
    out = subprocess.run(
        ["git", "-C", str(ROOT), "log", "-1", "--format=%cs", "--", "VERSION"],
        capture_output=True, text=True, timeout=15,
    )
    version_touched = out.stdout.strip()
except (OSError, subprocess.SubprocessError):
    version_touched = ""

if version_touched:
    check("RELEASED does not predate the last change to VERSION",
          released >= version_touched,
          f"RELEASED={released}, VERSION last changed {version_touched}. "
          "standard-currency measures every consumer against RELEASED, so a "
          "stale date makes every pinned copy look older than it is.")
else:
    ok("RELEASED guard skipped (no git history for VERSION — first commit)")

try:
    date.fromisoformat(released)
    ok("RELEASED parses as a date")
except ValueError:
    fail("RELEASED parses as a date", f"got {released!r}")


# ── 10. The vendored set, the bundle and the lock agree ─────────────────────

vendored = re.search(r"^VENDORED=\((.*?)^\)", sync_sh, re.MULTILINE | re.DOTALL)
# Comment lines inside the array are stripped first. Quoted prose in a comment
# is otherwise read as a filename, which is how this check first failed.
_vendored_body = "\n".join(
    line for line in (vendored.group(1).splitlines() if vendored else [])
    if not line.strip().startswith("#")
)
vendored_files = re.findall(r'"([^"]+)"', _vendored_body)
check("sync.sh VENDORED list is parseable", bool(vendored_files))

bundle_paths = {f["path"] for f in manifest["files"]}
# manifest.json is vendored but cannot digest itself.
not_in_bundle = sorted(f for f in vendored_files if f not in bundle_paths
                       and f != "bundle/manifest.json"
                       and not f.startswith("overlays/"))
check("every vendored file is covered by the bundle digest",
      not not_in_bundle,
      f"vendored but not digested: {not_in_bundle}")

missing_on_disk = sorted(f for f in vendored_files if not (ROOT / f).is_file())
check("every vendored file exists", not missing_on_disk, f"missing: {missing_on_disk}")

# Scope to the block that actually writes the lock, then take every echoed key
# in it — conditional or not.
#
# This guard used to read `^\s*echo "([a-z_]+)=`, which only matched an echo at
# the start of a line. Three of the seven keys are written conditionally
# (`[ -n "$COMMIT" ] && echo "commit=..."`), so `commit`, `overlay` and later
# `tag` were invisible to it. It reported agreement between two lists while
# silently comparing a subset, which is the shape of failure the conformance
# fixtures exist to catch and this check had itself.
# The lock is written into the staging directory and moved into place last
# (ADR 0042), so the redirect names the stage rather than the target.
lock_block = re.search(r"\{(.*?)\}\s*>\s*\"\$STAGE/new/\$LOCK_DST\"",
                       sync_sh, re.DOTALL)
check("sync.sh lock-writing block is parseable", bool(lock_block))
lock_keys = set(re.findall(r'echo "([a-z_]+)=\$',
                           lock_block.group(1) if lock_block else ""))
drift_skips = re.search(r"case \"\$sum\" in ([^)]*)\)", drift_sh)
drift_keys = set(re.findall(r"([a-z_]+)=\*", drift_skips.group(1))) if drift_skips else set()
unhandled = sorted(lock_keys - drift_keys)
check("check-drift.sh skips every header key sync.sh writes",
      not unhandled,
      f"sync.sh writes {sorted(lock_keys)}, check-drift.sh skips {sorted(drift_keys)}; "
      f"unhandled: {unhandled} — these would be read as checksum lines")


# ── 11. Every tracked path is governed ──────────────────────────────────────
#
# The check that would have caught the systems_engineering/ kit. See the $why
# in bundle/scope.json: a directory nothing enumerates is a directory nothing
# governs, and neither build-bundle.sh (an explicit allowlist) nor any check
# above (targeted globs) has ever looked at the tree as a whole.


def scope_match(pattern: str, path: str) -> bool:
    """gitignore-style match: * stays inside a segment, ** crosses them."""
    pat, seg = pattern.split("/"), path.split("/")

    def walk(pi: int, si: int) -> bool:
        while pi < len(pat):
            if pat[pi] == "**":
                if pi + 1 == len(pat):
                    return True
                return any(walk(pi + 1, s) for s in range(si, len(seg) + 1))
            if si >= len(seg) or not fnmatch.fnmatchcase(seg[si], pat[pi]):
                return False
            pi, si = pi + 1, si + 1
        return si == len(seg)

    return walk(0, 0)


try:
    scope = load("bundle/scope.json")
except (OSError, json.JSONDecodeError) as e:
    scope = {"ungoverned": []}
    fail("bundle/scope.json loads", str(e))

ungoverned = scope.get("ungoverned", [])
check("bundle/scope.json declares an ungoverned list", isinstance(ungoverned, list))

# A reason is not decoration. An exemption a reader cannot evaluate is a
# rubber stamp, and a rubber stamp is how the next kit gets in.
unreasoned = sorted(e.get("pattern", "<no pattern>") for e in ungoverned
                    if not str(e.get("reason", "")).strip())
check("every ungoverned pattern carries a reason",
      not unreasoned, f"no reason given: {unreasoned}")

# A pattern broad enough to swallow the tree defeats the check entirely.
catch_alls = sorted(e["pattern"] for e in ungoverned
                    if e.get("pattern") in ("*", "**", "**/*", "*/**"))
check("no ungoverned pattern is a catch-all",
      not catch_alls,
      f"{catch_alls} would exempt the whole tree — declare the directory instead")

try:
    tracked = sorted(subprocess.run(
        ["git", "-C", str(ROOT), "ls-files"],
        capture_output=True, text=True, check=True).stdout.split())
except (OSError, subprocess.CalledProcessError) as e:
    tracked = []
    fail("git ls-files enumerates the tree",
         f"{e} — this check cannot run outside a git checkout, and skipping it "
         f"silently is the failure mode it exists to prevent")

patterns = [e["pattern"] for e in ungoverned if e.get("pattern")]
undeclared = sorted(
    f for f in tracked
    if f not in bundle_paths
    and not any(scope_match(pat, f) for pat in patterns)
)
check("every tracked file is bundled or declared ungoverned",
      not undeclared,
      f"{len(undeclared)} path(s) governed by nothing: {undeclared[:10]}"
      f"{' …' if len(undeclared) > 10 else ''}\n      "
      f"Add them to BUNDLE_FILES in tools/build-bundle.sh, or declare them in "
      f"bundle/scope.json with the reason they are not part of the standard.")

# A pattern matching nothing is a pattern that outlived the files it excused.
dead = sorted(pat for pat in patterns
              if not any(scope_match(pat, f) for f in tracked))
check("no ungoverned pattern is dead",
      not dead or not tracked,
      f"matches no tracked file: {dead}")


# The README's repository map named `decision-spine/` and `adrs/` for several
# releases. Neither path has ever existed: the real ones are
# `skills/decision-spine/` and `decisions/`. A front door that misdirects is a
# worse first impression than no map, and prose is exactly where this rots.

readme = read("README.md")
map_section = re.search(r"## Repository map\n(.*?)\n## ", readme, re.DOTALL)
check("README repository map section is present", bool(map_section))

mapped = re.findall(r"^\| `([^`]+)` \|", map_section.group(1), re.MULTILINE) \
    if map_section else []
check("README repository map has rows", bool(mapped))

absent = sorted(m for m in mapped if not (ROOT / m.rstrip("/")).exists())
check("every path in the README repository map exists",
      not absent, f"named but not on disk: {absent}")

# And the reverse: a directory absent from the map is a directory a reader
# never learns about, which is how an unenumerated one stays unnoticed.
tracked_dirs = {f.split("/")[0] for f in tracked if "/" in f
                and not f.startswith(".")}
unmapped = sorted(d for d in tracked_dirs
                  if not any(m.rstrip("/").split("/")[0] == d for m in mapped))
check("every tracked top-level directory appears in the README map",
      not unmapped, f"on disk but unmapped: {unmapped}")


# ── 12. Every ADR is well-formed ────────────────────────────────────────────

adr_numbers: list[int] = []
for adr_path in sorted((ROOT / "decisions").glob("[0-9]*.md")):
    text = adr_path.read_text(encoding="utf-8")
    name = adr_path.name
    check(f"{name} opens with frontmatter", text.startswith("---\n"))
    fm = text.split("---", 2)[1] if text.count("---") >= 2 else ""
    for field in ("adr:", "title:", "status:", "date:"):
        check(f"{name} frontmatter has {field}", field in fm)
    # `adr:` must be a QUOTED four-digit string, and the quotes are the point.
    #
    # YAML 1.1 reads a leading-zero integer as octal, so bare `adr: 0010` parses
    # to 8, `0011` to 9, and so on — every ADR from the tenth onward silently
    # wrong, by a margin that grows. `0008` and `0009` are not valid octal, so
    # they fall back to strings and look correct, which is why the corruption
    # began exactly at 0010 and nothing noticed.
    #
    # This check previously read `^adr:\s*(\d+)` and compared the captured text.
    # A regex reads characters; a YAML parser reads meaning. checks.json defines
    # the repo-decisions input class as "ADR frontmatter parsed", so a conforming
    # engine sees the octal value while this validator saw the digits — the two
    # disagreed for seven releases and the build stayed green.
    #
    # Quoting is enforced rather than merely tolerated because it is the property
    # that makes the parse unambiguous under YAML 1.1 and 1.2 alike. Validating
    # the parsed value instead would mean this file parsing YAML, and the lesson
    # of the bug is that a text-level reading of YAML is not a reading of YAML.
    raw = re.search(r"^adr:[ \t]*(.*?)[ \t]*$", fm, re.MULTILINE)
    quoted = bool(raw) and re.fullmatch(r'"\d{4}"', raw.group(1))
    check(f"{name} adr value is a quoted four-digit string",
          bool(quoted),
          f'got {raw.group(1) if raw else "nothing"} — write adr: "{name.split("-")[0]}". '
          f"Unquoted leading-zero digits are octal in YAML: 0010 parses as 8.")
    if quoted:
        digits = raw.group(1).strip('"')
        adr_numbers.append(int(digits))
        check(f"{name} adr number matches its filename",
              digits == name.split("-")[0],
              f"frontmatter says {digits}")
    rows = re.search(r"^spine_rows:\s*\[(.*?)\]", fm, re.MULTILINE | re.DOTALL)
    if rows and rows.group(1).strip():
        for r in re.findall(r"SA-[0-9]+\.[0-9]+", rows.group(1)):
            check(f"{name} cites a real spine row ({r})", r in set(unique_rows))

check("ADR numbers are unique",
      len(adr_numbers) == len(set(adr_numbers)),
      f"{sorted(adr_numbers)}")


# A correction has to be reachable from the thing it corrects. ADRs 0025 and 0026
# shipped six wrong counts between them and the record had no way to say so: §8
# makes an ADR immutable, which protects the argument and leaves a reader of the
# wrong number with nowhere to go. `corrected_by` is the forward pointer, and it is
# only worth having if it cannot rot — so it is checked the way ADR 0026 checks
# `duplicate_of`, in both directions.

CORRECTS = re.compile(r"^(corrects|corrected_by):\s*\[(.*?)\]", re.MULTILINE)
corrections: dict[str, dict[str, set[str]]] = {}
for adr_path in sorted((ROOT / "decisions").glob("[0-9]*.md")):
    fm = adr_path.read_text(encoding="utf-8").split("---", 2)
    fm = fm[1] if len(fm) >= 3 else ""
    corrections[adr_path.name.split("-")[0]] = {
        key: set(re.findall(r'"(\d{4})"', body)) for key, body in CORRECTS.findall(fm)}

known = set(corrections)
dangling = sorted((n, key, tgt) for n, rels in corrections.items()
                  for key, tgts in rels.items() for tgt in tgts if tgt not in known)
check("every ADR named by a correction exists", not dangling, f"{dangling}")

self_ref = sorted(n for n, rels in corrections.items()
                  if n in rels.get("corrects", set()) | rels.get("corrected_by", set()))
check("no ADR corrects itself", not self_ref, f"{self_ref}")

one_sided = []
for n, rels in corrections.items():
    for tgt in rels.get("corrects", set()):
        if tgt in known and n not in corrections[tgt].get("corrected_by", set()):
            one_sided.append(f"{n} corrects {tgt}, which does not name {n} in corrected_by")
    for src in rels.get("corrected_by", set()):
        if src in known and n not in corrections[src].get("corrects", set()):
            one_sided.append(f"{n} says corrected_by {src}, which does not name {n} in corrects")
check("corrects and corrected_by name each other", not one_sided,
      "; ".join(sorted(one_sided)))


# ── 13. Conformance fixtures tie to the expectations file ───────────────────

try:
    expectations = load("conformance/expectations.json")
except (OSError, json.JSONDecodeError) as e:
    fail("conformance/expectations.json loads", str(e))
    expectations = None

if expectations:
    declared_verdicts = set(checks.get("verdicts", {})) - {"$comment"}

    check("expectations standard_version matches VERSION",
          expectations["standard_version"] == version,
          f"expectations {expectations['standard_version']} vs VERSION {version}")

    scope_checks = expectations["scope"]["checks"]
    unknown_scope = [c for c in scope_checks if c not in specs]
    check("every check in the conformance scope exists in checks.json",
          not unknown_scope, f"unknown: {unknown_scope}")

    fixture_dir = ROOT / "conformance" / "fixtures"
    on_disk = {p.name for p in fixture_dir.iterdir() if p.is_dir()} if fixture_dir.is_dir() else set()
    declared = {f["id"] for f in expectations["fixtures"]}

    check("every declared fixture has a directory",
          not (declared - on_disk), f"missing on disk: {sorted(declared - on_disk)}")
    check("every fixture directory is declared",
          not (on_disk - declared), f"undeclared: {sorted(on_disk - declared)}")

    precedence = expectations["exit_code_precedence"]
    check("exit_code_precedence covers exactly the declared exit codes",
          set(precedence) == exit_codes | {0},
          f"precedence {sorted(precedence)} vs declared {sorted(exit_codes | {0})}")

    for fx in expectations["fixtures"]:
        fid = fx["id"]
        expect = fx["expect"]

        check(f"fixture {fid} exit_code is a declared code",
              expect["exit_code"] in exit_codes | {0},
              f"got {expect['exit_code']}")

        stated = set(expect["checks"])
        check(f"fixture {fid} states a verdict for every in-scope check",
              stated == set(scope_checks),
              f"missing: {sorted(set(scope_checks) - stated)} · "
              f"extra: {sorted(stated - set(scope_checks))}")

        for cid, verdict in expect["checks"].items():
            check(f"fixture {fid}: {cid} verdict is declared vocabulary",
                  verdict in declared_verdicts,
                  f"got {verdict!r}, declared: {sorted(declared_verdicts)}")

        for cid in expect.get("evidence", {}):
            check(f"fixture {fid}: evidence names a real check",
                  cid in specs, f"unknown check {cid!r}")
            for key in expect["evidence"].get(cid, {}):
                declared_keys = specs.get(cid, {}).get("evidence", [])
                check(f"fixture {fid}: {cid} evidence key '{key}' is in the check's contract",
                      key in declared_keys,
                      f"declared: {declared_keys}")

        # A fixture asserting a blocking verdict must not claim exit 0, and one
        # asserting all-clear must not claim a failure. This caught nothing when
        # written, which is the point at which it is cheap to add.
        blocking_verdicts = {v for v, meta in checks["verdicts"].items()
                             if v != "$comment" and meta.get("blocking")}
        has_hard = any(v in blocking_verdicts for v in expect["checks"].values())
        has_fail = "fail" in expect["checks"].values()
        if has_hard or has_fail:
            check(f"fixture {fid} claims a non-zero exit for its blocking verdict",
                  expect["exit_code"] != 0,
                  f"verdicts {expect['checks']} but exit_code 0")


# ── 14. Overlays tie to the spine they claim ────────────────────────────────
#
# An overlay dispositions all 94 rows and publishes the counts (overlays/README
# "Writing a new one"), and both facts were previously enforced by whoever last
# read the file. The version guard is the one that earns its place: the spine
# moved 0.7 → 0.8 and the gate configuration 0.5 → 0.6 underneath
# overlays/servicenow.md, nothing failed, and the overlay spent a release
# describing an answer set the spine no longer had. Reconciling an overlay is
# cheap when a release forces it and archaeology when it does not.

DISPOSITION_ROW = re.compile(r"^\|\s*(SA-\d+\.\d+)\s*†?\s*\|\s*([ISP])\s*→?\s*\|",
                             re.MULTILINE)

overlay_paths = sorted(p for p in (ROOT / "overlays").glob("*.md")
                       if p.name != "README.md")
overlays_readme = read("overlays/README.md")
spine_rows_set = set(unique_rows)

check("at least one overlay is present", bool(overlay_paths))

for _path in overlay_paths:
    name = _path.stem
    text = read(f"overlays/{name}.md")
    rows = DISPOSITION_ROW.findall(text)
    ids = [r for r, _ in rows]

    check(f"overlay {name}: row ids appear once each",
          len(ids) == len(set(ids)),
          f"{len(ids)} rows, {len(set(ids))} distinct")

    absent = sorted(spine_rows_set - set(ids))
    invented = sorted(set(ids) - spine_rows_set)
    check(f"overlay {name}: dispositions every spine row and no others",
          not absent and not invented,
          f"undispositioned: {absent or 'none'} · not in the spine: {invented or 'none'}")

    tally = {d: sum(1 for _, disp in rows if disp == d) for d in "ISP"}

    m = re.search(r"Rows dispositioned \|\s*(\d+) of (\d+)", text)
    if m:
        check(f"overlay {name}: published row total matches its table",
              (int(m.group(1)), int(m.group(2))) == (len(ids), len(spine_rows_set)),
              f"published {m.group(1)} of {m.group(2)}, "
              f"table has {len(ids)} of {len(spine_rows_set)}")
    else:
        fail(f"overlay {name}: publishes a 'Rows dispositioned' total")

    m = re.search(r"Inherited / Shared / Project-answered \|\s*(\d+) / (\d+) / (\d+)", text)
    if m:
        check(f"overlay {name}: published I/S/P counts match its table",
              tuple(int(g) for g in m.groups()) == (tally["I"], tally["S"], tally["P"]),
              f"published {'/'.join(m.groups())}, "
              f"table has {tally['I']}/{tally['S']}/{tally['P']}")
    else:
        fail(f"overlay {name}: publishes I/S/P counts")

    # The header states what this overlay was ratified against. When core moves
    # past it, the overlay is stale by definition and the build says so.
    for label, pattern, current in (
        ("spine", r"Decision Spine v([0-9.]+)", spine_version_hdr),
        ("gate configuration", r"Gate configuration v([0-9.]+)", gate_version),
        ("Build DNA", r"Build DNA v([0-9.]+)", build_dna_version),
    ):
        m = re.search(pattern, text)
        check(f"overlay {name}: ratified against the current {label}",
              bool(m) and m.group(1) == current,
              f"overlay says {m.group(1) if m else 'nothing'}, "
              f"standard ships {current} — reconcile the overlay and move its header")

    m_ver = re.search(r"^\|\s*\*\*Version\*\*\s*\|\s*([0-9.]+)\s*\|", text, re.MULTILINE)
    m_row = re.search(rf"\|\s*\[`{re.escape(name)}\.md`\]\({re.escape(name)}\.md\)\s*\|"
                      rf"\s*([0-9.]+)\s*\|\s*Ratified against spine v([0-9.]+)",
                      overlays_readme)
    check(f"overlay {name}: listed in the overlays/README table", bool(m_row))
    if m_ver and m_row:
        check(f"overlay {name}: README version matches the overlay header",
              m_row.group(1) == m_ver.group(1),
              f"README {m_row.group(1)} vs overlay {m_ver.group(1)}")
        check(f"overlay {name}: README spine version matches the overlay header",
              m_row.group(2) == spine_version_hdr,
              f"README {m_row.group(2)} vs spine {spine_version_hdr}")


# ── 15. The machine-readable overlay projects the prose exactly ─────────────
#
# An overlay that ships a JSON alongside its markdown has two copies of the same
# dispositions, which is the shape of every drift this file was written for.
# The prose is the overlay; the JSON is a projection and must be derivable from
# it. Everything checkable is checked here, so "the JSON says something the
# document does not" cannot survive a push.

ONEWAY_FLAG = re.compile(r"^\|\s*(SA-\d+\.\d+)\s*\|[^|]*\|[^|]*\|\s*([YN])\s*\|", re.MULTILINE)
spine_oneway = {rid: flag == "Y" for rid, flag in ONEWAY_FLAG.findall(spine)}

for _path in overlay_paths:
    name = _path.stem
    json_path = ROOT / "overlays" / f"{name}.json"
    if not json_path.is_file():
        continue

    text = read(f"overlays/{name}.md")
    try:
        proj = load(f"overlays/{name}.json")
    except (OSError, json.JSONDecodeError) as e:
        fail(f"overlay {name}.json loads", str(e))
        continue

    prose_rows = {
        rid: {
            "disposition": d,
            "named_approver": bool(dagger),
            "platform_vocabulary": bool(arrow),
            "note": None if note.strip() == "—" else note.strip(),
        }
        for rid, dagger, d, arrow, note in re.findall(
            r"^\|\s*(SA-\d+\.\d+)\s*(†)?\s*\|\s*([ISP])\s*(→)?\s*\|\s*(.*?)\s*\|\s*$",
            text, re.MULTILINE)
    }
    divergent = sorted(r for r in set(prose_rows) | set(proj.get("dispositions", {}))
                       if prose_rows.get(r) != proj.get("dispositions", {}).get(r))
    check(f"overlay {name}.json dispositions match the prose table",
          not divergent,
          f"rows differing: {divergent[:8]}{' …' if len(divergent) > 8 else ''}")

    c = proj.get("counts", {})
    tally = collections.Counter(v["disposition"] for v in prose_rows.values())
    check(f"overlay {name}.json counts match the prose table",
          (c.get("inherited"), c.get("shared"), c.get("project_answered"), c.get("total"))
          == (tally["I"], tally["S"], tally["P"], len(prose_rows)),
          f"json {c}, prose I/S/P {tally['I']}/{tally['S']}/{tally['P']} of {len(prose_rows)}")

    m_ver = re.search(r"^\|\s*\*\*Version\*\*\s*\|\s*([0-9.]+)\s*\|", text, re.MULTILINE)
    check(f"overlay {name}.json version matches the overlay header",
          bool(m_ver) and proj.get("overlay_version") == m_ver.group(1),
          f"json {proj.get('overlay_version')} vs overlay "
          f"{m_ver.group(1) if m_ver else 'unparseable'}")

    rat = proj.get("ratified_against", {})
    check(f"overlay {name}.json is ratified against the current spine and gate config",
          (rat.get("spine"), rat.get("gate_config")) == (spine_version_hdr, gate_version),
          f"json {rat.get('spine')}/{rat.get('gate_config')} vs "
          f"standard {spine_version_hdr}/{gate_version}")
    # Checked apart from the pair above so the failure names the field. This is
    # the one that was missing: the projection carried build_dna from the day
    # it was written and nothing ever read it.
    check(f"overlay {name}.json is ratified against the current Build DNA",
          rat.get("build_dna") == build_dna_version,
          f"json {rat.get('build_dna')} vs AGENTS.md {build_dna_version} — "
          "reconcile the overlay against the new Build DNA and move both headers")

    # Evidence must cover every check and agree with the engine contract about
    # what each one reads. An overlay naming a platform artifact for an input
    # class the check does not take is describing a check that does not exist.
    ev = proj.get("check_evidence", {})
    check(f"overlay {name}.json names evidence for every check",
          set(ev) == set(spec_ids),
          f"missing: {sorted(set(spec_ids) - set(ev))} · "
          f"unknown: {sorted(set(ev) - set(spec_ids))}")
    mismatched = sorted(cid for cid in set(ev) & set(spec_ids)
                        if ev[cid].get("inputs") != specs[cid]["inputs"])
    check(f"overlay {name}.json evidence inputs match checks.json",
          not mismatched, f"disagreeing: {mismatched}")

    check(f"overlay {name}.json input classes match checks.json",
          set(proj.get("input_classes", {})) == set(checks["input_classes"]) - {"$comment"},
          f"json {sorted(set(proj.get('input_classes', {})))}")

    # Containment: an overlay supplies vocabulary for a one-way row. It may not
    # decide that a row is one-way, so every row it treats as one had better be
    # flagged that way in the spine.
    not_oneway = sorted(r for r in proj.get("one_way_vocabulary", {})
                        if not spine_oneway.get(r))
    check(f"overlay {name}.json gives one-way vocabulary only to one-way rows",
          not not_oneway,
          f"not flagged one-way in the spine: {not_oneway}")

    exposure = proj.get("engine_exposure", {})
    expected_repo = sorted(c["id"] for c in checks["checks"]
                           if any(i.startswith("repo-") for i in c.get("inputs", [])))
    check(f"overlay {name}.json repo-class check list is derived from checks.json",
          exposure.get("checks_reading_a_repo_class") == expected_repo
          and exposure.get("checks_total") == len(spec_ids),
          "the list or the total disagrees with checks.json")
    for prof, stated in (exposure.get("by_profile") or {}).items():
        blocking = [e["id"] for e in profiles["checks"] if e.get(prof) == "block"]
        check(f"overlay {name}.json {prof} exposure is derived from profiles.json",
              stated.get("blocking") == len(blocking)
              and stated.get("blocking_needing_repo_class")
              == sorted(b for b in blocking if b in expected_repo),
              f"stated {stated.get('blocking')} blocking at {prof}, "
              f"profiles.json has {len(blocking)}")


# The README advertised "8 conformance fixtures" and said nothing about how many
# checks those fixtures actually reach. Eight fixtures over five checks is an
# honest Phase 1 slice; eight fixtures over an unstated denominator reads like
# coverage. expectations.json already declares the scope — the README must agree
# with it rather than restate it from memory.

scoped_checks = (expectations or {}).get("scope", {}).get("checks", [])
check("conformance scope names only real checks",
      all(c in set(spec_ids) for c in scoped_checks),
      f"unknown: {sorted(set(scoped_checks) - set(spec_ids))}")


# ── 16. Counts stated in prose are derived from the artifacts ───────────────
#
# Three sentences across two documents quantified the engine-integration cost
# and all three were wrong at v1.6.0 — 14 for what is 17, and eleven others for
# what is nine. Nobody mistyped: the numbers were true of a draft inventory and
# nothing recounted them when checks moved. A number in prose that is derivable
# from an artifact belongs in this file.
#
# That reasoning still holds. How it was enforced did not.
#
# Each count was pinned to one exact sentence — `why (\w+) of the (\d+) checks
# read the \*product repository\*` — so the guard failed on any rewrite, and its
# own message said so: "the guard needs updating with the prose". It fired three
# times on three README rewrites (v1.7.0, and twice more) and every time the
# number in the prose was *correct*. Twice it was answered by retyping the
# blessed sentence; PR #11 is two added lines restoring one verbatim.
#
# A guard that cannot tell "this number went stale" from "this sentence was
# rephrased" reports the second as the first, and the cheapest way to green is
# to write the sentence back. That trains the prose to serve the regex.
#
# So the binding moves from the sentence to the claim. An anchor is the smallest
# span that identifies *which* count is being made — "N of the M checks read" —
# and carries no decoration. Every numeric match must agree with the artifact,
# and at least one must exist. Three consequences worth stating:
#
#   - Restating a count is now free, and helps: the README says 27 five times
#     and each one is checked. Under the old guard four of them were invisible.
#   - A match whose captured token is not a number is prose the anchor happened
#     to span ("lack conformance fixtures"), not a claim. It is skipped, which
#     is what lets anchors be loose enough to survive a rewrite.
#   - Losing the count entirely is still a failure, but a distinct one, and it
#     names the derived value so the fix is the prose, not the pattern.
#
# The anchor list is the declared surface, in the sense bundle/scope.json means
# it: a count nothing anchors is a count nothing governs. Adding an anchor is
# the intended response to a rewrite this set does not span. Retyping a sentence
# to satisfy a regex is not.

_WORDS = ("one two three four five six seven eight nine ten eleven twelve thirteen "
          "fourteen fifteen sixteen seventeen eighteen nineteen twenty").split()
NUMBERS = {w: i + 1 for i, w in enumerate(_WORDS)}

# Longest-first so `nineteen` is never shadowed by `nine`; \b makes that safe
# anyway, and the ordering makes it safe to read.
NUM = r"\b(" + "|".join([r"\d+"] + sorted(_WORDS, key=len, reverse=True)) + r")\b"


def numeral(token: str):
    """A count written as digits or as a word. None if it is neither."""
    return int(token) if token.isdigit() else NUMBERS.get(token.lower())


readme = read("README.md")
spine_skill = read("skills/decision-spine/SKILL.md")

# Scoped to the SA-n row tables for the same reason unique_rows is: the short-form
# and one-way sections below them list subsets, and an unscoped match reads those
# repeats as rows.
_spine_tables = spine.split("## SA-1 · ", 1)
_spine_tables = (_spine_tables[1].split("## The one-way doors", 1)[0]
                 if len(_spine_tables) > 1 else "")
APPLIES_COL = re.compile(
    r"^\|\s*SA-\d+\.\d+\s*(?:†\s*)?\|[^|]*\|[^|]*\|\s*[YN]\s*\|\s*(C1(?:[–-]C[23])?)\s*\|",
    re.MULTILINE)
n_short_form = sum(1 for a in APPLIES_COL.findall(_spine_tables)
                   if a in ("C1–C3", "C1-C3"))

repo_class_checks = [c["id"] for c in checks["checks"]
                     if any(i.startswith("repo-") for i in c.get("inputs", []))]
n_classes = len(set(checks["input_classes"]) - {"$comment"})
n_fixtures = len((expectations or {}).get("fixtures", []))

# `named_inline` is the five input classes gate-configuration lists by name
# before saying "and N others"; the prose count is the remainder, not the total.
named_inline = 5

# (label, documents, anchors). An anchor is (pattern, expected). `NUM` in a
# pattern expands to the number matcher above and contributes one group per
# occurrence — every other group in an anchor must be non-capturing, or the
# arity stops lining up with `expected`.
PROSE_COUNTS = (
    ("product-repository check count",
     (("README.md", readme), ("gate/gate-configuration.md", gate_config)),
     ((r"NUM of the NUM checks read", (len(repo_class_checks), len(spec_ids))),)),

    ("conformance coverage",
     (("README.md", readme),),
     ((r"NUM fixtures over NUM checks", (n_fixtures, len(scoped_checks))),
      (r"NUM (?:\w+ )?fixtures exercise (?:only )?NUM of NUM checks",
       (n_fixtures, len(scoped_checks), len(spec_ids))),
      (r"NUM (?:\w+ )?fixtures pin outcomes", (n_fixtures,)),
      (r"beyond NUM of NUM checks", (len(scoped_checks), len(spec_ids))))),

    ("gate-configuration input-class count",
     (("gate/gate-configuration.md", gate_config),),
     ((r"`ta-record`, and NUM others", (n_classes - named_inline,)),)),

    # The bundle file count. Stated three times in the README and checked by
    # nothing until ADR 0028, which was the first change in this repository's
    # history to move it — the count had been 24 since the bundle existed, so
    # every restatement of it had been accidentally correct. A number that has
    # never changed is not a number that is verified; it is one that has not yet
    # been tested, and §16 exists because this repository keeps finding the
    # difference the expensive way.
    # The C3 short form. The `Applies` column is authoritative — the short form
    # *is* the C1–C3 filter, which is what the v0.5 correction settled — so the
    # count is derived from the column and never from a list. spine.md stated it
    # as 22 from v0.6 until v1.16.0: correct when written, stale the moment
    # SA-5.16 joined the form, and four hundred lines from the section that said
    # twenty-three. Every other statement of it was right, so nothing disagreed
    # loudly enough for a reader to catch — which is the case §16 exists for.
    ("C3 short-form row count",
     (("skills/decision-spine/reference/spine.md", spine),
      ("skills/decision-spine/SKILL.md", spine_skill)),
     ((r"NUM-row short form", (n_short_form,)),
      (r"NUM in the short form", (n_short_form,)),
      (r"NUM \(the short form\)", (n_short_form,)))),

    ("bundle file count",
     (("README.md", readme),),
     ((r"NUM-file consumer bundle", (len(manifest["files"]),)),
      (r"NUM-file bundle digest", (len(manifest["files"]),)),
      (r"NUM consumer-bundle files", (len(manifest["files"]),)))),
)

for label, docs, anchors in PROSE_COUNTS:
    stated, wrong = 0, []
    for doc_name, doc in docs:
        for pattern, expected in anchors:
            for m in re.finditer(pattern.replace("NUM", NUM), doc, re.IGNORECASE):
                vals = tuple(numeral(g) for g in m.groups())
                if any(v is None for v in vals):
                    continue  # prose the anchor spanned, not a claim
                stated += 1
                if vals != expected:
                    wrong.append(f"{doc_name}: {' '.join(m.group(0).split())!r} "
                                 f"— the artifacts say {expected}")
    if not stated:
        fail(f"{label} is no longer stated in prose",
             f"the artifacts derive {anchors[0][1]}. State it, or add an anchor "
             f"to PROSE_COUNTS if the wording is right and the pattern is not.")
    else:
        check(f"{label} agrees with the artifacts in all {stated} places it is stated",
              not wrong, "; ".join(wrong))


# ── 17. The open-items index ties to the registers it names ─────────────────
#
# An ADR does not only close a spine row. It leaves things behind, and those land
# as numbered items in whatever document the ADR was amending — four documents
# here, four independent numberings, every closure written in prose and nowhere
# else. Nothing counted them, and the arithmetic that follows from that is the
# reason this section exists.
#
# gate/gate-configuration.md open item 10 was appended to the end of §11 when
# ADR 0009 opened it. ADR 0019 half-closed it in place. ADR 0023 amended it again
# and described it as keeping "its number per the rule §10 states for itself" —
# while the item sat two hundred lines outside §10. Three ADRs pointed at an item
# no reader of the register could find, and §10 showed nine items for eleven
# releases. Nothing disagreed, because nothing was counting.
#
# So the index counts, and this section checks the index against the prose. The
# split is the one Build DNA §8 states: the index owns an item's state, the prose
# entry owns its argument. What gets bound here is therefore structure and state
# — which numbers exist, which are closed, which ADRs are named — and never the
# text of a title. §16 records what happens when a guard binds prose it cannot
# distinguish from a rewrite, and the lesson transfers: rewording an item is free,
# losing one is not.
#
# Deliberately not checked: that an open item is still worth having open. No
# validator can know that, and one that pretended to would be the third numbering
# scheme in a different costume.

try:
    open_items = load("decisions/open-items.json")
except (OSError, json.JSONDecodeError) as e:
    fail("decisions/open-items.json loads", str(e))
    open_items = None

if open_items is not None:
    registers = open_items.get("registers", {})
    items = open_items.get("items", [])

    check("open-items index standard_version matches VERSION",
          open_items.get("standard_version") == version,
          f"index {open_items.get('standard_version')} vs VERSION {version}")

    ids = [i["id"] for i in items]
    check("open-items ids are unique",
          len(ids) == len(set(ids)),
          f"{len(ids)} entries, {len(set(ids))} distinct")

    orphans = sorted({i["register"] for i in items} - set(registers))
    check("every item belongs to a declared register",
          not orphans, f"item registers not in `registers`: {orphans}")

    empty = sorted(set(registers) - {i["register"] for i in items})
    check("no declared register is empty",
          not empty,
          f"declared and carries no item: {empty} — a register with nothing in it "
          f"is either a document that lost its items or a key nobody removed")

    statuses = {i["status"] for i in items}
    check("every item status is open or closed",
          statuses <= {"open", "closed"},
          f"unknown: {sorted(statuses - {'open', 'closed'})}. There is no "
          f"half-closed — an item is open until every half of it is closed")

    # Every ADR an item names has to exist. This is the assertion that would have
    # caught a pointer surviving the thing it pointed at.
    adr_files = {p.name.split("-")[0] for p in (ROOT / "decisions").glob("[0-9]*.md")}
    dangling = sorted({(i["id"], role, i[role])
                       for i in items for role in ("opened_by", "closed_by")
                       if i.get(role) and i[role] not in adr_files})
    check("every ADR named by an open item exists",
          not dangling, f"{dangling}")

    # A closed item says when it closed and which ADR closed it. Build DNA §8:
    # an item that closed by nothing lapsed rather than closed, and the register
    # is where that difference is supposed to be visible.
    lapsed = sorted(i["id"] for i in items if i["status"] == "closed"
                    and not (i.get("closed_by") and i.get("closed_in")))
    check("every closed item names its closing ADR and version",
          not lapsed,
          f"closed with no ADR or no version: {lapsed} — write the ADR, or the "
          f"item lapsed rather than closed and should say so")

    # An open item that already names a closing ADR is a status the index forgot
    # to move. Cheap, and it is the exact shape of the drift this file is for.
    contradicted = sorted(i["id"] for i in items
                          if i["status"] == "open" and i.get("closed_by"))
    check("no open item already names an ADR that closed it",
          not contradicted, f"{contradicted}")

    n_open = sum(1 for i in items if i["status"] == "open")
    n_closed = sum(1 for i in items if i["status"] == "closed")
    stated = open_items.get("counts", {})
    check("open-items counts are derived from the items",
          stated == {"open": n_open, "closed": n_closed, "total": len(items)},
          f"stated {stated}, items give "
          f"{{'open': {n_open}, 'closed': {n_closed}, 'total': {len(items)}}}")

    # The prose side. A register names a document and a heading; the items under
    # that heading are the numbered list, and its numbers must be exactly the
    # numbers the index carries for that register.
    ITEM = re.compile(r"^(\d+)\. \*\*(.+?)\*\*", re.MULTILINE | re.DOTALL)

    for key, reg in sorted(registers.items()):
        doc_path = reg["document"]
        try:
            doc = read(doc_path)
        except OSError as e:
            fail(f"open-items register {key}: {doc_path} is readable", str(e))
            continue

        heading = re.search(rf"^##+ {re.escape(reg['section'])}\s*$", doc, re.MULTILINE)
        if not heading:
            fail(f"open-items register {key}: {doc_path} still has the section it names",
                 f"no heading '{reg['section']}' — the register moved or was "
                 f"renamed; update decisions/open-items.json to match")
            continue

        rest = doc[heading.end():]
        nxt = re.search(r"^## ", rest, re.MULTILINE)
        section = rest[:nxt.start()] if nxt else rest

        prose = {int(m.group(1)): m.group(2) for m in ITEM.finditer(section)}
        indexed = {i["number"]: i for i in items
                   if i["register"] == key and i["number"] is not None}

        missing = sorted(set(indexed) - set(prose))
        extra = sorted(set(prose) - set(indexed))
        check(f"open-items register {key}: the index and {doc_path} carry the same numbers",
              not missing and not extra,
              f"indexed but not in the section: {missing or 'none'} · "
              f"in the section but not indexed: {extra or 'none'}")

        # Status agreement. The registers mark a closed item in its bold lead-in
        # — "closed in 1.6", "closed in v0.5", "closed at v0.8" — which is the
        # convention each of them states about itself at the top of its section.
        # Matching the word rather than a phrasing is what keeps this from being
        # the kind of guard §16 had to be rewritten out of.
        disagree = []
        for number, lead in sorted(prose.items()):
            if number not in indexed:
                continue
            marked = bool(re.search(r"\bclosed\b", lead, re.IGNORECASE))
            if marked != (indexed[number]["status"] == "closed"):
                disagree.append(
                    f"item {number} reads {'closed' if marked else 'open'} in "
                    f"{doc_path} and {indexed[number]['status']} in the index")
        check(f"open-items register {key}: status agrees with {doc_path}",
              not disagree, "; ".join(disagree))

    # And the count in the front door, anchored the way §16 anchors every other
    # derived number. Restating it is free and each restatement is checked.
    #
    # The index describes itself in prose, and those self-descriptions are derived
    # values like any other. ADR 0025's `$attribution` said "six registers" — the
    # count from a draft that included two README lists the index deliberately
    # excludes — and it shipped, because §16 anchors the README and nothing looked
    # at the artifact's own sentences about itself. A file that counts things is
    # the last place a wrong count should survive.
    attribution = open_items.get("$attribution", "")
    OPEN_ITEM_ANCHORS = (
        (r"NUM open items across NUM registers", (n_open, len(registers)), readme),
        (r"null for NUM items of NUM, across NUM registers",
         (sum(1 for i in items if not i.get("opened_by")), len(items), len(registers)),
         attribution),
    )
    claims = 0
    wrong = []
    for pattern, expected, doc in OPEN_ITEM_ANCHORS:
        for m in re.finditer(pattern.replace("NUM", NUM), doc, re.IGNORECASE):
            vals = tuple(numeral(g) for g in m.groups())
            if any(v is None for v in vals):
                continue
            claims += 1
            if vals != expected:
                wrong.append(f"{' '.join(m.group(0).split())!r} "
                             f"— the index says {expected}")
    if claims < len(OPEN_ITEM_ANCHORS):
        fail("every anchored open-item count is still stated",
             f"{claims} of {len(OPEN_ITEM_ANCHORS)} anchors matched. State the "
             f"count, or fix the anchor in OPEN_ITEM_ANCHORS if the wording is "
             f"right and the pattern is not.")
    else:
        check(f"every open-item count agrees with the index in all {claims} "
              f"places it is stated", not wrong, "; ".join(wrong))



# ── 18. Relations between open items mean what they say ─────────────────────
#
# §17 made every item countable and stopped there. That was enough to catch an
# item outside its register and not enough to catch the three failures the first
# full read of the index turned up, all of them about items in *different*
# registers:
#
#   - `gate-config-2` and `spine-3` are the same question, near-verbatim, in the
#     enforcement layer and the design layer, neither citing the other.
#   - `spine-1` kept asking a question ADR 0021 settled and `build-dna-2` closed
#     on, for two releases after the closure.
#   - `gate-config-8` asks whether the untagged G2/G3 set is small.
#     `overlays/servicenow.md` §8 answers it — "this overlay's contribution is
#     the evidence: on this platform the set is not small" — and has since
#     overlay 1.1. Nothing carried it back. An item whose premise is resolved in
#     another document is worse than a duplicated one, because reading the item
#     honestly tells you nothing is known.
#
# None of those is a counting error, so §17 could not see any of them. They are
# errors about the edges between registers, and the fix is to make the edges
# exist and then enforce what each kind promises. A relation that is only stored
# is an annotation; the invariants below are what make it a guard.
#
# The asymmetry is deliberate. `duplicate_of` is mutual and enforced in both
# directions because half a duplicate is exactly what goes wrong. `superseded_by`
# and `upstream_of` are directional and fire when the *target* moves, because the
# failure they describe is the downstream item not noticing. And `answered_by`
# points at a document rather than an item, because the answer that went missing
# was a section of prose, not a register entry — a relation vocabulary that could
# only name items would not have been able to record the case it was built for.

if open_items is not None:
    ids = {i["id"] for i in open_items.get("items", [])}
    by_id = {i["id"]: i for i in open_items.get("items", [])}
    rel_types = set(open_items.get("relation_types", {}))
    blockers = set(open_items.get("blockers", {}))

    check("the relation vocabulary is declared",
          rel_types == {"duplicate_of", "superseded_by", "upstream_of",
                        "answered_by", "blocked_on"},
          f"relation_types declares {sorted(rel_types)}")

    check("the blockers vocabulary is non-empty and declared",
          bool(blockers), "blockers is missing or empty")

    # Targets resolve. A relation naming an item that does not exist is the
    # dangling pointer §17 already refuses for ADRs, one field over.
    dangling = sorted(
        (i["id"], field, target)
        for i in open_items["items"]
        for field in ("duplicate_of", "superseded_by")
        if i.get(field) for target in [i[field]] if target not in ids)
    dangling += sorted(
        (i["id"], "upstream_of", target)
        for i in open_items["items"]
        for target in i.get("upstream_of", []) if target not in ids)
    check("every relation names an item that exists", not dangling, f"{dangling}")

    # duplicate_of is mutual and status-locked. Closing one half of a duplicate
    # is the single most likely way for this vocabulary to rot.
    broken = []
    for i in open_items["items"]:
        target = i.get("duplicate_of")
        if not target or target not in by_id:
            continue
        other = by_id[target]
        if other.get("duplicate_of") != i["id"]:
            broken.append(f"{i['id']} says duplicate_of {target}, which does not say it back")
        elif other["status"] != i["status"]:
            broken.append(f"{i['id']} is {i['status']} and its duplicate {target} is "
                          f"{other['status']} — a duplicate closes on both sides or neither")
    check("duplicate_of is mutual and both halves carry the same status",
          not broken, "; ".join(broken))

    # superseded_by: when the thing that settled the question has closed, an item
    # still asking it describes a standard that no longer exists.
    stale = [f"{i['id']} is open and superseded by {i['superseded_by']}, which closed"
             for i in open_items["items"]
             if i.get("superseded_by") in by_id
             and i["status"] == "open"
             and by_id[i["superseded_by"]]["status"] == "closed"]
    check("no open item is superseded by an item that has closed",
          not stale, "; ".join(stale))

    # upstream_of: cross-register by definition, and the downstream item has to
    # move when the thing it was waiting on does.
    misdirected = [f"{i['id']} points upstream at {tgt}, in its own register"
                   for i in open_items["items"]
                   for tgt in i.get("upstream_of", [])
                   if tgt in by_id and by_id[tgt]["register"] == i["register"]]
    check("every upstream_of edge crosses registers",
          not misdirected,
          "; ".join(misdirected) + " — an item in the same register is a sibling, "
          "not an upstream" if misdirected else "")

    unread = [f"{i['id']} is open and waits on {tgt}, which closed"
              for i in open_items["items"] if i["status"] == "open"
              for tgt in i.get("upstream_of", [])
              if tgt in by_id and by_id[tgt]["status"] == "closed"]
    check("no open item is waiting on an upstream item that has closed",
          not unread,
          "; ".join(unread) + " — re-read it against the closure and close it or "
          "say what is left" if unread else "")

    # answered_by names a document and a heading, and both have to still be there.
    # This is the carry-back record; a stale pointer here is the failure it exists
    # to prevent, wearing the fix as a disguise.
    for i in open_items["items"]:
        a = i.get("answered_by")
        if not a:
            continue
        label = f"open-items {i['id']}: answered_by"
        for field in ("document", "section", "summary"):
            check(f"{label} states its {field}", bool(a.get(field)))
        doc_path = a.get("document", "")
        try:
            doc = read(doc_path)
        except OSError:
            fail(f"{label} names a document that exists", f"no such file: {doc_path}")
            continue
        heading = re.search(rf"^#+ {re.escape(a.get('section', ''))}\s*$",
                            doc, re.MULTILINE)
        check(f"{label} names a heading {doc_path} still carries",
              bool(heading),
              f"no heading {a.get('section')!r} — the section was renamed or "
              f"removed and the answer this item rests on moved with it")
        check(f"{label} points outside {i['register']}'s own document",
              doc_path != open_items["registers"][i["register"]]["document"],
              "an item answered by its own register's document is a note, "
              "not a carry-back")

    undeclared = sorted({(i["id"], k) for i in open_items["items"]
                         for k in i.get("blocked_on", []) if k not in blockers})
    check("every blocked_on key is declared in the blockers vocabulary",
          not undeclared, f"{undeclared}")

    dead_blockers = sorted(blockers - {k for i in open_items["items"]
                                       for k in i.get("blocked_on", [])})
    check("no declared blocker is unused",
          not dead_blockers,
          f"declared and cited by nothing: {dead_blockers} — a blocker no item "
          f"names is either a resolved one nobody removed or a key nobody applied")

    # A closed item keeps its relations — they are how it was closed — but it
    # cannot still be blocked on anything.
    still_blocked = sorted(i["id"] for i in open_items["items"]
                           if i["status"] == "closed" and i.get("blocked_on"))
    check("no closed item is still blocked on something",
          not still_blocked, f"{still_blocked}")



# ── 13. Release signing is wired consistently, or visibly not wired ─────────
#
# Three couplings that a reader cannot see and a test would not exercise until
# the day a release is signed, which is the worst day to discover any of them.

sign_sh = (ROOT / "tools" / "sign-release.sh").read_text()
verify_sh = (ROOT / "tools" / "verify-release.sh").read_text()

# (a) The two halves must agree on the signature namespace. `ssh-keygen -Y`
# binds a signature to its namespace, so a mismatch does not degrade to a weaker
# check — it fails every verification, and only ever in the consumer.
sign_ns = re.search(r'^NAMESPACE="([^"]+)"', sign_sh, re.MULTILINE)
verify_ns = re.search(r'^NAMESPACE="([^"]+)"', verify_sh, re.MULTILINE)
check("sign and verify agree on the signature namespace",
      bool(sign_ns) and bool(verify_ns) and sign_ns.group(1) == verify_ns.group(1),
      f"sign {sign_ns.group(1) if sign_ns else None!r} vs "
      f"verify {verify_ns.group(1) if verify_ns else None!r}")

# (b) The statement format tag verify-release.sh accepts must be the one
# sign-release.sh writes, and the fields it reads must be fields that get
# written. A verifier reading a field the signer never emits reads empty and,
# without this, would compare empty to empty and call it agreement.
emitted = set(re.findall(r'^\s*echo "([a-z]+)=\$', sign_sh, re.MULTILINE))
read_back = set(re.findall(r'field (\w+)', verify_sh))
check("verify-release.sh reads only fields sign-release.sh writes",
      read_back <= emitted, f"read but never written: {sorted(read_back - emitted)}")

sign_fmt = re.search(r'echo "(causeway-release-v\d+)"', sign_sh)
verify_fmt = re.search(r'\[ "\$FMT" != "(causeway-release-v\d+)" \]', verify_sh)
check("sign and verify agree on the statement format tag",
      bool(sign_fmt) and bool(verify_fmt) and sign_fmt.group(1) == verify_fmt.group(1),
      f"sign {sign_fmt.group(1) if sign_fmt else None!r} vs "
      f"verify {verify_fmt.group(1) if verify_fmt else None!r}")

# (c) check-drift.sh parses bundle/manifest.json with sed, because it is
# consumer-facing and must not require a JSON parser. That couples it to
# build-bundle.sh's output shape. Run the actual sed and compare it to what a
# real parser sees: a regex that silently matches nothing would make every
# provenance check in the consumer vacuous while reporting success.
drift_sh = (ROOT / "tools" / "check-drift.sh").read_text()
sed_expr = re.search(r"MAN_LINES=\"\$\(sed -n '([^']+)'", drift_sh)
if not sed_expr:
    fail("check-drift.sh manifest parser found", "the guard needs updating")
else:
    out = subprocess.run(["sed", "-n", sed_expr.group(1), str(ROOT / "bundle" / "manifest.json")],
                         capture_output=True, text=True)
    parsed = {tuple(l.split("  ", 1)[::-1]) for l in out.stdout.splitlines() if l.strip()}
    truth = {(f["path"], f["sha256"]) for f in manifest["files"]}
    check("check-drift.sh's sed parses the manifest exactly as a JSON parser does",
          parsed == truth,
          f"sed saw {len(parsed)}, json has {len(truth)}; "
          f"differences: {sorted(parsed ^ truth)[:3]}")

# (d) The trust anchor was issued at v1.8.0. Issued or not, it must be vendored
# AND digested together: an anchor a project can swap without moving the
# bundle digest is not an anchor. Half an activation is worse than none, because
# verify-release.sh would report a trusted signer from a file nothing protects.
# Read BUNDLE_FILES from build-bundle.sh, not from the manifest. The manifest
# is the *output* of that list, so a file added to BUNDLE_FILES but absent from
# disk never reaches it — build-bundle.sh exits first. Checking the manifest
# would therefore report the declaration as absent no matter what was declared,
# which is a check that could only ever pass. It was written that way, and the
# mutation test that adds the anchor to BUNDLE_FILES caught it.
build_sh = (ROOT / "tools" / "build-bundle.sh").read_text()
_bf = re.search(r"^BUNDLE_FILES=\((.*?)^\)", build_sh, re.MULTILINE | re.DOTALL)
_bf_body = "\n".join(
    line for line in (_bf.group(1).splitlines() if _bf else [])
    if not line.strip().startswith("#")
)
declared_bundle = set(re.findall(r'"([^"]+)"', _bf_body))
check("build-bundle.sh BUNDLE_FILES list is parseable", bool(declared_bundle))

anchor_path = ROOT / "bundle" / "allowed-signers"
bundle_has_anchor = "bundle/allowed-signers" in declared_bundle
# The append itself, not the path anywhere in the file. This read
# `"bundle/allowed-signers" in sync_sh`, which sync.sh also satisfies from its
# comment block and its `[ -f ... ]` test — so the check passed whatever the
# VENDORED append actually named, and could only ever pass. Caught by the
# mutation that points the append at a different file. Sixth time a check in
# this repository has been found reading characters instead of meaning.
vendor_has_anchor = bool(re.search(
    r'VENDORED\+=\(\s*"bundle/allowed-signers"\s*\)', sync_sh))
if anchor_path.is_file():
    check("the issued trust anchor is covered by the bundle digest", bundle_has_anchor,
          "bundle/allowed-signers exists but is not in BUNDLE_FILES — "
          "add it to tools/build-bundle.sh")
    check("the issued trust anchor is vendored to consumers", vendor_has_anchor,
          "bundle/allowed-signers exists but sync.sh never copies it")
else:
    check("signing is declared unissued rather than half-wired",
          not bundle_has_anchor,
          "BUNDLE_FILES names bundle/allowed-signers but no such file exists — "
          "build-bundle.sh will fail")


# (e) Prose about the signing state agrees with the signing state.
#
# (a) through (d) check that the *mechanism* is wired consistently. Nothing
# checked that the documents describing it were telling the truth, and for two
# releases they were not: v1.8.0 issued the key and signed a release while
# `tools/sync.sh` still explained that the anchor was appended conditionally
# "because it does not exist yet: no signing key has been issued, so no release
# is signed", and `gate/gate-configuration.md` open item 10 still listed the
# signature and the key among things "none of which exist".
#
# Both were true when written. Neither was reviewed when the fact under them
# moved, because nothing pointed from the fact to the sentence. The repository's
# own README carried it as credibility gap #2 — *the executable behavior is
# current; the narrative contract is not* — and asked for exactly this guard.
#
# Matching is windowed rather than literal, in the ADR 0020 sense: an "unissued"
# phrase counts only when signing vocabulary sits near it, so the patterns can
# stay short without firing on unrelated prose. It is a heuristic and it will
# miss a claim worded outside this set. That is the honest limit — it catches
# the shape that has actually recurred, and a guard that catches the recurrence
# is worth more than one that waits for a complete vocabulary.
#
# validate.py is deliberately not scanned: the patterns live here, so it would
# match its own literals. It is the standard's validator, not prose a consumer
# reads.

UNISSUED_CLAIM = re.compile(
    r"no signing key|not signed yet|no release is signed|"
    r"does not exist yet|is not issued yet|none of which exist|"
    r"no signature exists|no trust anchor exists",
    re.IGNORECASE)
SIGNING_VOCAB = re.compile(r"sign|signature|signed|signing|anchor", re.IGNORECASE)
SIGNING_PROSE = (
    ("tools/sync.sh", sync_sh),
    ("gate/gate-configuration.md", gate_config),
    ("README.md", readme),
    ("tools/build-bundle.sh", build_sh),
    ("tools/verify-release.sh", verify_sh),
)


def unissued_claims(doc: str) -> list[str]:
    """Phrases asserting signing is unissued, with signing vocabulary nearby."""
    found = []
    for m in UNISSUED_CLAIM.finditer(doc):
        if SIGNING_VOCAB.search(doc[max(0, m.start() - 240):m.end() + 240]):
            excerpt = doc[max(0, m.start() - 50):m.end() + 50]
            found.append(" ".join(excerpt.split()))
    return found


stale = [(name, c) for name, doc in SIGNING_PROSE for c in unissued_claims(doc)]
if anchor_path.is_file():
    check("no document claims signing is unissued while the trust anchor exists",
          not stale,
          "; ".join(f"{n}: …{c}…" for n, c in stale[:3])
          + " — bundle/allowed-signers was issued at v1.8.0")
else:
    # The other direction: with no anchor, a consumer must be told, and sync.sh
    # is where they find out because it is the script that would have copied it.
    #
    # Checked on sync.sh's own warning rather than by reusing unissued_claims().
    # That predicate answers "does this text assert signing is unissued", which
    # is the wrong question here and gave the wrong answer: the rewritten warning
    # names the missing file without using any phrase in UNISSUED_CLAIM, so the
    # check failed while sync.sh was doing exactly what it should. Caught by the
    # mutation that removes the anchor.
    check("sync.sh tells a consumer when there is no trust anchor to vendor",
          bool(re.search(r'echo\s+"[^"]*no bundle/allowed-signers', sync_sh)),
          "no bundle/allowed-signers, and sync.sh has no echo naming it")


# ── 19. The release archive carries everything sync.sh reads ────────────────
#
# tools/build-archive.sh ships an explicit allowlist, exactly as build-bundle.sh
# does, and for the reason bundle/scope.json gives: a file nothing enumerates is
# a file nothing governs. An allowlist has one failure mode, and it is this one —
# somebody adds a template to sync.sh, sync keeps working in every checkout
# anyone tests it in, and the archive quietly stops being able to install.
#
# What makes that failure expensive rather than annoying is where it surfaces.
# It cannot surface here, or in CI, or on any machine with a clone. It surfaces
# on a machine with no git, no credential and no network — the machine that
# chose the archive precisely because it cannot fetch the missing file. The
# whole point of ADR 0030 is that such a machine exists and is ordinary, so the
# guard belongs where the list is written, not where it is consumed.

archive_sh = (ROOT / "tools" / "build-archive.sh").read_text()

_af = re.search(r"^ARCHIVE_FILES=\((.*?)^\)", archive_sh, re.MULTILINE | re.DOTALL)
_af_body = "\n".join(
    line for line in (_af.group(1).splitlines() if _af else [])
    if not line.strip().startswith("#")
)
archive_files = set(re.findall(r'"([^"]+)"', _af_body))
check("build-archive.sh ARCHIVE_FILES list is parseable", bool(archive_files))

missing_from_disk = sorted(f for f in archive_files if not (ROOT / f).is_file())
check("every file the archive declares exists",
      not missing_from_disk, f"declared but absent: {missing_from_disk}")

# Overlays reach the archive through the same find(1) globs build-bundle.sh
# uses, so they are correct by construction and are excluded from the literal
# comparisons below rather than restated.
def _globbed(path: str) -> bool:
    return path.startswith("overlays/")

# The statement and its signature are appended only when the tree has been
# signed, so they cannot appear in the static list. They must still be named in
# the script — an archive that stopped carrying its own signature material would
# take --require-release down with it and nothing else here would notice.
for optional in ("bundle/release.statement", "bundle/release.statement.sig"):
    check(f"build-archive.sh still carries {optional} when it exists",
          optional in archive_sh,
          "the archive would ship unsigned and --require-release could not be met")

# (a) Everything sync.sh vendors. `vendored_files` is parsed in §10.
vendored_gap = sorted(f for f in vendored_files
                      if not _globbed(f) and "$" not in f and f not in archive_files)
check("the archive carries every file sync.sh vendors",
      not vendored_gap,
      f"vendored but not in ARCHIVE_FILES: {vendored_gap} — a sync from an "
      f"extracted archive would fail on a machine that cannot fetch them")

# (b) Everything else sync.sh reads out of the standard directory: the adapters,
# the seeded templates, VERSION and RELEASED. These never appear in VENDORED
# because sync writes them under different names or only when absent, which is
# exactly why a list built by reading VENDORED alone would have missed them.
read_paths = set()
for m in re.finditer(r'"\$STANDARD_DIR/([^"$]*)"', sync_sh):
    path = m.group(1)
    if path and not path.endswith("/"):
        read_paths.add(path)
check("sync.sh's reads of the standard directory are parseable", bool(read_paths))

optional_reads = {"bundle/release.statement", "bundle/release.statement.sig"}
read_gap = sorted(f for f in read_paths
                  if not _globbed(f) and f not in archive_files
                  and f not in optional_reads)
check("the archive carries every path sync.sh reads from the standard",
      not read_gap,
      f"read by sync.sh, absent from ARCHIVE_FILES: {read_gap}")

# (c) The archive has to contain the installer. Obvious, and obvious things that
# nothing checks are how tools/check-drift.sh spent five releases being named in
# sync.sh's closing advice and shipped to nobody.
check("the archive carries sync.sh itself",
      "tools/sync.sh" in archive_files,
      "an archive that cannot install itself is a directory")

# (d) And it must not carry this repository's own record. decisions/ holds
# Causeway's ADRs, not a consumer's; conformance/ is for engine authors. A
# consumer who extracted either would find a decisions/ directory already
# populated with somebody else's decisions, which is worse than finding none.
leaked = sorted(f for f in archive_files
                if f.startswith(("decisions/", "conformance/")))
check("the archive carries none of this repository's own decision record",
      not leaked, f"would ship to consumers as their own: {leaked}")


# ── 20. The decision register's README indexes every ADR ────────────────────
#
# decisions/README.md is hand-maintained, because its index groups ADRs by family
# and family is a judgment no frontmatter field carries (ADR 0041). A
# hand-maintained index has one failure mode and §8 has already described it:
# nothing counts it, so the next ADR lands in the directory and not on the page,
# and the page goes on looking complete. So the build counts it. What is bound
# here is structure — which numbers are on disk, which are linked, which are
# missing — and never a title or a family name, for the reason §16 gives.

decisions_readme_path = ROOT / "decisions" / "README.md"
check("decisions/README.md exists", decisions_readme_path.is_file())
decisions_readme = (decisions_readme_path.read_text(encoding="utf-8")
                    if decisions_readme_path.is_file() else "")

adr_on_disk = {p.name for p in (ROOT / "decisions").glob("[0-9]*.md")}
adr_linked = {m.removeprefix("./")
              for m in re.findall(r"\]\(((?:\./)?\d{4}-[^)\s]+\.md)\)", decisions_readme)}

unindexed = sorted(adr_on_disk - adr_linked)
check("every ADR is linked from decisions/README.md",
      not unindexed, f"on disk, not in the index: {unindexed}")

broken = sorted(adr_linked - adr_on_disk)
check("every ADR link in decisions/README.md resolves",
      not broken, f"linked, not on disk: {broken}")

# The unused-numbers promise. A skipped number is legitimate — two branches, one
# abandoned — and §8 forbids closing the gap by renumbering; what the README
# promises is that the gap is explained. There are none today, so this passes on
# nothing: green, not verified, in the sense §16 means.
if adr_numbers:
    gaps = sorted(set(range(1, max(adr_numbers) + 1)) - set(adr_numbers))
    unexplained = [f"{n:04d}" for n in gaps
                   if not re.search(rf"\b{n:04d}\b", decisions_readme)]
    check("every skipped ADR number is named in decisions/README.md",
          not unexplained, f"skipped and unexplained: {unexplained}")


# ── 21. A release is published only after everything before it passed ───────
#
# ADR 0044. The release workflow used `if: '!cancelled()'` on its archive steps,
# which runs a step after an earlier one failed, so an archive could be attached
# to a release whose signature had not verified. The workflow is the control and
# nothing executes it before a tag is pushed, so its shape is checked here: no
# step overrides the default success() condition except the withdrawal, all
# release changes go through tools/publish-release.sh, and the gates run in order
# before it.

release_yml = read(".github/workflows/release.yml")
release_steps = [l for l in release_yml.splitlines()
                 if not l.lstrip().startswith("#")]
release_body = "\n".join(release_steps)

overrides = [c.strip() for c in re.findall(r"^\s*if:\s*(.+?)\s*$", release_body, re.MULTILINE)
             if re.search(r"(cancelled|always|failure)\(\)", c)]
check("release.yml: no step runs after a failure except the withdrawal",
      overrides == ["failure() && steps.tag.outputs.tag != ''"],
      f"found step conditions {overrides}")
check("release.yml: every change to a release goes through publish-release.sh",
      not re.search(r"\bgh\s+release\s+(create|upload|edit|delete)", release_body),
      "a gh release call in the workflow bypasses publish-release.sh's preconditions")

gates = ["tools/validate.py", "tools/test-sync.sh", "tools/sign-release.sh",
         "tools/verify-release.sh", "tools/build-archive.sh --out dist",
         "tools/test-release-archive.sh --dist dist",
         "tools/publish-release.sh --tag \"$TAG\" --dist dist",
         "tools/publish-release.sh --tag \"$TAG\" --withdraw"]
positions = [release_body.find(g) for g in gates]
check("release.yml: every gate is present",
      all(p >= 0 for p in positions),
      f"missing: {[g for g, p in zip(gates, positions) if p < 0]}")
check("release.yml: the gates run in order, publishing after acceptance",
      all(p >= 0 for p in positions) and positions == sorted(positions),
      f"order found: {[g for _, g in sorted(zip(positions, gates))]}")


# ── 22. upgrade-starters.sh knows every starter sync.sh seeds ───────────────
#
# ADR 0046. The upgrader carries its own template:project-path list so it can
# run without parsing sync.sh. A starter added to sync.sh and not to the list
# would be seeded with a baseline and then never offered an upgrade, silently.

upgrade_sh = read("tools/upgrade-starters.sh")
seeded_pairs = set(re.findall(
    r'^plan_seed "\$STANDARD_DIR/([^"]+)" "([^"]+)"', sync_sh, re.MULTILINE))
upgrade_block = re.search(r"^STARTERS=\((.*?)^\)", upgrade_sh, re.MULTILINE | re.DOTALL)
upgrade_pairs = set(tuple(m.split(":", 1)) for m in
                    re.findall(r'"([^"]+:[^"]+)"', upgrade_block.group(1) if upgrade_block else ""))
check("sync.sh's seeded starters are parseable", bool(seeded_pairs))
check("upgrade-starters.sh offers an upgrade for exactly the starters sync.sh seeds",
      seeded_pairs == upgrade_pairs,
      f"seeded only: {sorted(seeded_pairs - upgrade_pairs)}; "
      f"upgrade only: {sorted(upgrade_pairs - seeded_pairs)}")
check("the archive carries upgrade-starters.sh",
      "tools/upgrade-starters.sh" in archive_files,
      "a release that cannot upgrade starters from its archive")


# The README advertises how many assertions this file makes. That number is the
# one piece of prose about the validator that the validator can verify exactly,
# and it went stale the first time a check was added.
#
# Anchored like every other count in §16, and for the same reason: this one was
# pinned to `**(\d+)** self-validation assertions` and went red when the README
# started saying "476 assertions" in a table instead. It cannot use PROSE_COUNTS
# itself, because `checked` is only final once every check above has run.
ASSERTION_ANCHORS = (r"NUM assertions",
                     r"completes NUM internal consistency checks")
assertion_claims = [
    m
    for pattern in ASSERTION_ANCHORS
    for m in re.finditer(pattern.replace("NUM", NUM), readme, re.IGNORECASE)
    if numeral(m.group(1)) is not None
]
if not assertion_claims:
    failures.append("README no longer states the self-validation assertion count\n"
                    f"      this run made {checked}")
elif failures:
    pass  # A failed check does not increment `checked`, so the count is only
          # meaningful on an otherwise-clean run. Reporting it alongside another
          # failure would be a second, misleading complaint about one problem.
else:
    stale = [" ".join(m.group(0).split()) for m in assertion_claims
             if numeral(m.group(1)) != checked]
    if stale:
        failures.append(
            f"README self-validation assertion count is stale\n"
            f"      this run made {checked}; README says {'; '.join(stale)}")


# ── Report ──────────────────────────────────────────────────────────────────

print(f"Causeway v{version} ({released}) · spine {profiles['spine_version']} · "
      f"gate config {gate_version}")
print(f"  {len(profile_ids)} checks · {len(unique_rows)} spine rows · "
      f"{len(manifest['files'])} bundle files")
print()

if failures:
    for f in failures:
        print(f"  FAIL  {f}")
    print()
    print(f"{len(failures)} failed · {checked} passed")
    sys.exit(1)

print(f"  {checked} checks passed — the standard ties to itself")
