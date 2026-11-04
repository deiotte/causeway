"""Tests for the Recon intake page (ADR 0056).

    python3 -I -m unittest discover -s tools/recon -p 'test_*.py'

The page's logic lives in one <script id="core"> with no DOM in it, so it runs
under node exactly as it runs in a browser. The node tests skip with a reason
when node is absent; the structural tests never skip.
"""
import json
import pathlib
import re
import shutil
import subprocess
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
PAGE = HERE / "recon.html"
TEMPLATE = ROOT / "templates" / "recon.md"
sys.path.insert(0, str(HERE))
import build_page  # noqa: E402

HARNESS = r"""
const fs = require("fs");
const html = fs.readFileSync(process.argv[process.argv.length - 1], "utf8");
const core = /<script id="core">([\s\S]*?)<\/script>/.exec(html)[1];
const tpl = JSON.parse(/<script id="template" type="application\/json">([\s\S]*?)<\/script>/.exec(html)[1]);
const mod = { exports: {} };
new Function("module", core)(mod);
const C = mod.exports;
const out = {};

const blank = C.parse(tpl);
out.blank = C.render(blank);
out.blankUnfilled = C.unfilled(out.blank);

const m = C.parse(tpl);
const slots = b => (b.segs || []).filter(s => s.t === "slot");
const title = m.blocks.find(b => b.kind === "line" && b.segs[0].v.startsWith("# "));
slots(title)[0].value = "Permit Backlog";
const area = m.blocks.find(b => b.kind === "area");
area.value = "Permits take 5 days.\n\nWe start mapping the queue.";
const choice = m.blocks.find(b => b.kind === "choice");
choice.value = "No-go";
const pn = m.blocks.find(b => b.kind === "table" && b.rows.length && b.rows[0][0].v === "PN-1");
pn.rows[0][1].segs[0].value = "intake | triage handoff";
pn.rows[0][4].value = "measured";
const added = C.addRow(pn);
out.addedId = added[0].v;
const blankAdded = C.addRow(pn);
out.secondAddedId = blankAdded[0].v;
added[1].value = "rework on line\nbreaks";
out.filled = C.render(m);
out.filledUnfilled = C.unfilled(out.filled);
out.project = C.projectName(m);
out.preamble = C.AI_PREAMBLE;
console.log(JSON.stringify(out));
"""


def node_results():
    node = shutil.which("node")
    if not node:
        raise unittest.SkipTest("node not installed; the core logic is not exercised here")
    proc = subprocess.run([node, "-", str(PAGE)], input=HARNESS, capture_output=True, text=True, timeout=60)
    if proc.returncode != 0:
        raise AssertionError("node harness failed:\n" + proc.stderr)
    return json.loads(proc.stdout)


class PageIsBuiltFromTheTemplate(unittest.TestCase):
    def test_page_is_current(self):
        self.assertEqual(PAGE.read_text(encoding="utf-8"), build_page.build(),
                         "recon.html is stale: run python3 tools/recon/build_page.py")

    def test_embedded_template_is_the_template(self):
        html = PAGE.read_text(encoding="utf-8")
        raw = re.search(r'<script id="template" type="application/json">(.*?)</script>', html, re.S).group(1)
        self.assertEqual(json.loads(raw), TEMPLATE.read_text(encoding="utf-8"))

    def test_page_reaches_nothing(self):
        html = PAGE.read_text(encoding="utf-8")
        self.assertNotRegex(html, r'(?i)(src|href)\s*=\s*["\']?(https?:)?//', "page loads an external resource")
        self.assertNotRegex(html, r"(?i)@import|url\(\s*['\"]?https?:", "page loads an external stylesheet")
        self.assertNotRegex(html, r"(?i)\bfetch\(|XMLHttpRequest|navigator\.sendBeacon|new WebSocket", "page makes a network call")

    def test_template_tables_are_rectangular(self):
        rows = [l for l in TEMPLATE.read_text(encoding="utf-8").splitlines() if l.startswith("|")]
        block, widths = [], []
        lines = TEMPLATE.read_text(encoding="utf-8").splitlines() + [""]
        for line in lines:
            if line.startswith("|"):
                block.append(len(re.split(r"(?<!\\)\|", line.strip().strip("|"))))
            elif block:
                widths.append(block)
                block = []
        self.assertTrue(rows)
        for w in widths:
            self.assertEqual(len(set(w)), 1, f"a template table has ragged rows: {w}")


class CoreLogic(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.r = node_results()

    def test_guidance_is_left_out_of_the_record(self):
        self.assertFalse([l for l in self.r["blank"].splitlines() if l.startswith(">")])

    def test_every_section_heading_survives(self):
        headings = [l for l in TEMPLATE.read_text(encoding="utf-8").splitlines() if l.startswith("## ")]
        for h in headings:
            self.assertIn(h, self.r["blank"])

    def test_unfilled_prompts_stay_visible_and_are_counted(self):
        self.assertIn("{{PROJECT}}", self.r["blank"])
        self.assertGreater(self.r["blankUnfilled"], 20)
        self.assertLess(self.r["filledUnfilled"], self.r["blankUnfilled"])

    def test_empty_example_rows_are_dropped(self):
        self.assertNotIn("| PN-2 |", self.r["blank"])
        self.assertIn("| PN-1 |", self.r["blank"])

    def test_the_easter_egg_rides_along(self):
        self.assertIn("Unit 60460", self.r["blank"])

    def test_filled_values_land_and_pipes_are_escaped(self):
        f = self.r["filled"]
        self.assertIn("# RECON — Permit Backlog", f)
        self.assertIn("intake \\| triage handoff", f)
        self.assertIn("| measured |", f)
        self.assertEqual(self.r["project"], "Permit Backlog")

    def test_a_cell_never_breaks_its_table_row(self):
        self.assertIn("rework on line breaks", self.r["filled"])

    def test_paragraphs_survive_in_free_text(self):
        self.assertIn("Permits take 5 days.\n\nWe start mapping the queue.", self.r["filled"])

    def test_choice_marks_the_selection(self):
        self.assertIn("☐ Go ☐ Go with conditions ☐ Reframe ☒ No-go", self.r["filled"])

    def test_added_rows_continue_the_id_sequence(self):
        # PN-2 exists in the template, empty, so the first added row is PN-3.
        self.assertEqual(self.r["addedId"], "PN-3")
        self.assertEqual(self.r["secondAddedId"], "PN-4")
        self.assertIn("| PN-3 |", self.r["filled"])
        self.assertNotIn("| PN-4 |", self.r["filled"])

    def test_ai_preamble_forbids_invention_and_renumbering(self):
        p = self.r["preamble"]
        self.assertIn("Do not invent answers", p)
        self.assertIn("never renumber", p)


if __name__ == "__main__":
    unittest.main()
