@Tags(['design-review'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:promediacao/core/widgets/widgets.dart';
import 'package:promediacao/features/notifications/domain/notification_models.dart';

import '../../features/client_requests/client_requests_test_helpers.dart';
import '../../features/consent/consent_test_helpers.dart';
import '../../features/notifications/fake_notifications_repository.dart';
import '../../features/requests/fake_requests_repository.dart';
import 'review_helpers.dart';

FakeRequestsRepository _requests() {
  final repo = FakeRequestsRepository()..mine.addAll(mariaMine());
  repo.details['r-auto'] = automovelDetail();
  repo.details['r-saude'] = automovelDetail(withdrawn: true);
  return repo;
}

AppNotification _n(
  String id,
  String type,
  String office,
  DateTime at, {
  bool read = false,
}) => AppNotification(
  id: id,
  kind: AppNotification.kindRequestCreated,
  title: 'Novo pedido: $type',
  body: office,
  objectType: AppNotification.objectRequest,
  objectId: 'r-auto',
  isRead: read,
  createdAt: at,
);

/// 2 por ler + 2 lidas (uma de escritório com nome longo).
FakeNotificationsRepository _notifications() => FakeNotificationsRepository([
  _n('n1', 'Automóvel', 'Ribeira Seguros', DateTime.utc(2026, 11, 27, 10, 14)),
  _n('n2', 'Vida', 'Ribeira Seguros', DateTime.utc(2026, 11, 27, 10, 14)),
  _n(
    'n3',
    'Multirriscos Habitação',
    'Gabinete de Mediação de Seguros Vale do Sousa & Filhos, Lda.',
    DateTime.utc(2026, 11, 20, 16, 40),
    read: true,
  ),
  _n(
    'n4',
    'Saúde',
    'Seguros Lima & Viana (exemplo)',
    DateTime.utc(2026, 11, 13, 11, 2),
    read: true,
  ),
]);

FakeConsentRepository _consent() => FakeConsentRepository(
  grants: [
    activeGrant(),
    activeGrant(
      id: 'g-vale',
      office: 'Gabinete de Mediação de Seguros Vale do Sousa & Filhos, Lda.',
    ),
    withdrawnGrant(),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  double scale = 1.0,
  String location = '/cliente',
}) async {
  await loadReviewFonts();
  if (scale != 1.0) setTextScale(tester, scale);
  await pumpClient(
    tester,
    requests: _requests(),
    notifications: _notifications(),
    consent: _consent(),
    size: size,
    location: location,
  );
}

void main() {
  for (final v in mainVariants.entries) {
    testWidgets('meus-pedidos-${v.key}', (tester) async {
      await _pump(tester, v.value.$1, scale: v.value.$2);
      await shoot(tester, 'meus-pedidos-${v.key}');
    }, skip: skipReview);

    testWidgets('pedido-cliente-${v.key}', (tester) async {
      await _pump(
        tester,
        v.value.$1,
        scale: v.value.$2,
        location: '/cliente/pedidos/r-auto',
      );
      await shoot(tester, 'pedido-cliente-${v.key}');
    }, skip: skipReview);
  }

  for (final k in ['telemovel', 'desktop']) {
    testWidgets('meus-pedidos-completo-$k', (tester) async {
      await _pump(tester, reviewSizes[k]!);
      await growToFullPage(tester);
      await shoot(tester, 'meus-pedidos-completo-$k');
    }, skip: skipReview);

    testWidgets('pedido-cliente-completo-$k', (tester) async {
      await _pump(tester, reviewSizes[k]!, location: '/cliente/pedidos/r-auto');
      await growToFullPage(tester);
      await shoot(tester, 'pedido-cliente-completo-$k');
    }, skip: skipReview);
  }

  for (final e in reviewSizes.entries) {
    testWidgets('pedido-cliente-acesso-retirado-${e.key}', (tester) async {
      await _pump(tester, e.value, location: '/cliente/pedidos/r-saude');
      await shoot(tester, 'pedido-cliente-acesso-retirado-${e.key}');
    }, skip: skipReview);
  }

  for (final k in ['tablet', 'desktop']) {
    testWidgets('notificacoes-$k', (tester) async {
      await _pump(tester, reviewSizes[k]!);
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      await shoot(tester, 'notificacoes-$k');
    }, skip: skipReview);
  }

  for (final v in {
    'telemovel': (reviewSizes['telemovel']!, 1.0),
    '320': (smallSize, 1.0),
    'telemovel-1.3': (reviewSizes['telemovel']!, 1.3),
  }.entries) {
    testWidgets('notificacoes-${v.key}', (tester) async {
      await _pump(
        tester,
        v.value.$1,
        scale: v.value.$2,
        location: '/cliente/notificacoes',
      );
      await shoot(tester, 'notificacoes-${v.key}');
    }, skip: skipReview);
  }
}
