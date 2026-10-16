"""Find the installed runtime for source launchers and diagnostic runners."""
import os
from pathlib import Path
import shutil

def find_love(env=None):
    env = os.environ if env is None else env
    if env.get('LOVE_EXE'):
        return env['LOVE_EXE']
    found = shutil.which('love')
    if found:
        return found
    for path in (Path('C:/Program Files/LOVE/love.exe'), Path('C:/Program Files (x86)/LOVE/love.exe')):
        if path.is_file():
            return str(path)
    raise FileNotFoundError('LOVE 11.x non trovato: impostare LOVE_EXE o aggiungere love al PATH.')
