#!/usr/bin/env python3
"""Rasterize a VIS-06 Senior Learning layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    d.rounded_rectangle([24, 30, 716, 80], radius=24, fill=(26, 29, 51))
    d.text((50, 48), "Search anything to learn...", fill=(180, 180, 200), font=font)

    d.rounded_rectangle([24, 100, 716, 280], radius=20, fill=(26, 18, 64))
    d.text((48, 130), "Hi Builder!", fill=(220, 220, 230), font=font)
    d.text((48, 160), "I'm your AI Mentor", fill=(179, 157, 255), font=font)
    d.rounded_rectangle([48, 220, 280, 255], radius=16, fill=(155, 109, 255))
    d.text((70, 230), "Chat with Mentor", fill=(255, 255, 255), font=font)

    d.text((40, 310), "Recently Learned", fill=(255, 255, 255), font=font)
    for i, title in enumerate(["Python Basics", "Intro to AI", "Space Science"]):
        x0 = 24 + i * 230
        d.rounded_rectangle([x0, 340, x0 + 210, 460], radius=16, fill=(26, 29, 51))
        d.text((x0 + 20, 380), title, fill=(255, 255, 255), font=font)

    d.text((40, 490), "Explore by Category", fill=(255, 255, 255), font=font)
    cats = ["Programming", "AI", "Science", "Business", "History", "Design"]
    for i, title in enumerate(cats):
        col, row = i % 3, i // 3
        x0, y0 = 24 + col * 236, 520 + row * 150
        d.rounded_rectangle([x0, y0, x0 + 220, y0 + 130], radius=16, fill=(26, 29, 51))
        d.text((x0 + 16, y0 + 40), title, fill=(255, 255, 255), font=font)

    d.text((40, 850), "Learning Paths", fill=(255, 255, 255), font=font)
    for i, title in enumerate(["Foundations", "Build Basics", "Real World Builder"]):
        y = 890 + i * 50
        d.ellipse([40, y, 70, y + 30], outline=(155, 109, 255), width=2)
        d.text((90, y + 8), title, fill=(255, 255, 255), font=font)
    d.rounded_rectangle([520, 890, 700, 1030], radius=16, fill=(26, 29, 51))

    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    for i, label in enumerate(["Home", "Learn", "Games", "Communities", "Profile"]):
        x = 20 + i * 145
        color = (155, 109, 255) if label == "Learn" else (140, 140, 160)
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
        / "VIS-06"
        / "senior_learning"
        / "actual.png"
    )
    render(out)


if __name__ == "__main__":
    main()
