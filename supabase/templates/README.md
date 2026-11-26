# Templates de email do Supabase Auth

Estilo do `docs/design/DESIGN.md` ("Fora da app"): papel e tinta, serifa Georgia nos títulos e no wordmark (as fontes da app não existem em clientes de email), botão cheio a tinta, colofão no fim. HTML com tabelas e estilos inline, sem JS nem imagens, contraste AA, legível sem imagens. O Supabase só envia HTML: os `.txt` são a versão de texto de referência (para um SMTP próprio futuro) e guardam a mesma copy.

## Ficheiros e campos do painel (Authentication > Emails)

| Ficheiro | Campo (separador Templates) | Assunto (Subject) | Quando é enviado |
| --- | --- | --- | --- |
| `invite-mediator.html` | Invite user | Convite para o ProDossier | `invite-mediator` (admin convida mediador) |
| `magic-link.html` | Magic link | O seu link de acesso ao ProDossier | Convite do cliente (`create-client`, `resend-request`) e link de entrada pedido pelo próprio cliente |
| `recovery.html` | Reset password | Definir uma nova palavra-passe no ProDossier | "Esqueci-me da palavra-passe" (todos os perfis; é também como um cliente sem palavra-passe a cria) |

O convite de cliente e o link de entrada usam o mesmo campo do Supabase (Magic link), por isso estão num só ficheiro com `{{ if .Data.office_name }}`: com escritório mostra o convite (escritório e mediador em destaque); sem escritório mostra o link de entrada simples. Os outros templates (Confirm signup, Change email, Reauthentication e notificações) não são usados na fase 1.

## Variáveis (Go template)

- `{{ .ConfirmationURL }}`: o link (botão e endereço em texto).
- `{{ .Data.office_name }}` e `{{ .Data.mediator_name }}`: metadados do utilizador, escritos por `supabase/functions/_shared/requests.ts` antes de pedir o link. Vazios quando não há pedido pendente.
- `{{ if }}`, `{{ else }}`, `{{ end }}`.

Não há variável de data de envio no Supabase, por isso o colofão do email não leva "Enviado a {data}" (diferença em relação ao DESIGN.md).

## Procedimento para colar

1. Painel Supabase > Authentication > Emails.
2. Para cada linha da tabela: abrir o separador do template, pôr o Subject da tabela, apagar o corpo e colar o conteúdo do `.html` (modo Source). Guardar.
3. Enviar um convite de teste a um email próprio e ver no telemóvel e no desktop; com e sem o escritório.
4. Em URL Configuration, confirmar que `AUTH_REDIRECT_URL` está nos Redirect URLs (ver `supabase/functions/README.md`).

Alternativa por API de gestão: `PATCH /v1/projects/aboducqavmsmlzslrseu/config/auth` com `mailer_subjects_invite|magic_link|recovery` e `mailer_templates_invite_content|magic_link_content|recovery_content`.

## Estado (2026-11-26)

Não aplicados. A API de gestão recusa (`entitlement_required`): personalizar templates não está disponível no plano gratuito com o email por defeito do Supabase. É preciso configurar um SMTP próprio (decisão já prevista antes de uso real) ou mudar de plano; só depois se colam os templates.
