@echo off
REM Apartment Invoice Management System - Kubernetes Cleanup Script (Windows)

echo ========================================
echo Apartment Invoice Management System
echo Kubernetes Cleanup Script
echo ========================================
echo.

echo WARNING: This will delete all application resources from Kubernetes!
echo.
set /p confirm="Are you sure you want to continue? (yes/no): "

if /i not "%confirm%"=="yes" (
    echo Cleanup cancelled.
    exit /b 0
)

echo.
echo Deleting namespace 'doomed-apt'...
kubectl delete namespace doomed-apt

if %errorlevel% neq 0 (
    echo [ERROR] Failed to delete namespace
    exit /b 1
)

echo.
echo [OK] All resources have been deleted successfully!
echo.
echo The PersistentVolume data may still exist in Docker Desktop.
echo To completely reset, you can also clean Docker Desktop volumes.
echo.
pause
