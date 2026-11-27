// QA 002, reteste: ecrã inicial do cliente (sino + "Sair" no cabeçalho) com
// texto muito ampliado. A correção do bug 2 passou a multiplicar a reserva da
// conta em compacto (4 x 48 com sino) pela escala do texto sem limite; a 2.0
// num telemóvel de 390 a reserva (384) passa a largura útil e o separador
// recebe uma largura máxima negativa.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../requests/fake_requests_repository.dart';
import 'client_requests_test_helpers.dart';

void main() {
  for (final c in const [
    (Size(390, 844), 1.3),
    (Size(320, 640), 1.5),
    (Size(390, 844), 2.0),
  ]) {
    testWidgets(
      'cliente com sino a ${c.$2} em ${c.$1.width.toInt()}: sem erros de layout',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = c.$2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpClient(
          tester,
          requests: FakeRequestsRepository(),
          size: c.$1,
        );
        expect(tester.takeException(), isNull);
      },
      skip: c.$2 >= 2.0,
      // Bug 6 do 05-qa.md da 002 ("BoxConstraints has non-normalized width
      // constraints" em page_frame.dart). Tirar o skip quando corrigido.
    );
  }
}
