#!/usr/bin/env python3
"""CMP-04: generate companion reaction clips via Gradio Wan 2.2 i2v Space."""

from __future__ import annotations

import hashlib
import json
import shutil
import time
from pathlib import Path

from gradio_client import Client, handle_file

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "assets/companion/reference"
OUT = ROOT / "assets/companion/video"
THUMBS = ROOT / "assets/companion/thumbnails"
PROV = ROOT / "assets/companion/provenance"
OUT.mkdir(parents=True, exist_ok=True)
THUMBS.mkdir(parents=True, exist_ok=True)

SPACE = "cinderholm/wan2-2-i2v-v3"
NEGATIVE = (
    "色调艳丽, 过曝, 静态, 细节模糊不清, 字幕, 风格, 作品, 画作, 画面, 静止, "
    "整体发灰, 最差质量, 低质量, JPEG压缩残留, 丑陋的, 残缺的, 多余的手指, "
    "画得不好的手部, 画得不好的脸部, 畸形的, 毁容的, 形态畸形的肢体, 手指融合, "
    "静止不动的画面, 杂乱的背景, 三条腿, 背景人很多, 倒着走, "
    "deformed face, identity change, extra fingers, camera zoom, camera pan, "
    "text, watermark, logo, second character, weapon, photorealistic"
)

