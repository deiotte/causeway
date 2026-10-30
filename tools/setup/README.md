# tools/setup — `make setup`

Configure, set up and run a project from one local page. No file hunting.

Vendored by the Causeway standard into every project that syncs it (Build DNA §6,
*Configure, set up, run*; ADR 0052). Stdlib Python 3, nothing installed, nothing
leaves the machine.

```
make setup          # open http://127.0.0.1:3999, keep serving
make up             # with no .env yet: opens the same page, continues once you save
make test-setup     # the tool's unit tests (stdlib, no network, no docker)
```

## What it does

1. Reads **`.env.example`** and turns it into a form. A `# --- Title ---` line is a
   group; the comments under it are the group's help; the comment above a variable
   is that variable's help; the default is the prefilled value. A name containing
   `PASSWORD`, `SECRET`, `TOKEN`, `KEY` or `CREDENTIAL` is a secret: masked, with a
   ⟳ generate button, and prefilled with a fresh random value on a machine with no
   `.env`.
2. **Save** writes `.env` in the example's order with its comments, so the file
   still reads like the one you would have copied. Unknown keys from a previous
   `.env` are kept. Save uses an exclusively created mode-600 temporary file in
   the same directory and atomically replaces `.env`; an existing `.env` symlink
   is refused. Before the first secret is written, Save makes sure git will not
   pick the file up: it asks git when git is installed, reads `.gitignore` when
   it is not, and adds `/.env` to `.gitignore` (creating it) when nothing
   ignores it yet. A `.env` git already tracks is refused — an ignore rule cannot
   untrack it — with the commands to fix it and a reminder to rotate what it held.
   The file's header says it is gitignored only when that was established.
3. **Run** buttons start the project's own `make` targets, one at a time, and
   stream the output. The list is read from the Makefile: every target with a
   `## help` comment, or exactly the ones `SETUP_TARGETS := …` names. A target
   whose name is `clean`, `distclean`, `purge`, `nuke` or `destroy`, or whose help
   says it deletes, drops or wipes something, asks first.
4. **Health** shows docker's own view of the project's containers every five
   seconds: green when running, and healthy where the container has a healthcheck.

Add a variable to `.env.example` and it appears on the page. Document a target in
the Makefile and it appears too. There is no second list to maintain.

## Wiring it into a project

Three things, all in the Makefile. `.env.example` needs no change beyond the
`# --- Group ---` headers and comments it should already have.

```make
ENV_FILE    := .env
ENV_EXAMPLE := .env.example

# With no .env, any target that needs one opens the page and continues once it is
# saved. With no terminal (CI, a script) or SETUP_UI=0, copy the example instead.
SETUP_UI ?= 1
$(ENV_FILE):
	@if [ "$(SETUP_UI)" != "0" ] && [ -t 0 ] && command -v python3 >/dev/null 2>&1; then \
	  echo "==> $(ENV_FILE) not found — opening the setup page (SETUP_UI=0 copies $(ENV_EXAMPLE) instead)"; \
	  python3 tools/setup/setup.py --until-saved; \
	else \
	  echo "==> $(ENV_FILE) not found — creating it from $(ENV_EXAMPLE)"; \
	  cp $(ENV_EXAMPLE) $(ENV_FILE); \
	fi

.PHONY: setup test-setup
setup: ## Configure .env in your browser, then start, seed or stop the stack from the same page.
	@python3 tools/setup/setup.py

test-setup: ## Unit tests for the setup page (stdlib, no network).
	@python3 -I -m unittest discover -s tools/setup -p 'test_*.py'

# Optional: only these targets, in this order, on the page.
# SETUP_TARGETS := up wait-ready demo down clean
```

Then make `up` (and anything else that reads `.env`) depend on `$(ENV_FILE)`, and
add `test-setup` to `test`.

## What it is not

- **Not a secrets manager.** It writes one file on your disk, makes sure git ignores it, and nothing
  else. It binds to `127.0.0.1` only and requires a per-session token on every
  write. Every route checks the exact loopback Host and rejects foreign Origin
  headers and cross-site browser requests, including requests that only read
  secrets or logs. Use the printed `127.0.0.1` URL (or `localhost` on that port).
  This does not isolate local users or make an untrusted project safe to run;
  the project directory must not be concurrently modified by another user.
- **Not remote.** Running it on a server and port-forwarding to it is on you.
- **Not needed in CI.** `make up` falls back to copying `.env.example` when there
  is no terminal, or with `SETUP_UI=0`.

## Under `sudo`, over SSH, or with no desktop

The page prints its URL first and only then tries to open a browser, and it does
not try at all when that would fail: as root (`sudo make setup`), over SSH with no
forwarded display, or with no `DISPLAY` / `WAYLAND_DISPLAY`. Open the printed URL
in the browser you already have. `SETUP_NO_BROWSER=1` turns the launch off
everywhere. A browser that does start is launched quietly, so its own warnings
do not bury the one line that matters.

A `.env` written under `sudo` is handed back to the user who typed the command
(`SUDO_UID` / `SUDO_GID`), so the file is theirs and mode `600`, not root's. The
page and the terminal both say who owns it.

## Volumes from a previous run

Docker names volumes after the compose project (`name:` in the compose file, or
`COMPOSE_PROJECT_NAME`), not after the folder you unpacked into. A database and
an imported identity realm keep the passwords they were created with. So a fresh
checkout with a fresh `.env` against volumes from an earlier run fails at the
first service that logs in, with `exited (1)` and nothing on screen to say why.

When there is no `.env` yet and docker still holds volumes for this project, the
page says so above the form, lists them, and offers a checkbox (on by default)
to run `make clean` as part of Save, so the stack is created with the secrets
you just entered. It reports success only when the volumes are actually gone
afterwards; `make clean`'s own exit code is not trusted. The terminal prints the
same note at startup. When docker cannot be asked, the page says nothing.

**Your `clean` target must delete every volume of the project, overlays
included.** `docker compose down -v` only removes volumes declared in the compose
files it was given; load every overlay, then remove whatever still carries the
project's label:

```make
clean: $(ENV_FILE) ## Stop everything and delete every volume of this project.
	$(COMPOSE_ALL_OVERLAYS) down -v --remove-orphans || true
	@vols=$$(docker volume ls -q --filter label=com.docker.compose.project=$(COMPOSE_PROJECT) 2>/dev/null); \
	if [ -n "$$vols" ]; then docker volume rm $$vols; fi
```

## After a secret changes

Databases keep the password they were created with, and an identity provider
that imports a realm on first boot keeps the realm it imported. Changing one of
those on a stack that has already started needs `make clean && make up`. The
page says so when it sees a secret change on an existing `.env`.

## Files

| File | What |
|---|---|
| `env_schema.py` | Pure functions: parse `.env.example`, read `.env`, render `.env`, generate secrets. No I/O. |
| `setup.py` | The server and the page. Stdlib `http.server`, one HTML file inlined. Targets from the Makefile, health from docker. |
| `test_env_schema.py` | `unittest` suite for the parser and writer, plus a round-trip of the project's own `.env.example` when there is one. |
| `test_setup_launch.py` | `unittest` suite for the browser-launch decision, the `sudo` hand-back, target discovery and the health pills. |

The four field reports that shaped this, all from the first adopter: a browser
launched as root with no desktop; a `.env` written as root that its owner could
not read; a fresh `.env` against stale volumes; a `clean` that missed an
overlay's volumes. Each is now a rule above, with a test where one can be written.
