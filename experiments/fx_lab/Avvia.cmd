@echo off
setlocal
cd /d "%~dp0"
if defined LOVE_EXE if exist "%LOVE_EXE%" (
  "%LOVE_EXE%" "%~dp0."
  exit /b
)
where love.exe >nul 2>nul
if not errorlevel 1 (
  love.exe "%~dp0."
  exit /b
)
if exist "%ProgramFiles%\LOVE\love.exe" (
  "%ProgramFiles%\LOVE\love.exe" "%~dp0."
  exit /b
)
if exist "%ProgramFiles(x86)%\LOVE\love.exe" (
  "%ProgramFiles(x86)%\LOVE\love.exe" "%~dp0."
  exit /b
)
echo LOVE 11 non trovato. Imposta LOVE_EXE al percorso di love.exe.
pause
