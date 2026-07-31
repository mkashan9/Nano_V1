# Validates migration filenames without needing Docker or a live DB.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..
$files = Get-ChildItem supabase\migrations\*.sql -ErrorAction SilentlyContinue
if (-not $files) { Write-Error 'No migrations found under supabase/migrations'; exit 1 }
$bad = @()
foreach ($f in $files) {
  if ($f.Name -notmatch '^\d{14}_[a-z0-9_]+\.sql$') { $bad += $f.Name }
}
if ($bad.Count) {
  Write-Error ("Invalid migration names:`n" + ($bad -join "`n"))
  exit 1
}
Write-Host ("OK: {0} migration file(s)" -f $files.Count)
$files | ForEach-Object { Write-Host (' - ' + $_.Name) }
