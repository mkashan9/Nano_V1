# UI Reference Catalog

Status overview of `UI_reference/` assets used as visual targets for Nano.
Original images are never modified.

Total references: **9**

| Path | Experience | Screen | Size | Format | Aspect | Module |
|------|------------|--------|------|--------|--------|--------|
| `UI_reference/four_12/Communities.jpeg` | Senior | Communities | 740×1600 | JPEG | 0.463 | COM-01 |
| `UI_reference/four_12/games.jpeg` | Senior | Games | 740×1600 | JPEG | 0.463 | GME-01 |
| `UI_reference/four_12/home.jpeg` | Senior | Home | 740×1600 | JPEG | 0.463 | STU-03 / STU-04 |
| `UI_reference/four_12/Learning_stack.jpeg` | Senior | Learning Stack | 740×1600 | JPEG | 0.463 | LRN-01 |
| `UI_reference/four_12/profile.jpeg` | Senior | Profile | 740×1600 | JPEG | 0.463 | STU-05 |
| `UI_reference/kids/games.jpeg` | Junior | Games | 740×1600 | JPEG | 0.463 | GME-01 |
| `UI_reference/kids/home.jpeg` | Junior | Home | 740×1600 | JPEG | 0.463 | STU-03 / STU-04 |
| `UI_reference/kids/learning_stack.jpeg` | Junior | Learning Stack | 740×1600 | JPEG | 0.463 | LRN-01 |
| `UI_reference/kids/profile.jpeg` | Junior | Profile | 740×1600 | JPEG | 0.463 | STU-05 |

## Layout observations

### Junior (`kids/`)

- Larger touch targets and shorter labels expected.
- Strong visuals; companion/Nori presence likely near primary content.
- No Communities reference present (handbook: Junior must not see Communities).

### Senior (`four_12/`)

- Higher information density than Junior.
- Includes Communities screen.
- Bottom navigation pattern across Home, Learning, Games, Profile (+ Communities).

## Finding template

```text
Status: PASS | WARNING | FAIL | UNKNOWN
Evidence:
Risk:
Required action:
Blocking: YES | NO
```

### Catalog completeness

Status: PASS
Evidence: All image files under UI_reference inventoried with dimensions and screen hints.
Risk: Low — screen names inferred from filenames.
Required action: Refine region/component annotations during FND-02 / STU-03/04 modules.
Blocking: NO
