// Tarefa 3 da 002: sino e lista de notificações (US 7.3 a 7.6).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/app/connectivity.dart';
import 'package:promediacao/features/notifications/application/notifications_controller.dart';
import 'package:promediacao/features/notifications/data/supabase_notifications_repository.dart';
import 'package:promediacao/features/notifications/domain/notification_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_notifications_repository.dart';

void main() {
  late AppConnectivity connectivity;
  late FakeNotificationsRepository repo;
  late NotificationsController c;

  setUp(() {
    connectivity = AppConnectivity();
    repo = FakeNotificationsRepository([
      for (var i = 0; i < 30; i++) notification('n$i', read: i >= 2),
    ]);
    c = NotificationsController(
      repo,
      connectivity,
      now: () => DateTime.utc(2026, 11, 27, 12),
    );
    addTearDown(c.dispose);
    addTearDown(connectivity.dispose);
  });

  test('contador e lista paginada em 25', () async {
    expect(c.unread, isNull);
    await c.refreshCount();
    expect(c.unread, 2);
    await c.loadFirstPage();
    expect(c.items, hasLength(25));
    expect(c.hasMore, isTrue);
    expect(c.totalCount, 30);
    await c.loadMore();
    expect(c.items, hasLength(30));
    expect(c.syncedAt, DateTime.utc(2026, 11, 27, 12));
  });

  test(
    'abrir: devolve o pedido e só marca como lida depois do servidor',
    () async {
      await c.loadFirstPage();
      repo.readGate = Completer<void>();
      final target = c.open(c.items.first);
      expect(target, 'r-n0');
      expect(c.isMarking('n0'), isTrue);
      expect(c.items.first.isRead, isFalse);
      expect(c.unread, 2);

      repo.readGate!.complete();
      await pumpEventQueue();
      expect(c.items.first.isRead, isTrue);
      expect(c.unread, 1);
      expect(c.isMarking('n0'), isFalse);
    },
  );

  test('offline: último estado com aviso; aberta sem ligação é marcada '
      'quando a ligação volta', () async {
    await c.loadFirstPage();
    repo.failure = const NotificationFailure(NotificationFailureKind.network);
    await c.refreshCount();
    expect(connectivity.online, isFalse);
    expect(c.stale, isTrue);
    expect(c.unread, 2);
    await c.loadFirstPage();
    expect(c.load, NotificationsLoad.ready);
    expect(c.items, hasLength(25));

    expect(await c.markRead('n1'), isFalse);
    expect(c.isPendingRead('n1'), isTrue);
    expect(c.items[1].isRead, isFalse);

    repo.failure = null;
    connectivity.reportReachable();
    await pumpEventQueue();
    expect(c.isPendingRead('n1'), isFalse);
    expect(c.items[1].isRead, isTrue);
    expect(c.unread, 1);
    expect(c.stale, isFalse);
  });

  test('primeira carga com erro: estado de erro', () async {
    repo.failure = const NotificationFailure(NotificationFailureKind.unknown);
    await c.loadFirstPage();
    expect(c.load, NotificationsLoad.error);
  });

  test('não encontrada: não fica por marcar', () async {
    expect(await c.markRead('nao-existe'), isFalse);
    expect(c.isPendingRead('nao-existe'), isFalse);
  });

  test(
    'reset (fim de sessão) esquece tudo e ignora respostas antigas',
    () async {
      await c.loadFirstPage();
      repo.readGate = Completer<void>();
      final pending = c.markRead('n0');
      c.reset();
      repo.readGate!.complete();
      expect(await pending, isFalse);
      expect(c.items, isEmpty);
      expect(c.unread, isNull);
      expect(c.load, NotificationsLoad.idle);
    },
  );

  test('erros do repositório Supabase', () {
    expect(
      SupabaseNotificationsRepository.mapError(
        const PostgrestException(message: 'not_found', code: 'P0002'),
      ).kind,
      NotificationFailureKind.notFound,
    );
    expect(
      SupabaseNotificationsRepository.mapError(const SocketException('x')).kind,
      NotificationFailureKind.network,
    );
    expect(
      SupabaseNotificationsRepository.mapError(
        const PostgrestException(message: 'outra', code: '42501'),
      ).kind,
      NotificationFailureKind.unknown,
    );
  });

  test('linha de list_my_notifications', () {
    final n = AppNotification.fromRow({
      'notification_id': 'n1',
      'kind': 'pedido_criado',
      'title': 'Novo pedido: Vida',
      'body': 'Ribeira Seguros',
      'object_type': 'request',
      'object_id': 'r1',
      'is_read': false,
      'read_at': null,
      'created_at': '2026-11-27T10:14:00Z',
    });
    expect(n.requestId, 'r1');
    expect(n.isRead, isFalse);
  });
}
