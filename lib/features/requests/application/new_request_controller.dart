import 'package:flutter/foundation.dart';

import '../../../app/connectivity.dart';
import '../domain/request_email_sender.dart';
import '../domain/request_models.dart';
import '../domain/requests_repository.dart';
import 'batch_email_controller.dart';
import 'created_batch.dart';
import 'requests_load.dart';

export 'requests_load.dart';

/// Uma linha da lista que o cliente vai receber, num tipo escolhido.
class DraftLine {
  const DraftLine._({
    required this.key,
    required this.kind,
    required this.label,
    this.catalogItemId,
  });

  /// Identificador estável na lista (para "Tirar" e para chaves de widgets).
  final String key;
  final ItemKind kind;
  final String label;

  /// Nulo nos itens acrescentados neste pedido ("Acrescentado neste pedido").
  final String? catalogItemId;

  bool get isFree => catalogItemId == null;

  DraftItem toDraftItem() => catalogItemId != null
      ? CatalogDraftItem(catalogItemId!)
      : FreeDraftItem(kind: kind, label: label);
}

/// Porque é que um item livre não foi acrescentado.
enum FreeItemError {
  /// "Escreva o item a pedir."
  empty,

  /// Mais de [NewRequestController.maxItemLength] caracteres.
  tooLong,

  /// Tem `<`, `>` ou caracteres de controlo (tab, NEL U+0085...).
  invalidCharacters,

  /// A lista já tem [NewRequestController.maxItems] itens.
  tooMany,
}

/// Porque é que "Criar" está desativado (a razão fica escrita por baixo do
/// botão). [NewRequestController.blockedType] diz o tipo em `emptyList`.
enum SubmitBlock {
  /// "Escolha o cliente e pelo menos um tipo."
  chooseClientAndType,

  /// "Escolha o cliente" (já há tipos).
  chooseClient,

  /// "Escolha pelo menos um tipo de seguro."
  chooseType,

  /// Todos os tipos escolhidos estão à espera da confirmação de repetido.
  awaitingConfirmation,

  /// "A lista de {tipo} está vazia."
  emptyList,

  /// "Encurte a mensagem para 500 caracteres."
  messageTooLong,

  /// "Este cliente já não partilha dados consigo."
  clientUnavailable,

  /// "Sem ligação. A sua escolha fica guardada neste ecrã; pode criar quando
  /// a ligação voltar."
  offline,
}

class _TypeDraft {
  _TypeDraft(this.type);

  /// Troca-se quando o catálogo é recarregado (itens desativados saem).
  InsuranceType type;
  final Set<String> removed = {};
  final List<DraftLine> free = [];
  bool confirmRepeat = false;
}

