"""Record a reproducible Windows LÖVE screenshot baseline for UI 2.0/P0.

Uses the EXISTING real-game HUD smoke harness (not a fabricated mock UI).
Captures its 1920x1080 and 1280x720 frames, plus source commit hashes.
The group-held/grab and accessibility checks still require manual QA.
"""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--out", type=Path, default=ROOT / "audits" / "ui-v2-p0")
args = parser.parse_args()
out = args.out.resolve()


def git(*arguments):
    result = subprocess.run(
        ["git", *arguments], cwd=ROOT, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True
    )
    return result.stdout.strip()


def fingerprint(path):
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    out.mkdir(parents=True, exist_ok=True)
    current = git("rev-parse", "HEAD")
    status = git("status", "--porcelain")
    print("Capturing actual LÖVE frames at commit", current, flush=True)
    if status:
        print("WARNING: working tree contains local modifications", flush=True)
    subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "run_smoke.py"),
         "hud", "--out", str(out)],
        cwd=ROOT, check=True
    )
    frames = sorted((out / "hud").glob("hud-usability-*.png"))
    assert frames, "LÖVE smoke completed but produced no PNG screenshot"
    for resolution in ("1920", "1280"):
        assert any("hud-usability-" + resolution + "-" in p.name for p in frames), (
            "No real LÖVE capture at " + resolution)
    log = out / "hud" / "hud-smoke.log"
    text = log.read_text(encoding="utf-8")
    assert "PASS all HUD scenarios at both resolutions" in text
    manifest = {
        "purpose": "P0 legacy HUD baseline for Manuscript UI 2.0",
        "commit": current,
        "dirty_at_capture": bool(status),
        "actual_love_runtime": True,
        "resolutions": ["1920x1080", "1280x720"],
        "smoke_log": "hud/hud-smoke.log",
        "screenshots": [
            {
                "path": "hud/" + p.name,
                "bytes": p.stat().st_size,
                "sha256": fingerprint(p),
            } for p in frames
        ],
        "manual_checks_not_automated": [
            "6-die physical group held and moving with right mouse",
            "folio opened with F then Escape at both sizes",
            "big text, high contrast, reduced animations",
            "frame time/FPS with current g3d dice and renderer toggles",
        ],
    }
    (out / "baseline-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8"
    )
    print(
        "PASS UI 2.0 P0 baseline: %d real screenshots; manifest: %s"
        % (len(frames), out / "baseline-manifest.json")
    )


if __name__ == "__main__":
    main()
