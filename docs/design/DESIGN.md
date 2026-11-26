# DESIGN.md: direção de arte

> Fonte de verdade do agente designer. Os tokens e componentes vivem no design system; aqui fica a intenção, as regras e o que já foi rejeitado.
> Estado: **aprovada no gate 2 da feature 001** (2026-11-26), incluindo as fontes. Revista no mesmo dia para a decisão **web-first e responsiva** (`docs/decisions.md`). Os tokens existem em `lib/core/design/`; os marcados "(proposto)" ainda não, e o flutter-dev cria-os. Nenhum ecrã usa valores soltos: se faltar um token, propõe-se aqui primeiro.

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

Todos entram pelo navegador, sem instalar nada. Clientes e mediadores usam telemóvel, tablet e desktop e cada ecrã deles é desenhado nos três tamanhos com a mesma qualidade (ver "Responsividade (web)").

- **Mediadores** (horas seguidas, muitos clientes; sobretudo desktop no escritório, mas também tablet e telemóvel na rua): densidade média, tabelas legíveis no desktop e no tablet, lista empilhada no telemóvel, ações onde o olho já está, teclado a funcionar (Tab, Enter, Esc).
- **Clientes** particulares e empresas (muitas vezes telemóvel, abrindo o link do email; alguns com pouca destreza digital ou mais velhos): texto base 17, alvos de toque de 48 no mínimo e 56 nas ações principais em todos os tamanhos, uma decisão por ecrã, nenhuma informação só por cor ou só por movimento, sem gestos escondidos (nada de swipe para retirar).
- **Admin** (o Henrique): desktop-first, mas utilizável em tablet e telemóvel (empilha, não esconde). Poucos números, nenhum dado pessoal no ecrã.
- Tratamento: **formal na 3.ª pessoa** ("Pode retirar quando quiser"), nunca "tu". É o registo esperado em seguros em Portugal e o mais seguro para clientes mais velhos.

## Assinatura visual

O que torna a app reconhecível num screenshot sem logótipo:

1. **Papel e tinta.** Fundo cor de papel (`papel`), texto quase preto (`tinta`), e a ação principal é um botão cheio a tinta. Não há "cor de marca" a pintar botões: a autoridade vem do contraste, não do azul.
2. **O separador de pasta.** O contexto do ecrã (o escritório, "Os meus dados" no cliente, ou "Acesso" antes de haver sessão) aparece num separador cor de cartolina (`cartolina`) colado ao topo da área de conteúdo, com cantos superiores arredondados (`AppRadius.separador`) e o resto reto. Por baixo, uma régua `regua` corre a largura da moldura (1040 em largo), mesmo quando a coluna é mais estreita: é a borda da pasta. O separador é a primeira linha do ecrã: não há cabeçalho nem marca por cima nos ecrãs com sessão; "Sair" (e o nome, onde couber) fica na mesma linha, encostado à direita da moldura e centrado com o separador. Sem sessão, o separador diz "Acesso". É a única forma "decorativa" da app e é sempre informativa: diz em nome de quem se está a ver. A marca não vive aqui: vive no colofão (ponto 7).
3. **Serifa nos títulos e nos números, sans legível no resto.** Títulos, nomes de escritórios e contagens em Source Serif 4; interface e corpo em Atkinson Hyperlegible Next; datas, versões e registos em Atkinson Hyperlegible Mono.
4. **O carimbo.** Estados (Ativo, Pendente, Recusado, Retirado) são etiquetas retangulares de canto quase reto (`AppRadius.carimbo`), com ícone + palavra, contorno de 1.5 na cor do estado e fundo `folha`. Parecem carimbos num processo, não "pills" de app.
5. **Réguas em vez de cartões.** Listas separadas por linhas finas (`regua`), sem sombras. Só há superfície elevada (`folha`) em formulários, folhas laterais e diálogos.
6. **A voz.** Frases curtas, verbos concretos, datas sempre por extenso curto ("26 nov 2026, 14:32"). Cada ação sensível diz o que acontece a seguir.
7. **O colofão** (escolhido pelo Henrique a 2026-11-26). A página acaba como a última folha de um livro: uma régua `regua` à largura da moldura e, por baixo, o wordmark "*Pro*Dossier", uma linha que diz de quem é o que se está a ver e, onde houver, uma data de registo. É o único sítio onde a marca aparece na app (também no fim dos emails). Nunca é cabeçalho, nunca é fixo, nunca compete com o conteúdo: está depois dele.

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
| `sombra` | #1B1E24 a 12% (0x1F1B1E24) | Cor da sombra `AppShadow.superficie` | n/a |
| `veu` | #1B1E24 a 40% (0x661B1E24) | Véu atrás de diálogos, folhas inferiores e folhas laterais (`scrim`) | n/a |
| `nenhuma` | transparente (0x00000000) | Ponto de partida/chegada ao animar um fundo (ex.: `realce` a desvanecer) e para anular tints, hover e highlight do Material. Nunca como "cor" visível | n/a |

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
| `marca` | Serif | 19 / 24, -0.2 de espaçamento | "Pro" 400 itálico `tintaMedia` + "Dossier" 600 `tinta` | Só o wordmark "ProDossier" (colofão, emails). Lido como uma palavra pela leitura de ecrã |

