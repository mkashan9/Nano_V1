# MED-05 manual test

SQL against `nano_v1` in the Studio SQL editor, then one `admin_web` run. No
Docker, nothing to deploy.

`nano_v1` has never generated a real file, so step 2 plants two assets that look
exactly like a finished job except that no bytes exist behind the path. That is
enough to exercise every decision; the only thing you will not see is the
picture itself, which reads as **Preview unavailable**. Step 9 removes them.

## Fixtures

| Role | Email | Password | UUID |
|------|-------|----------|------|
| Superadmin | `platform@nano.dev` | `NanoPlatformDev1!` | `dddddddd-…` |
| School admin | `admin@alpha.nano.dev` | `NanoSchoolAdminDev1!` | `ffffffff-…` |
| Student | `ali@alpha.nano.dev` | — | `aaaaaaaa-…` |

Development fixtures only.

## 1. Nothing is published, because nothing has been decided

```sql
select count(*) as assets from public.generated_assets;
select count(*) as decisions from public.asset_review_events;
```

Expect `0` and `0`.

## 2. Plant two reviewable assets

Runs as your Studio session, then commits on purpose.

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select public.request_generated_asset(
  'image', 'med05_owner_test', 'A calm round companion waving.', 'v1'
) is not null as asked_one;
select public.request_generated_asset(
  'image', 'med05_screen_test', 'A companion pointing at a map.', 'v1'
) is not null as asked_two;

reset role;
update public.generated_assets
set status = 'ready',
    storage_bucket = 'generated-assets',
    storage_path = 'image/' || slot || '/en/hash.png',
    content_type = 'image/png',
    byte_size = 24576,
    checksum = 'sha256:' || slot,
    completed_at = timezone('utc', now())
where slot in ('med05_owner_test', 'med05_screen_test');
commit;
```

## 3. A learner sees nothing yet

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
select count(*) as visible
from public.list_generated_assets('image', 'en', 'med05_owner_test');
select nano_internal.asset_object_is_published(
  'image/med05_owner_test/en/hash.png'
) as file_readable;
rollback;
```

Expect `0` and `false`. This is the state every asset MED-01 through MED-04
produces.

## 4. Approving is publishing

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select public.review_generated_asset(
  (select id from public.generated_assets where slot = 'med05_owner_test'),
  'approved', 'Looks right.'
) ->> 'reviewed' as reviewed;
commit;
```

Expect `1`. Then re-run step 3: `1` and `true`. The catalog and the file open
together.

## 5. A rejection needs a reason, and then it un-publishes immediately

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
-- Expect NM010: a rejection needs a reason.
select public.review_generated_asset(
  (select id from public.generated_assets where slot = 'med05_owner_test'),
  'rejected', ''
);
rollback;
```

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select public.review_generated_asset(
  (select id from public.generated_assets where slot = 'med05_owner_test'),
  'rejected', 'Six fingers.'
) ->> 'reviewed' as reviewed;
commit;
```

Re-run step 3 once more: back to `0` and `false`, with no deploy in between.

## 6. Rejecting frees the slot instead of poisoning it

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select public.request_generated_asset(
  'image', 'med05_owner_test', 'A calm round companion waving.', 'v1'
) -> 'reused' as reused;
commit;
```

Expect `false` — a new attempt, not the rejected file handed back. There are now
two rows for that slot: the rejected one, and a fresh `requested` one with no
file.

## 7. A school admin is refused, not shown an empty list

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"ffffffff-ffff-ffff-ffff-ffffffffffff","role":"authenticated"}';
-- Expect NM010 on both.
select * from public.list_assets_for_review();
rollback;
```

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"ffffffff-ffff-ffff-ffff-ffffffffffff","role":"authenticated"}';
select public.review_generated_asset(
  (select id from public.generated_assets where slot = 'med05_screen_test'),
  'approved', 'Mine now.'
);
rollback;
```

## 8. The Moderation screen

```powershell
cd d:\nano\apps\admin_web
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=<project url> `
  --dart-define=SUPABASE_ANON_KEY=<publishable key>
```

Sign in as `platform@nano.dev`, then open **Moderation** in the side rail.

- **Unreviewed** is selected. `med05_screen_test` is listed and decidable;
  the fresh `med05_owner_test` row shows an hourglass, and Approve is disabled
  with "Only a ready asset can be approved" underneath.
- Select `med05_screen_test`. The prompt, provider, prompt version, feature, and
  cost are all shown — none of which a learner can ever read. The preview says
  **Preview unavailable**, because no bytes were ever uploaded.
- Press **Approve**. Expect "1 published". The row leaves the Unreviewed filter
  and appears under **Published**.
- Press **Reject** with the reason box empty. Expect the server's sentence in a
  snackbar and no change.
- Type a reason and press **Reject**. The row moves to **Rejected**, and
  **Review history** lists both decisions, newest first, each with your name.
- Switch the language to Urdu and confirm the screen is translated and
  `approved` still reads as published (شائع شدہ), not as approved paperwork.

## 9. Clean up

```sql
delete from public.generated_assets
where slot in ('med05_owner_test', 'med05_screen_test');

select count(*) as assets from public.generated_assets;
select count(*) as decisions from public.asset_review_events;
select count(*) as audit_survives
from public.audit_events
where target_type = 'generated_asset';
```

Expect `0`, `0`, and a non-zero audit count: the per-asset detail goes with the
asset, the durable record of who decided what does not.

You may also want to clear the image generation charges this test recorded:

```sql
delete from public.generation_usage where kind = 'image';
```

## 10. No secrets in clients

```powershell
cd d:\nano
rg -n "service_role|SUPABASE_SERVICE|PROVIDER_API_KEY" apps packages --glob "*.dart"
```

Expect no matches.

## Owner decision still pending

Deploying `generate-asset` with provider keys, so that a review can be made
against a real picture instead of a planted row. Until then, MED-05 is proven on
paths, policies, and refusals, not on bytes.

Reply `NEXT` to approve, or `FIX: …` if a decision or refusal looks wrong.
