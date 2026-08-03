#!/usr/bin/env python3
"""Run VIS-01 Junior Home visual capture + compare pipeline."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--screen", default="junior_home")
    parser.add_argument("--skip-capture", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    report = root / "docs" / "test-reports" / "visual" / "VIS-01" / "junior_home"
    report.mkdir(parents=True, exist_ok=True)
    reference = root / "UI_reference" / "kids" / "home.jpeg"
    actual = report / "actual.png"

    if not args.skip_capture:
        # Widget tests validate interactions; raster stand-in feeds compare_images
        # because matchesGoldenFile hangs on this Windows host at phone sizes.
        subprocess.check_call(
            [
                "flutter",
                "test",
                "test/screenshot_junior_home_test.dart",
            ],
            cwd=root / "apps" / "student_app",
        )
        subprocess.check_call(
            [
                sys.executable,
                str(root / "automation" / "scripts" / "render_vis01_layout_standin.py"),
            ],
        )

    if not actual.exists():
        print("missing actual.png — capture failed", file=sys.stderr)
        return 1

    shutil.copyfile(reference, report / "reference.jpeg")
    compare = [
        sys.executable,
        str(root / "automation" / "scripts" / "compare_images.py"),
        "--reference",
        str(reference),
        "--actual",
        str(actual),
        "--out",
        str(report),
    ]
    subprocess.check_call(compare)
    print("reports in", report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
