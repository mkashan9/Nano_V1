# MED-03 manual test

Mostly SQL against the development project `nano_v1`, plus one run of the student
app. No Docker. Nothing needs deploying for this check — recordings are not
approved yet, and no player is attached, so you are confirming captions and
refusals, not hearing Aoede.

## 1. The voice and the nine lines are there

Supabase Studio → Table editor:

- `narration_voices`: one row, `aoede`, default and enabled, locales `en` and `ur`
- `narration_lines`: nine rows matching the companion script book
- `narration_line_versions`: nine published rows
- `generation_providers`: `gemini_voice_aoede` is the default for `voice`

## 2. Asking twice charges once; Urdu is a second recording

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select public.request_narration_line('greeting-2', 'en') -> 'reused' as first_ask;
select public.request_narration_line('greeting-2', 'en') -> 'reused' as second_ask;
select public.request_narration_line('greeting-2', 'ur') -> 'reused' as urdu_ask;

select scope, kind, requests_count
from public.generation_usage
where kind = 'voice'
order by scope;
rollback;
```

Expect `false`, `true`, `false`, and **two** voice charges (English once, Urdu
once). The second English ask cost nothing.

## 3. The personalised greeting cannot be recorded

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

-- Expect NM007
select public.request_narration_line('greeting-1', 'en');
rollback;
```

Expect `NM007`. No `generated_assets` row and no usage row for that attempt.

## 4. A learner reads wording and cannot author

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select count(*) as lines_visible from public.narration_lines;
select count(*) as wording from public.list_narration_lines('en');
select count(*) as with_audio from public.list_narration_lines('en')
  where storage_path is not null;
rollback;
```

Expect `lines_visible = 0`, `wording = 9`, `with_audio = 0`.

## 5. New wording hides the old recording

Covered by the checked-in suite. Skim:

```powershell
cd d:\nano
Get-Content supabase\tests\med03_voice_narration.sql
```

The block titled "New wording retires the old…" plants an approved recording for
`idle-1`, publishes new text, and asserts the old path is no longer offered.

## 6. The student app is captions only

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Nori speaks in captions exactly as after CMP-03 / MED-02. There is **no** Listen
control — no player is attached and nothing is approved. Switching language still
shows the right caption language. No spinner, no banner, no error about audio.

## 7. No provider key in any client

```powershell
cd d:\nano
rg -n "VOICE_PROVIDER_API_KEY|PROVIDER_API_KEY|service_role" apps packages --glob "*.dart"
```

Expect no matches.

## Owner decision pending

Deploying `generate-asset` with `VOICE_PROVIDER_API_KEY` still needs your
approval and is **not** done. Choosing a Flutter audio plugin and attaching it as
`voicePlayer` is a later step; the seam is ready.

Reply `NEXT` to approve, or `FIX: …` if a refusal, a caption, or a Listen control
looks wrong.
