# Bootstrap Nano workspace (Windows) — no global melos PATH required
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..
dart pub get
dart run melos bootstrap
Write-Host "Bootstrap complete. Next: cd apps\student_app; flutter run -d chrome --dart-define=NANO_ENV=development"
