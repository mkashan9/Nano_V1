"""Extract Nano handbook DOCX to markdown with structure preserved."""
from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.oxml.ns import qn
from docx.table import Table
from docx.text.paragraph import Paragraph

ROOT = Path(r"d:\nano")
SRC = ROOT / "Nano_Product_and_Implementation_Handbook_v1.0.docx"
OUT = ROOT / "docs" / "handbook" / "NANO_HANDBOOK.md"


def iter_block_items(parent):
    body = parent.element.body
    for child in body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, parent)
        elif child.tag == qn("w:tbl"):
            yield Table(child, parent)


def heading_level(paragraph: Paragraph) -> int | None:
    style = paragraph.style.name if paragraph.style else ""
    if style.startswith("Heading"):
        try:
            return int(style.split()[-1])
        except ValueError:
            return 1
    if style in ("Title",):
        return 1
    return None


def para_to_md(paragraph: Paragraph) -> str:
    text = paragraph.text.strip()
    if not text:
        return ""
    level = heading_level(paragraph)
    if level:
        return f"{'#' * level} {text}"
    style = paragraph.style.name if paragraph.style else ""
    if "List" in style or paragraph._p.pPr is not None and paragraph._p.pPr.numPr is not None:
        return f"- {text}"
    return text


def table_to_md(table: Table) -> str:
    rows = []
    for row in table.rows:
        cells = [" ".join(c.text.split()) for c in row.cells]
        rows.append(cells)
    if not rows:
        return ""
    width = max(len(r) for r in rows)
    normalized = [r + [""] * (width - len(r)) for r in rows]
    header = normalized[0]
    lines = [
        "| " + " | ".join(header) + " |",
        "| " + " | ".join(["---"] * width) + " |",
    ]
    for r in normalized[1:]:
        lines.append("| " + " | ".join(r) + " |")
    return "\n".join(lines)


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = Document(str(SRC))
    parts = [
        "# Nano Product and Implementation Handbook",
        "",
        "> Machine-readable extraction of `Nano_Product_and_Implementation_Handbook_v1.0.docx`.",
        "> Do not edit the original DOCX; update this file only when re-extracting.",
        "",
    ]
    for block in iter_block_items(doc):
        if isinstance(block, Paragraph):
            md = para_to_md(block)
            if md:
                parts.append(md)
                parts.append("")
        elif isinstance(block, Table):
            md = table_to_md(block)
            if md:
                parts.append(md)
                parts.append("")
    OUT.write_text("\n".join(parts), encoding="utf-8")
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes, {len(parts)} parts)")


if __name__ == "__main__":
    main()
