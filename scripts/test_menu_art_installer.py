"""Regression tests for the optional menu illustration installer, no LÖVE/GPU."""
from __future__ import annotations

import hashlib
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile
import zlib

from install_menu_art import (
    HEIGHT, WIDTH, InvalidMenuArt, RELATIVE_ASSET, MANUZIO_ASSET,
    inspect_png, install, read_asset,
)


def chunk(name: bytes, data: bytes) -> bytes:
    payload = name + data
    return (struct.pack(">I", len(data)) + payload +
            struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF))


def sample_png(width: int = WIDTH, height: int = HEIGHT, value: int = 0) -> bytes:
    row = b"\x00" + bytes([value]) * (width * 3)
    pixels = zlib.compress(row * height, 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", pixels)
        + chunk(b"IEND", b"")
    )


def write_zip(path: Path, data: bytes, sha: str | None = None,
              asset: Path = RELATIVE_ASSET) -> None:
    if sha is None:
        sha = hashlib.sha256(data).hexdigest()
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr(asset.as_posix(), data)
        archive.writestr("MENU_ASSET_README.txt", f"SHA-256: {sha}\n")


class MenuArtInstallTests(unittest.TestCase):
    def test_shipping_manuzio_image_is_checked_in_at_the_runtime_path(self):
        root = Path(__file__).resolve().parents[1]
        image = root / MANUZIO_ASSET
        self.assertTrue(image.is_file(),
                        "Shipping Manuzio image missing from loader path")
        # Detect the exact regression caused by placing an otherwise
        # correct PNG under its descriptive export filename.
        self.assertFalse(
            (root / "resources/ui/ProjectFolio_Manuzio_Bottega_1920x1080.png").exists(),
            "Illustration exported under the wrong runtime filename",
        )
        data = image.read_bytes()
        self.assertEqual(inspect_png(data), (WIDTH, HEIGHT))
        self.assertEqual(
            hashlib.sha256(data).hexdigest(),
            "65e6748253a54dc58486b73cd3cea1a772e8a033509baaf1243240bcaa858d15",
            "Shipping PNG is not the approved Aldine printshop illustration",
        )


    def test_installs_exactly_one_validated_png_without_modifying_legacy(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            zip_path = root / "asset.zip"
            image = sample_png()
            write_zip(zip_path, image)
            legacy = root / "resources/ui/menu.png"
            legacy.parent.mkdir(parents=True)
            legacy.write_bytes(b"legacy")
            status, digest = install(zip_path, root)
            self.assertEqual(status, "installed")
            self.assertEqual(digest, hashlib.sha256(image).hexdigest())
            self.assertEqual((root / RELATIVE_ASSET).read_bytes(), image)
            self.assertEqual(legacy.read_bytes(), b"legacy")
            self.assertEqual(install(zip_path, root)[0], "already-installed")

    def test_refuses_implicit_overwrite_but_supports_force(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            first = root / "first.png"
            second = root / "second.png"
            first.write_bytes(sample_png(value=0))
            second.write_bytes(sample_png(value=1))
            install(first, root)
            with self.assertRaisesRegex(InvalidMenuArt, "use --force"):
                install(second, root)
            self.assertEqual((root / RELATIVE_ASSET).read_bytes(), first.read_bytes())
            self.assertEqual(install(second, root, force=True)[0], "installed")
            self.assertEqual((root / RELATIVE_ASSET).read_bytes(), second.read_bytes())

    def test_wrong_size_or_png_crc_cannot_be_installed(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            bad_size = root / "bad.png"
            bad_size.write_bytes(sample_png(width=1280, height=720))
            with self.assertRaisesRegex(InvalidMenuArt, "1920x1080"):
                install(bad_size, root)
            bad_crc = root / "badcrc.png"
            corrupted = bytearray(sample_png())
            corrupted[25] ^= 1
            bad_crc.write_bytes(corrupted)
            with self.assertRaisesRegex(InvalidMenuArt, "CRC mismatch"):
                install(bad_crc, root)
            self.assertFalse((root / RELATIVE_ASSET).exists())

    def test_zip_missing_png_or_bad_readme_sha(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            missing = root / "missing.zip"
            with zipfile.ZipFile(missing, "w") as archive:
                archive.writestr("other.png", sample_png())
            with self.assertRaisesRegex(InvalidMenuArt, "exactly one"):
                read_asset(missing)
            wrong_hash = root / "wrong.zip"
            write_zip(wrong_hash, sample_png(), sha="0" * 64)
            with self.assertRaisesRegex(InvalidMenuArt, "SHA-256"):
                read_asset(wrong_hash)
            self.assertFalse((root / RELATIVE_ASSET).exists())

    def test_manuzio_installs_separately_and_preserves_both_older_backgrounds(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            original = root / "resources/ui/menu.png"
            original.parent.mkdir(parents=True)
            original.write_bytes(b"original")
            earlier = root / RELATIVE_ASSET
            earlier.write_bytes(b"old illustrated image")
            archive_path = root / "manuzio.zip"
            image = sample_png(value=77)
            write_zip(archive_path, image, asset=MANUZIO_ASSET)
            status, _ = install(archive_path, root, relative_asset=MANUZIO_ASSET)
            self.assertEqual(status, "installed")
            self.assertEqual((root / MANUZIO_ASSET).read_bytes(), image)
            self.assertEqual(earlier.read_bytes(), b"old illustrated image")
            self.assertEqual(original.read_bytes(), b"original")
            self.assertEqual(install(archive_path,root,
                                     relative_asset=MANUZIO_ASSET)[0],
                             "already-installed")
            with self.assertRaisesRegex(InvalidMenuArt, "exactly one"):
                read_asset(archive_path, RELATIVE_ASSET)

    def test_reads_unchanged_png_and_rejects_invalid_trailing_bytes(self):
        data = sample_png()
        self.assertEqual(inspect_png(data), (1920, 1080))
        with self.assertRaisesRegex(InvalidMenuArt, "trailing"):
            inspect_png(data + b"garbage")


if __name__ == "__main__":
    unittest.main()
