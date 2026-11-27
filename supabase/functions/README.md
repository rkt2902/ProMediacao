# Funções de servidor (edge functions)

Publicadas no projeto `aboducqavmsmlzslrseu` com verificação de JWT. `resend-request` foi republicada a 2026-11-26 (bug 5 do qa: campo `delivered`); sem JWT responde `401`.

| Função | Quem chama | O que faz |
| --- | --- | --- |
| `invite-mediator` | admin | `{ email, office_id, full_name? }`: cria o utilizador mediador, perfil, pertença ao escritório e envia o convite |
| `create-client` | mediador | `{ full_name, email }`: cria o cliente (se não existir) e a concessão pendente do escritório do mediador e envia o pedido |
| `resend-request` | mediador ou cliente | `{ grant_id }` (mediador, "Reenviar pedido") ou `{ email }` (cliente, link novo no ecrã de entrada) |
| `send-request-email` (002, por publicar) | mediador | `{ batch_id }`: email curto ao cliente titular com os pedidos de uma criação; serve também o "Reenviar email" |

## `send-request-email` (feature 002): contrato para a app

Chamar depois de `create_requests` responder, com o `batch_id` devolvido (igual nos N pedidos): `functions.invoke('send-request-email', body: { 'batch_id': ... })` com a sessão do mediador. O mesmo pedido serve para "Reenviar email". A função só lê: **nunca desfaz nem altera os pedidos**.

Sucesso (200):
```json
{ "ok": true, "delivered": "email", "recipient_email": "maria@exemplo.pt",
  "sent_at": "2026-11-27T10:14:00.000Z", "next_allowed_at": "2026-11-27T10:15:00.000Z" }
```
`next_allowed_at` dá o "Pode reenviar às 10:17" (hora absoluta, 60 s).

Erros: `{ "error": { "code": "...", ... } }`. Para a app, todos os que não são 401/403/400 dão o mesmo aviso da US 4.4: "N pedidos criados, mas o email não foi enviado." + "Reenviar email".

| HTTP | `code` | Quando | O que a app faz |
| --- | --- | --- | --- |
| 401 | `unauthenticated` | sem sessão | como nas outras funções |
| 403 | `forbidden` | não é mediador com escritório | erro genérico |
| 400 | `invalid_input` | `batch_id` em falta ou não é UUID | erro genérico |
| 404 | `not_found` | batch não existe ou é de outro escritório (não distingue) | aviso de email não enviado |
| 409 | `client_not_available` | o batch é deste escritório mas a concessão já não está ativa | "Este cliente já não partilha dados consigo." (sem reenviar) |
| 429 | `too_soon` + `retry_after_seconds` | outro envio para este destinatário há menos de 60 s (inclui convites da 001) | "Pode reenviar às {hora}" |
| 502 | `send_failed` + `retry_after_seconds: 60` | o fornecedor recusou ou não respondeu | aviso + reenviar depois de 60 s |
| 503 | `email_unavailable` | fornecedor de email ou `APP_URL` por configurar (estado atual); nada enviado, limite não gasto | aviso de email não enviado |
| 500 | `server_error` | outro erro | aviso de email não enviado |

O que o email leva (US 4.1, copy do `03-design.md` secção 7): escritório, mediador que criou, tipos (pela ordem do catálogo), mensagem do mediador (HTML escapado, quebras de linha mantidas) e o botão "Ver os pedidos" para `{APP_URL}/pedidos`. Nunca a lista de documentos ou dados, as notas do tipo nem dados de saúde. O link é o endereço da app, não um link de entrada: sem sessão a app pede para entrar (regra da 001). A rota `/pedidos` é criada pela tarefa 3.

Código: `send-request-email/index.ts`, `_shared/request_email.ts` (copy e HTML, módulo puro), `_shared/mailer.ts` (API do fornecedor). Pré-visualizações geradas a partir de `request_email.ts` com os valores do render: `supabase/templates/request-created.html`, `request-created-sem-mensagem.html` e `request-created.txt`. Não são lidas em runtime: se a copy mudar, muda-se em `request_email.ts` e regeneram-se.

### O que sai hoje, sem fornecedor de email

**Nada.** O email por defeito do Supabase só envia emails de autenticação (link mágico, convite, recuperação), com template fixo no plano gratuito (o PATCH dos templates deu `entitlement_required` a 26/11) e poucos envios por hora. Não envia um email "pedido criado". Usar um link mágico como substituto está fora de questão: seria um link de entrada disparado pelo mediador para quem já usa a app, o que a regra da 001 proíbe. Por isso, hoje, a função responde `503 email_unavailable` e a app mostra "Pedido criado, mas o email não foi enviado". O cliente vê o pedido na app e recebe a notificação no sino: quem tem concessão ativa já entrou, para aceitar.

**Quando houver fornecedor** (por exemplo Brevo, ou Resend): basta definir os segredos abaixo e o email sai com este template, de imediato e sem nova publicação. Configurar "SMTP próprio" em Authentication > Emails **não chega** para este email: isso só muda os emails de autenticação. A função precisa da **chave da API HTTP** do fornecedor (o Brevo dá a chave SMTP e a chave da API: é esta a que conta). O mesmo `NOTICE_EMAIL_*` liga também o aviso sem link da 001.

### O que o lead publica (depois de aplicar a migração 002, no gate 3)

