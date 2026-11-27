// Catálogo de referência (docs/reference/tipos-de-seguro.md). D = Documento, I = Dado.
// As notas 8, 9 e 10 estão reescritas na voz do cliente (o catálogo original fala para o mediador: "pedir também…");
// ver 03-design.md, "Decisões em aberto".
const CC = ['D', 'Cartão de Cidadão (NIF, nome completo, data de nascimento)'];
const CCT = ['D', 'Dados do tomador (Cartão de Cidadão)'];
const MORADA = ['I', 'Morada'];
const IMOVEL = [
  ['I', 'Morada do risco, se diferente da do tomador'],
  ['I', 'Área em m², n.º de WC e assoalhadas'],
  ['I', 'Capital do edifício'],
  ['I', 'Capital do recheio'],
  ['D', 'Caderneta predial do imóvel'],
  ['I', 'Ano de construção'],
  ['I', 'Ano das obras (canalização, eletricidade, etc.)'],
];
const SAUDE = 'Se tiver problemas de saúde: todos os exames e relatórios recentes da patologia.';
window.CATALOGO = [
  { id: 1, nome: 'Vida', itens: [CC, MORADA, ['I', 'Capital seguro ou em dívida'], ['I', 'Profissão'], ['I', 'Prazo']], nota: SAUDE },
  { id: 2, nome: 'Vida Habitação', itens: [CC, MORADA, ['I', 'Capital seguro ou em dívida'], ['I', 'Taxas do empréstimo'], ['I', 'Prazo'], ['I', 'Profissão'], ['D', 'Exames e relatórios médicos (se aplicável)']], nota: SAUDE },
  { id: 3, nome: 'Doenças Graves', itens: [CC, MORADA, ['I', 'Capital seguro'], ['I', 'Profissão'], ['I', 'Prazo']], nota: 'Pode ser incluído no Seguro de Vida ou contratado em separado.' },
  { id: 4, nome: 'Multirriscos Habitação', itens: [CC, ...IMOVEL], nota: '' },
  { id: 5, nome: 'Multirriscos Negócio', itens: [CCT, ['I', 'CAE'], ...IMOVEL], nota: 'Capital do recheio enquadrado na atividade exercida no espaço e no seu conteúdo.' },
  { id: 6, nome: 'Saúde', itens: [CCT, MORADA, ['I', 'Data de nascimento de todas as pessoas a incluir'], ['I', 'Coberturas e capitais pretendidos']], nota: 'Para menores, o tomador é a mãe ou o pai. Com seguro de saúde há mais de 2 anos é possível transferir os períodos de carência.' },
  { id: 7, nome: 'Acidentes Pessoais', itens: [CCT, MORADA, ['I', 'Coberturas pretendidas'], ['I', 'Profissão']], nota: 'Individual ou de grupo.' },
  { id: 8, nome: 'Automóvel', itens: [CCT, MORADA, ['D', 'Carta de condução'], ['D', 'Documento Único Automóvel (DUA / livrete)'], ['I', 'Coberturas pretendidas'], ['I', 'Franquias (danos próprios)']], nota: 'Se o condutor habitual não for o tomador, envie também o Cartão de Cidadão, a carta de condução e a morada do condutor.' },
  { id: 9, nome: 'Acidentes de Trabalho (prémio fixo)', itens: [['D', 'Dados do tomador (empresa)'], MORADA, ['I', 'CAE'], ['I', 'Nome e data de nascimento dos trabalhadores'], ['D', 'Recibos de vencimento (horas, salário base, subsídios)'], ['D', 'Apólice em vigor']], nota: 'Se já tem seguro, a apólice em vigor é essencial.' },
  { id: 10, nome: 'Acidentes de Trabalho (prémio variável)', itens: [['D', 'Dados do tomador (empresa)'], MORADA, ['I', 'CAE'], ['I', 'Massa salarial'], ['D', 'Apólice em vigor']], nota: 'Se já tem seguro, a apólice em vigor é essencial.' },
  { id: 11, nome: 'Pets', itens: [CCT, ['D', 'Livro do animal e micro-chip'], ['I', 'Tipo de atividade do animal (companhia, provas desportivas, etc.)']], nota: '' },
  { id: 12, nome: 'Responsabilidade Civil', itens: [['D', 'Dados do tomador (CC para trabalhadores independentes)'], MORADA, ['I', 'CAE']], nota: '' },
  { id: 13, nome: 'Obras', itens: [['D', 'Dados do tomador (CC para particulares)'], ['I', 'Morada da obra'], ['D', 'Plantas'], ['D', 'Orçamentos'], ['D', 'Caderno de encargos'], ['D', 'Memória descritiva da obra'], ['I', 'Percentagem de obra realizada']], nota: 'Os documentos pedidos variam de seguradora para seguradora.' },
];
window.tipo = (nome) => window.CATALOGO.find((t) => t.nome === nome);

