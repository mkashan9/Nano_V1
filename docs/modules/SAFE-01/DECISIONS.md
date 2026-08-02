# SAFE-01 decisions

- Reuse SOC-02 `blocks` for also-block; do not invent a second block table.
- Reports resolve by username/friend code or peek peer tokens (no consume).
- Evidence stores privacy-safe labels only; queue actions deferred to SAFE-02.
- Duplicate open reports against the same peer within 24h are rejected.
