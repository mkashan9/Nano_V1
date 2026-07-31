# SEC-02 — Multi-School Tenancy and RLS

## Purpose

School isolation foundations: `schools`, `profiles`, `school_memberships`, `platform_roles`, `teacher_assignments`, with RLS and helpers in `nano_internal`.

## Main surfaces

- Migrations `20260731050457_sec02_tenancy_rls` + `20260731050531_sec02_internalize_rls_helpers`
- Domain fixtures `TenancyFixtures`
- SQL adversarial check under `supabase/tests/`