// Ícones (codepoints de Icons.* do Flutter; subconjunto em fonts/)
window.IC = {
  documento: '&#xefae;', // description_outlined
  dado: '&#xf04f6;', // edit_note
  tirar: '&#xe16a;', // close
  acrescentar: '&#xe047;', // add
  voltar: '&#xe092;', // arrow_back
  sair: '&#xe3b3;', // logout
  sino: '&#xe451;', // notifications_none
  seguir: '&#xe15f;', // chevron_right
  check: '&#xe156;', // check
  feito: '&#xe159;', // check_circle
  porFazer: '&#xef53;', // circle_outlined
  info: '&#xe33d;', // info_outline
  aviso: '&#xe6cc;', // warning_amber
  erro: '&#xe238;', // error_outline
  ok: '&#xe15a;', // check_circle_outline
  pendente: '&#xe556;', // schedule
  recusado: '&#xe0e1;', // block
  retirado: '&#xe68c;', // undo
  offline: '&#xe173;', // cloud_off
  email: '&#xe3c4;', // mail_outline
  procurar: '&#xe567;', // search
  radioOn: '&#xe503;', // radio_button_checked
  radioOff: '&#xe504;', // radio_button_unchecked
};

// Fragmentos partilhados entre páginas
window.F = {
  offline: (txt) => `<div class="offline"><div class="frame"><div class="in"><span class="ic">${IC.offline}</span><p class="corpoPequeno">${txt || 'Sem ligação à internet. Pode ver o que está no ecrã; as alterações ficam bloqueadas até a ligação voltar.'}</p></div></div></div>`,
  natureza: (k) => k === 'D' ? `<span class="natureza"><span class="ic">${IC.documento}</span>Documento</span>` : `<span class="natureza"><span class="ic">${IC.dado}</span>Dado</span>`,
  trilho: (n, palavra) => `<span class="trilho"><span class="seg" aria-hidden="true">${[1, 2, 3, 4].map((i) => `<i class="${i <= n ? 'f' : ''}"></i>`).join('')}</span><span class="corpoPequeno">${palavra}</span></span>`,
  carimbo: (tipo, txt, ic) => `<span class="carimbo ${tipo}"><span class="ic">${ic}</span>${txt}</span>`,
  sino: (n) => `<span class="sino" aria-label="Notificações${n ? `, ${n} por ler` : ''}"><span class="ic g">${IC.sino}</span><span class="palavra">Notificações</span>${n ? `<span class="contador">${n}</span>` : ''}</span>`,
  sair: () => `<span class="acao"><span class="ic">${IC.sair}</span><span class="t">Sair</span></span>`,
  etapas: (dataCriado) => `<div class="etapas" role="list" aria-label="Etapas do pedido">
    <div class="et feita" role="listitem"><span class="n">1</span><div><p class="nome">Pedido criado</p><p class="quando"><span class="ic">${IC.feito}</span><span class="registo tenue">${dataCriado}</span></p></div></div>
    <div class="et" role="listitem"><span class="n">2</span><div><p class="nome">Documentos enviados</p><p class="quando registo tenue">Por fazer</p></div></div>
    <div class="et" role="listitem"><span class="n">3</span><div><p class="nome">Em análise pelo mediador</p><p class="quando registo tenue">Por fazer</p></div></div>
    <div class="et" role="listitem"><span class="n">4</span><div><p class="nome">Enviado às seguradoras</p><p class="quando registo tenue">Por fazer</p></div></div>
  </div>`,
};
