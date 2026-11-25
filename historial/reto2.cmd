@echo off
cd /d "%~dp0"
if not exist evidencias mkdir evidencias
rem Credencial ficticia, la misma definida en kong\kong.yml
set "API_KEY=demo-ficticia-3e5c63a79d7556f9"
echo Ejecutando pruebas del Reto 2...
call :pruebas > evidencias\reto2.txt 2>&1
type evidencias\reto2.txt
echo.
echo Salida guardada en evidencias\reto2.txt
exit /b

:pruebas
echo === Inicio: %date% %time% ===
echo --- Recargar Kong con la configuracion actual
docker compose up -d --wait --force-recreate kong
docker compose ps
for %%s in (estudiantes matriculas pagos) do (
  echo.
  echo ============ /api/%%s ============
  echo --- 1. Sin API Key
  curl.exe -s -i http://localhost:8000/api/%%s
  echo.
  echo --- 2. API Key incorrecta
  curl.exe -s -i -H "X-API-Key: clave-incorrecta" http://localhost:8000/api/%%s
  echo.
  echo --- 3. API Key valida ^(valor ficticio no mostrado^)
  curl.exe -s -i -H "X-API-Key: %API_KEY%" http://localhost:8000/api/%%s
  echo.
)
echo --- Logs de los mocks
docker compose logs --since 1m estudiantes matriculas pagos
exit /b
