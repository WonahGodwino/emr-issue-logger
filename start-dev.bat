@echo off
title EMR Issue Logger - Dev Startup
setlocal enabledelayedexpansion

set "PROJECT_DIR=%~dp0"

echo ============================================
echo   EMR Issue Logger - Starting Services
echo   Project: %PROJECT_DIR%
echo ============================================
echo.

:: --- Backend ---
echo [1/2] Building Backend...
cd /d "%PROJECT_DIR%backend"
go build -C "%PROJECT_DIR%backend" -o server.exe .\cmd\server\
if %ERRORLEVEL% NEQ 0 (
    echo       ERROR: Backend build failed! Check Go errors above.
    pause
    exit /b 1
)
echo       Backend built successfully.

start "EMR-Backend" cmd /k "cd /d %PROJECT_DIR%backend && server.exe"
echo       Backend starting in new window (port 8080).
echo.

:: Give the backend a moment to start initializing
ping -n 3 127.0.0.1 >nul

:: --- Frontend ---
echo [2/2] Starting Frontend (Angular on port 4200)...
start "EMR-Frontend" cmd /k "cd /d %PROJECT_DIR%frontend && npm start"
echo       Frontend starting in new window (port 4200).
echo.

echo ============================================
echo   Both services are launching...
echo.
echo   Frontend : http://localhost:4200
echo   Backend  : http://localhost:8080
echo.
echo   Close this window or press any key to exit.
echo   (Services run in their own windows)
echo ============================================
pause >nul