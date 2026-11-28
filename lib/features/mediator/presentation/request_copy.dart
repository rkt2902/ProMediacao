import '../../../core/format/dates.dart';
import '../../requests/application/new_request_controller.dart';
import '../../requests/domain/request_models.dart';

/// Textos dos ecrãs de pedidos do mediador (03-design.md, ecrãs 1, 3 e 3b).
/// Tratamento formal, PT-PT.
abstract final class RequestCopy {
  // ---- Etapas ---------------------------------------------------------------

  /// Palavra curta ao lado do trilho nas listas.
  static String stageShort(RequestStage s) => switch (s) {
    RequestStage.created => 'Criado',
    RequestStage.documentsSent => 'Documentos enviados',
    RequestStage.inReview => 'Em análise',
    RequestStage.sentToInsurers => 'Enviado às seguradoras',
  };

  /// Nome completo da etapa (pedido aberto e faixa de etapas).
  static String stageLong(RequestStage s) => switch (s) {
    RequestStage.created => 'Pedido criado',
    RequestStage.documentsSent => 'Documentos enviados',
    RequestStage.inReview => 'Em análise pelo mediador',
    RequestStage.sentToInsurers => 'Enviado às seguradoras',
  };

  static const List<String> stageNames = [
    'Pedido criado',
    'Documentos enviados',
    'Em análise pelo mediador',
    'Enviado às seguradoras',
  ];

  // ---- Comuns ---------------------------------------------------------------

  static const String retry = 'Tentar de novo';
  static const String backToClients = 'Voltar a Clientes';
  static const String backFallback = 'Cliente';
  static const String backClients = 'Clientes';
  static const String needsConnectionToCreate =
      'Precisa de ligação para criar.';
  static const String offline =
      'Sem ligação. Pode ver os pedidos; criar fica disponível quando a '
      'ligação voltar.';
  static const String offlineNewRequest =
      'Sem ligação. A sua escolha fica guardada neste ecrã; pode criar '
      'quando a ligação voltar.';

  static const String offlineBanner =
      'Sem ligação à internet. Pode continuar a escolher; criar fica '
      'disponível quando a ligação voltar.';

  static const String policyConditions = 'Condições particulares';
  static const String policyNoteSheet =
      'Pode enviar as condições particulares da apólice atual em vez dos '
      'documentos um a um.';
  static const String policyNoteReading =
      'O cliente pode enviar as condições particulares da apólice atual em '
      'vez dos documentos um a um.';

  static String plural(int n, String one, String many) =>
      n == 1 ? '$n $one' : '$n $many';

  /// "4 documentos · 2 dados".
  static String counts(int documents, int data) =>
      '${plural(documents, 'documento', 'documentos')} · '
      '${plural(data, 'dado', 'dados')}';

  static String inProgress(int n) => '$n em curso';

  // ---- Novo pedido ----------------------------------------------------------

  static const String newRequest = 'Novo pedido';
  static const String newRequestIntro =
      'Um pedido por tipo de seguro. O cliente recebe um email curto e vê a '
      'lista na app.';

  static const String sectionClient = 'Cliente';
  static const String sectionTypes = 'Tipos de seguro';
  static const String sectionTypesHint = 'É criado um pedido por tipo.';
  static const String sectionPolicy = 'Condições particulares';
  static const String sectionMessage = 'Mensagem';

  static const String change = 'Mudar';
  static const String searchClient = 'Procurar por nome ou email';
  static const String onlyActiveNote =
      'Só aparecem clientes que aceitaram partilhar os dados com este '
      'escritório.';
  static const String noMatches = 'Nenhum cliente corresponde à pesquisa.';

  static String openSince(DateTime d) => 'Em curso desde ${AppDates.date(d)}';
  static const String openSinceUnknown = 'Já existe um pedido em curso';

  static String repeatTitle(String type) =>
      'Já existe um pedido de $type em curso.';
  static String repeatDetail(OpenType? open) {
    if (open == null) {
      return 'Sem confirmar, este tipo não é criado.';
    }
    return 'Criado a ${AppDates.date(open.lastCreatedAt)}, ainda na etapa '
        '${open.maxStage.number} de 4. Sem confirmar, este tipo não é '
        'criado.';
  }

  static const String createAnyway = 'Criar outro na mesma';
  static const String removeType = 'Tirar este tipo';
  static String secondRequest(String type) =>
      'Vai ser criado um segundo pedido de $type.';

