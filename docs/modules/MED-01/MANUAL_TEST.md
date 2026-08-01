# MED-01 manual test

This module is server-side, so most of it is checked in the Supabase SQL editor
against the development project `nano_v1`. No Docker, and nothing needs deploying.

## 1. The schema is there

Supabase Studio → Table editor. Confirm `generation_providers` has three rows
(`pollinations_image`, `configured_voice`, `configured_video`), and that
`generated_assets` and `generation_attempts` exist and are empty. Storage should
list a private bucket `generated-assets`.

## 2. A learner is locked out

SQL editor:

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
select
  (select count(*) from public.generated_assets)     as assets,
  (select count(*) from public.generation_providers) as providers,
  (select count(*) from public.list_generated_assets()) as published,
  has_function_privilege(
    'authenticated', 'public.claim_generated_asset(uuid)', 'execute'
  ) as can_claim;
rollback;
```

Expect zeros and `can_claim = false`.

## 3. An identical ask is free

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select public.request_generated_asset(
  'image', 'guide_greeting_staticArt', 'A friendly round companion waving', 'v1'
) -> 'reused' as first_ask;
select public.request_generated_asset(
  'image', 'guide_greeting_staticArt', '  a friendly   ROUND companion waving ', 'v1'
) -> 'reused' as second_ask;
rollback;
```

Expect `false` then `true`: the same ask in different spacing and case is one
asset, so a provider would be called once.

## 4. Everything else is covered by the checked-in suite

```powershell
cd d:\nano
Get-Content supabase\tests\med01_generated_asset_adapters.sql
```

That file is what was run against development for this module (worker claim,
duplicate callbacks, failure and retry, publication gate). Results are in
TEST_REPORT.

## 5. No provider key is anywhere near the client

```powershell
cd d:\nano
rg -n "PROVIDER_API_KEY|service_role" apps packages --glob "*.dart"
```

Expect no matches.

## 6. The learner's app is unchanged

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Nori still appears exactly as after CMP-03, drawn from local art. That is the
intended outcome: nothing generated is published, and nothing generated is
required.

## Owner decision pending

Deploying `generate-asset` and setting `VOICE_PROVIDER_API_KEY` /
`VIDEO_PROVIDER_API_KEY` remotely both need your approval and are **not** done.
Say so explicitly if you want the image path deployed to development so a real
picture can be generated end to end.

Reply `NEXT` to approve, or `FIX: …` if a rule or a boundary looks wrong.
