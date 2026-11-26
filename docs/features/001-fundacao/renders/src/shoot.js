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
  fluxo: { width: 1600, height: 900 },
};
const ALL = ['telemovel', 'tablet', 'desktop'];
const ADMIN = ['telemovel', 'desktop'];

// [nome do ficheiro, página, tamanhos, página inteira?]
const SHOTS = [
  // Entrar e palavra-passe
  ['entrar', 'entrar.html', ALL],
  ['entrar-link-enviado', 'entrar.html?estado=enviado', ALL],
  ['entrar-erro', 'entrar.html?estado=erro', ALL],
  ['entrar-validacao', 'entrar.html?estado=validacao', ALL],
  ['entrar-sem-rede', 'entrar.html?estado=rede', ALL],
  ['entrar-sessao-terminada', 'entrar.html?estado=sessao', ALL],
  ['entrar-offline', 'entrar.html?estado=offline', ALL],
  ['recuperar-palavra-passe', 'recuperar.html', ALL],
  ['definir-palavra-passe', 'criar-palavra-passe.html?modo=definir', ALL],
  ['criar-palavra-passe', 'criar-palavra-passe.html', ALL],
  ['criar-palavra-passe-cumprida', 'criar-palavra-passe.html?estado=todas', ALL],
  ['criar-palavra-passe-fraca', 'criar-palavra-passe.html?estado=fraca', ALL],
  ['criar-palavra-passe-erro', 'criar-palavra-passe.html?estado=erro', ALL],
  ['criar-palavra-passe-offline', 'criar-palavra-passe.html?estado=offline', ALL],
  ['alterar-palavra-passe', 'criar-palavra-passe.html?modo=alterar&estado=todas', ALL],
  ['link-expirado', 'link-expirado.html', ALL],
  ['link-expirado-enviado', 'link-expirado.html?estado=enviado', ALL],
  // Consentimento
  ['consentimento', 'consentimento.html', ALL],
  ['consentimento-completo', 'consentimento.html', ['telemovel'], true],
  ['consentimento-a-carregar', 'consentimento.html?estado=a-carregar', ALL],
  ['consentimento-erro', 'consentimento.html?estado=erro', ALL],
  ['consentimento-offline', 'consentimento.html?estado=offline', ALL],
  ['consentimento-aceite', 'consentimento.html?estado=aceite', ALL],
  ['consentimento-recusado', 'consentimento.html?estado=recusado', ALL],
  // Com quem partilho
  ['com-quem-partilho', 'com-quem-partilho.html', ALL],
  ['com-quem-partilho-completo', 'com-quem-partilho.html', ['telemovel'], true],
  ['com-quem-partilho-a-carregar', 'com-quem-partilho.html?estado=a-carregar', ALL],
  ['com-quem-partilho-vazio', 'com-quem-partilho.html?estado=vazio', ALL],
  ['com-quem-partilho-erro', 'com-quem-partilho.html?estado=erro', ALL],
  ['com-quem-partilho-offline', 'com-quem-partilho.html?estado=offline', ALL],
  ['conta-cliente', 'com-quem-partilho.html#conta', ALL],
  ['palavra-passe-criada', 'com-quem-partilho.html?estado=criada', ALL],
  ['retirar-acesso', 'com-quem-partilho.html?folha=retirar', ALL],
  ['retirar-acesso-erro', 'com-quem-partilho.html?folha=retirar&estado=retirar-erro', ALL],
  ['acesso-retirado', 'com-quem-partilho.html?estado=retirado', ALL],
  // Clientes (mediador)
  ['clientes', 'clientes.html', ALL],
  ['clientes-completo', 'clientes.html', ['telemovel'], true],
  ['clientes-vazio', 'clientes.html?estado=vazio', ALL],
  ['clientes-a-carregar', 'clientes.html?estado=a-carregar', ALL],
  ['clientes-erro', 'clientes.html?estado=erro', ALL],
  ['clientes-offline', 'clientes.html?estado=offline', ALL],
  ['criar-cliente', 'clientes.html?folha=criar', ALL],
  ['criar-cliente-validacao', 'clientes.html?folha=criar&estado=validacao', ALL],
  ['cliente-criado', 'clientes.html?estado=criado', ALL],
  ['pedido-reenviado', 'clientes.html?estado=reenviado', ALL],
  // Admin (desktop e pequeno)
  ['admin', 'admin.html', ADMIN],
  ['admin-completo', 'admin.html', ['telemovel'], true],
  ['admin-a-carregar', 'admin.html?estado=a-carregar', ADMIN],
  ['admin-vazio', 'admin.html?estado=vazio', ADMIN],
  ['admin-erro', 'admin.html?estado=erro', ADMIN],
  ['admin-offline', 'admin.html?estado=offline', ADMIN],
  ['criar-escritorio', 'admin.html?folha=escritorio', ADMIN],
  ['convidar-mediador', 'admin.html?folha=convidar', ADMIN],
  ['escritorio-criado', 'admin.html?estado=criado', ADMIN],
  // Storyboards (página inteira, 1600 de largura)
  ['fluxo-1-convite', 'fluxos.html?fluxo=1', ['fluxo'], true],
  ['fluxo-2-entrar', 'fluxos.html?fluxo=2', ['fluxo'], true],
  ['fluxo-3-link-expirado', 'fluxos.html?fluxo=3', ['fluxo'], true],
  ['fluxo-4-criar-cliente', 'fluxos.html?fluxo=4', ['fluxo'], true],
  ['fluxo-5-retirar-acesso', 'fluxos.html?fluxo=5', ['fluxo'], true],
  ['fluxo-6-admin', 'fluxos.html?fluxo=6', ['fluxo'], true],
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
    if (filter && !filter.split(',').some((f) => name === f || (f.endsWith('*') && name.startsWith(f.slice(0, -1))))) continue;
    for (const size of sizes) {
      const ctx = await browser.newContext({ viewport: SIZES[size], deviceScaleFactor: 2 });
      const tab = await ctx.newPage();
      await tab.goto(`http://127.0.0.1:${port}${BASE}${page}`);
      await tab.evaluate(() => document.fonts.ready);
      await tab.waitForLoadState('networkidle');
      const fonts = await tab.evaluate(() => [...document.fonts].filter((f) => f.status === 'error').map((f) => f.family));
      // Âncora no endereço: mostra essa secção no topo da janela.
      await tab.evaluate(() => { if (location.hash) document.querySelector(location.hash).scrollIntoView(); });
      if (fonts.length) console.warn(`  fontes com erro em ${name}: ${fonts.join(', ')}`);
      // Página inteira: a barra fixa aparece no fim, onde fica ao acabar o scroll.
      if (full) await tab.addStyleTag({ content: '.barra-fixa { position: static; }' });
      const file = path.join(OUT, size === 'fluxo' ? `${name}.png` : `${name}-${size}.png`);
      await tab.screenshot({ path: file, fullPage: !!full });
      console.log(path.relative(ROOT, file));
      await ctx.close();
    }
  }
  await browser.close();
  server.close();
})();
