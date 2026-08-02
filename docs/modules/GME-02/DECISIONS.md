# GME-02 decisions

- Reuse GME-01 eligibility; start fails if version is not eligible.
- Play token is opaque, returned once, stored as SHA-256 hash only.
- Host never exposes Supabase session tokens to game code.
- Bridge rejects unknown types and oversized payloads.
- Fixture `fixture://` surfaces satisfy catalog seeds without WebView.
- Client completion is stored unverified (`verified: false`); no XP.
- HTTPS remote WebView deferred until registered origins exist beyond fixtures.
