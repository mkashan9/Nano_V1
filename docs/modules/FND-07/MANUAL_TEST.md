# FND-07 Manual Test Guide

## Setup

```powershell
cd D:\nano
dart pub get
dart run melos bootstrap
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Open **A11y** from the debug strip
- [ ] Toggle **Reduced motion** — motion sample becomes static
- [ ] Toggle **Classroom Mode** — sound switch shows paused; motion static
- [ ] Drag **Text size** — UI text scales
- [ ] Tap Success / Error try buttons (haptics may no-op on web)
- [ ] Captions sample banner when captions enabled

## Approve

`NEXT`

## Reject

`FIX: <problem>`
