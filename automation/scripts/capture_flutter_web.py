#!/usr/bin/env python3
"""Capture Flutter web screenshot for a visual screen (Playwright when available)."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import time
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--screen", default="junior_home")
    parser.add_argument("--width", type=int, default=740)
    parser.add_argument("--height", type=int, default=1600)
    parser.add_argument(
        "--out",
        default="docs/test-reports/visual/VIS-01/junior_home/actual_web.png",
    )
    parser.add_argument("--port", type=int, default=7357)
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    out = root / args.out
    out.parent.mkdir(parents=True, exist_ok=True)

    # Prefer widget-test capture path documented in run_visual_test.py.
    # Optional Playwright path when flutter web + playwright are installed.
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print(
            "Playwright not installed — use run_visual_test.py widget capture.",
            file=sys.stderr,
        )
        return 2

    app_dir = root / "apps" / "student_app"
    cmd = [
        "flutter",
        "run",
        "-d",
        "web-server",
        f"--web-port={args.port}",
        "--dart-define=NANO_SCREENSHOT_MODE=true",
        "--web-renderer=html",
    ]
    proc = subprocess.Popen(cmd, cwd=app_dir)
    try:
        time.sleep(25)
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": args.width, "height": args.height})
            page.goto(f"http://127.0.0.1:{args.port}/#/screenshot/{args.screen}", wait_until="networkidle")
            time.sleep(2)
            page.screenshot(path=str(out), full_page=False)
            browser.close()
        print("wrote", out)
        return 0
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    raise SystemExit(main())
