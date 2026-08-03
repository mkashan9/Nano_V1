#!/usr/bin/env python3
"""Compare actual Flutter screenshot PNGs against UI_reference images."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps, ImageStat
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Pillow is required: pip install pillow"
    ) from exc


def _load_rgb(path: Path, size: tuple[int, int] | None = None) -> Image.Image:
    img = Image.open(path).convert("RGB")
    if size and img.size != size:
        img = img.resize(size, Image.Resampling.LANCZOS)
    return img


def _mae(a: Image.Image, b: Image.Image) -> float:
    diff = ImageChops.difference(a, b)
    stat = ImageStat.Stat(diff)
    return sum(stat.mean) / (3 * 255.0)


def _rough_ssim(a: Image.Image, b: Image.Image) -> float:
    """Cheap structural proxy (1 - normalized MAE after blur). Not true SSIM."""
    ab = a.filter(ImageFilter.GaussianBlur(1.2))
    bb = b.filter(ImageFilter.GaussianBlur(1.2))
    return max(0.0, 1.0 - _mae(ab, bb) * 1.35)


def _region_crop(img: Image.Image, box: list[int]) -> Image.Image:
    x, y, w, h = box
    return img.crop((x, y, x + w, y + h))


def compare(
    reference: Path,
    actual: Path,
    out_dir: Path,
    regions: dict[str, list[int]],
) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    ref = _load_rgb(reference)
    act = _load_rgb(actual, size=ref.size)

    # Persist aligned copies
    ref.save(out_dir / "reference.png")
    act.save(out_dir / "actual_aligned.png")

    overlay = Image.blend(ref, act, alpha=0.45)
    overlay.save(out_dir / "overlay.png")

    diff = ImageChops.difference(ref, act)
    diff.save(out_dir / "difference.png")

    # Heatmap: amplify difference into red channel
    gray = ImageOps.grayscale(diff)
    heat = ImageOps.colorize(ImageEnhance.Brightness(gray).enhance(3.0), black="black", white="red")
    heat = Image.blend(ref, heat, 0.55)
    heat.save(out_dir / "difference_heatmap.png")

    overall_ssim = _rough_ssim(ref, act)
    overall_mae = _mae(ref, act)

    region_scores: dict[str, dict[str, float]] = {}
    for name, box in regions.items():
        try:
            r = _region_crop(ref, box)
            a = _region_crop(act, box)
            region_scores[name] = {
                "ssim_proxy": round(_rough_ssim(r, a), 4),
                "mae": round(_mae(r, a), 4),
            }
        except Exception as exc:  # noqa: BLE001
            region_scores[name] = {"error": str(exc)}  # type: ignore[dict-item]

    # Heuristic component scores from region proxies
    layout = region_scores.get("header", {}).get("ssim_proxy", overall_ssim)
    hero = region_scores.get("hero", {}).get("ssim_proxy", overall_ssim)
    subjects = region_scores.get("subjects", {}).get("ssim_proxy", overall_ssim)
    nav = region_scores.get("bottom_navigation", {}).get("ssim_proxy", overall_ssim)

    report = {
        "reference": str(reference).replace("\\", "/"),
        "actual": str(actual).replace("\\", "/"),
        "size": {"width": ref.size[0], "height": ref.size[1]},
        "scores": {
            "overall_ssim_proxy": round(overall_ssim, 4),
            "overall_mae": round(overall_mae, 4),
            "layout_score": round((layout + nav) / 2, 4),
            "typography_score": round((layout + hero) / 2, 4),
            "color_score": round(1.0 - overall_mae, 4),
            "component_geometry_score": round((hero + subjects) / 2, 4),
            "asset_placement_score": round(hero, 4),
            "asset_visual_similarity_score": round(subjects, 4),
            "overall_structural_similarity": round(overall_ssim, 4),
        },
        "regions": region_scores,
        "gate": {
            "target_overall_ssim": 0.95,
            "passed_auto": overall_ssim >= 0.95,
            "status": "PASS" if overall_ssim >= 0.95 else "REVIEW_REQUIRED",
        },
    }
    (out_dir / "comparison_report.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )
    md = [
        "# Comparison report",
        "",
        f"- Reference: `{reference}`",
        f"- Actual: `{actual}`",
        f"- Overall SSIM proxy: **{report['scores']['overall_ssim_proxy']}**",
        f"- Layout: {report['scores']['layout_score']}",
        f"- Typography: {report['scores']['typography_score']}",
        f"- Color: {report['scores']['color_score']}",
        f"- Geometry: {report['scores']['component_geometry_score']}",
        f"- Asset placement: {report['scores']['asset_placement_score']}",
        f"- Asset similarity: {report['scores']['asset_visual_similarity_score']}",
        f"- Gate: **{report['gate']['status']}**",
        "",
    ]
    (out_dir / "comparison_report.md").write_text("\n".join(md), encoding="utf-8")
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", required=True)
    parser.add_argument("--actual", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    regions = {
        "header": [24, 48, 692, 100],
        "hero": [24, 160, 692, 280],
        "subjects": [24, 460, 692, 900],
        "bottom_navigation": [0, 1450, 740, 150],
    }
    report = compare(Path(args.reference), Path(args.actual), Path(args.out), regions)
    print(json.dumps(report["scores"], indent=2))
    print("status:", report["gate"]["status"])


if __name__ == "__main__":
    main()
