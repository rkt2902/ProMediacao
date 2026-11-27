// Lista dos PNG da 002: [nome do ficheiro, página, tamanhos, página inteira?]
const ALL = ['telemovel', 'tablet', 'desktop'];
const TEL = ['telemovel'];
const EMAIL = ['telemovel', 'desktop'];

module.exports = [
  // 1. Novo pedido (mediador)
  ['novo-pedido', 'novo-pedido.html', ALL],
  ['novo-pedido-completo', 'novo-pedido.html', ALL, true],
  ['novo-pedido-escolher-cliente', 'novo-pedido.html?estado=escolher', ALL],
  ['novo-pedido-sem-tipos', 'novo-pedido.html?estado=inicio', ALL],
  ['novo-pedido-repetido', 'novo-pedido.html?estado=repetido', ALL, true],
  ['novo-pedido-acrescentar-item', 'novo-pedido.html?estado=acrescentar', ALL, true],
  ['novo-pedido-lista-vazia', 'novo-pedido.html?estado=lista-vazia', ALL, true],
  ['novo-pedido-a-carregar', 'novo-pedido.html?estado=a-carregar', ALL],
  ['novo-pedido-a-criar', 'novo-pedido.html?estado=a-criar', ALL],
  ['novo-pedido-erro', 'novo-pedido.html?estado=erro', ALL],
  ['novo-pedido-sem-concessao', 'novo-pedido.html?estado=sem-concessao', ALL],
  ['novo-pedido-erro-catalogo', 'novo-pedido.html?estado=erro-catalogo', ALL],
  ['novo-pedido-offline', 'novo-pedido.html?estado=offline', ALL],
  ['novo-pedido-sem-clientes', 'novo-pedido.html?estado=sem-clientes', ALL],
  ['novo-pedido-sem-acesso-pendente', 'novo-pedido.html?estado=sem-acesso&motivo=pendente', ALL],
  ['novo-pedido-sem-acesso-recusada', 'novo-pedido.html?estado=sem-acesso&motivo=recusada', ALL],
  ['novo-pedido-sem-acesso-retirada', 'novo-pedido.html?estado=sem-acesso&motivo=retirada', ALL],
  // 2. Clientes (mediador), evolução da 001
  ['clientes', 'clientes.html', ALL],
  ['clientes-completo', 'clientes.html', TEL, true],
  ['clientes-a-carregar', 'clientes.html?estado=a-carregar', ALL],
  ['clientes-erro', 'clientes.html?estado=erro', ALL],
  ['clientes-offline', 'clientes.html?estado=offline', ALL],
  // 3. Ficha do cliente (mediador)
  ['ficha', 'ficha.html', ALL],
  ['ficha-completo', 'ficha.html', TEL, true],
  ['ficha-pedidos-criados', 'ficha.html?estado=criado', ALL],
  ['ficha-email-falhou', 'ficha.html?estado=email-falhou', ALL],
  ['ficha-email-reenviado', 'ficha.html?estado=email-reenviado', ALL],
  ['ficha-sem-pedidos', 'ficha.html?estado=vazio', ALL],
  ['ficha-a-carregar', 'ficha.html?estado=a-carregar', ALL],
  ['ficha-erro', 'ficha.html?estado=erro', ALL],
  ['ficha-offline', 'ficha.html?estado=offline', ALL],
  ['ficha-sem-acesso', 'ficha.html?estado=sem-acesso', ALL],
  // 3b. Pedido aberto (mediador, só leitura)
  ['pedido-mediador', 'pedido.html?perfil=mediador', ALL],
  ['pedido-mediador-completo', 'pedido.html?perfil=mediador', TEL, true],
  ['pedido-mediador-a-carregar', 'pedido.html?perfil=mediador&estado=a-carregar', ALL],
  ['pedido-mediador-erro', 'pedido.html?perfil=mediador&estado=erro', ALL],
  // 4. Os meus pedidos (cliente)
  ['meus-pedidos', 'meus-pedidos.html', ALL],
  ['meus-pedidos-completo', 'meus-pedidos.html', TEL, true],
  ['meus-pedidos-vazio', 'meus-pedidos.html?estado=vazio', ALL],
  ['meus-pedidos-a-carregar', 'meus-pedidos.html?estado=a-carregar', ALL],
  ['meus-pedidos-erro', 'meus-pedidos.html?estado=erro', ALL],
  ['meus-pedidos-offline', 'meus-pedidos.html?estado=offline', ALL],
  // 5. Pedido (cliente, só leitura)
  ['pedido-cliente', 'pedido.html?perfil=cliente', ALL],
  ['pedido-cliente-completo', 'pedido.html?perfil=cliente', TEL, true],
  ['pedido-cliente-acesso-retirado', 'pedido.html?perfil=cliente&estado=retirado', ALL],
  ['pedido-cliente-a-carregar', 'pedido.html?perfil=cliente&estado=a-carregar', ALL],
  ['pedido-cliente-erro', 'pedido.html?perfil=cliente&estado=erro', ALL],
  ['pedido-cliente-offline', 'pedido.html?perfil=cliente&estado=offline', ALL],
  ['pedido-cliente-sem-acesso', 'pedido.html?perfil=cliente&estado=sem-acesso', ALL],
  // 6. Sino e notificações (cliente)
  ['notificacoes', 'meus-pedidos.html?folha=notificacoes', ALL],
  ['notificacoes-vazio', 'meus-pedidos.html?folha=notificacoes&lista=vazio', ALL],
  ['notificacoes-todas-lidas', 'meus-pedidos.html?folha=notificacoes&lista=lidas', ALL],
  ['notificacoes-a-carregar', 'meus-pedidos.html?folha=notificacoes&lista=a-carregar', ALL],
  ['notificacoes-erro', 'meus-pedidos.html?folha=notificacoes&lista=erro', ALL],
  ['notificacoes-offline', 'meus-pedidos.html?folha=notificacoes&estado=offline&lista=offline', ALL],
  ['sino-estados', 'sino.html', ['sino']],
  // 7. Email do pedido
  ['email-pedido', 'email-pedido.html', EMAIL, true],
  ['email-pedido-sem-mensagem', 'email-pedido.html?mensagem=nao', EMAIL, true],
  // Storyboards
  ['fluxo-1-novo-pedido', 'fluxos.html?fluxo=1', ['fluxo'], true],
  ['fluxo-2-cliente', 'fluxos.html?fluxo=2', ['fluxo'], true],
  ['fluxo-3-excecoes', 'fluxos.html?fluxo=3', ['fluxo'], true],
];
