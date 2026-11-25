@echo off
cd /d "%~dp0"
if not exist evidencias mkdir evidencias
rem Credencial ficticia, la misma definida en kong\kong.yml
set "API_KEY=demo-ficticia-3e5c63a79d7556f9"
echo Ejecutando pruebas del Reto 4...
call :pruebas > evidencias\reto4.txt 2>&1
type evidencias\reto4.txt
echo.
echo Salida guardada en evidencias\reto4.txt
exit /b

:pruebas
echo === Inicio: %date% %time% ===
echo --- Recargar Kong (tambien reinicia el contador local de cuota)
docker compose up -d --wait --force-recreate kong

echo.
echo ============ 4a. Ruta no registrada ============
echo --- Con API Key valida
curl.exe -s -i --max-time 60 -H "X-API-Key: %API_KEY%" http://localhost:8000/api/no-existe
echo.
echo --- Sin API Key
curl.exe -s -i --max-time 60 http://localhost:8000/api/no-existe
echo.

echo ============ 4b. Backend no disponible ============
docker compose stop pagos
docker compose ps -a
call :peticion pagos
call :peticion estudiantes
call :peticion matriculas
echo.
echo --- Logs de Kong
docker compose logs --since 40s kong

echo.
echo ============ Recuperacion ============
docker compose start pagos
powershell -NoProfile -Command "Start-Sleep -Seconds 10"
docker compose ps
call :peticion pagos
echo === Fin ===
exit /b

:peticion
echo.
echo --- GET /api/%1
curl.exe -s -i --max-time 60 -w "\nTiempo total: %%{time_total} s\n" -H "X-API-Key: %API_KEY%" http://localhost:8000/api/%1
exit /b
