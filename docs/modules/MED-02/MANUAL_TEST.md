# MED-02 manual test

Mostly SQL against the development project `nano_v1`, plus one run of the student
app. No Docker, and nothing needs deploying.

## 1. The budgets are there

Supabase Studio → Table editor → `generation_quotas`. Expect four rows: a
platform budget for every kind, platform budgets for `video` and `voice`, and a
`companion` feature budget. `generation_usage` should be empty (nothing has been
generated today).

## 2. A curator can see the budgets; a learner cannot

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select scope, scope_key, kind, max_requests_per_day, requests_used
from public.generation_budget_status();
rollback;

begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
select count(*) as learner_sees from public.generation_budget_status();
rollback;
```

Expect four rows for the admin and `learner_sees = 0` — not an error, just
nothing. A dashboard for the wrong person shows an empty table rather than a
failure.

## 3. Asking twice charges once

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select public.request_generated_asset(
  'image', 'guide_greeting_staticArt', 'A friendly round companion waving', 'v1'
) -> 'reused' as first_ask;

select public.request_generated_asset(
  'image', 'guide_greeting_staticArt', 'A friendly round companion waving', 'v1'
) -> 'reused' as second_ask;

select scope, scope_key, kind, requests_count
from public.generation_usage
order by scope;
rollback;
```

Expect `false`, then `true`, and exactly **one** request counted against the
platform budget and one against the companion budget. The second ask cost
nothing, so it was charged nothing.

## 4. A spent budget refuses before any provider is reached

```sql
begin;
update public.generation_quotas
set max_requests_per_day = 0
where scope = 'platform' and scope_key = '' and kind = 'video';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

-- Expect an error naming the platform budget, and no row created.
select public.request_generated_asset(
  'video', 'celebration_celebration_shortClip', 'a short celebration', 'v1',
  'en', '16:9'
);
rollback;
```

Expect `NM006` with a message naming the budget. Note that the budget change had
to happen **before** the role switch: nobody signed in, superadmin included, has
write access to `generation_quotas` today.

## 5. Only an approved file is deliverable

```sql
select nano_internal.asset_object_is_published('image/nothing.png') as unknown_file;
```

Expect `false`. The checked-in suite covers the approved and unapproved cases with
seeded rows:

```powershell
cd d:\nano
Get-Content supabase\tests\med02_quotas_caching_fallback.sql
```

## 6. The learner's app is unchanged, and unbothered by a broken catalog

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Nori appears exactly as after CMP-03, from local art. The app asks for the
published catalog once behind the first screen; because nothing is approved yet it
gets an empty answer, and because a failure is treated the same way as an empty
answer, an offline device looks identical. No spinner, no banner, no error.

## 7. No provider key, and no key-shaped thing, in any client

```powershell
cd d:\nano
rg -n "PROVIDER_API_KEY|service_role" apps packages --glob "*.dart"
```

Expect no matches.

## Owner decision pending

Deploying `generate-asset` and setting provider secrets remotely still need your
approval and are **not** done. The budgets above are enforced in the database, so
they apply the moment the function is ever deployed.

Reply `NEXT` to approve, or `FIX: …` if a budget, a limit, or a fallback looks
wrong.
