#!/usr/bin/env python3
from pathlib import Path
import json
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
env = {}
for p in [
    Path(r"d:\nano\supabase\functions\.env.local"),
    ROOT / "supabase/functions/.env.local",
]:
    if not p.exists():
        continue
    for line in p.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.strip().startswith("#"):
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")

interesting = sorted(k for k in env if any(x in k for x in ("VOICE", "FISH", "AUDIO", "HF", "VIDEO")))
print("keys", interesting)
key = (env.get("VOICE_PROVIDER_API_KEY") or env.get("FISH_API_KEY") or "").strip()
print("key_present", bool(key), "key_len", len(key))
model = (env.get("VOICE_PROVIDER_MODEL") or "s2.1-pro-free").strip()
print("model", model)
endpoint = (env.get("VOICE_PROVIDER_URL") or "https://api.fish.audio").rstrip("/")
body = json.dumps({"text": "Hello.", "format": "mp3", "mp3_bitrate": 128}).encode()
req = urllib.request.Request(
    endpoint + "/v1/tts",
    data=body,
    method="POST",
    headers={
        "Content-Type": "application/json",
        "Authorization": "Bearer " + key,
        "model": model,
    },
)
try:
    with urllib.request.urlopen(req, timeout=60) as r:
        print("status", r.status, "bytes", len(r.read()))
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read()[:300])
except Exception as e:
    print("ERR", type(e).__name__, str(e)[:200])
