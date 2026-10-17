#!/usr/bin/env python3
"""`make setup`: configure the stack in your browser instead of hunting for `.env`.

A small local web page, served on 127.0.0.1 only, that:

  1. shows every variable in `.env.example` as a form, grouped and documented
     the way the example file already is, prefilled from your `.env` if you
     have one or from the defaults (with fresh random secrets) if you do not;
  2. writes `.env` when you press Save;
  3. runs the project's documented `make` targets (the ones with a `## help`
     comment, or the ones `SETUP_TARGETS` names) from the same page and
     streams their output;
  4. shows the project's containers, from docker's own view, going healthy as
     the stack comes up.

Stdlib only; nothing is installed and nothing leaves your machine. There is no
authentication beyond the loopback bind: a random token embedded in the page
is required on every write, so another site open in your browser cannot drive
it.

    python3 tools/setup/setup.py                 # open the page, keep serving
    python3 tools/setup/setup.py --until-saved   # exit as soon as .env is written
                                                 # (what `make up` does when .env is missing)
    python3 tools/setup/setup.py --no-browser --port 3999

Repo-agnostic by construction: the only inputs are `.env.example`, `.env`, and
the project's Makefile. Ships with the Causeway standard (Build DNA §6,
*Configure, set up, run*); DISE was the first adopter, and the rules below that
read like scars are its field reports (ADR 0052).
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import secrets as pysecrets
import subprocess
import sys
import threading
import time
import webbrowser
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import env_schema as es  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
EXAMPLE_PATH = REPO_ROOT / ".env.example"
ENV_PATH = REPO_ROOT / ".env"


def browser_launch_decision(env: dict[str, str], euid: int, platform: str) -> tuple[bool, str]:
    """Whether to launch a browser ourselves, and why not when not. Pure.

    Launching under `sudo` is the case that bit first: the browser starts as
    root with no desktop session behind it, and GNOME Web crashed in a loop
    while the server sat there working. Printing the URL and letting the person
    open it in the browser they already have is the version that cannot fail."""
    if env.get("SETUP_NO_BROWSER", "") not in ("", "0"):
        return False, "SETUP_NO_BROWSER is set"
    if euid == 0 or env.get("SUDO_USER"):
        return False, "running as root (sudo), so the browser is not launched for you"
    if platform.startswith(("linux", "freebsd", "openbsd")) and not (
        env.get("DISPLAY") or env.get("WAYLAND_DISPLAY")
    ):
        return False, "no desktop session (DISPLAY / WAYLAND_DISPLAY unset)"
    if env.get("SSH_CONNECTION") and not env.get("DISPLAY"):
        return False, "SSH session without a forwarded display"
    return True, ""


def open_browser(url: str) -> None:
    """Best effort, and quiet: a browser's own warnings on stderr are noise
    next to the one line that matters, the URL."""
    if sys.platform.startswith("linux"):
        try:
            subprocess.Popen(
                ["xdg-open", url],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            return
        except OSError:
            pass
    try:
        webbrowser.open(url)
    except Exception:  # noqa: BLE001 — a browser that cannot start is not our failure
        pass


def compose_project_name(makefile_text: str, compose_text: str, env: dict[str, str], fallback: str) -> str:
    """The name docker compose files volumes under. `COMPOSE_PROJECT_NAME` wins,
    then a top-level `name:` in the compose file, then the directory name,
    which is compose's own default. Pure."""
    if env.get("COMPOSE_PROJECT_NAME"):
        return env["COMPOSE_PROJECT_NAME"]
    m = re.search(r"^name:\s*['\"]?([A-Za-z0-9][A-Za-z0-9_.-]*)", compose_text, re.M)
    if m:
        return m.group(1)
    return fallback.lower()


def compose_file_path(makefile_text: str) -> Path:
    m = re.search(r"^COMPOSE_FILE\s*[:?]?=\s*(\S+)", makefile_text, re.M)
    return REPO_ROOT / (m.group(1) if m else "docker-compose.yml")


