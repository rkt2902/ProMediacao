// Goldens de revisão de design da 002 (tarefa 7). Não são regressão: os
// renders mudam entre Linux e Windows. Só correm com `--update-goldens`:
//   flutter test --update-goldens test/design_review/002_novo_pedido
//
// Os ajudantes de base (fontes reais, tamanhos, escala, `shoot`) são os da
// 001; aqui ficam as fixtures do `03-design.md` da 002 e a página inteira.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/features/requests/domain/request_models.dart';

import '../../features/requests/fake_requests_repository.dart';

export '../001_fundacao/review_helpers.dart';

/// Variantes dos ecrãs principais: os três tamanhos, 320 e escala 1.3.
const mainVariants = <String, (Size, double)>{
  'telemovel': (Size(390, 844), 1.0),
  'tablet': (Size(768, 1024), 1.0),
  'desktop': (Size(1280, 800), 1.0),
  '320': (Size(320, 700), 1.0),
  'telemovel-1.3': (Size(390, 844), 1.3),
  'desktop-1.3': (Size(1280, 800), 1.3),
};

/// Põe todos os scrolls verticais no topo (depois de `ensureVisible`).
Future<void> scrollToTop(WidgetTester tester) async {
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    if (s.position.axis == Axis.vertical && s.position.pixels != 0) {
      s.position.jumpTo(0);
    }
  }
  await tester.pumpAndSettle();
}

/// Aumenta a janela até caber a página inteira (o maior scroll vertical),
/// para ver o que fica abaixo da dobra. A barra fixa fica no fundo.
Future<void> growToFullPage(WidgetTester tester) async {
  await scrollToTop(tester);
  var extra = 0.0;
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    if (s.position.axis == Axis.vertical &&
        s.position.maxScrollExtent > extra) {
      extra = s.position.maxScrollExtent;
    }
  }
  if (extra == 0) return;
  final size = tester.view.physicalSize;
  tester.view.physicalSize = Size(size.width, size.height + extra);
  await tester.pumpAndSettle();
}

// --- Fixtures do 03-design.md -------------------------------------------

CatalogItem _d(String id, int p, String label) =>
    CatalogItem(id: id, position: p, kind: ItemKind.document, label: label);
CatalogItem _i(String id, int p, String label) =>
    CatalogItem(id: id, position: p, kind: ItemKind.data, label: label);

const _saude =
    'Se tiver problemas de saúde, envie todos os exames e relatórios '
    'recentes da patologia.';

