import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(__dirname, '../web');

function readLocalMapsConfig() {
  const localPath = path.join(webRoot, 'vexda_maps_config.local.js');
  if (!fs.existsSync(localPath)) {
    return { apiKey: process.env.VEXDA_WEB_MAPS_API_KEY || '', mapId: process.env.VEXDA_WEB_MAPS_MAP_ID || '' };
  }
  const content = fs.readFileSync(localPath, 'utf8');
  const apiMatch = content.match(/apiKey:\s*'([^']*)'/);
  const mapMatch = content.match(/mapId:\s*'([^']*)'/);
  return {
    apiKey: (process.env.VEXDA_WEB_MAPS_API_KEY || apiMatch?.[1] || '').trim(),
    mapId: (process.env.VEXDA_WEB_MAPS_MAP_ID || mapMatch?.[1] || '').trim(),
  };
}

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

const localConfig = readLocalMapsConfig();
if (!localConfig.apiKey || !localConfig.mapId) {
  console.log(
    JSON.stringify(
      {
        skipped: true,
        reason:
          'Configure VEXDA_WEB_MAPS_API_KEY and VEXDA_WEB_MAPS_MAP_ID (run dart run tool/ensure_local_platform_config.dart) before vector verification.',
      },
      null,
      2,
    ),
  );
  process.exit(0);
}

const { server, url } = await startServer(webRoot);
const browser = await puppeteer.launch({
  headless: 'new',
  args: ['--use-gl=angle', '--enable-webgl', '--ignore-gpu-blocklist'],
});
const page = await browser.newPage();
await page.setViewport({ width: 1400, height: 900, deviceScaleFactor: 1 });

await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
await page.waitForFunction(
  () => (document.getElementById('status')?.textContent || '').startsWith('Map ready'),
  { timeout: 60000 },
);
await new Promise((r) => setTimeout(r, 2000));
await page.evaluate(() => document.getElementById('analyze').click());
await new Promise((r) => setTimeout(r, 300));

const report = await page.evaluate(() => JSON.parse(document.getElementById('report').textContent));

const result = {
  getRenderingType: report.configuration.getRenderingType,
  styleMode: report.configuration.styleMode,
  cloudMapIdConfigured: !!report.configuration.cloudMapId,
  rasterTileImgCount: report.domSummary.rasterTileImgCount,
  gmStyleCanvasCount: report.domSummary.gmStyleCanvasCount,
  vectorPipelineConfirmed: report.domSummary.vectorPipelineConfirmed,
  passed:
    report.configuration.getRenderingType === 'VECTOR' &&
    report.domSummary.rasterTileImgCount === 0 &&
    report.domSummary.gmStyleCanvasCount >= 1,
};

console.log(JSON.stringify(result, null, 2));

await browser.close();
server.close();
process.exit(result.passed ? 0 : 1);
