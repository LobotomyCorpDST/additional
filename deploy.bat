@echo off
REM Apartment Invoice Management System - Kubernetes Deployment Script (Windows)

echo ========================================
echo Apartment Invoice Management System
echo Kubernetes Deployment Script
echo ========================================
echo.

REM Check if kubectl is installed
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] kubectl is not installed
    echo Please install kubectl and enable Kubernetes in Docker Desktop
    exit /b 1
)

REM Check if Kubernetes is running
kubectl cluster-info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Kubernetes cluster is not running
    echo Please enable Kubernetes in Docker Desktop Settings
    exit /b 1
)

echo Step 1: Creating namespace...
kubectl apply -f 00-namespace.yaml
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create namespace
    exit /b 1
)
echo [OK] Namespace created
echo.

echo Step 2: Deploying MySQL database...
kubectl apply -f 01-mysql.yaml
if %errorlevel% neq 0 (
    echo [ERROR] Failed to deploy MySQL
    exit /b 1
)
echo [OK] MySQL deployment created
echo.

echo Step 3: Waiting for MySQL to be ready (this may take 1-2 minutes)...
kubectl wait --for=condition=ready pod -l app=mysql -n doomed-apt --timeout=300s
if %errorlevel% neq 0 (
    echo [ERROR] MySQL pod failed to become ready
    echo Check logs with: kubectl logs -n doomed-apt -l app=mysql
    exit /b 1
)
echo [OK] MySQL is ready
echo.

echo Step 4: Deploying backend application...
kubectl apply -f 02-backend.yaml
if %errorlevel% neq 0 (
    echo [ERROR] Failed to deploy backend
    exit /b 1
)
echo [OK] Backend deployment created
echo.

echo Step 5: Waiting for backend to be ready (this may take 1-2 minutes)...
kubectl wait --for=condition=ready pod -l app=backend -n doomed-apt --timeout=300s
if %errorlevel% neq 0 (
    echo [ERROR] Backend pod failed to become ready
    echo Check logs with: kubectl logs -n doomed-apt -l app=backend
    exit /b 1
)
echo [OK] Backend is ready
echo.

echo Step 6: Deploying frontend application...
kubectl apply -f 03-frontend.yaml
if %errorlevel% neq 0 (
    echo [ERROR] Failed to deploy frontend
    exit /b 1
)
echo [OK] Frontend deployment created
echo.

echo Step 7: Waiting for frontend to be ready...
kubectl wait --for=condition=ready pod -l app=frontend -n doomed-apt --timeout=300s
if %errorlevel% neq 0 (
    echo [ERROR] Frontend pod failed to become ready
    echo Check logs with: kubectl logs -n doomed-apt -l app=frontend
    exit /b 1
)
echo [OK] Frontend is ready
echo.

echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Application is now running:
echo   Frontend:    http://localhost:32080
echo   Backend API: http://localhost:32081
echo   MySQL:       localhost:3306
echo.
echo Login credentials:
echo   Username: guest
echo   Password: guest123
echo.
echo Useful commands:
echo   View all resources:  kubectl get all -n doomed-apt
echo   View logs:           kubectl logs -n doomed-apt -l app=backend
echo   Delete deployment:   kubectl delete namespace doomed-apt
echo.
pause
