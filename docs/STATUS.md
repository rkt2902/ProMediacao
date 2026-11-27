# Estado do projeto

Atualizado: 2026-11-27 (**feature 001 Fundação fechada e no `main`**; Cloudflare adiado pelo Henrique; a seguir: propor a 002)

## Agora

- **001 Fundação: PASSA COM RESSALVAS** (`docs/features/001-fundacao/05-qa.md`). PR https://github.com/rkt2902/ProMediacao/pull/3 com merge feito no `main` (gate 4 fechado).
- App Flutter web-first e responsiva (entrada, palavra-passe, consentimento, Com quem partilho, clientes do mediador, admin com contagens), design aprovado e goldens da app real em `test/design_review/001_fundacao/`. `flutter analyze` limpo, 275 testes.
- Supabase ao vivo: migrações 001 a 001e aplicadas e verificadas; matriz de isolamento 66 PASS, 0 FAIL, 1 RISCO (X01); regressão 001d/001e 15 PASS; 3 funções publicadas; Auth com palavra-passe forte, registo público desativado, URLs provisórios `http://localhost:8080`; `private` fora dos esquemas expostos.
- Regras de trabalho do Henrique no `CLAUDE.md`: design primeiro, fecho de marco no fim de cada feature, gestão de modelos por tarefa, limite de uso (parar aos 93%), o lead aplica migrações com resumo prévio.

## Como retomar (chat novo)

1. Lê `CLAUDE.md`, este ficheiro, `docs/decisions.md` e `docs/business/backlog.md`. Se o Flutter faltar: `bash docs/cloud/setup-flutter.sh`.
2. **Publicar a app no Cloudflare Pages** (decidido; **adiado a 27/11**: o Henrique ainda não criou a conta, só retomar quando ele disser). Token: My Profile > API Tokens > Custom Token com só Account > Cloudflare Pages > Edit, pedido por `request_credential` para `api.cloudflare.com`. Projeto `promediacao` criado pelo lead (upload direto). Chave publishable: API de gestão, `GET /v1/projects/aboducqavmsmlzslrseu/api-keys`. Passos: o Henrique cria a conta/projeto e dá um token da API do Cloudflare pelo pedido de credencial; o lead faz `flutter build web` com `SUPABASE_URL` e a chave publishable e publica; depois troca `ALLOWED_ORIGINS`, `AUTH_REDIRECT_URL` (segredos das funções), `site_url` e Redirect URLs do Auth pelo endereço `*.pages.dev`.
3. Com a app online (bloqueado pelo passo 2: os links mágicos apontam para `localhost`), o Henrique faz a **checklist manual de 8 passos** do `05-qa.md` (sessões e emails reais; o email por defeito envia 2 por hora). Os bugs que aparecerem são corrigidos antes da 002.
4. Bugs baixos herdados: 16 (botões anunciados duas vezes, `app_pressable.dart:72`), 14 (aviso offline só depois de um pedido falhar; plugin de rede), 10 (ver `05-qa.md`).
5. **Próxima feature (002): escolhida pelo Henrique a 27/11, "Novo pedido" + ecrã de clientes com o estado dos pedidos.** Sequência 002 a 007 e modelo Pedido / Destinatário / Proposta em `docs/business/roadmap.md` (a 002 já prepara o modelo para pedidos do cliente, vários destinatários e propostas). Arranque: o Henrique escreve `/feature Novo pedido: escolher o cliente e o tipo de seguro, com a lista automática do que pedir, e ecrã de clientes com o estado dos pedidos (ver docs/business/roadmap.md)`. Descrição original: "Novo pedido: escolher o cliente e o tipo de seguro, com a lista automática do que pedir" (o mediador cria pedidos por tipo de seguro), que assenta na 001. Correr `/feature` com bizdev e pm; design primeiro com renders.

## Decisões abertas

- SMTP próprio (Brevo recomendado) e domínio (verificar ProDossier no INPI e .pt/.com); depois aplicar os templates de `supabase/templates/` e fechar o link mágico a mediador/admin no servidor (Send Email Hook).
- Parecer jurídico (briefing em `docs/business/research/08-juridico.md`; inclui X01 e o apagamento RGPD).
- Notificações ao cliente (portal, push no telemóvel e app): no backlog.

## Checklist do Henrique (marcar quando feito)

Bloqueia a continuação da 001 (por ordem):
- [x] 1. Aplicar no SQL Editor (confirmado ao vivo via MCP: 8 tabelas com RLS, funções 001c presentes), por ordem, `supabase/migrations/20261126120000_001_fundacao.sql`, `..._001b_send_throttle.sql` e `..._001c_declined_final.sql`; dizer "aplicada".
- [x] 2. Criar o utilizador admin (1 perfil admin confirmado ao vivo) em Authentication > Users (Auto confirm) e correr `supabase/seed/001_first_admin.sql` com o UUID, nome e email trocados.
- [x] 3. Alojamento decidido: Cloudflare Pages (opção A). Falta criar o projeto Cloudflare e ligar o repositório; o URL `*.pages.dev` serve de endereço provisório.
- [x] 4. Funções `invite-mediator`, `create-client`, `resend-request` publicadas em 26/11 (ACTIVE, JWT obrigatório; sem sessão devolvem 401). Segredos `ALLOWED_ORIGINS` e `AUTH_REDIRECT_URL` definidos com o URL provisório `http://localhost:8080`: **trocar pelo URL final do Cloudflare Pages** (`supabase secrets set` + Auth > URL Configuration). Código não testado com chamadas reais autenticadas.
- [x] 5. Colar `docs/cloud/setup-flutter.sh` no setup script do ambiente cloud (`docs/cloud/CLOUD.md`), para os chats novos terem o Flutter.
- [x] 6. Reconectar o MCP do Supabase (liga em só leitura; confirmado) (token em Network secrets, `docs/cloud/CLOUD.md`); sem isto o qa dá queries para correres tu.

Não bloqueia agora, mas tem de estar feito antes de clientes reais ou de publicar:
- [x] 6b. Auth configurado em 26/11 via API: palavra-passe mínima 10 com minúscula, maiúscula, número e símbolo; registo público desativado (`disable_signup`); site_url e Redirect URL provisórios `http://localhost:8080`. Falta ativar a verificação de palavras-passe comprometidas (só em planos pagos) e trocar o URL.
- [ ] 7. Fornecedor de email (SMTP): recomendado Brevo, plano gratuito (300 emails/dia), trocável depois; precisa de um domínio próprio para SPF/DKIM. Falta abrir conta e domínio para os links mágicos.
- [ ] (depois) 8. Escolher o jurista e entregar `docs/business/research/08-juridico.md`.
- [ ] (depois) 9. Verificar a marca ProDossier no INPI/TMview (classes 9, 42, 35) e os domínios .pt/.com.

Úteis, sem pressa:
- [ ] (depois) 10. Juntar `Dossier-Seguros-prototipo.html` a `docs/reference/prototipo/`.
- [ ] (depois) 11. Juntar templates reais de seguradoras (sem dados de clientes) a `docs/reference/` para a fase 2 das fichas.
- [ ] (depois) 12. Confirmar com colegas da APROSE que não há concorrente português equivalente.

- [ ] 13. Revogar o token de acesso do Supabase em Account > Access Tokens (foi usado para publicar as funções; já não é preciso). A credencial `api.supabase.com` fica guardada no ambiente cloud: removê-la em Settings se quiseres.

