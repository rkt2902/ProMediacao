---
name: ideias
description: Ronda de ideias de negócio e produto com o agente bizdev. Atualiza o backlog e pede ao Henrique para escolher o que avança.
argument-hint: "[foco opcional, ex.: receita, retenção]"
disable-model-invocation: true
---

Delega ao subagente `bizdev` em modo A (ronda de ideias). Foco: $ARGUMENTS (se estiver vazio, todos os eixos).

Quando ele terminar:

1. Mostra ao Henrique as 3 a 5 melhores ideias numa tabela curta (ideia, impacto, esforço, porquê) e diz qual recomendas.
2. Pergunta com AskUserQuestion quais avançam (escolha múltipla).
3. As escolhidas passam a "aprovada" no `docs/business/backlog.md`. Para cada uma, sugere o comando `/feature` pronto a correr.
