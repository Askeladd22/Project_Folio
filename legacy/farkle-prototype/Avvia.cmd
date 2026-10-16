@echo off
rem Compatibility launcher: the repository root is the sole application.
call "%~dp0..\..\Avvia.cmd" %*
exit /b %ERRORLEVEL%
