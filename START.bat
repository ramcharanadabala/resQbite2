@echo off
title ResQBite Setup
color 0A

echo.
echo  ==========================================
echo   ResQBite - Auto Setup and Run
echo  ==========================================
echo.

:: Step 1 - Go to backend folder
cd /d "%~dp0backend"
echo [1/5] Working directory: %CD%
echo.

:: Step 2 - Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found!
    echo Please download Python 3.12 from https://python.org/downloads
    echo Make sure to check "Add Python to PATH" during install
    pause
    exit /b 1
)
echo [2/5] Python found:
python --version
echo.

:: Step 3 - Create venv inside backend
echo [3/5] Creating virtual environment...
if exist ".venv" (
    echo   .venv already exists, skipping creation
) else (
    python -m venv .venv
    echo   .venv created
)
echo.

:: Step 4 - Install packages
echo [4/5] Installing packages (this may take 2-3 minutes)...
echo.
.venv\Scripts\python.exe -m pip install --upgrade pip --quiet
.venv\Scripts\python.exe -m pip install --only-binary :all: pydantic-core
.venv\Scripts\python.exe -m pip install -r requirements.txt
echo.
echo [4/5] Packages installed!
echo.

:: Step 5 - Run the server
echo [5/5] Starting ResQBite API server...
echo.
echo  ==========================================
echo   API running at: http://localhost:8000
echo   Docs at:        http://localhost:8000/api/docs
echo   Press Ctrl+C to stop
echo  ==========================================
echo.
.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

pause
