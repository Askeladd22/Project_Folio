"""Pure, GPU-free tests of the current UI V2 screenshot inventory."""
from __future__ import annotations
import tempfile
from pathlib import Path
import struct
import unittest
import zlib

from capture_ui_v2_review import SCENES, SIZES, collect_frames, png_dimensions, report_html, review_checklist


def png_chunk(kind: bytes, contents: bytes) -> bytes:
    data = kind + contents
    return (struct.pack(">I", len(contents)) + data +
            struct.pack(">I", zlib.crc32(data) & 0xFFFFFFFF))


def stub_png(path: Path, w: int, h: int) -> None:
    """Small structurally valid PNG with the test dimensions in IHDR."""
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00"))
        + png_chunk(b"IEND", b"")
    )


class UiReviewManifestTests(unittest.TestCase):
    def test_scene_inventory_is_unique_and_covers_required_views(self):
        self.assertEqual(len(SCENES), len(set(SCENES)))
        self.assertGreaterEqual(len(SCENES), 15)
        for scene in (
            "physical-group-held", "accessibility-on", "help",
            "choices-fixture", "upgrade-fixture", "medal-fixture",
            "folio", "monk-live",
        ):
            self.assertIn(scene, SCENES)

    def test_validates_every_real_png_and_checksum(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hud = root / "hud"
            hud.mkdir()
            for prefix, w, h in SIZES:
                for scene in SCENES:
                    stub_png(hud / f"hud-usability-{prefix}-{scene}.png", w, h)
            frames = collect_frames(root)
            self.assertEqual(len(frames), len(SIZES) * len(SCENES))
            self.assertEqual(len({x["sha256"] for x in frames}), len(SIZES))
            self.assertTrue(all(x["bytes"] > 45 for x in frames))
            self.assertFalse("manual_visual_qa_approved" in str(frames))
            gallery = report_html(frames, "abc123")
            self.assertIn("non ancora approvate visivamente", gallery)
            self.assertIn("hud-usability-1920-monk-live.png", gallery)
            checklist = review_checklist("abc123")
            self.assertIn("DA VERIFICARE SU WINDOWS", checklist)

            missing = hud / f"hud-usability-1280-{SCENES[0]}.png"
            missing.unlink()
            with self.assertRaises(FileNotFoundError):
                collect_frames(root)

    def test_rejects_bad_png_and_wrong_resolution(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / "frame.png"
            file.write_bytes(b"not a screenshot")
            with self.assertRaises(ValueError):
                png_dimensions(file)
            stub_png(file, 1280, 720)
            self.assertEqual(png_dimensions(file), (1280, 720))
            file.write_bytes(file.read_bytes()[:-12])
            with self.assertRaises(ValueError):
                png_dimensions(file)


if __name__ == "__main__":
    unittest.main()
