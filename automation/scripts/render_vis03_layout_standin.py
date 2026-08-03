#!/usr/bin/env python3
"""Rasterize a VIS-03 Junior Games layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    d.ellipse([24, 40, 120, 130], outline=(255, 160, 60), width=3)
    d.rounded_rectangle([140, 50, 700, 120], radius=28, fill=(26, 31, 58))
    d.text((170, 70), "Today's Adventure!", fill=(155, 109, 255), font=font)

    cards = [
        ((24, 160, 356, 620), (123, 97, 255), "Math Island"),
        ((384, 160, 716, 620), (47, 191, 113), "Word Forest"),
        ((24, 640, 356, 1100), (61, 139, 255), "Science Ocean"),
        ((384, 640, 716, 1100), (255, 79, 154), "Puzzle Castle"),
    ]
    for box, color, title in cards:
        d.rounded_rectangle(list(box), radius=28, fill=color)
        d.rounded_rectangle(
            [box[0] + 40, box[1] + 24, box[2] - 40, box[1] + 60],
            radius=16,
            fill=tuple(max(0, c - 30) for c in color),
        )
        d.text((box[0] + 60, box[1] + 34), title, fill=(255, 255, 255), font=font)
        d.rounded_rectangle(
            [box[0] + 80, box[3] - 70, box[2] - 80, box[3] - 30],
            radius=20,
            fill=(255, 255, 255),
        )
        d.text((box[0] + 130, box[3] - 58), "Play", fill=(91, 60, 196), font=font)

    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    for i, label in enumerate(["Home", "Learn", "Games", "Profile"]):
        x = 40 + i * 180
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
        / "VIS-03"
        / "junior_games"
        / "actual.png"
    )
    render(out)


if __name__ == "__main__":
    main()
