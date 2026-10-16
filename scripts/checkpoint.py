"""Create or verify an unpacked, minimal checkpoint outside the source tree."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat

ROOT = Path(__file__).resolve().parents[1]
DIRECTORIES = ('src', 'resources', 'lib', 'third_party', 'scripts', 'tests', 'docs')
ENTRY_FILES = ('Avvia.cmd', 'main.lua', 'core.lua', 'conf.lua', 'stylua.toml')
EXCLUDED = {'audits', 'backups', 'tmp', '__pycache__', '.git', '.venv', 'node_modules'}
ARCHIVES = ('.zip', '.love', '.7z', '.rar', '.tar', '.gz', '.bz2', '.xz', '.bak')


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def inventory(root):
    paths = [root / name for name in ENTRY_FILES]
    for path in paths:
        if not path.is_file() or path.is_symlink():
            raise ValueError(f'Missing or linked entry file: {path}')
    paths.extend(root.glob('*.md'))
    for name in DIRECTORIES:
        folder = root / name
        if not folder.is_dir() or folder.is_symlink() or folder.is_junction():
            raise ValueError(f'Missing or linked directory: {folder}')
        for parent, folders, files in os.walk(folder, followlinks=False):
            folders[:] = sorted(child for child in folders if child not in EXCLUDED
                               and not (Path(parent) / child).is_symlink()
                               and not (Path(parent) / child).is_junction())
            paths.extend(Path(parent) / filename for filename in sorted(files)
                         if not filename.lower().endswith(ARCHIVES + ('.pyc', '.pyo')))
    rows = []
    for path in sorted(set(paths)):
        if path.is_symlink() or not stat.S_ISREG(path.stat().st_mode):
            raise ValueError(f'Unsupported checkpoint file: {path}')
        rows.append({'path': path.relative_to(root).as_posix(),
                     'bytes': path.stat().st_size, 'sha256': digest(path)})
    return rows


def verify(folder):
    manifest = json.loads((folder / 'checkpoint.json').read_text(encoding='utf-8'))
    if manifest['format'] != 1:
        raise ValueError('Unsupported checkpoint format')
    expected = set()
    for row in manifest['files']:
        relative = Path(row['path'])
        target = folder / relative
        if relative.is_absolute() or '..' in relative.parts or not target.resolve().is_relative_to(folder.resolve()):
            raise ValueError(f'Unsafe checkpoint path: {relative}')
        if target.is_symlink() or target.stat().st_size != row['bytes'] or digest(target) != row['sha256']:
            raise ValueError(f'Checkpoint integrity failure: {relative}')
        expected.add(relative.as_posix())
    actual = {path.relative_to(folder).as_posix() for path in folder.rglob('*') if path.is_file()}
    if actual != expected | {'checkpoint.json'}:
        raise ValueError('Unexpected or missing checkpoint files')
    return manifest


def create(root, destination):
    root, destination = root.resolve(), destination.resolve()
    if destination == root or destination.is_relative_to(root):
        raise ValueError('Checkpoint destination must be outside the project')
    rows = inventory(root)
    identifier = hashlib.sha256(json.dumps(rows, sort_keys=True).encode()).hexdigest()
    folder = destination / identifier
    if folder.exists():
        manifest = verify(folder)
        if manifest['files'] != rows:
            raise ValueError('Checkpoint identity mismatch')
        return folder
    size = sum(row['bytes'] for row in rows)
    destination.mkdir(parents=True, exist_ok=True)
    if shutil.disk_usage(destination).free < size + 64 * 1024 * 1024:
        raise ValueError('Insufficient free space for checkpoint')
    folder.mkdir()
    for row in rows:
        target = folder / row['path']
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / row['path'], target)
    (folder / 'checkpoint.json').write_text(
        json.dumps({'format': 1, 'files': rows}, indent=2), encoding='utf-8')
    verify(folder)
    if inventory(root) != rows:
        raise ValueError('Source changed during checkpoint; do not use this checkpoint')
    return folder


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, default=ROOT.parent / 'manuscript-checkpoints')
    parser.add_argument('--verify', type=Path)
    args = parser.parse_args()
    folder = args.verify.resolve() if args.verify else create(ROOT, args.destination)
    manifest = verify(folder)
    size = sum(row['bytes'] for row in manifest['files'])
    print(f'PASS checkpoint: {folder}\n{len(manifest["files"])} files, {size / 1024**2:.1f} MiB; SHA-256 verified')


if __name__ == '__main__':
    main()