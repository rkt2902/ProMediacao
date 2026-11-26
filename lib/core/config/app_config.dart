/// Configuração de arranque, vinda de `--dart-define` (sem segredos no
/// repositório):
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://<projeto>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<chave anon> \
///   --dart-define=AUTH_REDIRECT_URL=<opcional>
/// ```
///
/// A chave anon é pública por desenho (a segurança está na RLS), mas fica
/// fora do código para poder mudar por ambiente.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.authRedirectUrl = '',
  });

  /// Valores injetados na compilação.
  static const AppConfig environment = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    authRedirectUrl: String.fromEnvironment('AUTH_REDIRECT_URL'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Opcional: para onde o link de recuperação de palavra-passe leva.
  /// Tem de estar na lista de Redirect URLs do Supabase.
  final String authRedirectUrl;

  /// Nomes dos `--dart-define` em falta ou inválidos (para o ecrã de erro em
  /// modo de desenvolvimento).
  List<String> get problems {
    final out = <String>[];
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (supabaseUrl.trim().isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      out.add('SUPABASE_URL');
    }
    if (supabaseAnonKey.trim().isEmpty) out.add('SUPABASE_ANON_KEY');
    return out;
  }

  bool get isValid => problems.isEmpty;
}
