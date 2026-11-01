"""Capture and inventory the *shipping* Project Folio UI V2 on Windows.

Uses a separate real-LÖVE screenshot scenario, not the retired HUD fallback.
Screenshots prove frames were captured, NOT that visual QA has passed.
"""
from __future__ import annotations
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import html
import json
from pathlib import Path
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SCENES = (
    "fresh", "marquee-six", "physical-group-held",
    "fresh-after-cancel", "accessibility-on",
    "help", "help-scores", "folio", "run-menu",
    "ready-fixture", "choices-fixture", "selected-fixture",
    "upgrade-fixture", "medal-fixture", "reference-catalog",
    "monk-live",
)
SIZES = (("1920", 1920, 1080), ("1280", 1280, 720))


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=ROOT, check=True, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


def fingerprint(file: Path) -> str:
    digest = hashlib.sha256()
    with file.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def png_dimensions(file: Path) -> tuple[int, int]:
    """Validate that screenshot data starts with a PNG IHDR."""
    with file.open("rb") as handle:
        header = handle.read(24)
        if file.stat().st_size < 45:
            raise ValueError(f"Incomplete PNG: {file}")
        handle.seek(-12, 2)
        footer = handle.read(12)
    if footer[:8] != b"\x00\x00\x00\x00IEND":
        raise ValueError(f"Missing PNG end marker: {file}")
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not a PNG screenshot: {file}")
    if header[12:16] != b"IHDR":
        raise ValueError(f"Missing PNG IHDR: {file}")
    width, height = struct.unpack(">II", header[16:24])
    if width <= 0 or height <= 0:
        raise ValueError(f"Invalid dimensions in {file}")
    return width, height


def read_hitboxes(path: Path, width: int, height: int) -> list[dict]:
    """Verify the REAL controller rectangles exported for this PNG frame.

    This file is a companion screenshot audit, not a second gameplay
    hit-test implementation. Values are already mapped to screen pixels
    by the running LÖVE resolution manager.
    """
    if not path.is_file():
        raise FileNotFoundError(f"Missing controller hitbox snapshot: {path.name}")
    required = {"id", "x", "y", "w", "h", "enabled", "source"}
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if set(reader.fieldnames or ()) != required:
            raise ValueError(f"Invalid hitbox TSV schema: {path.name}")
        result = []
        seen = set()
        for row in reader:
            name = row["id"]
            if not name or name in seen or any(c in name for c in "<>&"):
                raise ValueError(f"Duplicate/invalid control ID in {path.name}: {name}")
            seen.add(name)
            if row["enabled"] not in ("0", "1") or row["source"] not in (
                "game", "modal", "reward", "tray"
            ):
                raise ValueError(f"Bad hitbox role for {name}")
            coords = [float(row[key]) for key in ("x", "y", "w", "h")]
            x, y, w, h = coords
            if not all(__import__("math").isfinite(v) for v in coords):
                raise ValueError(f"Non-finite hitbox for {name}")
            if w <= 0 or h <= 0 or x < -0.05 or y < -0.05 or (
                x + w > width + 0.05 or y + h > height + 0.05
            ):
                raise ValueError(f"Off-screen control {name} in {path.name}")
            if (name == "__tray__") != (row["source"] == "tray"):
                raise ValueError(f"Tray metadata incorrectly classified: {name}")
            result.append({
                "id": name, "x": x, "y": y, "w": w, "h": h,
                "enabled": row["enabled"] == "1", "source": row["source"],
            })
    if not any(r["source"] != "tray" for r in result):
        raise ValueError(f"Missing controller actions in {path.name}")
    return result


def collect_frames(root: Path) -> list[dict]:
    hud = root / "hud"
    result = []
    for resolution, width, height in SIZES:
        for scene in SCENES:
            name = f"hud-usability-{resolution}-{scene}.png"
            path = hud / name
            if not path.is_file():
                raise FileNotFoundError(f"Missing real LÖVE frame: {name}")
            dimensions = png_dimensions(path)
            if dimensions != (width, height):
                raise ValueError(
                    f"{name}: expected {width}x{height}, got {dimensions}"
                )
            hitbox_name = name[:-4] + ".hitboxes.tsv"
            boxes = read_hitboxes(hud / hitbox_name, width, height)
            result.append({
                "path": f"hud/{name}",
                "hitbox_path": f"hud/{hitbox_name}",
                "hitboxes": boxes,
                "resolution": f"{width}x{height}",
                "scene": scene,
                "bytes": path.stat().st_size,
                "sha256": fingerprint(path),
            })
    return result


