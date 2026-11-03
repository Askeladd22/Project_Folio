"""Validate and package a complete, actual LÖVE UI V2 capture for review.

Requires ALL 32 real PNGs, their 32 live controller TSVs, and the
original generated manifest, gallery, checklist and smoke log.
Never synthesizes missing frames, claims visual QA or includes APPDATA.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import zipfile

from capture_ui_v2_review import SCENES, SIZES, collect_frames, fingerprint


REVIEW_FILES = (
    "gallery.html",
    "review-manifest.json",
    "review-checklist.md",
    "hud/hud-smoke.log",
)


class IncompleteCapture(ValueError):
    """One or more original artifacts are missing, inconsistent or altered."""


def required_capture_files() -> list[str]:
    files = list(REVIEW_FILES)
    for size, _, _ in SIZES:
        for scene in SCENES:
            stem = f"hud/hud-usability-{size}-{scene}"
            files.extend((stem + ".png", stem + ".hitboxes.tsv"))
    return sorted(files)


def verify_capture(folder: Path) -> list[str]:
    """Validate source files in-place; does not alter screenshots or checklists."""
    root = Path(folder).resolve()
    if not root.is_dir():
        raise IncompleteCapture(f"Capture directory not found: {root}")

    files = required_capture_files()
    missing = [name for name in files if not (root / name).is_file()]
    if missing:
        raise IncompleteCapture(
            f"Incomplete UI V2 capture: {len(missing)} missing files\n"
            + "\n".join("  MISSING " + name for name in missing)
            + "\nNo evidence archive was created."
        )
    for name in files:
        if (root / name).is_symlink():
            raise IncompleteCapture(f"Evidence file is a symlink: {name}")

    try:
        manifest = json.loads((root / "review-manifest.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise IncompleteCapture(f"Invalid capture manifest: {exc}") from exc
    if not isinstance(manifest, dict) or manifest.get("actual_love_runtime") is not True:
        raise IncompleteCapture("Manifest does not attest an actual LÖVE runtime capture")
    commit = manifest.get("commit")
    if not isinstance(commit, str) or not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise IncompleteCapture("Manifest does not contain a full source commit SHA")
    if manifest.get("smoke_log") != "hud/hud-smoke.log":
        raise IncompleteCapture("Manifest smoke log path does not match expected capture")
    if manifest.get("resolutions") != [f"{w}x{h}" for _, w, h in SIZES]:
        raise IncompleteCapture("Manifest resolution set differs from capture schema")

    # collect_frames verifies actual PNG headers/dimensions and the exported
    # TSV geometry, not just filenames or GitHub metadata.
    frames = collect_frames(root)
    listed = manifest.get("frames")
    if not isinstance(listed, list) or len(listed) != len(frames):
        raise IncompleteCapture(f"Manifest must contain {len(frames)} captured frames")
    by_path = {item.get("path"): item for item in listed if isinstance(item, dict)}
    if len(by_path) != len(frames):
        raise IncompleteCapture("Manifest has duplicate or invalid screenshot paths")
    for frame in frames:
        entry = by_path.get(frame["path"])
        if not entry:
            raise IncompleteCapture(f"Missing manifest frame: {frame['path']}")
        for key in ("sha256", "bytes", "hitbox_path", "resolution", "scene", "hitboxes"):
            if entry.get(key) != frame[key]:
                raise IncompleteCapture(
                    f"Captured evidence differs from manifest: {frame['path']} ({key})"
                )

    log = (root / "hud/hud-smoke.log").read_text(encoding="utf-8")
    if "PASS current UI V2 visual review at both resolutions" not in log:
        raise IncompleteCapture("No successful real LÖVE review marker in smoke log")
    for size, _, _ in SIZES:
        for marker in ("physically grabbed 6 D6", "UI V2 accessibility flags restored"):
            if f"PASS hud-usability-{size}- {marker}" not in log:
                raise IncompleteCapture(f"Missing actual runtime evidence: {size} {marker}")
    gallery = (root / "gallery.html").read_text(encoding="utf-8")
    for frame in frames:
        if Path(frame["path"]).name not in gallery:
            raise IncompleteCapture(f"Gallery does not reference {frame['path']}")
    if not (root / "review-checklist.md").read_text(encoding="utf-8").strip():
        raise IncompleteCapture("Visual QA checklist is empty")

    return files


def package_capture(folder: Path, output: Path | None = None) -> Path:
    """Build a single ZIP AFTER complete validation; no half-package on failure."""
    root = Path(folder).resolve()
    files = verify_capture(root)
    target = (Path(output).resolve() if output else
              root.parent / f"{root.name}-evidence.zip")
    if target == root or root in target.parents:
        raise IncompleteCapture("Write the ZIP outside the capture folder")
    target.parent.mkdir(parents=True, exist_ok=True)

    index = {
        "format": "project-folio-ui-v2-evidence-v1",
        "source_directory": root.name,
        "file_count": len(files),
        "visual_qa_automatically_approved": False,
        "note": "Valid screenshots and logs do not replace a human visual/physics review.",
        "files": [
            {"path": rel, "bytes": (root / rel).stat().st_size,
             "sha256": fingerprint(root / rel)}
            for rel in files
        ],
    }
    handle, temporary = tempfile.mkstemp(
        prefix=target.name + ".", suffix=".tmp", dir=target.parent
    )
    os.close(handle)
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED,
                             compresslevel=6) as bundle:
            for rel in files:
                bundle.write(root / rel, arcname=f"{root.name}/{rel}")
            bundle.writestr(
                f"{root.name}/evidence-index.json",
                json.dumps(index, ensure_ascii=False, indent=2) + "\n",
            )
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    return target


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture_directory", type=Path)
    parser.add_argument("--out", type=Path, help="ZIP destination (outside capture)")
    parser.add_argument("--check-only", action="store_true",
                        help="Verify all 32 frames and originals; do not write ZIP")
    args = parser.parse_args()
    try:
        if args.check_only:
            files = verify_capture(args.capture_directory)
            print(f"PASS: complete UI V2 evidence ({len(files)} original files)")
        else:
            zip_path = package_capture(args.capture_directory, args.out)
            print(f"PASS: complete UI V2 evidence bundle: {zip_path}")
        return 0
    except (IncompleteCapture, OSError, ValueError, KeyError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
