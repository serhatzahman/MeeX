@echo off
title MeeX Server
chcp 65001 > nul
cd /d "%~dp0"

echo ========================================================
echo         MeeX - Nokia N9 X (Twitter) Bridge Server
echo ========================================================
echo.

echo [1/2] Checking Python dependencies...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies. Make sure Python 3.10+ and pip are installed.
    pause
    exit /b %errorlevel%
)

echo.
echo [2/2] Starting MeeX Server...
echo.
python MeeX.py

pause
