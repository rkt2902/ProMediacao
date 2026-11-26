# DESIGN.md: direção de arte

> Fonte de verdade do agente designer. Os tokens e componentes vivem no design system; aqui fica a intenção, as regras e o que já foi rejeitado.
> Estado: **aprovada no gate 2 da feature 001** (2026-11-26), incluindo as fontes. Os tokens abaixo ainda não existem em código; o flutter-dev cria-os nos caminhos indicados em "Design system". Até lá, nenhum ecrã usa valores soltos: se faltar um token, propõe-se aqui primeiro.

## Personalidade

- Três adjetivos: **arrumada, franca, calma.**
  - Arrumada: parece um dossiê bem organizado por alguém cuidadoso. Tudo tem um lugar, uma data e um estado.
  - Franca: diz o que acontece aos dados em frases curtas, sem letra miudinha. O "não" tem o mesmo peso que o "sim".
  - Calma: pouca cor, pouco movimento, nada a pedir atenção sem motivo. A urgência é rara e por isso nota-se.
- O que a app NÃO é:
  - Não é uma seguradora nem um banco: nada de azul institucional, escudos, cadeados, pessoas sorridentes de banco de imagens, gráficos financeiros.
  - Não é uma app de produtividade genérica: nada de grelhas de cartões iguais, gradientes, glassmorphism, ícones em círculos coloridos.
  - Não é marketing: nenhum ecrã de trabalho abre com hero centrado, slogan e botão.

## Para quem

- **Mediadores** (desktop e tablet, horas seguidas, muitos clientes): densidade média, tabelas legíveis, ações onde o olho já está, teclado a funcionar (Tab, Enter, Esc).
- **Clientes** particulares e empresas (sobretudo telemóvel; alguns com pouca destreza digital ou mais velhos): texto base 17, alvos de toque de 48 no mínimo e 56 nas ações principais, uma decisão por ecrã, nenhuma informação só por cor ou só por movimento, sem gestos escondidos (nada de swipe para retirar).
- **Admin** (o Henrique, desktop): poucos números, nenhum dado pessoal no ecrã.
- Tratamento: **formal na 3.ª pessoa** ("Pode retirar quando quiser"), nunca "tu". É o registo esperado em seguros em Portugal e o mais seguro para clientes mais velhos.

## Assinatura visual

O que torna a app reconhecível num screenshot sem logótipo:

1. **Papel e tinta.** Fundo cor de papel (`papel`), texto quase preto (`tinta`), e a ação principal é um botão cheio a tinta. Não há "cor de marca" a pintar botões: a autoridade vem do contraste, não do azul.
2. **O separador de pasta.** O contexto do ecrã (o escritório, ou "Os meus dados" no cliente) aparece num separador cor de cartolina (`cartolina`) colado ao topo da área de conteúdo, com cantos superiores arredondados (`AppRadius.separador`) e o resto reto. É a única forma "decorativa" da app e é sempre informativa: diz em nome de quem se está a ver.
3. **Serifa nos títulos e nos números, sans legível no resto.** Títulos, nomes de escritórios e contagens em Source Serif 4; interface e corpo em Atkinson Hyperlegible Next; datas, versões e registos em Atkinson Hyperlegible Mono.
4. **O carimbo.** Estados (Ativo, Pendente, Recusado, Retirado) são etiquetas retangulares de canto quase reto (`AppRadius.carimbo`), com ícone + palavra, contorno de 1.5 na cor do estado e fundo `folha`. Parecem carimbos num processo, não "pills" de app.
5. **Réguas em vez de cartões.** Listas separadas por linhas finas (`regua`), sem sombras. Só há superfície elevada (`folha`) em formulários, folhas laterais e diálogos.
6. **A voz.** Frases curtas, verbos concretos, datas sempre por extenso curto ("26 nov 2026, 14:32"). Cada ação sensível diz o que acontece a seguir.

## Design system

Caminhos onde os tokens e widgets vão viver (o flutter-dev cria-os na feature 001):

- Tokens: `lib/core/design/tokens.dart` (classes `AppColors`, `AppSpace`, `AppRadius`, `AppStroke`, `AppSize`, `AppBreakpoints`)
- Tipografia: `lib/core/design/typography.dart` (`AppType`, com os estilos abaixo)
- Motion spec: `lib/core/design/motion.dart` (`AppMotion`); a especificação está na secção "Motion" deste ficheiro
- Tema: `lib/core/design/app_theme.dart` (`ThemeData` construído só a partir dos tokens; Material 3 como motor, nunca como aspeto)
- Widgets partilhados: `lib/core/widgets/` (lista em "Componentes partilhados")
- Fontes: `assets/fonts/` (ficheiros .ttf incluídos no projeto, licença OFL; **sem** o pacote `google_fonts`, para funcionar offline e nos golden tests)

### Cores (só tema claro na fase 1)

