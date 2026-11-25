@echo off
cd /d "%~dp0"
if not exist evidencias mkdir evidencias
echo Ejecutando pruebas del Reto 1...
call :pruebas > evidencias\reto1.txt 2>&1
type evidencias\reto1.txt
echo.
echo Salida guardada en evidencias\reto1.txt
exit /b

:pruebas
echo === Inicio: %date% %time% ===
echo --- Recargar Kong con la configuracion actual
docker compose up -d --wait --force-recreate kong
docker compose ps
for %%s in (estudiantes matriculas pagos) do (
  echo.
  echo --- GET http://localhost:8000/api/%%s
  curl.exe -s -i http://localhost:8000/api/%%s
  echo.
)
echo --- Logs de los mocks
docker compose logs --since 1m estudiantes matriculas pagos
exit /b
