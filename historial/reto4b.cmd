@echo off
cd /d "%~dp0"
if not exist evidencias mkdir evidencias
rem Credencial ficticia, la misma definida en kong\kong.yml
set "API_KEY=demo-ficticia-3e5c63a79d7556f9"
call :pruebas > evidencias\reto4b-recuperacion.txt 2>&1
type evidencias\reto4b-recuperacion.txt
exit /b

:pruebas
echo === Inicio: %date% %time% ===
echo --- Sin recrear Kong
docker compose ps
curl.exe -s -i --max-time 60 -H "X-API-Key: %API_KEY%" http://localhost:8000/api/pagos
echo.
exit /b
