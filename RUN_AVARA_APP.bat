@echo off
setlocal enabledelayedexpansion
title AVARA Voice App Launcher
color 0b

echo ======================================================================
echo                     AVARA Voice-First App Launcher
echo ======================================================================
echo.

cd /d "c:\Vinya\Sem - 5\NLP\AVARA app"

:: Detect Python
where python >nul 2>nul
if !ERRORLEVEL! equ 0 (
    set "PYTHON_EXE=python"
) else if exist "C:\Users\mcasu\AppData\Local\Programs\Python\Python312\python.exe" (
    set "PYTHON_EXE=C:\Users\mcasu\AppData\Local\Programs\Python\Python312\python.exe"
) else (
    set "PYTHON_EXE=python"
)

:: Detect Flutter
where flutter >nul 2>nul
if !ERRORLEVEL! equ 0 (
    set "FLUTTER_BAT=flutter"
) else if exist "C:\Users\mcasu\Downloads\flutter_windows_3.50.0-stable\flutter\bin\flutter.bat" (
    set "FLUTTER_BAT=C:\Users\mcasu\Downloads\flutter_windows_3.50.0-stable\flutter\bin\flutter.bat"
) else (
    set "FLUTTER_BAT=flutter"
)

echo [Step 1/3] Checking AVARA Backend...
tasklist /FI "IMAGENAME eq python.exe" 2>NUL | find /I /N "python.exe">NUL
if "!ERRORLEVEL!"=="0" (
    echo [OK] Python backend is already running.
) else (
    echo Starting Python backend in background...
    start /b "" "!PYTHON_EXE!" -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --app-dir "c:\Vinya\Sem - 5\NLP\AVARA app\backend"
    echo [OK] Backend server started on http://127.0.0.1:8000.
)

echo.
echo [Step 2/3] Checking Flutter dependencies...
call "!FLUTTER_BAT!" pub get

echo.
echo [Step 3/3] Launching AVARA App in Chrome with Microphone Enabled...
echo ======================================================================
echo  Microphone is automatically approved via Chrome media flags.
echo  Opening at: http://localhost:5000
echo ======================================================================
echo.

call "!FLUTTER_BAT!" run -d chrome --web-port=5000 --web-browser-flag="--use-fake-ui-for-media-stream"

pause
