"""`.env.example` as a form schema, and `.env` as the thing the form writes.

The setup page (`setup.py`) never has its own list of variables. It reads the
committed `.env.example`, which is already the documented contract of every
value the stack consumes (`docs/SECRETS.md`), and turns its structure into a
form:

  * a `# --- Title ---` comment line opens a group;
  * comment lines that follow the header, before any variable, are the group's
    help text;
  * comment lines directly above a variable are that variable's help text;
  * `NAME=default` is a field, prefilled with the default;
  * a name containing PASSWORD, SECRET, TOKEN or KEY is a secret: masked, with
    a generate button, and prefilled with a fresh random value rather than the
    committed dev default when no `.env` exists yet.

Add a variable to `.env.example` and it appears on the page. There is no second
place to maintain, which is the whole point.

Stdlib only, and no I/O in the parsing and rendering functions, so this module
is testable without a filesystem and reusable by any project that keeps an
`.env.example`. Ships with the Causeway standard as `tools/setup/`.
"""

from __future__ import annotations

import re
import secrets
import string
from dataclasses import dataclass, field

GROUP_HEADER = re.compile(r"^#\s*-{2,}\s*(?P<title>.+?)\s*-{2,}\s*$")
ASSIGNMENT = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?P<value>.*)$")
SECRET_HINT = re.compile(r"(PASSWORD|SECRET|TOKEN|_KEY$|_KEY_|CREDENTIAL)", re.IGNORECASE)
_SECRET_ALPHABET = string.ascii_letters + string.digits


@dataclass
class Var:
    name: str
    default: str
    help: str = ""
    secret: bool = False


@dataclass
class Group:
    title: str
    help: str = ""
    vars: list[Var] = field(default_factory=list)


@dataclass
class Schema:
    preamble: str
    groups: list[Group]

    def names(self) -> list[str]:
        return [v.name for g in self.groups for v in g.vars]

    def var(self, name: str) -> Var | None:
        for g in self.groups:
            for v in g.vars:
                if v.name == name:
                    return v
        return None

    def defaults(self) -> dict[str, str]:
        return {v.name: v.default for g in self.groups for v in g.vars}


def is_secret_name(name: str) -> bool:
    return bool(SECRET_HINT.search(name))


def parse_example(text: str) -> Schema:
    """Turns the text of an `.env.example` into a Schema. Pure."""
    preamble_lines: list[str] = []
    groups: list[Group] = []
    current: Group | None = None
    pending_comment: list[str] = []
    seen_var_in_group = False

    def flush_group_help() -> None:
        nonlocal pending_comment
        if current is not None and not seen_var_in_group and pending_comment:
            current.help = "\n".join(pending_comment).strip()
        pending_comment = []

    for raw in text.splitlines():
        line = raw.rstrip()
        header = GROUP_HEADER.match(line)
        if header:
            flush_group_help()
            current = Group(title=header.group("title").strip())
            groups.append(current)
            seen_var_in_group = False
            pending_comment = []
            continue
        if not line.strip():
            # A blank line ends a comment block. Before the first variable it
            # was the group's help; after one it was a stray comment.
            if current is not None and not seen_var_in_group:
                flush_group_help()
            pending_comment = []
            continue
        if line.lstrip().startswith("#"):
            body = line.lstrip()[1:]
            body = body[1:] if body.startswith(" ") else body
            if current is None:
                preamble_lines.append(line)
            else:
                pending_comment.append(body.rstrip())
            continue
        m = ASSIGNMENT.match(line)
        if not m:
            pending_comment = []
            continue
        name = m.group("name")
        value = _unquote(m.group("value").strip())
        if current is None:
            current = Group(title="Settings")
            groups.append(current)
        if not seen_var_in_group:
            # Comments between the header and the first variable are the
            # group's help, unless the last block sits right against the
            # variable with no blank line and the group already has help.
            if current.help:
                help_text = "\n".join(pending_comment).strip()
            else:
                current.help = "\n".join(pending_comment).strip()
                help_text = ""
        else:
            help_text = "\n".join(pending_comment).strip()
        current.vars.append(Var(name=name, default=value, help=help_text, secret=is_secret_name(name)))
        seen_var_in_group = True
        pending_comment = []

    flush_group_help()
    return Schema(preamble="\n".join(preamble_lines).strip(), groups=groups)


def _unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_env(text: str) -> dict[str, str]:
    """Reads an existing `.env` into a dict. Comments and blanks are ignored;
    unknown keys are kept so a value the schema does not know is never lost."""
    values: dict[str, str] = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export "):]
        m = ASSIGNMENT.match(line)
        if m:
            values[m.group("name")] = _unquote(m.group("value").strip())
    return values


def generate_secret(length: int = 24) -> str:
    """A fresh secret safe to put in `.env` unquoted and to pass through
    docker compose interpolation: letters and digits only, no `$`, no quotes."""
    return "".join(secrets.choice(_SECRET_ALPHABET) for _ in range(length))


def needs_quoting(value: str) -> bool:
    return any(ch in value for ch in " #\"'$`\\") or value != value.strip()


def quote(value: str) -> str:
    if not needs_quoting(value):
        return value
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def render_env(schema: Schema, values: dict[str, str], *, source_name: str = ".env.example",
               ignored: bool = False) -> str:
    """Writes a `.env` in the schema's order with its comments, so the file a
    person opens later reads like the example they would have copied. Keys in
    `values` the schema does not know are kept in a final group. `ignored` is
    whether the caller established that git ignores the file; the header claims
    only what was established."""
    out: list[str] = []
    out.append(f"# Written by tools/setup from {source_name}. Edit here or re-run `make setup`.")
    if ignored:
        out.append("# This file is gitignored. Never commit it.")
    else:
        out.append("# setup could not confirm this file is gitignored. Never commit it.")
    known: set[str] = set()
    for g in schema.groups:
        out.append("")
        out.append(f"# --- {g.title} ---")
        if g.help:
            out.extend(f"# {line}" if line else "#" for line in g.help.splitlines())
        for v in g.vars:
            known.add(v.name)
            if v.help:
                out.extend(f"# {line}" if line else "#" for line in v.help.splitlines())
            out.append(f"{v.name}={quote(values.get(v.name, v.default))}")
    extras = {k: v for k, v in values.items() if k not in known}
    if extras:
        out.append("")
        out.append("# --- Kept from your previous .env (not in .env.example) ---")
        for k in sorted(extras):
            out.append(f"{k}={quote(extras[k])}")
    out.append("")
    return "\n".join(out)


def initial_values(schema: Schema, existing: dict[str, str] | None) -> dict[str, str]:
    """What the form shows: the existing `.env` where there is one, otherwise
    the defaults with every secret replaced by a fresh random value."""
    if existing:
        merged = schema.defaults()
        merged.update(existing)
        return merged
    return {v.name: (generate_secret() if v.secret else v.default) for g in schema.groups for v in g.vars}


def changed_secrets(schema: Schema, before: dict[str, str], after: dict[str, str]) -> list[str]:
    """Secrets whose value changed between two `.env` states. A password baked
    into a database volume or an imported Keycloak realm on first boot does not
    follow a later edit, so the page warns that `make clean` is coming."""
    return [
        v.name
        for g in schema.groups
        for v in g.vars
        if v.secret and v.name in before and before.get(v.name) != after.get(v.name)
    ]
