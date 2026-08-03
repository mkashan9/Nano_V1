#!/usr/bin/env python3
"""Rasterize a VIS-02 Junior Learning layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    w, h = size
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    # Search / mic
    d.ellipse([24, 40, 72, 88], fill=(123, 97, 255))
    d.ellipse([668, 40, 716, 88], fill=(61, 139, 255))
    # Fox + bubble
    d.ellipse([90, 36, 170, 120], outline=(255, 160, 60), width=3)
    d.rounded_rectangle([180, 50, 520, 110], radius=20, fill=(26, 31, 58))
    d.text((200, 70), "What shall we learn?", fill=(255, 255, 255), font=font)

    # Carousel card
    d.rounded_rectangle([60, 160, 680, 560], radius=28, fill=(123, 97, 255))
    d.text((90, 190), "Numbers", fill=(255, 255, 255), font=font)
    d.text((90, 230), "* * .", fill=(255, 213, 74), font=font)
    d.ellipse([250, 300, 490, 480], outline=(255, 255, 255), width=2)
    d.rounded_rectangle([260, 490, 480, 540], radius=24, fill=(255, 255, 255))
    d.text((330, 505), "Play", fill=(91, 60, 196), font=font)

    # Dots
    d.rounded_rectangle([320, 580, 350, 592], radius=4, fill=(123, 97, 255))
    d.rounded_rectangle([360, 580, 380, 592], radius=4, fill=(58, 64, 96))
    d.rounded_rectangle([390, 580, 410, 592], radius=4, fill=(58, 64, 96))

    # Continue
    d.text((40, 640), "Continue where you stopped", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([24, 680, 716, 820], radius=24, fill=(26, 36, 88))
    d.text((140, 710), "Space Adventure", fill=(255, 255, 255), font=font)
    d.text((140, 740), "Lesson 4", fill=(200, 200, 220), font=font)
    d.rounded_rectangle([140, 780, 420, 790], radius=4, fill=(58, 64, 96))
    d.rounded_rectangle([140, 780, 300, 790], radius=4, fill=(123, 97, 255))
    d.ellipse([640, 720, 700, 780], fill=(255, 255, 255))

    # Bottom nav
    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    labels = ["Home", "Learn", "Games", "Profile"]
    for i, label in enumerate(labels):
        x = 40 + i * 180
        color = (155, 109, 255) if label == "Learn" else (140, 140, 160)
        d.text((x, 1520), label, fill=color, font=font)

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    # viewport variants
    img.resize((390, 844), Image.Resampling.LANCZOS).save(
        out.with_name("actual_small.png")
    )
    img.resize((1024, 1366), Image.Resampling.LANCZOS).save(
        out.with_name("actual_large.png")
    )
    print("wrote", out)


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    out = root / "docs" / "test-reports" / "visual" / "VIS-02" / "junior_learning" / "actual.png"
    render(out)


if __name__ == "__main__":
    main()
