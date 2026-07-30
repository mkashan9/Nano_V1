# One-command workspace verify (Windows)
$ErrorActionPreference = "Stop"
dart pub global activate melos
melos bootstrap
melos run verify
