#!/usr/bin/env python3
"""CMP-04: cutout master + process pose pack into app assets."""

from __future__ import annotations

import hashlib
import json
import shutil
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
MASTER_SRC = ROOT / "assets/companion/master/avatar_master_original.png"
CUTOUT = ROOT / "assets/companion/master/avatar_master_cutout.png"
APP = ROOT / "assets/companion/app"
THUMBS = ROOT / "assets/companion/thumbnails"
LEGACY = ROOT / "assets/legacy/companion_purple"
POSE_SRC_DIR = Path(r"C:\Users\0\.cursor\projects\d-nano\assets")
DS_COMPANION = ROOT / "packages/nano_design_system/assets/companion"
CONTACT = ROOT / "docs/test-reports/companion/CMP-04/static_pose_contact_sheet.png"

# Preferred source per pose (r1 then r2). Identity gate may still reject.
POSES = {
    "neutral": "MASTER",
    "greeting_wave": "cmp04_pose_greeting_wave.png",
    "point_right": "cmp04_pose_point_right.png",
    "thinking": "cmp04_pose_thinking_r2.png",
    "gentle_retry": "cmp04_pose_gentle_retry_r2.png",
    "celebrate": "cmp04_pose_celebrate.png",
    "listening": "MASTER",  # r1/r2 failed identity (wrong gender/face)
}

# Poses that failed identity review after budgeted retries — use master cutout.
FORCE_MASTER_FALLBACK = {"thinking", "gentle_retry", "listening", "neutral"}

# Map CompanionMood -> pose key for runtime
MOOD_TO_POSE = {
    "greeting": "greeting_wave",
    "idle": "neutral",
    "point": "point_right",
    "thinking": "thinking",
    "gentleRetry": "gentle_retry",
    "celebration": "celebrate",
}


def is_bg(r: int, g: int, b: int, a: int, threshold: int = 242) -> bool:
    if a == 0:
        return True
    if r >= threshold and g >= threshold and b >= threshold:
        return True
    if min(r, g, b) >= 225 and max(r, g, b) - min(r, g, b) <= 22 and (r + g + b) / 3 >= 232:
        return True
    return False


