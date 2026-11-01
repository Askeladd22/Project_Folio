"""Run current-source LOVE diagnostics with isolated settings and output."""
from pathlib import Path
import argparse,os,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from scripts.love_runtime import find_love
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('case',choices=['all','hud','frontend','partial','face-gate','integration','tray'],nargs='?',default='all')
parser.add_argument('--out',type=Path,default=ROOT/'audits/farkle-promotion/after')
parser.add_argument('--ui-v2-baseline',action='store_true',help='Historic P0 HUD baseline (legacy scenarios)')
parser.add_argument('--ui-v2-review',action='store_true',help='Capture the current shipping UI V2 with a dedicated review-only scenario')
args=parser.parse_args()
cases=['partial','face-gate','integration','hud','frontend'] if args.case=='all' else [args.case]
if (args.ui_v2_baseline or args.ui_v2_review) and args.case!='hud':
 raise SystemExit('UI V2 screenshot modes require case=hud')
if args.ui_v2_baseline and args.ui_v2_review:
 raise SystemExit('Choose only one HUD capture mode')
for case in cases:
 out=(args.out/case).resolve();out.mkdir(parents=True,exist_ok=True);(out/'appdata').mkdir(exist_ok=True)
 env={k:v for k,v in os.environ.items() if not k.startswith('MANUSCRIPT_')}
 env.update(APPDATA=str(out/'appdata'),MANUSCRIPT_AUDIT_OUT=out.as_posix())
 if case in ('hud','tray'):
  env['MANUSCRIPT_FARKLE_'+case.upper()+'_SMOKE']='1'
  if case=='hud' and args.ui_v2_baseline:
   env['MANUSCRIPT_UI_V2_P0_CAPTURE']='1'
  if case=='hud' and args.ui_v2_review:
   env['MANUSCRIPT_UI_V2_REVIEW_CAPTURE']='1'
  name,success=('hud-smoke.log',
    'PASS current UI V2 visual review at both resolutions' if args.ui_v2_review
    else 'PASS all HUD scenarios at both resolutions') if case=='hud' else ('tray-smoke.log','PASS all six dice physically cross old divider')
 elif case=='frontend':env['MANUSCRIPT_FRONTEND_SMOKE']='current';name,success='frontend.log','PASS frontend complete'
 else:
  env['MANUSCRIPT_SOURCE_CASE']=case
  if case=='face-gate':env['MANUSCRIPT_FACE_GATE']='1'
  name={'partial':'partial.txt','face-gate':'observations.txt','integration':'integration.txt'}[case];success='PASS'
 command=['cmd.exe','/c',str(ROOT/'Avvia.cmd')] if case=='frontend' else [find_love(),'.']
 log=out/name
 if log.exists():log.unlink()
 p=subprocess.run(command,cwd=ROOT,env=env,timeout=200)
 text=log.read_text(encoding='utf-8') if log.exists() else (out/'driver-error.txt').read_text(encoding='utf-8')
 print(text,flush=True)
 assert p.returncode==0 and success in text and 'FAIL' not in text and 'ERROR' not in text,case
print('PASS current-source smoke:',', '.join(cases))
