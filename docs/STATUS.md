# Estado do projeto

Atualizado: 2026-11-25

## Agora

- Repo montado com a equipa de agentes (agentes, skills, templates e docs). Ainda não há código da app.

## Próximos passos

1. **Criar o projeto Flutter na raiz:** `flutter create --project-name promediacao --org <org> .`
   - O `<org>` (ex.: `pt.promediacao`) define o package id da app e é difícil de mudar depois: pergunta ao Henrique antes.
   - O `--project-name` é obrigatório porque o nome da pasta (`ProMediacao`) tem maiúsculas.
   - Não substituir o `.gitignore`, o `CLAUDE.md` nem o `README.md` que já existem; juntar ao `.gitignore` o que o Flutter precisar.
   - No fim: `flutter analyze` e `flutter test` limpos, commit e push.
2. **Criar o projeto Supabase** e ligar o MCP em modo só leitura (ver `docs/cloud/CLOUD.md`).
3. **Preencher `docs/business/context.md` e `docs/design/DESIGN.md`.** Correr `/ideias` ajuda a fechar o contexto de negócio.

## Em aberto

- Package id / org da app.
- Stack assumida: Flutter + Supabase (confirmar).