| Token | Hex | Uso | Contraste |
| --- | --- | --- | --- |
| `papel` | #F6F3EC | Fundo de todos os ecrãs | n/a |
| `folha` | #FDFCF9 | Superfícies: formulários, folhas laterais, diálogos, fundo dos carimbos | n/a |
| `cartolina` | #EADBB2 | Separador de pasta. Só texto `tinta` ou `tintaMedia` por cima | tinta 12.1, tintaMedia 6.5 |
| `realce` | #F3E6C4 | Fundo de linha acabada de criar/alterar (desvanece) e de aviso informativo | tinta 13.5 |
| `tinta` | #1B1E24 | Texto principal, botão principal cheio, faixa de offline | 15.1 sobre papel |
| `tintaMedia` | #454A55 | Texto secundário (emails, explicações) | 8.0 sobre papel |
| `tintaTenue` | #62666F | Metadados (datas, versões, contagens pequenas). Nunca sobre `cartolina` | 5.2 sobre papel |
| `regua` | #D8D1C1 | Divisores de lista e de secção | decorativo |
| `reguaForte` | #8E8778 | Contorno de campos e de botões secundários | 3.2 (não texto, mínimo 3) |
| `foco` | #8F6200 | Anel de foco de teclado (2 de espessura, 2 de afastamento) | 4.8 |
| `estadoAtivo` | #2E6A4E | Carimbo "Ativo" | 6.2 sobre folha |
| `estadoPendente` | #7F5600 | Carimbo "Pendente", avisos | 6.3 sobre folha |
| `estadoInativo` | = `tintaTenue` | Carimbos "Recusado" e "Retirado" | 5.6 sobre folha |
| `erro` | #A3311C | Erros de campo, ação destrutiva ("Retirar acesso") | 6.3 sobre papel |
| `sobreTinta` | = `papel` | Texto sobre botão cheio e faixa offline | 15.1 |
| `esqueleto` | #ECE7DB | Blocos de skeleton | n/a |

Regra: verde só para "Ativo". Ocre só para "Pendente" e avisos. Vermelho-lacre só para erro e retirar. Nenhuma outra cor entra sem passar por aqui.

### Tipografia

Famílias: **Source Serif 4** (títulos, nomes, números), **Atkinson Hyperlegible Next** (interface e corpo; desenhada para baixa visão, o que justifica acrescentar uma fonte), **Atkinson Hyperlegible Mono** (datas, versões, registos). Números tabulares em contagens e datas.

| Token | Família | Tamanho / altura de linha | Peso | Uso |
| --- | --- | --- | --- | --- |
| `numero` | Serif | 56 / 60 | 500 | Contagens do admin |
| `titulo` | Serif | 30 / 36 (compacto: 26 / 32) | 600 | Título do ecrã, nome do escritório no consentimento |
| `subtitulo` | Serif | 21 / 28 | 600 | Nome do escritório numa linha de lista, título de diálogo |
| `corpoForte` | Sans | 17 / 26 | 600 | Nome do cliente na lista, frase-chave |
| `corpo` | Sans | 17 / 26 | 400 | Texto corrido, campos |
| `corpoPequeno` | Sans | 15 / 22 | 400 | Emails, explicações secundárias |
| `rotulo` | Sans | 14 / 20 | 600, +0.2 de espaçamento | Rótulos de campo, cabeçalhos de coluna e de grupo, texto de botão secundário |
| `botao` | Sans | 17 / 24 | 600 | Texto de botões |
| `carimbo` | Sans | 13 / 16 | 700, +0.6, maiúsculas | Texto dentro dos carimbos de estado |
| `registo` | Mono | 13 / 18 | 400 | Datas, versão do texto, horas de envio |

A escala de texto do sistema é respeitada até 1.3 sem cortar ações; acima disso o texto pode fazer scroll, os botões nunca saem do ecrã.

### Espaço, raios, traços e tamanhos

- `AppSpace`: `s4`=4, `s8`=8, `s12`=12, `s16`=16, `s24`=24, `s32`=32, `s48`=48, `s72`=72. Ritmo: 8 dentro de um componente, 16 a 24 entre elementos de um grupo, 48 entre grupos, 72 acima do título em largo.
- `AppRadius`: `carimbo`=3, `controlo`=6 (botões, campos), `superficie`=10 (folhas, diálogos), `separador`=10 só nos cantos superiores. Listas e linhas não têm raio.
- `AppStroke`: `fino`=1 (réguas), `controlo`=1.5 (campos, botão secundário, carimbos), `foco`=2.
- `AppSize`: `alvoMinimo`=48, `alvoPrincipal`=56 (ações principais do cliente), `campo`=52, `larguraLeitura`=640 (texto de consentimento, formulários), `larguraLista`=1040, `folhaLateral`=440, `separadorAltura`=40.
- `AppBreakpoints`: `compacto` < 640, `medio` 640 a 1100, `largo` > 1100. Margens laterais: 16 / 32 / 48.
- Sombras: nenhuma, exceto diálogos e folhas laterais (`sombraSuperficie`: 0 8 24, tinta a 12%). Cartões com elevação estão proibidos.

