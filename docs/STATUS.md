# Estado do projeto

Atualizado: 2026-11-25

## Agora

- Projeto Flutter criado na raiz (`flutter create`), package id `pt.promediacao.promediacao`. `flutter analyze` e `flutter test` limpos. Ainda é o esqueleto por defeito (`lib/main.dart` do contador).

## Próximos passos

1. **Supabase:** projeto `aboducqavmsmlzslrseu` existe, está vazio, e o MCP só leitura está no `.mcp.json`. Na sessão de 25/11 a ligação MCP falhou (erro de proxy): confirmar a ligação (pede login no Supabase).
2. **Contexto de negócio em rascunho** em `docs/business/context.md` (vindo da thread de planeamento) e backlog em `docs/business/backlog.md`. Nada é definitivo: rever as 10 decisões em aberto (secção 7) e confirmar o que já vinha como decidido.
3. **Preencher `docs/design/DESIGN.md`** a partir do protótipo (`docs/reference/prototipo/`).

## Em aberto

- Stack decidida: Flutter + Supabase (projeto vazio). Decisões de negócio 1, 2 e 4 fechadas; ver `docs/decisions.md`. Faltam as decisões 3 (diferenciação), 5 a 10 da secção 7 do `context.md`.
