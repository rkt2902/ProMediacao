// Gera os PNG de referência da feature 001.
// Uso (a partir de qualquer pasta): node docs/features/001-fundacao/renders/src/shoot.js [filtro]
// Serve a raiz do repositório por HTTP local (as fontes vêm de assets/fonts).
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const SRC = __dirname;
const OUT = path.resolve(SRC, '..');
const ROOT = path.resolve(SRC, '../../../../..');
const BASE = '/docs/features/001-fundacao/renders/src/';

const SIZES = {
  telemovel: { width: 390, height: 844 },
  tablet: { width: 768, height: 1024 },
  desktop: { width: 1280, height: 800 },
};
const ALL = ['telemovel', 'tablet', 'desktop'];

// [nome do ficheiro, página, tamanhos, página inteira?]
const SHOTS = [
  ['entrar', 'entrar.html', ALL],
  ['entrar-link-enviado', 'entrar.html?estado=enviado', ALL],
  ['criar-palavra-passe', 'criar-palavra-passe.html', ALL],
  ['recuperar-palavra-passe', 'recuperar.html', ALL],
  ['link-expirado', 'link-expirado.html', ALL],
  ['link-expirado-enviado', 'link-expirado.html?estado=enviado', ALL],
  ['consentimento', 'consentimento.html', ALL],
  ['consentimento-completo', 'consentimento.html', ['telemovel'], true],
  ['com-quem-partilho', 'com-quem-partilho.html', ALL],
  ['com-quem-partilho-completo', 'com-quem-partilho.html', ['telemovel'], true],
  ['conta-cliente', 'com-quem-partilho.html#conta', ALL],
  ['retirar-acesso', 'com-quem-partilho.html?folha=retirar', ALL],
  ['clientes', 'clientes.html', ALL],
  ['clientes-completo', 'clientes.html', ['telemovel'], true],
  ['clientes-vazio', 'clientes.html?estado=vazio', ALL],
  ['criar-cliente', 'clientes.html?folha=criar', ALL],
  ['admin', 'admin.html', ['telemovel', 'desktop']],
  ['admin-completo', 'admin.html', ['telemovel'], true],
];

const TYPES = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.ttf': 'font/ttf', '.otf': 'font/otf' };

function serve() {
  const server = http.createServer((req, res) => {
    const p = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
    if (!p.startsWith(ROOT) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) {
      res.writeHead(404); res.end(); return;
    }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(p)] || 'application/octet-stream' });
    fs.createReadStream(p).pipe(res);
  });
  return new Promise((r) => server.listen(0, '127.0.0.1', () => r(server)));
}

(async () => {
  const filter = process.argv[2];
  const server = await serve();
  const port = server.address().port;
  const browser = await chromium.launch();
  for (const [name, page, sizes, full] of SHOTS) {
    if (filter && !name.startsWith(filter)) continue;
    for (const size of sizes) {
      const ctx = await browser.newContext({ viewport: SIZES[size], deviceScaleFactor: 2 });
      const tab = await ctx.newPage();
      await tab.goto(`http://127.0.0.1:${port}${BASE}${page}`);
      await tab.evaluate(() => document.fonts.ready);
      const fonts = await tab.evaluate(() => [...document.fonts].filter((f) => f.status === 'error').map((f) => f.family));
      // Âncora no endereço: mostra essa secção no topo da janela.
      await tab.evaluate(() => { if (location.hash) document.querySelector(location.hash).scrollIntoView(); });
      if (fonts.length) console.warn(`  fontes com erro em ${name}: ${fonts.join(', ')}`);
      // Página inteira: a barra fixa aparece no fim, onde fica ao acabar o scroll.
      if (full) await tab.addStyleTag({ content: '.barra-fixa { position: static; }' });
      const file = path.join(OUT, `${name}-${size}.png`);
      await tab.screenshot({ path: file, fullPage: !!full });
      console.log(path.relative(ROOT, file));
      await ctx.close();
    }
  }
  await browser.close();
  server.close();
})();
