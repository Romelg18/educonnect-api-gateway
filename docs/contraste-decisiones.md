# Contraste de decisiones con documentación técnica

Consultado el 25/11/2026. La PoC usa Kong 3.9.5. Las páginas web de Kong no son específicas de esa versión y el código citado es de la etiqueta 3.9.1.

| Decisión o afirmación | Qué dice la fuente | Resultado | Fuente |
|---|---|---|---|
| Comunicación por nombre de servicio, sin IP fijas | Compose registra cada servicio en un DNS interno; la IP puede cambiar al recrear, el nombre se mantiene | Respaldado | [Docker: networking](https://docs.docker.com/compose/how-tos/networking/) |
| Modo DB-less con kong.yml | No requiere base de datos y permite versionar la configuración; los nodos son independientes | Respaldado | [Kong: DB-less](https://developer.konghq.com/gateway/db-less-mode/) |
| Service como destino y Route como criterio | La Route compara las peticiones y las envía a un Service, que representa el backend | Respaldado | [Routes](https://developer.konghq.com/gateway/entities/route/), [Services](https://developer.konghq.com/gateway/entities/service/) |
| strip_path: true | Quita la parte de la ruta que coincidió antes de reenviar | Respaldado y probado | [Routes](https://developer.konghq.com/gateway/entities/route/) |
| connect_timeout 5000 y retries 1 | Los valores por defecto son 60000 ms y 5 reintentos | Valores respaldados; efecto no probado | [Código: services.lua](https://raw.githubusercontent.com/Kong/kong/3.9.1/kong/db/schema/entities/services.lua) |
| X-API-Key, sin clave en la URL, hide_credentials | Por defecto: nombre apikey, se admite en la URL y no se oculta al backend | Cambios justificados; la eliminación de la cabecera no se probó en los mocks | [Código: esquema key-auth](https://raw.githubusercontent.com/Kong/kong/3.9.1/kong/plugins/key-auth/schema.lua) |
| La autenticación se evalúa antes del límite | Prioridad de key-auth 1250 y de rate-limiting 910 (la mayor se ejecuta antes) | Prioridades respaldadas | [key-auth handler](https://raw.githubusercontent.com/Kong/kong/3.9.1/kong/plugins/key-auth/handler.lua), [rate-limiting handler](https://raw.githubusercontent.com/Kong/kong/3.9.1/kong/plugins/rate-limiting/handler.lua) |
| Cuota compartida y contador propio de certificados | La clave del contador usa la ruta y el servicio de la configuración del plugin, el consumidor y el periodo | Respaldado y probado | [Código: contadores](https://raw.githubusercontent.com/Kong/kong/3.9.1/kong/plugins/rate-limiting/policies/init.lua) |
| Consumidor + ruta tiene prioridad sobre consumidor | La configuración más específica prevalece | Respaldado y probado | [Kong: Plugins](https://developer.konghq.com/gateway/entities/plugin/) |
| local no sirve como cuota global entre nodos; proponer Redis | local guarda el contador en cada nodo; redis lo comparte | Respaldado; no probado con varios nodos | [Kong: Rate Limiting](https://developer.konghq.com/plugins/rate-limiting/) |
| La opción cluster no se usa | Sin base de datos, el esquema solo admite local y redis | Respaldado | [Código: esquema rate-limiting](https://raw.githubusercontent.com/Kong/kong/3.9.1/kong/plugins/rate-limiting/schema.lua) |
| Fallo de Redis | fault_tolerant es true por defecto: si falla el almacén, las peticiones pasan sin aplicar el límite | Aspecto a decidir en producción | Mismo esquema |
| Una API Key válida no autoriza el acceso a cualquier registro | Cada operación sobre un objeto identificado requiere comprobar permisos sobre ese objeto | Respaldado | [OWASP API1:2023](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authori%7Aation/) |
| Versión kong:3.9.5 | La imagen oficial la listaba como parche 3.9.x más reciente | Respaldado en la fecha de consulta | [Docker Hub](https://hub.docker.com/_/kong) |

## Sin comprobar
- Que la caché DNS negativa causara el 503 posterior a la recuperación. El valor por defecto de dns_not_found_ttl (30 s) está en [kong.conf.default](https://raw.githubusercontent.com/Kong/kong/3.9.1/kong.conf.default), pero la causa no se demostró.
- La causa de las demoras de unos 4 s.
- Las mejoras de TLS, gestor de secretos, OAuth 2.0 / OpenID Connect, balanceo y observabilidad son propuestas; no se contrastaron una por una ni se probaron.
