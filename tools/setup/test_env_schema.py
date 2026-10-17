"""Unit tests for env_schema. Stdlib unittest, no filesystem, no network.

    python3 -m unittest discover -s tools/setup -p 'test_*.py'
"""

from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))

import env_schema as es  # noqa: E402

EXAMPLE = """\
# ──────────────────────────────
# DISE — secrets & configuration contract
#
#   cp .env.example .env
# ──────────────────────────────

# --- Database passwords (one per Postgres instance) ---
CATALOG_DB_PASSWORD=catalog-db-dev-Hq3v
PARTICIPANT_ALPHA_DB_PASSWORD=alpha-db-dev-Kp7w

# --- OIDC service-account client secrets ---
# These are read by Keycloak at realm import and by the services that
# authenticate with them.
PARTICIPANT_NODE_CLIENT_SECRET=pn-bootstrap-dev-Df2k
# Catalog's service-account secret — used ONLY by the mTLS overlay.
CATALOG_CLIENT_SECRET=catalog-dev-Wn4r

# --- Demo BOLO emitter (alerting demo; not a secret) ---
# Alpha and Bravo each publish a signed BOLO on a fixed cadence.
BOLO_SCHEDULER_ENABLED=true
BOLO_SCHEDULER_INTERVAL_MS=300000

# --- Host port overrides ---
CATALOG_HOST_PORT=8085
"""


class ParseExampleTest(unittest.TestCase):
    def setUp(self):
        self.schema = es.parse_example(EXAMPLE)

    def test_groups_come_from_dashed_headers_in_order(self):
        self.assertEqual(
            [g.title for g in self.schema.groups],
            [
                "Database passwords (one per Postgres instance)",
                "OIDC service-account client secrets",
                "Demo BOLO emitter (alerting demo; not a secret)",
                "Host port overrides",
            ],
        )

    def test_preamble_is_kept_out_of_groups(self):
        self.assertIn("secrets & configuration contract", self.schema.preamble)
        self.assertEqual(self.schema.names()[0], "CATALOG_DB_PASSWORD")

    def test_group_help_is_the_comment_block_after_the_header(self):
        oidc = self.schema.groups[1]
        self.assertTrue(oidc.help.startswith("These are read by Keycloak"))
        self.assertEqual(oidc.vars[0].help, "")

    def test_var_help_is_the_comment_block_directly_above_it(self):
        catalog = self.schema.var("CATALOG_CLIENT_SECRET")
        self.assertIsNotNone(catalog)
        self.assertIn("mTLS overlay", catalog.help)

    def test_defaults_and_secret_detection(self):
        self.assertEqual(self.schema.var("CATALOG_HOST_PORT").default, "8085")
        self.assertTrue(self.schema.var("CATALOG_DB_PASSWORD").secret)
        self.assertTrue(self.schema.var("PARTICIPANT_NODE_CLIENT_SECRET").secret)
        self.assertFalse(self.schema.var("BOLO_SCHEDULER_ENABLED").secret)
        self.assertFalse(self.schema.var("CATALOG_HOST_PORT").secret)

    def test_the_projects_own_example_file_parses_and_every_variable_lands_in_a_group(self):
        # Runs against the repository this tool is vendored into. The standard
        # itself has no .env.example, so it is skipped there and real everywhere
        # else: a project whose example stops parsing finds out in its own CI.
        here = os.path.dirname(os.path.abspath(__file__))
        path = os.path.join(here, "..", "..", ".env.example")
        if not os.path.exists(path):
            self.skipTest("no .env.example at the repository root")
        with open(path, encoding="utf-8") as f:
            text = f.read()
        schema = es.parse_example(text)
        assigned = {m.group("name") for m in map(es.ASSIGNMENT.match, text.splitlines()) if m}
        self.assertEqual(set(schema.names()), assigned)
        self.assertTrue(schema.groups)


class EnvRoundTripTest(unittest.TestCase):
    def setUp(self):
        self.schema = es.parse_example(EXAMPLE)

    def test_parse_env_reads_assignments_and_ignores_comments(self):
        text = "# hi\nA=1\nexport B=two words\nC=\"quoted # not a comment\"\n\nnot an assignment\n"
        self.assertEqual(es.parse_env(text), {"A": "1", "B": "two words", "C": "quoted # not a comment"})

    def test_render_then_parse_is_identity_for_known_and_unknown_keys(self):
        values = self.schema.defaults()
        values["CATALOG_DB_PASSWORD"] = "has a space and a # hash"
        values["MY_EXTRA"] = "kept"
        text = es.render_env(self.schema, values)
        self.assertEqual(es.parse_env(text), values)
        self.assertIn("# --- Kept from your previous .env", text)
        self.assertIn("# --- Host port overrides ---", text)

    def test_render_keeps_help_comments_so_the_file_reads_like_the_example(self):
        text = es.render_env(self.schema, self.schema.defaults())
        self.assertIn("# Catalog's service-account secret", text)
        self.assertIn("# These are read by Keycloak", text)
        self.assertIn("Never commit it", text)

    def test_quoting_only_when_needed(self):
        self.assertEqual(es.quote("plain-value_1"), "plain-value_1")
        self.assertEqual(es.quote("with space"), '"with space"')
        self.assertEqual(es.quote('say "hi"'), '"say \\"hi\\""')
        self.assertEqual(es.quote("a$b"), '"a$b"')


class ValuesTest(unittest.TestCase):
    def setUp(self):
        self.schema = es.parse_example(EXAMPLE)

    def test_generated_secrets_are_long_random_and_compose_safe(self):
        a, b = es.generate_secret(), es.generate_secret()
        self.assertNotEqual(a, b)
        self.assertEqual(len(a), 24)
        self.assertTrue(all(ch.isalnum() for ch in a))
        self.assertFalse(es.needs_quoting(a))

    def test_first_run_prefills_fresh_secrets_and_committed_non_secret_defaults(self):
        values = es.initial_values(self.schema, None)
        self.assertNotEqual(values["CATALOG_DB_PASSWORD"], "catalog-db-dev-Hq3v")
        self.assertEqual(values["CATALOG_HOST_PORT"], "8085")
        self.assertEqual(values["BOLO_SCHEDULER_ENABLED"], "true")

    def test_existing_env_wins_and_new_variables_get_defaults(self):
        existing = {"CATALOG_DB_PASSWORD": "mine", "MY_EXTRA": "kept"}
        values = es.initial_values(self.schema, existing)
        self.assertEqual(values["CATALOG_DB_PASSWORD"], "mine")
        self.assertEqual(values["CATALOG_HOST_PORT"], "8085")
        self.assertEqual(values["MY_EXTRA"], "kept")

    def test_changed_secrets_names_only_secrets_that_actually_changed(self):
        before = self.schema.defaults()
        after = dict(before)
        after["CATALOG_DB_PASSWORD"] = "rotated"
        after["CATALOG_HOST_PORT"] = "9999"
        self.assertEqual(es.changed_secrets(self.schema, before, after), ["CATALOG_DB_PASSWORD"])
        self.assertEqual(es.changed_secrets(self.schema, {}, after), [])


if __name__ == "__main__":
    unittest.main()
