# Funções de servidor (edge functions)

Escritas como ficheiros. Nada foi publicado. Quem publica é o Henrique.

| Função | Quem chama | O que faz |
| --- | --- | --- |
| `invite-mediator` | admin | `{ email, office_id, full_name? }`: cria o utilizador mediador, perfil, pertença ao escritório e envia o convite |
| `create-client` | mediador | `{ full_name, email }`: cria o cliente (se não existir) e a concessão pendente do escritório do mediador e envia o pedido |
| `resend-request` | mediador ou cliente | `{ grant_id }` (mediador, "Reenviar pedido") ou `{ email }` (cliente, link novo no ecrã de entrada) |

Erros: `{ "error": { "code": "..." } }` com códigos fixos (`forbidden`, `invalid_input`, `already_client`, `declined`, `not_pending`, `too_soon` com `retry_after_seconds`, `send_failed`, `cannot_invite`, `not_found`, `server_error`). Nunca há texto técnico.

## O que o Henrique tem de fazer (por esta ordem)

1. Aplicar no SQL Editor `migrations/20261126120000_001_fundacao.sql` e depois `migrations/20261126130000_001b_send_throttle.sql` (esta cria o limite de 60 s). Confirmar "aplicada".
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
