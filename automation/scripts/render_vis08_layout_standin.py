#!/usr/bin/env python3
"""Rasterize a VIS-08 Senior Profile layout stand-in."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def render(out: Path, size=(740, 1600)) -> None:
    img = Image.new("RGB", size, (8, 10, 28))
    d = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    d.ellipse([40, 36, 112, 108], outline=(155, 109, 255), width=3)
    d.text((130, 44), "Hey Ayaan!", fill=(255, 255, 255), font=font)
    d.text((130, 68), "Keep learning, keep leveling up!", fill=(160, 160, 180), font=font)

    d.rounded_rectangle([40, 120, 280, 180], radius=12, fill=(26, 29, 51))
    d.text((55, 135), "Builder Rank", fill=(180, 180, 200), font=font)
    d.text((55, 155), "Master Builder", fill=(255, 255, 255), font=font)
    d.rounded_rectangle([300, 120, 560, 180], radius=12, fill=(26, 29, 51))
    d.text((315, 135), "Level 28", fill=(180, 180, 200), font=font)
    d.text((315, 155), "12,450 / 15,000 XP", fill=(255, 255, 255), font=font)
    d.text((580, 145), "Friends", fill=(160, 160, 180), font=font)

    d.rounded_rectangle([40, 200, 700, 260], radius=14, fill=(26, 29, 51))
    d.text((70, 220), "23 Day Streak", fill=(255, 255, 255), font=font)
    d.text((70, 240), "Keep building!", fill=(160, 160, 180), font=font)

    metrics = [
        ("12,450", "XP Earned"),
        ("24", "Projects Built"),
        ("86", "Hours Focused"),
        ("320", "Problems Solved"),
    ]
    for i, (value, label) in enumerate(metrics):
        col, row = i % 2, i // 2
        x0, y0 = 40 + col * 340, 280 + row * 110
        d.rounded_rectangle([x0, y0, x0 + 320, y0 + 96], radius=14, fill=(26, 29, 51))
        d.text((x0 + 16, y0 + 24), value, fill=(255, 255, 255), font=font)
        d.text((x0 + 16, y0 + 50), label, fill=(160, 160, 180), font=font)

    d.text((40, 520), "This Week", fill=(255, 255, 255), font=font)
    d.text((620, 520), "View All", fill=(179, 157, 255), font=font)
    for i, title in enumerate(["Learn", "Build", "Share"]):
        x0 = 40 + i * 230
        d.rounded_rectangle([x0, 550, x0 + 210, 680], radius=14, fill=(26, 29, 51))
        d.text((x0 + 16, 580), title, fill=(155, 109, 255), font=font)

    d.text((40, 710), "Achievements", fill=(255, 255, 255), font=font)
    for i, title in enumerate(
        [
            "Problem Solver",
            "Creative Builder",
            "Science Explorer",
            "Entrepreneur",
            "AI Creator",
            "Team Leader",
        ]
    ):
        col, row = i % 3, i // 3
        x0, y0 = 40 + col * 230, 740 + row * 110
        d.rounded_rectangle([x0, y0, x0 + 210, y0 + 96], radius=14, fill=(26, 29, 51))
        d.text((x0 + 16, y0 + 40), title[:12], fill=(255, 255, 255), font=font)

    d.text((40, 980), "Top Builders", fill=(255, 255, 255), font=font)
    for i, name in enumerate(["Zayan", "Hania", "Noor"]):
        x0 = 40 + i * 230
        d.rounded_rectangle([x0, 1010, x0 + 210, 1120], radius=14, fill=(26, 29, 51))
        d.text((x0 + 16, 1040), name, fill=(255, 255, 255), font=font)
        d.text((x0 + 16, 1080), "Build Together", fill=(179, 157, 255), font=font)

    d.text((40, 1150), "Learning Journey", fill=(255, 255, 255), font=font)
    for i, title in enumerate(
        ["Foundations", "Problem Solver", "Independent Builder", "Team Builder"]
    ):
        y = 1185 + i * 36
        d.ellipse([48, y, 68, y + 20], outline=(47, 191, 113), width=2)
        d.text((80, y), title, fill=(255, 255, 255), font=font)
    d.rounded_rectangle([480, 1185, 700, 1360], radius=12, fill=(26, 29, 51))
    d.text((500, 1260), "Portal", fill=(155, 109, 255), font=font)

    d.rectangle([0, 1450, 740, 1600], fill=(16, 18, 36))
    for i, label in enumerate(["Home", "Learn", "Games", "Communities", "Profile"]):
        x = 20 + i * 145
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
        / "VIS-08"
        / "senior_profile"
        / "actual.png"
    )
    render(out)


if __name__ == "__main__":
    main()
