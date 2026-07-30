# FND-03 Manual Test Guide

## Prerequisites

- Git on PATH (new terminal after PATH changes)
- Flutter on PATH

## Setup

```powershell
cd D:\nano
dart pub get
dart run melos bootstrap
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Home shows Junior layout by default (Hi Ali, subject tiles)
- [ ] Toggle **Senior** — denser progress cards for the same Math/English/Science/Stories titles
- [ ] Open **Responsive preview** — switch Phone / Tablet / Web frames; grid columns change for Junior
- [ ] Resize Chrome window — content stays readable, max width capped on large screens
- [ ] No Docker required

## Approve

`NEXT`

## Reject

`FIX: <problem>`
