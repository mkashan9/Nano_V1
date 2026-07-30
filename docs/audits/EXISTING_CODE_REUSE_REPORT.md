# EXISTING_CODE_REUSE_REPORT

## Inventory

| Area | Location | Classification | Notes |
|------|----------|----------------|-------|
| Companion trials | `avatar_trials/` | QUARANTINE | Useful patterns for CMP-01; not product architecture |
| Reaction controller | `avatar_trials/lib/companion/reaction_controller.dart` | ADAPT | Candidate for Nori reaction rules |
| DiceBear trials | `avatar_trials/lib/dicebear/` | ADAPT | Profile avatars — verify license |
| 3D / Sketchfab embeds | `avatar_trials/lib/panda/` | DISCARD / QUARANTINE | Web embed complexity; license unclear |
| Kenney / Fluent / Xylo assets | `avatar_trials/assets/` | QUARANTINE | Confirm licenses before ship |
| UI mockups | `UI_reference/` | REUSE | Visual target only; do not copy third-party brands |
| Handbook | DOCX + `docs/handbook/` | REUSE | Product SoT |
| Supabase schema | remote empty | — | Greenfield |

---

### Finding: Reuse-first readiness

Status: PASS  
Evidence: Registry files created under `docs/provenance/`.  
Risk: Shipping trial assets without license confirmation.  
Required action: License gate in CMP/MED modules.  
Blocking: NO

### Finding: Internet packages

Status: PASS  
Evidence: No abandoned packages added during bootstrap. Trial pub deps remain inside `avatar_trials` only.  
Risk: Low.  
Required action: Evaluate each pub dependency at adoption time.  
Blocking: NO