/// Os 13 tipos do catálogo, pela ordem do Novo pedido.
List<InsuranceType> catalog13() => [
  InsuranceType(
    code: 'vida',
    name: 'Vida',
    sortOrder: 1,
    note: _saude,
    items: [
      _d('v1', 1, 'Cartão de Cidadão (NIF, nome completo, data de nascimento)'),
      _i('v2', 2, 'Morada'),
      _i('v3', 3, 'Capital seguro ou em dívida'),
      _i('v4', 4, 'Profissão'),
      _i('v5', 5, 'Prazo'),
    ],
  ),
  InsuranceType(
    code: 'vida_habitacao',
    name: 'Vida Habitação',
    sortOrder: 2,
    note: _saude,
    items: [_d('vh1', 1, 'Cartão de Cidadão'), _i('vh2', 2, 'Morada')],
  ),
  InsuranceType(
    code: 'doencas_graves',
    name: 'Doenças Graves',
    sortOrder: 3,
    items: [_d('dg1', 1, 'Cartão de Cidadão')],
  ),
  InsuranceType(
    code: 'multirriscos_habitacao',
    name: 'Multirriscos Habitação',
    sortOrder: 4,
    items: [_d('mh1', 1, 'Cartão de Cidadão'), _i('mh2', 2, 'Morada do risco')],
  ),
  InsuranceType(
    code: 'multirriscos_negocio',
    name: 'Multirriscos Negócio',
    sortOrder: 5,
    items: [_d('mn1', 1, 'Dados do tomador (Cartão de Cidadão)')],
  ),
  InsuranceType(
    code: 'saude',
    name: 'Saúde',
    sortOrder: 6,
    items: [_d('s1', 1, 'Dados do tomador (Cartão de Cidadão)')],
  ),
  InsuranceType(
    code: 'acidentes_pessoais',
    name: 'Acidentes Pessoais',
    sortOrder: 7,
    items: [_d('ap1', 1, 'Dados do tomador (Cartão de Cidadão)')],
  ),
  InsuranceType(
    code: 'automovel',
    name: 'Automóvel',
    sortOrder: 8,
    note:
        'Se o condutor habitual não for o tomador, envie também o Cartão de '
        'Cidadão, a carta de condução e a morada do condutor.',
    items: [
      _d('a1', 1, 'Dados do tomador (Cartão de Cidadão)'),
      _i('a2', 2, 'Morada'),
      _d('a3', 3, 'Carta de condução'),
      _d('a4', 4, 'Documento Único Automóvel (DUA / livrete)'),
      _i('a5', 5, 'Coberturas pretendidas'),
      _i('a6', 6, 'Franquias (danos próprios)'),
    ],
  ),
  InsuranceType(
    code: 'at_fixo',
    name: 'Acidentes de Trabalho (prémio fixo)',
    sortOrder: 9,
    note: 'Se a empresa já tem seguro, envie a apólice em vigor.',
    items: [_d('af1', 1, 'Dados do tomador (empresa)')],
  ),
  InsuranceType(
    code: 'at_variavel',
    name: 'Acidentes de Trabalho (prémio variável)',
    sortOrder: 10,
    note: 'Se a empresa já tem seguro, envie a apólice em vigor.',
    items: [_d('av1', 1, 'Dados do tomador (empresa)')],
  ),
  InsuranceType(
    code: 'pets',
    name: 'Pets',
    sortOrder: 11,
    items: [_d('p1', 1, 'Livro do animal e micro-chip')],
  ),
  InsuranceType(
    code: 'rc',
    name: 'Responsabilidade Civil',
    sortOrder: 12,
    items: [_i('rc1', 1, 'CAE')],
  ),
  InsuranceType(
    code: 'obras',
    name: 'Obras',
    sortOrder: 13,
    note: 'Os documentos pedidos variam de seguradora para seguradora.',
    items: [_d('o1', 1, 'Plantas')],
  ),
];

/// Multirriscos Habitação em curso desde 20 nov 2026 (dispara o repetido).
OpenType openMultirriscos() => OpenType(
  typeCode: 'multirriscos_habitacao',
  typeName: 'Multirriscos Habitação',
  openCount: 1,
  firstCreatedAt: DateTime(2026, 11, 20, 16, 40),
  lastCreatedAt: DateTime(2026, 11, 20, 16, 40),
  maxStage: RequestStage.created,
);

/// Repositório com o catálogo completo e Maria com Multirriscos em curso.
FakeRequestsRepository newRequestRepo() {
  final repo = FakeRequestsRepository(
    catalog: catalog13(),
    clients: const [
      FakeRequestsRepository.maria,
      ActiveClient(
        clientId: 'c-manuel',
        fullName: 'Manuel Araújo Pereira',
        email: 'manuel.pereira@exemplo.pt',
      ),
      ActiveClient(
        clientId: 'c-marta',
        fullName: 'Marta Sousa Lopes',
        email: 'marta.lopes@exemplo.pt',
      ),
      FakeRequestsRepository.joao,
    ],
  );
  repo.openTypes['c-maria'] = [openMultirriscos()];
  return repo;
}

const message156 =
    'Bom dia, D. Maria. Para a renovação do seguro automóvel e para o novo '
    'seguro de vida, preciso destes elementos até ao fim do mês. Qualquer '
    'dúvida, ligue-me.';

OfficeRequest _office(
  String id,
  String code,
  String name,
  DateTime at, {
  RequestStage stage = RequestStage.created,
  bool policy = false,
}) => OfficeRequest(
  id: id,
  typeCode: code,
  typeName: name,
  stage: stage,
  origin: RequestOrigin.mediador,
  allowPolicyConditions: policy,
  createdAt: at,
  documentCount: 4,
  dataCount: 2,
  authorName: 'Ana Martins',
);

