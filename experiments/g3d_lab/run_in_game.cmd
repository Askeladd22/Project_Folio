@echo off
setlocal
pushd "%~dp0\..\.." || exit /b 1
set "MANUSCRIPT_G3D_DEBUG=1"
call "run_game.cmd"
set "EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %EXIT_CODE%
