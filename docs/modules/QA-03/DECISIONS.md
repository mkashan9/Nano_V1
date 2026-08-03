# QA-03 — Decisions

1. **Executable smoke, not a live probe.** Latency thresholds classify
   scenarios; they do not measure real RTT.
2. **Reuse SYNC-01 authority.** Trusted vs draft kinds come from
   `OfflineMutationPolicy` — the audit asserts policy, not a second rule set.
3. **Poor = ≥2s.** `PoorNetworkBudgets.poorLatencyMs` matches handbook
   poor-network smoke.
4. **Me entry + Sync Preview.** Checklist is the owner gate; Sync Preview
   remains the interactive offline/drafts surface.
5. **Offline chrome for offline and poor.** Banner guidance applies whenever
   quality is not OK.
