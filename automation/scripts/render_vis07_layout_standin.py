#!/usr/bin/env python3
"""Rasterize a VIS-07 Senior Games layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    d.text((40, 40), "Play. Learn.", fill=(255, 255, 255), font=font)
    d.text((40, 70), "Build the future.", fill=(179, 157, 255), font=font)
    d.ellipse([600, 30, 700, 130], outline=(155, 109, 255), width=2)

    games = [
        "Code Quest",
        "Math Arena",
        "Physics Lab",
        "Space Explorer",
        "Logic Factory",
        "Business Empire",
    ]
    for i, title in enumerate(games):
        col, row = i % 2, i // 2
        x0, y0 = 24 + col * 360, 160 + row * 220
        d.rounded_rectangle([x0, y0, x0 + 340, y0 + 200], radius=16, fill=(26, 29, 51))
        d.text((x0 + 20, y0 + 140), title, fill=(255, 255, 255), font=font)
        d.rounded_rectangle([x0 + 220, y0 + 160, x0 + 310, y0 + 188], radius=12, fill=(155, 109, 255))
        d.text((x0 + 240, y0 + 168), "Play", fill=(255, 255, 255), font=font)

    d.text((40, 840), "Challenges", fill=(255, 255, 255), font=font)
    for i, title in enumerate(["Daily", "Weekly", "Boss"]):
        x0 = 24 + i * 240
        d.rounded_rectangle([x0, 870, x0 + 220, 980], radius=14, fill=(26, 29, 51))
        d.text((x0 + 20, 910), title, fill=(155, 109, 255), font=font)

    d.text((40, 1010), "Unlock Worlds", fill=(255, 255, 255), font=font)
    for i in range(4):
        x0 = 24 + i * 120
        d.rounded_rectangle([x0, 1040, x0 + 100, 1140], radius=12, fill=(26, 29, 51))

    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    for i, label in enumerate(["Home", "Learn", "Games", "Communities", "Profile"]):
        x = 20 + i * 145
        color = (155, 109, 255) if label == "Games" else (140, 140, 160)
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
        / "VIS-07"
        / "senior_games"
        / "actual.png"
    )
    render(out)


if __name__ == "__main__":
    main()
