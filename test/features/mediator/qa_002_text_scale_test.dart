// QA 002 (tarefa 6): ecrãs do mediador da 002 com texto ampliado a 1.3 no
// telemóvel e no tablet (os testes da tarefa 4 cobrem os três tamanhos a 1.0;
// a 1.3 só a lista de Clientes estava coberta). Inclui o caso pesado: 2 tipos
// escolhidos, condições particulares e mensagem de 500 caracteres.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/features/mediator/presentation/client_file_page.dart';
import 'package:promediacao/features/mediator/presentation/mediator_request_page.dart';
import 'package:promediacao/features/mediator/presentation/new_request_page.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../requests/fake_requests_repository.dart';
import 'request_test_helpers.dart';

const _sizes = <String, Size>{
  'telemóvel': Size(390, 844),
  'tablet': Size(768, 1024),
};

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Bug 2 do 05-qa.md da 002: em compacto o `PageFrame` reserva 2 x 48 para
/// "Sair" sem contar com a escala do texto; a 1.3 "Sair" transborda 16 px.
/// Tirar o `skip` quando `lib/core/widgets/page_frame.dart` for corrigido.
String? _skip(String size) => size == 'telemóvel'
    ? 'Bug 2 do 05-qa.md da 002: "Sair" transborda 16 px a 1.3 em compacto'
    : null;

void main() {
  for (final e in _sizes.entries) {
    testWidgets('Novo pedido a 1.3, ${e.key}: 2 tipos, condições e mensagem '
        'de 500 sem overflow', (tester) async {
      await pumpPage(
        tester,
        const NewRequestPage(clientId: 'c-maria', fromClientFile: true),
        size: e.value,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await _tap(tester, find.byKey(const ValueKey('tipo-automovel')));
      await _tap(tester, find.byKey(const ValueKey('tipo-vida')));
      await _tap(tester, find.text('Permitir condições particulares'));
      final field = find.byType(EditableText);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Bom dia. ${'x' * 491}');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('500 / 500'), findsOneWidget);
      expect(find.text('Criar 2 pedidos'), findsOneWidget);
    }, skip: _skip(e.key) != null);

    testWidgets('ficha do cliente a 1.3, ${e.key}', (tester) async {
      final repo = FakeRequestsRepository();
      repo.officeRequests['c-maria'] = [
        OfficeRequest(
          id: 'r-at',
          typeCode: 'acidentes_trabalho_variavel',
          typeName: 'Acidentes de Trabalho (prémio variável)',
          stage: RequestStage.created,
          origin: RequestOrigin.mediador,
          allowPolicyConditions: true,
          createdAt: DateTime(2026, 11, 27, 10, 14),
          documentCount: 2,
          dataCount: 3,
          authorName: 'Ana Martins',
        ),
      ];
      await pumpPage(
        tester,
        const ClientFilePage(clientId: 'c-maria'),
        repo: repo,
        size: e.value,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('Acidentes de Trabalho (prémio variável)'),
        findsOneWidget,
      );
    }, skip: _skip(e.key) != null);

    testWidgets('pedido aberto do mediador a 1.3, ${e.key}', (tester) async {
      final repo = FakeRequestsRepository();
      repo.details['r1'] = sampleDetail();
      await pumpPage(
        tester,
        const MediatorRequestPage(clientId: 'c-maria', requestId: 'r1'),
        repo: repo,
        size: e.value,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Etapa 1 de 4: Pedido criado'), findsOneWidget);
    }, skip: _skip(e.key) != null);
  }
}
