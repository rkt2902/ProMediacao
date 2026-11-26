import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/mediator_models.dart';
import '../domain/mediator_repository.dart';

enum ClientsLoad { loading, ready, error }

/// Mensagem de resultado por cima da lista (sucesso, aviso ou erro).
class ClientsNotice {
  const ClientsNotice(this.id, this.kind, this.message);

  /// Muda a cada aviso novo (para a animação de entrada repetir).
  final int id;
  final ClientsNoticeKind kind;
  final String message;
}

enum ClientsNoticeKind { info, aviso, erro }

/// Resultado de [ClientsController.createClient].
enum CreateOutcome {
  /// Pedido criado e enviado.
  created,

  /// Pedido criado mas o email não seguiu (o aviso já está na lista).
  createdNotSent,
}

/// Estado do ecrã Clientes: lista paginada, criar cliente e "Reenviar
/// pedido" com o bloqueio de 60 s. Nada é dado como feito sem a resposta do
/// servidor.
class ClientsController extends ChangeNotifier {
  ClientsController(
    this._repo,
    this._connectivity, {
    this.pageSize = 25,
    this.cooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// O servidor aceita no máximo 200 linhas por pedido.
  static const int maxRows = 200;

  final MediatorRepository _repo;
  final AppConnectivity _connectivity;
  final int pageSize;
  final Duration cooldown;
  final DateTime Function() _now;

  ClientsLoad _load = ClientsLoad.loading;
  List<OfficeClient> _items = const [];
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  ClientsNotice? _notice;
  int _noticeSeq = 0;
  String? _highlight;
  final Map<String, DateTime> _locks = {};
  final Set<String> _sending = {};
  Timer? _timer;
  bool _disposed = false;

  ClientsLoad get load => _load;
  List<OfficeClient> get items => _items;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  bool get loadMoreFailed => _loadMoreFailed;
  ClientsNotice? get notice => _notice;
  String? get highlightId => _highlight;
  bool isSending(String grantId) => _sending.contains(grantId);

  /// Instante a partir do qual o pedido pode ser reenviado, ou `null` se já
  /// pode. Conta o reenvio feito aqui e a data do último envio do servidor
  /// (que sobrevive a recarregar a página).
  DateTime? lockUntil(OfficeClient c) {
    if (c.status != ClientStatus.pendente) return null;
    DateTime? until = _locks[c.grantId];
    final server = c.updatedAt.add(cooldown);
    if (until == null || server.isAfter(until)) until = server;
    return until.isAfter(_now()) ? until : null;
  }

  void _emit() {
    if (_disposed) return;
    _scheduleTick();
    notifyListeners();
  }

  void _scheduleTick() {
    _timer?.cancel();
    _timer = null;
    DateTime? next;
    for (final c in _items) {
      final u = lockUntil(c);
      if (u != null && (next == null || u.isBefore(next))) next = u;
    }
    if (next == null) return;
    var wait = next.difference(_now());
    if (wait < const Duration(milliseconds: 50)) {
      wait = const Duration(milliseconds: 50);
    }
    _timer = Timer(wait, _emit);
  }

  void _setNotice(ClientsNoticeKind kind, String? message) {
    _notice = message == null
        ? null
        : ClientsNotice(++_noticeSeq, kind, message);
  }

  void dismissNotice() {
    if (_notice == null) return;
    _notice = null;
    _emit();
  }

  /// Primeira carga (ou "Tentar de novo").
  Future<void> start() async {
    _load = ClientsLoad.loading;
    _emit();
    try {
      final rows = await _repo.listClients(limit: pageSize + 1, offset: 0);
      _connectivity.reportReachable();
      _applyFirstPage(rows, pageSize);
      _load = ClientsLoad.ready;
    } on MediatorFailure catch (f) {
      _reportNetwork(f);
      _load = ClientsLoad.error;
    }
    _emit();
  }

  void _applyFirstPage(List<OfficeClient> rows, int wanted) {
    _hasMore = rows.length > wanted;
    _items = _hasMore ? rows.sublist(0, wanted) : rows;
    _loadMoreFailed = false;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _loadMoreFailed = false;
    _emit();
    try {
      final rows = await _repo.listClients(
        limit: pageSize + 1,
        offset: _items.length,
      );
      _connectivity.reportReachable();
      final more = rows.length > pageSize;
      final known = {for (final c in _items) c.grantId};
      _items = [
        ..._items,
        for (final c in (more ? rows.sublist(0, pageSize) : rows))
          if (!known.contains(c.grantId)) c,
      ];
      _hasMore = more;
    } on MediatorFailure catch (f) {
      _reportNetwork(f);
      _loadMoreFailed = true;
    }
    _loadingMore = false;
    _emit();
  }

  /// Volta a ler o que já está carregado (depois de criar ou reenviar a
  /// linha sobe ao topo). Falhar aqui não estraga o que já está no ecrã.
  Future<void> _refresh({String? highlightEmail, String? highlightId}) async {
    final wanted = (_items.length > pageSize ? _items.length : pageSize).clamp(
      1,
      maxRows - 1,
    );
    try {
      final rows = await _repo.listClients(limit: wanted + 1, offset: 0);
      _connectivity.reportReachable();
      _applyFirstPage(rows, wanted);
      _load = ClientsLoad.ready;
      if (highlightId != null) {
        _highlight = highlightId;
      } else if (highlightEmail != null) {
        final e = highlightEmail.toLowerCase();
        for (final c in _items) {
          if (c.email.toLowerCase() == e) {
            _highlight = c.grantId;
            break;
          }
        }
      }
    } on MediatorFailure catch (f) {
      _reportNetwork(f);
    }
  }

  void _reportNetwork(MediatorFailure f) {
    if (f.kind == MediatorFailureKind.network) {
      _connectivity.reportNetworkFailure();
    }
  }

  /// Cria o cliente. Lança [MediatorFailure] para o formulário mostrar o
  /// erro junto dos campos; no sucesso, a lista é atualizada e aparece o aviso.
  Future<CreateOutcome> createClient({
    required String fullName,
    required String email,
    required String successMessage,
    required String notSentMessage,
  }) async {
    _highlight = null;
    try {
      await _repo.createClient(fullName: fullName, email: email);
    } on MediatorFailure catch (f) {
      _reportNetwork(f);
      if (f.kind != MediatorFailureKind.sendFailed) rethrow;
      _connectivity.reportReachable();
      await _refresh(highlightEmail: email);
      _setNotice(ClientsNoticeKind.aviso, notSentMessage);
      _emit();
      return CreateOutcome.createdNotSent;
    }
    _connectivity.reportReachable();
    await _refresh(highlightEmail: email);
    _setNotice(ClientsNoticeKind.info, successMessage);
    _emit();
    return CreateOutcome.created;
  }

  /// "Reenviar pedido". As mensagens vêm de quem chama (copy da UI).
  Future<void> resend(
    OfficeClient c, {
    required String sentMessage,
    required String notPendingMessage,
    required String sendFailedMessage,
    required String networkMessage,
    required String genericMessage,
  }) async {
    if (_sending.contains(c.grantId) || lockUntil(c) != null) return;
    _highlight = null;
    _setNotice(ClientsNoticeKind.info, null);
    _sending.add(c.grantId);
    _emit();
    try {
      await _repo.resendRequest(c.grantId);
      _connectivity.reportReachable();
      _locks[c.grantId] = _now().add(cooldown);
      _sending.remove(c.grantId);
      await _refresh(highlightId: c.grantId);
      _setNotice(
        ClientsNoticeKind.info,
        sentMessage.replaceAll('{email}', c.email),
      );
    } on MediatorFailure catch (f) {
      _sending.remove(c.grantId);
      _reportNetwork(f);
      switch (f.kind) {
        case MediatorFailureKind.tooSoon:
          // Já houve um envio há pouco: só passa a mostrar o bloqueio.
          _locks[c.grantId] = _now().add(
            Duration(seconds: f.retryAfterSeconds ?? cooldown.inSeconds),
          );
        case MediatorFailureKind.notPending:
        case MediatorFailureKind.forbidden:
          _setNotice(ClientsNoticeKind.erro, notPendingMessage);
          await _refresh();
        case MediatorFailureKind.sendFailed:
          _setNotice(ClientsNoticeKind.erro, sendFailedMessage);
        case MediatorFailureKind.network:
          _setNotice(ClientsNoticeKind.erro, networkMessage);
        default:
          _setNotice(ClientsNoticeKind.erro, genericMessage);
      }
    }
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
