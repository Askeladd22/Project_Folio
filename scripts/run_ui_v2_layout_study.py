"""Open a reversible, visual A/B study of Scriptorium's UI 2.0 pages.

Requires a local LÖVE 11.x runtime; does NOT replace or modify gameplay UI.
F6 toggles geometry; F7 captures screenshot to LÖVE save directory;
Escape quits the study.
"""
from pathlib import Path
import os
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from scripts.love_runtime import find_love

env={k:v for k,v in os.environ.items() if not k.startswith('MANUSCRIPT_')}
env['MANUSCRIPT_UI_V2_LAYOUT_STUDY']='1'
print('UI 2.0 P1 layout A/B: F6 cambia, F7 cattura PNG, Esc esce',flush=True)
print('Diagnostica soltanto; il normale HUD/Farkle non viene modificato.',flush=True)
subprocess.run([find_love(),'.'],cwd=ROOT,env=env,check=True)
