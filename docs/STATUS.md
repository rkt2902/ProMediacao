# Estado do projeto

Atualizado: 2026-11-28 (**feature 002 Novo pedido fechada no gate 4**; PR para o `main` à espera do merge do Henrique)

## Agora

- **002 Novo pedido + clientes com o estado dos pedidos: PASSA COM RESSALVAS** (`docs/features/002-novo-pedido/05-qa.md`). Gates 1 a 4 aprovados (27 e 28/11). PR do branch `claude/stoic-euler-i4bbpo` para o `main` (o merge é do Henrique).
  - Mediador: Novo pedido (cliente com concessão ativa, N tipos, lista editável, condições particulares, mensagem, aviso de repetido), Clientes com a coluna "Pedidos" e "Novo pedido" como ação principal, ficha do cliente, pedido em só leitura; admin com a 4.ª contagem.
  - Cliente: "Os meus pedidos" é o ecrã inicial (4 etapas, "Acesso retirado"), detalhe só leitura, sino e notificações; "Com quem partilho" em `/cliente/partilhas`.
  - Supabase ao vivo: migração `20261127120000_002_requests.sql` aplicada (matriz 002 35/0, casos-limite 002b 13/0, regressão 001 66/0/1 RISCO, 001de 15/0); função `send-request-email` publicada (401 sem sessão; 503 `email_unavailable` sem fornecedor).
  - `flutter analyze` limpo; `flutter test --exclude-tags design-review` 479 a passar.
- **001 Fundação:** no `main` (PR #3). Roadmap dos pedidos 002 a 007 em `docs/business/roadmap.md`.
- Regras do Henrique no `CLAUDE.md`, incluindo a nova regra de uso: perguntar a % em cada paragem, registar em `docs/usage-log.md`, parar perto dos 90%.

## Como retomar (chat novo)

1. Lê `CLAUDE.md`, este ficheiro, `docs/decisions.md`, `docs/usage-log.md` e `docs/business/roadmap.md`. Se o Flutter faltar: `bash docs/cloud/setup-flutter.sh`. Pergunta ao Henrique a % de uso antes de lançar trabalho Opus.
2. Se o PR da 002 ainda não tiver merge, lembra o Henrique.
3. **Polimento e goldens da 002 (tarefa 7 do `04-plan.md`, pendente):** `designer` (opus) em modo 2: goldens em `test/design_review/002_novo_pedido/`, comparar com `docs/features/002-novo-pedido/renders/`; os pedidos de correção vão ao flutter-dev (sonnet) e depois `qa` só nos ecrãs mexidos. Pendentes conhecidos do design: animações de saída de folhas/itens tirados e entrada `lento` das linhas novas na ficha; escala 1.3 e largura 320 nos goldens.
4. **Publicar a app no Cloudflare Pages** (adiado a 27/11 até o Henrique criar a conta). Token: My Profile > API Tokens > Custom Token com só Account > Cloudflare Pages > Edit, pedido por `request_credential` para `api.cloudflare.com`. Projeto `promediacao` criado pelo lead (upload direto). Chave publishable: API de gestão, `GET /v1/projects/aboducqavmsmlzslrseu/api-keys`. Depois: `flutter build web` com `SUPABASE_URL`, `SUPABASE_ANON_KEY` (publishable) e `AUTH_REDIRECT_URL`; trocar `ALLOWED_ORIGINS`, `AUTH_REDIRECT_URL` e `APP_URL` (segredos das funções), `site_url` e Redirect URLs do Auth pelo endereço `*.pages.dev`.
5. **Fornecedor de email (Brevo recomendado) + domínio:** sem ele o email do pedido não sai (o cliente vê o pedido na app e no sino). Segredos `NOTICE_EMAIL_API_KEY`, `NOTICE_EMAIL_FROM`, `NOTICE_EMAIL_API_URL` (Brevo); detalhe em `supabase/functions/README.md`.
6. Com a app online: checklists manuais do Henrique, a da 001 (`docs/features/001-fundacao/05-qa.md`) e a da 002 (8 passos em `docs/features/002-novo-pedido/05-qa.md`). Testar o email com sessão real quando houver fornecedor.
7. **Próxima feature (003):** "O cliente responde: carrega documentos ou condições particulares, com progresso" (`docs/business/roadmap.md`). Correr `/feature` com bizdev e pm; design primeiro com renders.

## Bugs e riscos em aberto

- 001: bug 14 (aviso offline só depois de um pedido falhar). O bug 16 (botões anunciados duas vezes, `app_pressable.dart:72`) não foi replicado nos widgets novos, mas continua no da 001.
- 002: email com sessão real por testar; o limite de 60 s faz falhar o email de um 2.º lote ao mesmo cliente em menos de 60 s; `_refresh` do `ClientsController` limita a 199 linhas; o motivo da retirada não é mostrado ao mediador ("Sem acesso", decisão D1).

## Decisões abertas

- SMTP/fornecedor de email (Brevo) e domínio (verificar ProDossier no INPI e .pt/.com); depois aplicar os templates de `supabase/templates/` e fechar o link mágico a mediador/admin no servidor (Send Email Hook).
- Parecer jurídico (briefing em `docs/business/research/08-juridico.md`; inclui X01, o apagamento RGPD e o anúncio aberto da 007).
- Notificações push no telemóvel: no backlog.

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

