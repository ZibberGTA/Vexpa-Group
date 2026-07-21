import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(__dirname, '../web');

function startServer(root) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const urlPath = req.url === '/' ? '/maps_tile_diagnostic.html' : req.url.split('?')[0];
      const filePath = path.join(root, decodeURIComponent(urlPath.replace(/^\//, '')));
      if (!filePath.startsWith(root) || !fs.existsSync(filePath)) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      const ext = path.extname(filePath);
      const type =
        ext === '.html'
          ? 'text/html'
          : ext === '.js'
            ? 'text/javascript'
            : 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': type });
      fs.createReadStream(filePath).pipe(res);
    });
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address();
      resolve({ server, url: `http://127.0.0.1:${port}/maps_tile_diagnostic.html` });
    });
  });
}

async function waitForMapReady(page) {
  await page.waitForFunction(
    () => (document.getElementById('status')?.textContent || '').startsWith('Map ready'),
    { timeout: 60000 },
  );
  await new Promise((r) => setTimeout(r, 1500));
}

async function analyzeCurrent(page) {
  await page.evaluate(() => document.getElementById('analyze').click());
  await new Promise((r) => setTimeout(r, 300));
  return page.evaluate(() => JSON.parse(document.getElementById('report').textContent));
}

const { server, url } = await startServer(webRoot);
const browser = await puppeteer.launch({ headless: 'new' });
const page = await browser.newPage();

await page.setViewport({ width: 1400, height: 900, deviceScaleFactor: 1.25 });
await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
await waitForMapReady(page);
const dpr125Report = await analyzeCurrent(page);

await page.setViewport({ width: 1400, height: 900, deviceScaleFactor: 1 });
await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
await page.waitForFunction(() => window.google?.maps?.importLibrary, { timeout: 60000 });
await page.evaluate(async () => {
  const { Map, RenderingType } = await google.maps.importLibrary('maps');
  const mapDiv = document.getElementById('map');
  mapDiv.innerHTML = '';
  const map = new Map(mapDiv, {
    center: { lat: 51.5074, lng: -0.1278 },
    zoom: 11,
    disableDefaultUI: true,
    renderingType: RenderingType.VECTOR,
  });
  window.__diagMap = map;
  await new Promise((resolve) => google.maps.event.addListenerOnce(map, 'tilesloaded', resolve));
  document.getElementById('status').textContent = `Map ready (${map.getRenderingType()})`;
});
await new Promise((r) => setTimeout(r, 1500));
const vectorReport = await analyzeCurrent(page);

await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
await waitForMapReady(page);
await page.evaluate(() => document.getElementById('toggle-style').click());
await new Promise((r) => setTimeout(r, 1000));
const darkRasterReport = await analyzeCurrent(page);
await page.evaluate(() => document.getElementById('toggle-style').click());
await new Promise((r) => setTimeout(r, 500));

function summarize(label, report) {
  return {
    label,
    getRenderingType: report.configuration.getRenderingType,
    style: report.configuration.style,
    container: report.container,
    domSummary: report.domSummary,
    tilesWithFractionalGeometry: report.tileGridEvidence.tilesWithFractionalGeometry,
    tileLeftSample: report.tileSample.slice(0, 3).map((t) => t.left),
  };
}

console.log(
  JSON.stringify(
    {
      dpr125: summarize('devicePixelRatio=1.25', dpr125Report),
      vector: summarize('renderingType=VECTOR', vectorReport),
      darkRaster: summarize('vexda dark raster', darkRasterReport),
    },
    null,
    2,
  ),
);

await browser.close();
server.close();
