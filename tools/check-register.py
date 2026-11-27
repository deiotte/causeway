#!/usr/bin/env python3
"""check-register.py — does this project's decision record hold together?

    python3 tools/check-register.py [project-dir] [--json] [--strict] [--standard DIR]

Reads `decisions/` and `decisions/open-items.json` in a project that adopted
Causeway and reports what does not tie: an ADR the gate cannot parse, a row ID
the vendored spine does not have, a supersession or correction that points one
way only, an open item that names an ADR nobody wrote, a count nobody
recomputed. Each of those closes nothing while looking as if it did.

Two levels, and the difference is the point:

  violation  the record says something false, or something the gate cannot read.
             Exit 1.
  warning    the record is legal and probably not what you meant: two live ADRs
             on one row (other than a correction and the record it corrects),
             a skipped number with no line under *Unused numbers* (singly or in a
             range such as "0001 to 0008"),
             an ADR missing from the index, the template's example still in the
             open-items index. Exit 0, unless --strict.

It is warn-only by default in the way the evaluator is (ADR 0063): `doctor.sh`
reports its result and never fails on it, and a project chooses when to make it
blocking by running it with no flags in CI. It is not a gate check and has no
number in gate/checks.json; Build DNA open item 6 records what would earn one.

What this deliberately does not check:

  - Named approvers on the eight dagger rows. evaluate.py does (named-approvers),
    and a second implementation here would be a second answer to one question.
  - Whether a waiver has expired. That is the gate's waiver-expiry check.
  - Whether an ADR's argument is any good. No parser can tell, and one that
    pretended to would teach people to write for the parser.
  - Whether the prose of a register states the same count as the index. A
    project chooses how its register documents are written; this checks that the
    document and the heading the index names still exist.

Offline, standard library only, and reads nothing outside the project and the
standard. ADR 0067.
"""
from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path

STATUSES = ("Proposed", "Accepted", "Deferred", "Waived", "Deprecated", "Superseded")
LIVE = {"Accepted", "Waived"}            # the statuses that close or hold a row
REQUIRED = ("adr", "title", "status", "date", "spine_rows")
CAUSES = {"S1", "S2", "S3", "S4", "S5"}  # Build DNA 8.4


