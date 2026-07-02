$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$lua = Get-Command lua -ErrorAction SilentlyContinue
$lovec = Get-Command lovec -ErrorAction SilentlyContinue

if (-not $lua -and -not $lovec) {
    Write-Error "lua not found and lovec fallback unavailable. Install Lua 5.4+ or LOVE to run tests."
}

$tests = Get-ChildItem tests -Filter "*_test.lua" | Sort-Object Name
if (-not $tests -or $tests.Count -eq 0) {
    Write-Error "No *_test.lua files found under tests/."
}

if ($lua) {
    foreach ($test in $tests) {
        & $lua.Source $test.FullName
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    exit 0
}

$harnessRoot = Join-Path ([System.IO.Path]::GetTempPath()) "scriptorium-lovec-test-harness"
$harnessMain = Join-Path $harnessRoot "main.lua"
New-Item -ItemType Directory -Force -Path $harnessRoot | Out-Null
@'
local test_path = arg and arg[2]
if not test_path or test_path == "" then
    io.stderr:write("missing test path\n")
    love.event.quit(1)
    return
end

package.path = "./?.lua;./?/init.lua;" .. package.path
local ok, err = pcall(dofile, test_path)
if not ok then
    io.stderr:write(tostring(err) .. "\n")
    love.event.quit(1)
    return
end

love.event.quit(0)
'@ | Set-Content -LiteralPath $harnessMain -Encoding ASCII

foreach ($test in $tests) {
    & $lovec.Source $harnessRoot $test.FullName
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

exit 0
