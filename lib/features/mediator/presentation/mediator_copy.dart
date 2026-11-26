/// Textos do ecrã Clientes (03-design.md, ecrã 5). Tratamento formal.
abstract final class MediatorCopy {
  static const String title = 'Clientes';
  static const String createClient = 'Criar cliente';
  static const String fallbackOffice = 'escritório';

  static const String colClient = 'Cliente';
  static const String colState = 'Estado';
  static const String colDate = 'Data';
  static const String colAction = 'Ação';

  static const String resend = 'Reenviar pedido';
  static const String resending = 'A enviar…';
  static const String needsConnection = 'Precisa de ligação.';
  static const String needsConnectionToCreate =
      'Precisa de ligação para criar.';

  static const String showMore = 'Mostrar mais 25';
  static const String loadingMore = 'A carregar…';

  static const String loadError =
      'Não foi possível carregar os clientes. Tente de novo.';
  static const String loadMoreError =
      'Não foi possível carregar mais clientes. Tente de novo.';
  static const String retry = 'Tentar de novo';
  static const String offline =
      'Sem ligação à internet. Pode ver o que está no ecrã; as alterações '
      'ficam bloqueadas até a ligação voltar.';

  static const String emptyTitle = 'Ainda não tem clientes';
  static const String emptyBody =
      'Crie o primeiro cliente. Ele recebe um pedido para aceitar a '
      'partilha dos dados com {office}.';

  // Folha "Criar cliente"
  static const String sheetTitle = 'Criar cliente';
  static const String sheetIntro =
      'O cliente recebe o pedido com o nome da {office} e o seu: por email '
      'ou, se já usar o ProDossier, dentro da app. Só vê os dados dele '
      'depois de ele aceitar.';
  static const String fieldName = 'Nome completo';
  static const String fieldEmail = 'Email';
  static const String sheetNote =
      'Até o cliente aceitar, vê apenas o nome, o email e o estado do pedido.';
  static const String submit = 'Criar e enviar pedido';
  static const String submitting = 'A criar…';
  static const String cancel = 'Cancelar';

  static const String nameEmpty = 'Escreva o nome do cliente.';
  static const String emailEmpty = 'Escreva o email do cliente.';
  static const String emailInvalid =
      'Escreva um email completo, por exemplo nome@exemplo.pt.';
  static const String formNetwork =
      'Não foi possível ligar. Verifique a ligação e tente de novo.';
  static const String formGeneric =
      'Não foi possível criar o cliente. Nada foi enviado. Tente de novo.';
  static const String formInvalid =
      'Não foi possível aceitar estes dados. Verifique o nome e o email.';
  static const String formForbidden =
      'Não foi possível criar o cliente com esta conta.';

  static String alreadyClient(String office) =>
      'Este email já é cliente da $office.';
  static String declined(String office) =>
      'Este cliente recusou o pedido da $office. Não é possível enviar outro.';

  static String created(String email) =>
      'Pedido enviado a $email. O acesso fica pendente até o cliente aceitar.';
  static const String createdNotSent =
      'O cliente foi criado, mas o pedido não seguiu. Tente Reenviar pedido '
      'daqui a pouco.';

  static const String resent = 'Pedido reenviado a {email}.';
  static const String resendNotPending =
      'Este pedido já não está pendente. A lista foi atualizada.';
  static const String resendSendFailed =
      'O pedido não seguiu. Tente Reenviar pedido daqui a pouco.';
  static const String resendNetwork =
      'Não foi possível reenviar. Verifique a ligação e tente de novo.';
  static const String resendGeneric =
      'Não foi possível reenviar o pedido. Tente de novo.';

  static String canResendAt(DateTime at) => 'Pode reenviar às ${hhmm(at)}';

  /// Hora local a cima ao minuto: nunca promete antes do que é verdade.
  static String hhmm(DateTime at) {
    var l = at.toLocal();
    if (l.second > 0 || l.millisecond > 0 || l.microsecond > 0) {
      l = DateTime(l.year, l.month, l.day, l.hour, l.minute + 1);
    }
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}';
  }

  /// "12 clientes · 3 pendentes · 1 recusado" (partes a zero omitem-se).
  /// Com mais por carregar, a contagem é só do que está no ecrã.
  static String summary({
    required int total,
    required int pending,
    required int declined,
    bool partial = false,
  }) {
    String plural(int n, String one, String many) =>
        n == 1 ? '$n $one' : '$n $many';
    final parts = [
      '${partial ? 'A mostrar ' : ''}${plural(total, 'cliente', 'clientes')}',
      if (pending > 0) plural(pending, 'pendente', 'pendentes'),
      if (declined > 0) plural(declined, 'recusado', 'recusados'),
    ];
    return parts.join(' · ');
  }

  static const List<String> _monthsLong = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// Para leitura de ecrã: "12 de novembro de 2026".
  static String spokenDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day} de ${_monthsLong[l.month - 1]} de ${l.year}';
  }
}
