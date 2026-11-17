#!/usr/bin/env python3
"""evaluate.py — Causeway's reference evaluator. A slice of the gate, not all of it.

    python3 tools/evaluate.py [project-dir] [--date YYYY-MM-DD] [--json] [--advisory]
    python3 tools/evaluate.py --coverage [project-dir]
    python3 tools/evaluate.py --conform [--standard DIR]

Reads the gate contract this copy of the standard ships (gate/checks.json,
gate/profiles.json, the Decision Spine) and evaluates a project against the checks
it implements:

    standard-currency  named-approvers  dependency-provenance  composition-state
    install-scripts    shortform-closure  oneway-closure  class-scoped-closure

The first five are the checks conformance/expectations.json pins, and --conform runs
every fixture there and fails on any difference. The three closure checks are the
ones that say how much of the spine a system has actually closed.

Every other check in gate/checks.json is reported `unsupported` wherever its
profile cell is not `skip`, never `pass`: a check this file cannot run has found
nothing, and saying so is the contract (gate-configuration.md §11). That is also
why a full run on a real project exits 4 — required checks it cannot execute.
Use --advisory in CI during a warn cycle; it prints the same report and exits 0.

What this is not: a conforming engine for the whole contract, an evidence store,
or a receipt signer. It writes no receipt. Build DNA open item 12 records what it
does not do yet, including the adoption-horizon arithmetic. ADR 0063.

Exit codes are the gate's (gate-configuration.md §8): 0 pass · 1 blocking check
failed · 2 expired waiver · 4 configuration error or a required check that could
not be executed. Precedence 4 > 3 > 2 > 1 > 0. --conform exits 0 when every
fixture matches and 1 otherwise.
"""
from __future__ import annotations

import json
import os
import re
import sys
from datetime import date
from pathlib import Path

IMPLEMENTED = (
    "standard-currency", "named-approvers", "dependency-provenance",
    "composition-state", "install-scripts",
    "shortform-closure", "oneway-closure", "class-scoped-closure",
)
SKIP_DIRS = {".git", "node_modules", "target", "vendor", ".venv", "venv",
             "__pycache__", ".causeway", "dist", "build"}


class ConfigError(Exception):
    """The run cannot be configured: gate exit 4."""


# ── The standard ─────────────────────────────────────────────────────────────

def load_standard(root: Path) -> dict:
    checks = json.loads((root / "gate/checks.json").read_text(encoding="utf-8"))
    profiles = json.loads((root / "gate/profiles.json").read_text(encoding="utf-8"))
    spine = (root / "skills/decision-spine/reference/spine.md").read_text(encoding="utf-8")
    tables = spine.split("## SA-1 · ", 1)
    tables = tables[1].split("## The one-way doors", 1)[0] if len(tables) > 1 else ""
    row_re = re.compile(
        r"^\|\s*(SA-\d+\.\d+)\s*(†)?\s*\|[^|]*\|[^|]*\|\s*([YN])\s*\|\s*(C1(?:[–-]C[23])?)\s*\|",
        re.MULTILINE)
    rows = {}
    for rid, dagger, one_way, applies in row_re.findall(tables):
        top = {"C1": 1, "C1–C2": 2, "C1-C2": 2, "C1–C3": 3, "C1-C3": 3}[applies]
        rows[rid] = {"one_way": one_way == "Y", "named": bool(dagger),
                     "short_form": top == 3, "applies_to": top}
    if not rows:
        raise ConfigError("the vendored Decision Spine has no row table this file can read")
    return {
        "checks": {c["id"]: c for c in checks["checks"]},
        "order": [c["id"] for c in checks["checks"]],
        "cells": {c["id"]: c for c in profiles["checks"]},
        "matrix": profiles["resolution"]["matrix"],
        "default_class": profiles["resolution"]["default_criticality_class"],
        "spine_version": profiles["spine_version"],
        "named_rows": profiles["named_approver_rows"],
        "rows": rows,
    }


# ── The project ──────────────────────────────────────────────────────────────

