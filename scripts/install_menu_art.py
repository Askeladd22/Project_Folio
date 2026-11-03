"""Safely install the optional illustrated Project Folio menu PNG.

Usage (run from the repository root on Windows):
    python scripts/install_menu_art.py "$env:USERPROFILE\Downloads\ProjectFolio_Illustrated_Menu_Asset.zip"
    python scripts/install_menu_art.py --verify-installed

Does not download files, alter the legacy menu.png or touch save data.
"""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import struct
import sys
import tempfile
import zipfile
import zlib

RELATIVE_ASSET = Path("resources/ui/menu_illustrated.png")
MANUZIO_ASSET = Path("resources/ui/menu_manuzio.png")
MAX_BYTES = 16 * 1024 * 1024
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
WIDTH, HEIGHT = 1920, 1080


class InvalidMenuArt(ValueError):
    pass


def inspect_png(data: bytes) -> tuple[int, int]:
    """Check every PNG chunk and the expected native 16:9 RGB/RGBA format."""
    if not data.startswith(PNG_SIGNATURE) or len(data) > MAX_BYTES:
        raise InvalidMenuArt("Not a PNG, or PNG exceeds 16 MiB")
    offset = len(PNG_SIGNATURE)
    seen_ihdr = False
    seen_idat = False
    seen_iend = False
    width = height = 0
    while offset + 12 <= len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        if length > MAX_BYTES or offset + 12 + length > len(data):
            raise InvalidMenuArt("Truncated or excessive PNG chunk")
        kind = data[offset + 4:offset + 8]
        chunk = data[offset + 8:offset + 8 + length]
        actual_crc = struct.unpack(
            ">I", data[offset + 8 + length:offset + 12 + length]
        )[0]
        if zlib.crc32(kind + chunk) & 0xFFFFFFFF != actual_crc:
            raise InvalidMenuArt(f"PNG CRC mismatch in {kind!r}")
        if not seen_ihdr:
            if kind != b"IHDR" or length != 13:
                raise InvalidMenuArt("PNG must begin with a valid IHDR")
            width, height, bits, color_type, compression, filtering, interlace = (
                struct.unpack(">IIBBBBB", chunk)
            )
            if ((width, height) != (WIDTH, HEIGHT) or bits != 8 or
                    color_type not in (2, 6) or compression != 0 or
                    filtering != 0 or interlace != 0):
                raise InvalidMenuArt(
                    "Expected 1920x1080, 8-bit RGB/RGBA non-interlaced PNG"
                )
            seen_ihdr = True
        if kind == b"IDAT":
            seen_idat = True
        if kind == b"IEND":
            seen_iend = True
            offset += 12 + length
            break
        offset += 12 + length
    if not (seen_ihdr and seen_idat and seen_iend) or offset != len(data):
        raise InvalidMenuArt("Incomplete PNG or trailing unexpected data")
    return width, height


def read_asset(source: Path, relative_asset: Path = RELATIVE_ASSET) -> bytes:
    if not source.is_file():
        raise FileNotFoundError(f"Illustration archive not found: {source}")
    if source.suffix.lower() == ".png":
        data = source.read_bytes()
    elif source.suffix.lower() == ".zip":
        with zipfile.ZipFile(source) as archive:
            name = relative_asset.as_posix()
            if archive.namelist().count(name) != 1:
                raise InvalidMenuArt(f"ZIP must contain exactly one {name}")
            info = archive.getinfo(name)
            mode = (info.external_attr >> 16) & 0o170000
            if info.is_dir() or mode == 0o120000 or info.file_size > MAX_BYTES:
                raise InvalidMenuArt("Unsafe or oversized image entry")
            data = archive.read(info)
            if "MENU_ASSET_README.txt" in archive.namelist():
                note = archive.read("MENU_ASSET_README.txt").decode("utf-8")
                match = re.search(r"SHA-256:\s*([0-9a-fA-F]{64})", note)
                if match and hashlib.sha256(data).hexdigest() != match.group(1).lower():
                    raise InvalidMenuArt("ZIP README SHA-256 does not match PNG")
    else:
        raise InvalidMenuArt("Provide a .zip archive or a direct .png file")
    inspect_png(data)
    return data


def install(source: Path, root: Path, force: bool = False,
            relative_asset: Path = RELATIVE_ASSET) -> tuple[str, str]:
    """Install a single validated file, atomically, under the known path."""
    data = read_asset(source, relative_asset)
    sha = hashlib.sha256(data).hexdigest()
    dest = root / relative_asset
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.is_symlink():
        raise InvalidMenuArt("Refusing to replace a symlink")
    if dest.exists():
        installed_hash = hashlib.sha256(dest.read_bytes()).hexdigest()
        if installed_hash == sha:
            return "already-installed", sha
        if not force:
            raise InvalidMenuArt(
                f"An illustrated PNG already exists at {dest}; "
                "use --force to replace it intentionally"
            )
    temp_name = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", prefix="menu_art_", suffix=".tmp",
            dir=str(dest.parent), delete=False
        ) as temp:
            temp.write(data)
            temp_name = temp.name
        os.replace(temp_name, dest)
        temp_name = None
    finally:
        if temp_name and os.path.exists(temp_name):
            os.unlink(temp_name)
    return "installed", sha


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", nargs="?", type=Path,
                        help="Downloaded ZIP or illustrated PNG")
    parser.add_argument("--verify-installed", action="store_true",
                        help="Check the currently installed optional background")
    parser.add_argument("--manuzio", action="store_true",
                        help="Install/read the Venetian Renaissance workshop asset, not the legacy illustration")
    parser.add_argument("--force", action="store_true",
                        help="Replace an existing different optional PNG")
    parser.add_argument("--repo-root", type=Path,
                        default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    target = MANUZIO_ASSET if args.manuzio else RELATIVE_ASSET
    dest = args.repo_root / target
    try:
        if args.verify_installed:
            if args.source:
                parser.error("--verify-installed does not take a source")
            data = dest.read_bytes()
            size = inspect_png(data)
            print(f"PASS {dest}: {size[0]}x{size[1]}, SHA-256 "
                  f"{hashlib.sha256(data).hexdigest()}")
        elif args.source:
            status, sha = install(args.source, args.repo_root, args.force, target)
            print(f"PASS {status}: {dest} (SHA-256 {sha})")
        else:
            parser.error("Provide the corresponding ProjectFolio_Bottega_Manuzio.zip (--manuzio) or legacy illustrated ZIP")
        return 0
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
