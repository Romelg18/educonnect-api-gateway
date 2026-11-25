@echo off
cd /d "%~dp0"
if not exist evidencias mkdir evidencias
rem Credencial ficticia, la misma definida en kong\kong.yml
set "API_KEY=demo-ficticia-3e5c63a79d7556f9"
echo Ejecutando pruebas de Certificados (puede tardar mas de un minuto)...
call :pruebas > evidencias\reto5-certificados.txt 2>&1
type evidencias\reto5-certificados.txt
echo.
echo Salida guardada en evidencias\reto5-certificados.txt
exit /b

:pruebas
echo --- Levantar certificados y recargar Kong
docker compose up -d --wait --force-recreate kong
docker compose ps
echo --- Esperando el inicio del siguiente minuto
powershell -NoProfile -Command "Start-Sleep -Seconds (62 - (Get-Date).Second)"
echo === Inicio de la secuencia: %date% %time% ===
echo.
echo --- Sin API Key: GET /api/certificados
curl.exe -s -i http://localhost:8000/api/certificados
echo.
echo --- API Key incorrecta: GET /api/certificados
curl.exe -s -i -H "X-API-Key: clave-incorrecta" http://localhost:8000/api/certificados
echo.
for %%n in (1 2 3 4) do call :peticion %%n certificados
echo.
echo ----- Comprobacion del limite general despues de certificados -----
call :peticion 5 estudiantes
echo.
echo === Fin de la secuencia ===
powershell -NoProfile -Command "Get-Date -Format 'HH:mm:ss'"
echo --- Logs de los mocks
docker compose logs --since 1m certificados estudiantes
exit /b

:peticion
echo.
echo --- Peticion %1 con API Key valida: GET /api/%2
curl.exe -s -i -H "X-API-Key: %API_KEY%" http://localhost:8000/api/%2
echo.
exit /b
