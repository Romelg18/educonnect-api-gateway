@echo off
cd /d "%~dp0"
if not exist evidencias mkdir evidencias
rem Credencial ficticia, la misma definida en kong\kong.yml
set "API_KEY=demo-ficticia-3e5c63a79d7556f9"
echo Ejecutando pruebas del Reto 3 (puede tardar mas de un minuto)...
call :pruebas > evidencias\reto3.txt 2>&1
type evidencias\reto3.txt
echo.
echo Salida guardada en evidencias\reto3.txt
exit /b

:pruebas
echo --- Recargar Kong con la configuracion actual
docker compose up -d --wait --force-recreate kong
echo --- Esperando el inicio del siguiente minuto
powershell -NoProfile -Command "Start-Sleep -Seconds (62 - (Get-Date).Second)"
echo === Inicio de la secuencia: %date% %time% ===
for %%n in (1 2 3 4 5 6) do call :peticion %%n estudiantes
call :peticion 7 matriculas
call :peticion 8 pagos
echo.
echo === Fin de la secuencia ===
powershell -NoProfile -Command "Get-Date -Format 'HH:mm:ss'"
echo --- Logs de los mocks
docker compose logs --since 1m estudiantes matriculas pagos
exit /b

:peticion
echo.
echo --- Peticion %1: GET /api/%2
curl.exe -s -i -H "X-API-Key: %API_KEY%" http://localhost:8000/api/%2
echo.
exit /b
