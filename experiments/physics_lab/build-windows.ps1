$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $root
$dir = Join-Path $root 'experiments\physics_lab\build'
New-Item -ItemType Directory -Force $dir | Out-Null
$source = Join-Path $root 'experiments\physics_lab\fpslab.c'
$output = Join-Path $dir 'fpslab.dll'
if (Get-Command cl.exe -ErrorAction SilentlyContinue) {
    # Use a VS x64 Developer PowerShell / Native Tools prompt.
    & cl.exe /nologo /O2 /LD /W3 /D_CRT_SECURE_NO_WARNINGS /Fe:"$output" "$source" /link /OUT:"$output"
} elseif (Get-Command gcc.exe -ErrorAction SilentlyContinue) {
    & gcc.exe -O2 -std=c99 -shared -Wall -Wextra "$source" -o "$output" -lm
} elseif (Get-Command clang.exe -ErrorAction SilentlyContinue) {
    & clang.exe -O2 -std=c99 -shared "$source" -o "$output" -lm
} else {
    throw 'C compiler not found. Open an x64 Visual Studio Developer PowerShell or install MinGW.'
}
if ($LASTEXITCODE -ne 0 -or !(Test-Path $output)) { throw 'Experimental FPS DLL compilation failed' }
Write-Host "Built $output (lab only, not part of the game)"