1. Segredos (valores fora do repositório):
   ```
   supabase secrets set --project-ref aboducqavmsmlzslrseu APP_URL=<origem da app, ex.: https://promediacao.pages.dev>
   ```
   `APP_URL` é opcional: sem ele usa a origem de `AUTH_REDIRECT_URL` (hoje `http://localhost:8080`, por isso o link do email aponta para localhost até a app estar publicada).
   Fornecedor (quando existir): `NOTICE_EMAIL_API_KEY`, `NOTICE_EMAIL_FROM` (ex.: `ProDossier <no-reply@dominio.pt>`, com o domínio verificado no fornecedor) e, para o Brevo, `NOTICE_EMAIL_API_URL=https://api.brevo.com/v3/smtp/email` (por defeito usa Resend).
2. Publicar (com JWT obrigatório, sem `--no-verify-jwt`; a pasta `_shared/` vai junto):
   ```
   supabase functions deploy send-request-email --project-ref aboducqavmsmlzslrseu
   ```
   As outras funções não mudam: `_shared/requests.ts`, `clients.ts` e `http.ts` não foram alterados.
3. Verificar: sem sessão responde 401; com sessão de mediador e um `batch_id` de teste, sem fornecedor, responde 503 `email_unavailable`. Com fornecedor, o email chega e um segundo pedido em menos de 60 s dá 429.

### Respostas de sucesso de `resend-request`

- Mediador (`{ grant_id }`): `{ "ok": true, "delivered": "link" | "notice" | "none" }`.
  - `link`: o cliente nunca tinha entrado e recebeu o link mágico.
  - `notice`: o cliente já tem conta e recebeu um aviso por email sem link (só com `NOTICE_EMAIL_*` configurado).
  - `none`: não saiu nenhum email (cliente com conta e sem `NOTICE_EMAIL_*`). O pedido continua visível na app do cliente; a app deve dizê-lo ao mediador em vez de "Pedido reenviado".
- Cliente (`{ email }`): sempre `{ "ok": true }`, sem `delivered`, exista ou não a conta (não revela contas).
- `create-client` continua a responder só `{ "ok": true }` (a resposta para emails já existentes é neutra de propósito).

Erros: `{ "error": { "code": "..." } }` com códigos fixos (`forbidden`, `invalid_input`, `already_client`, `declined`, `not_pending`, `too_soon` com `retry_after_seconds`, `send_failed`, `cannot_invite`, `not_found`, `server_error`). Nunca há texto técnico.

## O que o Henrique tem de fazer (por esta ordem)

1. Aplicar no SQL Editor, por esta ordem, `migrations/20261126120000_001_fundacao.sql`, `migrations/20261126130000_001b_send_throttle.sql` (limite de 60 s), `migrations/20261126140000_001c_declined_final.sql` ("recusada é final" na RLS e listas por data de atualização) e `migrations/20261126150000_001d_hardening.sql` (auxiliares no esquema `private`, nome de escritório único, `office_client_count()`). Confirmar "aplicada". O esquema `private` nunca deve ser acrescentado a Settings > API > Exposed schemas.
2. Definir os segredos (só os nomes estão aqui; os valores ficam fora do repositório):
   ```
   supabase secrets set --project-ref aboducqavmsmlzslrseu ALLOWED_ORIGINS=<origens da app web, separadas por vírgula>
   supabase secrets set --project-ref aboducqavmsmlzslrseu AUTH_REDIRECT_URL=<URL ou deep link para onde o link leva>
   ```
   Opcionais (aviso por email SEM link a clientes que já têm conta; ver decisão em aberto):
   `NOTICE_EMAIL_API_KEY`, `NOTICE_EMAIL_FROM`, `NOTICE_EMAIL_API_URL` (por defeito Resend). Sem eles o aviso não é enviado e o pedido continua visível na app.
3. Publicar:
   ```
   supabase functions deploy invite-mediator --project-ref aboducqavmsmlzslrseu
   supabase functions deploy create-client   --project-ref aboducqavmsmlzslrseu
   supabase functions deploy resend-request  --project-ref aboducqavmsmlzslrseu
   ```
   Não usar `--no-verify-jwt`: a app chama com a chave anon ou a sessão. A pasta `_shared/` vai junto.
4. No painel Supabase, Authentication:
   - URL Configuration: pôr `AUTH_REDIRECT_URL` na lista de Redirect URLs.
   - Email Templates (Invite e Magic Link): mostrar `{{ .Data.office_name }}` e `{{ .Data.mediator_name }}` em destaque quando existirem (`{{ if .Data.office_name }}...{{ end }}`).

Já injetadas pela plataforma (não definir): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.

## Notas de segurança

- O papel do chamador vem sempre da base de dados (`profiles`) a partir do JWT validado, nunca do corpo nem dos metadados. O escritório do mediador vem de `office_members`.
- A service role só existe no servidor. A concessão é inserida com o JWT do mediador, por isso a RLS e a auditoria (autor = mediador) aplicam-se.
- Resposta igual exista ou não a conta: `resend-request` por email e `create-client` para emails já existentes. O limite de 60 s (`claim_send_slot`) conta qualquer email e guarda só um hash.
- "Tem conta" significa já ter iniciado sessão. Reenvio do mediador a quem tem conta: só aviso sem link, nunca um link de entrada. O link de entrada só sai a pedido do próprio cliente (e só para papel cliente).
- CORS: sem `ALLOWED_ORIGINS` não há cabeçalhos CORS. Corpo máximo 4 KB. Registos só com códigos, nunca emails.
- Falhas no pedido do próprio cliente não são mostradas (para não revelar contas); limites de envio do email por defeito do Supabase podem fazer o link não chegar.
