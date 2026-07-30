from pathlib import Path
ROOT = Path(r"d:\nano")
(ROOT / "docs/provenance/CODE_REUSE_REGISTRY.md").write_text(
"""# Code Reuse Registry

| Name | Source | Version | License | Purpose | Decision |
|------|--------|---------|---------|---------|----------|
| avatar_trials | formerly local | removed | N/A | Companion experiments | DISCARD — removed per owner 2026-07-31 |
| Official Flutter/Supabase packages | pub.dev / supabase | as adopted | package license | Product stack | REUSE when needed |

Trial companion code was deleted. Future CMP modules start from handbook + licensed assets only.
""",
    encoding="utf-8",
)
(ROOT / "docs/provenance/ASSET_PROVENANCE.md").write_text(
"""# Asset Provenance

| Asset path | Source | License | Module | Status |
|------------|--------|---------|--------|--------|
| UI_reference/** | Owner-provided mockups | Owner | design | REFERENCE ONLY |
| assets/** | TBD in FND/CMP modules | TBD | various | Pending |

avatar_trials assets were removed with the trial app (owner directive).
""",
    encoding="utf-8",
)
# Fix AGENTS no-docker note
agents = ROOT / "AGENTS.md"
t = agents.read_text(encoding="utf-8", errors="replace")
if "No Docker" not in t and "without Docker" not in t:
    t = t.rstrip() + """

## Supabase without Docker

- Do **not** use Docker or `supabase start`.
- Use remote-first development against a classified development project (see ADR-0002).
- Migrations live in git; apply via approved remote workflow / MCP.
"""
    agents.write_text(t + "\n", encoding="utf-8")

# Update SUPABASE baseline docker findings
sb = ROOT / "docs/audits/SUPABASE_BASELINE.md"
if sb.exists():
    s = sb.read_text(encoding="utf-8", errors="replace")
    if "ADR-0002" not in s:
        s += """

### Finding: Docker prohibited by owner

Status: PASS
Evidence: Owner directive 2026-07-31 — no Docker; ADR-0002 remote-first.
Risk: Shared remote development data must stay disposable.
Required action: Use nano_v1 as development until staging/production projects exist.
Blocking: NO
"""
        sb.write_text(s, encoding="utf-8")

# KNOWN_ISSUES update
ki = ROOT / "docs/modules/AUD-01/KNOWN_ISSUES.md"
k = ki.read_text(encoding="utf-8", errors="replace")
k = k.replace("Docker / local Supabase", "Docker / local Supabase (superseded)")
if "avatar_trials removed" not in k:
    k = k.rstrip() + """

8. **avatar_trials removed** — Owner directed complete deletion; provenance updated to DISCARD.
9. **No Docker** — Remote-first Supabase per ADR-0002; do not require Docker Desktop.
"""
    ki.write_text(k + "\n", encoding="utf-8")
print("closeout docs ok")
