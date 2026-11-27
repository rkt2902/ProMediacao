# Funções de servidor (edge functions)

Publicadas no projeto `aboducqavmsmlzslrseu` com verificação de JWT. `resend-request` foi republicada a 2026-11-26 (bug 5 do qa: campo `delivered`); sem JWT responde `401`.

| Função | Quem chama | O que faz |
| --- | --- | --- |
| `invite-mediator` | admin | `{ email, office_id, full_name? }`: cria o utilizador mediador, perfil, pertença ao escritório e envia o convite |
| `create-client` | mediador | `{ full_name, email }`: cria o cliente (se não existir) e a concessão pendente do escritório do mediador e envia o pedido |
| `resend-request` | mediador ou cliente | `{ grant_id }` (mediador, "Reenviar pedido") ou `{ email }` (cliente, link novo no ecrã de entrada) |

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
