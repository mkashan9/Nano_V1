# FND-02 Manual Test Guide

## Prerequisites

- Flutter stable on PATH
- **Git on PATH** (required by Flutter/`dart pub get` on Windows)
- **No Docker required**

If `git` is not recognized, install Git for Windows, then **close and reopen** the terminal (Git was added to your User PATH).

## Setup

```powershell
cd D:\nano
git --version
dart pub get
dart run melos bootstrap
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Home uses dark Nano canvas (not light green placeholder)
- [ ] **Component gallery** opens from home (dev)
- [ ] Toggle **Junior / Senior** — Math action card vs progress card for same subject idea
- [ ] Loading / empty / error / offline / suspended states visible in gallery
- [ ] Companion slot and XP chip render
- [ ] Teacher app uses denser teacher theme
- [ ] Admin web uses school-admin theme
- [ ] No Docker required

## Approve

`NEXT`

## Reject

`FIX: <problem>`