  static const String allowPolicy = 'Permitir condições particulares';
  static const String allowPolicyHint =
      'O cliente pode enviar as condições particulares da apólice atual em '
      'vez dos documentos um a um. Vale para todos os tipos escolhidos.';

  static const String messageLabelBase = 'Para o cliente';
  static const String messageLabel = '$messageLabelBase (opcional)';
  static const String messageHelp =
      'Vai no email e na app. Não escreva dados de saúde.';
  static String messageCounter(int n) =>
      '$n / ${NewRequestController.maxMessageLength}';

  static const String willReceive = 'O cliente vai receber';
  static const String willReceiveHint =
      'Tirar ou acrescentar itens muda só este pedido, não a lista do tipo '
      'de seguro.';
  static String requestIndex(int i, int n) => 'Pedido $i de $n';
  static const String awaitingYou = 'À espera da sua confirmação';
  static const String noTypesBox =
      'Escolha pelo menos um tipo de seguro para ver aqui a lista que o '
      'cliente vai receber.';
  static const String noClientNoTypesBox =
      'Escolha o cliente e pelo menos um tipo de seguro para ver aqui a lista '
      'que o cliente vai receber.';
  static const String noTypesYet = 'Ainda sem tipos de seguro';
  static String emptyListNotice(String type) =>
      'A lista de $type está vazia. Acrescente um item ou reponha a lista; '
      'sem itens, este pedido não é criado.';

  static const String newItem = 'Novo item';
  static const String kindLabel = 'É um';
  static const String kindDocument = 'Documento';
  static const String kindData = 'Dado a preencher';
  static const String addItemConfirm = 'Acrescentar';
  static const String cancel = 'Cancelar';

  static String freeItemError(FreeItemError e) => switch (e) {
    FreeItemError.empty => 'Escreva o item a pedir.',
    FreeItemError.tooLong =>
      'Use no máximo ${NewRequestController.maxItemLength} caracteres.',
    FreeItemError.invalidCharacters =>
      'Não use < nem >, nem tabulações ou outros caracteres invisíveis.',
    FreeItemError.tooMany => 'A lista já tem o máximo de itens.',
  };

  static const String summaryRegion = 'Resumo do pedido';
  static String summaryTitle(int n, String? client) {
    if (client == null) return 'Escolha o cliente';
    if (n == 0) return 'Nenhum pedido para $client';
    return '${n == 1 ? '1 pedido' : '$n pedidos'} para $client';
  }

  static String summaryTypes(
    List<String> names,
    bool policy,
    List<String> waiting,
  ) {
    final parts = [
      if (names.isNotEmpty)
        '${names.join(', ')}${policy ? ' · com condições particulares' : ''}',
      for (final w in waiting) '$w à espera de confirmação',
    ];
    return parts.isEmpty ? noTypesYet : parts.join(' · ');
  }

  static String create(int n) => n <= 1
      ? (n == 1 ? 'Criar 1 pedido' : 'Criar pedido')
      : 'Criar $n pedidos';
  static const String creating = 'A criar…';

  static String blockReason(SubmitBlock b, String? emptyType) => switch (b) {
    SubmitBlock.chooseClientAndType =>
      'Escolha o cliente e pelo menos um tipo.',
    SubmitBlock.chooseClient => 'Escolha o cliente.',
    SubmitBlock.chooseType => 'Escolha pelo menos um tipo de seguro.',
    SubmitBlock.awaitingConfirmation =>
      'Confirme o pedido repetido ou tire esse tipo.',
    SubmitBlock.emptyList => 'A lista de ${emptyType ?? 'um tipo'} está vazia.',
    SubmitBlock.messageTooLong => 'Encurte a mensagem para 500 caracteres.',
    SubmitBlock.clientUnavailable =>
      'Este cliente já não partilha dados consigo.',
    SubmitBlock.offline => offlineNewRequest,
  };

  static const String createFailed =
      'Não foi possível criar os pedidos. Nada foi criado. A sua escolha '
      'mantém-se: tente de novo.';
  static const String catalogChanged =
      'A lista de tipos ou de itens mudou. Nada foi criado. Atualizámos a '
      'lista: confirme a sua escolha e crie de novo.';
  static const String createNetwork =
      'Não foi possível ligar. Nada foi criado. A sua escolha mantém-se: '
      'tente de novo.';
  static const String clientLost =
      'Este cliente já não partilha dados consigo.';
  static const String clientLostDetail =
      'Nenhum pedido foi criado. Só pode voltar a pedir se ele aceitar um '
      'novo pedido de partilha.';
  static const String catalogError =
      'Não foi possível carregar os tipos de seguro. Tente de novo.';
  static const String clientsError =
      'Não foi possível carregar os clientes. Tente de novo.';
  static const String preselectError =
      'Não foi possível carregar este cliente. Tente de novo.';