## Motion

Princípio: só se move o que mudou de estado, e o movimento mostra de onde vem e para onde vai. Nada de animações de entrada em ecrãs inteiros, nada decorativo. Com `MediaQuery.disableAnimations` (ou "reduzir movimento"), todas as durações passam a 0 e os desvanecimentos passam a corte seco; nenhuma informação se perde.

| Token | Valor | Uso |
| --- | --- | --- |
| `AppMotion.rapido` | 120 ms | Hover, pressão, foco, troca de texto num botão |
| `AppMotion.base` | 200 ms | Mudança de carimbo, aparecer/desaparecer de faixas e mensagens inline |
| `AppMotion.lento` | 320 ms | Folha lateral/inferior a entrar, linha a mudar de grupo |
| `AppMotion.realce` | 1600 ms | Desvanecer do fundo `realce` de uma linha acabada de alterar |
| `AppMotion.pulsar` | 1200 ms (ida e volta) | Opacidade do skeleton 1.0 a 0.55; nunca shimmer |
| `AppMotion.entrar` | `Curves.easeOutCubic` | Tudo o que aparece |
| `AppMotion.sair` | `Curves.easeInCubic` | Tudo o que sai |
| `AppMotion.mudar` | `Curves.easeInOutCubic` | Mudanças de estado e de posição |

## Componentes partilhados

A criar em `lib/core/widgets/` na feature 001:

- `FolderTab` (separador de pasta com o contexto), `FolderTabs` (dois ou mais separadores escolhíveis, 50/50, `alvoMinimo` 48: o ativo em `cartolina`, os inativos em `papel` com contorno `regua` e texto `tintaMedia`; usado em Entrar para "Sou cliente" e "Trabalho num escritório"), `PageFrame` (papel + separador + margens por breakpoint + largura máxima).
- `StatusStamp` (carimbo: ativo, pendente, recusado, retirado; ícone + palavra, nunca só cor).
- `PrimaryButton` (cheio a tinta, spinner só aqui dentro), `SecondaryButton` (contorno `reguaForte` 1.5), `DestructiveButton` (cheio a `erro`), `TextAction` (sublinhado, para ações de linha).
- `LabeledField` (rótulo por cima, nunca só placeholder; erro por baixo com ícone).
- `RuledList` / `RuledRow` (lista com réguas), `SkeletonRows`.
- `OfflineBar` (faixa a tinta no topo), `InlineNotice` (mensagem dentro do fluxo, com ação), `ConfirmSheet` (folha inferior em compacto, diálogo em médio/largo).

## Regras

- Valores sempre via tokens, nunca soltos.
- Skeleton em listas; spinner só dentro de botões.
- Uma ação principal por ecrã. Em decisões do cliente sobre os seus dados (aceitar/recusar), as duas opções têm o mesmo tamanho e a mesma posição de destaque: o "não" nunca é um link pequeno.
- Estados com ícone + palavra. A cor reforça, nunca é o único sinal.
- Botão desativado tem sempre a razão escrita por baixo ("Sem ligação. Tente quando voltar a ligação.").
- Nunca mostrar como feito algo que o servidor não confirmou (sem updates otimistas em consentimento).
- Erros dizem o que aconteceu e o que fazer, em PT-PT, sem códigos técnicos.
- Nomes e emails longos: uma linha com reticências em listas; o nome completo aparece no foco/hover (tooltip) e na leitura de ecrã.
- Datas: "26 nov 2026" e "26 nov 2026, 14:32", em `registo`. Nada de "há 3 dias" em consentimento (tem de ser verificável).
- Ícones: Material Symbols Outlined (já incluídos no Flutter), traço uniforme, sempre com etiqueta visível quando o significado não é óbvio. Sem emoji.
- Nenhum `AppBar`, `Card`, `FloatingActionButton` ou `ListTile` com estilo por defeito a definir o aspeto de um ecrã.
- Admin: nunca mostrar nome nem email de pessoas, nem em tooltips.

## Referências

| App ou site | O que vale a pena roubar |
| --- | --- |
| GOV.UK Design System | Copy franca, uma pergunta por página, botões grandes, erros que dizem o que fazer |
| Gov.pt / Autenticação.gov (fluxo de consentimento de atributos) | Mostrar quem pede e o que vai ver antes do "Autorizar" |
| Linear (listas) | Densidade de tabela com réguas finas e estados discretos |
| Pastas de arquivo em cartolina | O separador como forma de contexto, a cor manila como único acento |

## Rejeitado

| Data | O quê | Porquê |
| --- | --- | --- |

(Só rejeições do Henrique em gates. As direções descartadas pelo designer ficam no `03-design.md` de cada feature.)
