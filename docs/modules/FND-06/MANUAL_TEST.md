# FND-06 Manual Test Guide

## Setup

```powershell
cd D:\nano
dart pub get
dart run melos bootstrap
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Default English: Hi Ali, Subjects, Home/Play/Me
- [ ] Use debug strip **UR** — layout becomes RTL; greeting سلام Ali; مضامین
- [ ] Open **Locale** preview — sample Urdu sentence and RTL note
- [ ] Switch back to **EN** — LTR restored
- [ ] Teacher/Admin still launch (nav labels via NanoCopy)

## Approve

`NEXT`

## Reject

`FIX: <problem>`
