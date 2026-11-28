// Mostra só os blocos do estado pedido (?estado=...&folha=...). Um bloco com data-em="a b" aparece nos estados a e b;
// data-fora="a" esconde-o nesses estados. Também marca o body para CSS (data-estado, data-folha).
(function () {
  const q = new URLSearchParams(location.search);
  const estado = q.get('estado') || 'normal';
  const folha = q.get('folha') || 'nenhuma';
  document.body.dataset.estado = estado;
  document.body.dataset.folha = folha;
  if (q.get('animar')) document.body.classList.add('animar');
  document.querySelectorAll('[data-em]').forEach((el) => {
    if (el.dataset.em.split(' ').includes(estado)) el.removeAttribute('data-em');
  });
  document.querySelectorAll('[data-fora]').forEach((el) => {
    if (el.dataset.fora.split(' ').includes(estado)) el.remove();
  });
  document.querySelectorAll('[data-folha-em]').forEach((el) => {
    if (!el.dataset.folhaEm.split(' ').includes(folha)) el.remove();
  });
})();
