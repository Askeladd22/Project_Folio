@echo off
setlocal
rem Isolated experiment: does not start the main game or touch its saves.
rem Optional: --seed 12345, --simulate 500, or --analyze
set "LOVE=C:\Program Files\LOVE\lovec.exe"
if not exist "%LOVE%" set "LOVE=C:\Program Files (x86)\LOVE\lovec.exe"
if not exist "%LOVE%" set "LOVE=lovec"
"%LOVE%" "%~dp0." %*
exit /b %ERRORLEVEL%
