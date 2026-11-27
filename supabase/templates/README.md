# Templates de email do Supabase Auth

Estilo do `docs/design/DESIGN.md` ("Fora da app"): papel e tinta, serifa nos títulos e no wordmark (Source Serif 4 com alternativa Georgia; o corpo usa Atkinson com alternativas Segoe UI, Helvetica, Arial), botão cheio a tinta, colofão no fim. HTML com tabelas e estilos inline, sem JS nem imagens, contraste AA (tinta 15.1, tintaMedia 8.0, tintaTenue 5.2), legível sem imagens. O Supabase só envia HTML: os `.txt` são a versão de texto de referência (para um SMTP próprio futuro) com a mesma copy.

## Ficheiros e campos do painel (Authentication > Emails)

| Email | HTML (corpo) | Texto | Campo do painel | Subject |
| --- | --- | --- | --- | --- |
| Convite de mediador | `invite-mediator.html` | `invite-mediator.txt` | Invite user | `Convite para o ProDossier` |
| Convite de cliente | `magic-link.html` (ramo com escritório) | `client-invite.txt` | Magic link | ver abaixo |
| Link de entrada (cliente) | `magic-link.html` (ramo sem escritório) | `magic-link.txt` | Magic link | ver abaixo |
| Recuperação de palavra-passe | `recovery.html` | `recovery.txt` | Reset password | `Definir uma nova palavra-passe no ProDossier` |

Subject do Magic link (uma linha, tal como está):
`{{ if .Data.office_name }}{{ .Data.office_name }} pede acesso aos seus dados{{ else }}O seu link de acesso ao ProDossier{{ end }}`

O convite de cliente e o link de entrada saem os dois por `signInWithOtp` (`supabase/functions/_shared/requests.ts`), por isso partilham o campo Magic link: com `office_name` mostra o convite (escritório e quem enviou em destaque); vazio mostra o link de entrada. Os outros templates (Confirm signup, Change email, Reauthentication, notificações) não são usados na fase 1.

## Variáveis (Go template)

- `{{ .ConfirmationURL }}`: o link (botão e endereço em texto).
- `{{ .Email }}`: destinatário, no colofão ("Enviado para ..."). O Supabase não tem variável de data de envio, por isso o "Enviado a {data, hora}" do DESIGN.md fica de fora.
- `{{ .Data.office_name }}`, `{{ .Data.mediator_name }}`: metadados do utilizador escritos por `_shared/requests.ts` antes de pedir o link; vazios quando não há pedido pendente.
- `{{ if }}`, `{{ else }}`, `{{ end }}`. Verificado com `html/template` do Go: os três HTML compilam e os nomes são escapados.

## Procedimento para colar

0. Pré-requisito: SMTP próprio configurado (Authentication > Emails > SMTP Settings) ou plano pago. Sem isso o Supabase recusa (ver Estado).
1. Authentication > Emails > Templates.
2. Para cada linha da tabela: abrir o template, pôr o Subject, apagar o corpo, colar o `.html` inteiro (Source). Guardar.
3. Teste: criar um cliente de teste (convite), pedir um link no ecrã Entrar sem pedido pendente (link de entrada), convidar um mediador de teste, e "Esqueci-me da palavra-passe". Ver cada um no telemóvel e no desktop, com imagens desligadas.
4. URL Configuration: `AUTH_REDIRECT_URL` nos Redirect URLs (ver `supabase/functions/README.md`).

Alternativa por API: `PATCH https://api.supabase.com/v1/projects/aboducqavmsmlzslrseu/config/auth` só com `mailer_subjects_invite`, `mailer_subjects_magic_link`, `mailer_subjects_recovery`, `mailer_templates_invite_content`, `mailer_templates_magic_link_content`, `mailer_templates_recovery_content` (os nomes são válidos: a API não os rejeita).

## Estado (2026-11-26)

Não aplicados. PATCH (templates e, à parte, só assuntos) devolve 400 `entitlement_required` (`auth.email_templates`): "Email template modification is not available for free tier projects using the default email provider". GET confirma que os campos continuam nos valores por defeito. Falta SMTP próprio (`smtp_host` vazio) ou mudar de plano; depois cola-se pelo painel ou repete-se o PATCH.