def report_html(frames: list[dict], commit: str) -> str:
    cells = []
    for frame in frames:
        src = html.escape(frame["path"], quote=True)
        caption = html.escape(frame["scene"].replace("-", " ").title())
        resolution = html.escape(frame["resolution"])
        width, height = (int(n) for n in frame["resolution"].split("x"))
        overlays = []
        for box in frame["hitboxes"]:
            role = box["source"]
            state = " enabled" if box["enabled"] else " disabled"
            label = html.escape(box["id"])
            x, y, w, h = (box[k] for k in ("x", "y", "w", "h"))
            overlays.append(
                f'<g class="hitbox {role}{state}">'
                f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" />'
                f'<text x="{x + 5:g}" y="{y + 19:g}">{label}</text></g>'
            )
        overlay = (
            f'<svg class="overlay" viewBox="0 0 {width} {height}" '
            f'preserveAspectRatio="none" aria-hidden="true">'
            + "".join(overlays) + "</svg>"
        )
        cells.append(
            f'<figure><div class="image-stage">'
            f'<a href="{src}"><img loading="lazy" src="{src}" '
            f'alt="{caption} at {resolution}"></a>'
            f'{overlay}</div>'
            f'<figcaption><strong>{caption}</strong> · {resolution}</figcaption></figure>'
        )
    return (
        "<!doctype html><html lang=\"it\"><meta charset=\"utf-8\">"
        "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
        "<title>Project Folio · UI V2 visual review</title>"
        "<style>body{font:16px system-ui;margin:2rem;background:#282018;color:#f2e9d4}"
        "main{max-width:1600px;margin:auto}section{display:grid;"
        "grid-template-columns:repeat(auto-fit,minmax(310px,1fr));gap:1.25rem}"
        "figure{margin:0;background:#3b3024;padding:12px;border-radius:8px}"
        ".image-stage{position:relative;outline:1px solid #ad9162}"
        "img{display:block;width:100%;height:auto}"
        ".overlay{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}"
        "#toggle-hitboxes:not(:checked)~section .overlay{display:none}"
        ".hitbox rect{fill:#ffd04c16;stroke:#ffca47;stroke-width:3}"
        ".hitbox text{fill:#fff9e8;font:bold 19px system-ui;paint-order:stroke;"
        "stroke:#211a12;stroke-width:4;stroke-linejoin:round}"
        ".hitbox.disabled rect{stroke:#aea08b;stroke-dasharray:12 7}"
        ".hitbox.tray rect{stroke:#53b9ff;fill:#53b9ff16;stroke-width:4}"
        ".hitbox.tray text{fill:#d4edff}"
        "figcaption{padding-top:8px}p{line-height:1.5}"
        "label{cursor:pointer;display:inline-block;margin-bottom:1.25rem}</style>"
        "<main><h1>Project Folio — UI V2</h1>"
        f"<p>Commit: <code>{html.escape(commit)}</code>. "
        "Acquisizioni reali LÖVE, <b>non ancora approvate visivamente</b>. "
        "Le immagini *fixture* simulano solo la risposta dei dadi per "
        "mostrare una schermata del gioco; non certificano la fisica.</p>"
        '<input type="checkbox" id="toggle-hitboxes"> '
        '<label for="toggle-hitboxes">Mostra hitbox reali (oro: attive; '
        'grigio: disabilitate; blu: tavolo 3D)</label>'
        "<section>" + "\n".join(cells) + "</section></main></html>"
    )


