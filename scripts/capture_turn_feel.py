"""Real-time LOVE capture, encoded using actual frame timestamps (silent video)."""
from pathlib import Path
import csv, os, shutil, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from scripts.love_runtime import find_love
out=(ROOT/(sys.argv[1] if len(sys.argv)>1 else 'audits/turn-feel/after-video')).resolve()
out.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='manuscript-capture-') as temporary:
    work=Path(temporary)
    (work/'appdata').mkdir()
    env={k:v for k,v in os.environ.items() if not k.startswith('MANUSCRIPT_')}
    env.update(APPDATA=str(work/'appdata'),MANUSCRIPT_AUDIT_OUT=work.as_posix(),MANUSCRIPT_SOURCE_CASE='turn-feel')
    try:
        subprocess.run([find_love(),'.'],cwd=ROOT,env=env,timeout=100,check=True)
        with (work/'frames.csv').open() as stream:
            rows=list(csv.DictReader(stream))
        if not rows:
            raise ValueError('Capture produced no frames')
        lines=[]
        for index,row in enumerate(rows):
            lines.append("file '"+row['file']+".png'")
            duration=float(rows[index+1]['time'])-float(row['time']) if index+1<len(rows) else 1/15
            lines.append(f'duration {duration:.6f}')
        lines.append("file '"+rows[-1]['file']+".png'")
        (work/'frames.txt').write_text('\n'.join(lines))
        subprocess.run(['ffmpeg','-y','-v','error','-f','concat','-safe','0','-i',str(work/'frames.txt'),'-vsync','vfr','-c:v','libx264','-pix_fmt','yuv420p',str(work/'turn-feel.mp4')],check=True)
        shutil.copy2(work/'turn-feel.mp4',out/'turn-feel.mp4')
        print((work/'turn-feel.log').read_text())
        print('Real-time projection ranges:',{key:(min(float(row[key]) for row in rows),max(float(row[key]) for row in rows)) for key in ('cx','cy','scale')})
    finally:
        for name in ('turn-feel.log','frames.csv','driver-error.txt'):
            if (work/name).is_file():
                shutil.copy2(work/name,out/name)
