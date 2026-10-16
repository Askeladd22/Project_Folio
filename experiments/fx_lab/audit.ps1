param([string]$LoveExe = 'C:\Program Files (x86)\LOVE\love.exe')
$ErrorActionPreference='Stop'
$labRoot=$PSScriptRoot
$auditPath=Join-Path $labRoot 'audit'
New-Item -ItemType Directory -Path $auditPath -Force | Out-Null
$oldAudit=$env:FX_LAB_AUDIT
try {
 $env:FX_LAB_AUDIT=$auditPath
 $process=Start-Process -FilePath $LoveExe -ArgumentList ('"'+$labRoot+'"') -WindowStyle Hidden -PassThru
 if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'LOVE audit exceeded 60 seconds; inspect audit/error.txt.' }
 if ($process.ExitCode -ne 0) { throw "LOVE exited with $($process.ExitCode)" }
 Get-Content -LiteralPath (Join-Path $auditPath 'runtime.txt')
 Get-Content -LiteralPath (Join-Path $auditPath 'metrics.csv')
} finally { $env:FX_LAB_AUDIT=$oldAudit }
