@echo off
cd /d "%~dp0"
if not exist evidencias\repeticion mkdir evidencias\repeticion
rem Credencial ficticia, la misma definida en kong\kong.yml
set "API_KEY=demo-ficticia-3e5c63a79d7556f9"
set "URL=http://localhost:8000"
set "SALIDA=evidencias\repeticion\pruebas.txt"
echo Ejecutando todas las pruebas. Tarda varios minutos, no cierre la ventana...
call :pruebas > %SALIDA% 2>&1
type %SALIDA%
echo.
echo Salida guardada en %SALIDA%
exit /b

:pruebas
echo === Inicio: %date% %time% ===
docker compose up -d --wait --quiet-pull
docker compose ps
docker compose exec -T kong kong version
docker compose exec -T kong getent hosts estudiantes matriculas pagos certificados

echo.
echo ################ A. Autenticacion y rutas ################
call :reiniciar
for %%s in (estudiantes matriculas pagos certificados) do (
  call :sinclave %%s 401
  call :claveerronea %%s 401
  call :conclave %%s 200
)
echo.
echo --- Ruta no registrada. Esperado: 404
curl.exe -s -i --max-time 60 -H "X-API-Key: %API_KEY%" %URL%/api/no-existe
echo.

echo ################ B. Limite general: 5 por minuto ################
call :reiniciar
call :esperarminuto
for %%n in (1 2 3 4 5) do call :conclave estudiantes 200
call :conclave estudiantes 429
call :conclave matriculas 429
call :conclave pagos 429

echo ################ C. Limite de certificados: 3 por minuto ################
call :reiniciar
call :esperarminuto
for %%n in (1 2 3) do call :conclave certificados 200
call :conclave certificados 429
call :conclave estudiantes 200

echo ################ D. Backend no disponible y recuperacion ################
call :reiniciar
docker compose stop pagos
call :conclave pagos 503
call :conclave estudiantes 200
call :conclave matriculas 200
echo.
echo --- Logs de Kong sobre el fallo
docker compose logs --since 40s kong | findstr /C:"[error]"
docker compose start pagos
echo --- Esperando 45 segundos antes de comprobar la recuperacion
powershell -NoProfile -Command "Start-Sleep -Seconds 45"
call :conclave pagos 200
echo.
echo === Fin: %date% %time% ===
exit /b

:reiniciar
rem Recrear Kong reinicia el contador local de cuota
docker compose up -d --wait --force-recreate kong
exit /b

:esperarminuto
powershell -NoProfile -Command "Start-Sleep -Seconds (62 - (Get-Date).Second)"
exit /b

:sinclave
echo.
echo --- Sin API Key: GET /api/%1. Esperado: %2
curl.exe -s -i --max-time 60 %URL%/api/%1
echo.
exit /b

:claveerronea
echo.
echo --- API Key incorrecta: GET /api/%1. Esperado: %2
curl.exe -s -i --max-time 60 -H "X-API-Key: clave-incorrecta" %URL%/api/%1
echo.
exit /b

:conclave
echo.
echo --- API Key valida: GET /api/%1. Esperado: %2
curl.exe -s -i --max-time 60 -H "X-API-Key: %API_KEY%" %URL%/api/%1
echo.
exit /b