def load_evaluator(standard: Path):
    """The frontmatter parser and the spine reader are evaluate.py's.

    Imported by path rather than by name, because doctor.sh runs Python with -I
    and an isolated interpreter does not put the script's directory on sys.path.
    One parser for one format: if this file and the evaluator ever read the same
    ADR differently, the register check would pass a record the gate rejects.
    """
    path = standard / "tools" / "evaluate.py"
    sys.dont_write_bytecode = True     # never leave a __pycache__ in the project
    spec = importlib.util.spec_from_file_location("causeway_evaluate", path)
    if spec is None or spec.loader is None:
        raise FileNotFoundError(path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class Report:
    def __init__(self):
        self.violations: list[dict] = []
        self.warnings: list[dict] = []

    def violation(self, where: str, msg: str):
        self.violations.append({"where": where, "message": msg})

    def warning(self, where: str, msg: str):
        self.warnings.append({"where": where, "message": msg})


def as_list(v) -> list[str]:
    if v is None or v == "" or v == {}:
        return []          # evaluate.py reads a bare `key:` as an empty mapping
    if isinstance(v, list):
        return [str(x) for x in v if str(x).strip()]
    return [str(v)]


def heading_present(doc: Path, heading: str) -> bool:
    return bool(re.search(rf"^#+\s+{re.escape(heading)}\s*$",
                          doc.read_text(encoding="utf-8", errors="replace"), re.MULTILINE))


# A range is how people write a run of skipped numbers: "0001 to 0008",
# "0001–0008", "0001-0008", "0001 through 0008". Both ends are four digits, so a
# date or a count in the same sentence is not mistaken for one.
RANGE = re.compile(r"(?<!\d)(\d{4})\s*(?:to|through|thru|–|—|-|\.\.)\s*(\d{4})(?!\d)")
NUMBER = re.compile(r"(?<!\d)(\d{4})(?!\d)")


def unused_numbers(readme_text: str) -> set[int]:
    """Every ADR number listed under *Unused numbers*, singly or as a range."""
    m = re.search(r"^#+\s+Unused numbers\s*$(.*?)(?=^#+\s|\Z)", readme_text, re.MULTILINE | re.DOTALL)
    if not m:
        return set()
    text = m.group(1)
    found: set[int] = set()
    for a, b in RANGE.findall(text):
        lo, hi = sorted((int(a), int(b)))
        if hi - lo <= 1000:              # a typo should not list the whole register
            found.update(range(lo, hi + 1))
    found.update(int(n) for n in NUMBER.findall(text))
    return found


# ── The ADRs ─────────────────────────────────────────────────────────────────

def check_adrs(project: Path, ev, rows: dict, rep: Report) -> dict:
    dec = project / "decisions"
    adrs: dict[str, tuple[str, dict]] = {}
    for p in sorted(dec.glob("[0-9]*.md")):
        try:
            fm = ev.parse_frontmatter(p.read_bytes().decode("utf-8"))
        except UnicodeDecodeError:
            rep.violation(p.name, "not UTF-8 — the gate cannot read it, so it closes nothing")
            continue
        except ValueError as e:
            rep.violation(p.name, f"{e} — the gate reads frontmatter, not prose, so this closes nothing")
            continue
        for k in REQUIRED:
            if k not in fm:
                rep.violation(p.name, f"frontmatter has no `{k}`")
        num = str(fm.get("adr") or "")
        prefix = p.name.split("-", 1)[0]
        if not re.fullmatch(r"\d{4}", num):
            rep.violation(p.name, f"adr is {fm.get('adr')!r}; it should be the quoted four-digit "
                                  f"number, adr: \"{prefix}\" (unquoted, YAML reads 0010 as 8)")
            num = prefix
        elif num != prefix:
            rep.violation(p.name, f"adr is \"{num}\" but the filename says {prefix}")
        status = fm.get("status")
        if status not in STATUSES:
            rep.violation(p.name, f"status {status!r} is not one of {', '.join(STATUSES)}")
        if "spine_rows" in fm and not isinstance(fm.get("spine_rows"), list):
            rep.violation(p.name, "spine_rows must be a [list], even when it is empty")
        if num in adrs:
            rep.violation(p.name, f"ADR {num} is also {adrs[num][0]} — a number is an identity")
            continue
        adrs[num] = (p.name, fm)

    def corrects_pair(a: str, b: str) -> bool:
        """A correction restates the record it corrects, rows and all, and both
        stay live (Build DNA 8.4). That is one decision written twice on purpose,
        not two decisions on one row."""
        fa, fb = adrs[a][1], adrs[b][1]
        return (b in as_list(fa.get("corrects")) or b in as_list(fa.get("corrected_by"))
                or a in as_list(fb.get("corrects")) or a in as_list(fb.get("corrected_by")))

    claimed: dict[str, str] = {}
    for num, (name, fm) in sorted(adrs.items()):
        for r in as_list(fm.get("spine_rows")) if isinstance(fm.get("spine_rows"), list) else []:
            if r not in rows:
                rep.violation(name, f"{r} is not a row in the vendored spine — an invented row "
                                    "ID is worse than none, because everything downstream trusts it")
            elif fm.get("status") in LIVE:
                if r in claimed and corrects_pair(num, claimed[r]):
                    pass
                elif r in claimed:
                    rep.warning(name, f"{r} is also closed by ADR {claimed[r]}. Legal, and usually "
                                      "a supersession that was never written down")
                else:
                    claimed[r] = num

    for num, (name, fm) in sorted(adrs.items()):
        mine = as_list(fm.get("spine_rows")) if isinstance(fm.get("spine_rows"), list) else []
        # Supersession is mutual, and the earlier record says so in its status.
        sup = as_list(fm.get("supersedes"))
        for s in sup:
            if s not in adrs:
                rep.violation(name, f"supersedes {s}, which is not in decisions/")
                continue
            old_name, old = adrs[s]
            if num not in as_list(old.get("superseded_by")):
                rep.violation(name, f"supersedes {s}, but {old_name} does not name {num} in superseded_by")
            if fm.get("status") in LIVE:
                lost = set(as_list(old.get("spine_rows"))) - set(mine)
                lost -= set(claimed)          # re-closed by some other live ADR
                if lost:
                    rep.violation(name, f"supersedes {s} and drops its rows {sorted(lost)} — re-close "
                                        "them here or in another ADR, or they went open without a record")
        if sup and (str(fm.get("supersession_cause") or "").split() or [""])[0] not in CAUSES:
            hint = (" It carries `cause`; the field the standard reads is `supersession_cause`."
                    if fm.get("cause") else "")
            rep.violation(name, f"supersedes {', '.join(sup)} with supersession_cause "
                                f"{fm.get('supersession_cause') or 'empty'}; it must be one of S1–S5, "
                                f"stated when the ADR is written (Build DNA 8.4).{hint}")
        for s in as_list(fm.get("superseded_by")):
            if s not in adrs:
                rep.violation(name, f"superseded_by {s}, which is not in decisions/")
            elif num not in as_list(adrs[s][1].get("supersedes")):
                rep.violation(name, f"superseded_by {s}, but ADR {s} does not say it supersedes {num}")
            if fm.get("status") != "Superseded":
                rep.violation(name, f"superseded_by {s} but status is {fm.get('status')!r}, not Superseded")
        if fm.get("status") == "Superseded" and not as_list(fm.get("superseded_by")):
            rep.violation(name, "status is Superseded but superseded_by names nothing — a reader "
                                "cannot reach whatever replaced it")

        # Corrections are mutual too (Build DNA 8.4): the build checks both directions.
        for field, mirror in (("corrects", "corrected_by"), ("corrected_by", "corrects")):
            for ref in as_list(fm.get(field)):
                if ref not in adrs:
                    rep.violation(name, f"{field} names ADR {ref}, which is not in decisions/")
                elif num not in as_list(adrs[ref][1].get(mirror)):
                    rep.violation(name, f"{field} {ref}, but ADR {ref} does not list {num} in {mirror}")

    # A skipped number is allowed and stays skipped, with a line saying why.
    readme = dec / "README.md"
    readme_text = readme.read_text(encoding="utf-8", errors="replace") if readme.is_file() else ""
    unused = unused_numbers(readme_text)
    if adrs:
        nums = sorted(int(n) for n in adrs)
        for gap in sorted(set(range(1, nums[-1] + 1)) - set(nums)):
            if gap not in unused:
                rep.warning("decisions/", f"{gap:04d} is skipped and decisions/README.md does not list "
                                          "it under Unused numbers — the next reader goes looking for it")
    if not readme.is_file():
        rep.warning("decisions/README.md", "missing — sync.sh seeds it; the index is how a decision "
                                           "is found from the front")
    else:
        for num, (name, _) in sorted(adrs.items()):
            if name not in readme_text:
                rep.warning("decisions/README.md", f"has no row linking {name}")
    return adrs


# ── The open-items index ─────────────────────────────────────────────────────

def check_open_items(project: Path, adrs: dict, rep: Report) -> dict | None:
    path = project / "decisions" / "open-items.json"
    at = "decisions/open-items.json"
    if not path.is_file():
        rep.warning(at, "missing — sync.sh seeds it, and an ADR that opens an item has nowhere to say so")
        return None
    try:
        idx = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        rep.violation(at, f"not JSON: {e}")
        return None

    registers = idx.get("registers") or {}
    if not isinstance(registers, dict):
        rep.violation(at, "registers must be an object keyed by register name")
        registers = {}
    items = idx.get("items") or []
    blockers = idx.get("blockers") or {}
    if "REPLACE" in json.dumps({"r": registers, "i": items, "b": blockers}):
        rep.warning(at, "still carries the template's REPLACE example — name your registers and "
                        "drop the example item")

    for key, reg in sorted(registers.items()):
        doc = project / str(reg.get("document") or "")
        if not reg.get("document") or not doc.is_file():
            rep.violation(at, f"register {key!r} names {reg.get('document')!r}, which does not exist")
        elif reg.get("section") and not heading_present(doc, reg["section"]):
            rep.violation(at, f"register {key!r} names the heading {reg['section']!r}, which "
                              f"{reg['document']} no longer has")

    by_id: dict[str, dict] = {}
    numbers: dict[tuple, str] = {}
    for it in items:
        iid = str(it.get("id"))
        tag = f"{at} {iid}"
        if iid in by_id:
            rep.violation(tag, "duplicate id — ids are never reused")
        by_id[iid] = it
        if it.get("register") not in registers:
            rep.violation(tag, f"register {it.get('register')!r} is not declared under registers")
        if it.get("number") is not None:
            k = (it.get("register"), it.get("number"))
            if k in numbers:
                rep.violation(tag, f"number {it['number']} is also {numbers[k]} in the same register")
            numbers[k] = iid
        st = it.get("status")
        if st not in ("open", "closed"):
            rep.violation(tag, f"status {st!r} — there is no half-closed, only open or closed")
        for role in ("opened_by", "closed_by"):
            ref = it.get(role)
            if ref and str(ref) not in adrs:
                rep.violation(tag, f"{role} names ADR {ref}, which is not in decisions/")
        if st == "open" and it.get("closed_by"):
            rep.violation(tag, "open, but already names the ADR that closed it")
        lapsed = it.get("lapsed")
        if lapsed is not None and not (isinstance(lapsed, str) and lapsed.strip()):
            rep.violation(tag, "lapsed must say why, in a sentence — an empty lapse is the silence "
                               "it exists to replace")
        elif lapsed and st != "closed":
            rep.violation(tag, f"says it lapsed but is {st} — a lapsed item is closed, by nothing")
        elif lapsed and it.get("closed_by"):
            rep.violation(tag, f"says it lapsed and names ADR {it['closed_by']} as closing it — it "
                               "closed or it lapsed, not both")
        if st == "closed" and not it.get("closed_by") and not it.get("answered_by") and not lapsed:
            rep.violation(tag, "closed by nothing — name the closing ADR in closed_by, the document "
                               "that answered it in answered_by, or say why it lapsed in lapsed; an "
                               "item closed by nothing lapsed rather than closed")
        ans = it.get("answered_by")
        if isinstance(ans, dict):
            doc = project / str(ans.get("document") or "")
            if not doc.is_file():
                rep.violation(tag, f"answered_by names {ans.get('document')!r}, which does not exist")
            elif ans.get("section") and not heading_present(doc, ans["section"]):
                rep.violation(tag, f"answered_by names the heading {ans['section']!r}, which "
                                   f"{ans['document']} no longer has")
        for b in as_list(it.get("blocked_on")):
            if b not in blockers:
                rep.violation(tag, f"blocked_on {b!r}, which blockers does not declare")

    # The relations promise things a count cannot see (Build DNA §8).
    for iid, it in sorted(by_id.items()):
        tag = f"{at} {iid}"
        dup = it.get("duplicate_of")
        if dup:
            other = by_id.get(str(dup))
            if other is None:
                rep.violation(tag, f"duplicate_of {dup}, which is not an item")
            else:
                if str(other.get("duplicate_of")) != iid:
                    rep.violation(tag, f"duplicate_of {dup}, but {dup} does not name {iid} back")
                if other.get("status") != it.get("status"):
                    rep.violation(tag, f"is {it.get('status')} and its duplicate {dup} is "
                                       f"{other.get('status')} — you cannot close half a duplicate")
        sup = it.get("superseded_by")
        if sup:
            other = by_id.get(str(sup))
            if other is None:
                rep.violation(tag, f"superseded_by {sup}, which is not an item")
            elif other.get("status") == "closed" and it.get("status") != "closed":
                rep.violation(tag, f"superseded_by {sup}, which is closed, so this must close too")
        for up in as_list(it.get("upstream_of")):
            if up not in by_id:
                rep.violation(tag, f"upstream_of {up}, which is not an item — a finding that "
                                   "belongs upstream names the item it belongs to")

    cited = {b for it in items for b in as_list(it.get("blocked_on"))}
    for b in sorted(set(blockers) - cited):
        rep.warning(at, f"blocker {b!r} is declared and no item cites it")

    want = {"open": sum(1 for i in items if i.get("status") == "open"),
            "closed": sum(1 for i in items if i.get("status") == "closed"),
            "total": len(items)}
    if "counts" not in idx and not items:
        pass                              # an empty index states nothing to recompute
    elif (idx.get("counts") or {}) != want:
        rep.violation(at, f"counts say {idx.get('counts')}, the items give {want} — every stated "
                          "count derives from the items, in the commit that changes them")
    return want


# ── Entry point ──────────────────────────────────────────────────────────────

def main(argv: list[str]) -> int:
    opts, args, it = {}, [], iter(argv)
    for a in it:
        if a in ("--json", "--strict"):
            opts[a] = True
        elif a == "--standard":
            opts[a] = next(it, None)
        elif a in ("-h", "--help"):
            print(__doc__)
            return 0
        else:
            args.append(a)
    project = Path(args[0] if args else ".").resolve()
    here = Path(__file__).resolve().parent.parent
    standard = Path(opts.get("--standard") or here).resolve()

    try:
        ev = load_evaluator(standard)
        rows = ev.load_standard(standard)["rows"]
    except Exception as e:  # noqa: BLE001 — any failure here is a configuration error
        print(f"check-register: cannot read the standard at {standard}: {e}", file=sys.stderr)
        return 4
    if not (project / "decisions").is_dir():
        print(f"check-register: {project} has no decisions/ directory", file=sys.stderr)
        return 4

    rep = Report()
    adrs = check_adrs(project, ev, rows, rep)
    counts = check_open_items(project, adrs, rep)

    code = 1 if rep.violations else (1 if opts.get("--strict") and rep.warnings else 0)
    if opts.get("--json"):
        print(json.dumps({"format": "causeway-register-v1", "adrs": len(adrs),
                          "open_items": counts, "violations": rep.violations,
                          "warnings": rep.warnings, "exit_code": code}, indent=2))
        return code

    print(f"Decision register — {project}")
    print(f"  {len(adrs)} ADRs" + (f" · open items {counts['open']} open, {counts['closed']} closed"
                                    if counts else ""))
    for label, entries in (("VIOLATION", rep.violations), ("warning  ", rep.warnings)):
        for e in entries:
            print(f"  {label}  {e['where']}: {e['message']}")
    if not rep.violations and not rep.warnings:
        print("  ok  the record ties: every pointer resolves and every count derives")
    else:
        print(f"\n  {len(rep.violations)} violation(s), {len(rep.warnings)} warning(s)")
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
