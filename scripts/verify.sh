#!/usr/bin/env bash
set -euo pipefail
dart pub global activate melos
melos bootstrap
melos run verify
