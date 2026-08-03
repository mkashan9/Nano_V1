# CMP-04 Known issues

| Issue | Status | Notes |
|-------|--------|--------|
| Wan / Gradio ZeroGPU | `ZEROGPU_QUOTA_EXCEEDED` | HF Space rejected jobs; retry after ~24h. Script: `tools/cmp04_generate_videos.py` (`frame_multiplier` must be int `16`). |
| Fish Audio | `VOICE_GENERATION_BLOCKED` | `VOICE_PROVIDER_API_KEY` returns HTTP 401 Invalid Token. Owner sample MP3 still missing on disk. |
| Tier-2 MP4 assets | Pending | Static + Tier-1 motion fallbacks active; `companion_generated_clips=false` until clips land in `assets/companion/video/`. |
| Pose identity drift | Partial | Some poses use master cutout fallback (`ASSET_REVIEW_REQUIRED`). |
| VIS-09 dirty tree | Isolated | Integration branch is `module/CMP-04-integrated-humanoid-companion` in `nano-cmp04-worktree`. |
