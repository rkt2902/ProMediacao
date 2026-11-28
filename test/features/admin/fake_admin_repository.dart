import 'dart:async';

import 'package:promediacao/features/admin/domain/admin_models.dart';
import 'package:promediacao/features/admin/domain/admin_repository.dart';

/// Repositório de teste: sem rede, tudo controlável.
class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({List<OfficeSummary>? offices, this.counts})
    : offices = List.of(offices ?? sampleOffices);

  static const sampleOffices = [
    OfficeSummary(id: 'o1', name: 'Ribeira Seguros', mediatorCount: 3),
    OfficeSummary(
      id: 'o2',
      name: 'Gabinete de Mediação de Seguros Vale do Sousa & Filhos, Lda.',
      mediatorCount: 1,
    ),
    OfficeSummary(id: 'o3', name: 'Mediação Norte Exemplo'),
  ];

  List<OfficeSummary> offices;
  AdminCounts? counts;

  /// Se definido, `loadCounts` espera por ele.
  Completer<void>? gate;
  AdminFailure? loadFailure;
  AdminFailure? createFailure;
  AdminFailure? inviteFailure;

  final List<String> created = [];
  final List<({String officeId, String email, String fullName})> invites = [];
  int loads = 0;

  @override
  Future<AdminCounts> loadCounts() async {
    loads++;
    if (gate != null) await gate!.future;
    if (loadFailure != null) throw loadFailure!;
    return counts ??
        AdminCounts(
          offices: offices.length,
          mediators: offices.fold(0, (a, o) => a + o.mediatorCount),
          clients: 12,
          requests: 6,
        );
  }

  @override
  Future<List<OfficeSummary>> loadOffices() async {
    if (gate != null) await gate!.future;
    if (loadFailure != null) throw loadFailure!;
    return List.of(offices);
  }

  @override
  Future<OfficeSummary> createOffice(String name) async {
    if (createFailure != null) throw createFailure!;
    created.add(name);
    final o = OfficeSummary(id: 'new-${created.length}', name: name);
    offices = [o, ...offices];
    return o;
  }

  @override
  Future<void> inviteMediator({
    required String officeId,
    required String email,
    required String fullName,
  }) async {
    if (inviteFailure != null) throw inviteFailure!;
    invites.add((officeId: officeId, email: email, fullName: fullName));
  }
}
