# Matriz de evidencias - EduConnect API Gateway

Integrantes: Romel Gualoto, Paulo Olivo, Issac Trujillo, Brandon Arellano.

Los scripts reto*.cmd citados están en historial/. Para repetir las pruebas con la configuración final se usa pruebas.cmd.

## Reto 0 - Despliegue
- Hipótesis (redactada DESPUÉS de ejecutar la prueba): sin rutas configuradas, GET /api/pagos da 404 de Kong, porque ninguna Route coincide, aunque el backend esté activo.
- Decisión: Kong 3.9.5 en modo DB-less con Docker Compose; red propia; solo se publica 127.0.0.1:8000.
- Prueba: reto0.cmd (25/11/2026, 14:53 hora local). Salida en reto0.txt.
- Resultado: Kong "healthy", versión 3.9.5; Kong resuelve estudiantes, matriculas y pagos; los 3 mocks responden 200 dentro de la red; GET http://localhost:8000/api/pagos da 404 "no Route matched with those values". Coincide con la hipótesis.
- Explicación: Kong usa los nombres de servicio, que el DNS interno de Docker traduce a las IP de los contenedores; no se fijan IP en la configuración.
- Limitación: no demuestra que Kong reenvíe tráfico a los backends (aún no hay Services ni Routes). El DNS prueba resolución de nombres, no una petición HTTP desde Kong.

## Reto 1 - Unificar el punto de acceso
- Hipótesis (escrita antes de la prueba): Si creo un Service y una Route por backend y consulto /api/estudiantes, /api/matriculas y /api/pagos, espero 200 con el JSON y X-Service-Name del servicio correcto, porque la Route identifica la petición y el Service define a qué destino enviarla.
- Decisión: un Service (destino) y una Route (criterio de coincidencia) por backend en kong.yml, con strip_path: true para quitar el prefijo público; las URL usan nombres de servicio, no IP.
- Prueba: reto1.cmd (25/11/2026, 15:01 hora local). Método GET a http://localhost:8000/api/estudiantes, /api/matriculas y /api/pagos, sin cabeceras adicionales. Salida en reto1.txt.
- Resultado: las tres peticiones dieron 200, con Content-Type application/json, el JSON esperado y X-Service-Name correcto. Cada mock registró su petición sin el prefijo /api. Coincide con la hipótesis.
- Observación: X-Kong-Proxy-Latency fue de unos 4000 ms en las tres peticiones (la primera a cada servicio tras recrear Kong), frente a 1-3 ms de X-Kong-Upstream-Latency. Causa no verificada.
- Limitación: las rutas siguen sin autenticación ni límite de consumo. No se probó el cambio de dirección de un backend, subrutas ni otros métodos HTTP.

## Reto 2 - Proteger el acceso con API Key
- Hipótesis (escrita antes de la prueba): Si activo key-auth en las tres rutas, espero 401 sin clave o con clave incorrecta y 200 con la clave válida, porque Kong comprueba que la credencial pertenezca a un Consumer antes de reenviar la petición.
- Decisión: plugin key-auth global; consumidor ficticio portal-externo-demo; credencial en la cabecera X-API-Key (desactivada en URL y cuerpo, para no exponerla en la dirección); hide_credentials: true para no reenviarla a los backends.
- Prueba: reto2.cmd (25/11/2026, 15:05 hora local). GET a /api/estudiantes, /api/matriculas y /api/pagos en http://localhost:8000: sin cabecera, con X-API-Key incorrecta y con X-API-Key válida. Salida en reto2.txt.
- Resultado: en las tres rutas, sin clave dio 401 "No API key found in request", con clave incorrecta 401 "Unauthorized" y con clave válida 200 con el JSON y X-Service-Name correctos. En los logs del período, cada mock registró una sola petición. Coincide con la hipótesis.
- Explicación: autenticación identifica al consumidor; autorización decide qué recursos puede usar. Una clave válida solo prueba que se presentó una credencial reconocida (que pudo ser robada o compartida), no que exista permiso sobre una matrícula o un dato personal.
- Limitación: no hay autorización por recurso ni identidad de usuario final. La conexión es HTTP sin cifrar (solo local). No se comprobó en los backends que la cabecera de la clave se haya eliminado. Todavía no hay límite de consumo.

