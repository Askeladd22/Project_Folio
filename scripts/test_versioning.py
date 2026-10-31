"""Regression tests for the Project Folio version/changelog gate."""
from __future__ import annotations

import unittest
from check_versioning import VersionError, check_record, compare_versions, parse_version


class VersioningTests(unittest.TestCase):
    def test_semver_prerelease_order(self):
        self.assertLess(compare_versions("0.1.0-dev.1", "0.1.0-dev.2"), 0)
        self.assertLess(compare_versions("0.1.0-dev.9", "0.1.0-dev.10"), 0)
        self.assertLess(compare_versions("0.1.0-dev.10", "0.1.0"), 0)
        self.assertLess(compare_versions("0.1.0", "0.2.0-dev.1"), 0)
        self.assertEqual(compare_versions("1.2.3+abc", "1.2.3+def"), 0)

    def test_reject_invalid_versions(self):
        for bad in ("v0.1", "0.1", "1.02.3", "1.2.3-dev.01", "a.b.c", "1.2.3\n2.0.0"):
            with self.subTest(bad=bad), self.assertRaises(VersionError):
                parse_version(bad)

    def test_current_section_must_match_and_have_notes(self):
        good = """# Notes
## [0.1.0-dev.2] - 2026-11-01

### Modificato
- Version gate and documented an example of improvements applied.

## [0.1.0-dev.1] - 2026-10-31

### Aggiunto
- Original baseline version notes and earlier update summaries.
"""
        check_record("0.1.0-dev.2", good)
        with self.assertRaises(VersionError):
            check_record("0.1.0-dev.3", good)
        with self.assertRaises(VersionError):
            check_record("0.1.0-dev.2", good.replace("2026-11-01", "2026-13-01"))
        with self.assertRaises(VersionError):
            check_record("0.1.0-dev.2", good.replace("[0.1.0-dev.1]", "[0.1.0-dev.2]"))
        with self.assertRaises(VersionError):
            check_record("0.1.0-dev.2", good.split("### Modificato")[0])


if __name__ == "__main__":
    unittest.main()
