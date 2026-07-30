# FND-01 Manual Test Guide

## Prerequisites

- Flutter stable on PATH
- Git on PATH
- **No Docker required**
- You do **not** need a global `melos` install on PATH

## Setup

```powershell
cd D:\nano
dart pub get
dart run melos bootstrap
```

Or:

```powershell
.\scripts\bootstrap.ps1
```

## Run student app (Chrome)

```powershell
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] `dart run melos bootstrap` succeeds (no Docker)
- [ ] App title shows **Nano**
- [ ] AppBar shows **DEV** badge
- [ ] **Open diagnostics** works and lists environment fields
- [ ] Teacher app runs: `cd apps\teacher_app; flutter run -d chrome`
- [ ] Admin web runs: `cd apps\admin_web; flutter run -d chrome`
- [ ] `.env.example` has names only
- [ ] `docs/setup/ENVIRONMENTS.md` describes remote-first `nano_v1` development

## Approve

Reply `NEXT`

## Reject

Reply `FIX: <problem>`
