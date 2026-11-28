/// Caminhos da app. Em web são URLs limpos (sem `#`): os links mágicos e de
/// recuperação abrem no navegador.
abstract final class AppRoutes {
  static const gate = '/a-validar';
  static const entry = '/entrar';
  static const recover = '/recuperar';
  static const setPassword = '/definir-palavra-passe';
  static const expiredLink = '/link-invalido';

  static const admin = '/admin';
  static const mediator = '/mediador';
  static const client = '/cliente';

  /// Convite "Criar palavra-passe" depois de entrar por link (cliente).
  static const clientCreatePassword = '/cliente/criar-palavra-passe';

  /// Criar ou alterar a palavra-passe a partir de "A sua conta" (cliente).
  static const clientPassword = '/cliente/palavra-passe';

  /// Pedido de consentimento (tarefa 5).
  static const consentPattern = '/cliente/pedido/:grantId';

  static String consentFor(String grantId) =>
      '$client/pedido/${Uri.encodeComponent(grantId)}';

  /// "Criar cliente" em ecrã inteiro (mediador, telemóvel): rota própria para
  /// o "voltar" do navegador o fechar.
  static const mediatorNewClient = '/mediador/novo-cliente';

  // ---- 002 Novo pedido ------------------------------------------------------

  /// Link do email do pedido (`{APP_URL}/pedidos`). Sem sessão passa por
  /// Entrar e volta aqui; com sessão leva ao ecrã inicial do papel (o do
  /// cliente é "Os meus pedidos").
  static const emailRequests = '/pedidos';

  /// "Com quem partilho" (deixa de ser o ecrã inicial do cliente na 002; o
  /// inicial, [client], passa a ser "Os meus pedidos").
  static const clientSharing = '/cliente/partilhas';

  /// Pedido do cliente, só leitura (ecrã 5). Não confundir com
  /// [consentPattern] (`/cliente/pedido/...`, pedido de acesso).
  static const clientRequestPattern = '/cliente/pedidos/:requestId';

  static String clientRequest(String requestId) =>
      '$client/pedidos/${Uri.encodeComponent(requestId)}';

  /// Notificações em ecrã inteiro (compacto; em médio/largo abre a folha
  /// lateral sobre o ecrã atual).
  static const clientNotifications = '/cliente/notificacoes';

  /// Novo pedido a partir de Clientes. Com `?cliente={id}` (linha de um
  /// cliente) o cliente já vem escolhido e o regresso é "Clientes".
  static const mediatorNewRequest = '/mediador/novo-pedido';

  static String mediatorNewRequestFor(String? clientId) => clientId == null
      ? mediatorNewRequest
      : '$mediatorNewRequest?cliente=${Uri.encodeQueryComponent(clientId)}';

  /// Ficha do cliente (mediador).
  static const mediatorClientPattern = '/mediador/clientes/:clientId';

  static String mediatorClient(String clientId) =>
      '$mediator/clientes/${Uri.encodeComponent(clientId)}';

  /// Novo pedido a partir da ficha: cliente escolhido e regresso à ficha.
  static const mediatorClientNewRequestPattern =
      '/mediador/clientes/:clientId/novo-pedido';

  static String mediatorClientNewRequest(String clientId) =>
      '${mediatorClient(clientId)}/novo-pedido';

  /// Pedido aberto do mediador, só leitura (ecrã 3b); regresso à ficha.
  static const mediatorRequestPattern =
      '/mediador/clientes/:clientId/pedidos/:requestId';

  static String mediatorRequest(String clientId, String requestId) =>
      '${mediatorClient(clientId)}/pedidos/${Uri.encodeComponent(requestId)}';
}
