# FND-06 Decisions

- R0 uses typed `NanoCopy` catalogs; ARB/`gen-l10n` can replace the catalog later without changing call sites much.
- Urdu is RTL via Flutter `Locale('ur')` + Material delegates.
- Nunito / Noto Nastaliq Urdu are declared as family slots; system fallbacks apply until fonts are bundled in a media module.
- Subject titles remain English in fixtures for now (curriculum content localization is later).
