#!/usr/bin/env python3
"""Rasterize a VIS-09 Senior Communities layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    d.text((40, 40), "Communities", fill=(255, 255, 255), font=font)
    d.text((40, 70), "Build Together", fill=(179, 157, 255), font=font)

    d.rounded_rectangle([40, 110, 700, 360], radius=18, fill=(42, 26, 85))
    d.text((55, 130), "WEEKLY BUILD CHALLENGE", fill=(179, 157, 255), font=font)
    d.text((55, 160), "Solve real problems. Build the future.", fill=(255, 255, 255), font=font)
    d.text((55, 200), "Build an AI Study Assistant", fill=(220, 220, 240), font=font)
    d.text((55, 220), "Create a School Attendance App", fill=(220, 220, 240), font=font)
    d.text((55, 240), "Design a Better Recycling System", fill=(220, 220, 240), font=font)
    d.rounded_rectangle([55, 280, 220, 320], radius=14, fill=(155, 109, 255))
    d.text((75, 292), "Join Challenge", fill=(255, 255, 255), font=font)
    d.text((55, 335), "Ends in 2d 14h 32m", fill=(180, 180, 200), font=font)

    d.text((40, 390), "Find a Team", fill=(255, 255, 255), font=font)
    d.text((620, 390), "View All", fill=(179, 157, 255), font=font)
    for i, title in enumerate(["Flutter Team", "AI Crew", "Robotics Lab"]):
        x0 = 40 + i * 230
        d.rounded_rectangle([x0, 420, x0 + 210, 580], radius=14, fill=(26, 29, 51))
        d.text((x0 + 16, 450), title, fill=(255, 255, 255), font=font)
        d.rounded_rectangle([x0 + 16, 530, x0 + 180, 560], radius=12, fill=(155, 109, 255))
        d.text((x0 + 50, 538), "Join Team", fill=(255, 255, 255), font=font)

    d.text((40, 610), "Builder Clubs", fill=(255, 255, 255), font=font)
    clubs = [
        "AI Builders",
        "Game Developers",
        "Future Scientists",
        "Young Founders",
        "Robot Makers",
        "Design Studio",
    ]
    for i, title in enumerate(clubs):
        col, row = i % 2, i // 2
        x0, y0 = 40 + col * 340, 640 + row * 150
        d.rounded_rectangle([x0, y0, x0 + 320, y0 + 130], radius=14, fill=(26, 29, 51))
        d.text((x0 + 16, y0 + 20), title, fill=(255, 255, 255), font=font)
        d.text((x0 + 16, y0 + 90), "Join Club", fill=(179, 157, 255), font=font)

    d.rounded_rectangle([40, 1100, 700, 1280], radius=16, fill=(26, 29, 51))
    d.text((180, 1140), "Have an idea?", fill=(180, 180, 200), font=font)
    d.text((180, 1165), "Start Your Own Project", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([180, 1220, 420, 1255], radius=12, fill=(155, 109, 255))
    d.text((230, 1230), "Create Project", fill=(255, 255, 255), font=font)

    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    for i, label in enumerate(["Home", "Learn", "Games", "Communities", "Profile"]):
        x = 20 + i * 145
        color = (155, 109, 255) if label == "Communities" else (140, 140, 160)
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
        / "VIS-09"
        / "senior_communities"
        / "actual.png"
    )
    render(out)


if __name__ == "__main__":
    main()