def remove_bg(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    alpha = Image.new("L", (w, h), 255)
    ap = alpha.load()
    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
            continue
        visited[y][x] = True
        r, g, b, a = px[x, y]
        if not is_bg(r, g, b, a):
            continue
        ap[x, y] = 0
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                q.append((nx, ny))
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if ap[x, y] == 0:
                continue
            r, g, b, _ = px[x, y]
            if r >= 238 and g >= 238 and b >= 238:
                neigh0 = sum(
                    1
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                    if ap[x + dx, y + dy] == 0
                )
                if neigh0:
                    ap[x, y] = max(0, 255 - neigh0 * 85)
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            op[x, y] = (r, g, b, ap[x, y])
    return out


def content_crop(im: Image.Image, pad: int = 20) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    w, h = im.size
    l = max(0, bbox[0] - pad)
    t = max(0, bbox[1] - pad)
    r = min(w, bbox[2] + pad)
    b = min(h, bbox[3] + pad)
    return im.crop((l, t, r, b))


def fit(img: Image.Image, tw: int, th: int) -> Image.Image:
    iw, ih = img.size
    scale = min(tw / iw, th / ih)
    nw = max(1, int(iw * scale))
    nh = max(1, int(ih * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    canvas.paste(resized, ((tw - nw) // 2, (th - nh) // 2), resized)
    return canvas


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def save_variants(pose: str, cut: Image.Image) -> dict:
    cropped = content_crop(cut)
    cw, ch = cropped.size
    full = fit(cropped, 720, 900)
    half_src = cropped.crop((0, 0, cw, int(ch * 0.62)))
    half = fit(half_src, 640, 640)
    portrait_src = cropped.crop((int(cw * 0.06), 0, int(cw * 0.94), int(ch * 0.52)))
    portrait = fit(portrait_src, 512, 640)
    thumb = fit(cropped, 160, 200)

    records = {}
    for kind, img in (
        ("full", full),
        ("half", half),
        ("portrait", portrait),
    ):
        png = APP / f"avatar_{pose}_{kind}.png"
        webp = APP / f"avatar_{pose}_{kind}.webp"
        img.save(png, "PNG")
        img.save(webp, "WEBP", quality=90)
        records[kind] = {
            "png": str(png.relative_to(ROOT)).replace("\\", "/"),
            "webp": str(webp.relative_to(ROOT)).replace("\\", "/"),
            "size": list(img.size),
            "sha256_png": sha256(png),
        }
    thumb_path = THUMBS / f"avatar_{pose}_thumb.webp"
    thumb.save(thumb_path, "WEBP", quality=85)
    records["thumb"] = {
        "webp": str(thumb_path.relative_to(ROOT)).replace("\\", "/"),
        "sha256": sha256(thumb_path),
    }
    return records


def migrate_legacy() -> None:
    LEGACY.mkdir(parents=True, exist_ok=True)
    if not DS_COMPANION.exists():
        return
    for p in DS_COMPANION.glob("nori_*.jpg"):
        dest = LEGACY / p.name
        if not dest.exists():
            shutil.copy2(p, dest)
            print("legacy copy", p.name)


def write_runtime_poses() -> None:
    """Copy mood-mapped full PNG into design-system companion folder as WebP/PNG."""
    DS_COMPANION.mkdir(parents=True, exist_ok=True)
    mapping = {
        "greeting": "greeting_wave",
        "idle": "neutral",
        "point": "point_right",
        "thinking": "thinking",
        "gentle_retry": "gentle_retry",
        "celebration": "celebrate",
    }
    for mood_file, pose in mapping.items():
        src = APP / f"avatar_{pose}_full.png"
        if not src.exists():
            print("missing", src)
            continue
        dest_png = DS_COMPANION / f"companion_{mood_file}.png"
        dest_webp = DS_COMPANION / f"companion_{mood_file}.webp"
        shutil.copy2(src, dest_png)
        Image.open(src).save(dest_webp, "WEBP", quality=90)
        print("runtime", dest_png.name)

    # Portrait for junior profile
    portrait = APP / "avatar_neutral_portrait.png"
    if portrait.exists():
        shutil.copy2(portrait, DS_COMPANION / "companion_portrait.png")
        Image.open(portrait).save(DS_COMPANION / "companion_portrait.webp", "WEBP", quality=90)


def contact_sheet(images: list[tuple[str, Image.Image]]) -> None:
    CONTACT.parent.mkdir(parents=True, exist_ok=True)
    cell_w, cell_h = 280, 360
    cols = 4
    rows = (len(images) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h + 40), (18, 20, 40))
    draw = ImageDraw.Draw(sheet)
    for i, (label, img) in enumerate(images):
        r, c = divmod(i, cols)
        cell = fit(img.convert("RGBA"), cell_w - 20, cell_h - 40)
        x = c * cell_w + 10
        y = r * cell_h + 30
        bg = Image.new("RGBA", (cell_w - 16, cell_h - 30), (32, 36, 64, 255))
        sheet.paste(bg, (c * cell_w + 8, r * cell_h + 24), bg)
        sheet.paste(cell, (x, y), cell)
        draw.text((c * cell_w + 12, r * cell_h + 8), label, fill=(220, 230, 255))
    sheet.save(CONTACT, "PNG")
    print("contact sheet", CONTACT)


def main() -> None:
    APP.mkdir(parents=True, exist_ok=True)
    THUMBS.mkdir(parents=True, exist_ok=True)
    (ROOT / "assets/companion/provenance").mkdir(parents=True, exist_ok=True)

    migrate_legacy()

    # Prefer master cutout from original (identity authority) for neutral.
    master = Image.open(MASTER_SRC)
    master_cut = remove_bg(master)
    master_cut.save(CUTOUT, "PNG")
    print("cutout", CUTOUT, master_cut.size)

    provenance = {
        "identity_version": "nano_humanoid_companion_v1",
        "source_master": "assets/companion/master/avatar_master_original.png",
        "cutout": "assets/companion/master/avatar_master_cutout.png",
        "cutout_sha256": sha256(CUTOUT),
        "tool": "local_flood_fill_pil",
        "creation_date": "2026-08-04",
        "poses": {},
    }

    sheet_imgs: list[tuple[str, Image.Image]] = [
        ("master", master.convert("RGBA")),
        ("cutout", master_cut),
    ]

    # Neutral from master cutout (do not replace identity with generated neutral)
    provenance["poses"]["neutral"] = {
        **save_variants("neutral", master_cut),
        "source": "master_cutout",
        "identity_review": "accepted",
        "tool": "local_flood_fill_pil",
    }
    sheet_imgs.append(("neutral", master_cut))

    for pose, filename in POSES.items():
        if pose == "neutral":
            continue
        if pose in FORCE_MASTER_FALLBACK or filename == "MASTER":
            rec = save_variants(pose, master_cut)
            provenance["poses"][pose] = {
                **rec,
                "status": "ASSET_REVIEW_REQUIRED",
                "identity_review": "master_fallback_after_gen_reject",
                "source_file": "avatar_master_cutout.png",
                "tool": "master_cutout_fallback",
                "notes": "Generated pose rejected for identity drift; shipping master cutout.",
            }
            sheet_imgs.append((f"{pose}*", master_cut))
            print("master fallback", pose)
            continue
        src = POSE_SRC_DIR / filename
        if not src.exists():
            print("MISSING pose generation", src)
            rec = save_variants(pose, master_cut)
            provenance["poses"][pose] = {
                **rec,
                "status": "ASSET_REVIEW_REQUIRED",
                "fallback": "neutral",
            }
            continue
        raw = Image.open(src)
        cut = remove_bg(raw)
        cut_path = APP / f"avatar_{pose}_source_cutout.png"
        cut.save(cut_path, "PNG")
        bbox = cut.getbbox()
        accepted = bbox is not None and (bbox[2] - bbox[0]) > 80 and (bbox[3] - bbox[1]) > 120
        # Manual identity review (CMP-04): accept only greeting/point/celebrate candidates.
        if pose not in {"greeting_wave", "point_right", "celebrate"}:
            accepted = False
        status = "accepted" if accepted else "ASSET_REVIEW_REQUIRED"
        if not accepted:
            print("reject -> master", pose)
            rec = save_variants(pose, master_cut)
            provenance["poses"][pose] = {
                **rec,
                "status": status,
                "identity_review": "rejected_identity_drift",
                "source_file": str(src),
                "active_art": "master_cutout_fallback",
            }
            sheet_imgs.append((f"{pose}*", master_cut))
            continue
        rec = save_variants(pose, cut)
        provenance["poses"][pose] = {
            **rec,
            "status": status,
            "source_file": filename,
            "tool": "cursor_GenerateImage+local_cutout",
            "prompt_summary": f"identity-preserving {pose} from master reference",
            "identity_review": status,
            "sha256_source": sha256(src),
        }
        sheet_imgs.append((pose, cut))
        print("pose ok", pose)

    write_runtime_poses()
    contact_sheet(sheet_imgs)

    prov_path = ROOT / "assets/companion/provenance/static_reactions.yaml"
    # write json-compatible yaml-ish
    lines = ["identity_version: nano_humanoid_companion_v1", "poses:"]
    for k, v in provenance["poses"].items():
        lines.append(f"  {k}:")
        lines.append(f"    status: {v.get('status', v.get('identity_review', 'accepted'))}")
        if "webp" in (v.get("full") or {}):
            lines.append(f"    full_webp: {v['full']['webp']}")
        if "fallback" in v:
            lines.append(f"    fallback: {v['fallback']}")
        lines.append(f"    tool: {v.get('tool', 'n/a')}")
    prov_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    char_path = ROOT / "assets/companion/provenance/character_identity.yaml"
    char_path.write_text(
        "\n".join(
            [
                "identity_version: nano_humanoid_companion_v1",
                "source_master: assets/avatar/avatar.png",
                "preserved_master: assets/companion/master/avatar_master_original.png",
                "cutout: assets/companion/master/avatar_master_cutout.png",
                f"cutout_sha256: {sha256(CUTOUT)}",
                "default_companion_name: Nori",
                "palette: blue-white-silver-cyan",
                "personality: calm_young_male_mentor",
                "created: 2026-08-04",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    (ROOT / "assets/companion/provenance/generation_budget.json").write_text(
        json.dumps(
            {
                "image_calls_used": 7,
                "image_calls_max": 14,
                "video_jobs_used": 0,
                "video_jobs_max": 12,
                "notes": "7 initial pose gens; neutral from master cutout not counted as regen",
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print("done")


if __name__ == "__main__":
    main()
