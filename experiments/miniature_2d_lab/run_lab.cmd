@echo off
setlocal
set "PROJECT_FOLIO_MINIATURE_LAB=1"
call "%~dp0..\..\run_game.cmd" %*
exit /b %ERRORLEVEL%
