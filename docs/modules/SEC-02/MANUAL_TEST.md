# SEC-02 Manual Test Guide

## Checklist

- [ ] Migrations present: `sec02_tenancy_rls`, `sec02_internalize_rls_helpers`
- [ ] Run `powershell -File scripts\check_migration_layout.ps1`
- [ ] Dashboard/MCP: tables `schools`, `profiles`, `school_memberships`, `platform_roles`, `teacher_assignments` with RLS on
- [ ] Seed: Alpha + Beta schools; Ali/Bina/teacher/platform/indie profiles
- [ ] Adversarial: as Ali JWT, `select code from schools` returns only `ALPHA01`
- [ ] Security advisors clean for SEC-02 helpers

## Approve

`NEXT`

## Reject

`FIX: <problem>`
