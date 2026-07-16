import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:3000').replace(/\/$/, '');

export const options = {
  scenarios: {
    carga_normal: {
      executor: 'ramping-vus',
      stages: [
        { duration: '20s', target: 5 },
        { duration: '40s', target: 10 },
        { duration: '20s', target: 0 },
      ],
      gracefulRampDown: '10s',
    },
    estres_moderado: {
      executor: 'ramping-vus',
      startTime: '1m30s',
      stages: [
        { duration: '20s', target: 15 },
        { duration: '30s', target: 25 },
        { duration: '20s', target: 0 },
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.10'],
    http_req_duration: ['p(95)<3000'],
  },
};

const routes = ['/', '/login', '/registro', '/paquetes', '/workshops-conferencias', '/devwebcamp'];

export default function () {
  const path = routes[Math.floor(Math.random() * routes.length)];
  const res = http.get(`${BASE_URL}${path}`, { timeout: '20s' });
  check(res, {
    'HTTP 2xx o 3xx': (r) => r.status >= 200 && r.status < 400,
    'Respuesta menor a 3s': (r) => r.timings.duration < 3000,
  });
  sleep(1);
}

function metricValue(data, name, prop, fallback = 0) {
  if (!data.metrics[name] || data.metrics[name].values[prop] === undefined) return fallback;
  return data.metrics[name].values[prop];
}
function esc(value) {
  return String(value).replace(/[&<>"']/g, (m) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
}
function statusBadge(ok) { return ok ? '<span class="estado ok">APROBADO</span>' : '<span class="estado fail">FALLO</span>'; }

export function handleSummary(data) {
  const reqs = metricValue(data, 'http_reqs', 'count', 0);
  const failRate = metricValue(data, 'http_req_failed', 'rate', 0);
  const avg = metricValue(data, 'http_req_duration', 'avg', 0);
  const p95 = metricValue(data, 'http_req_duration', 'p(95)', 0);
  const max = metricValue(data, 'http_req_duration', 'max', 0);
  const checksRate = metricValue(data, 'checks', 'rate', 0);
  const okFailRate = failRate < 0.10;
  const okP95 = p95 < 3000;
  const okChecks = checksRate >= 0.90;
  const conclusion = okFailRate && okP95 && okChecks
    ? 'El sistema respondio dentro de los parametros definidos para carga y estres moderado.'
    : 'El sistema presenta degradacion o errores bajo carga. Revise servidor, base de datos, rutas con error y tiempos altos.';
  const rows = `
    <tr><td><strong>Tasa de errores HTTP</strong><span class="small">Umbral: menor a 10%</span></td><td>${statusBadge(okFailRate)}</td><td>${(failRate*100).toFixed(2)}%</td><td>Solicitudes evaluadas: ${reqs}</td><td>Corregir rutas con 4xx/5xx o problemas de disponibilidad.</td></tr>
    <tr><td><strong>Percentil 95 de respuesta</strong><span class="small">Umbral: menor a 3000 ms</span></td><td>${statusBadge(okP95)}</td><td>${p95.toFixed(2)} ms</td><td>Promedio: ${avg.toFixed(2)} ms<br>Maximo: ${max.toFixed(2)} ms</td><td>Optimizar consultas, recursos estaticos y respuesta del servidor.</td></tr>
    <tr><td><strong>Checks funcionales bajo carga</strong><span class="small">Umbral: al menos 90%</span></td><td>${statusBadge(okChecks)}</td><td>${(checksRate*100).toFixed(2)}%</td><td>Checks: HTTP 2xx/3xx y respuesta menor a 3s</td><td>Revisar las rutas que fallen durante usuarios concurrentes.</td></tr>`;
  const folio = 'PS-' + new Date().toISOString().replace(/[-:T]/g, '').slice(0, 12);
  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>08. Reporte de rendimiento k6</title><style>
*{box-sizing:border-box}
body{margin:0;background:#e9e9e9;font-family:Calibri,"Segoe UI",Arial,sans-serif;color:#222;line-height:1.5}
.page{max-width:960px;margin:26px auto 60px;background:#ffffff;padding:46px 56px;border:1px solid #c9c9c9;box-shadow:0 1px 4px rgba(0,0,0,.15)}
.folio{text-align:right;font-size:11px;color:#666;margin-bottom:2px}
.encabezado{border-bottom:3px double #333;padding-bottom:12px;margin-bottom:18px}
.encabezado h1{margin:0 0 4px;font-size:20px;font-weight:700;color:#111}
.encabezado .desc{font-size:13px;color:#444;margin:0}
.datos-generales{width:100%;border-collapse:collapse;margin:14px 0 22px;font-size:13px}
.datos-generales td{padding:5px 8px;border:1px solid #ccc;vertical-align:top}
.datos-generales td.et{background:#f2f2f2;font-weight:700;width:190px}
h2.tit{font-size:15px;margin:26px 0 8px;padding-bottom:4px;border-bottom:1px solid #999;color:#111}
.resumen-tabla{width:100%;border-collapse:collapse;margin-bottom:6px;font-size:13px}
.resumen-tabla th{background:#333;color:#fff;padding:7px 8px;text-align:left;font-weight:600}
.resumen-tabla td{padding:7px 8px;border:1px solid #ccc}
.conclusion{margin-top:10px;padding:10px 12px;border:1px solid #ccc;border-left:4px solid #555;background:#fafafa;font-size:13px}
table.detalle{width:100%;border-collapse:collapse;margin-top:8px;font-size:12.5px}
table.detalle th{background:#e6e6e6;color:#222;padding:7px 8px;text-align:left;border:1px solid #bbb;font-weight:700}
table.detalle td{padding:7px 8px;border:1px solid #ccc;vertical-align:top}
table.detalle tr:nth-child(even){background:#fafafa}
.small{display:block;color:#666;font-size:11px;margin-top:3px}
.estado{font-weight:700}
.estado.ok{color:#1a6b3c}
.estado.fail{color:#a3251d}
.pie{margin-top:34px;padding-top:12px;border-top:1px solid #ccc;font-size:11px;color:#777}
@media print{body{background:#fff}.page{box-shadow:none;border:none;margin:0;padding:20px}}
@media(max-width:800px){.page{padding:22px 18px}table.detalle{display:block;overflow-x:auto}}
</style></head><body>
<div class="page">
  <div class="folio">Folio interno: ${folio}</div>
  <div class="encabezado">
    <h1>08. Reporte de rendimiento, carga y estres con k6</h1>
    <p class="desc">Evalua el comportamiento del sistema con usuarios concurrentes sobre rutas publicas principales.</p>
  </div>
  <table class="datos-generales">
    <tr><td class="et">Categoria evaluada</td><td>Rendimiento / Carga y estres</td></tr>
    <tr><td class="et">Base URL evaluada</td><td>${esc(BASE_URL)}</td></tr>
    <tr><td class="et">Escenarios ejecutados</td><td>carga_normal y estres_moderado</td></tr>
  </table>
  <h2 class="tit">1. Resumen de resultados</h2>
  <table class="resumen-tabla">
    <tr><th>Solicitudes</th><th>Promedio</th><th>Percentil 95</th><th>Errores</th></tr>
    <tr><td>${reqs}</td><td>${avg.toFixed(0)} ms</td><td>${p95.toFixed(0)} ms</td><td>${(failRate*100).toFixed(2)}%</td></tr>
  </table>
  <div class="conclusion">${esc(conclusion)}</div>
  <h2 class="tit">2. Detalle de verificaciones</h2>
  <table class="detalle">
    <thead><tr><th style="width:20%">Criterio</th><th style="width:11%">Estado</th><th style="width:23%">Resultado</th><th style="width:26%">Evidencia</th><th style="width:20%">Recomendacion</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
  <div class="pie">Reporte generado automaticamente por el script de pruebas correspondiente a esta categoria. Conservar como evidencia de la ejecucion.</div>
</div>
</body></html>`;
  return {
    'reportes/08_reporte_rendimiento_k6.html': html,
    stdout: `\nReporte generado: reportes/08_reporte_rendimiento_k6.html\nSolicitudes: ${reqs}\nErrores: ${(failRate*100).toFixed(2)}%\nP95: ${p95.toFixed(2)} ms\n`,
  };
}