## Reto 3 - Controlar el consumo
- Hipótesis (escrita antes de la prueba): Si limito al consumidor a 5 solicitudes por minuto y envío 6 válidas dentro del mismo minuto, espero que las 5 primeras den 200 y la sexta 429, porque supera la cuota de la ventana. Si la secuencia cruza al minuto siguiente, el contador puede reiniciarse. Alcance (añadido antes de la prueba): como el plugin se aplica solo al consumidor, espero que la cuota sea compartida por las tres rutas; si tras superarla en /api/estudiantes consulto /api/matriculas y /api/pagos en el mismo minuto, también darán 429.
- Decisión: plugin rate-limiting aplicado al consumidor portal-externo-demo: minute 5, policy local, limit_by consumer. Alcance observado: una sola cuota para las tres rutas.
- Prueba: reto3.cmd (25/11/2026). GET a http://localhost:8000 con X-API-Key válida: 6 veces /api/estudiantes, 1 /api/matriculas y 1 /api/pagos. Inicio 15:09:02, fin 15:09:16 (hora local), dentro del mismo minuto. Solicitudes previas: ninguna del consumidor desde que se recreó Kong. Salida en reto3.txt.
- Resultado: peticiones 1-5 dieron 200 y X-RateLimit-Remaining-Minute bajó de 4 a 0; la 6 dio 429 "API rate limit exceeded" con Retry-After: 45; la 7 (matriculas) y la 8 (pagos) también dieron 429. Los mocks registraron solo las 5 peticiones aceptadas. Coincide con la hipótesis y con el alcance previsto.
- Observación: las peticiones 1, 2 y 4 tuvieron X-Kong-Proxy-Latency de unos 4000 ms; la 3 y la 5, 1 ms. La demora no ocurre solo en la primera petición a un servicio. Causa no verificada.
- Con varias instancias (análisis, no probado): con policy local cada nodo cuenta por separado; con N nodos y tráfico repartido se podrían aceptar hasta 5 x N por minuto, y el contador se pierde al recrear el nodo. Propuesta: contador compartido en Redis, con alta disponibilidad, sincronización en tiempo real si se requiere precisión y una decisión sobre qué hacer si Redis falla.
- Limitación: no se probó el reinicio de la cuota en el minuto siguiente ni varias instancias. El límite por consumidor no limita las peticiones rechazadas por autenticación (por diseño; no probado).

## Reto 4a - Ruta no registrada
- Hipótesis (escrita antes de la prueba): Si consulto /api/no-existe, espero 404, porque ninguna Route coincide.
- Decisión: probar con y sin credencial.
- Prueba: reto4.cmd (25/11/2026, 15:11 hora local). GET http://localhost:8000/api/no-existe, con X-API-Key válida y sin ella. Salida en reto4.txt.
- Resultado: 404 "no Route matched with those values" en ambos casos. Coincide con la hipótesis.
- Limitación: solo se probó una ruta inexistente con método GET.

