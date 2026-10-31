#!/usr/bin/env python3
"""Require a version bump and matching changelog entry in EVERY Project Folio update.

Usage:
    python3 scripts/check_versioning.py
    python3 scripts/check_versioning.py --base-sha BASE --head-sha HEAD

No external dependencies. GitHub Actions passes PR base/head or push before/after.
"""
from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
SEMVER = re.compile(
    r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?"
    r"(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$"
)
HEADINGS = re.compile(r"^## \[([^\]]+)\] - ([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$", re.M)
REQUIRED = {"version.txt", "CHANGELOG.md"}


class VersionError(ValueError):
    """Version/changelog integrity or update policy violation."""


def parse_version(raw: str) -> tuple[int, int, int, tuple[str, ...] | None]:
    """Validate SemVer 2.0 (including prerelease identifiers), ignoring build metadata."""
    value = raw.strip()
    if "\n" in value or "\r" in value:
        raise VersionError("version.txt must contain exactly one version line")
    m = SEMVER.fullmatch(value)
    if not m:
        raise VersionError(f"Invalid SemVer: {value!r}")
    prerelease = m.group(4)
    if prerelease is not None:
        for piece in prerelease.split("."):
            if piece.isascii() and piece.isdigit() and len(piece) > 1 and piece[0] == "0":
                raise VersionError(f"Leading zero in numeric prerelease: {value}")
    return int(m[1]), int(m[2]), int(m[3]), (
        tuple(prerelease.split(".")) if prerelease else None
    )


def compare_versions(left: str, right: str) -> int:
    """Return -1, 0, 1 using SemVer precedence (build metadata has no precedence)."""
    a, b = parse_version(left), parse_version(right)
    for i in range(3):
        if a[i] != b[i]:
            return 1 if a[i] > b[i] else -1
    pre_a, pre_b = a[3], b[3]
    if pre_a is None or pre_b is None:
        if pre_a == pre_b:
            return 0
        return 1 if pre_a is None else -1
    for lhs, rhs in zip(pre_a, pre_b):
        if lhs == rhs:
            continue
        lnum, rnum = lhs.isascii() and lhs.isdigit(), rhs.isascii() and rhs.isdigit()
        if lnum and rnum:
            return 1 if int(lhs) > int(rhs) else -1
        if lnum != rnum:
            return -1 if lnum else 1
        return 1 if lhs > rhs else -1
    if len(pre_a) == len(pre_b):
        return 0
    return 1 if len(pre_a) > len(pre_b) else -1


def check_record(version: str, changelog: str) -> None:
    parse_version(version)
    matches = HEADINGS.findall(changelog)
    if not matches:
        raise VersionError("CHANGELOG.md has no '## [version] - YYYY-MM-DD' sections")
    if matches[0][0] != version.strip():
        raise VersionError(
            f"Newest changelog entry {matches[0][0]!r} does not match "
            f"version.txt {version.strip()!r}"
        )
    seen = set()
    for number, recorded_on in matches:
        parse_version(number)
        if number in seen:
            raise VersionError(f"Duplicate changelog version: {number}")
        seen.add(number)
        try:
            date.fromisoformat(recorded_on)
        except ValueError as err:
            raise VersionError(f"Bad changelog date: {recorded_on}") from err
    for older, newer in zip(matches, matches[1:]):
        if compare_versions(older[0], newer[0]) <= 0:
            raise VersionError(f"Changelog must be newest first: {older[0]} / {newer[0]}")
    # Require actual work notes, not just an empty version heading.
    heading = re.search(
        r"^## \[" + re.escape(version.strip()) + r"\] - [0-9-]+\s*$", changelog, re.M
    )
    assert heading
    body = changelog[heading.end():].split("\n## [", 1)[0]
    if len(body.strip()) < 80 or not re.search(r"^###\s+", body, re.M):
        raise VersionError("Newest changelog entry needs categorized change notes")


def git(*arguments: str, allow_missing: bool = False) -> str | None:
    result = subprocess.run(
        ["git", *arguments], cwd=ROOT, capture_output=True, text=True, check=False
    )
    if result.returncode:
        if allow_missing and "exists on disk, but not in" in result.stderr:
            return None
        if allow_missing and ("does not exist in" in result.stderr or "path '" in result.stderr and "exists on disk" in result.stderr):
            return None
        raise VersionError("git " + " ".join(arguments) + ": " + result.stderr.strip())
    return result.stdout


def check_update(version: str, base: str, head: str) -> None:
    if not re.fullmatch(r"[0-9a-fA-F]{40}", base or "") or not re.fullmatch(
        r"[0-9a-fA-F]{40}", head or ""
    ):
        raise VersionError("Provide full 40-digit Git commit SHAs for base and head")
    changed = set(git("diff", "--name-only", base + "..." + head).splitlines())
    missing = REQUIRED - changed
    if missing:
        raise VersionError(
            "Every PR/push must update both version.txt and CHANGELOG.md; missing: "
            + ", ".join(sorted(missing))
        )
    old = git("show", f"{base}:version.txt", allow_missing=True)
    if old is None:
        # One-time bootstrap: this repository had only a hardcoded menu v0.1,
        # not a canonical version file. All later PRs must monotonically bump.
        print("INFO: first version-file bootstrap (no canonical prior version)")
        return
    if compare_versions(version.strip(), old.strip()) <= 0:
        raise VersionError(
            f"Version must increase relative to destination: "
            f"{old.strip()} -> {version.strip()}"
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-sha")
    parser.add_argument("--head-sha")
    args = parser.parse_args(argv)
    try:
        version = (ROOT / "version.txt").read_text(encoding="utf-8").strip()
        changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
        check_record(version, changelog)
        if (args.base_sha is None) != (args.head_sha is None):
            raise VersionError("Specify both --base-sha and --head-sha together")
        if args.base_sha and args.head_sha:
            check_update(version, args.base_sha, args.head_sha)
        print(f"PASS Project Folio version {version}: matching changelog and bump policy")
        return 0
    except (OSError, VersionError) as exc:
        print(f"FAIL versioning: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
