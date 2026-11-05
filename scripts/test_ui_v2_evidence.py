"""Headless tests: a partial Git upload must NEVER look like a complete QA."""
from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from capture_ui_v2_review import SCENES, SIZES, collect_frames, report_html
from package_ui_v2_review import (
    IncompleteCapture, package_capture, required_capture_files, verify_capture
)
from test_ui_v2_review import png_chunk, stub_png


def fixture(root: Path) -> None:
    hud = root / "hud"
    hud.mkdir()
    for label, width, height in SIZES:
        for scene in SCENES:
            stem = f"hud-usability-{label}-{scene}"
            stub_png(hud / (stem + ".png"), width, height)
            (hud / (stem + ".hitboxes.tsv")).write_text(
                "id\tx\ty\tw\th\tenabled\tsource\n"
                "roll\t100\t30\t180\t50\t1\tgame\n"
                f"__tray__\t50\t200\t{width - 100}\t{height - 250}\t0\ttray\n",
                encoding="utf-8",
            )
    frames = collect_frames(root)
    (root / "review-manifest.json").write_text(json.dumps({
        "project": "Project Folio",
        "commit": "a" * 40,
        "actual_love_runtime": True,
        "smoke_log": "hud/hud-smoke.log",
        "resolutions": [f"{w}x{h}" for _, w, h in SIZES],
        "frames": frames,
    }), encoding="utf-8")
    (root / "gallery.html").write_text(report_html(frames, "a" * 40),
                                       encoding="utf-8")
    (root / "review-checklist.md").write_text(
        "Stato: DA VERIFICARE SU WINDOWS\n- [ ] Esito visivo\n",
        encoding="utf-8",
    )
    (hud / "hud-smoke.log").write_text(
        "PASS current UI V2 visual review at both resolutions\n"
        + "".join(f"PASS hud-usability-{size}- {marker}\n"
                  for size, _, _ in SIZES
                  for marker in ("physically grabbed 6 D6",
                                 "UI V2 accessibility flags restored")),
        encoding="utf-8",
    )


class EvidenceBundleTests(unittest.TestCase):
    def test_complete_evidence_is_verified_and_packaged_without_appdata(self):
        with tempfile.TemporaryDirectory() as tmp:
            # Use the real folder shape but no local LÖVE runtime.
            root = Path(tmp) / "20261103-084723-aaaaaaaa"
            root.mkdir()
            fixture(root)
            (root / "hud" / "appdata").mkdir()
            (root / "hud" / "appdata" / "sensitive.txt").write_text("exclude")
            source_files = verify_capture(root)
            self.assertEqual(len(source_files), len(SIZES)*len(SCENES)*2 + 4)
            bundle = package_capture(root)
            self.assertEqual(bundle.parent, root.parent)
            with zipfile.ZipFile(bundle) as z:
                names = z.namelist()
                self.assertEqual(len(names), len(source_files)+1)
                self.assertTrue(all(n.startswith(root.name + "/") for n in names))
                self.assertFalse(any("appdata" in n for n in names))
                index = json.loads(z.read(root.name + "/evidence-index.json"))
                self.assertEqual(index["file_count"], 68)
                self.assertFalse(index["visual_qa_automatically_approved"])
                self.assertEqual(len(index["files"]), 68)
                self.assertIn(root.name + "/review-checklist.md", names)

    def test_partial_18_frames_fails_and_does_not_create_a_zip(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "capture"
            root.mkdir()
            fixture(root)
            for scene in SCENES:
                if scene not in ("fresh", "marquee-six"):
                    for suffix in (".png", ".hitboxes.tsv"):
                        (root / "hud" / f"hud-usability-1280-{scene}{suffix}").unlink()
            with self.assertRaisesRegex(IncompleteCapture, "28 missing files"):
                package_capture(root)
            self.assertFalse((root.parent / "capture-evidence.zip").exists())

    def test_modified_png_must_not_pass_a_manifest_checksum(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "capture"
            root.mkdir()
            fixture(root)
            file = root / "hud" / "hud-usability-1920-fresh.png"
            original = file.read_bytes()
            # A valid additional PNG tEXt chunk changes only the checksum.
            file.write_bytes(original[:-12] + png_chunk(b"tEXt", b"qa=tamper") + original[-12:])
            with self.assertRaisesRegex(IncompleteCapture, "differs from manifest"):
                verify_capture(root)

    def test_missing_log_or_bad_manifest_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "capture"
            root.mkdir()
            fixture(root)
            (root / "hud" / "hud-smoke.log").unlink()
            with self.assertRaisesRegex(IncompleteCapture, "hud-smoke.log"):
                verify_capture(root)
            (root / "hud" / "hud-smoke.log").write_text("PASS fake\n")
            with self.assertRaisesRegex(IncompleteCapture, "real LÖVE review marker"):
                verify_capture(root)

    def test_schema_lists_all_screenshot_pairs_and_original_reports(self):
        files = required_capture_files()
        self.assertEqual(len(files), 68)
        self.assertIn("hud/hud-usability-1280-merchant-live.png", files)
        self.assertIn("hud/hud-usability-1920-merchant-live.hitboxes.tsv", files)
        self.assertIn("review-manifest.json", files)


if __name__ == "__main__":
    unittest.main()
