#!/usr/bin/env python3
"""CMP-04: generate Fish Audio narration lines (server-side style, local batch).

Reads VOICE_PROVIDER_API_KEY from environment or supabase/functions/.env.local
without printing secrets. Uses reference_id from env FISH_REFERENCE_ID or
VOICE_REFERENCE_ID when set; otherwise attempts reference audio upload path
if assets/companion/audio/voice_reference_gentle_young_male.mp3 exists.
"""

from __future__ import annotations

import hashlib
import json
import os
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/companion/audio/lines"
PROV = ROOT / "assets/companion/provenance"
OUT.mkdir(parents=True, exist_ok=True)

LINES = [
    ("intro_speaking", "Hey. I'm here to help you learn, play, and keep moving forward."),
    ("home_greeting_speaking", "Welcome back. Ready for your next step?"),
    ("welcome_back_speaking", "Good to see you again. We can continue whenever you're ready."),
    ("guide_point", "Pick something that looks interesting, and we'll start from there."),
    ("listening", "Take your time. I'll be here when you finish."),
    ("gentle_retry_speaking", "That one was tricky. Take another look. You've got this."),
    ("lesson_complete_speaking", "Nice work. You finished the lesson. Let's check what you remember."),
    ("quiz_complete_speaking", "Well done. You stayed focused and finished strong."),
    ("level_up_speaking", "Level up. You earned it, one step at a time."),
    ("long_video_refresh_speaking", "Quick break. Stretch, breathe, and continue when you're ready."),
]


def load_env() -> dict[str, str]:
    env = dict(os.environ)
    for candidate in (
        ROOT / "supabase/functions/.env.local",
        Path(r"d:\nano\supabase\functions\.env.local"),
    ):
        if not candidate.exists():
            continue
        for line in candidate.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            env.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    return env


def main() -> None:
    env = load_env()
    key = (env.get("VOICE_PROVIDER_API_KEY") or env.get("FISH_API_KEY") or "").strip()
    endpoint = (env.get("VOICE_PROVIDER_URL") or "https://api.fish.audio").rstrip("/")
    model = (env.get("VOICE_PROVIDER_MODEL") or "s2.1-pro-free").strip()
    reference_id = (
        env.get("FISH_REFERENCE_ID")
        or env.get("VOICE_REFERENCE_ID")
        or ""
    ).strip()
    # Do not use PENDING_OWNER_REFERENCE placeholder
    if reference_id.upper().startswith("PENDING"):
        reference_id = ""

    log = {"voice_id": "gentle_young_male_c48e8683", "lines": []}
    if not key:
        log["status"] = "VOICE_GENERATION_BLOCKED"
        log["reason"] = "VOICE_PROVIDER_API_KEY missing"
        (PROV / "fish_audio_log.json").write_text(json.dumps(log, indent=2), encoding="utf-8")
        print("VOICE_GENERATION_BLOCKED: no API key")
        return

    if not reference_id:
        log["status"] = "VOICE_APPROXIMATION_USED"
        log["note"] = "No Fish reference_id; using account default male path if any"
        print("VOICE_APPROXIMATION_USED: no reference_id")
    else:
        log["status"] = "ok"
        print("using reference_id length", len(reference_id))

    for line_id, text in LINES:
        dest = OUT / f"{line_id}.mp3"
        if dest.exists() and dest.stat().st_size > 1000:
            print("skip", line_id)
            log["lines"].append({"id": line_id, "status": "exists", "path": str(dest)})
            continue
        body = {
            "text": text,
            "format": "mp3",
            "mp3_bitrate": 128,
            "normalize": True,
            "latency": "normal",
        }
        if reference_id:
            body["reference_id"] = reference_id
        req = urllib.request.Request(
            f"{endpoint}/v1/tts",
            data=json.dumps(body).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {key}",
                "model": model,
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                audio = resp.read()
        except Exception as exc:  # noqa: BLE001
            print("FAIL", line_id, type(exc).__name__)
            log["lines"].append({"id": line_id, "status": "failed", "error": type(exc).__name__})
            continue
        dest.write_bytes(audio)
        log["lines"].append(
            {
                "id": line_id,
                "status": "accepted",
                "bytes": len(audio),
                "sha256": hashlib.sha256(audio).hexdigest(),
                "text": text,
                "path": str(dest.relative_to(ROOT)).replace("\\", "/"),
            }
        )
        print("saved", line_id, len(audio))

    (PROV / "fish_audio_log.json").write_text(json.dumps(log, indent=2), encoding="utf-8")
    print("done")


if __name__ == "__main__":
    main()
