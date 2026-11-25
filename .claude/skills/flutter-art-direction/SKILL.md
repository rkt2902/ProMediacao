---
name: flutter-art-direction
description: Processo de direção de arte para ecrãs Flutter que evita o look genérico de IA e de Material por defeito. Usar ao desenhar, redesenhar ou rever visualmente qualquer ecrã.
---

# Direção de arte em Flutter

Os modelos tendem para a resposta mais provável. Em UI isso dá o look "feito por IA": Material por defeito, tudo em cartões, gradientes roxos, tudo com o mesmo peso. Este processo existe para fugir disso de forma deliberada.

## Processo

1. **Preflight.** Lê `docs/design/DESIGN.md`, o tema (ThemeData e tokens), os widgets partilhados e 2 ou 3 ecrãs vizinhos. Preserva a identidade que já existe: isto não é um redesign, a não ser que o peçam.
2. **Classificação.** Diz se o pedido é preservação, refinamento, transformação visível ou paridade com uma referência, e ajusta a ambição a isso. Responder a um redesign com o default quase intacto é uma falha; responder a um ajuste pequeno com um redesign também.
3. **Diagnóstico.** A tarefa principal do utilizador neste ecrã numa frase, e o que falha visualmente hoje, em termos observáveis.
4. **Três direções.** Escreve 3 abordagens, da mais previsível à menos previsível. A mais previsível é a zona de risco: só a escolhes com uma razão concreta. Escolhe uma e regista as outras duas numa linha cada.
5. **Hierarquia primeiro.** Define o que se vê em 1.º, 2.º e 3.º lugar. Usa tamanho, peso, espaço e posição antes de cor e decoração.
6. **Tokens antes de widgets.** Se faltar um token, propõe-no em DESIGN.md em vez de usar um valor solto.
7. **Estados.** Populado (com dados realistas e um caso de texto longo), vazio, a carregar (skeleton), erro, offline e desativado. Cada estado com uma ação principal.
8. **Motion.** Só o que informa: mudança de estado, origem e destino. Durações e curvas do motion spec. Nenhuma informação existe só como movimento.
9. **Render e crítica.** Gera golden tests do ecrã (tema claro e escuro se existir, escala de texto 1.0 e 1.3, ecrã pequeno e largo), lê os PNG, confirma o contraste do texto e corre a checklist abaixo. Itera até passar. Nos golden tests carrega as fontes reais da app; sem isso o texto aparece como blocos e a crítica não vale nada.

## Limites

- Não acrescentas fontes, packs de ícones, sistemas de tema ou dependências de UI novas sem uma razão concreta.
- Não metes dados falsos na base de dados só para um screenshot ficar bonito: usa fixtures nos testes.

## Teste de cara de IA

Se um ecrã tiver 3 ou mais destes sinais, refaz:

- Widgets Material sem estilo (AppBar, Card com elevação, FAB, ListTile) a definir o aspeto do ecrã.
- Tudo dentro de cartões quando espaço e divisores chegavam.
- Grelha de 3 cartões iguais com ícone, título e texto.
- O mesmo raio, sombra e espaçamento em todos os elementos, sem ritmo.
- Gradientes roxo/azul, glassmorphism, blobs, brilhos, ilustrações 3D genéricas.
- Emoji como ícones; ícones sem etiqueta quando o significado não é óbvio.
- Uma fonte genérica (Inter, Roboto, sistema) como "escolha" quando o projeto tem a sua.
- Hero centrado com título grande, subtítulo cinzento e botão, num ecrã que não é marketing.
- Texto cinzento claro sobre fundo colorido (contraste baixo).
- Copy genérica ("Bem-vindo!", "Comece já"), lorem ipsum ou placeholders.
- Spinners em listas, animações decorativas, confettis.

## Como reportar

- Mudanças em termos concretos: medidas, tokens, ordem, contraste.
- Nunca "moderno", "limpo" ou "bonito" como justificação.
