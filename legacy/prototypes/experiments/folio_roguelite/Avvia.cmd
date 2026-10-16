@echo off
if exist "C:\Program Files (x86)\LOVE\love.exe" (
  start "" "C:\Program Files (x86)\LOVE\love.exe" "%~dp0folio-roguelite.love"
) else (
  echo Apri folio-roguelite.love con LOVE, oppure usa scripts/run_folio.py.
  pause
)