def previous_run_volumes(project: str) -> list[str] | None:
    """Volumes docker still holds for this compose project. None when docker
    cannot be asked (not installed, not permitted, not running): the page then
    says nothing rather than guessing.

    Why it matters: a database or an imported Keycloak realm keeps the password
    it was created with. A fresh `.env` with fresh secrets against volumes from
    an earlier run fails at the first service that logs in, which is Keycloak,
    with nothing on the page to say why."""
    try:
        out = subprocess.run(
            ["docker", "volume", "ls", "--filter", f"label=com.docker.compose.project={project}", "--format", "{{.Name}}"],
            capture_output=True, text=True, timeout=8,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if out.returncode != 0:
        return None
    return sorted(line.strip() for line in out.stdout.splitlines() if line.strip())


def detect_previous_run() -> dict[str, object]:
    makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8") if (REPO_ROOT / "Makefile").exists() else ""
    compose = compose_file_path(makefile)
    compose_text = compose.read_text(encoding="utf-8") if compose.exists() else ""
    project = compose_project_name(makefile, compose_text, dict(os.environ), REPO_ROOT.name)
    return {"project": project, "volumes": previous_run_volumes(project)}


def run_make_clean() -> tuple[bool, str]:
    """Runs `make clean` and reports whether the previous run's volumes are
    actually gone afterwards. The target's own exit code is not the evidence
    (it ends in `|| true`); the volume list is."""
    env = dict(os.environ, SETUP_UI="0")
    try:
        out = subprocess.run(["make", "clean"], cwd=REPO_ROOT, env=env, capture_output=True, text=True, timeout=600)
    except (OSError, subprocess.TimeoutExpired) as e:
        return False, str(e)
    tail = "\n".join((out.stdout + out.stderr).splitlines()[-15:])
    remaining = previous_run_volumes(detect_previous_run()["project"])
    if remaining == []:
        return True, tail
    if remaining:
        tail += "\nvolumes still present: " + ", ".join(remaining)
    else:
        tail += "\ncould not ask docker whether the volumes are gone"
    return False, tail


def hand_back_to_invoking_user(path: Path, env: dict[str, str]) -> str | None:
    """Under `sudo`, a file we write belongs to root and is mode 600, which
    locks the person who typed the command out of their own `.env`. Give it
    back to them. Returns the user name on success, None otherwise."""
    uid, gid = env.get("SUDO_UID"), env.get("SUDO_GID")
    if not (uid and gid and uid.isdigit() and gid.isdigit()):
        return None
    try:
        if os.geteuid() != 0:
            return None
        os.chown(path, int(uid), int(gid))
    except (AttributeError, OSError):
        return None
    return env.get("SUDO_USER") or uid

# ---- run targets ---------------------------------------------------------
#
# The page may run an allow-list of make targets, not free text: it can only do
# what a person at the terminal would type. The list is the project's own, read
# from its Makefile, so there is no second place to maintain:
#
#   * every target with a `## help` comment (`up: $(ENV_FILE) ## Start …`), in
#     Makefile order, with the comment as its description; or, when the
#     Makefile sets `SETUP_TARGETS := up wait-ready demo down clean`, exactly
#     those, in that order (a help comment is still used when present).
#   * a target is destructive, and the page asks before running it, when its
#     name is one of DESTRUCTIVE_NAMES or its help says it deletes something.

TARGET_HELP = re.compile(r"^(?P<name>[A-Za-z0-9_.-]+):[^#=\n]*##\s*(?P<help>.+?)\s*$", re.M)
SETUP_TARGETS_VAR = re.compile(r"^SETUP_TARGETS\s*[:?]?=\s*(?P<list>.*?)\s*$", re.M)
DESTRUCTIVE_NAMES = {"clean", "distclean", "purge", "nuke", "destroy", "reset-all"}
DESTRUCTIVE_HINT = re.compile(r"\b(delet\w*|destroy\w*|wipe\w*|eras\w*|drop\w*|purge\w*)\b", re.I)


@dataclass
class Target:
    id: str
    label: str
    desc: str
    destructive: bool


def discover_targets(makefile_text: str) -> list[Target]:
    """The targets the page offers, from the Makefile alone. Pure."""
    helps: dict[str, str] = {}
    order: list[str] = []
    for m in TARGET_HELP.finditer(makefile_text):
        name = m.group("name")
        if name.startswith(".") or name in helps:
            continue
        helps[name] = m.group("help")
        order.append(name)
    chosen = order
    m = SETUP_TARGETS_VAR.search(makefile_text)
    if m:
        chosen = [t for t in m.group("list").split() if t]
    out: list[Target] = []
    for name in chosen:
        desc = helps.get(name, "")
        destructive = name in DESTRUCTIVE_NAMES or bool(DESTRUCTIVE_HINT.search(desc))
        out.append(Target(id=name, label=f"make {name}", desc=desc, destructive=destructive))
    return out


# ---- health -----------------------------------------------------------------
#
# Docker's own view of the project's containers, by the compose project label:
# no list of ports to maintain, and "healthy" means the container's healthcheck
# says so, not that something answered on a port.

def container_status(project: str) -> list[dict[str, object]] | None:
    try:
        out = subprocess.run(
            ["docker", "ps", "-a", "--filter", f"label=com.docker.compose.project={project}",
             "--format", "{{.Label \"com.docker.compose.service\"}}\t{{.State}}\t{{.Status}}"],
            capture_output=True, text=True, timeout=8,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if out.returncode != 0:
        return None
    return parse_container_status(out.stdout)


def parse_container_status(text: str) -> list[dict[str, object]]:
    """Rows of `service\tstate\tstatus` into pills. Pure. A running container
    with a healthcheck is up when it says healthy; one without is up when it
    runs; anything exited or restarting is down, and its status says why."""
    rows: list[dict[str, object]] = []
    for line in text.splitlines():
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        name, state, status = parts[0].strip(), parts[1].strip(), parts[2].strip()
        if not name:
            continue
        has_health = "health" in status.lower()
        up = state == "running" and ((not has_health) or "(healthy)" in status.lower())
        rows.append({"name": name, "state": state, "status": status, "up": up})
    rows.sort(key=lambda r: str(r["name"]))
    return rows


class Runner:
    """One `make` subprocess at a time, output kept in memory for the page."""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.proc: subprocess.Popen | None = None
        self.target: str | None = None
        self.lines: list[str] = []
        self.exit_code: int | None = None

    def start(self, target: str) -> tuple[bool, str]:
        with self.lock:
            if self.proc is not None and self.proc.poll() is None:
                return False, f"`make {self.target}` is still running"
            self.lines = [f"$ make {target}"]
            self.exit_code = None
            self.target = target
            try:
                self.proc = subprocess.Popen(
                    ["make", target],
                    cwd=str(REPO_ROOT),
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    env={**os.environ, "SETUP_UI": "0", "PYTHONUNBUFFERED": "1"},
                )
            except OSError as e:
                return False, f"could not start make: {e}"
            threading.Thread(target=self._pump, args=(self.proc,), daemon=True).start()
            return True, "started"

    def _pump(self, proc: subprocess.Popen) -> None:
        assert proc.stdout is not None
        for line in proc.stdout:
            with self.lock:
                self.lines.append(line.rstrip("\n"))
                if len(self.lines) > 5000:
                    del self.lines[: len(self.lines) - 5000]
        code = proc.wait()
        with self.lock:
            self.exit_code = code
            self.lines.append(f"[exit {code}]")

    def stop(self) -> str:
        with self.lock:
            if self.proc is None or self.proc.poll() is not None:
                return "nothing running"
            self.proc.terminate()
            return "sent SIGTERM"

    def snapshot(self, since: int) -> dict:
        with self.lock:
            running = self.proc is not None and self.proc.poll() is None
            return {
                "target": self.target,
                "running": running,
                "exit_code": self.exit_code,
                "next": len(self.lines),
                "lines": self.lines[since:] if since < len(self.lines) else [],
            }


class State:
    def __init__(self, until_saved: bool) -> None:
        self.token = pysecrets.token_urlsafe(24)
        self.until_saved = until_saved
        self.saved = threading.Event()
        self.saved_owner: str | None = None
        self.runner = Runner()
        makefile = REPO_ROOT / "Makefile"
        self.makefile_text = makefile.read_text(encoding="utf-8") if makefile.exists() else ""
        self.targets = discover_targets(self.makefile_text)
        self.project = detect_previous_run()["project"]

    def schema(self) -> es.Schema:
        return es.parse_example(EXAMPLE_PATH.read_text(encoding="utf-8"))

    def existing(self) -> dict[str, str] | None:
        if ENV_PATH.exists():
            return es.parse_env(ENV_PATH.read_text(encoding="utf-8"))
        return None


def make_handler(state: State):
    class Handler(BaseHTTPRequestHandler):
        server_version = "dise-setup/1"

        def log_message(self, fmt, *args):  # quiet; the page is the log
            pass

        # ---- helpers ----
        def _json(self, code: int, body) -> None:
            data = json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def _html(self, body: str) -> None:
            data = body.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Frame-Options", "DENY")
            self.end_headers()
            self.wfile.write(data)

        def _authorized(self) -> bool:
            return self.headers.get("X-Setup-Token") == state.token

        def _read_json(self):
            n = int(self.headers.get("Content-Length") or 0)
            raw = self.rfile.read(n) if n else b"{}"
            return json.loads(raw.decode() or "{}")

        # ---- routes ----
        def do_GET(self):
            path = self.path.split("?", 1)[0]
            if path == "/":
                return self._html(render_page(state))
            if path == "/favicon.ico":
                self.send_response(204)
                self.end_headers()
                return None
            if path == "/api/state":
                schema = state.schema()
                existing = state.existing()
                return self._json(200, {
                    "env_exists": existing is not None,
                    "values": es.initial_values(schema, existing),
                })
            if path.startswith("/api/log"):
                qs = self.path.split("?", 1)[1] if "?" in self.path else ""
                since = 0
                for part in qs.split("&"):
                    if part.startswith("since="):
                        try:
                            since = int(part[6:])
                        except ValueError:
                            since = 0
                return self._json(200, state.runner.snapshot(since))
            if path == "/api/health":
                rows = container_status(state.project)
                return self._json(200, {"available": rows is not None, "services": rows or []})
            self.send_error(404)

        def do_POST(self):
            if not self._authorized():
                return self._json(403, {"error": "missing or wrong setup token"})
            path = self.path.split("?", 1)[0]
            if path == "/api/save":
                return self._save()
            if path == "/api/run":
                body = self._read_json()
                target = str(body.get("target", ""))
                if target not in {t.id for t in state.targets}:
                    return self._json(400, {"error": f"unknown target {target!r}"})
                if not ENV_PATH.exists():
                    return self._json(409, {"error": "save .env first"})
                ok, msg = state.runner.start(target)
                return self._json(200 if ok else 409, {"ok": ok, "message": msg})
            if path == "/api/stop":
                return self._json(200, {"message": state.runner.stop()})
            if path == "/api/secret":
                return self._json(200, {"value": es.generate_secret()})
            self.send_error(404)

        def _save(self):
            body = self._read_json()
            incoming = body.get("values")
            if not isinstance(incoming, dict):
                return self._json(400, {"error": "values must be an object"})
            schema = state.schema()
            known = set(schema.names())
            before = state.existing() or {}
            values: dict[str, str] = dict(before)  # keep unknown keys from a previous .env
            for k, v in incoming.items():
                if not isinstance(k, str) or not es.ASSIGNMENT.match(f"{k}="):
                    return self._json(400, {"error": f"bad variable name {k!r}"})
                if k not in known and k not in before:
                    return self._json(400, {"error": f"{k} is not in .env.example"})
                if not isinstance(v, str) or "\n" in v or "\r" in v:
                    return self._json(400, {"error": f"{k}: value must be a single line"})
                values[k] = v
            missing = [n for n in schema.names() if not values.get(n, "").strip() and schema.var(n).default.strip()]
            if missing:
                return self._json(400, {"error": "these need a value: " + ", ".join(missing)})
            text = es.render_env(schema, values)
            tmp = ENV_PATH.with_suffix(".env.tmp")
            tmp.write_text(text, encoding="utf-8")
            try:
                os.chmod(tmp, 0o600)
            except OSError:
                pass
            owner = hand_back_to_invoking_user(tmp, dict(os.environ))
            os.replace(tmp, ENV_PATH)
            rotated = es.changed_secrets(schema, before, values)
            state.saved_owner = owner
            cleaned: bool | None = None
            clean_tail = ""
            if body.get("clean_first") is True:
                # Opt-in from the page, shown only when volumes from a previous
                # run exist and this .env is new: delete them before `make up`
                # continues, so the fresh secrets are the ones the databases
                # and the realm are created with. Synchronous on purpose: in
                # --until-saved mode make continues the moment we signal.
                cleaned, clean_tail = run_make_clean()
            state.saved.set()
            return self._json(200, {
                "ok": True,
                "path": str(ENV_PATH),
                "owner": owner,
                "cleaned": cleaned,
                "clean_tail": clean_tail,
                "rotated_secrets": rotated,
                "note": (
                    "A password or secret changed after the stack may already have started. "
                    "Databases keep the password they were created with and Keycloak keeps the "
                    "realm it first imported, so run `make clean` (deletes volumes) before `make up`."
                    if rotated and before else ""
                ),
            })

    return Handler


def render_page(state: State) -> str:
    schema = state.schema()
    existing = state.existing()
    groups = [
        {
            "title": g.title,
            "help": g.help,
            "vars": [{"name": v.name, "help": v.help, "secret": v.secret, "default": v.default} for v in g.vars],
        }
        for g in schema.groups
    ]
    initial = es.initial_values(schema, existing)
    boot = {
        "token": state.token,
        "groups": groups,
        "values": initial,
        "env_exists": existing is not None,
        "env_path": str(ENV_PATH),
        "example_path": str(EXAMPLE_PATH.relative_to(REPO_ROOT)),
        "targets": [{"id": t.id, "label": t.label, "desc": t.desc, "destructive": t.destructive} for t in state.targets],
        "until_saved": state.until_saved,
        "preamble": schema.preamble,
        "previous_run": detect_previous_run(),
    }
    # Inside a <script> element entities are not decoded, so the JSON is not
    # HTML-escaped; the one sequence that could end the element early is `</`.
    boot_json = json.dumps(boot).replace("</", "<\\/")
    return PAGE.replace("__BOOT__", boot_json).replace("__TITLE__", html.escape(REPO_ROOT.name))


PAGE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__ setup</title>
<style>
  :root { --bg:#0b0f14; --card:#11161e; --line:#2a3441; --fg:#e6edf3; --muted:#8b98a5; --ok:#3fb950; --warn:#d29922; --bad:#f85149; --accent:#58a6ff; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--fg); font:14px/1.45 ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,sans-serif; }
  header { padding:1rem 1.25rem; border-bottom:1px solid var(--line); display:flex; align-items:baseline; gap:1rem; flex-wrap:wrap; position:sticky; top:0; background:var(--bg); z-index:2; }
  header h1 { font-size:1.1rem; margin:0; }
  header .muted { color:var(--muted); }
  main { display:grid; grid-template-columns: minmax(0,1.3fr) minmax(0,1fr); gap:1rem; padding:1rem 1.25rem; }
  @media (max-width: 1000px) { main { grid-template-columns:1fr; } }
  .card { background:var(--card); border:1px solid var(--line); border-radius:6px; padding:1rem; margin-bottom:1rem; }
  .card h2 { font-size:1rem; margin:0 0 .35rem; }
  .help { color:var(--muted); white-space:pre-wrap; font-size:.82rem; margin:0 0 .6rem; }
  .var { display:grid; grid-template-columns: minmax(180px, 34%) 1fr; gap:.4rem .75rem; align-items:start; padding:.45rem 0; border-top:1px solid var(--line); }
  .var:first-of-type { border-top:0; }
  .var label { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size:.8rem; word-break:break-all; padding-top:.45rem; }
  .var .help { margin:.25rem 0 0; grid-column: 1 / -1; }
  .field { display:flex; gap:.35rem; min-width:0; }
  @media (max-width: 600px) { .var { grid-template-columns: 1fr; } .var label { padding-top:0; } main { padding:.75rem 1rem; } header { padding:.75rem 1rem; } }
  main, .card, pre#log { min-width:0; max-width:100%; }
  html, body { overflow-x:hidden; }
  input[type=text], input[type=password] { flex:1; min-width:0; width:100%; background:#0b0f14; color:var(--fg); border:1px solid var(--line); border-radius:4px; padding:.4rem .5rem; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size:.82rem; }
  input:focus { outline:1px solid var(--accent); }
  button { background:#1b2330; color:var(--fg); border:1px solid var(--line); border-radius:4px; padding:.4rem .7rem; cursor:pointer; font-size:.82rem; }
  button:hover { border-color:var(--accent); }
  button.primary { background:#1f4d8a; border-color:#2f6fbf; }
  button.danger { border-color:#7d2a2a; }
  button:disabled { opacity:.5; cursor:not-allowed; }
  .bar { display:flex; gap:.5rem; flex-wrap:wrap; align-items:center; }
  .status { font-size:.82rem; color:var(--muted); }
  .status.ok { color:var(--ok); } .status.bad { color:var(--bad); } .status.warn { color:var(--warn); }
  .targets { display:grid; grid-template-columns: repeat(auto-fill, minmax(150px,1fr)); gap:.5rem; }
  .targets button { text-align:left; }
  .targets small { display:block; color:var(--muted); font-size:.72rem; margin-top:.15rem; }
  pre#log { background:#05080c; border:1px solid var(--line); border-radius:4px; padding:.6rem; height:360px; overflow:auto; font-size:.76rem; margin:.6rem 0 0; white-space:pre-wrap; }
  .health { display:flex; flex-wrap:wrap; gap:.4rem; }
  .pill { border:1px solid var(--line); border-radius:999px; padding:.15rem .6rem; font-size:.76rem; color:var(--muted); }
  .pill.up { border-color:var(--ok); color:var(--ok); }
  .note { border-left:3px solid var(--warn); padding:.4rem .6rem; color:var(--fg); background:#1a1708; font-size:.82rem; margin-top:.6rem; display:none; }
  code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size:.8rem; }
</style>
</head>
<body>
<header>
  <h1>__TITLE__ · setup</h1>
  <span class="muted" id="envline"></span>
  <span class="status" id="savestatus"></span>
</header>
<main>
  <section id="form">
    <div class="card">
      <div class="bar">
        <button class="primary" id="save">Save .env</button>
        <button id="genall">Generate all secrets</button>
        <button id="showall">Show secrets</button>
        <span class="status muted">Form is built from <code id="example"></code>. Add a variable there and it appears here.</span>
      </div>
      <div class="note" id="note"></div>
      <div class="note" id="stale"></div>
    </div>
    <div id="groups"></div>
  </section>
  <aside>
    <div class="card">
      <h2>Run</h2>
      <p class="help">Runs the same <code>make</code> targets you would type, the ones the Makefile documents. One at a time; output streams below.</p>
      <div class="targets" id="targets"></div>
      <div class="bar" style="margin-top:.6rem">
        <button id="stop">Stop</button>
        <span class="status" id="runstatus">idle</span>
      </div>
      <pre id="log"></pre>
    </div>
    <div class="card">
      <h2>Health</h2>
      <p class="help">Docker's own view of this project's containers, every 5 seconds. Green means running, and healthy where the container has a healthcheck.</p>
      <div class="health" id="health"></div>
    </div>
  </aside>
</main>
<script id="boot" type="application/json">__BOOT__</script>
<script>
(function(){
  const B = JSON.parse(document.getElementById('boot').textContent);
  const $ = (id) => document.getElementById(id);
  const headers = { 'Content-Type': 'application/json', 'X-Setup-Token': B.token };
  const esc = (s) => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

  $('example').textContent = B.example_path;
  $('envline').textContent = B.env_exists ? ('editing ' + B.env_path) : ('no .env yet — will write ' + B.env_path);

  // ---- volumes from a previous run ----
  // A database and an imported Keycloak realm keep the password they were
  // created with. New .env + old volumes = `make up` dies at Keycloak with
  // exit 1 and nothing on screen to say why. Say why, here, before Save.
  const prev = B.previous_run || {};
  const vols = prev.volumes || [];
  const stale = $('stale');
  const hasClean = B.targets.some(t => t.id === 'clean');
  if (!B.env_exists && vols.length) {
    stale.style.display = 'block';
    stale.innerHTML = '<b>Docker still has ' + vols.length + ' volume' + (vols.length === 1 ? '' : 's') + ' from a previous run of <code>' + esc(prev.project) + '</code>.</b> ' +
      'Databases and the Keycloak realm keep the passwords they were created with, and this is a new .env with new secrets, so <code>make up</code> would fail at Keycloak. ' +
      (hasClean
        ? '<label style="display:block;margin-top:.4rem"><input type="checkbox" id="cleanfirst" checked> Delete those volumes when I save (<code>make clean</code>: all data from the previous run is gone)</label>'
        : '<span style="display:block;margin-top:.4rem">This Makefile has no <code>clean</code> target; remove the volumes yourself before starting, or enter the secrets that run used.</span>') +
      '<span class="muted" style="display:block;margin-top:.3rem">' + esc(vols.join(', ')) + '</span>';
  }

  // ---- form ----
  const groupsEl = $('groups');
  for (const g of B.groups) {
    const card = document.createElement('div'); card.className = 'card';
    card.innerHTML = '<h2>' + esc(g.title) + '</h2>' + (g.help ? '<p class="help">' + esc(g.help) + '</p>' : '');
    for (const v of g.vars) {
      const row = document.createElement('div'); row.className = 'var';
      const val = B.values[v.name] ?? v.default;
      row.innerHTML =
        '<label for="f-' + esc(v.name) + '">' + esc(v.name) + '</label>' +
        '<div class="field"><input id="f-' + esc(v.name) + '" data-name="' + esc(v.name) + '" type="' + (v.secret ? 'password' : 'text') + '" value="' + esc(val) + '" autocomplete="off" spellcheck="false">' +
        (v.secret ? '<button type="button" data-gen="' + esc(v.name) + '" title="Generate a fresh random value">⟳</button><button type="button" data-eye="' + esc(v.name) + '" title="Show / hide">👁</button>' : '') +
        '</div>' + (v.help ? '<p class="help">' + esc(v.help) + '</p>' : '');
      card.appendChild(row);
    }
    groupsEl.appendChild(card);
  }
  groupsEl.addEventListener('click', async (e) => {
    const gen = e.target.closest('[data-gen]'); const eye = e.target.closest('[data-eye]');
    if (gen) { const r = await fetch('/api/secret', {method:'POST', headers}); const j = await r.json(); $('f-' + gen.dataset.gen).value = j.value; }
    if (eye) { const i = $('f-' + eye.dataset.eye); i.type = i.type === 'password' ? 'text' : 'password'; }
  });
  $('genall').onclick = async () => {
    for (const g of B.groups) for (const v of g.vars) if (v.secret) {
      const r = await fetch('/api/secret', {method:'POST', headers}); const j = await r.json(); $('f-' + v.name).value = j.value;
    }
  };
  let shown = false;
  $('showall').onclick = () => { shown = !shown; document.querySelectorAll('input[data-name]').forEach(i => { if (B.groups.some(g => g.vars.some(v => v.name === i.dataset.name && v.secret))) i.type = shown ? 'text' : 'password'; }); $('showall').textContent = shown ? 'Hide secrets' : 'Show secrets'; };

  function collect() { const o = {}; document.querySelectorAll('input[data-name]').forEach(i => o[i.dataset.name] = i.value); return o; }
  $('save').onclick = async () => {
    const st = $('savestatus'); st.className = 'status'; st.textContent = 'saving…';
    const cf = $('cleanfirst');
    const cleanFirst = !!(cf && cf.checked);
    if (cleanFirst) st.textContent = 'saving, then make clean (deleting previous volumes)…';
    const r = await fetch('/api/save', {method:'POST', headers, body: JSON.stringify({values: collect(), clean_first: cleanFirst})});
    const j = await r.json();
    if (!r.ok) { st.className = 'status bad'; st.textContent = j.error || 'save failed'; return; }
    st.className = 'status ok'; st.textContent = 'saved ' + j.path + (j.owner ? ' (owned by ' + j.owner + ')' : '') + (B.until_saved ? ' — you can close this tab; make is continuing' : '');
    if (j.cleaned === true) { stale.innerHTML = '<b>Previous volumes deleted.</b> The stack will be created with the secrets you just saved.'; }
    else if (j.cleaned === false) { stale.innerHTML = '<b>make clean failed</b>, so the previous volumes are still there. Run <code>make clean</code> yourself before <code>make up</code>.<pre style="white-space:pre-wrap;margin:.3rem 0 0">' + esc(j.clean_tail || '') + '</pre>'; }
    B.env_exists = true; $('envline').textContent = 'editing ' + j.path;
    const note = $('note');
    if (j.note) { note.style.display = 'block'; note.textContent = j.note + ' Changed: ' + j.rotated_secrets.join(', '); } else { note.style.display = 'none'; }
  };

  // ---- run ----
  const targetsEl = $('targets');
  for (const t of B.targets) {
    const b = document.createElement('button'); b.type = 'button'; b.dataset.target = t.id; if (t.destructive) b.className = 'danger';
    b.innerHTML = '<strong>' + esc(t.label) + '</strong><small>' + esc(t.desc) + '</small>';
    targetsEl.appendChild(b);
  }
  targetsEl.addEventListener('click', async (e) => {
    const b = e.target.closest('button[data-target]'); if (!b) return;
    const t = B.targets.find(x => x.id === b.dataset.target);
    if (t.destructive && !confirm(t.label + ': ' + (t.desc || 'this deletes data') + '\n\nContinue?')) return;
    const rs = $('runstatus');
    next = 0; $('log').textContent = ''; rs.className = 'status'; rs.textContent = 'starting ' + t.label;
    const r = await fetch('/api/run', {method:'POST', headers, body: JSON.stringify({target: t.id})});
    const j = await r.json();
    if (!r.ok) { rs.className = 'status bad'; rs.textContent = j.error || j.message; }
    // From here the log poll owns the status: it reports running / finished / exited.
  });
  $('stop').onclick = async () => { await fetch('/api/stop', {method:'POST', headers}); };

  let next = 0;
  async function pollLog() {
    try {
      const r = await fetch('/api/log?since=' + next); const j = await r.json();
      if (j.lines.length) { const log = $('log'); const atBottom = log.scrollTop + log.clientHeight >= log.scrollHeight - 8; log.textContent += (log.textContent ? '\n' : '') + j.lines.join('\n'); next = j.next; if (atBottom) log.scrollTop = log.scrollHeight; }
      const rs = $('runstatus');
      if (j.target) {
        if (j.running) { rs.className = 'status'; rs.textContent = 'running make ' + j.target; }
        else if (j.exit_code === 0) { rs.className = 'status ok'; rs.textContent = 'make ' + j.target + ' finished'; }
        else if (j.exit_code !== null) { rs.className = 'status bad'; rs.textContent = 'make ' + j.target + ' exited ' + j.exit_code; }
      }
      document.querySelectorAll('button[data-target]').forEach(b => b.disabled = !!j.running);
    } catch (e) { /* server went away (until-saved mode); stop quietly */ return; }
    setTimeout(pollLog, 700);
  }
  pollLog();

  // ---- health ----
  async function pollHealth() {
    try {
      const r = await fetch('/api/health'); const j = await r.json();
      if (!j.available) { $('health').innerHTML = '<span class="muted">docker cannot be asked from here</span>'; }
      else if (!j.services.length) { $('health').innerHTML = '<span class="muted">no containers for this project yet</span>'; }
      else { $('health').innerHTML = j.services.map(s => '<span class="pill ' + (s.up ? 'up' : '') + '" title="' + esc(s.status) + '">' + esc(s.name) + (s.up ? '' : ' · ' + esc(s.state)) + '</span>').join(''); }
    } catch (e) { return; }
    setTimeout(pollHealth, 5000);
  }
  pollHealth();
})();
</script>
</body>
</html>
"""


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--port", type=int, default=3999)
    ap.add_argument("--no-browser", action="store_true")
    ap.add_argument("--until-saved", action="store_true", help="exit 0 as soon as .env has been written")
    args = ap.parse_args(argv)

    if not EXAMPLE_PATH.exists():
        print(f"setup: {EXAMPLE_PATH} not found; nothing to configure", file=sys.stderr)
        return 2

    state = State(until_saved=args.until_saved)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(state))
    server.daemon_threads = True
    url = f"http://127.0.0.1:{server.server_address[1]}/"
    launch, why_not = browser_launch_decision(dict(os.environ), os.geteuid() if hasattr(os, "geteuid") else -1, sys.platform)
    if args.no_browser:
        launch = False
    print("setup: ready", flush=True)
    print(f"setup:   open {url} in your browser  (Ctrl-C here stops the server)", flush=True)
    if not args.no_browser and not launch:
        print(f"setup:   ({why_not})", flush=True)
    if launch:
        threading.Timer(0.4, lambda: open_browser(url)).start()
    if not ENV_PATH.exists():
        prev = detect_previous_run()
        if prev["volumes"]:
            print(
                f"setup:   note: docker still has {len(prev['volumes'])} volume(s) from a previous run of "
                f"{prev['project']}; a new .env has new secrets, so the page offers to delete them on Save",
                flush=True,
            )

    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    try:
        if args.until_saved:
            while not state.saved.wait(0.5):
                pass
            owner = f" (owned by {state.saved_owner})" if state.saved_owner else ""
            print(f"setup: wrote {ENV_PATH}{owner}; continuing", flush=True)
            time.sleep(1.0)  # let the page read the save response
            return 0
        while True:
            time.sleep(3600)
    except KeyboardInterrupt:
        print("\nsetup: stopped", flush=True)
        return 0
    finally:
        server.shutdown()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
