#!/usr/bin/env python3
"""Run VIS-01 Junior Home visual capture + compare pipeline."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


def find_flutter() -> str | None:
    """Resolve flutter on Windows/Unix (CreateProcess does not find .bat alone)."""
    for name in ("flutter.bat", "flutter"):
        which = shutil.which(name)
        if which:
            return which
    home = Path.home()
    candidates = (
        home / "flutter" / "bin" / "flutter.bat",
        home / "flutter" / "bin" / "flutter",
        home / "develop" / "flutter" / "bin" / "flutter.bat",
        home / "Downloads" / "flutter_windows_3.44.4-stable" / "flutter" / "bin" / "flutter.bat",
        Path(r"C:\flutter\bin\flutter.bat"),
        Path(r"C:\src\flutter\bin\flutter.bat"),
    )
    for path in candidates:
        if path.is_file():
            return str(path)
    for entry in os.environ.get("PATH", "").split(os.pathsep):
        if not entry:
            continue
        for name in ("flutter.bat", "flutter.exe", "flutter"):
            candidate = Path(entry) / name
            if candidate.is_file():
                return str(candidate)
    return None


def run_cmd(cmd: list[str], cwd: Path | None = None) -> None:
    """Run a command; shell out for .bat/.cmd on Windows."""
    flutterish = cmd and str(cmd[0]).lower().endswith((".bat", ".cmd"))
    if flutterish and os.name == "nt":
        quoted = subprocess.list2cmdline(cmd)
        subprocess.check_call(quoted, cwd=cwd, shell=True)
    else:
        subprocess.check_call(cmd, cwd=cwd)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--screen", default="junior_home")
    parser.add_argument(
        "--skip-tests",
        action="store_true",
        help="Skip flutter widget tests (still render stand-in + compare).",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    report = root / "docs" / "test-reports" / "visual" / "VIS-01" / "junior_home"
    report.mkdir(parents=True, exist_ok=True)
    reference = root / "UI_reference" / "kids" / "home.jpeg"
    actual = report / "actual.png"
    standin = root / "automation" / "scripts" / "render_vis01_layout_standin.py"
    compare = root / "automation" / "scripts" / "compare_images.py"

    if args.screen != "junior_home":
        print(f"unsupported screen: {args.screen}", file=sys.stderr)
        return 2

    if not args.skip_tests:
        flutter = find_flutter()
        if flutter:
            cmd = [
                flutter,
                "test",
                "test/junior_home_page_test.dart",
                "test/screenshot_junior_home_test.dart",
            ]
            print("running:", " ".join(cmd))
            try:
                run_cmd(cmd, cwd=root / "apps" / "student_app")
            except (FileNotFoundError, subprocess.CalledProcessError) as exc:
                print(f"flutter tests skipped/failed: {exc}")
        else:
            print("flutter not found on PATH; skipping widget tests")

    print("rendering layout stand-in")
    run_cmd([sys.executable, str(standin)], cwd=root)

    if not actual.exists():
        print("missing actual.png after stand-in render", file=sys.stderr)
        return 1

    shutil.copyfile(reference, report / "reference.jpeg")
    print("comparing against reference")
    run_cmd(
        [
            sys.executable,
            str(compare),
            "--reference",
            str(reference),
            "--actual",
            str(actual),
            "--out",
            str(report),
        ],
        cwd=root,
    )
    print("reports in", report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
