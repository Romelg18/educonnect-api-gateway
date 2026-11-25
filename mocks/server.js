const http = require('node:http');

const SERVICE = process.env.SERVICE_NAME;
const PORT = 3000;

const DATA = {
  estudiantes: { id: 101, nombre: 'Ana Perez' },
  matriculas: { id: 501, estudianteId: 101, estado: 'ACTIVA' },
  pagos: { id: 701, matriculaId: 501, valor: 150.0, estado: 'PENDIENTE' },
  certificados: { id: 901, estudianteId: 101, tipo: 'MATRICULA', estado: 'EMITIDO' },
};

if (!Object.hasOwn(DATA, SERVICE)) {
  console.error(`SERVICE_NAME no válido: ${SERVICE}`);
  process.exit(1);
}

http
  .createServer((req, res) => {
    const found = req.method === 'GET' && req.url.split('?')[0] === `/${SERVICE}`;
    const status = found ? 200 : 404;

    // Registro en consola de cada solicitud recibida
    console.log(`${new Date().toISOString()} [${SERVICE}] ${req.method} ${req.url} -> ${status}`);

    // X-Service-Name permite comprobar qué servicio respondió
    res.writeHead(status, { 'Content-Type': 'application/json', 'X-Service-Name': SERVICE });
    res.end(JSON.stringify(found ? DATA[SERVICE] : { error: 'Recurso no encontrado' }));
  })
  .listen(PORT, () => console.log(`Mock ${SERVICE} escuchando en el puerto ${PORT}`));
