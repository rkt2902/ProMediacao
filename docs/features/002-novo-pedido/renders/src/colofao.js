// Colofão de referência: acrescenta o rodapé da marca a seguir ao <main> da página (antes da barra fixa, se houver).
// Perfil em <body data-colofao="sem-sessao|cliente|mediador|admin">; ?modo=definir é sempre sem sessão.
// A carregar: só o wordmark (a linha de identidade aparece quando os dados chegam; nunca skeleton no colofão).
(function () {
  const q = new URLSearchParams(location.search);
  const estado = q.get('estado') || 'normal';
  const folha = q.get('folha') || 'nenhuma';
  const perfil = q.get('modo') === 'definir' ? 'sem-sessao' : (document.body.dataset.colofao || 'sem-sessao');
  const LINHAS = {
    'sem-sessao': ['O dossiê dos seus seguros, partilhado só com quem autorizar.', ''],
    cliente: ['Dossiê de Maria do Carmo Figueiredo', 'Aberto a 12 nov 2026'],
    mediador: ['Ana Martins, Ribeira Seguros', 'Na equipa desde 3 nov 2026'],
    admin: ['Administração da plataforma', ''],
  };
  const [linha, registo] = LINHAS[perfil];
  const carregar = estado === 'a-carregar' && (perfil === 'cliente' || perfil === 'mediador');
  const f = document.createElement('footer');
  f.className = 'colofao frame';
  // Formulário de ecrã inteiro em compacto (criar cliente, criar escritório, convidar): sem colofão.
  if (folha !== 'nenhuma' && document.querySelector('.form-pagina')) f.classList.add('nao-compacto');
  f.innerHTML = `<div class="in"><div class="corpo-colofao">
    <span class="wordmark" aria-label="ProDossier"><span class="pro">Pro</span><span class="dossier">Dossier</span></span>
    ${carregar ? '' : `<span class="corpoPequeno linha-colofao">${linha}</span>`}
    ${carregar || !registo ? '' : `<span class="registo">${registo}</span>`}
  </div></div>`;
  const main = document.querySelector('main.frame:not(.form-pagina)') || document.querySelector('main.frame');
  main.after(f);
})();
