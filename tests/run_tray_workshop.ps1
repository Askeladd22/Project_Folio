param([string]$OutputDir = 'tmp/tray-workshop')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$outputPath = [System.IO.Path]::GetFullPath((Join-Path $projectPath $OutputDir))
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
$env:MANUSCRIPT_TRAY_WORKSHOP_SMOKE = '1'
$env:MANUSCRIPT_WORKSHOP_OUT = $outputPath
$lovePath = (Get-Command love).Source
$process = Start-Process -FilePath $lovePath -ArgumentList ('"' + $projectPath + '"') -WorkingDirectory $projectPath -WindowStyle Hidden -PassThru
if (-not $process.WaitForExit(210000)) { Stop-Process -Id $process.Id; throw 'Workshop verification timed out' }
Get-Content -LiteralPath (Join-Path $outputPath 'checks.log')
if ($process.ExitCode -ne 0) { throw "LOVE exited $($process.ExitCode)" }
