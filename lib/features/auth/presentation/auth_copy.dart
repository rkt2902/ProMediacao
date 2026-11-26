/// Textos do fluxo de autenticação (03-design.md, ecrãs 1, 1b e 2).
abstract final class AuthCopy {
  static const tabClient = 'Sou cliente';
  static const tabOffice = 'Trabalho num escritório';
  static const title = 'Entrar';

  static const clientHelp =
      'Indique o seu email. Enviamos-lhe um link para entrar, sem '
      'palavra-passe.';
  static const clientSend = 'Enviar link de acesso';
  static const sending = 'A enviar…';
  static const sentBefore =
      'Se este email tiver acesso ao ProDossier, o link '
      'chega a ';
  static const sentAfter =
      ' dentro de alguns minutos. Abra-o neste '
      'dispositivo. Veja também a pasta de spam.';
  static const sendAgain = 'Enviar outra vez';
  static const otherEmail = 'Usar outro email';
  static const sendNew = 'Enviar link novo';

  static String waitToResend(int seconds) => seconds >= 60
      ? 'Pode enviar outra vez daqui a 1 minuto.'
      : 'Pode enviar outra vez daqui a $seconds '
            '${seconds == 1 ? 'segundo' : 'segundos'}.';

  static const officeHelp = 'Para mediadores e administração.';
  static const email = 'Email';
  static const password = 'Palavra-passe';
  static const show = 'Mostrar';
  static const hide = 'Ocultar';
  static const signIn = 'Entrar';
  static const signingIn = 'A entrar…';
  static const forgot = 'Esqueci-me da palavra-passe';
  static const badCredentials = 'Email ou palavra-passe incorretos.';
  static const emailEmpty = 'Escreva o seu email.';
  static const emailInvalid =
      'Escreva um email completo, por exemplo nome@exemplo.pt.';
  static const passwordEmpty = 'Escreva a palavra-passe.';
  static const sessionEndedOffice =
      'A sua sessão terminou. Entre de novo para continuar.';
  static const sessionEndedClient =
      'A sua sessão terminou. Entre de novo com o seu email: enviamos-lhe um '
      'link.';

  static const networkError =
      'Não foi possível ligar. Verifique a ligação e tente de novo.';
  static const sendFailed = 'Não foi possível enviar. Tente de novo.';
  static const genericError = 'Não foi possível concluir. Tente de novo.';
  static const offlineEntry =
      'Sem ligação à internet. Precisa de ligação para entrar.';
  static const offlineLink =
      'Sem ligação à internet. Precisa de ligação para '
      'abrir o link.';
  static const offlineReason = 'Precisa de ligação à internet.';

  // Recuperar
  static const recoverTitle = 'Recuperar palavra-passe';
  static const recoverHelp =
      'Indique o email da sua conta. Se existir, enviamos um link para '
      'definir uma nova palavra-passe.';
  static const recoverSend = 'Enviar link';
  static const recoverSent =
      'Se houver uma conta com este email, o link chega dentro de alguns '
      'minutos. Veja também a pasta de spam.';
  static const backToSignIn = 'Voltar a entrar';

  // Definir palavra-passe
  static const setTitle = 'Definir palavra-passe';
  static const newPassword = 'Nova palavra-passe';
  static const ruleLength = 'Pelo menos 10 caracteres';
  static const saveAndEnter = 'Guardar e entrar';
  static const saving = 'A guardar…';

  // Link expirado
  static const linkInvalidTitle = 'Este link já não é válido';
  static const linkInvalidClient =
      'Os links de acesso expiram ao fim de algum tempo, por segurança. '
      'Peça um novo aqui: basta o seu email.';
  static const linkInvalidMediator =
      'Também pode pedir ao seu mediador que reenvie o pedido.';
  static const linkInvalidPassword =
      'Por segurança, os links expiram. Peça um novo em Recuperar '
      'palavra-passe ou ao administrador, se foi convidado.';
  static const tabMyData = 'Os meus dados';

  static const retry = 'Tentar de novo';
  static const signOut = 'Sair';
}
