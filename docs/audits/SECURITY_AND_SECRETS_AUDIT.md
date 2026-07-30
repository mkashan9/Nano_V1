# SECURITY_AND_SECRETS_AUDIT

## Summary

Credentials migrated out of the workspace root into ignored local env. Source files removed. No Flutter embedding of provider keys. GitHub remote uses credential manager (no token-in-URL).

---

### Finding: api_s.txt migration

Status: PASS  
Evidence: Values moved to `supabase/functions/.env.local` (gitignored). Names-only `supabase/functions/.env.example` committed. `api_s.txt` removed. Private redacted report under `docs/audits/private/`.  
Risk: Keys previously existed in a plaintext root file.  
Required action: Owner should rotate video/voice keys if this machine or file was shared.  
Blocking: NO

### Finding: github.txt migration

Status: PASS  
Evidence: Repo `mkashan9/Nano_V1` configured as `origin`. Token stored via Git Credential Manager. `github.txt` removed. File patterns ignored.  
Risk: PAT scopes are `repo`, `write:packages` — missing `read:org` for `gh auth login`.  
Required action: Optionally add `read:org` for full CLI login; GCM + session GH_TOKEN works for API.  
Blocking: NO

### Finding: Ignore rules

Status: PASS  
Evidence: `.gitignore` and `.cursorignore` include required secret/env/supabase temp/private audit paths.  
Risk: Low.  
Required action: Keep `.env.example` tracked.  
Blocking: NO

### Finding: Secrets in git history

Status: PASS  
Evidence: Fresh `git init` — no prior commits containing secrets at audit time.  
Risk: None in history yet.  
Required action: Never commit `.env.local` or restore credential files.  
Blocking: NO

### Finding: Provider key placement

Status: PASS  
Evidence: Keys only in Edge Function local env; provider registry has names only.  
Risk: Future Flutter code might accidentally request keys.  
Required action: Enforce in MED-01 / Cursor rules — no privileged keys in clients.  
Blocking: NO

### Finding: MCP Supabase access

Status: WARNING  
Evidence: Cursor MCP can list projects and tables on linked org; `nano_v1` empty but ACTIVE.  
Risk: Agent or human could apply remote migrations accidentally.  
Required action: Local-first; require owner approval for remote deploy/push.  
Blocking: NO

### Finding: Service role in Flutter

Status: PASS  
Evidence: No Flutter Supabase integration yet; no service-role leakage found.  
Risk: Future.  
Required action: Never put service role in mobile/web clients.  
Blocking: NO
