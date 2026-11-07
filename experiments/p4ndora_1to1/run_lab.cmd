@echo off
setlocal
cd /d "%~dp0"
where love >nul 2>&1
if errorlevel 1 (
    echo LÖVE 11.x non trovato nel PATH.
    echo Installa LÖVE da https://love2d.org/
    pause
    exit /b 1
)
love .
