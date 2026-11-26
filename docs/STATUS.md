# Estado do projeto

Atualizado: 2026-11-26 (gate 3 das migrações confirmado; fecho do marco "001 Fundação: fundação visual e autenticação")

## Agora

- Decisões 1 a 10 da secção 7 do `docs/business/context.md` tratadas e registadas em `docs/decisions.md`. Nome de trabalho: ProDossier. Stack: Flutter (web-first, responsivo em telemóvel/tablet/desktop) + Supabase.
- **Feature 001 Fundação** em `docs/features/001-fundacao/` (01 a 04 escritos; 05-qa por escrever). Gates 1 e 2 aprovados. **Gate 3 (migração) por confirmar pelo Henrique.**
- Tarefas do `04-plan.md`: 1 (esquema/RLS/auditoria), 2 (3 funções de servidor + migração 001b e 001c), 3 e 3b (fundação visual e responsividade) e 4 (esqueleto, sessão, login, link mágico) **feitas**; `flutter analyze` limpo e 112 testes a passar. **Por fazer:** 5 (ecrãs do cliente), 6 (mediador), 7 (admin), 8 (qa), 9 (designer, goldens a 390×844, 768×1024, 1280×800, mais 320 e 844×390).
- Nada foi aplicado nem publicado no Supabase, nem testado contra o Supabase real nem num navegador (MCP do Supabase falhou por proxy; sem `deno` aqui).

## Como retomar (chat novo)

1. Lê `CLAUDE.md`, este ficheiro, `docs/decisions.md` e `docs/features/001-fundacao/04-plan.md`.
2. Se o Flutter não existir (`flutter --version`), corre `bash docs/cloud/setup-flutter.sh`.
3. **Primeiro passo de trabalho: tarefa 4b.** O Henrique quer ver referências visuais de cada ecrã antes de implementar (regra "Design primeiro" no `CLAUDE.md`). Lança o `designer` para produzir os renders PNG da 001 em `docs/features/001-fundacao/renders/` (telemóvel, tablet, desktop; admin desktop e um tamanho pequeno), mostra-os ao Henrique e só com aprovação avançam as tarefas 5, 6 e 7. Os renders não dependem do gate 3.
3b. Pergunta ao Henrique quais pontos da checklist abaixo já estão feitos. Sem o ponto 1 e 2 (migrações aplicadas e admin criado) não se lançam as tarefas 5, 6 e 7.
4. Pequeno arranjo antes da tarefa 5/6 (flutter-dev): o `PageFrame` ganhou `accountName`/`onSignOut` e `AccountActions` (telemóvel só "Sair"); o `AccountMenu` em `lib/features/auth/` deve passar a usá-los. A copy nova "Não foi possível concluir. Tente de novo." e "Precisa de ligação à internet." precisa de validação do designer.
5. Depois da aprovação dos renders (4b) e do gate 3, lança as tarefas 5, 6 e 7 (flutter-dev, pastas separadas; os marcadores trocam-se só em `lib/app/route_builders.dart`), depois 8 (qa) e 9 (designer), depois gate 4 (PR com o resumo do `05-qa.md`; o merge é do Henrique).
6. Critérios transversais: tudo testado em telemóvel/tablet/desktop (admin desktop-first); sem clientes reais até haver parecer jurídico; texto de consentimento `v0-rascunho` é provisório; migrações só como ficheiros, aplicadas pelo Henrique.

## Decisões abertas

- Alojamento da app web (UE) e endereço estável para os links mágicos (`AUTH_REDIRECT_URL`).
- Fornecedor de email (SMTP) e do aviso por email sem link para quem já tem conta.
- Parecer jurídico (briefing em `docs/business/research/08-juridico.md`); apagamento RGPD de clientes (DELETE está bloqueado na base de dados por desenho).
- Por validar: diferenciação face a concorrentes, viabilidade dos templates de seguradora (fase 2), valores de preços, marca ProDossier no INPI e domínios.

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
