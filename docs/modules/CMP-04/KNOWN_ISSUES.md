# CMP-04 Known issues

| Issue | Status | Notes |
|-------|--------|--------|
| Owner voice sample `option_A_gentle_young_male__c48e8683.mp3` | Missing on disk | Searched Downloads/Desktop/repo; mark `VOICE_GENERATION_BLOCKED` until supplied. Voice id + migration still ship with `PENDING_OWNER_REFERENCE`. |
| Fish clone reference | Pending | `provider_voice_name = PENDING_OWNER_REFERENCE` |
| Gemini path | `VOICE_APPROXIMATION_USED` | Fallback voice name `Puck` (male); never Aoede |
| Generated Tier-2 clips (6) | `VIDEO_REVIEW_REQUIRED` | Wan i2v not run in this pass; static + Tier-1 motion fallback active; `companion_generated_clips=false` |
| Pose identity drift | Partial | greeting/point/celebrate accepted from gen; thinking/gentle_retry/listening use master cutout + `ASSET_REVIEW_REQUIRED` |
| White-robe cutout edge | Watch | Flood-fill cutout; hair/sleeve edges need owner eye-check on contact sheet |
| VIS-09 dirty tree | Isolated | Implementation only in `nano-cmp04-worktree` |
