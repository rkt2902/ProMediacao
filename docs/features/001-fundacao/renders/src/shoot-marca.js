// Gera os PNG das propostas de marca (renders/marca-<ideia>-<ecra>-<tamanho>.png).
// Uso: node docs/features/001-fundacao/renders/src/shoot-marca.js
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const SRC = __dirname;
const OUT = path.resolve(SRC, '..');
const ROOT = path.resolve(SRC, '../../../../..');
const BASE = '/docs/features/001-fundacao/renders/src/';
const SIZES = { telemovel: { width: 390, height: 844 }, desktop: { width: 1280, height: 800 } };

// [ideia, ecrã, página, página inteira?]
const SHOTS = [
  ['lombada', 'entrar', 'marca-entrar.html?ideia=lombada'],
  ['lombada', 'com-quem-partilho', 'marca-partilho.html?ideia=lombada'],
  ['selo', 'entrar', 'marca-entrar.html?ideia=selo'],
  ['selo', 'com-quem-partilho', 'marca-partilho.html?ideia=selo'],
  ['colofao', 'entrar', 'marca-entrar.html?ideia=colofao'],
  // O colofão está no fim da página: página inteira.
  ['colofao', 'com-quem-partilho', 'marca-partilho.html?ideia=colofao', true],
];
const TYPES = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.ttf': 'font/ttf', '.otf': 'font/otf' };

function serve() {
  const server = http.createServer((req, res) => {
    const p = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
    if (!p.startsWith(ROOT) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(p)] || 'application/octet-stream' });
    fs.createReadStream(p).pipe(res);
  });
  return new Promise((r) => server.listen(0, '127.0.0.1', () => r(server)));
}

(async () => {
  const server = await serve();
  const port = server.address().port;
  const browser = await chromium.launch();
  for (const [ideia, ecra, page, full] of SHOTS) {
    for (const size of Object.keys(SIZES)) {
      const ctx = await browser.newContext({ viewport: SIZES[size], deviceScaleFactor: 2 });
      const tab = await ctx.newPage();
      await tab.goto(`http://127.0.0.1:${port}${BASE}${page}`);
      await tab.evaluate(() => document.fonts.ready);
      await tab.waitForLoadState('networkidle');
      const erros = await tab.evaluate(() => [...document.fonts].filter((f) => f.status === 'error').map((f) => f.family));
      if (erros.length) console.warn(`  fontes com erro: ${erros.join(', ')}`);
      const file = path.join(OUT, `marca-${ideia}-${ecra}-${size}.png`);
      await tab.screenshot({ path: file, fullPage: !!full });
      console.log(path.relative(ROOT, file));
      await ctx.close();
    }
  }
  await browser.close();
  server.close();
})();
