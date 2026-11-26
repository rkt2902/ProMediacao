// Propostas de marca: ?ideia=lombada|selo|colofao. Um bloco com data-ideia="a b" só aparece nessas ideias.
(function () {
  const ideia = new URLSearchParams(location.search).get('ideia') || 'lombada';
  document.body.classList.add('ideia-' + ideia);
  document.querySelectorAll('[data-ideia]').forEach((el) => {
    if (el.dataset.ideia.split(' ').includes(ideia)) el.removeAttribute('data-ideia');
    else el.remove();
  });
})();
