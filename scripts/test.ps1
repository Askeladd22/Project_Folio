$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

if (-not (Get-Command lua -ErrorAction SilentlyContinue)) {
    Write-Error "lua not found. Install Lua 5.4+ to run tests."
}

$tests = Get-ChildItem tests -Recurse -Filter "*_test.lua" | Sort-Object FullName
if (-not $tests -or $tests.Count -eq 0) {
    Write-Error "No *_test.lua files found under tests/."
}

foreach ($test in $tests) {
    lua $test.FullName
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

exit 0
