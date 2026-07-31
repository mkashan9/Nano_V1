# FND-04 Manual Test Guide

## Prerequisites

- Git + Flutter on PATH
- Melos bootstrap

## Student

```powershell
cd D:\nano
dart pub get
dart run melos bootstrap
cd apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

- [ ] Junior: bottom tabs Home / Play / Me; no Flex
- [ ] Switch to Senior: Learning / Games / Flex / Communities / Profile
- [ ] Switch to Independent: no Flex tab; Learning still works
- [ ] Tap **Deep link: Flex** as Independent — snackbar + Home (not Flex)
- [ ] As Senior, open Flex tab — placeholder visible
- [ ] Browser URL updates when switching tabs; refresh stays on a valid tab

## Teacher

```powershell
cd D:\nano\apps\teacher_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

- [ ] Tabs: Dashboard, Classes, Attendance, Marks, Classroom, Profile

## Admin web

```powershell
cd D:\nano\apps\admin_web
flutter run -d chrome --dart-define=NANO_ENV=development
```

- [ ] School side rail: Overview, Students, Teachers, Classes, Reports, Settings
- [ ] Switch to Superadmin: Platform, Schools, Content, Moderation, Analytics, Audit

## Approve

`NEXT`

## Reject

`FIX: <problem>`
