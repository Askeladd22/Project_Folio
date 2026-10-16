import csv
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


class CaptureRetentionTests(unittest.TestCase):
    def run_capture(self, output, fail_encoding=False):
        stages = []

        def run(command, **options):
            if 'env' in options:
                stage = Path(options['env']['MANUSCRIPT_AUDIT_OUT'])
                stages.append(stage)
                (stage / 'turn-feel.log').write_text('PASS capture')
                (stage / 'frame-1.png').write_bytes(b'frame')
                with (stage / 'frames.csv').open('w', newline='') as stream:
                    writer = csv.DictWriter(stream, fieldnames=['file', 'time', 'cx', 'cy', 'scale'])
                    writer.writeheader()
                    writer.writerow(dict(file='frame-1', time=0, cx=1, cy=2, scale=3))
            elif fail_encoding:
                (stages[0] / 'driver-error.txt').write_text('encoder failure')
                raise subprocess.CalledProcessError(1, command)
            else:
                Path(command[-1]).write_bytes(b'video')

        with patch.object(sys, 'argv', ['capture_turn_feel.py', str(output)]), \
             patch('scripts.love_runtime.find_love', return_value='love'), \
             patch('subprocess.run', side_effect=run):
            if fail_encoding:
                with self.assertRaises(subprocess.CalledProcessError):
                    runpy.run_module('scripts.capture_turn_feel', run_name='__main__')
            else:
                runpy.run_module('scripts.capture_turn_feel', run_name='__main__')
        self.assertFalse(stages[0].exists())

    def test_retains_only_final_artifacts_and_preserves_existing_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            (output / 'existing.png').write_bytes(b'untouched')
            self.run_capture(output)
            self.assertEqual({path.name for path in output.iterdir()},
                             {'existing.png', 'turn-feel.mp4', 'turn-feel.log', 'frames.csv'})
            self.assertEqual((output / 'existing.png').read_bytes(), b'untouched')

    def test_retains_failure_evidence(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            self.run_capture(output, fail_encoding=True)
            self.assertTrue((output / 'driver-error.txt').is_file())
            self.assertTrue((output / 'turn-feel.log').is_file())
            self.assertFalse((output / 'turn-feel.mp4').exists())


if __name__ == '__main__':
    unittest.main()