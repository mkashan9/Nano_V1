# FND-01 Manual Test Guide

## Prerequisites

- Flutter stable on PATH
- Git on PATH
- **No Docker required**

## Setup

```powershell
cd d:\nano
dart pub global activate melos
# ensure Pub\Cache\bin is on PATH
melos bootstrap
```

## Run student app (Chrome)

```powershell
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] App title shows **Nano**
- [ ] AppBar shows **DEV** badge
- [ ] **Open diagnostics** works and lists environment fields
- [ ] Diagnostics does not appear when conceptually production (badge hidden for production enum)
- [ ] `melos bootstrap` succeeds without Docker
- [ ] Teacher app runs: `cd apps\teacher_app; flutter run -d chrome`
- [ ] Admin web runs: `cd apps\admin_web; flutter run -d chrome`
- [ ] `.env.example` has names only
- [ ] `docs/setup/ENVIRONMENTS.md` describes remote-first `nano_v1` development

## Approve

Reply `NEXT`

## Reject

Reply `FIX: <problem>`
