@echo off
cd /d "%~dp0"
if not exist evidencias mkdir evidencias
call :pruebas > evidencias\reto0.txt 2>&1
type evidencias\reto0.txt
echo.
echo Salida guardada en evidencias\reto0.txt
exit /b

:pruebas
echo === Inicio: %date% %time% ===
echo --- docker compose up
docker compose up -d --wait
echo --- docker compose ps
docker compose ps
echo --- kong version
docker compose exec -T kong kong version
echo --- DNS interno
docker compose exec -T kong getent hosts estudiantes matriculas pagos
echo --- Mocks dentro de la red
docker compose exec -T estudiantes node -e "for (const s of ['estudiantes','matriculas','pagos']) fetch('http://'+s+':3000/'+s).then(async r => console.log(s, r.status, await r.text()))"
echo --- Gateway desde el equipo
curl.exe -s -i http://localhost:8000/api/pagos
echo.
echo --- Logs de los mocks
docker compose logs estudiantes matriculas pagos
exit /b