/// Os 5 pedidos da ficha da Maria (mais recentes primeiro).
List<OfficeRequest> mariaRequests() => [
  _office(
    'r-auto',
    'automovel',
    'Automóvel',
    DateTime(2026, 11, 27, 10, 14),
    policy: true,
  ),
  _office('r-vida', 'vida', 'Vida', DateTime(2026, 11, 27, 10, 14)),
  _office(
    'r-mh',
    'multirriscos_habitacao',
    'Multirriscos Habitação',
    DateTime(2026, 11, 20, 16, 40),
    stage: RequestStage.documentsSent,
  ),
  _office(
    'r-at',
    'at_variavel',
    'Acidentes de Trabalho (prémio variável)',
    DateTime(2026, 11, 14, 9, 30),
  ),
  _office('r-saude', 'saude', 'Saúde', DateTime(2026, 11, 13, 11, 2)),
];

/// Pedido aberto completo (Automóvel da Maria, lista editada).
RequestDetail automovelDetail({
  bool withdrawn = false,
  RequestStage stage = RequestStage.created,
}) => RequestDetail(
  id: 'r-auto',
  clientId: 'c-maria',
  clientName: 'Maria do Carmo Figueiredo',
  officeId: 'o-ribeira',
  officeName: 'Ribeira Seguros',
  typeCode: 'automovel',
  typeName: 'Automóvel',
  typeNote:
      'Se o condutor habitual não for o tomador, envie também o Cartão de '
      'Cidadão, a carta de condução e a morada do condutor.',
  origin: RequestOrigin.mediador,
  stage: stage,
  allowPolicyConditions: true,
  message: message156,
  authorName: 'Ana Martins',
  createdAt: DateTime.utc(2026, 11, 27, 10, 14),
  documentsSentAt: stage.number >= 2 ? DateTime.utc(2026, 11, 28, 9) : null,
  accessWithdrawn: withdrawn,
  accessWithdrawnAt: withdrawn ? DateTime.utc(2026, 11, 26, 15, 2) : null,
  items: const [
    RequestItem(
      id: 'i1',
      position: 1,
      kind: ItemKind.document,
      label: 'Dados do tomador (Cartão de Cidadão)',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'i2',
      position: 2,
      kind: ItemKind.data,
      label: 'Morada',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'i3',
      position: 3,
      kind: ItemKind.document,
      label: 'Carta de condução',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'i4',
      position: 4,
      kind: ItemKind.document,
      label: 'Documento Único Automóvel (DUA / livrete)',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'i5',
      position: 5,
      kind: ItemKind.data,
      label: 'Coberturas pretendidas',
      source: ItemSource.catalog,
    ),
    RequestItem(
      id: 'i6',
      position: 6,
      kind: ItemKind.document,
      label: 'Fotografias do veículo (frente, traseira e lados)',
      source: ItemSource.free,
    ),
  ],
);

MyRequest _mine(
  String id,
  String code,
  String name,
  String office,
  DateTime at, {
  int docs = 4,
  int data = 2,
  RequestStage stage = RequestStage.created,
  DateTime? withdrawnAt,
}) => MyRequest(
  id: id,
  typeCode: code,
  typeName: name,
  officeId: 'o-${office.hashCode}',
  officeName: office,
  stage: stage,
  origin: RequestOrigin.mediador,
  allowPolicyConditions: false,
  createdAt: at,
  documentCount: docs,
  dataCount: data,
  accessWithdrawn: withdrawnAt != null,
  accessWithdrawnAt: withdrawnAt,
);

/// Os meus pedidos da Maria: 3 em curso (um de escritório com nome longo)
/// e 1 com o acesso retirado.
List<MyRequest> mariaMine() => [
  _mine(
    'r-auto',
    'automovel',
    'Automóvel',
    'Ribeira Seguros',
    DateTime.utc(2026, 11, 27, 10, 14),
  ),
  _mine(
    'r-vida',
    'vida',
    'Vida',
    'Ribeira Seguros',
    DateTime.utc(2026, 11, 27, 10, 14),
    docs: 1,
    data: 4,
  ),
  _mine(
    'r-mh',
    'multirriscos_habitacao',
    'Multirriscos Habitação',
    'Gabinete de Mediação de Seguros Vale do Sousa & Filhos, Lda.',
    DateTime.utc(2026, 11, 20, 16, 40),
    docs: 2,
    data: 6,
  ),
  _mine(
    'r-saude',
    'saude',
    'Saúde',
    'Seguros Lima & Viana (exemplo)',
    DateTime.utc(2026, 11, 13, 11, 2),
    docs: 1,
    data: 3,
    withdrawnAt: DateTime.utc(2026, 11, 26, 15, 2),
  ),
];
