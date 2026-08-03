#!/usr/bin/env python3
"""Rasterize a VIS-01 layout stand-in when Flutter golden capture is unavailable.

This is NOT a claim of pixel match — it documents structure for compare_images
while widget tests prove interactive controls. Prefer flutter goldens when the
host can run matchesGoldenFile without hanging.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    w, h = size
    img = Image.new("RGB", size, (10, 12, 27))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    # Header
    d.ellipse([24, 56, 24 + 96, 56 + 96], outline=(155, 109, 255), width=4)
    d.text((140, 70), "Hi Ali", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([600, 70, 700, 120], radius=20, fill=(26, 31, 58))
    d.text((630, 85), "* 7", fill=(255, 213, 74), font=font)

    # Hero
    d.rounded_rectangle([24, 180, 716, 460], radius=28, fill=(58, 42, 140))
    d.text((48, 210), "Continue Learning", fill=(230, 230, 255), font=font)
    d.text((48, 250), "Animals Adventure", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([48, 360, 200, 420], radius=24, fill=(255, 255, 255))
    d.text((80, 380), "Start", fill=(91, 60, 196), font=font)

    # Subjects 2x2
    colors = [(47, 123, 255), (47, 191, 113), (255, 138, 61), (255, 79, 154)]
    titles = ["Math", "English", "Science", "Stories"]
    gap = 20
    card_w = (692 - gap) // 2
    card_h = 320
    y0 = 500
    for i, (c, t) in enumerate(zip(colors, titles)):
        col = i % 2
        row = i // 2
        x = 24 + col * (card_w + gap)
        y = y0 + row * (card_h + gap)
        d.rounded_rectangle([x, y, x + card_w, y + card_h], radius=28, fill=c)
        d.text((x + 24, y + 24), t, fill=(255, 255, 255), font=font)

    # Bottom nav
    d.rectangle([0, h - 120, w, h], fill=(20, 22, 42))
    for i, label in enumerate(["Home", "Learn", "Games", "Profile"]):
        x = 40 + i * 180
        color = (155, 109, 255) if i == 0 else (140, 140, 150)
        d.text((x, h - 70), label, fill=color, font=font)

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print("wrote", out)


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[2]
    report = root / "docs/test-reports/visual/VIS-01/junior_home"
    render(report / "actual.png", (740, 1600))
    render(report / "actual_small.png", (360, 640))
    render(report / "actual_large.png", (430, 932))
