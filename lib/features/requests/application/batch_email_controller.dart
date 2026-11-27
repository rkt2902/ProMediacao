import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/request_email_sender.dart';
import '../domain/request_models.dart';

/// Estado do email de uma criação (US 4.1 e 4.4).
enum BatchEmailStatus {
  /// Seguiu no envio inicial ("Email enviado a {email}.").
  sent,

  /// Não seguiu: "N pedidos criados, mas o email não foi enviado." com
  /// "Reenviar email".
  notSent,

  /// Reenviado com sucesso ("Email reenviado a {email}.").
  resent,

  /// A concessão deixou de estar ativa: "Este cliente já não partilha dados
  /// consigo." (sem reenviar).
  clientNotAvailable,
}

/// Resultado de uma tentativa de envio.
class EmailAttempt {
  const EmailAttempt({
    required this.delivered,
    this.lockUntil,
    this.recipientEmail,
    this.failure,
  });

  final bool delivered;

  /// Bloqueio do próximo envio (60 s depois de cada envio, ou o que o
  /// servidor pedir).
  final DateTime? lockUntil;
  final String? recipientEmail;
  final RequestFailure? failure;
}

/// Uma tentativa de envio, sem estado: usada no envio inicial (Novo pedido)
/// e em cada "Reenviar email".
Future<EmailAttempt> attemptBatchEmail(
  RequestEmailSender sender,
  String batchId, {
  required DateTime Function() now,
  Duration cooldown = const Duration(seconds: 60),
}) async {
  try {
    final r = await sender.send(batchId);
    return EmailAttempt(
      delivered: true,
      lockUntil: r.nextAllowedAt ?? now().add(cooldown),
      recipientEmail: r.recipientEmail,
    );
  } on RequestFailure catch (f) {
    final retry = f.retryAfterSeconds;
    return EmailAttempt(
      delivered: false,
      lockUntil: retry != null
          ? now().add(Duration(seconds: retry))
          : f.kind == RequestFailureKind.tooSoon
          ? now().add(cooldown)
          : null,
      failure: f,
    );
  }
}

/// "Reenviar email" na ficha do cliente depois de criar: bloqueio de 60 s
/// após cada envio (hora absoluta em [lockUntil]), nada dado como enviado
/// sem a resposta do servidor.
class BatchEmailController extends ChangeNotifier {
  BatchEmailController(
    this._sender,
    this._connectivity, {
    required this.batchId,
    required this._status,
    this._lockUntil,
    this._recipientEmail,
    this.cooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _scheduleTick();
  }

  final RequestEmailSender _sender;
  final AppConnectivity _connectivity;
  final String batchId;
  final Duration cooldown;
  final DateTime Function() _now;

  BatchEmailStatus _status;
  DateTime? _lockUntil;
  String? _recipientEmail;
  bool _sending = false;
  RequestFailureKind? _lastError;
  Timer? _timer;
  bool _disposed = false;

  BatchEmailStatus get status => _status;
  bool get sending => _sending;

  /// Email do destinatário, se o servidor o disse.
  String? get recipientEmail => _recipientEmail;

  /// "Pode reenviar às {hora}": nulo quando já pode.
  DateTime? get lockUntil {
    final l = _lockUntil;
    return l != null && l.isAfter(_now()) ? l : null;
  }

  /// Falha do último "Reenviar email" (`network`, `notAuthorized`,
  /// `unknown`, `emailNotSent`), para o aviso de erro. Nula depois de um
  /// envio com sucesso.
  RequestFailureKind? get lastError => _lastError;

  /// "Reenviar email" visível: o email não seguiu, ou já foi reenviado
  /// (botão desativado até ao fim do bloqueio).
  bool get showResend =>
      _status == BatchEmailStatus.notSent || _status == BatchEmailStatus.resent;

  /// Pode carregar em "Reenviar email" agora (offline bloqueia).
  bool get canResend =>
      showResend && !_sending && lockUntil == null && _connectivity.online;

  Future<void> resend() async {
    if (!showResend || _sending || lockUntil != null) return;
    _sending = true;
    _lastError = null;
    _emit();
    final a = await attemptBatchEmail(
      _sender,
      batchId,
      now: _now,
      cooldown: cooldown,
    );
    _sending = false;
    if (a.lockUntil != null) _lockUntil = a.lockUntil;
    if (a.delivered) {
      _connectivity.reportReachable();
      _status = BatchEmailStatus.resent;
      _recipientEmail = a.recipientEmail ?? _recipientEmail;
    } else {
      final kind = a.failure!.kind;
      switch (kind) {
        case RequestFailureKind.network:
          _connectivity.reportNetworkFailure();
          _lastError = kind;
        case RequestFailureKind.clientNotAvailable:
          _status = BatchEmailStatus.clientNotAvailable;
        case RequestFailureKind.tooSoon:
          // Houve um envio há pouco: só passa a mostrar o bloqueio.
          break;
        default:
          _lastError = kind;
      }
    }
    _emit();
  }

  void _emit() {
    if (_disposed) return;
    _scheduleTick();
    notifyListeners();
  }

  void _scheduleTick() {
    _timer?.cancel();
    _timer = null;
    final until = lockUntil;
    if (until == null) return;
    var wait = until.difference(_now());
    if (wait < const Duration(milliseconds: 50)) {
      wait = const Duration(milliseconds: 50);
    }
    _timer = Timer(wait, _emit);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
