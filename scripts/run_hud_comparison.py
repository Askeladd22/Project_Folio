"""Run full-commission comparison between Standard and Minimal HUD."""
from pathlib import Path
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from scripts.love_runtime import find_love

out = (ROOT / 'audits/hud-comparison').resolve()
out.mkdir(parents=True, exist_ok=True)
(out / 'appdata').mkdir(exist_ok=True)

env = {k: v for k, v in os.environ.items() if not k.startswith('MANUSCRIPT_')}
env.update(
    APPDATA=str(out / 'appdata'),
    MANUSCRIPT_AUDIT_OUT=out.as_posix(),
    MANUSCRIPT_HUD_COMPARISON='1'
)

command = [find_love(), '.']
log = out / 'comparison.log'
if log.exists():
    log.unlink()

print('Starting HUD comparison runner...', flush=True)
p = subprocess.run(command, cwd=ROOT, env=env, timeout=120)
text = log.read_text(encoding='utf-8') if log.exists() else 'No log file generated.'
print(text, flush=True)
assert p.returncode == 0 and 'PASS comparison complete' in text, f'Failed comparison, returncode={p.returncode}'
print('SUCCESS: Both HUDs completed full commission and captured comparison screenshots.')
