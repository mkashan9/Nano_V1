#!/usr/bin/env python3
"""Rasterize a VIS-05 Senior Home layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    d.ellipse([24, 30, 90, 96], outline=(155, 109, 255), width=3)
    d.text((110, 36), "I'm building my future.", fill=(255, 255, 255), font=font)
    d.text((110, 60), "12  Today's Builder Streak", fill=(255, 138, 61), font=font)
    d.text((110, 80), "Gold Builder", fill=(179, 157, 255), font=font)

    d.rounded_rectangle([24, 120, 716, 340], radius=20, fill=(26, 29, 51))
    d.text((48, 140), "Continue Building", fill=(179, 157, 255), font=font)
    d.text((48, 170), "Resume your current project", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([48, 220, 500, 270], radius=12, fill=(20, 22, 42))
    d.text((70, 238), "Space Explorer Game  72%", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([48, 290, 692, 325], radius=16, fill=(155, 109, 255))
    d.text((320, 300), "Continue", fill=(255, 255, 255), font=font)

    d.text((40, 370), "Today's Mission", fill=(255, 255, 255), font=font)
    for i, title in enumerate(["Learn", "Build", "Share"]):
        x0 = 24 + i * 230
        d.rounded_rectangle([x0, 400, x0 + 210, 520], radius=16, fill=(26, 29, 51))
        d.text((x0 + 24, 430), title, fill=(155, 109, 255), font=font)

    d.text((40, 550), "Builder Dashboard", fill=(255, 255, 255), font=font)
    boxes = [(24, 580, 356, 700), (384, 580, 716, 700), (24, 720, 356, 840), (384, 720, 716, 840)]
    labels = ["560 XP", "8 Projects", "6.4 Hours", "42 Problems"]
    for box, label in zip(boxes, labels):
        d.rounded_rectangle(list(box), radius=16, fill=(26, 29, 51))
        d.text((box[0] + 24, box[1] + 40), label, fill=(255, 255, 255), font=font)

    d.text((40, 870), "Continue Learning", fill=(255, 255, 255), font=font)
    for i, title in enumerate(["Genetics", "The Tempest", "Mughal Empire"]):
        y = 900 + i * 70
        d.rounded_rectangle([24, y, 716, y + 60], radius=14, fill=(26, 29, 51))
        d.text((48, y + 22), title, fill=(255, 255, 255), font=font)

    d.text((40, 1120), "Build Challenge", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([24, 1150, 716, 1280], radius=16, fill=(26, 29, 51))
    d.text((48, 1180), "Build a Calculator", fill=(255, 255, 255), font=font)
    d.text((48, 1210), "Reward 100 XP", fill=(255, 213, 74), font=font)

    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    for i, label in enumerate(["Home", "Learn", "Games", "Communities", "Profile"]):
        x = 20 + i * 145
        color = (155, 109, 255) if label == "Home" else (140, 140, 160)
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
        / "VIS-05"
        / "senior_home"
        / "actual.png"
    )
    render(out)


if __name__ == "__main__":
    main()
