import json
from pathlib import Path
import tempfile
import unittest

from scripts import checkpoint


class CheckpointTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / 'game'
        self.root.mkdir()
        for name in checkpoint.ENTRY_FILES:
            (self.root / name).write_text('current game', encoding='utf-8')
        for name in checkpoint.DIRECTORIES:
            (self.root / name).mkdir()
            (self.root / name / 'current.txt').write_text(name, encoding='utf-8')
        self.destination = self.root.parent / 'checkpoints'

    def test_exclusion_integrity_and_reuse(self):
        for name in ('audits', 'backups', 'tmp', '.venv', 'legacy'):
            (self.root / name).mkdir()
            (self.root / name / 'old.txt').write_text('not part of game')
        for extension in checkpoint.ARCHIVES:
            (self.root / 'scripts' / ('previous' + extension)).write_bytes(b'never archive archives')
        nested = self.root / 'src' / 'backups'
        nested.mkdir()
        (nested / 'old.lua').write_text('old')
        folder = checkpoint.create(self.root, self.destination)
        manifest = checkpoint.verify(folder)
        self.assertEqual(len(manifest['files']), len(checkpoint.ENTRY_FILES) + len(checkpoint.DIRECTORIES))
        self.assertEqual(checkpoint.create(self.root, self.destination), folder)
        self.assertEqual(len(list(self.destination.iterdir())), 1)
        self.assertEqual((folder / 'main.lua').read_text(), 'current game')
        self.assertFalse((folder / 'audits').exists())
        self.assertFalse((folder / 'scripts' / 'previous.love').exists())
        (folder / 'main.lua').write_text('corrupted')
        with self.assertRaisesRegex(ValueError, 'integrity'):
            checkpoint.verify(folder)
        with self.assertRaises(ValueError):
            checkpoint.create(self.root, self.destination)

    def test_rejects_internal_destination_and_missing_entry(self):
        with self.assertRaisesRegex(ValueError, 'outside'):
            checkpoint.create(self.root, self.root / 'tmp')
        (self.root / 'main.lua').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing'):
            checkpoint.create(self.root, self.destination)

    def test_changes_create_separate_checkpoint(self):
        first = checkpoint.create(self.root, self.destination)
        (self.root / 'main.lua').write_text('new game')
        second = checkpoint.create(self.root, self.destination)
        self.assertNotEqual(first, second)
        self.assertEqual((first / 'main.lua').read_text(), 'current game')
        self.assertEqual((second / 'main.lua').read_text(), 'new game')

    def test_rejects_unsafe_manifest(self):
        folder = checkpoint.create(self.root, self.destination)
        manifest_path = folder / 'checkpoint.json'
        manifest = json.loads(manifest_path.read_text())
        manifest['files'][0]['path'] = '../outside.txt'
        manifest_path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, 'Unsafe'):
            checkpoint.verify(folder)


if __name__ == '__main__':
    unittest.main()