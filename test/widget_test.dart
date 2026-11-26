import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/config_error_app.dart';

// O arranque real depende de Supabase; aqui verifica-se só o ecrã de erro de
// configuração. Os fluxos vivem em test/features/auth/.
void main() {
  testWidgets('arranque sem configuração mostra o ecrã de erro', (
    tester,
  ) async {
    await tester.pumpWidget(const ConfigErrorApp());
    expect(find.text('Não foi possível abrir a aplicação'), findsOneWidget);
  });
}
