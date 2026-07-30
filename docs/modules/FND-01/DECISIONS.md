# FND-01 Decisions

1. **Dart workspace + Melos** — Native `workspace:` in root pubspec with Melos scripts for verify.
2. **Package name `nano_design_system`** — Matches automation AGENTS contract (handbook alias `nano_design`).
3. **Remote-first Supabase** — Per ADR-0002 / owner: no Docker; development uses remote `nano_v1`.
4. **Compile-time env** — `--dart-define` for `NANO_ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
5. **Diagnostics** — Only when `environment.showDebugTools` and feature flag `diagnostics`.
