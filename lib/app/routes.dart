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

  /// Pedido de consentimento (tarefa 5).
  static const consentPattern = '/cliente/pedido/:grantId';
}
