# FND-04 Decisions

- Client route guards are convenience only; RLS remains authoritative (AUTH/SEC later).
- Independent students use a dedicated catalog with no Flex entry (not a hidden placeholder).
- Deep links to denied/unknown paths fall back to `/`.
- `go_router` StatefulShellRoute keeps tab state and URL locations for browser refresh.
