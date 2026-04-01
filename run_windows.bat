@echo off
echo ========================================
echo   Iniciando Backend + Frontend (Windows)
echo ========================================

:: 1. Iniciar o Backend (local)
cd "C:\dev_hibrido\agua1\backend"
start "BACKEND" cmd /k "mvnw spring-boot:run"

:: Aguardar o Spring Boot iniciar
timeout /t 15 /nobreak

:: 2. Frontend Windows — aponta para PRODUÇÃO (Render)
cd "C:\dev_hibrido\agua1\frontend\vendedor_app"
start "FLUTTER WINDOWS (PROD)" cmd /k "flutter run -d windows -v --dart-define=API_BASE_URL=https://agua-v1.onrender.com --dart-define=FORCE_PROD=true"



:: 2b. Frontend Windows — aponta para LOCAL (descomenta para dev)
@REM start "FLUTTER WINDOWS (LOCAL)" cmd /k "flutter run -d windows"

:: 3. Frontend android — aponta para PRODUÇÃO (Render)
cd "C:\dev_hibrido\agua1\frontend\vendedor_app"
start "FLUTTER ANDROID (PROD)" cmd /k "flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://agua-v1.onrender.com --dart-define=FORCE_PROD=true"

@REM :: 2b. Frontend android — aponta para LOCAL (descomenta para dev)
@REM start "FLUTTER ANDROID (LOCAL)" cmd /k "flutter run -d emulator-5554"


echo ========================================
echo   Tudo iniciado! Verifique as janelas.
echo ========================================
pause