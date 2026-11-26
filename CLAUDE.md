# ProMediacao

## Projeto
- App em Flutter + Supabase. Projeto novo: o estado atual e o próximo passo estão sempre em `docs/STATUS.md`.
- UI e docs em português de Portugal. Código, nomes de ficheiros e identificadores em inglês.
- Commits: uma linha curta, conventional commits (ex.: `feat: ecrã de login`).
- Código de referência vindo de ferramentas de design (Claude Design, outra AI, ficheiros colados) é sempre referência: integra-o no projeto da melhor forma, não o copies tal como está.

## Comandos
- `flutter pub get`
- `flutter analyze` (zero problemas novos antes de dar algo como feito)
- `flutter test` (os goldens de `test/design_review/` são só para o designer ver, ficam fora da regressão)
- `dart format .`

## Estrutura
- `lib/` app, `test/` testes, `supabase/migrations/` migrações .sql, `docs/` fonte de verdade.
- Supabase: projeto `aboducqavmsmlzslrseu` (org ProMediacao, eu-west-1), ligado em só leitura pelo `.mcp.json`.
- Sessões cloud: ver `docs/cloud/CLOUD.md`.

## Papéis
- Esta sessão principal é o Tech Lead. O Henrique é aprovador: só decide nos gates do `/feature`.
- Agentes em `.claude/agents/`: bizdev, pm, designer, flutter-dev, supabase-dev, qa. Para pesquisar no código usa o agente Explore.
- Pedidos pequenos (um bug, um ajuste em 1 ou 2 ficheiros): sem pipeline. Delega direto ao dev certo e depois ao qa.

## Fontes de verdade
- `docs/STATUS.md` (estado), `docs/decisions.md` (decisões), `docs/design/DESIGN.md` (design), `docs/business/context.md` (negócio).
- Cada feature vive em `docs/features/NNN-slug/`: 01-business, 02-spec, 03-design, 04-plan, 05-qa.
- A conversa não é fonte de verdade: o que importa fica nestes ficheiros.

## Contrato de handoff
Todos os agentes terminam com isto, no máximo 10 linhas:
- FEITO: o que ficou feito, em uma ou duas linhas
- FICHEIROS: caminhos criados ou alterados
- DECISÕES EM ABERTO: opções A/B/C com recomendação, ou "nenhuma"
- RISCOS: o que pode estar errado ou não foi verificado
- PRÓXIMO: o que o lead deve fazer a seguir
O detalhe fica no ficheiro do pacote, não no resumo.

## Regras duras
- Migrações: os agentes só escrevem ficheiros .sql e nunca os aplicam. O Henrique aplica no SQL Editor e confirma.
- Numa tarefa, nenhum ficheiro tem dois donos.
- Os agentes não fazem perguntas ao Henrique: escrevem a dúvida em DECISÕES EM ABERTO e o lead junta tudo no gate seguinte.

## Fecho de marco (regra do Henrique)
- Quando uma feature, marco ou fase termina, paras de produzir nesse chat. Antes de parar: atualiza `docs/STATUS.md` (o que está feito, o que está em curso, gates aprovados e pendentes, decisões em aberto, bugs, e os próximos passos por ordem, com o comando ou ficheiro exato para retomar), regista decisões novas em `docs/decisions.md`, faz commit e push.
- Depois dás um aviso curto ao Henrique: o marco acabou, continuar num chat novo (`/clear` ou sessão nova), e onde está o ponto de retoma. Não começas a fase seguinte no mesmo chat.
- Um chat novo tem de conseguir continuar perfeitamente só com `CLAUDE.md`, `docs/STATUS.md` e `docs/decisions.md`: nada de importante fica só na conversa.

## Compact instructions
Ao compactar, preserva: feature atual e fase, gates aprovados, decisões tomadas, ficheiros do pacote e bugs em aberto. Descarta outputs de comandos e leituras de ficheiros.