A escala de texto do sistema é respeitada até 1.3 sem cortar ações; acima disso o texto pode fazer scroll, os botões nunca saem do ecrã.

### Espaço, raios, traços e tamanhos

- `AppSpace`: `s4`=4, `s8`=8, `s12`=12, `s16`=16, `s24`=24, `s32`=32, `s48`=48, `s72`=72. Ritmo: 8 dentro de um componente, 16 a 24 entre elementos de um grupo, 32 da régua do separador ao título, 48 entre grupos. Topo da janela ao separador: `s16` em compacto, `s24` em médio/largo (não há linha de cabeçalho). `s72` é a distância do fim do conteúdo à régua do colofão em médio/largo (`s48` em compacto); não volta a ser usado como vazio acima de formulários (rejeitado).
- `AppRadius`: `carimbo`=3, `controlo`=6 (botões, campos), `superficie`=10 (folhas, diálogos), `separador`=10 só nos cantos superiores. Listas e linhas não têm raio.
- `AppStroke`: `fino`=1 (réguas), `controlo`=1.5 (campos, botão secundário, carimbos), `foco`=2, `focoAfastamento`=2 (distância entre o controlo e o anel de foco).
- `AppSize`: `alvoMinimo`=48, `alvoPrincipal`=56 (ações principais do cliente em todos os tamanhos; de mediador e admin em compacto), `campo`=52, `larguraLeitura`=640 (texto de consentimento, listas de leitura do cliente, diálogo só de leitura), `larguraLista`=1040 (também largura máxima da moldura em largo), `folhaLateral`=440, `separadorAltura`=40, `icone`=24 (ícones de interface: resumo do consentimento, spinner), `iconePequeno`=18 (ícones dentro de carimbos, campos, avisos e botões), `dialogo`=480 (diálogo de confirmação em médio/largo).
- `AppSize` (proposto, para a feature 001): `larguraFormulario`=400 (coluna de Entrar, recuperar/definir/criar palavra-passe, link expirado; largura máxima do separador de pasta em médio/largo), `textoMinimo`=240 (largura mínima da zona de texto de uma linha antes de passar ao layout seguinte, mais empilhado), `linhaTabela`=72 (altura mínima de linha de tabela), `colunaEstado`=140, `colunaData`=248 (também a coluna Estado + data da tabela em médio; revisto de 200 nos renders da tarefa 4b: "Recusado a 20 nov 2026, 09:12" em `registo` mede 238), `colunaAcao`=160.
- `AppBreakpoints`: `compacto` < 640 (telemóvel), `medio` 640 a 1100 (tablet), `largo` > 1100 (desktop). 640 exato já é médio (a decisão diz "até 640"; 1 px sem efeito prático). Margens laterais: 16 / 32 / 48. Proposto: `alturaBaixa`=480 (altura da janela abaixo da qual as barras fixas encolhem: telemóvel deitado).
- Sombras: nenhuma, exceto diálogos, folhas inferiores e folhas laterais (`AppShadow.superficie`: deslocamento 0 8, desfoque 24, cor `sombra`). Cartões com elevação estão proibidos.

## Motion

