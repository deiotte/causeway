#!/usr/bin/env python3
"""scan-secrets.py — the merge-blocking credential scan for this repository.

    ./tools/scan-secrets.py                 tracked files and every blob in history
    ./tools/scan-secrets.py --tree          tracked files only (or every file, without git)
    ./tools/scan-secrets.py --history       every blob reachable from any ref
    ./tools/scan-secrets.py --root DIR      scan another tree (the tests use this)

Exit 0 clean, 1 a finding or a stale suppression, 2 a usage or allowlist error.
Stdlib only and offline: the standard that tells consumers to count publishers
does not add one to scan itself (Build DNA §5; ADR 0054).

Build DNA §5 and rules/secrets.md make the secrets scan a merge-blocker. Until
v2.12.1 this repository's own gate ran no scanner at all, while it held a
release-signing secret and published security text (issue #38).

What it is: provider-shaped patterns with a low false-positive rate — private
key blocks and the token formats GitHub, AWS, Slack, Google, Stripe, npm, PyPI,
GitLab, Anthropic and OpenAI publish. What it is not: an entropy scanner. A
password typed into prose matches nothing here; that gap is stated, not closed.

A finding prints its rule, where it is, and a fingerprint — the SHA-256 of the
matched text — and never the text. A log that repeats the secret it caught has
leaked it a second time.

Suppressions live in tools/secret-scan-allow.json. Each one names a rule, an
exact path and an exact fingerprint (no globs, no rule-wide waivers), the reason
it is safe, and the person who accepted it. A suppression that matches nothing
in this scan is stale and fails, so a waiver cannot outlive what it waived.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

RULES: list[tuple[str, re.Pattern[bytes]]] = [
    ("private-key", re.compile(rb"-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY(?: BLOCK)?-----")),
    ("github-token", re.compile(rb"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}\b")),
    ("github-fine-grained-token", re.compile(rb"\bgithub_pat_[A-Za-z0-9_]{82}\b")),
    ("aws-access-key-id", re.compile(rb"\b(?:AKIA|ASIA|ABIA|ACCA)[A-Z2-7]{16}\b")),
    ("slack-token", re.compile(rb"\bxox[abposr]-[A-Za-z0-9-]{10,}")),
    ("slack-webhook", re.compile(rb"https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]{20,}")),
    ("google-api-key", re.compile(rb"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("stripe-live-key", re.compile(rb"\b[rs]k_live_[0-9A-Za-z]{20,}\b")),
    ("npm-token", re.compile(rb"\bnpm_[A-Za-z0-9]{36}\b")),
    ("pypi-token", re.compile(rb"\bpypi-AgEIcHlwaS5vcmc[A-Za-z0-9_-]{50,}")),
    ("gitlab-token", re.compile(rb"\bglpat-[A-Za-z0-9_-]{20}\b")),
    ("anthropic-key", re.compile(rb"\bsk-ant-[A-Za-z0-9_-]{20,}")),
    ("openai-key", re.compile(rb"\bsk-[A-Za-z0-9_-]{20,}T3BlbkFJ[A-Za-z0-9_-]{20,}")),
]

ALLOW_FIELDS = ("rule", "path", "fingerprint", "reason", "accepted_by")
RULE_NAMES = {name for name, _ in RULES}


def fingerprint(match: bytes) -> str:
    return hashlib.sha256(match).hexdigest()


def scan_bytes(data: bytes) -> list[tuple[str, int, str]]:
    """(rule, line, fingerprint) for every match. Binary content is skipped:
    a NUL in the first 8 KiB, the same test git uses."""
    if b"\0" in data[:8192]:
        return []
    out = []
    for name, pattern in RULES:
        for m in pattern.finditer(data):
            out.append((name, data.count(b"\n", 0, m.start()) + 1, fingerprint(m.group(0))))
    return out


def git(root: Path, *args: str, data: bytes | None = None) -> bytes | None:
    try:
        r = subprocess.run(["git", "-C", str(root), *args], input=data,
                           capture_output=True, timeout=600)
    except (OSError, subprocess.SubprocessError):
        return None
    return r.stdout if r.returncode == 0 else None


def is_git_tree(root: Path) -> bool:
    out = git(root, "rev-parse", "--is-inside-work-tree")
    return out is not None and out.strip() == b"true"


def tree_files(root: Path) -> list[str]:
    if is_git_tree(root):
        out = git(root, "ls-files", "-z") or b""
        return [p.decode("utf-8", "surrogateescape") for p in out.split(b"\0") if p]
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for f in filenames:
            files.append(os.path.relpath(os.path.join(dirpath, f), root))
    return sorted(files)


def scan_tree(root: Path) -> list[dict]:
    findings = []
    for rel in tree_files(root):
        p = root / rel
        if p.is_symlink() or not p.is_file():
            continue
        try:
            data = p.read_bytes()
        except OSError:
            continue
        for rule, line, fp in scan_bytes(data):
            findings.append({"rule": rule, "path": rel, "where": f"{rel}:{line}", "fingerprint": fp})
    return findings


def scan_history(root: Path) -> list[dict] | None:
    """Every blob reachable from any ref, once each, attributed to the first
    path it was seen under. None when there is no git history to read."""
    listing = git(root, "rev-list", "--objects", "--all")
    if listing is None:
        return None
    paths: dict[str, str] = {}
    for line in listing.decode("utf-8", "surrogateescape").splitlines():
        sha, _, path = line.partition(" ")
        if path and sha not in paths:
            paths[sha] = path
    if not paths:
        return []
    check = git(root, "cat-file", "--batch-check=%(objectname) %(objecttype)",
                data="\n".join(paths).encode() + b"\n") or b""
    blobs = [l.split()[0].decode() for l in check.splitlines() if l.endswith(b" blob")]
    findings = []
    for sha in blobs:
        data = git(root, "cat-file", "blob", sha)
        if data is None:
            continue
        for rule, line, fp in scan_bytes(data):
            findings.append({"rule": rule, "path": paths[sha],
                             "where": f"{paths[sha]}:{line} (blob {sha[:12]})", "fingerprint": fp})
    return findings


def load_allow(path: Path) -> tuple[list[dict], list[str]]:
    if not path.exists():
        return [], []
    try:
        doc = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        return [], [f"{path}: unreadable: {e}"]
    entries = doc.get("suppressions") if isinstance(doc, dict) else None
    if not isinstance(entries, list):
        return [], [f"{path}: needs a \"suppressions\" list"]
    errors = []
    for i, e in enumerate(entries):
        if not isinstance(e, dict):
            errors.append(f"suppression {i}: not an object"); continue
        empty = [f for f in ALLOW_FIELDS if not isinstance(e.get(f), str) or not e[f].strip()]
        if empty:
            errors.append(f"suppression {i}: missing {', '.join(empty)}")
            continue
        if e["rule"] not in RULE_NAMES:
            errors.append(f"suppression {i}: unknown rule {e['rule']!r}")
        if not re.fullmatch(r"[0-9a-f]{64}", e["fingerprint"]):
            errors.append(f"suppression {i}: fingerprint must be a full sha256")
        if any(ch in e["path"] for ch in "*?["):
            errors.append(f"suppression {i}: path must be exact, not a pattern")
    return entries, errors


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Merge-blocking credential scan (ADR 0054).")
    ap.add_argument("--tree", action="store_true", help="scan tracked files")
    ap.add_argument("--history", action="store_true", help="scan every blob in history")
    ap.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    ap.add_argument("--allow", help="suppression file (default: <root>/tools/secret-scan-allow.json)")
    args = ap.parse_args(argv)
    root = Path(args.root).resolve()
    allow_path = Path(args.allow) if args.allow else root / "tools" / "secret-scan-allow.json"
    do_tree = args.tree or not args.history
    do_history = args.history or not args.tree

    allow, errors = load_allow(allow_path)
    if errors:
        for e in errors:
            print(f"scan-secrets: {e}", file=sys.stderr)
        return 2

    findings: list[dict] = []
    scopes = []
    if do_tree:
        findings += scan_tree(root)
        scopes.append("tracked tree")
    if do_history:
        hist = scan_history(root)
        if hist is None:
            if args.history:
                print("scan-secrets: --history needs a git checkout with its history", file=sys.stderr)
                return 2
        else:
            findings += hist
            scopes.append("history")

    used = set()
    open_findings = []
    for f in findings:
        hit = next((i for i, a in enumerate(allow)
                    if (a["rule"], a["path"], a["fingerprint"]) == (f["rule"], f["path"], f["fingerprint"])), None)
        if hit is None:
            open_findings.append(f)
        else:
            used.add(hit)

    for f in open_findings:
        print(f"  FOUND  {f['rule']:<26} {f['where']}  fingerprint={f['fingerprint'][:16]}")
    stale = [a for i, a in enumerate(allow) if i not in used]
    for a in stale:
        print(f"  STALE  suppression for {a['rule']} in {a['path']} matches nothing — remove it")

    if open_findings or stale:
        print("")
        if open_findings:
            print(f"{len(open_findings)} possible credential(s). Do not paste the value anywhere to ask about it.")
            print("A real one: remove it, rotate it at the provider, and treat it as disclosed —")
            print("deleting it from the tree does not delete it from history (rules/secrets.md).")
            print("A synthetic fixture: build it at runtime, or suppress it by fingerprint in")
            print("tools/secret-scan-allow.json with a reason and the name of who accepted it.")
        return 1
    print(f"no credentials found ({' and '.join(scopes)}, {len(RULES)} rules, {len(allow)} suppression(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
