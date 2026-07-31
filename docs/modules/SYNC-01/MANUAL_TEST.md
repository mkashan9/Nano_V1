# SYNC-01 Manual Test Guide

## Prerequisites

```powershell
cd D:\nano
dart pub get
dart run melos bootstrap
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Debug bar shows **Offline**
- [ ] Offline page shows last-updated cache label and a pending attendance draft
- [ ] Tap **Simulate newer saved version** → conflict banner with Try again / Discard / Keep saved version
- [ ] Resolve conflict clears the banner
- [ ] Copy does not say “sync queue”
- [ ] Optional: `dart test` in `packages/nano_domain` and `packages/nano_data`

## Approve

`NEXT`

## Reject

`FIX: <problem>`