def review_checklist(commit: str) -> str:
    return f"""# Verifica visiva Project Folio — UI V2

Commit: `{commit}`
Stato: **DA VERIFICARE SU WINDOWS — non approvato automaticamente**

Annota PASS / FAIL / N/A, screenshot e osservazioni per ciascun punto:

- [ ] Sei D6 g3d: facce distinguibili e area di tiro libera a 720p e 1080p
- [ ] Presa fisica: marquee, sei dadi afferrati e overlay non invasivi
- [ ] HUD: numeri di commissione, punti, turni e messaggi leggibili
- [ ] Folio laterale: niente clipping o testo sovrapposto alle cornici
- [ ] Help e combinazioni: schede, tabelle e opzioni completamente leggibili
- [ ] Ricompense: due schede visibili e pulsanti con buon contrasto
- [ ] Menu partita, catalogo medaglie e pannello Monaco senza sovrapposizioni
- [ ] Accessibilità: big text, high contrast, reduced animations realmente percepibili
- [ ] Puntatore/click: attivare `Mostra hitbox reali` nella galleria e verificare allineamento oro/grigio/blu
- [ ] Nessuna regressione di g3d, input fisico, scoring, Farkle e rendering
- [ ] FPS e tempi di rendering rilevati sul PC Windows (se disponibili)

I frame con suffisso `-fixture` usano il controller e le vere regole,
ma i risultati logici dei dadi sono iniettati per la sola cattura:
NON sostituiscono una prova di tiro fisico reale.

Puoi caricare qui `gallery.html`, `review-manifest.json`, `review-checklist.md`
e le immagini con anomalie per la revisione.
"""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out", type=Path, default=ROOT / "audits" / "ui-v2-review",
        help="Destination parent directory for timestamped captures",
    )
    args = parser.parse_args()
    commit = git("rev-parse", "HEAD")
    dirty = bool(git("status", "--porcelain"))
    now = datetime.now(timezone.utc)
    output = args.out.resolve() / (now.strftime("%Y%m%d-%H%M%S")
                                    + "-" + commit[:8])
    output.mkdir(parents=True, exist_ok=False)
    print(f"Capturing current UI V2 with LÖVE at {commit}", flush=True)
    if dirty:
        print("WARNING: local changes are present; manifest marks dirty", flush=True)
    subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "run_smoke.py"),
         "hud", "--ui-v2-review", "--out", str(output)],
        cwd=ROOT, check=True,
    )
    log = output / "hud" / "hud-smoke.log"
    content = log.read_text(encoding="utf-8")
    if "PASS current UI V2 visual review at both resolutions" not in content:
        raise RuntimeError("LÖVE did not complete the active UI V2 review")
    for resolution, _, _ in SIZES:
        for label in ("physically grabbed 6 D6",
                      "UI V2 accessibility flags restored"):
            if f"PASS hud-usability-{resolution}- {label}" not in content:
                raise RuntimeError(f"Missing real runtime evidence: {resolution} {label}")
    frames = collect_frames(output)
    manifest = {
        "project": "Project Folio",
        "purpose": "Current shipping UI V2 visual review, not P0 legacy",
        "commit": commit,
        "dirty_at_capture": dirty,
        "captured_at_utc": now.isoformat(),
        "actual_love_runtime": True,
        "manual_visual_qa_approved": False,
        "resolutions": [f"{w}x{h}" for _, w, h in SIZES],
        "smoke_log": "hud/hud-smoke.log",
        "frames": frames,
        "notes": [
            "Physical group screenshots use the real production controller and g3d.",
            "The *-fixture phases use injected scoring outcomes with real Farkle rules.",
            "Action rectangles are exported by the active LÖVE controller in screen pixels for each shot.",
            "The gallery can overlay these rectangles; they do not prove a physical click happened.",
            "A successful capture does not prove appearance, pointer accuracy or FPS.",
        ],
    }
    (output / "review-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (output / "gallery.html").write_text(
        report_html(frames, commit), encoding="utf-8",
    )
    (output / "review-checklist.md").write_text(
        review_checklist(commit), encoding="utf-8",
    )
    print(
        f"PASS: {len(frames)} captured LÖVE frames, manifest, gallery and "
        f"unapproved visual QA checklist at {output}",
        flush=True,
    )


if __name__ == "__main__":
    main()
