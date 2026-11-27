import '../../../core/format/dates.dart';

/// Copy dos ecrãs do cliente (03-design.md, ecrãs 3 e 4). Tratamento formal.
abstract final class ConsentCopy {
  // Separadores e navegação
  static const tabRequest = 'Pedido de acesso';
  static const tabMyData = 'Os meus dados';
  static const backToHome = 'Com quem partilho';

  // Consentimento (ecrã 3)
  static const requestsAccess = 'pede acesso aos seus dados';
  static String sentBy(String name) => 'Enviado por $name';
  static const summarySees =
      'Vê os dados e documentos que guardar aqui, incluindo dados de saúde, '
      'se os enviar.';
  static const summaryOthers =
      'Não sabe com que outros escritórios partilha, e eles não sabem deste.';
  static const summaryWithdraw =
      'Pode retirar o acesso quando quiser, em Com quem partilho.';
  static const fullText = 'Texto completo';
  static String version(String v) => 'Versão do texto: $v';
  static const recorded = 'A sua resposta fica registada com data e hora.';
  static const decline = 'Recusar';
  static const accept = 'Aceitar';
  static const registering = 'A registar…';
  static const offlineRespond = 'Precisa de ligação para responder.';
  static const respondFailed =
      'Não foi possível registar a sua resposta. Nada foi alterado. '
      'Tente de novo.';

  /// Sem ligação não se sabe se o pedido chegou: não se afirma que nada
  /// mudou. Ao tentar de novo, o servidor diz o estado real.
  static const respondUnconfirmed =
      'Não foi possível confirmar a sua resposta por falta de ligação. '
      'Tente de novo quando a ligação voltar.';
  static const textFailed =
      'Não foi possível carregar o texto. Sem o ler não pode responder.';
  static const retry = 'Tentar de novo';
  static const seeHome = 'Ver com quem partilho';
  static String activeSince(DateTime d) =>
      'Partilha ativa desde ${AppDates.dateTime(d)}';
  static String declinedOn(DateTime d) => 'Recusado a ${AppDates.dateTime(d)}';
  static String acceptedResult(String office) =>
      'O escritório $office já pode ver os seus dados. Pode retirar o acesso '
      'quando quiser, em Com quem partilho.';
  static String declinedResult(String office) =>
      'O escritório $office não tem acesso aos seus dados nem documentos. Se mudar de '
      'ideias, peça ao escritório um novo pedido.';
  static String alreadyAnswered(DateTime d) =>
      'Já respondeu a este pedido a ${AppDates.dateTime(d)}.';
  static const requestUnavailable =
      'Este pedido já não está disponível. Os seus pedidos estão aqui.';

  // Com quem partilho (ecrã 4)
  static const homeTitle = 'Com quem partilho';
  static const pendingTitle = 'À espera da sua resposta';
  static String pendingHelp(int n) => n == 1
      ? 'Este escritório pede acesso aos seus dados. Nada é partilhado até '
            'responder.'
      : 'Estes escritórios pedem acesso aos seus dados. Nada é partilhado '
            'até responder.';
  static String pendingAnnounce(int n) => n == 1
      ? 'Tem 1 pedido de acesso à espera da sua resposta.'
      : 'Tem $n pedidos de acesso à espera da sua resposta.';
  static const respond = 'Responder';
  static String summary(int n) => switch (n) {
    0 => 'Neste momento não partilha os seus dados com nenhum escritório.',
    1 => 'Partilha os seus dados com 1 escritório.',
    _ => 'Partilha os seus dados com $n escritórios.',
  };
  static const withAccess = 'Com acesso';
  static const withoutAccess = 'Sem acesso';
  static String requestedOn(DateTime d) => 'Pedido a ${AppDates.dateTime(d)}';
  static String since(DateTime d) => 'Desde ${AppDates.dateTime(d)}';
  static String withdrawnOn(DateTime d) => 'Retirado a ${AppDates.dateTime(d)}';
  static const withdraw = 'Retirar acesso';
  static const withdrawing = 'A retirar…';
  static const readAccepted = 'Ler o texto aceite';
  static const offlineShort = 'Precisa de ligação.';
  static const footer =
      'Retirar é imediato e não precisa de justificação. Cada resposta fica '
      'registada com data, hora e a versão do texto que aceitou.';
  static const emptyTitle = 'Ainda não partilha dados com nenhum escritório.';
  static const emptyHelp =
      'Quando um escritório lhe pedir acesso, o pedido aparece aqui.';
  static const loadFailed = 'Não foi possível carregar a lista. Tente de novo.';

  // Retirar acesso
  static String withdrawTitle(String office) => 'Retirar o acesso a $office?';
  static const withdrawMessage =
      'A partir de agora, ninguém deste escritório vê os seus dados e '
      'documentos no ProDossier, incluindo o que o mediador escreveu no seu '
      'perfil. Para voltar a partilhar, o escritório terá de lhe enviar um '
      'novo pedido.';
  static const cancel = 'Cancelar';
  static const withdrawFailed =
      'Não foi possível retirar o acesso. O escritório continua com acesso. '
      'Tente de novo.';
  static const withdrawUnconfirmed =
      'Não foi possível confirmar a retirada por falta de ligação. Tente de '
      'novo quando a ligação voltar.';
  static String withdrawn(String office) =>
      'Acesso retirado. O escritório $office já não vê os seus dados.';

  // Texto aceite (só leitura)
  static const acceptedTextTitle = 'Texto que aceitou';
  static String acceptedOn(String office, DateTime d) =>
      'Aceite para o escritório $office a ${AppDates.dateTime(d)}.';
  static const close = 'Fechar';
  static const acceptedTextFailed =
      'Não foi possível carregar o texto. Tente de novo.';
}
