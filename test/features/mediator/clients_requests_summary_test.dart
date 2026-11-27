// Bug 5 do 05-qa.md da 002: com mais de 200 clientes carregados, o resumo de
// pedidos é pedido em blocos de 200 e junta-se, para nenhum cliente ativo
// mostrar "Sem pedidos" por engano.
import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/features/mediator/application/clients_controller.dart';
import 'package:promediacao/features/mediator/domain/mediator_models.dart';
import 'package:promediacao/features/mediator/domain/mediator_repository.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../requests/fake_requests_repository.dart';

class _Clients implements MediatorRepository {
  _Clients(this.items);

  final List<OfficeClient> items;

  @override
  Future<int?> countClients() async => items.length;

  @override
  Future<List<OfficeClient>> listClients({
    required int limit,
    required int offset,
  }) async => items.skip(offset).take(limit).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Como o servidor: recusa-se a devolver mais de 200 linhas por pedido.
class _Requests extends FakeRequestsRepository {
  final List<int> sizes = [];

  @override
  Future<Map<String, ClientRequestsSummary>> officeRequestsSummary([
    List<String>? clientIds,
  ]) async {
    sizes.add(clientIds?.length ?? 0);
    final all = await super.officeRequestsSummary(clientIds);
    return {for (final e in all.entries.take(200)) e.key: e.value};
  }
}

void main() {
  test('mais de 200 clientes ativos: resumo em blocos de 200, todos '
      'preenchidos', () async {
    final at = DateTime(2026, 11, 27);
    final items = [
      for (var i = 0; i < 230; i++)
        OfficeClient(
          grantId: 'g$i',
          clientId: 'c$i',
          fullName: 'Cliente $i',
          email: 'c$i@exemplo.pt',
          status: ClientStatus.ativo,
          updatedAt: at,
        ),
    ];
    final requests = _Requests()
      ..summary = {
        for (final i in [0, 199, 200, 229])
          'c$i': ClientRequestsSummary(
            clientId: 'c$i',
            openCount: 1,
            totalCount: 1,
            maxOpenStage: RequestStage.created,
          ),
      };
    final connectivity = AppConnectivity();
    addTearDown(connectivity.dispose);
    final c = ClientsController(
      _Clients(items),
      connectivity,
      requests: requests,
      pageSize: 250,
    );
    addTearDown(c.dispose);

    await c.start();

    expect(c.items, hasLength(230));
    expect(requests.sizes, [200, 30]);
    expect(c.requestsKnown, isTrue);
    for (final i in [0, 199, 200, 229]) {
      expect(c.summaryFor(items[i]), isNotNull, reason: 'c$i');
    }
    expect(c.summaryFor(items[100]), isNull);
  });
}