CLIPS = [
    {
        "id": "intro_speaking",
        "ref": "ref_greeting_wave.jpg",
        "duration": 4.5,
        "prompt": (
            "The same blue-haired young male companion waves gently hello once, "
            "calm warm closed-mouth smile, soft eye contact, subtle robe and hair "
            "movement, locked camera, centered character, Nano cosmic navy background "
            "preserved, graceful controlled motion, no lip sync exaggeration."
        ),
    },
    {
        "id": "home_greeting_speaking",
        "ref": "ref_greeting_wave.jpg",
        "duration": 3.5,
        "prompt": (
            "Gentle small wave and slight nod of greeting, calm confident posture, "
            "subtle cloth motion, locked camera, preserve exact face and blue-white robes."
        ),
    },
    {
        "id": "welcome_back_speaking",
        "ref": "ref_greeting_wave.jpg",
        "duration": 3.0,
        "prompt": (
            "Small welcoming nod and soft half-wave, never guilty, calm smile, "
            "locked camera, identity locked to reference."
        ),
    },
    {
        "id": "guide_point",
        "ref": "ref_point_right.jpg",
        "duration": 3.0,
        "prompt": (
            "Open-hand guiding gesture toward the right, slight lean, calm focus, "
            "subtle sleeve movement, locked camera, no finger pointing aggression."
        ),
    },
    {
        "id": "listening",
        "ref": "ref_listening.jpg",
        "duration": 3.0,
        "prompt": (
            "Attentive listening pose with gentle breathing and one soft blink, "
            "slight forward attention, locked camera, restrained motion."
        ),
    },
    {
        "id": "correct_small_celebration",
        "ref": "ref_celebrate.jpg",
        "duration": 2.5,
        "prompt": (
            "Small controlled celebration, hands rise slightly, soft cyan sparkle accents, "
            "calm proud smile, no jump, locked camera."
        ),
    },
    {
        "id": "gentle_retry_speaking",
        "ref": "ref_gentle_retry.jpg",
        "duration": 3.0,
        "prompt": (
            "Supportive open-hand encouragement and small nod, warm sympathetic expression "
            "not sad, locked camera, preserve identity."
        ),
    },
    {
        "id": "lesson_complete_speaking",
        "ref": "ref_celebrate.jpg",
        "duration": 3.5,
        "prompt": (
            "Calm proud smile and slight bow of acknowledgment after finishing a lesson, "
            "soft cloth motion, locked camera."
        ),
    },
    {
        "id": "quiz_complete_speaking",
        "ref": "ref_celebrate.jpg",
        "duration": 3.5,
        "prompt": (
            "Controlled celebration smile, hands rise slightly, soft cyan light accents, "
            "no extreme bounce, locked camera, identity preserved."
        ),
    },
    {
        "id": "level_up_speaking",
        "ref": "ref_celebrate.jpg",
        "duration": 4.0,
        "prompt": (
            "Meaningful level-up moment: calm confident smile, subtle upward cyan light arc, "
            "robe and hair movement, locked camera, no weapons."
        ),
    },
    {
        "id": "long_video_refresh_speaking",
        "ref": "ref_listening.jpg",
        "duration": 3.5,
        "prompt": (
            "Calm stretch cue: small shoulder roll and relaxed breathing, gentle open hand, "
            "locked camera, soothing motion."
        ),
    },
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_hf_token() -> str | None:
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
            key = k.strip()
            val = v.strip().strip('"').strip("'")
            if key in {"VIDEO_PROVIDER_API_KEY", "HF_TOKEN", "HUGGINGFACE_TOKEN"} and val:
                return val
    return None


def main() -> None:
    budget_path = PROV / "video_generation_log.json"
    log = {"jobs": [], "space": SPACE}
    if budget_path.exists():
        log = json.loads(budget_path.read_text(encoding="utf-8"))

    done_ids = {j["id"] for j in log.get("jobs", []) if j.get("status") == "accepted"}
    token = load_hf_token()
    print("hf_token_present", bool(token))
    client = Client(SPACE, token=token)
    print("connected", SPACE)

    for clip in CLIPS:
        cid = clip["id"]
        dest = OUT / f"{cid}.mp4"
        if cid in done_ids and dest.exists() and dest.stat().st_size > 10_000:
            print("skip existing", cid)
            continue
        if len([j for j in log.get("jobs", []) if j.get("attempt") and j.get("status") == "accepted"]) >= 12:
            print("budget exhausted")
            break

        ref = REF / clip["ref"]
        if not ref.exists():
            print("missing ref", ref)
            continue

        attempt = 1
        accepted = False
        while attempt <= 2 and not accepted:
            print(f"generate {cid} attempt {attempt}…")
            t0 = time.time()
            try:
                result = client.predict(
                    input_image=handle_file(str(ref)),
                    last_image=handle_file(str(ref)),
                    prompt=clip["prompt"],
                    steps=6,
                    negative_prompt=NEGATIVE,
                    duration_seconds=float(clip["duration"]),
                    guidance_scale=1,
                    guidance_scale_2=1,
                    seed=42 + attempt,
                    randomize_seed=False,
                    quality=6,
                    scheduler="UniPCMultistep",
                    flow_shift=3,
                    frame_multiplier=16,
                    safe_mode=True,
                    lora_groups=[],
                    video_component=True,
                    api_name="/generate_video",
                )
            except Exception as exc:  # noqa: BLE001
                print("FAIL", cid, exc)
                log.setdefault("jobs", []).append(
                    {
                        "id": cid,
                        "attempt": attempt,
                        "status": "failed",
                        "error": str(exc)[:500],
                    }
                )
                budget_path.write_text(json.dumps(log, indent=2), encoding="utf-8")
                attempt += 1
                continue

            # result typically path or tuple
            video_path = None
            if isinstance(result, str):
                video_path = result
            elif isinstance(result, (list, tuple)):
                for item in result:
                    if isinstance(item, str) and item.lower().endswith((".mp4", ".webm")):
                        video_path = item
                        break
                    if isinstance(item, dict) and item.get("video"):
                        video_path = item["video"]
                        break
                    if isinstance(item, str) and Path(item).exists():
                        video_path = item
                        break
            print("result type", type(result), "path", video_path)

            if not video_path or not Path(video_path).exists():
                log.setdefault("jobs", []).append(
                    {
                        "id": cid,
                        "attempt": attempt,
                        "status": "failed",
                        "error": f"no file in result: {result!r}"[:500],
                    }
                )
                budget_path.write_text(json.dumps(log, indent=2), encoding="utf-8")
                attempt += 1
                continue

            shutil.copy2(video_path, dest)
            entry = {
                "id": cid,
                "attempt": attempt,
                "status": "accepted",
                "duration_s": clip["duration"],
                "reference": clip["ref"],
                "prompt": clip["prompt"],
                "output": str(dest.relative_to(ROOT)).replace("\\", "/"),
                "sha256": sha256(dest),
                "bytes": dest.stat().st_size,
                "elapsed_s": round(time.time() - t0, 1),
                "provider": SPACE,
                "review": "pending_manual",
            }
            log.setdefault("jobs", []).append(entry)
            budget_path.write_text(json.dumps(log, indent=2), encoding="utf-8")
            print("saved", dest, dest.stat().st_size)
            accepted = True

        if not accepted:
            print("VIDEO_REVIEW_REQUIRED", cid)

    budget_path.write_text(json.dumps(log, indent=2), encoding="utf-8")
    print("done jobs", len(log.get("jobs", [])))


if __name__ == "__main__":
    main()