Princípio: só se move o que mudou de estado, e o movimento mostra de onde vem e para onde vai. Nada de animações de entrada em ecrãs inteiros, nada decorativo. Com `MediaQuery.disableAnimations` (ou "reduzir movimento"), todas as durações passam a 0 e os desvanecimentos passam a corte seco; nenhuma informação se perde.

| Token | Valor | Uso |
| --- | --- | --- |
| `AppMotion.rapido` | 120 ms | Hover, pressão, foco, troca de texto num botão |
| `AppMotion.base` | 200 ms | Mudança de carimbo, aparecer/desaparecer de faixas e mensagens inline |
| `AppMotion.lento` | 320 ms | Folha lateral/inferior a entrar, linha a mudar de grupo |
| `AppMotion.realce` | 1600 ms | Desvanecer do fundo `realce` de uma linha acabada de alterar |
| `AppMotion.pulsar` | 1200 ms (ida e volta) | Opacidade do skeleton 1.0 a `pulsarMinimo`; nunca shimmer |
| `AppMotion.pulsarMinimo` | 0.55 | Opacidade mínima do skeleton |
| `AppMotion.escalaDialogo` | 0.98 | Escala inicial do diálogo de confirmação (0.98 a 1.0, em `base`) |
| `AppMotion.entrar` | `Curves.easeOutCubic` | Tudo o que aparece |
| `AppMotion.sair` | `Curves.easeInCubic` | Tudo o que sai |
| `AppMotion.mudar` | `Curves.easeInOutCubic` | Mudanças de estado e de posição |

## Componentes partilhados

A criar em `lib/core/widgets/` na feature 001:

- `FolderTab` (separador de pasta com o contexto), `PageFrame` (papel + `s16`/`s24` de topo + linha do separador com a conta à direita + régua à largura da moldura + margens por breakpoint + largura máxima). `FolderTabs` (separadores escolhíveis) deixou de ser usado a 2026-11-26, quando Entrar passou a um só formulário para todos os perfis; não se usa separadores de pasta como controlo de navegação sem uma razão nova.
- `StatusStamp` (carimbo: ativo, pendente, recusado, retirado; ícone + palavra, nunca só cor).
- `PrimaryButton` (cheio a tinta, spinner só aqui dentro), `SecondaryButton` (contorno `reguaForte` 1.5), `DestructiveButton` (cheio a `erro`), `TextAction` (sublinhado, para ações de linha).
- `LabeledField` (rótulo por cima, nunca só placeholder; erro por baixo com ícone).
- `RuledList` / `RuledRow` (lista com réguas), `SkeletonRows`.
- `OfflineBar` (faixa a tinta no topo), `InlineNotice` (mensagem dentro do fluxo, com ação), `ConfirmSheet` (folha inferior em compacto, diálogo de `dialogo` 480 em médio/largo; variante só de leitura: folha alta em compacto, diálogo de `larguraLeitura` 640 em médio/largo).
- `PageFrame` em largo: moldura de `larguraLista` 1040 centrada na janela; a barra fixa de baixo (`bottom`) tem o fundo à largura da janela e o conteúdo alinhado com a coluna do ecrã.
- `Wordmark` ("ProDossier" em `AppType.marca`, com `semanticsLabel` "ProDossier") e `Colophon` (régua + wordmark + linha de identidade + registo opcional). O `PageFrame` desenha o `Colophon` como último elemento do scroll, depois do conteúdo; quando o conteúdo é mais curto do que a janela, o colofão fica encostado ao fundo dela. Regras em "Colofão".

## Colofão

Decisão do Henrique (2026-11-26), entre três propostas (as outras duas estão em "Rejeitado").

