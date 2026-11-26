# Estado do projeto

Atualizado: 2026-11-26 (fecho do marco "001 Fundação: design aprovado, backend publicado")

## Agora

- Decisões 1 a 10 da secção 7 do `docs/business/context.md` tratadas (ver `docs/decisions.md`). Nome de trabalho ProDossier. Stack: Flutter web-first e responsivo (telemóvel, tablet, desktop; admin desktop-first) + Supabase (eu-west-1) + Cloudflare Pages (alojamento, por criar).
- **Feature 001 Fundação** (`docs/features/001-fundacao/`): 01 a 04 escritos; **gates 1, 2 e 3 aprovados**; 05-qa por escrever. Design aprovado em 152+ renders (`renders/`, índice em `renders/README.md`), incluindo estados, fluxos, transições, cabeçalho sem marca com "Sair" na linha do separador e **marca por colofão**.
- **Backend (ao vivo, confirmado):** 8 tabelas com RLS, 3 migrações aplicadas, 1 admin; 3 funções (`invite-mediator`, `create-client`, `resend-request`) ACTIVE; Auth: palavra-passe 10+ com 4 classes, registo público desativado, URLs provisórios `http://localhost:8080`. Nunca testadas com chamadas autenticadas.
- **App (código):** tarefas 3, 3b, 4, 4b (renders), 4c (alinhamento com o design), 4d (templates de email, por aplicar sem SMTP), 4e, 5 (cliente), 6 (mediador) e 7 (admin) **feitas e ligadas às rotas**; `flutter analyze` limpo e 245 testes a passar (26/11). **Tarefa 8 (qa) feita: veredicto FALHA com correções localizadas** (`docs/features/001-fundacao/05-qa.md`). Sem fugas no esquema e RLS ao vivo; build web e teste de fumo no navegador sem erros. Depois: tarefa 9 (designer, goldens e polimento) e gate 4. Nada foi testado com sessões reais nem num navegador.

## Como retomar (chat novo)

1. Lê `CLAUDE.md`, este ficheiro, `docs/decisions.md`, `docs/features/001-fundacao/04-plan.md`, `docs/design/DESIGN.md` e o `renders/README.md`. Regras do Henrique: design primeiro com renders aprovados antes de implementar; fecho de marco (parar e avisar para chat novo).
2. Se o Flutter não existir (`flutter --version`), corre `bash docs/cloud/setup-flutter.sh`. O MCP do Supabase (só leitura) liga nesta conta.
3. (Feito) ~~Lança a tarefa 4c~~ (flutter-dev) e a **4d** (supabase-dev, templates de email) em paralelo; ficheiros separados. Decisão já tomada para o colofão: datas de `profiles.created_at` (cliente) e `office_members.created_at` (mediador).
4. (5, 6, 7 feitas) Seguem (flutter-dev, pastas separadas; os marcadores trocam-se só em `lib/app/route_builders.dart`), **8** (qa: matriz de isolamento ao vivo + `05-qa.md`; não há utilizadores de teste ainda, o qa propõe os scripts), **9** (designer: goldens 390×844, 768×1024, 1280×800, mais 320 e 844×390, escala de texto 1,3), e **gate 4** (PR com o resumo do `05-qa.md`; o merge é do Henrique).
5. Critérios transversais: tudo testado em telemóvel/tablet/desktop; sem clientes reais até haver parecer jurídico; texto de consentimento `v0-rascunho` provisório; migrações só como ficheiros, aplicadas pelo Henrique (as funções foram publicadas excecionalmente a pedido dele, com token temporário).

## Decisões abertas

- Domínio próprio (verificar marca ProDossier no INPI/TMview e .pt/.com) e fornecedor de email (recomendado Brevo, precisa do domínio); entretanto o email por defeito do Supabase (limite de 2 por hora).
- Templates de email (`supabase/templates/`) prontos mas **por aplicar** até haver SMTP próprio; depois, colar segundo o README ou repetir o PATCH (ver tarefa 4d). Fechar o envio de link mágico a mediador/admin (Send Email Hook ou filtro) quando houver SMTP.
- Criar o projeto Cloudflare Pages e trocar `ALLOWED_ORIGINS`, `AUTH_REDIRECT_URL`, site_url e Redirect URLs pelo endereço final.
- Parecer jurídico (briefing em `docs/business/research/08-juridico.md`); apagamento RGPD de clientes (DELETE bloqueado por desenho).
- Por validar: diferenciação face a concorrentes, templates de seguradora (fase 2), preços.

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

## Pendências para o polimento (tarefa 9) e para uma migração 001d

- Designer: campo "Nome do mediador" no convite (não está nos renders); frases "A {escritório}" com nomes masculinos; 3 px a mais por baixo da régua do separador; botões da folha lateral do mediador em 2:3; confirmar o glifo "…" na fonte (o texto "A criar…" mediu 136).
- supabase-dev (migração 001d, aplicada pelo Henrique): índice único em `lower(offices.name)`; RPC com o total de clientes do escritório (a lista mostra 25 por página sem total).
- flutter-dev: "Criar cliente" no telemóvel abre com `Navigator.push` sobre o GoRouter: o "voltar" do navegador pode não o fechar (verificar no qa).

## Próximo passo exato (retoma da 001 depois do qa)

0. **Feito a 26/11 pelo lead (API de gestão, com ROLLBACK): matriz de isolamento ao vivo com 65 PASS, 0 FAIL, 2 RISCO.** X01: a auditoria de um cliente que retirou o acesso continua visível ao escritório (aceitável como prova de consentimento; pergunta ao jurista). X02: funções auxiliares respondem por RPC a mediadores (é o bug 7, corrigido na 001d).
1. **Bug 1 (chave publishable) refutado pelo lead a 26/11:** `resend-request` com a chave `sb_publishable` passou a porta do Supabase (resposta 429 do bloqueio de 60 s, não 401). Não é preciso mudar de chave; o qa confirma no reteste.
2. **flutter-dev (opus)**: bugs 2 (recuperação revela conta e sem 60 s), 3 (link expirado no fragmento vai para /entrar sem explicação), 4 ("Criar palavra-passe" antes do consentimento), 6 (rejeitar na app sessões por link de mediador/admin: terminar sessão e mensagem genérica) e os baixos do `05-qa.md` que sejam de `lib/`; mais a pendência do `Navigator.push` em "Criar cliente".
3. **supabase-dev (opus)**: bug 5 (decisão A: `resend-request` devolve `delivered: "none"` quando nada foi enviado, e a app ajusta a copy em conjunto com o flutter-dev), bug 7 (funções auxiliares SECURITY DEFINER expostas por RPC: mover para um esquema não exposto ou revogar EXECUTE sem partir as políticas RLS que as usam) e a migração **001d** (índice único em `lower(offices.name)`, RPC do total de clientes); republicar funções alteradas; a migração é aplicada pelo Henrique.
4. Reteste do qa (opus) só nos pontos corrigidos e no resultado do script.
5. Tarefa 9 (designer, opus): goldens e polimento com as pendências acima. Depois gate 4 (PR, merge do Henrique) e fecho da feature (chat novo).