## Reto 4b - Backend no disponible
- Hipótesis (escrita antes de la prueba): Si detengo solo el mock de pagos y consulto /api/pagos con clave válida y cuota disponible, espero un error 5xx (probablemente 503) y que las otras rutas sigan en 200, porque Kong no podrá localizar o alcanzar ese backend.
- Decisión: detener solo el mock pagos. Antes de la prueba se fijó connect_timeout 5000 ms y retries 1 en los tres Services.
- Prueba: reto4.cmd. GET /api/pagos, /api/estudiantes y /api/matriculas con X-API-Key válida.
- Resultado: pagos dio 503 "name resolution failed" en 11,99 s; estudiantes y matriculas dieron 200. El log de Kong muestra "DNS resolution failed ... name error". Coincide con la hipótesis.
- Explicación: el fallo ocurrió al resolver el nombre, antes de intentar la conexión, por lo que esta prueba no demuestra el efecto de connect_timeout ni de retries.
- Recuperación (diferencia no prevista): unos 13 s después de arrancar de nuevo (según docker compose ps) y unos 23 s después del primer error, pagos seguía dando 503 (en 0,03 s). Posible causa: caché de la respuesta DNS negativa (dns_not_found_ttl, 30 s por defecto según kong.conf.default de Kong 3.9.1). Comprobación posterior: ver el punto siguiente.
- Hipótesis de recuperación (escrita antes de la segunda consulta): si consulto /api/pagos más de 30 s después del error, sin recrear Kong, espero 200 porque la respuesta DNS negativa guardada ya habrá vencido.
- Resultado de recuperación: reto4b.cmd (15:13:51 hora local), sin recrear Kong: 200 con X-Service-Name: pagos, unos 113 s después del primer error. Coincide. Confirma que Kong se recupera sin reiniciarlo; no demuestra que la causa fuera la caché DNS ni el tiempo exacto de recuperación.
- Limitación: solo se probó un backend detenido; no un backend lento ni uno que responda con errores.

## Desafío de transferencia - Certificados
- Hipótesis (escrita antes de la prueba): Si publico /api/certificados con API Key y un límite propio de 3 solicitudes por minuto, espero 401 sin clave, 200 en las 3 primeras válidas y 429 en la cuarta, porque una política más específica para esa ruta reemplaza al límite general. Independencia (añadido antes de la prueba): como el límite de certificados es otra instancia asociada a su ruta, espero un contador separado; tras las peticiones a certificados, la primera a /api/estudiantes en el mismo minuto dará 200 con 4 de 5 restantes.
- Decisión: cuarto mock certificados, con Service y Route /api/certificados; protegido por el key-auth global; segunda instancia de rate-limiting (consumidor + ruta) con minute 3, policy local.
- Prueba: reto5.cmd (25/11/2026). GET http://localhost:8000/api/certificados sin clave, con clave incorrecta y 4 veces con X-API-Key válida; luego 1 vez /api/estudiantes. Inicio 15:17:02, fin 15:17:20 (hora local). Salida en reto5-certificados.txt.
- Resultado: 401 sin clave y con clave incorrecta; válidas 1-3 dieron 200 (límite 3, restantes 2, 1, 0); la 4 dio 429 con Retry-After: 46. Después /api/estudiantes dio 200 con 4 de 5 restantes. El mock certificados registró solo las 3 aceptadas. Coincide con la hipótesis y con la independencia prevista.
- Trade-off: con contadores independientes, el consumidor puede lograr hasta 8 solicitudes aceptadas por minuto en total (3 en certificados y 5 compartidas en las otras rutas); si se exigiera un máximo total de 5, esta configuración no lo cumple. El máximo de 8 se deduce de ambos límites; no se probó en una sola ventana.
- Limitación: no hay autorización por certificado ni por estudiante; contador local, válido para una sola instancia.

## Repetición con la configuración final
- Prueba: pruebas.cmd (25/11/2026, 15:21:37 a 15:25:47 hora local). Salida en repeticion/pruebas.txt.
- Resultado: las 30 respuestas HTTP coincidieron con el estado esperado (401, 200, 404, 429, 503 y recuperación 200).
- Limitación: se ejecutó en el mismo equipo, con las imágenes ya descargadas; no demuestra el funcionamiento en otro equipo ni con descarga de imágenes desde cero.
- Segunda repetición: después de docker compose down, pruebas.cmd (15:27:56 a 15:31:49 hora local) volvió a crear la red y los contenedores; las 30 respuestas coincidieron con lo esperado. La salida anterior de repeticion/pruebas.txt fue reemplazada.