/// Estado do ecrã Novo pedido (mediador, US 1 e 2.1). Guarda a escolha
/// durante erros e falta de ligação; nada é dado como criado sem a resposta
/// do servidor, e "Criar" não duplica pedidos (um envio de cada vez, e
/// nenhum depois do sucesso).
///
/// Depois de [submit] devolver um [CreatedBatch], ele já está no
/// [CreatedRequestsHandoff]: a página só tem de navegar para a ficha do
/// cliente (`AppRoutes.mediatorClient(clientId)`).
class NewRequestController extends ChangeNotifier {
  NewRequestController(
    this._repo,
    this._email,
    this._connectivity,
    this._handoff, {
    this.preselectedClientId,
    this.emailCooldown = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _wasOnline = _connectivity.online;
    _connectivity.addListener(_onConnectivity);
  }

  static const int maxMessageLength = 500;
  static const int maxItemLength = 200;
  static const int maxItems = 60;

  final RequestsRepository _repo;
  final RequestEmailSender _email;
  final AppConnectivity _connectivity;
  final CreatedRequestsHandoff _handoff;

  /// Cliente vindo da ficha ou da linha de Clientes (já escolhido).
  final String? preselectedClientId;
  final Duration emailCooldown;
  final DateTime Function() _now;

  bool _disposed = false;
  late bool _wasOnline;

  // ---- Catálogo -------------------------------------------------------------

  RequestsLoad _catalogLoad = RequestsLoad.loading;
  List<InsuranceType> _catalog = const [];

  RequestsLoad get catalogLoad => _catalogLoad;
  List<InsuranceType> get catalog => _catalog;

  // ---- Cliente --------------------------------------------------------------

  RequestsLoad? _clientsLoad;
  List<ActiveClient> _clients = const [];
  String _query = '';
  ActiveClient? _client;
  RequestsLoad? _preselectLoad;
  ClientHeader? _unavailable;
  bool _clientLost = false;

  /// Lista para escolher o cliente (nula enquanto não é precisa).
  RequestsLoad? get clientsLoad => _clientsLoad;
  List<ActiveClient> get clients => _clients;
  String get query => _query;

  /// Clientes que coincidem com [query] (nome ou email, sem distinguir
  /// maiúsculas).
  List<ActiveClient> get matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _clients;
    return [
      for (final c in _clients)
        if (c.fullName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q))
          c,
    ];
  }

  /// Cliente escolhido.
  ActiveClient? get client => _client;

  /// Validação do cliente pré-escolhido (nula sem pré-escolha).
  RequestsLoad? get preselectLoad => _preselectLoad;

  /// Cliente pré-escolhido sem concessão ativa: a página mostra o motivo
  /// (pendente, recusada) ou "Sem acesso" (`unavailable`).
  ClientHeader? get unavailableClient => _unavailable;

  /// A concessão deixou de estar ativa entre abrir e criar.
  bool get clientLost => _clientLost;

  // ---- Tipos em curso -------------------------------------------------------

  RequestsLoad? _openLoad;
  Map<String, OpenType> _open = const {};
  final Set<String> _repeatFlagged = {};
  int _clientToken = 0;

  RequestsLoad? get openTypesLoad => _openLoad;

  /// "Em curso desde {data}" e o aviso de repetido. Nulo se não se sabe a
  /// data (o servidor só disse que há um pedido em curso).
  OpenType? openTypeFor(String code) => _open[code];

  /// O tipo tem pedido em curso para este cliente.
  bool isOpen(String code) =>
      _open.containsKey(code) || _repeatFlagged.contains(code);

  // ---- Tipos escolhidos e listas --------------------------------------------

  final Map<String, _TypeDraft> _drafts = {};
  int _lineSeq = 0;

  bool isSelected(String code) => _drafts.containsKey(code);

  /// Tipos escolhidos, pela ordem do catálogo.
  List<InsuranceType> get selectedTypes => [
    for (final t in _catalog)
      if (_drafts.containsKey(t.code)) t,
  ];

  /// Escolhido, em curso e ainda sem "Criar outro na mesma": não conta.
  bool needsConfirmation(String code) {
    final d = _drafts[code];
    return d != null && isOpen(code) && !d.confirmRepeat;
  }

  /// "Vai ser criado um segundo pedido de {tipo}."
  bool repeatConfirmed(String code) {
    final d = _drafts[code];
    return d != null && isOpen(code) && d.confirmRepeat;
  }

  /// Tipos que vão ser criados (escolhidos e sem confirmação pendente).
  List<InsuranceType> get typesToCreate => [
    for (final t in selectedTypes)
      if (!needsConfirmation(t.code)) t,
  ];

  /// Tipos à espera da confirmação de repetido.
  List<InsuranceType> get typesAwaitingConfirmation => [
    for (final t in selectedTypes)
      if (needsConfirmation(t.code)) t,
  ];

  /// Linhas visíveis de um tipo: itens do catálogo não tirados (pela ordem
  /// do catálogo) e depois os acrescentados.
  List<DraftLine> lines(String code) {
    final d = _drafts[code];
    if (d == null) return const [];
    return [
      for (final i in d.type.items)
        if (!d.removed.contains(i.id))
          DraftLine._(
            key: 'c:${i.id}',
            kind: i.kind,
            label: i.label,
            catalogItemId: i.id,
          ),
      ...d.free,
    ];
  }

  /// Itens do catálogo tirados que ainda existem no catálogo.
  int removedCount(String code) {
    final d = _drafts[code];
    if (d == null) return 0;
    final ids = {for (final i in d.type.items) i.id};
    return d.removed.where(ids.contains).length;
  }

  bool isEmptyList(String code) => lines(code).isEmpty;

  // ---- Opções ---------------------------------------------------------------

  bool _allowPolicyConditions = false;
  String _message = '';

  bool get allowPolicyConditions => _allowPolicyConditions;
  String get message => _message;

  /// Caracteres contados como o servidor (code points, depois de aparar).
  int get messageLength => _message.trim().runes.length;
  bool get messageTooLong => messageLength > maxMessageLength;

  // ---- Envio ----------------------------------------------------------------

  bool _submitting = false;
  RequestFailure? _error;
  CreatedBatch? _created;

  bool get submitting => _submitting;

  /// Falha do último "Criar" (nada foi criado). `repeatedRequest` marca os
  /// tipos em [isOpen]; `clientNotAvailable` liga [clientLost].
  RequestFailure? get error => _error;

  /// Resultado depois do sucesso (o ecrã navega para a ficha).
  CreatedBatch? get created => _created;

  /// Razão de "Criar" estar desativado; nula se pode criar.
  SubmitBlock? get block {
    if (_clientLost || _unavailable != null) {
      return SubmitBlock.clientUnavailable;
    }
    final noClient = _client == null;
    if (_drafts.isEmpty) {
      return noClient
          ? SubmitBlock.chooseClientAndType
          : SubmitBlock.chooseType;
    }
    if (noClient) return SubmitBlock.chooseClient;
    if (blockedType != null) return SubmitBlock.emptyList;
    if (typesToCreate.isEmpty) return SubmitBlock.awaitingConfirmation;
    if (messageTooLong) return SubmitBlock.messageTooLong;
    if (!_connectivity.online) return SubmitBlock.offline;
    return null;
  }

  /// Primeiro tipo a criar com a lista vazia ("A lista de {tipo} está
  /// vazia.").
  InsuranceType? get blockedType {
    for (final t in typesToCreate) {
      if (isEmptyList(t.code)) return t;
    }
    return null;
  }

  bool get canSubmit => block == null && !_submitting && _created == null;

  // ---- Ações ----------------------------------------------------------------

  /// Primeira carga: catálogo e, conforme a origem, a validação do cliente
  /// pré-escolhido ou a lista de clientes ativos.
  Future<void> start() async {
    final preselected = preselectedClientId;
    await Future.wait([
      loadCatalog(),
      if (preselected != null) _loadPreselected(preselected) else loadClients(),
    ]);
  }

  /// [silent]: recarrega sem voltar ao estado "a carregar" (a escolha não
  /// pisca).
  Future<void> loadCatalog({bool silent = false}) async {
    if (!silent) {
      _catalogLoad = RequestsLoad.loading;
      _emit();
    }
    try {
      _catalog = await _repo.catalog();
      _connectivity.reportReachable();
      _catalogLoad = RequestsLoad.ready;
      // Tipos que já não estão no catálogo saem da escolha.
      final codes = {for (final t in _catalog) t.code};
      _drafts.removeWhere((code, _) => !codes.contains(code));
      // Os tipos que ficam passam a ter os itens atuais do catálogo.
      for (final t in _catalog) {
        _drafts[t.code]?.type = t;
      }
    } on RequestFailure catch (f) {
      _report(f);
      _catalogLoad = RequestsLoad.error;
    }
    _emit();
  }

  Future<void> loadClients() async {
    _clientsLoad = RequestsLoad.loading;
    _emit();
    try {
      _clients = await _repo.activeClients();
      _connectivity.reportReachable();
      _clientsLoad = RequestsLoad.ready;
    } on RequestFailure catch (f) {
      _report(f);
      _clientsLoad = RequestsLoad.error;
    }
    _emit();
  }

  Future<void> _loadPreselected(String clientId) async {
    _preselectLoad = RequestsLoad.loading;
    _emit();
    try {
      final h = await _repo.clientHeader(clientId);
      _connectivity.reportReachable();
      _preselectLoad = RequestsLoad.ready;
      if (h.isActive) {
        _unavailable = null;
        _setClient(
          ActiveClient(
            clientId: h.clientId,
            fullName: h.fullName ?? '',
            email: h.email ?? '',
          ),
        );
      } else {
        _unavailable = h;
      }
    } on RequestFailure catch (f) {
      _report(f);
      _preselectLoad = RequestsLoad.error;
    }
    _emit();
  }

  /// "Tentar de novo" de qualquer carga que falhou.
  Future<void> retry() async {
    final preselected = preselectedClientId;
    await Future.wait([
      if (_catalogLoad == RequestsLoad.error) loadCatalog(),
      if (_preselectLoad == RequestsLoad.error && preselected != null)
        _loadPreselected(preselected),
      if (_clientsLoad == RequestsLoad.error) loadClients(),
      if (_openLoad == RequestsLoad.error && _client != null)
        _loadOpenTypes(_client!.clientId, _clientToken),
    ]);
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _emit();
  }

  void chooseClient(ActiveClient c) {
    _unavailable = null;
    _setClient(c);
    _emit();
  }

  /// "Mudar": volta à escolha do cliente. Os tipos e as listas ficam.
  void changeClient() {
    _client = null;
    _clientLost = false;
    _unavailable = null;
    _open = const {};
    _repeatFlagged.clear();
    _openLoad = null;
    _clientToken++;
    if (_error?.kind == RequestFailureKind.clientNotAvailable ||
        _error?.kind == RequestFailureKind.repeatedRequest) {
      _error = null;
    }
    for (final d in _drafts.values) {
      d.confirmRepeat = false;
    }
    if (_clientsLoad == null || _clientsLoad == RequestsLoad.error) {
      loadClients();
    }
    _emit();
  }

  void _setClient(ActiveClient c) {
    final changed = _client?.clientId != c.clientId;
    _client = c;
    if (!changed) return;
    _clientLost = false;
    _open = const {};
    _repeatFlagged.clear();
    for (final d in _drafts.values) {
      d.confirmRepeat = false;
    }
    _loadOpenTypes(c.clientId, ++_clientToken);
  }

  Future<void> _loadOpenTypes(String clientId, int token) async {
    _openLoad = RequestsLoad.loading;
    _emit();
    try {
      final rows = await _repo.clientOpenTypes(clientId);
      if (token != _clientToken) return;
      _open = {for (final r in rows) r.typeCode: r};
      _openLoad = RequestsLoad.ready;
    } on RequestFailure catch (f) {
      if (token != _clientToken) return;
      // Não bloqueia: o servidor recusa o repetido de qualquer forma.
      _report(f);
      _openLoad = RequestsLoad.error;
    }
    _emit();
  }

  void toggleType(String code) {
    if (_drafts.containsKey(code)) {
      _drafts.remove(code);
    } else {
      final type = _typeFor(code);
      if (type == null) return;
      _drafts[code] = _TypeDraft(type);
    }
    _emit();
  }

  /// "Tirar este tipo" (aviso de repetido).
  void removeType(String code) {
    if (_drafts.remove(code) != null) _emit();
  }

  /// "Criar outro na mesma".
  void confirmRepeat(String code) {
    final d = _drafts[code];
    if (d == null || d.confirmRepeat) return;
    d.confirmRepeat = true;
    if (_error?.kind == RequestFailureKind.repeatedRequest &&
        typesAwaitingConfirmation.isEmpty) {
      _error = null;
    }
    _emit();
  }

  /// "Tirar" um item (do catálogo: fica para "Repor lista"; acrescentado:
  /// sai de vez).
  void removeLine(String code, String key) {
    final d = _drafts[code];
    if (d == null) return;
    if (key.startsWith('c:')) {
      d.removed.add(key.substring(2));
    } else {
      d.free.removeWhere((l) => l.key == key);
    }
    _emit();
  }

  /// "Repor lista": volta a pôr os itens do catálogo tirados.
  void restoreList(String code) {
    final d = _drafts[code];
    if (d == null || d.removed.isEmpty) return;
    d.removed.clear();
    _emit();
  }

  /// "Acrescentar item": valida como o servidor (≤200, sem `<` `>` nem
  /// caracteres de controlo). Devolve o erro, ou nulo se acrescentou.
  FreeItemError? addFreeItem(String code, ItemKind kind, String label) {
    final d = _drafts[code];
    if (d == null) return null;
    final error = validateFreeItem(label);
    if (error != null) return error;
    if (lines(code).length >= maxItems) return FreeItemError.tooMany;
    d.free.add(
      DraftLine._(key: 'f:${++_lineSeq}', kind: kind, label: label.trim()),
    );
    _emit();
    return null;
  }

  static final RegExp _invalidChars = RegExp(r'[<>\x00-\x1F\x7F-\x9F]');

  /// Validação de um item livre (pública para o formulário a usar ao vivo).
  static FreeItemError? validateFreeItem(String label) {
    final text = label.trim();
    if (text.isEmpty) return FreeItemError.empty;
    if (text.runes.length > maxItemLength) return FreeItemError.tooLong;
    if (_invalidChars.hasMatch(text)) return FreeItemError.invalidCharacters;
    return null;
  }

  set allowPolicyConditions(bool value) {
    if (value == _allowPolicyConditions) return;
    _allowPolicyConditions = value;
    _emit();
  }

  set message(String value) {
    if (value == _message) return;
    _message = value;
    if (_error?.kind == RequestFailureKind.messageTooLong && !messageTooLong) {
      _error = null;
    }
    _emit();
  }

  /// "Criar N pedidos". Devolve o resultado (já no handoff) ou nulo se nada
  /// foi criado (a razão fica em [error]; a escolha mantém-se).
  Future<CreatedBatch?> submit() async {
    final c = _client;
    if (!canSubmit || c == null) return null;
    final types = typesToCreate;
    _submitting = true;
    _error = null;
    _emit();

    final List<CreatedRequest> rows;
    try {
      rows = await _repo.createRequests(
        clientId: c.clientId,
        requests: [
          for (final t in types)
            RequestDraft(
              typeCode: t.code,
              confirmRepeat: _drafts[t.code]!.confirmRepeat,
              items: [for (final l in lines(t.code)) l.toDraftItem()],
            ),
        ],
        allowPolicyConditions: _allowPolicyConditions,
        message: _message,
      );
    } on RequestFailure catch (f) {
      _report(f);
      _error = f;
      switch (f.kind) {
        case RequestFailureKind.clientNotAvailable:
          _clientLost = true;
        case RequestFailureKind.repeatedRequest:
          // Nada foi criado: os tipos em curso passam a pedir confirmação.
          for (final code in f.typeCodes) {
            _repeatFlagged.add(code);
            _drafts[code]?.confirmRepeat = false;
          }
          _loadOpenTypes(c.clientId, _clientToken);
        case RequestFailureKind.invalidItem:
        case RequestFailureKind.invalidInput:
          // O catálogo mudou entre abrir e criar: recarrega-o e a página
          // explica (a escolha e os itens acrescentados mantêm-se).
          _submitting = false;
          _emit();
          await loadCatalog(silent: true);
          return null;
        default:
          break;
      }
      _submitting = false;
      _emit();
      return null;
    }
    _connectivity.reportReachable();

    // Os pedidos existem: daqui em diante nada é mostrado como falha de
    // criação. O email é um passo à parte (US 4.4).
    final batchId = rows.first.batchId;
    final email = await attemptBatchEmail(
      _email,
      batchId,
      now: _now,
      cooldown: emailCooldown,
    );
    if (email.failure?.kind == RequestFailureKind.network) {
      _connectivity.reportNetworkFailure();
    }
    final byOrder = {for (final (i, t) in types.indexed) t.code: i};
    final sorted = [...rows]
      ..sort(
        (a, b) =>
            (byOrder[a.typeCode] ?? 99).compareTo(byOrder[b.typeCode] ?? 99),
      );
    final batch = CreatedBatch(
      batchId: batchId,
      clientId: c.clientId,
      clientName: c.fullName,
      clientEmail: email.recipientEmail ?? c.email,
      requests: List.unmodifiable(sorted),
      emailStatus: email.delivered
          ? BatchEmailStatus.sent
          : email.failure?.kind == RequestFailureKind.clientNotAvailable
          ? BatchEmailStatus.clientNotAvailable
          : BatchEmailStatus.notSent,
      emailLockUntil: email.lockUntil,
    );
    _handoff.put(batch);
    _created = batch;
    _submitting = false;
    _emit();
    return batch;
  }

  // ---- Auxiliares -----------------------------------------------------------

  InsuranceType? _typeFor(String code) {
    for (final t in _catalog) {
      if (t.code == code) return t;
    }
    return null;
  }

  void _report(RequestFailure f) {
    if (f.kind == RequestFailureKind.network) {
      _connectivity.reportNetworkFailure();
    }
  }

  void _onConnectivity() {
    final online = _connectivity.online;
    final back = online && !_wasOnline;
    _wasOnline = online;
    if (back) {
      retry();
    } else {
      _emit();
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivity.removeListener(_onConnectivity);
    super.dispose();
  }
}
