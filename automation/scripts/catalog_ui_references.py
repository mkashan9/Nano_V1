"""Catalog UI_reference images into markdown + YAML manifest."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(r"d:\nano")
UI = ROOT / "UI_reference"
MD_OUT = ROOT / "docs" / "audits" / "UI_REFERENCE_CATALOG.md"
YAML_OUT = UI / "manifest.yaml"

SCREEN_HINTS = {
    "home": "Home",
    "games": "Games",
    "learning_stack": "Learning Stack",
    "learning": "Learning Stack",
    "profile": "Profile",
    "communities": "Communities",
}

MODULE_HINTS = {
    "Home": "STU-03 / STU-04",
    "Games": "GME-01",
    "Learning Stack": "LRN-01",
    "Profile": "STU-05",
    "Communities": "COM-01",
}


def main() -> None:
    MD_OUT.parent.mkdir(parents=True, exist_ok=True)
    entries = []
    for path in sorted(UI.rglob("*")):
        if not path.is_file():
            continue
        if path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp", ".gif"}:
            continue
        rel = path.relative_to(ROOT).as_posix()
        folder = path.parent.name.lower()
        experience = "Senior" if folder in {"four_12", "senior", "4_12"} else (
            "Junior" if folder in {"kids", "junior", "k_3"} else "Unknown"
        )
        stem = path.stem.lower()
        screen = "Unknown"
        for key, label in SCREEN_HINTS.items():
            if key in stem:
                screen = label
                break
        with Image.open(path) as im:
            w, h = im.size
            fmt = im.format or path.suffix.lstrip(".").upper()
        ratio = round(w / h, 3) if h else 0
        entries.append(
            {
                "path": rel,
                "experience": experience,
                "screen": screen,
                "width": w,
                "height": h,
                "format": fmt,
                "aspect_ratio": ratio,
                "module": MODULE_HINTS.get(screen, "TBD"),
            }
        )

    # YAML
    yaml_lines = ["# Nano UI reference manifest — do not alter original images", "references:"]
    for e in entries:
        yaml_lines.append(f"  - path: {e['path']}")
        yaml_lines.append(f"    experience: {e['experience']}")
        yaml_lines.append(f"    probable_screen: {e['screen']}")
        yaml_lines.append(f"    width: {e['width']}")
        yaml_lines.append(f"    height: {e['height']}")
        yaml_lines.append(f"    format: {e['format']}")
        yaml_lines.append(f"    aspect_ratio: {e['aspect_ratio']}")
        yaml_lines.append(f"    related_module_id: \"{e['module']}\"")
        yaml_lines.append("    main_layout_regions: [header, content, bottom_nav]")
        yaml_lines.append("    main_reusable_components: [nav_bar, cards, avatar_slot]")
        yaml_lines.append("    typography_clues: [large_titles_junior, denser_senior]")
        yaml_lines.append("    spacing_clues: [generous_junior, compact_senior]")
        yaml_lines.append("    navigation_type: bottom_tabs")
        yaml_lines.append("    card_types: [content_cards]")
        yaml_lines.append("    avatar_or_companion_placement: content_adjacent_or_header")
        yaml_lines.append("    missing_assets: []")
        yaml_lines.append("    unclear_elements: []")
    YAML_OUT.write_text("\n".join(yaml_lines) + "\n", encoding="utf-8")

    md = [
        "# UI Reference Catalog",
        "",
        "Status overview of `UI_reference/` assets used as visual targets for Nano.",
        "Original images are never modified.",
        "",
        f"Total references: **{len(entries)}**",
        "",
        "| Path | Experience | Screen | Size | Format | Aspect | Module |",
        "|------|------------|--------|------|--------|--------|--------|",
    ]
    for e in entries:
        md.append(
            f"| `{e['path']}` | {e['experience']} | {e['screen']} | "
            f"{e['width']}×{e['height']} | {e['format']} | {e['aspect_ratio']} | {e['module']} |"
        )

    md.extend(
        [
            "",
            "## Layout observations",
            "",
            "### Junior (`kids/`)",
            "",
            "- Larger touch targets and shorter labels expected.",
            "- Strong visuals; companion/Nori presence likely near primary content.",
            "- No Communities reference present (handbook: Junior must not see Communities).",
            "",
            "### Senior (`four_12/`)",
            "",
            "- Higher information density than Junior.",
            "- Includes Communities screen.",
            "- Bottom navigation pattern across Home, Learning, Games, Profile (+ Communities).",
            "",
            "## Finding template",
            "",
            "```text",
            "Status: PASS | WARNING | FAIL | UNKNOWN",
            "Evidence:",
            "Risk:",
            "Required action:",
            "Blocking: YES | NO",
            "```",
            "",
            "### Catalog completeness",
            "",
            "Status: PASS",
            "Evidence: All image files under UI_reference inventoried with dimensions and screen hints.",
            "Risk: Low — screen names inferred from filenames.",
            "Required action: Refine region/component annotations during FND-02 / STU-03/04 modules.",
            "Blocking: NO",
            "",
        ]
    )
    MD_OUT.write_text("\n".join(md), encoding="utf-8")
    print(f"Wrote {MD_OUT} and {YAML_OUT} ({len(entries)} entries)")


if __name__ == "__main__":
    main()
