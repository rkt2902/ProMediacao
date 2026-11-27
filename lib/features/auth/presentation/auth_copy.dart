import '../application/password_rules.dart';

/// Textos do fluxo de autenticação (03-design.md, ecrãs 1, 1b, 1c, 1d e 2).
abstract final class AuthCopy {
  static const tabAccess = 'Acesso';
  static const tabMyData = 'Os meus dados';
  static const title = 'Entrar';

  // Entrar
  static const email = 'Email';
  static const password = 'Palavra-passe';
  static const show = 'Mostrar';
  static const hide = 'Ocultar';
  static const signIn = 'Entrar';
  static const signingIn = 'A entrar…';
  static const forgot = 'Esqueci-me da palavra-passe';
  static const badCredentials = 'Email ou palavra-passe incorretos.';
  static const badCredentialsHint =
      'Se ainda não criou palavra-passe, use Receber link de acesso por email.';
  static const emailEmpty = 'Escreva o seu email.';
  static const emailInvalid =
      'Escreva um email completo, por exemplo nome@exemplo.pt.';
  static const passwordEmpty = 'Escreva a palavra-passe.';
  static const sessionEnded =
      'A sua sessão terminou. Entre de novo para continuar.';

  // Alternativa por link (só clientes)
  static const linkQuestion = 'Prefere entrar sem palavra-passe?';
  static const linkHelp =
      'Enviamos um link para o email acima. Só para clientes.';
  static const linkButton = 'Receber link de acesso por email';
  static const sending = 'A enviar…';
  static const sentBefore =
      'Se este email tiver acesso ao ProDossier, o link '
      'chega a ';
  static const sentAfter =
      ' dentro de alguns minutos. Abra-o neste '
      'dispositivo. Veja também a pasta de spam.';
  static const sendAgain = 'Enviar outra vez';
  static const otherEmail = 'Usar outro email';
  static const backToPassword = 'Entrar com palavra-passe';

  static String waitToResend(int seconds) => seconds >= 60
      ? 'Pode enviar outra vez daqui a 1 minuto.'
      : 'Pode enviar outra vez daqui a $seconds '
            '${seconds == 1 ? 'segundo' : 'segundos'}.';

  // Erros e offline
  static const networkError =
      'Não foi possível ligar. Verifique a ligação e tente de novo.';
  static const sendFailed = 'Não foi possível enviar. Tente de novo.';
  static const genericError = 'Não foi possível concluir. Tente de novo.';
  static const offlineEntry =
      'Sem ligação à internet. Precisa de ligação para entrar.';
  static const offlineLink =
      'Sem ligação à internet. Precisa de ligação para abrir o link.';
  static const offlineGeneral =
      'Sem ligação à internet. Pode ver o que está no ecrã; as alterações '
      'ficam bloqueadas até a ligação voltar.';
  static const offlineReason = 'Sem ligação. Tente quando voltar a ligação.';
  static const offlineSaveReason = 'Precisa de ligação para guardar.';

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

  // Definir palavra-passe (recuperação, convite de mediador)
  static const setTitle = 'Definir palavra-passe';
  static const invitedBefore = 'Foi convidado para a ';
  static String invitedTo(String office) => '$invitedBefore$office.';
  static const newPassword = 'Nova palavra-passe';
  static const saveAndEnter = 'Guardar e entrar';
  static const saving = 'A guardar…';

  // Criar / alterar palavra-passe (cliente)
  static const createTitle = 'Criar palavra-passe';
  static const changeTitle = 'Alterar palavra-passe';
  static const createHelp =
      'Da próxima vez pode entrar com o seu email e esta palavra-passe, sem '
      'esperar pelo email. O link de acesso continua a funcionar.';
  static const changeHelp =
      'A palavra-passe antiga deixa de funcionar. O link de acesso continua a '
      'funcionar.';
  static const savePassword = 'Guardar palavra-passe';
  static const notNow = 'Agora não';
  static const cancel = 'Cancelar';
  static const createFooter =
      'Pode criar mais tarde, em Com quem partilho, na secção A sua conta.';
  static const saveFailed =
      'Não foi possível guardar a palavra-passe. Nada foi alterado. Tente de '
      'novo.';
  static const weakServer =
      'A palavra-passe não foi aceite por não ser segura. Escolha outra.';
  static const created =
      'Palavra-passe criada. Da próxima vez pode entrar com o seu email e '
      'esta palavra-passe.';
  static const changed = 'Palavra-passe alterada.';

  // Regras (1d)
  static const rulesHeader = 'A palavra-passe precisa de ter:';

  static String rule(PasswordRule r) => switch (r) {
    PasswordRule.length => 'Pelo menos 10 caracteres',
    PasswordRule.upper => 'Uma letra maiúscula',
    PasswordRule.lower => 'Uma letra minúscula',
    PasswordRule.digit => 'Um número',
    PasswordRule.special => 'Um carácter especial, como ! ? # @',
  };

  static String weak(int missing) =>
      'A palavra-passe ainda não é segura. Falta cumprir $missing '
      '${missing == 1 ? 'regra' : 'regras'}.';

  static String rulesSummary(int met) => '$met de 5 regras cumpridas';
  static const ruleMet = 'Cumprida';
  static const ruleUnmet = 'Por cumprir';
  static const ruleMissing = 'Em falta';

  // A sua conta
  static const accountTitle = 'A sua conta';
  static const noPassword =
      'Ainda não criou. Entra com um link enviado para o seu email.';
  static const passwordCreated = 'Criada.';
  static const createdBefore = 'Criada a ';
  static String passwordCreatedAt(String date) => '$createdBefore$date.';

  // Link expirado
  static const linkInvalidTitle = 'Este link já não é válido';
  static const linkInvalidClient =
      'Os links de acesso expiram ao fim de algum tempo, por segurança. '
      'Peça um novo aqui: basta o seu email.';
  static const sendNew = 'Enviar link novo';
  static const hasPassword = 'Já tem palavra-passe? Entrar com ela';
  static const linkInvalidMediator =
      'Também pode pedir ao seu mediador que reenvie o pedido.';
  static const linkInvalidPassword =
      'Por segurança, os links expiram. Peça um novo em Recuperar '
      'palavra-passe ou ao administrador, se foi convidado.';

  static const retry = 'Tentar de novo';
  static const signOut = 'Sair';
}
