@echo off
setlocal
pushd "%~dp0" || exit /b 1
set "MANUSCRIPT_LOVE=%LOVE_EXE%"
if not defined MANUSCRIPT_LOVE if exist "C:\Program Files\LOVE\love.exe" set "MANUSCRIPT_LOVE=C:\Program Files\LOVE\love.exe"
if not defined MANUSCRIPT_LOVE if exist "C:\Program Files (x86)\LOVE\love.exe" set "MANUSCRIPT_LOVE=C:\Program Files (x86)\LOVE\love.exe"
if not defined MANUSCRIPT_LOVE (
  where love.exe >nul 2>nul
  if errorlevel 1 (
    echo LOVE 11.x non trovato. Imposta LOVE_EXE al percorso di love.exe.
    popd
    exit /b 1
  )
  set "MANUSCRIPT_LOVE=love.exe"
)
"%MANUSCRIPT_LOVE%" "%CD%" %*
set "MANUSCRIPT_EXIT=%ERRORLEVEL%"
popd
exit /b %MANUSCRIPT_EXIT%
