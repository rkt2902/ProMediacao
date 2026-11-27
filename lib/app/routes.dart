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
}