- **Onde:** em todos os ecrãs de página (sem sessão, cliente, mediador, admin), como último elemento do scroll do `PageFrame`, depois do conteúdo e antes de qualquer barra fixa. Nunca dentro de folhas, diálogos ou formulários em ecrã inteiro do compacto (são passagens, não páginas); por trás de um véu continua onde está.
- **Composição:** a `s72` do fim do conteúdo (`s48` em compacto), régua `regua` `fino` à largura da moldura (como a da pasta, mesmo quando a coluna é 400 ou 640); a `s16` dela, numa linha alinhada pela base: `Wordmark` (`marca`), a `s16` a linha de identidade em `corpoPequeno` `tintaMedia`, a `s16` o registo em `registo` `tintaTenue`. Por baixo, `s32` (`s24` em compacto) até ao fim da página. Em compacto, ou quando a linha não cabe (escala 1.3), os três empilham à esquerda com `s4`. Sem ícones, sem ligações, sem versão nem copyright.
- **Linha de identidade e registo por perfil:** sem sessão "O dossiê dos seus seguros, partilhado só com quem autorizar." (sem registo); cliente "Dossiê de {nome}" + "Aberto a {data de criação da conta}"; mediador "{nome}, {escritório}" + "Na equipa desde {data de entrada no escritório}"; admin "Administração da plataforma" (sem nome nem registo, pela regra de privacidade do admin).
- **Altura da janela:** quando o conteúdo é curto, o colofão encosta ao fundo da janela; quando é longo, só aparece no fim do scroll. Nunca fixo, nunca sobreposto ao conteúdo.
- **Estados:** a carregar (cliente e mediador), só o wordmark até o perfil chegar, e a linha entra em `base` / `entrar` (nunca skeleton no colofão); erro, vazio e offline não mudam o colofão (a `OfflineBar` fica no topo).
- **Fora da app:** emails transacionais acabam com o mesmo colofão em texto (wordmark em serifa com alternativa Georgia, a frase sem sessão e "Enviado a {data, hora}"); o ecrã de arranque (enquanto a sessão é lida) é `papel` vazio com o colofão sem sessão no fundo, sem nada ao centro e sem animação.

## Responsividade (web)

Decisão de 2026-11-26: a app é usada no navegador. Regras para todos os ecrãs de cliente e de mediador (o admin segue-as no "utilizável"):

- **Três composições explícitas por ecrã** (compacto, médio, largo), escritas no `03-design.md` da feature com: colunas e larguras máximas, o que muda de sítio, alvos, rato, teclado e foco, conta e navegação, folhas e diálogos. Nenhum ecrã de cliente ou mediador tem um tamanho "primeiro"; não há "versão desktop esticada" nem "versão telemóvel encolhida".
- **Largura lógica da janela decide**, não o tipo de aparelho: zoom de 200% num desktop dá compacto; tablet deitado dá largo. Largura mínima suportada 320 sem scroll horizontal.
- **Moldura:** em largo, centrada com máximo `larguraLista`; dentro dela tudo alinha à esquerda (nada de colunas centradas), incluindo os formulários de entrada (nunca deslocados para uma fração da janela). Colunas de leitura e formulários mantêm a sua largura máxima (`larguraLeitura`, `larguraFormulario`) e deixam o resto em `papel` vazio, sem encher com decoração.
- **Layout por espaço disponível:** linhas e tabelas descem para uma forma mais empilhada quando a zona de texto fica abaixo de `textoMinimo`, seja por breakpoint, escala de texto ou zoom.
- **Alvos não encolhem em largo** (há toque em tablets deitados e portáteis táteis): 48 mínimo em todos os tamanhos.
- **Rato:** cursor de clique e hover só como reforço; nenhuma informação só em hover. Tooltips abrem também com foco e toque longo. Razão de botão desativado sempre escrita, não só em tooltip.
- **Teclado:** ordem de Tab = ordem de leitura; anel `foco` só com navegação por teclado; Enter submete formulários; Esc fecha folhas e diálogos; foco preso em folhas e diálogos e devolvido ao botão de origem. Em decisões do cliente não há botão por defeito.
- **Navegador:** cada ecrã tem endereço; "voltar" fecha primeiro a folha ou o diálogo; texto de consentimento, nomes e emails selecionáveis.
- **Teclado virtual:** campo com foco e botão de envio visíveis acima dele; sem foco automático em compacto; em formulários de ecrã inteiro (compacto) os botões vão no fluxo, não fixos.
- **Folhas e diálogos:** compacto = folha inferior (decisões, leitura) ou ecrã inteiro (formulários); médio e largo = diálogo centrado (decisões, leitura) ou folha lateral de `folhaLateral` (formulários).
- **Conta e navegação:** sem AppBar, sem barra de navegação e sem linha de cabeçalho em nenhum tamanho enquanto cada perfil tiver poucos ecrãs; a conta vive na linha do separador (compacto: só "Sair", com o nome na leitura de ecrã; médio/largo: nome + "Sair").
- **Goldens:** cada ecrã de cliente e mediador a 390 × 844, 768 × 1024 e 1280 × 800, escala 1.0 e 1.3.

