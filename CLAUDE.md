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

## Gestão de agentes (regra do Henrique: eficiência sem sacrificar qualidade)
- Poupar tokens importa, mas código limpo e sem bugs à primeira poupa mais a longo prazo: nunca se baixa o modelo numa tarefa onde um erro sai caro.
- O lead escolhe o `model` em cada delegação, conforme a dificuldade (os defaults em `.claude/agents/` são só o ponto de partida: designer e supabase-dev em opus; bizdev, pm, flutter-dev e qa em sonnet):
  - **opus**: esquema, RLS, auditoria, funções de servidor e tudo o que toca em segurança ou dados pessoais; autenticação, sessão, rotas e lógica com muitos estados; trabalho visual de julgamento (designer); veredicto do qa sobre isolamento e permissões; bugs cuja causa não é óbvia.
  - **sonnet**: ecrãs e widgets seguindo uma spec e um design já claros, testes, ajustes e correções localizadas, specs e docs, pesquisa de negócio, revisões simples.
  - **haiku**: só buscas e tarefas mecânicas triviais.
- Não definir `effort` salvo pedido do Henrique.
- Menos tokens sem perder qualidade: prompts com objetivo, ficheiros de entrada e de saída, critério de feito e o que não fazer; passar caminhos em vez de colar conteúdo; retomar um agente com SendMessage em vez de lançar outro do zero; um único agente por ficheiro; `flutter analyze` e `flutter test` só uma vez no fim de cada tarefa; regenerar só os renders afetados; o lead lê os handoffs, não os ficheiros.
- Sempre que uma tarefa tiver partes de dificuldade diferente, divide-a: a parte crítica em opus e a rotineira em sonnet.

## Design primeiro (regra do Henrique)
- Nenhum ecrã é implementado antes de o Henrique ver e aprovar uma referência visual dele (renders em PNG, ou página navegável, por ecrã e nos três tamanhos: telemóvel, tablet, desktop; admin só desktop e um tamanho pequeno). O texto do `03-design.md` não chega.
- O designer produz primeiro as referências (em `docs/features/NNN-slug/renders/`), o lead mostra-as no gate 2, e só com aprovação o flutter-dev implementa. Mudanças pedidas voltam ao designer.
- As referências são só referência: o flutter-dev integra-as com os tokens e widgets do projeto, não copia HTML.

## Fecho de marco (regra do Henrique)
- Quando uma **feature** termina (não cada fase ou tarefa: dentro de uma feature o Henrique quer continuar no mesmo chat e que faças tudo), paras de produzir nesse chat. Antes de parar: atualiza `docs/STATUS.md` (o que está feito, o que está em curso, gates aprovados e pendentes, decisões em aberto, bugs, e os próximos passos por ordem, com o comando ou ficheiro exato para retomar), regista decisões novas em `docs/decisions.md`, faz commit e push.
- Depois dás um aviso curto ao Henrique: o marco acabou, continuar num chat novo (`/clear` ou sessão nova), e onde está o ponto de retoma. Não começas a fase seguinte no mesmo chat.
- Um chat novo tem de conseguir continuar perfeitamente só com `CLAUDE.md`, `docs/STATUS.md` e `docs/decisions.md`: nada de importante fica só na conversa.

## Compact instructions
Ao compactar, preserva: feature atual e fase, gates aprovados, decisões tomadas, ficheiros do pacote e bugs em aberto. Descarta outputs de comandos e leituras de ficheiros.
