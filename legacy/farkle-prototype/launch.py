"""Compatibility launcher: current sources, no packaging."""
import argparse, subprocess, sys
from pathlib import Path
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--hud-smoke',action='store_true')
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root))
from scripts.love_runtime import find_love
if args.hud_smoke:
    raise SystemExit(subprocess.call([sys.executable,str(root/'audits/repository-cleanup/run_hud.py')],cwd=root))
try: love=find_love()
except FileNotFoundError as e: parser.error(str(e))
raise SystemExit(subprocess.call([love,str(root)],cwd=root))
