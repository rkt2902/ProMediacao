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
