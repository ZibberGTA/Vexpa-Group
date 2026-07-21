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

const { server, url } = await startServer(webRoot);
const browser = await puppeteer.launch({ headless: 'new' });
const page = await browser.newPage();
page.on('console', (msg) => console.error('PAGE LOG:', msg.text()));
await page.setViewport({ width: 1400, height: 900, deviceScaleFactor: 1 });

await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
await page.waitForFunction(
  () => {
    const status = document.getElementById('status')?.textContent || '';
    return status.startsWith('Map ready');
  },
  { timeout: 60000 },
).catch(async () => {
  const status = await page.evaluate(() => document.getElementById('status')?.textContent);
  console.error('MAP_READY_TIMEOUT', status);
});
await new Promise((r) => setTimeout(r, 2000));

const bootstrap = await page.evaluate(() => ({
  status: document.getElementById('status')?.textContent,
  hasGoogle: !!(window.google && window.google.maps),
  loadState: window.vexdaMapsLoadState || null,
  mapInnerHtmlLength: document.getElementById('map')?.innerHTML?.length || 0,
  gmStyleExists: !!document.querySelector('.gm-style'),
}));

console.error('BOOTSTRAP', JSON.stringify(bootstrap));

if (!bootstrap.hasGoogle) {
  console.log(JSON.stringify({ error: 'Maps JS API did not load', bootstrap }, null, 2));
  await browser.close();
  server.close();
  process.exit(0);
}

await page.evaluate(() => document.getElementById('analyze').click());
await new Promise((r) => setTimeout(r, 500));

const darkReport = await page.evaluate(() => {
  const text = document.getElementById('report').textContent;
  return JSON.parse(text);
});

await page.evaluate(() => document.getElementById('toggle-legacy-raster').click());
await new Promise((r) => setTimeout(r, 1500));
await page.evaluate(() => document.getElementById('analyze').click());
await new Promise((r) => setTimeout(r, 500));

const defaultReport = await page.evaluate(() => {
  const text = document.getElementById('report').textContent;
  return JSON.parse(text);
});

await page.evaluate(() => document.getElementById('toggle-fractional').click());
await new Promise((r) => setTimeout(r, 1500));
await page.evaluate(() => document.getElementById('analyze').click());
await new Promise((r) => setTimeout(r, 500));

const fractionalReport = await page.evaluate(() => {
  const text = document.getElementById('report').textContent;
  return JSON.parse(text);
});

console.log(JSON.stringify({ darkReport, defaultReport, fractionalReport }, null, 2));

await browser.close();
server.close();