## Regras

- Valores sempre via tokens, nunca soltos.
- Skeleton em listas; spinner só dentro de botões.
- Uma ação principal por ecrã. Em decisões do cliente sobre os seus dados (aceitar/recusar), as duas opções têm o mesmo tamanho e a mesma posição de destaque: o "não" nunca é um link pequeno.
- Estados com ícone + palavra. A cor reforça, nunca é o único sinal.
- Botão desativado tem sempre a razão escrita por baixo ("Sem ligação. Tente quando voltar a ligação.").
- Nunca mostrar como feito algo que o servidor não confirmou (sem updates otimistas em consentimento).
- Erros dizem o que aconteceu e o que fazer, em PT-PT, sem códigos técnicos.
- Nomes e emails longos: em médio/largo, uma linha com reticências em tabelas; em compacto, até 2 linhas (emails quebram em qualquer caractere) e só depois reticências. O texto completo aparece no tooltip (hover, foco e toque longo) e na leitura de ecrã.
- Datas: "26 nov 2026" e "26 nov 2026, 14:32", em `registo`. Nada de "há 3 dias" em consentimento (tem de ser verificável).
- Ícones: Material Symbols Outlined (já incluídos no Flutter), traço uniforme, sempre com etiqueta visível quando o significado não é óbvio. Sem emoji.
- Nenhum `AppBar`, `Card`, `FloatingActionButton` ou `ListTile` com estilo por defeito a definir o aspeto de um ecrã.
- Admin: nunca mostrar nome nem email de pessoas, nem em tooltips.
- Palavra-passe: mínimo 10 caracteres com maiúscula, minúscula, número e carácter especial, sem campo de confirmação ("Mostrar" no campo). As regras estão sempre visíveis por baixo do campo e mudam em tempo real com ícone + texto (por cumprir `circle_outlined`, cumprida `check_circle`, em erro `error_outline` a `erro`). O botão de guardar nunca fica desativado por causa das regras: ao carregar, o erro diz quantas faltam.
- Mudança de ecrã: cross-fade `base` (entra `entrar`, sai `sair`); nada desliza entre ecrãs. Só folhas laterais e inferiores se deslocam, porque têm um sítio de onde vêm.
- Entrada: um só formulário (email + palavra-passe) para todos os perfis; o link mágico é alternativa do cliente, com `SecondaryButton` à largura da coluna e "Só para clientes." escrito, nunca um link pequeno. Convites opcionais (ex.: criar palavra-passe) têm "Agora não" como `SecondaryButton` do mesmo tamanho, e nunca aparecem antes de uma decisão de consentimento.

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
| 2026-11-26 | Marca "ProDossier" visível num cabeçalho por cima do separador, com "Sair" à parte | Parecia nota de rodapé e o "Sair" flutuava sem relação; a marca sai dos ecrãs com sessão e a conta passa para a linha do separador |
| 2026-11-26 | Marca na "etiqueta da lombada": wordmark em serifa no separador sem sessão e monograma "pD" num campo próprio do separador com sessão | Proposta de marca não escolhida (o Henrique escolheu o colofão); não pôr a marca no separador |
| 2026-11-26 | Marca como "selo de registo": carimbo a tinta, contorno duplo e inclinado, com "PRODOSSIER" e a data, nos momentos registados (link enviado, consentimento, acesso retirado) | Proposta de marca não escolhida (o Henrique escolheu o colofão); não usar selos de marca nos avisos |
| 2026-11-26 | Vazio entre a linha do topo (marca + conta) e o separador de pasta: 24 + 16 nos ecrãs de lista e mais 32 / 48 / 72 nos formulários de entrada | Demasiado espaço vertical; o separador tem de ficar colado ao cabeçalho, como uma pasta |

(Só rejeições do Henrique em gates. As direções descartadas pelo designer ficam no `03-design.md` de cada feature.)
