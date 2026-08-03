# QA-05 — Decisions

1. **Executable smoke, not a layout linter.** Overflow is a smoke flag;
   owner confirms visually on Locale preview.
2. **Default Urdu.** Me entry opens in Urdu/RTL so the primary pilot path is
   exercised first.
3. **360px + textScale 1.3.** Same floor as QA-02 for small-phone Urdu review.
4. **Reuse FND-06 surfaces.** Locale preview remains the interactive sample;
   this module is the owner gate checklist.
5. **Domain owns direction via `NanoAppLocale.isRtl`.** Widget tests assert
   Flutter `Directionality` separately.
