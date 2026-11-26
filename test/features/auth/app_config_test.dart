import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/config_error_app.dart';
import 'package:promediacao/core/config/app_config.dart';

void main() {
  test('configuração em falta é inválida e diz o que falta', () {
    const c = AppConfig(supabaseUrl: '', supabaseAnonKey: '');
    expect(c.isValid, isFalse);
    expect(c.problems, ['SUPABASE_URL', 'SUPABASE_ANON_KEY']);
  });

  test('URL sem esquema é inválida', () {
    const c = AppConfig(supabaseUrl: 'abc', supabaseAnonKey: 'k');
    expect(c.problems, ['SUPABASE_URL']);
  });

  test('configuração completa é válida', () {
    const c = AppConfig(
      supabaseUrl: 'https://x.supabase.co',
      supabaseAnonKey: 'k',
    );
    expect(c.isValid, isTrue);
  });

  testWidgets('ecrã de erro de configuração é claro e sem termos técnicos', (
    tester,
  ) async {
    await tester.pumpWidget(const ConfigErrorApp(missing: ['SUPABASE_URL']));
    expect(find.text('Não foi possível abrir a aplicação'), findsOneWidget);
    expect(find.textContaining('Contacte a administração'), findsOneWidget);
    expect(find.byType(Text), findsWidgets);
  });
}
