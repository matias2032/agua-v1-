@echo off
echo ========================================
echo   Iniciando Backend + Frontend (Windows)
echo ========================================

:: 1. Iniciar o Backend
cd "C:\desenvolvimento hibrido\agua(v1)\backend"
start "BACKEND" cmd /k "mvnw spring-boot:run"

:: Aguardar o Spring Boot iniciar
timeout /t 15 /nobreak

:: 2. Iniciar o Frontend para Windows
cd "C:\desenvolvimento hibrido\agua(v1)\frontend\vendedor_app"
start "FLUTTER WINDOWS" cmd /k "flutter run -d windows"

:: 3. Iniciar o Frontend para Chrome (Web)
:: --web-renderer foi removido no Flutter 3.22+
:: A forma correcta agora é --dart-define=FLUTTER_WEB_USE_SKIA=false (usa CanvasKit por omissão)
:: Para forçar o renderer HTML (equivalente ao antigo --web-renderer html):
@REM cd "C:\desenvolvimento hibrido\loja1\frontend\cliente_web"
@REM start "FLUTTER WEB" cmd /k "flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=false"

echo ========================================
echo   Tudo iniciado! Verifique as janelas.
echo ========================================