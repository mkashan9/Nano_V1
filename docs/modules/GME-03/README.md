# GME-03 — Open-Source Native Game Integration

Flutter-native games (`entry_kind = flutter`) start through the same
session + bridge contract as GME-02. This slice ships **Shape Sort** as a
first-party native fixture with provenance recorded.

## Owns

- `start_game_session` for `flutter` entries
- Published Shape Sort native fixture
- `NativeShapeSortSurface` + catalog Play for flutter
- Provenance note for the native reference integration

## Does not own

- Asset download / cache → GME-04
- Trusted verify / XP → GME-05
- Third-party OSS binary packaging beyond the reference fixture
- HTTPS WebView → remaining GME-02 follow-up
