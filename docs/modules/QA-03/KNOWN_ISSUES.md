# QA-03 known issues

- Latency classification is smoke-only; no live network probe.
- Teacher/admin shells are not separately smoked (student Me is the pilot
  surface).
- Conflict / idempotency checks use fake flags until a richer queue fixture
  is wired into Sync Preview.
