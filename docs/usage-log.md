# Registo de uso (limite de 5 horas)

Regra no `CLAUDE.md` (secção "Limite de uso"): o lead pergunta a % ao Henrique sempre que para para perguntar algo, regista aqui e para perto dos **90%**. "Janela" = período de 5 horas do limite; "mudou" = começou uma janela nova desde o registo anterior.

## Registos

| Data e hora | % usado | Janela mudou? | Feito desde o registo anterior (agentes e modelos) |
| --- | --- | --- | --- |
| 2026-11-27 (1.º registo) | 64% | não (tudo na mesma janela) | Desde o início da janela, num só chat: retoma da 001 (STATUS, Cloudflare adiado), roadmap dos pedidos; 002 até ao gate 3: bizdev (sonnet), pm (sonnet, 2 voltas), designer modo 1 (opus, ~290k tokens, 163 renders) + ajustes do gate 2 (opus), supabase-dev migração (opus, ~230k), flutter-dev 3a e 3a-2 (sonnet, ~160k), aplicação e verificação ao vivo da migração pelo lead. Em curso: supabase-dev tarefa 2 (opus) e flutter-dev tarefa 3 (opus) |
| 2026-11-27 (2.º) | 100% (limite atingido; janela reiniciada às 15:30 UTC) | sim, depois do limite | De 64% a 100% na mesma janela: supabase-dev tarefa 2 (opus, ~280k), flutter-dev tarefa 3 (opus, ~280k), lead (aplicação e verificação ao vivo da migração, commits); o limite chegou logo a seguir a lançar as tarefas 4 e 5 (sonnet, em paralelo), que pararam a meio. **Falha da regra:** lancei trabalho sem confirmar a % depois das duas tarefas Opus |

## Estimativas (a afinar com os registos)

- **Duas tarefas Opus pesadas (~280k tokens cada, ~15 a 18 min) custaram cerca de 35% da janela** (64% para ~100%). Uma tarefa Opus deste tamanho ≈ 15 a 18%. Perguntar a % depois de cada tarefa Opus e antes de lançar mais trabalho em paralelo.
- Primeira impressão: o designer com renders (opus) e a migração (opus) são as tarefas mais caras; specs e docs (sonnet) são baratas.
