# Estado do projeto

Atualizado: 2026-11-25

## Agora

- Projeto Flutter criado na raiz (`flutter create`), package id `pt.promediacao.promediacao`. `flutter analyze` e `flutter test` limpos. Ainda é o esqueleto por defeito (`lib/main.dart` do contador).

## Próximos passos

1. **Primeira feature:** 001 Fundação (autenticação, perfis, escritórios e consentimento). Proposta ao Henrique; falta o OK para abrir o gate 1 (`/feature`).
2. **Supabase:** projeto `aboducqavmsmlzslrseu` existe, está vazio, e o MCP só leitura está no `.mcp.json`. Na sessão de 25/11 a ligação falhou (erro de proxy): confirmar (pede login).
3. **Preencher `docs/design/DESIGN.md`** a partir do protótipo (`docs/reference/prototipo/`).
4. **Henrique:** verificar marca ProDossier no INPI/TMview e domínios; escolher jurista e fornecedor de email; juntar templates reais de seguradoras em `docs/reference/`.

## Em aberto

- Decisões 1 a 10 da secção 7 do `context.md` tratadas (ver `docs/decisions.md`). Por validar: diferenciação (decisão 3), parecer jurídico (briefing em `docs/business/research/08-juridico.md`), viabilidade dos templates, valores de preços.
- Sem clientes reais até haver parecer jurídico.

## Checklist do Henrique (marcar quando feito)

Bloqueia a continuação da 001 (por ordem):
- [ ] 1. Aplicar no SQL Editor, por ordem, `supabase/migrations/20261126120000_001_fundacao.sql`, `..._001b_send_throttle.sql` e `..._001c_declined_final.sql`; dizer "aplicada".
- [ ] 2. Criar o utilizador admin em Authentication > Users (Auto confirm) e correr `supabase/seed/001_first_admin.sql` com o UUID, nome e email trocados.
- [ ] 3. Decidir o alojamento da app web (UE) e o endereço estável para os links mágicos.
- [ ] 4. Publicar as 3 funções e definir `ALLOWED_ORIGINS` e `AUTH_REDIRECT_URL` (passos em `supabase/functions/README.md`); ajustar Redirect URLs e modelos de email no painel. Depende do ponto 3.
- [ ] 5. Colar `docs/cloud/setup-flutter.sh` no setup script do ambiente cloud (`docs/cloud/CLOUD.md`), para os chats novos terem o Flutter.
- [ ] 6. Reconectar o MCP do Supabase (token em Network secrets, `docs/cloud/CLOUD.md`); sem isto o qa dá queries para correres tu.

Não bloqueia agora, mas tem de estar feito antes de clientes reais ou de publicar:
- [ ] 7. Escolher o fornecedor de email (SMTP) para os links mágicos.
- [ ] 8. Escolher o jurista e entregar `docs/business/research/08-juridico.md`.
- [ ] 9. Verificar a marca ProDossier no INPI/TMview (classes 9, 42, 35) e os domínios .pt/.com.

Úteis, sem pressa:
- [ ] 10. Juntar `Dossier-Seguros-prototipo.html` a `docs/reference/prototipo/`.
- [ ] 11. Juntar templates reais de seguradoras (sem dados de clientes) a `docs/reference/` para a fase 2 das fichas.
- [ ] 12. Confirmar com colegas da APROSE que não há concorrente português equivalente.
