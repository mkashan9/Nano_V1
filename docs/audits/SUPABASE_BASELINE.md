# SUPABASE_BASELINE

## Projects (MCP inventory)

| Name | Ref | Region | Status | Tables |
|------|-----|--------|--------|--------|
| nano_v1 | jjsnvmxasbtimesjsyoy | ap-northeast-1 | ACTIVE_HEALTHY | 0 |
| dost | npokunutplmxgbfvcykr | ap-northeast-2 | INACTIVE | — |
| app | luxkjzulnuejwtycrdnl | ap-south-1 | INACTIVE | — |
| mkashan9's Project | vffmlhqalvihfcdjzfsu | ap-northeast-2 | INACTIVE | — |

Classification: **`nano_v1` treated as production-like until owner labels it development/staging/production.**

---

### Finding: Local Supabase

Status: WARNING  
Evidence: `supabase init` created config; Docker not available for `supabase start`.  
Risk: Cannot run `db reset` / pgTAP locally until Docker works.  
Required action: Start Docker Desktop; then `supabase start` in SEC-01.  
Blocking: NO (AUD-01)

### Finding: Migrations

Status: PASS  
Evidence: Empty `supabase/migrations/` ready for SEC-01+. Seed not yet authored.  
Risk: None.  
Required action: All schema via migrations; never dashboard-only.  
Blocking: NO

### Finding: Edge Functions env

Status: PASS  
Evidence: `.env.example` (names) + ignored `.env.local` (secrets) for provider keys.  
Risk: None if ignore rules held.  
Required action: MED-01 adapters read env server-side only.  
Blocking: NO

### Finding: Remote writes policy

Status: PASS  
Evidence: Automation forbids `db push`, linked reset, functions deploy, secrets set without owner permission.  
Risk: Human override.  
Required action: Owner approval checklist before any remote change.  
Blocking: NO


### Finding: Docker prohibited by owner

Status: PASS
Evidence: Owner directive 2026-07-31 — no Docker; ADR-0002 remote-first.
Risk: Shared remote development data must stay disposable.
Required action: Use nano_v1 as development until staging/production projects exist.
Blocking: NO
