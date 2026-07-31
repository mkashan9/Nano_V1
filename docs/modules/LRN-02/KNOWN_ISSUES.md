# LRN-02 Known Issues

- Topic Start opens progress but does not play a video — playback is LRN-03.
- Fake progress repository unlocks are local only; the live path always re-reads lock state from the server.
- Superadmin curator UI for editing prerequisites is out of scope; seeds and service-role writes cover development.
- `authenticated` can execute `start_topic` / `save_topic_progress` (security definer) — intentional, documented in DECISIONS.md.
