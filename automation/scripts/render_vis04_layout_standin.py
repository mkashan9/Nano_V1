#!/usr/bin/env python3
"""Rasterize a VIS-04 Junior Profile layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    d.ellipse([24, 36, 110, 122], outline=(155, 109, 255), width=3)
    d.text((130, 40), "Ali *", fill=(255, 255, 255), font=font)
    d.text((130, 70), "Level 7", fill=(179, 157, 255), font=font)
    d.rounded_rectangle([130, 100, 520, 122], radius=12, fill=(26, 31, 58))
    d.rounded_rectangle([130, 100, 380, 122], radius=12, fill=(155, 109, 255))
    d.text((400, 104), "320 / 500", fill=(255, 255, 255), font=font)
    d.ellipse([600, 30, 710, 140], outline=(255, 160, 60), width=3)

    d.text((40, 170), "Recent Learning", fill=(255, 255, 255), font=font)
    for i, title in enumerate(["Counting Fun", "Wild Animals", "The Letter A"]):
        x0 = 24 + i * 230
        d.rounded_rectangle([x0, 200, x0 + 210, 420], radius=20, fill=(26, 29, 51))
        d.text((x0 + 24, 360), title, fill=(255, 255, 255), font=font)

    d.text((40, 460), "My Weekly Journey", fill=(255, 255, 255), font=font)
    for i, label in enumerate(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]):
        x = 40 + i * 95
        color = (155, 109, 255) if i < 5 else (58, 63, 92)
        d.ellipse([x, 500, x + 48, 548], outline=color, width=2)
        d.text((x + 8, 560), label, fill=(255, 255, 255), font=font)

    d.rounded_rectangle([24, 620, 356, 900], radius=20, fill=(26, 29, 51))
    d.text((48, 640), "For Parents", fill=(255, 255, 255), font=font)
    d.ellipse([130, 700, 250, 820], fill=(61, 139, 255))
    d.text((48, 850), "View progress and updates", fill=(200, 200, 220), font=font)

    d.rounded_rectangle([384, 620, 716, 900], radius=20, fill=(26, 29, 51))
    d.text((408, 640), "Settings", fill=(255, 255, 255), font=font)
    d.text((408, 700), "Sound", fill=(255, 255, 255), font=font)
    d.text((408, 760), "Language", fill=(255, 255, 255), font=font)
    d.text((408, 820), "Dark Mode", fill=(255, 255, 255), font=font)

    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    for i, label in enumerate(["Home", "Learn", "Games", "Profile"]):
        x = 40 + i * 180
        color = (155, 109, 255) if label == "Profile" else (140, 140, 160)
        d.text((x, 1520), label, fill=color, font=font)

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    img.resize((390, 844), Image.Resampling.LANCZOS).save(
        out.with_name("actual_small.png")
    )
    img.resize((1024, 1366), Image.Resampling.LANCZOS).save(
        out.with_name("actual_large.png")
    )
    print("wrote", out)


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    out = (
        root
        / "docs"
        / "test-reports"
        / "visual"
        / "VIS-04"
        / "junior_profile"
        / "actual.png"
    )
    render(out)


if __name__ == "__main__":
    main()