  static const String noActiveTitle = 'Ainda não tem clientes com acesso ativo';
  static const String noActiveBody =
      'Só pode criar pedidos para clientes que aceitaram partilhar os dados '
      'com este escritório. Crie um cliente, ou reenvie o pedido de '
      'partilha a quem ainda não respondeu.';
  static const String createClient = 'Criar cliente';
  static const String seePending = 'Ver clientes pendentes';

  static const String noRequestsForClient =
      'Não é possível criar pedidos para este cliente.';
  static const String reasonPending =
      'Ainda não aceitou. Reenvie o pedido de partilha.';
  static const String reasonDeclined =
      'Recusou a partilha. Não é possível criar pedidos.';
  static const String resendGrant = 'Reenviar pedido de partilha';
  static const String resendGrantDone =
      'Pedido de partilha reenviado. O acesso fica pendente até o cliente '
      'aceitar.';
  static const String resendGrantFailed =
      'Não foi possível reenviar o pedido de partilha. Tente de novo.';

  // ---- Ficha ----------------------------------------------------------------

  static const String requestsOfOffice = 'Pedidos deste escritório';
  static const String colType = 'Tipo';
  static const String colStage = 'Etapa';
  static const String colCreated = 'Criado';
  static const String showMore = 'Mostrar mais 25';
  static const String loadingMore = 'A carregar…';
  static const String loadMoreError =
      'Não foi possível carregar mais pedidos. Tente de novo.';
  static const String fileError =
      'Não foi possível carregar os pedidos. Tente de novo.';
  static const String noRequestsTitle = 'Sem pedidos';
  static const String noRequestsBody =
      'Crie o primeiro pedido para este cliente: escolhe os tipos de seguro '
      'e ele recebe a lista do que precisa.';
  static const String noAccessTitle = 'Sem acesso';
  static const String noAccessBody =
      'Este cliente não existe ou não partilha dados com este escritório. '
      'Se retirou o acesso, os pedidos deixam de aparecer aqui; voltam se '
      'ele aceitar um novo pedido de partilha.';

  static String author(RequestOrigin o, String? name) {
    final who = o == RequestOrigin.mediador ? 'Mediador' : 'Cliente';
    return name == null ? who : '$who · $name';
  }

  static String createdTitle(int n) =>
      n == 1 ? '1 pedido criado' : '$n pedidos criados';
  static String createdSent(List<String> types, String? email) =>
      '${_join(types)}. Email enviado a ${email ?? 'o cliente'}.';
  static String createdNotSentTitle(int n) =>
      '${createdTitle(n)}, mas o email não foi enviado.';
  static const String createdNotSentDetail =
      'Os pedidos já existem e estão nesta ficha. Tente enviar o email de '
      'novo; se o cliente já usa o ProDossier, também os vê na app.';
  static const String resendEmail = 'Reenviar email';
  static const String resendingEmail = 'A enviar…';
  static String resentEmail(String? email) =>
      'Email reenviado a ${email ?? 'o cliente'}.';
  static const String resendNetwork =
      'Não foi possível reenviar. Verifique a ligação e tente de novo.';
  static const String resendGeneric =
      'Não foi possível reenviar o email. Tente de novo.';

  /// "A e B" / "A, B e C".
  static String _join(List<String> items) {
    if (items.length <= 1) return items.join();
    return '${items.sublist(0, items.length - 1).join(', ')} e ${items.last}';
  }

  /// Hora local "10:17" (a cima ao minuto, como na lista de Clientes).
  static String canResendAt(String hhmm) => 'Pode reenviar às $hhmm';

  // ---- Pedido aberto --------------------------------------------------------

  static String forClient(String name) => 'Para $name';
  static String createdBy(String? name) =>
      name == null ? 'Criado' : 'Criado por $name';
  static const String originMediator = 'Origem: mediador';
  static const String originClient = 'Origem: cliente';
  static String messageFrom(String? name) =>
      name == null ? 'Mensagem' : 'Mensagem de $name';
  static const String requestedList = 'Lista pedida';
  static const String stages = 'Etapas';
  static const String readOnly =
      'Só leitura: um pedido não se altera depois de criado.';
  static const String requestError =
      'Não foi possível abrir este pedido. Tente de novo.';
}
