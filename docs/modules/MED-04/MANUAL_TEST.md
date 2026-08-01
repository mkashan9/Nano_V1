# MED-04 manual test

Mostly SQL against `nano_v1`, plus one student app run. No Docker. Nothing needs
deploying — no clip is approved, so you are confirming the library and refusals,
not watching Veo.

## 1. The library and provider are there

Studio → Table editor:

- `reaction_clips`: three rows
- `reaction_clip_versions`: three published
- `generation_providers`: `gemini_veo_video` is the video default
- `list_reaction_clips()` returns 0 rows (nothing approved)

## 2. Ask twice, then ask a different shape

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select public.request_reaction_clip('celebration_celebration', '1:1')
  -> 'reused' as first_ask;
select public.request_reaction_clip('celebration_celebration', '1:1')
  -> 'reused' as second_ask;
select public.request_reaction_clip('celebration_celebration', '9:16')
  -> 'reused' as tall_ask;

select scope, kind, requests_count
from public.generation_usage
where kind = 'video';
rollback;
```

Expect `false`, `true`, `false`, and **two** video charges.

## 3. Unauthored shape and personalised refusals

```sql
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
-- Expect NM009
select public.request_reaction_clip('guide_greeting', '9:16');
rollback;
```

## 4. Student app is local art only

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Nori looks as after MED-03. No play badge — no approved clip and no player.
Captions and Listen (when wired later) are unchanged.

## 5. No provider key in clients

```powershell
cd d:\nano
rg -n "VIDEO_PROVIDER_API_KEY|VOICE_PROVIDER_API_KEY|service_role" apps packages --glob "*.dart"
```

Expect no matches.

## Owner decision pending

Deploy `generate-asset` with `VIDEO_PROVIDER_API_KEY`, and later choose a Flutter
video plugin. Neither is done.

Reply `NEXT` to approve, or `FIX: …` if a refusal or fallback looks wrong.
