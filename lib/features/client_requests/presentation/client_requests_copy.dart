import '../../../core/format/dates.dart';
import '../../requests/domain/request_models.dart';

/// Copy dos ecrãs do cliente "Os meus pedidos" e "Pedido" (03-design.md,
/// ecrãs 4 e 5). Tratamento formal.
abstract final class ClientRequestsCopy {
  static const title = 'Os meus pedidos';
  static const retry = 'Tentar de novo';

  /// Aviso interino (sai com a 003). Sem promessa de data.
  static const interimNotice =
      'Para já, aqui só pode ver o que lhe pedem. Combine o envio com o '
      'escritório.';

  static String openSummary(int n) => switch (n) {
    0 => 'Não tem pedidos em curso.',
    1 => 'Tem 1 pedido em curso.',
    _ => 'Tem $n pedidos em curso.',
  };

  static const groupOpen = 'Em curso';
  static const groupWithdrawn = 'Com o acesso retirado';
  static const withdrawnHelp =
      'Estes escritórios já não veem os pedidos nem os seus dados. Se voltar '
      'a dar acesso, os pedidos continuam onde estavam.';

  static String fromOffice(String office) => 'Do escritório $office';
  static const viewRequest = 'Ver o pedido';
  static String createdOn(DateTime d) => 'Criado a ${AppDates.dateTime(d)}';

  static String stageName(RequestStage s) => switch (s) {
    RequestStage.created => 'Pedido criado',
    RequestStage.documentsSent => 'Documentos enviados',
    RequestStage.inReview => 'Em análise pelo mediador',
    RequestStage.sentToInsurers => 'Enviado às seguradoras',
  };

  static const stageNames = [
    'Pedido criado',
    'Documentos enviados',
    'Em análise pelo mediador',
    'Enviado às seguradoras',
  ];

  /// "Etapa 1 de 4: Pedido criado".
  static String stageLine(RequestStage s) =>
      'Etapa ${s.number} de 4: ${stageName(s)}';

  static String _documents(int n) => n == 1 ? '1 documento' : '$n documentos';
  static String _data(int n) => '$n dado${n == 1 ? '' : 's'}';

  /// "4 documentos e 2 dados pedidos".
  static String requested(int documents, int data) =>
      '${_documents(documents)} e ${_data(data)} pedidos';

  /// "4 documentos · 2 dados".
  static String counts(int documents, int data) =>
      '${_documents(documents)} · ${_data(data)}';

  static const emptyTitle = 'Ainda não tem pedidos.';
  static const emptyHelp =
      'Quando um escritório lhe pedir documentos para um seguro, o pedido '
      'aparece aqui e recebe também um email.';
  static const loadFailed =
      'Não foi possível carregar os seus pedidos. Tente de novo.';
  static const showMore = 'Mostrar mais';
  static const loadingMore = 'A carregar…';
  static const moreFailed =
      'Não foi possível mostrar mais pedidos. Tente de novo.';

  // Com quem partilho (passagem)
  static const sharingTitle = 'Com quem partilho';
  static const viewSharing = 'Ver com quem partilho';

  // Pedido (ecrã 5)
  static const backToRequests = 'Os meus pedidos';
  static String fromOfficeTitle(String office) =>
      'Pedido do escritório $office';
  static String sentBy(String author) => 'Enviado por $author, mediadora';
  static String messageFrom(String? author) =>
      author == null ? 'Mensagem do escritório' : 'Mensagem de $author';
  static const whatIsAsked = 'O que lhe pedem';
  static const policyNote =
      'Pode enviar as condições particulares da apólice atual em vez dos '
      'documentos um a um.';
  static const stages = 'Etapas';
  static const stagePending = 'Por fazer';
  static const footer =
      'Os documentos que enviar ficam no seu dossiê; só os vê quem tem acesso '
      'aos seus dados.';
  static String withdrawnOn(DateTime d) => 'Retirado a ${AppDates.dateTime(d)}';
  static String withdrawnExplain(String office) =>
      'O escritório $office já não vê este pedido nem os seus dados. Se '
      'voltar a dar acesso, o pedido continua onde estava.';
  static const detailFailed = 'Não foi possível abrir este pedido.';
  static const notFoundTitle = 'Pedido não encontrado';
  static const notFoundHelp =
      'Este pedido não existe ou não é seu. Veja os seus pedidos na página '
      'inicial.';
  static const seeMyRequests = 'Ver os meus pedidos';
}
