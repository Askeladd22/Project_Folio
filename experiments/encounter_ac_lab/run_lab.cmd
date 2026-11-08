@echo off
setlocal
cd /d "%~dp0\..\.."
where love >nul 2>&1
if errorlevel 1 (
  echo LÖVE 11.4 non e' nel PATH. Aggiungere love.exe al PATH.
  exit /b 1
)
love experiments\encounter_ac_lab %*
