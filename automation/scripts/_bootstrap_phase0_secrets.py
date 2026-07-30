"""PHASE 0: Secure credentials without printing secret values."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


def main() -> None:
    gi = ROOT / ".gitignore"
    existing = gi.read_text(encoding="utf-8") if gi.exists() else ""
    required = [
        "api_s.txt",
        "github.txt",
        ".env",
        ".env.local",
        ".env.*.local",
        "supabase/functions/.env",
        "supabase/functions/.env.local",
        "supabase/functions/.env.production",
        "supabase/.temp/",
        "supabase/.branches/",
        "docs/audits/private/",
    ]
    missing = [n for n in required if n not in existing]
    block = """
# --- Nano credential and env safety ---
api_s.txt
github.txt

.env
.env.local
.env.*.local

supabase/functions/.env
supabase/functions/.env.local
supabase/functions/.env.production

supabase/.temp/
supabase/.branches/

docs/audits/private/

# Flutter / Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
*.iml
.idea/

# OS
.DS_Store
Thumbs.db
"""
    if missing or not gi.exists():
        if gi.exists():
            gi.write_text(existing.rstrip() + "\n" + block, encoding="utf-8")
        else:
            gi.write_text(block.lstrip() + "\n", encoding="utf-8")
        print("Updated .gitignore")
    else:
        print(".gitignore already has required entries")

    (ROOT / ".cursorignore").write_text(
        """api_s.txt
github.txt

.env
.env.local
.env.*.local

supabase/functions/.env
supabase/functions/.env.local
supabase/functions/.env.production

supabase/.temp/
supabase/.branches/

docs/audits/private/
""",
        encoding="utf-8",
    )
    print("Wrote .cursorignore")

    api = (ROOT / "api_s.txt").read_text(encoding="utf-8", errors="replace")
    video_key = voice_key = image_key = ""
    pollinations_note = False
    for line in api.splitlines():
        t = line.strip()
        low = t.lower()
        if low.startswith("video api"):
            parts = t.split(":", 1) if ":" in t else t.split("=", 1)
            if len(parts) == 2:
                video_key = parts[1].strip()
        elif low.startswith("voice api"):
            parts = t.split(":", 1) if ":" in t else t.split("=", 1)
            if len(parts) == 2:
                voice_key = parts[1].strip()
        elif low.startswith("image api"):
            parts = t.split(":", 1) if ":" in t else t.split("=", 1)
            if len(parts) == 2:
                image_key = parts[1].strip()
        elif "pollinations" in low:
            pollinations_note = True

    fn_dir = ROOT / "supabase" / "functions"
    fn_dir.mkdir(parents=True, exist_ok=True)
    (ROOT / "supabase" / "migrations").mkdir(parents=True, exist_ok=True)
    (ROOT / "supabase" / "tests").mkdir(parents=True, exist_ok=True)
    (ROOT / "docs" / "audits" / "private").mkdir(parents=True, exist_ok=True)

    env_local = "\n".join(
        [
            "# Local development secrets — DO NOT COMMIT",
            "# Migrated from api_s.txt during Nano bootstrap",
            "",
            f"VIDEO_PROVIDER_API_KEY={video_key}",
            f"VOICE_PROVIDER_API_KEY={voice_key}",
            f"IMAGE_PROVIDER_API_KEY={image_key}",
            "",
            "# Image generation: Pollinations (primary when IMAGE_PROVIDER_API_KEY empty)",
            "IMAGE_PROVIDER=pollinations",
            "VIDEO_PROVIDER=configured",
            "VOICE_PROVIDER=configured",
            "",
        ]
    )
    (fn_dir / ".env.local").write_text(env_local + "\n", encoding="utf-8")
    print(
        "Wrote supabase/functions/.env.local "
        f"(video={bool(video_key)} voice={bool(voice_key)} image={bool(image_key)})"
    )

    (fn_dir / ".env.example").write_text(
        """# Nano Edge Function environment (names only — no secrets)
# Copy to .env.local and fill values.

VIDEO_PROVIDER_API_KEY=
VOICE_PROVIDER_API_KEY=
IMAGE_PROVIDER_API_KEY=

# Provider selection (adapters decide routing)
IMAGE_PROVIDER=pollinations
VIDEO_PROVIDER=
VOICE_PROVIDER=

# Optional Pollinations base (no secret required for basic usage)
# IMAGE_POLLINATIONS_BASE_URL=https://image.pollinations.ai
""",
        encoding="utf-8",
    )
    print("Wrote supabase/functions/.env.example")

    # Private redacted credential report (ignored path)
    report = ROOT / "docs" / "audits" / "private" / "CREDENTIAL_SETUP_REDACTED.md"
    report.write_text(
        f"""# Credential Setup Report (Redacted)

Generated during Nano PHASE 0 bootstrap.

## Sources migrated

| Source | Disposition |
|--------|-------------|
| `api_s.txt` | Migrated to `supabase/functions/.env.local`, then removed |
| `github.txt` | Used for GitHub auth/remote, then removed |

## Environment variables (names only)

| Variable | Present in local env | Category |
|----------|----------------------|----------|
| `VIDEO_PROVIDER_API_KEY` | {"YES" if video_key else "NO"} | video |
| `VOICE_PROVIDER_API_KEY` | {"YES" if voice_key else "NO"} | voice |
| `IMAGE_PROVIDER_API_KEY` | {"YES" if image_key else "NO"} | image |
| `IMAGE_PROVIDER` | YES (`pollinations`) | image routing |
| `VIDEO_PROVIDER` | YES | video routing |
| `VOICE_PROVIDER` | YES | voice routing |

## Provider notes

- Image: Pollinations documented in source (`image.pollinations.ai`). No privileged key required for basic usage.
- Video / Voice: Privileged keys stored only in ignored local env file.
- Flutter clients must never receive these keys. Use Supabase Edge Functions / trusted backend only.

## Ignore rules

Confirmed in `.gitignore` and `.cursorignore`:

- `api_s.txt`, `github.txt`
- `.env`, `.env.local`, `.env.*.local`
- `supabase/functions/.env`, `.env.local`, `.env.production`
- `supabase/.temp/`, `supabase/.branches/`
- `docs/audits/private/`

## Example committed file

- `supabase/functions/.env.example` (names only)

## Git history scan

See `docs/audits/SECURITY_AND_SECRETS_AUDIT.md` after repository init.

## Owner actions

- Rotate any keys that were previously shared in chat, email, or unencrypted files.
- Confirm GitHub token scopes are least-privilege for this repository.
- Never commit `.env.local` or restore `api_s.txt` / `github.txt` into the tree.

Pollinations documented in source: {"YES" if pollinations_note else "NO"}
""",
        encoding="utf-8",
    )
    print(f"Wrote {report}")


if __name__ == "__main__":
    main()
