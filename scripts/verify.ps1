# One-command workspace verify (Windows) — no global melos PATH required
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..
dart pub get
dart run melos bootstrap
dart run melos run verify
