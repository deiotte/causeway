"""Unit tests for the parts of setup.py that decide things without serving:
whether to launch a browser, and who owns a `.env` written under sudo."""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))

import setup  # noqa: E402

DESKTOP = {"DISPLAY": ":0", "HOME": "/home/karl"}


class BrowserLaunchDecisionTest(unittest.TestCase):
    def test_a_normal_desktop_session_launches(self):
        self.assertEqual(setup.browser_launch_decision(DESKTOP, 1000, "linux"), (True, ""))

    def test_root_never_launches_and_says_why(self):
        launch, why = setup.browser_launch_decision(DESKTOP, 0, "linux")
        self.assertFalse(launch)
        self.assertIn("root", why)

    def test_sudo_is_detected_even_when_euid_is_not_zero(self):
        env = dict(DESKTOP, SUDO_USER="sdadmin")
        self.assertFalse(setup.browser_launch_decision(env, 1000, "linux")[0])

    def test_no_display_on_linux_does_not_launch(self):
        self.assertFalse(setup.browser_launch_decision({"HOME": "/home/karl"}, 1000, "linux")[0])
        self.assertTrue(setup.browser_launch_decision({"WAYLAND_DISPLAY": "wayland-0"}, 1000, "linux")[0])

    def test_macos_needs_no_display_variable(self):
        self.assertTrue(setup.browser_launch_decision({"HOME": "/Users/karl"}, 501, "darwin")[0])

    def test_ssh_without_forwarded_display_does_not_launch(self):
        env = {"SSH_CONNECTION": "1 2 3 4", "WAYLAND_DISPLAY": "wayland-0"}
        self.assertFalse(setup.browser_launch_decision(env, 1000, "linux")[0])

    def test_opt_out_variable(self):
        self.assertFalse(setup.browser_launch_decision(dict(DESKTOP, SETUP_NO_BROWSER="1"), 1000, "linux")[0])
        self.assertTrue(setup.browser_launch_decision(dict(DESKTOP, SETUP_NO_BROWSER="0"), 1000, "linux")[0])


class ComposeProjectNameTest(unittest.TestCase):
    COMPOSE = "services:\n  a: {}\n"

    def test_environment_override_wins(self):
        self.assertEqual(setup.compose_project_name("", "name: dise\n", {"COMPOSE_PROJECT_NAME": "x"}, "Repo"), "x")

    def test_top_level_name_in_the_compose_file(self):
        self.assertEqual(setup.compose_project_name("", "name: cjis-federation\nservices: {}\n", {}, "Repo"), "cjis-federation")
        self.assertEqual(setup.compose_project_name("", 'name: "quoted"\n', {}, "Repo"), "quoted")

    def test_falls_back_to_the_directory_name_lowercased(self):
        self.assertEqual(setup.compose_project_name("", self.COMPOSE, {}, "DISE-main"), "dise-main")

    def test_compose_file_path_comes_from_the_makefile(self):
        self.assertEqual(
            setup.compose_file_path("COMPOSE_FILE  := infrastructure/compose/docker-compose.yml\n"),
            setup.REPO_ROOT / "infrastructure/compose/docker-compose.yml",
        )
        self.assertEqual(setup.compose_file_path(""), setup.REPO_ROOT / "docker-compose.yml")

    def test_the_repository_this_runs_in_resolves_to_some_project(self):
        prev = setup.detect_previous_run()
        self.assertIsInstance(prev["project"], str)
        self.assertTrue(prev["project"])
        self.assertIn(type(prev["volumes"]), (list, type(None)))


MAKEFILE = """\
.PHONY: up
up: $(ENV_FILE) ## Start the stack (rebuilds changed images).
\t$(COMPOSE) up -d --build

wait-ready: ## Wait until every service reports ready.
\tbash tools/wait-ready.sh

build-java:
\tmvn -q package

down: $(ENV_FILE) ## Stop containers (volumes kept).
\t$(COMPOSE) down

clean: $(ENV_FILE) ## Stop everything and delete every volume of this project.
\t$(COMPOSE) down -v

reset-db: ## Drops and recreates the database; all rows are deleted.
\tbash tools/reset-db.sh
"""


class DiscoverTargetsTest(unittest.TestCase):
    def test_documented_targets_in_makefile_order_with_their_help(self):
        ts = setup.discover_targets(MAKEFILE)
        self.assertEqual([t.id for t in ts], ["up", "wait-ready", "down", "clean", "reset-db"])
        self.assertEqual(ts[0].label, "make up")
        self.assertEqual(ts[1].desc, "Wait until every service reports ready.")

    def test_undocumented_targets_are_not_offered(self):
        self.assertNotIn("build-java", [t.id for t in setup.discover_targets(MAKEFILE)])

    def test_destructive_by_name_or_by_what_the_help_says(self):
        by_id = {t.id: t for t in setup.discover_targets(MAKEFILE)}
        self.assertTrue(by_id["clean"].destructive)
        self.assertTrue(by_id["reset-db"].destructive)
        self.assertFalse(by_id["down"].destructive)
        self.assertFalse(by_id["up"].destructive)

    def test_setup_targets_variable_picks_and_orders(self):
        ts = setup.discover_targets("SETUP_TARGETS := down up build-java\n" + MAKEFILE)
        self.assertEqual([t.id for t in ts], ["down", "up", "build-java"])
        self.assertEqual(ts[1].desc, "Start the stack (rebuilds changed images).")
        self.assertEqual(ts[2].desc, "")

    def test_no_makefile_means_no_targets(self):
        self.assertEqual(setup.discover_targets(""), [])


class ContainerStatusTest(unittest.TestCase):
    def test_rows_become_pills_with_docker_health_semantics(self):
        text = (
            "keycloak\trunning\tUp 3 minutes (healthy)\n"
            "catalog\trunning\tUp 3 minutes (health: starting)\n"
            "nats\trunning\tUp 3 minutes\n"
            "participant-node-marlow\texited\tExited (1) 2 minutes ago\n"
            "\n"
            "malformed line\n"
        )
        rows = setup.parse_container_status(text)
        self.assertEqual([r["name"] for r in rows], ["catalog", "keycloak", "nats", "participant-node-marlow"])
        up = {r["name"]: r["up"] for r in rows}
        self.assertEqual(up, {"keycloak": True, "catalog": False, "nats": True, "participant-node-marlow": False})
        self.assertEqual(rows[3]["state"], "exited")

    def test_empty_output_is_an_empty_list_not_none(self):
        self.assertEqual(setup.parse_container_status(""), [])


class HandBackToInvokingUserTest(unittest.TestCase):
    def test_without_sudo_nothing_happens(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / ".env"
            f.write_text("A=1\n")
            self.assertIsNone(setup.hand_back_to_invoking_user(f, {}))
            self.assertIsNone(setup.hand_back_to_invoking_user(f, {"SUDO_UID": "x", "SUDO_GID": "1000"}))

    def test_under_sudo_as_root_the_file_is_chowned_to_the_caller(self):
        if not hasattr(os, "geteuid") or os.geteuid() != 0:
            self.skipTest("needs root to chown")
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / ".env"
            f.write_text("A=1\n")
            env = {"SUDO_UID": str(os.getuid()), "SUDO_GID": str(os.getgid()), "SUDO_USER": "me"}
            self.assertEqual(setup.hand_back_to_invoking_user(f, env), "me")


if __name__ == "__main__":
    unittest.main()
