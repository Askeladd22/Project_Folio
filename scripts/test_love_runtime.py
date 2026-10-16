import unittest
from unittest.mock import patch
from love_runtime import find_love

class LoveDiscovery(unittest.TestCase):
    def test_explicit_override(self):
        self.assertEqual(find_love({'LOVE_EXE':'D:/tools/love.exe'}), 'D:/tools/love.exe')

    @patch('love_runtime.shutil.which', return_value='D:/bin/love.exe')
    def test_path_installation(self, _):
        self.assertEqual(find_love({}), 'D:/bin/love.exe')

    @patch('love_runtime.shutil.which', return_value=None)
    @patch('love_runtime.Path.is_file', lambda p: str(p).replace('\\','/')=='C:/Program Files/LOVE/love.exe')
    def test_native_program_files_installation(self, _):
        self.assertEqual(find_love({}).replace('\\','/'), 'C:/Program Files/LOVE/love.exe')

    @patch('love_runtime.shutil.which', return_value=None)
    @patch('love_runtime.Path.is_file', return_value=False)
    def test_missing_runtime_is_explicit(self, *_):
        with self.assertRaises(FileNotFoundError): find_love({})

if __name__=='__main__': unittest.main()
