/// Textos do painel do admin (03-design.md, ecrã 6).
abstract final class AdminCopy {
  static const tab = 'Administração';
  static const title = 'Plataforma';
  static const offices = 'Escritórios';
  static const mediators = 'Mediadores';
  static const clients = 'Clientes';
  static const privacyNote =
      'Só contagens. Por privacidade, a administração não vê nomes, '
      'emails nem documentos.';

  static String mediatorCount(int n) => switch (n) {
    0 => 'Sem mediadores',
    1 => '1 mediador',
    _ => '$n mediadores',
  };

  static const createOffice = 'Criar escritório';
  static const inviteMediator = 'Convidar mediador';
  static const emptyTitle = 'Ainda não há escritórios.';
  static const emptyBody =
      'Crie o primeiro escritório para poder convidar mediadores.';

  static const loadError =
      'Não foi possível carregar as contagens. Tente de novo.';
  static const retry = 'Tentar de novo';
  static const offlineReason =
      'Sem ligação. Criar e convidar ficam disponíveis quando a ligação '
      'voltar.';

  // Criar escritório
  static const officeName = 'Nome do escritório';
  static const creating = 'A criar…';
  static const officeCreated =
      'Escritório criado. Convide agora o primeiro mediador.';
  static const officeNameReason = 'Escreva o nome do escritório.';
  static const duplicateOffice = 'Já existe um escritório com este nome.';

  // Convidar mediador
  static const mediatorName = 'Nome do mediador';
  static const email = 'Email';
  static const officeField = 'Escritório';
  static const inviteHelp =
      'O mediador recebe um email para definir a palavra-passe. Cada '
      'mediador pertence a um só escritório.';
  static const sendInvite = 'Enviar convite';
  static const sending = 'A enviar…';
  static const inviteSent = 'Convite enviado.';
  static const mediatorNameHelp =
      'Aparece aos clientes nos pedidos que enviar.';
  static const mediatorNameError = 'Escreva o nome do mediador.';
  static const emailError =
      'Escreva um email completo, por exemplo nome@exemplo.pt.';
  static const cannotInvite =
      'Não foi possível convidar este email. Pode já pertencer a um '
      'escritório.';
  static const inviteSendFailed =
      'Não foi possível enviar o convite. Tente de novo.';

  static const cancel = 'Cancelar';
  static const networkError =
      'Não foi possível ligar. Verifique a ligação e tente de novo.';
  static const genericError = 'Não foi possível concluir. Tente de novo.';
}
