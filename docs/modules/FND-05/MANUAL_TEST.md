# FND-05 Manual Test Guide

## Setup

```powershell
cd D:\nano
dart pub get
dart run melos bootstrap
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Open **UI states** from the debug strip
- [ ] Cycle Ready → Loading → Empty → Error (tap Try again)
- [ ] Offline / Syncing keep sample content visible with banners
- [ ] Suspended / Maintenance / Permission denied / Feature disabled replace content
- [ ] Open **Gallery** — new state widgets and sync banners appear
- [ ] No Docker required

## Approve

`NEXT`

## Reject

`FIX: <problem>`