def parse_frontmatter(text: str) -> dict:
    """Enough YAML for ADR frontmatter: scalars, [lists], one level of nesting.

    Values stay strings, so adr: "0010" is never read as octal 8 — the bug the
    adr-identifier-boundary fixture exists for.
    """
    if not text.startswith("---\n"):
        raise ValueError("no frontmatter")
    end = text.find("\n---", 4)
    if end < 0:
        raise ValueError("unterminated frontmatter")
    out: dict = {}
    parent = None
    for raw in text[4:end].splitlines():
        line = re.sub(r"\s+#.*$", "", raw)
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        m = re.match(r"^\s*([A-Za-z_][\w-]*):\s*(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2).strip()
        target = out
        if indent and isinstance(out.get(parent), dict):
            target = out[parent]
        if val == "":
            if not indent:
                out[key] = {}
                parent = key
            else:
                target[key] = ""
            continue
        if not indent:
            parent = None
        if val.startswith("[") and val.endswith("]"):
            target[key] = [v.strip().strip('"\'') for v in val[1:-1].split(",") if v.strip()]
        else:
            target[key] = val.strip('"\'')
    return out


def read_adrs(project: Path) -> tuple[list[dict], list[str]]:
    adrs, unreadable = [], []
    d = project / "decisions"
    if not d.is_dir():
        return adrs, unreadable
    for p in sorted(d.glob("[0-9]*.md")):
        try:
            fm = parse_frontmatter(p.read_bytes().decode("utf-8"))
        except (UnicodeDecodeError, ValueError):
            unreadable.append(p.name)
            continue
        fm["_file"] = p.name
        rows = fm.get("spine_rows")
        fm["spine_rows"] = rows if isinstance(rows, list) else []
        adrs.append(fm)
    return adrs, unreadable


def read_system(project: Path) -> dict:
    p = project / "system.json"
    if not p.is_file():
        raise ConfigError("no system.json: the profile cannot be resolved")
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        raise ConfigError(f"system.json is not JSON: {e}")


def resolve_profile(std: dict, system: dict) -> tuple[str, str, str]:
    tier = system.get("tier")
    if tier not in std["matrix"]:
        raise ConfigError(f"system.json tier is {tier!r}; the profile cannot be derived")
    klass = system.get("criticality_class") or std["default_class"]
    if klass not in std["matrix"][tier]:
        raise ConfigError(f"system.json criticality_class is {klass!r}")
    return tier, klass, std["matrix"][tier][klass]


def walk(project: Path):
    for dirpath, dirnames, filenames in os.walk(project):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for f in filenames:
            yield Path(dirpath) / f


# ── Checks. Each returns (outcome, evidence); outcome is pass, fail, error,
#    not_applicable or unsupported, before the profile cell is applied. ────────

def check_standard_currency(ctx):
    lock = ctx["project"] / ".causeway-lock"
    if not lock.is_file():
        return "error", {"reason": "no .causeway-lock"}
    fields = dict(l.split("=", 1) for l in lock.read_text(encoding="utf-8").splitlines() if "=" in l)
    if "released" not in fields:
        raise ConfigError(".causeway-lock has no released= line; re-sync writes it")
    try:
        released = date.fromisoformat(fields["released"].strip())
    except ValueError:
        raise ConfigError(f".causeway-lock released= is not a date: {fields['released']!r}")
    threshold = ctx["std"]["checks"]["standard-currency"]["thresholds"]["finding_after_days"]
    age = (ctx["today"] - released).days
    ev = {"pinned_version": fields.get("version"), "released": released.isoformat(),
          "standard_age_days": age, "threshold_days": threshold}
    return ("fail" if age > threshold else "pass"), ev


def check_named_approvers(ctx):
    if ctx["unreadable"]:
        return "error", {"unreadable_adrs": ctx["unreadable"]}
    named = set(ctx["std"]["named_rows"])
    required, with_name, missing = set(), set(), set()
    for a in ctx["adrs"]:
        if a.get("status") != "Accepted":
            continue
        for r in named & set(a["spine_rows"]):
            required.add(r)
            ap = a.get("approver") if isinstance(a.get("approver"), dict) else {}
            if (ap.get("name") or "").strip() and (ap.get("role") or "").strip():
                with_name.add(r)
            else:
                missing.add(r)
    missing -= with_name
    ev = {"rows_required": sorted(required), "rows_with_approver": sorted(with_name),
          "missing_rows": sorted(missing)}
    return ("fail" if missing else "pass"), ev


FLOATING = re.compile(r"^\s*(?:[\^~*xX><]|latest$|next$|.*\|\||.*\s-\s|.*\.x\b|.*\.\*)")


def check_dependency_provenance(ctx):
    found, without_lock, no_integrity, floating, unsupported = set(), [], [], [], []
    project = ctx["project"]
    for f in walk(project):
        rel = f.relative_to(project).as_posix()
        here = f.parent
        if f.name == "package.json":
            try:
                pkg = json.loads(f.read_text(encoding="utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                return "error", {"unreadable_manifest": rel}
            deps = {}
            for k in ("dependencies", "devDependencies", "optionalDependencies"):
                deps.update(pkg.get(k) or {})
            if not deps:
                continue
            found.add("npm")
            lock = next((here / n for n in ("package-lock.json", "npm-shrinkwrap.json",
                                            "yarn.lock", "pnpm-lock.yaml") if (here / n).is_file()), None)
            if lock is None:
                without_lock.append(rel)
                floating += [f"{n}@{v}" for n, v in sorted(deps.items()) if FLOATING.match(str(v))]
            elif lock.name in ("package-lock.json", "npm-shrinkwrap.json"):
                data = json.loads(lock.read_text(encoding="utf-8"))
                for name, entry in (data.get("packages") or {}).items():
                    if name and entry.get("resolved") and not entry.get("integrity"):
                        no_integrity.append(f"{lock.relative_to(project).as_posix()}:{name}")
        elif f.name == "Cargo.toml":
            found.add("cargo")
            if not any((p / "Cargo.lock").is_file() for p in [here, *here.parents] if project in [p, *p.parents]):
                without_lock.append(rel)
        elif f.name == "go.mod":
            found.add("go")
            if not (here / "go.sum").is_file():
                without_lock.append(rel)
        elif f.name in ("pyproject.toml", "requirements.txt"):
            found.add("pypi")
            if not any((here / n).is_file() for n in ("uv.lock", "poetry.lock", "pdm.lock", "Pipfile.lock")) \
               and not (f.name == "requirements.txt" and "--hash=" in f.read_text(encoding="utf-8", errors="replace")):
                without_lock.append(rel)
        elif f.name in ("pom.xml", "build.gradle", "build.gradle.kts") or f.suffix == ".csproj":
            unsupported.append(rel)
    ev = {"ecosystems_found": sorted(found), "manifests_without_lock": sorted(without_lock),
          "entries_without_integrity": sorted(no_integrity), "floating_ranges": sorted(floating)}
    if unsupported:
        ev["manifests_not_read"] = sorted(unsupported)
    if without_lock or no_integrity or floating:
        return "fail", ev
    if unsupported:
        return "unsupported", ev
    return ("pass" if found else "not_applicable"), ev


BOOTSTRAP = re.compile(r"(curl|wget)\b[^|\n]*\|\s*(sudo\s+)?(ba|z|da)?sh\b")
NPM_INSTALL = re.compile(r"\b(npm\s+(ci|install|i)\b|yarn(\s+install)?\s*$|yarn\s+install\b|pnpm\s+(install|i)\b)")


def check_install_scripts(ctx):
    project = ctx["project"]
    ecosystems, config_v, invoke_v, bootstrap, unsupported = set(), [], [], [], []
    npm_dirs = []
    for f in walk(project):
        if f.name == "package.json":
            ecosystems.add("npm")
            npm_dirs.append(f.parent)
        elif f.name in ("pyproject.toml", "requirements.txt", "setup.py"):
            unsupported.append("pypi")
        elif f.name == "Cargo.toml":
            unsupported.append("cargo")
    steps = []
    wf = project / ".github" / "workflows"
    if wf.is_dir():
        steps += sorted(p for p in wf.iterdir() if p.suffix in (".yml", ".yaml"))
    for extra in ("Makefile", "Dockerfile"):
        if (project / extra).is_file():
            steps.append(project / extra)
    for s in steps:
        text = s.read_text(encoding="utf-8", errors="replace")
        rel = s.relative_to(project).as_posix()
        if BOOTSTRAP.search(text):
            bootstrap.append(rel)
        if "npm" in ecosystems:
            for line in text.splitlines():
                if NPM_INSTALL.search(line) and "--ignore-scripts" not in line:
                    invoke_v.append(rel)
                    break
    # ignore-scripts=true in a committed .npmrc beside the package, or above it.
    for d in npm_dirs:
        chain = [d, *(p for p in d.parents if project in (p, *p.parents))]
        if not any(re.search(r"^\s*ignore-scripts\s*=\s*true\s*$",
                             (c / ".npmrc").read_text(encoding="utf-8", errors="replace"), re.MULTILINE)
                   for c in chain if (c / ".npmrc").is_file()):
            config_v.append((d / ".npmrc").relative_to(project).as_posix())
    ev = {"ecosystems_found": sorted(ecosystems | set(unsupported)),
          "config_violations": sorted(config_v), "invocation_violations": sorted(set(invoke_v)),
          "unverified_bootstrap_sites": sorted(set(bootstrap))}
    if unsupported:
        ev["ecosystems_not_read"] = sorted(set(unsupported))
    if config_v or invoke_v or bootstrap:
        return "fail", ev
    if unsupported:
        return "unsupported", ev
    return ("pass" if ecosystems else "not_applicable"), ev


def check_composition_state(ctx):
    valid = ctx["std"]["checks"]["composition-state"]["valid_values"]
    declared = ctx["system"].get("composition-state", ctx["system"].get("composition_state"))
    ev = {"declared_state": declared, "valid_values": valid}
    return ("pass" if declared in valid else "fail"), ev


def closure(ctx, selector):
    std, system = ctx["std"], ctx["system"]
    closed_against = (system.get("spine") or {}).get("closed_against")
    if ctx["unreadable"]:
        return "error", {"unreadable_adrs": ctx["unreadable"]}
    in_scope = sorted(r for r, meta in std["rows"].items() if selector(meta))
    closed, waived, expired = set(), set(), set()
    for a in ctx["adrs"]:
        rows = set(a["spine_rows"])
        if a.get("status") == "Accepted":
            closed |= rows
        elif a.get("status") == "Waived":
            w = a.get("waiver") if isinstance(a.get("waiver"), dict) else {}
            try:
                live = date.fromisoformat(str(w.get("expires", ""))) >= ctx["today"]
            except ValueError:
                live = False
            (waived if live else expired).update(rows)
    open_rows = [r for r in in_scope if r not in closed and r not in waived]
    ev = {"criticality_class": ctx["klass"], "rows_in_scope": len(in_scope),
          "rows_closed": sum(1 for r in in_scope if r in closed),
          "rows_waived": sorted(r for r in in_scope if r in waived and r not in closed),
          "rows_in_adoption": [], "open_rows": open_rows}
    if closed_against and closed_against != std["spine_version"]:
        ev["reason"] = (f"system.json closes against spine {closed_against}, the vendored spine is "
                        f"{std['spine_version']}: the adoption-horizon arithmetic is not implemented "
                        "here (Build DNA open item 12)")
        return "unsupported", ev
    if any(r in expired for r in open_rows):
        ev["expired_waivers"] = sorted(r for r in open_rows if r in expired)
    if open_rows:
        return "fail", ev
    return ("waived" if ev["rows_waived"] else "pass"), ev


CHECKS = {
    "standard-currency": check_standard_currency,
    "named-approvers": check_named_approvers,
    "dependency-provenance": check_dependency_provenance,
    "composition-state": check_composition_state,
    "install-scripts": check_install_scripts,
    "shortform-closure": lambda c: closure(c, lambda m: m["short_form"]),
    "oneway-closure": lambda c: closure(c, lambda m: m["one_way"]),
    "class-scoped-closure": lambda c: closure(
        c, lambda m: m["applies_to"] >= {"C1": 1, "C2": 2, "C3": 3}[c["klass"]]),
}


# ── Verdicts and exit codes ──────────────────────────────────────────────────

def verdict(outcome: str, cell: str) -> tuple[str, bool]:
    """Apply the profile cell. Returns (verdict, blocks)."""
    if cell == "skip":
        return "not_run", False
    blocking = cell == "block"
    if outcome == "fail":
        return ("fail", True) if blocking else ("advisory", False)
    if outcome in ("error", "unsupported"):
        return outcome, blocking
    return outcome, False


def evaluate(project: Path, std: dict, today: date, scope=None) -> dict:
    report = {"project": str(project), "evaluated_at": today.isoformat(),
              "engine": "causeway-reference-evaluator", "partial": True, "checks": {}}
    codes = []
    try:
        system = read_system(project)
        tier, klass, profile = resolve_profile(std, system)
    except ConfigError as e:
        report.update(error=str(e), exit_code=4)
        return report
    adrs, unreadable = read_adrs(project)
    ctx = {"project": project, "std": std, "today": today, "system": system,
           "klass": klass, "adrs": adrs, "unreadable": unreadable}
    report.update(tier=tier, criticality_class=klass, profile=profile)
    for cid in (scope or std["order"]):
        cell = std["cells"].get(cid, {}).get(profile, "skip")
        spec = std["checks"][cid]
        if cid in CHECKS:
            try:
                outcome, ev = CHECKS[cid](ctx)
            except ConfigError as e:
                report["checks"][cid] = {"verdict": "error", "evidence": {"reason": str(e)}}
                codes.append(4)
                continue
            except Exception as e:  # a check that crashed found nothing
                outcome, ev = "error", {"reason": f"{type(e).__name__}: {e}"}
        else:
            outcome, ev = "unsupported", {"reason": "not implemented by the reference evaluator"}
        v, blocks = verdict(outcome, cell)
        report["checks"][cid] = {"verdict": v, "cell": cell, "evidence": ev}
        if blocks:
            codes.append(4 if v == "unsupported" else spec.get("exit_code", 1))
        if v == "fail" and ev.get("expired_waivers"):
            codes.append(2)
    report["exit_code"] = next((c for c in (4, 3, 2, 1) if c in codes), 0)
    return report


# ── Output ───────────────────────────────────────────────────────────────────

def coverage(report: dict, std: dict) -> list[str]:
    out = []
    for cid in ("shortform-closure", "oneway-closure", "class-scoped-closure"):
        c = report["checks"].get(cid)
        if not c:
            continue
        ev = c["evidence"]
        if "rows_in_scope" in ev:
            out.append(f"  {cid:22s} {ev['rows_closed']}/{ev['rows_in_scope']} closed"
                       f"{', ' + str(len(ev['rows_waived'])) + ' waived' if ev['rows_waived'] else ''}"
                       f" · {len(ev['open_rows'])} open  [{c['verdict']}]")
    return out


def human(report: dict, std: dict) -> str:
    if "error" in report:
        return f"configuration error: {report['error']}\nexit 4"
    lines = [f"Causeway reference evaluator — {report['project']}",
             f"  {report['tier']} · {report['criticality_class']} → {report['profile']}"
             f" · evaluated as of {report['evaluated_at']}", ""]
    ran = [c for c in report["checks"] if c in CHECKS]
    lines.append(f"  Implemented here ({len(ran)} of {len(std['order'])} checks):")
    for cid in ran:
        c = report["checks"][cid]
        note = ""
        ev = c["evidence"]
        for k in ("missing_rows", "manifests_without_lock", "floating_ranges",
                  "unverified_bootstrap_sites", "config_violations", "invocation_violations"):
            if ev.get(k):
                note += f"  {k}: {', '.join(ev[k])}"
        if "standard_age_days" in ev:
            note += f"  age {ev['standard_age_days']} days"
        if "rows_in_scope" in ev:
            note += f"  {ev['rows_closed']}/{ev['rows_in_scope']} rows closed"
        if ev.get("reason"):
            note += f"  ({ev['reason']})"
        lines.append(f"    {c['verdict']:15s} {cid}{note}")
    rest = [c for c in report["checks"] if c not in CHECKS]
    if rest:
        uns = [c for c in rest if report["checks"][c]["verdict"] == "unsupported"]
        lines += ["", f"  Not implemented here: {len(uns)} reported unsupported, "
                      f"{len(rest) - len(uns)} not run at {report['profile']}."]
    lines += ["", "  This is a partial evaluation. Unsupported is not pass. ADR 0063.",
              f"  exit {report['exit_code']}"]
    return "\n".join(lines)


def conform(std_root: Path) -> int:
    std = load_standard(std_root)
    exp = json.loads((std_root / "conformance/expectations.json").read_text(encoding="utf-8"))
    today = date.fromisoformat(exp["evaluated_at"])
    scope = exp["scope"]["checks"]
    failures = 0
    for fx in exp["fixtures"]:
        rep = evaluate(std_root / "conformance/fixtures" / fx["id"], std, today, scope)
        want, problems = fx["expect"], []
        if rep.get("exit_code") != want["exit_code"]:
            problems.append(f"exit {rep.get('exit_code')}, expected {want['exit_code']}")
        for cid, v in want["checks"].items():
            got = rep["checks"].get(cid, {}).get("verdict")
            if got != v:
                problems.append(f"{cid} {got}, expected {v}")
        for cid, keys in want.get("evidence", {}).items():
            ev = rep["checks"].get(cid, {}).get("evidence", {})
            for k, v in keys.items():
                if ev.get(k) != v:
                    problems.append(f"{cid}.{k} = {ev.get(k)!r}, expected {v!r}")
        for cid, banned in (fx.get("expect", {}).get("must_not") or {}).items():
            if cid.startswith("$"):
                continue
            if rep["checks"].get(cid, {}).get("verdict") in banned:
                problems.append(f"{cid} reported a prohibited verdict")
        res = (fx.get("resolves") or {}).get("profile")
        if res and rep.get("profile") != res:
            problems.append(f"profile {rep.get('profile')}, expected {res}")
        print(f"  {'ok  ' if not problems else 'FAIL'}  {fx['id']}" +
              ("".join(f"\n          {p}" for p in problems)))
        failures += bool(problems)
    print(f"\n  {len(exp['fixtures']) - failures} of {len(exp['fixtures'])} fixtures match "
          f"conformance/expectations.json over {len(scope)} checks")
    return 1 if failures else 0


def main(argv: list[str]) -> int:
    args, opts = [], {}
    it = iter(argv)
    for a in it:
        if a in ("--json", "--advisory", "--coverage", "--conform"):
            opts[a] = True
        elif a in ("--date", "--standard"):
            opts[a] = next(it, None)
        elif a in ("-h", "--help"):
            print(__doc__)
            return 0
        else:
            args.append(a)
    here = Path(__file__).resolve().parent.parent
    std_root = Path(opts.get("--standard") or here)
    if opts.get("--conform"):
        return conform(std_root)
    project = Path(args[0] if args else ".").resolve()
    if not opts.get("--standard") and (project / "gate/checks.json").is_file():
        std_root = project
    try:
        std = load_standard(std_root)
    except (OSError, json.JSONDecodeError, ConfigError) as e:
        print(f"cannot read the gate contract under {std_root}: {e}", file=sys.stderr)
        return 4
    today = date.fromisoformat(opts["--date"]) if opts.get("--date") else date.today()
    report = evaluate(project, std, today)
    if opts.get("--json"):
        print(json.dumps(report, indent=2))
    elif opts.get("--coverage"):
        if "error" in report:
            print(f"configuration error: {report['error']}")
        else:
            print(f"Spine coverage — {report['tier']} · {report['criticality_class']} → {report['profile']}")
            print("\n".join(coverage(report, std)))
    else:
        print(human(report, std))
    if opts.get("--advisory") or opts.get("--coverage"):
        return 0
    return report.get("exit_code", 4)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
