# 03 Design: 002 Novo pedido (mediador) + clientes com o estado dos pedidos

> Estado: **proposta para o gate 2** (2026-11-27). Renders em `renders/` (índice em `renders/README.md`).
> Classificação: **refinamento com extensão**. A identidade da 001 ("Dossiê arrumado", aprovada a 2026-11-26) mantém-se tal como está: papel e tinta, separador de pasta, carimbos, réguas, colofão. A 002 acrescenta quatro peças novas a esse vocabulário (a lista de tipos, a folha "O cliente vai receber", o trilho/faixa de etapas e o sino) e mexe em dois ecrãs da 001 (Clientes e o ecrã inicial do cliente). Nenhuma fonte, cor ou dependência nova.
> Fonte do âmbito: `02-spec.md` (gate 1 fechado a 27/11). Catálogo: `docs/reference/tipos-de-seguro.md`. O protótipo antigo foi usado só como referência de fluxo (grelha de 13 tipos, caixa de condições particulares, "O cliente vai receber" ao lado).

## Diagnóstico

- **Tarefa principal:** o mediador cria, em menos de 1 minuto, os pedidos certos para um cliente e vê a lista exata que ele vai receber; o cliente percebe, no telemóvel, o que lhe pedem e em que ponto está.
- **O que falharia com o default:** um assistente em 5 passos com stepper do Material (esconde a lista enquanto se escolhem tipos), uma grelha de 13 cartões iguais com ícones (o protótipo), chips para os tipos, um Badge vermelho sobreposto ao sino e um "Stepper" horizontal com bolinhas para as etapas. Tudo isto parece app genérica e nada disto diz "dossiê".

## Direção

- **Escolhida: "A folha que vai para a pasta".** O Novo pedido é um formulário de papel com secções numeradas (1 Cliente, 2 Tipos de seguro, 3 Condições particulares, 4 Mensagem) e, ao lado (largo) ou por baixo (médio e compacto), a **folha** que o cliente vai receber, uma por tipo, editável ali mesmo (tirar e acrescentar itens). A folha usa a superfície `folha` com régua e raio `superficie`, sem sombra: é o único elemento "cartão" do ecrã e é-o porque representa literalmente uma folha. O estado dos pedidos é sempre texto ("Etapa 1 de 4: Pedido criado") reforçado por um **trilho** de 4 segmentos nas listas e por uma **faixa de 4 colunas com réguas** no pedido aberto (o mesmo vocabulário das contagens do admin).
- **Porquê:** responde à pergunta que o mediador faz antes de carregar em "Criar" ("o que é que o cliente vai ver?") sem mudar de ecrã, e dá ao cliente a mesma folha, com o mesmo aspeto, quando abre o pedido. Mantém uma ação principal por ecrã ("Criar N pedidos", sempre visível numa barra fixa) e não introduz cor: os estados continuam a ser palavra + forma.
- **Descartadas:**
  1. *Assistente em passos* (cliente → tipos → lista → mensagem → confirmar, com stepper): a mais previsível; esconde a lista enquanto se escolhem os tipos e transforma 1 minuto em 5 ecrãs.
  2. *Grelha de 13 cartões de tipo com ícones + painel geral de pedidos em colunas por etapa (kanban)*: é a cara de IA (cartões iguais com ícone) e o painel geral está fora de âmbito (decisão 7 do gate 1).

## Fixtures (renders e goldens)

- Escritório "Ribeira Seguros"; mediadora "Ana Martins" (na equipa desde 3 nov 2026). Outros escritórios do cliente: "Gabinete de Mediação de Seguros Vale do Sousa & Filhos, Lda." (caso longo), "Seguros Lima & Viana (exemplo)" (acesso retirado).
- Cliente principal: "Maria do Carmo Figueiredo", `maria.figueiredo@exemplo.pt`, ativa desde 12 nov 2026, 10:04. Pedidos: Automóvel e Vida (27 nov 2026, 10:14, com condições particulares), Multirriscos Habitação (20 nov 2026, 16:40, em curso: dispara o aviso de pedido repetido), Acidentes de Trabalho (prémio variável), Saúde.
- Lista editada (Automóvel): tirado "Franquias (danos próprios)"; acrescentado "Fotografias do veículo (frente, traseira e lados)" (Documento).
- Mensagem: "Bom dia, D. Maria. Para a renovação do seguro automóvel e para o novo seguro de vida, preciso destes elementos até ao fim do mês. Qualquer dúvida, ligue-me." (156 caracteres).
- Restantes clientes da lista: os da 001 (pendentes, recusado, ativos), com "Sem pedidos" e "1 em curso" para variar.

## Estrutura comum (o que muda em relação à 001)

- **Ligação de regresso** (`TextAction` com `arrow_back`, alvo 48) por cima da linha do separador, a `s8` dela, como no consentimento da 001: Novo pedido ("Clientes" ou o nome do cliente, conforme a origem), Ficha ("Clientes"), Pedido aberto (nome do cliente no mediador, "Os meus pedidos" no cliente), Notificações em compacto ("Os meus pedidos"). Clientes e Os meus pedidos não têm (são ecrãs iniciais).
- **Sino na linha do separador (só cliente):** entre o separador e "Sair", a `s8` de "Sair". Médio/largo: ícone `notifications_none` (24) + palavra "Notificações" (`TextAction`, sublinhada) + contador; compacto: ícone + contador (a palavra está na leitura de ecrã e no tooltip). Contador: retângulo `tinta` com texto `sobreTinta` em `AppType.carimbo` (13, 700, tabular), altura e largura mínima `iconePequeno` 18, padding `s4` dos lados, raio `carimbo`, **ao lado** do ícone/palavra e nunca sobreposto (não é um Badge do Material). Oculto a 0; "9+" acima de 9. Com o painel aberto, o alvo fica com fundo `cartolina` (raio `controlo`), a mesma cor do separador: diz "está aberto aqui".
- **Colofão:** igual à 001 em todos os ecrãs de página. Não aparece dentro da folha de notificações nem no ecrã inteiro de notificações em compacto (passagem, não página).
- **Barra fixa do Novo pedido:** como a barra do consentimento da 001 (fundo `folha`, régua em cima, fundo à largura da janela, conteúdo na moldura), com o resumo à esquerda e a ação à direita.

## Ecrãs

### 1. Novo pedido [mediador; compacto, médio e largo]

Rota própria (`/clientes/novo-pedido` ou `/clientes/{id}/novo-pedido`). Vindo da ficha ou da linha de um cliente, o cliente já vem escolhido; vindo do botão "Novo pedido" de Clientes, começa pela escolha.

- **Hierarquia:** 1.º o título e a escolha (cliente e tipos); 2.º a folha "O cliente vai receber"; 3.º condições particulares, mensagem e o resumo da barra. A ação "Criar N pedidos" está sempre visível na barra fixa.
- **Composição:**
  - Cabeçalho: regresso, separador "Ribeira Seguros", título "Novo pedido" (`titulo`), apoio em `corpo` `tintaMedia` (coluna `larguraLeitura`).
  - **Escolhas** (a `s48` do apoio), quatro secções com cabeçalho em `subtitulo` precedido do número em `subtitulo` `tintaTenue` (coluna de `s16` + `s12`; o corpo da secção alinha pelo texto do título em médio/largo e encosta à margem em compacto). `s32` entre secções.
    1. **Cliente.** Escolhido: caixa `folha` com régua e raio `controlo`, nome `corpoForte` + email `corpoPequeno` `tintaMedia` (quebra em qualquer caractere), `TextAction` "Mudar" à direita. Por escolher: `LabeledField` "Procurar por nome ou email" com pesquisa (ícone `search`) e, por baixo, a lista de opções no fluxo (não sobreposta): superfície `folha`, contorno `reguaForte` 1.5, opções com régua (nome `corpoForte` + email, a parte que coincide sublinhada), opção ativa com fundo `realce`, e no fim, sempre, "Só aparecem clientes que aceitaram partilhar os dados com este escritório." Teclado: setas mudam a opção, Enter escolhe, Esc fecha.
    2. **Tipos de seguro** + apoio "É criado um pedido por tipo.". Lista de verificação com réguas pela ordem do catálogo: caixa própria de 24 (`icone`; contorno `reguaForte` 1.5, raio `carimbo`, fundo `folha`; escolhida: cheia a `tinta` com `check` 18 `sobreTinta`), nome em `corpo` (escolhido: 600). Linha com alvo 48 em toda a largura (clicar no nome também escolhe). Tipo já em curso para este cliente: por baixo do nome, `registo` "Em curso desde 20 nov 2026" (antes de escolher, para não surpreender). Largo: uma coluna de 400; médio: duas colunas, lidas de cima para baixo (7 + 6); compacto: uma coluna.
       - **Pedido repetido (US 1.8):** ao escolher um tipo em curso, abre-se por baixo dessa linha um `InlineNotice` aviso: "Já existe um pedido de {tipo} em curso." + "Criado a {data}, ainda na etapa {n} de 4. Sem confirmar, este tipo não é criado." + `SecondaryButton` "Criar outro na mesma" + `TextAction` "Tirar este tipo". Até confirmar, esse tipo não conta: a barra diz "Criar 1 pedido" e "{tipo} à espera de confirmação", e a folha desse tipo diz "À espera da sua confirmação". Confirmado, o aviso passa a uma linha `registo` "Vai ser criado um segundo pedido de {tipo}.".
    3. **Condições particulares:** uma linha da mesma lista de verificação, desligada por omissão: "Permitir condições particulares" + `corpoPequeno` `tintaMedia` "O cliente pode enviar as condições particulares da apólice atual em vez dos documentos um a um. Vale para todos os tipos escolhidos."
    4. **Mensagem:** `LabeledField` multilinha "Para o cliente (opcional)", altura mínima `campoMensagem` 128 (cresce até 8 linhas e depois faz scroll); por baixo, à esquerda, "Vai no email e na app. Não escreva dados de saúde." e à direita o contador em `registo` "156 / 500" (passa a `erro` com ícone acima de 500, e o envio diz "Encurte a mensagem para 500 caracteres.").
  - **O cliente vai receber** (`subtitulo`) + apoio "Tirar ou acrescentar itens muda só este pedido, não a lista do tipo de seguro." Por baixo, uma **folha** por tipo escolhido, pela ordem do catálogo, `s24` entre folhas: superfície `folha`, régua `fino`, raio `superficie`, padding `s24` (`s16` em compacto), sem sombra. Dentro:
    - cabeçalho: nome do tipo em `subtitulo` e, à direita, `registo` "Pedido 1 de 2";
    - notas com ícone `info_outline` 18 em `corpoPequeno` `tintaMedia`: primeiro a das condições particulares (só se ativas), depois a nota do tipo;
    - lista de itens com réguas: coluna `colunaNatureza` 120 com ícone + palavra em `rotulo` `tintaMedia` ("Documento" `description_outlined`, "Dado" `edit_note`), texto do item em `corpo`, e `TextAction` "Tirar" (ícone `close` + palavra, alvo 48; leitura de ecrã "Tirar {item}"). Compacto: a natureza passa para cima do texto e "Tirar" fica à direita, centrado nas duas linhas. Item acrescentado: `registo` "Acrescentado neste pedido" por baixo do texto;
    - rodapé: `TextAction` "Acrescentar item" (ícone `add`) à esquerda e, se houve itens tirados, `corpoPequeno` "1 item tirado · " + `TextAction` "Repor lista" à direita;
    - **Acrescentar item:** abre no sítio do rodapé uma caixa com contorno `reguaForte` 1.5: `LabeledField` "Novo item" (foco aqui), escolha "É um" com dois rádios ("Documento", "Dado a preencher"; Documento por omissão), `SecondaryButton` "Acrescentar" e `TextAction` "Cancelar". Enter acrescenta; Esc cancela. Texto vazio: "Escreva o item a pedir.".
    - lista vazia (todos tirados): `InlineNotice` erro na folha "A lista de {tipo} está vazia. Acrescente um item ou reponha a lista; sem itens, este pedido não é criado."
    - sem tipos: em vez das folhas, uma caixa de contorno tracejado `reguaForte` 1 com "Escolha pelo menos um tipo de seguro para ver aqui a lista que o cliente vai receber." (o tracejado é a única exceção: marca o lugar vazio onde a folha vai aparecer).
  - **Barra fixa:** à esquerda, `corpoForte` "2 pedidos para Maria do Carmo Figueiredo" (uma linha, reticências) e `corpoPequeno` `tintaMedia` com os tipos e "· com condições particulares"; à direita `PrimaryButton` "Criar 2 pedidos" (56 em compacto, 48+ nos outros; o rótulo acompanha o número). Desativado, sempre com a razão escrita por baixo do botão.
- **Por tamanho:**
  - *Largo:* duas zonas na moldura de 1040: escolhas em `larguraFormulario` 400, `s48`, folha no resto (592). As duas zonas fazem scroll juntas (a folha não é fixa: com 3 tipos fica mais alta do que a janela).
  - *Médio:* uma coluna à largura da moldura: escolhas (tipos em 2 colunas), depois "O cliente vai receber". Duas zonas lado a lado dariam 320 a cada uma e partiam os itens em 3 linhas.
  - *Compacto:* uma coluna; escolhas, depois a folha; barra fixa com o resumo numa linha e o botão a toda a largura (56). O aviso de pedido repetido aparece junto ao tipo (é onde o olho está), não na folha mais abaixo.
  - *Teclado:* Tab segue a ordem de leitura (Mudar, tipos, condições, mensagem, itens de cada folha, Acrescentar item, Criar). Espaço marca/desmarca. Ctrl+Enter na mensagem não cria (só o botão cria). Foco inicial no título em médio/largo; sem foco automático em compacto.
- **Componentes e tokens:** `PageFrame`, `FolderTab`, `TextAction`, `LabeledField` (multilinha + contador), `CheckRow` (novo), `RequestSheet` (novo, modo editável), `RequestItemRow` (novo), `InlineNotice`, `PrimaryButton`, `SecondaryButton`, `OfflineBar`, `SkeletonRows`; `AppSize.larguraFormulario`, `colunaNatureza`, `campoMensagem`; `AppColors.folha`, `realce`.
- **Copy:**
  - Título "Novo pedido"; apoio "Um pedido por tipo de seguro. O cliente recebe um email curto e vê a lista na app."
  - Secções "Cliente", "Tipos de seguro" ("É criado um pedido por tipo."), "Condições particulares", "Mensagem"; "Mudar"; "Só aparecem clientes que aceitaram partilhar os dados com este escritório."
  - "Em curso desde {data}"; aviso de repetido como acima; "Criar outro na mesma"; "Tirar este tipo"; "Vai ser criado um segundo pedido de {tipo}."
  - "Permitir condições particulares" + apoio como acima; nota na folha "Pode enviar as condições particulares da apólice atual em vez dos documentos um a um." (voz do cliente: é o texto que ele vai ler).
  - "Para o cliente (opcional)"; "Vai no email e na app. Não escreva dados de saúde."; "{n} / 500".
  - "O cliente vai receber"; "Tirar ou acrescentar itens muda só este pedido, não a lista do tipo de seguro."; "Pedido {i} de {n}"; "Documento", "Dado"; "Tirar"; "Acrescentar item"; "Novo item"; "É um"; "Documento" / "Dado a preencher"; "Acrescentar"; "Cancelar"; "Acrescentado neste pedido"; "{n} item(ns) tirado(s)"; "Repor lista".
  - Barra: "{n} pedido(s) para {cliente}"; "{tipos} · com condições particulares"; "Criar {n} pedido(s)"; "A criar…"; "Escolha o cliente" / "Nenhum pedido para {cliente}".
  - Razões do botão desativado: "Escolha o cliente e pelo menos um tipo." / "Escolha pelo menos um tipo de seguro." / "A lista de {tipo} está vazia." / "Este cliente já não partilha dados consigo." / offline "Sem ligação. A sua escolha fica guardada neste ecrã; pode criar quando a ligação voltar."
  - Erros: "Não foi possível criar os pedidos. Nada foi criado. A sua escolha mantém-se: tente de novo." / "Este cliente já não partilha dados consigo." + "Nenhum pedido foi criado. Só pode voltar a pedir se ele aceitar um novo pedido de partilha." + "Voltar a Clientes" / "Não foi possível carregar os tipos de seguro. Tente de novo." + "Tentar de novo".
  - Sem clientes ativos: "Ainda não tem clientes com acesso ativo" + "Só pode criar pedidos para clientes que aceitaram partilhar os dados com este escritório. Crie um cliente, ou reenvie o pedido de partilha a quem ainda não respondeu." + `PrimaryButton` "Criar cliente" + `TextAction` "Ver clientes pendentes".
  - Sem acesso (link antigo ou endereço direto; US 2.1): cliente com carimbo e data, `InlineNotice` aviso "Não é possível criar pedidos para este cliente." + motivo: pendente "Ainda não aceitou. Reenvie o pedido de partilha." com `SecondaryButton` "Reenviar pedido de partilha"; recusada "Recusou a partilha. Não é possível criar pedidos."; retirada "Retirou o acesso. Só volta a ser possível se aceitar de novo." Sempre "Voltar a Clientes". Cliente de outro escritório ou inexistente: o ecrã "Sem acesso" da ficha (não revela existência).

### 2. Clientes [mediador; evolução do ecrã 5 da 001]

- **Hierarquia:** 1.º título e "Novo pedido"; 2.º a lista com nome, estado da partilha e pedidos em curso; 3.º email, datas e ação da linha.
- **O que muda:**
  - Botões do cabeçalho: `PrimaryButton` "Novo pedido" (ação principal do dia a dia) e, à esquerda dele, `SecondaryButton` "Criar cliente". Compacto: "Novo pedido" a toda a largura 56 e "Criar cliente" por baixo a `s12`, a toda a largura 48.
  - Contagem: "12 clientes · 3 pendentes · 1 recusado · 6 pedidos em curso" (cada parte não parte a meio).
  - Nome dos clientes **ativos** é ligação para a ficha: `corpoForte` sublinhado `reguaForte` 1 sempre visível (passa a `tinta` no hover e no foco). Pendentes e recusados não são ligação (US 3.2).
  - Coluna **Pedidos** (`colunaEtapa` 200): ativos com pedidos, "**3** em curso" em `corpoPequeno` + trilho com "Criado" (a etapa mais avançada); ativos sem pedidos, "Sem pedidos" `tintaMedia`; pendentes e recusados, vazio (leitura de ecrã: "Sem pedidos visíveis até o cliente aceitar").
  - Ação: ativos "Novo pedido" (`TextAction` com `add`); pendentes "Reenviar pedido" (como na 001); recusados sem ação.
- **Por tamanho:**
  - *Largo:* 4 colunas: Cliente (flexível, 384 a 1040) | Estado (carimbo em cima, data por baixo a `s4`; `colunaData` 248) | Pedidos (200) | Ação (160). Deixa de haver coluna Data separada: com a coluna Pedidos, Cliente ficava em 216, abaixo de `textoMinimo`.
  - *Médio:* 3 colunas: Cliente | "Estado e pedidos" (248: carimbo, data e, por baixo, a linha de pedidos) | Ação.
  - *Compacto:* empilhado como na 001, com a linha de pedidos a seguir ao carimbo e à data, e a ação a toda a largura.
- **Copy:** "Novo pedido", "Criar cliente", "Pedidos", "Estado e pedidos" (médio), "{n} em curso", "Criado", "Sem pedidos", "{n} pedidos em curso" (contagem). Resto igual à 001.

### 3. Ficha do cliente [mediador; nova]

- **Hierarquia:** 1.º nome do cliente e "Novo pedido"; 2.º os pedidos deste escritório; 3.º email, carimbo e datas.
- **Composição:** regresso "Clientes"; separador; título com o nome (`titulo`, quebra em várias linhas, nunca reticências), email `corpoPequeno` `tintaMedia`, carimbo "Ativo" + `registo` "Desde 12 nov 2026, 10:04"; `PrimaryButton` "Novo pedido" à direita (compacto: a toda a largura 56 por baixo). A `s48`, "Pedidos deste escritório" (`subtitulo`) + `registo` "5 em curso". Tabela com réguas, mais recentes primeiro, paginada em 25:
  - *Largo:* Tipo (flexível: nome do tipo como ligação `corpoForte` sublinhado `reguaForte` + `Etiqueta` "Condições particulares" se ativa) | Etapa (`colunaEtapa` 200: trilho + "Criado") | Criado (`colunaData` 248: `registo` "27 nov 2026, 10:14" e por baixo `corpoPequeno` "Mediador · Ana Martins", que é a origem e o autor).
  - *Médio:* Tipo | Criado (248), com o trilho na linha de baixo do tipo.
  - *Compacto:* empilhado: tipo + etiqueta, trilho, data e "Mediador · Ana Martins".
  - O nome do tipo abre o pedido (ecrã 3b). A linha inteira não é clicável: só o nome (alvo 48).
- **Depois de criar (US 1.7):** a página entra com `InlineNotice` "**2 pedidos criados**: Automóvel e Vida. Email enviado a maria.figueiredo@exemplo.pt." e as linhas novas no topo com `realce` a desvanecer (1600 ms).
- **Email não enviado (US 4.4):** `InlineNotice` aviso "2 pedidos criados, mas o email não foi enviado." + "Os pedidos já existem e estão nesta ficha. Tente enviar o email de novo; se o cliente já usa o ProDossier, também os vê na app." + `SecondaryButton` "Reenviar email". Depois de reenviar: "Email reenviado a {email}." e o botão desativado com "Pode reenviar às 10:17" (60 s, hora absoluta, como na 001). As linhas novas não levam `realce` neste caso (o aviso já é ocre).
- **Copy:** "Pedidos deste escritório"; "{n} em curso"; "Tipo", "Etapa", "Criado"; "Condições particulares"; "Mediador · {nome}"; vazio "Sem pedidos" + "Crie o primeiro pedido para este cliente: escolhe os tipos de seguro e ele recebe a lista do que precisa." + `PrimaryButton` "Novo pedido" (o do cabeçalho desaparece: uma ação principal); erro "Não foi possível carregar os pedidos. Tente de novo."; offline "Sem ligação. Pode ver os pedidos; criar fica disponível quando a ligação voltar."; sem acesso "Sem acesso" + "Este cliente não existe ou não partilha dados com este escritório. Se retirou o acesso, os pedidos deixam de aparecer aqui; voltam se ele aceitar um novo pedido de partilha." + "Voltar a Clientes".

### 3b. Pedido aberto [mediador; só leitura; nova]

Mesma composição do ecrã 5 (pedido do cliente), com o widget partilhado `RequestSheet` em modo leitura. Página (não diálogo) porque na 004 é aqui que o mediador vai rever o que o cliente enviou.

- Regresso com o nome do cliente; título com o tipo; "Para Maria do Carmo Figueiredo" (`corpoForte`); linha de metadados: "Criado por Ana Martins" + `registo` "27 nov 2026, 10:14" + `Etiqueta` "Origem: mediador" + `Etiqueta` "Condições particulares"; trilho "Etapa 1 de 4: Pedido criado"; "Mensagem de Ana Martins"; "Lista pedida" + `registo` "4 documentos · 2 dados", notas e itens (sem "Tirar"); faixa "Etapas"; rodapé "Só leitura: um pedido não se altera depois de criado."

### 4. Os meus pedidos [cliente; passa a ser o ecrã inicial do cliente]

- **Hierarquia:** 1.º (se houver) o bloco "À espera da sua resposta" da 001, que continua acima de tudo; 2.º "Os meus pedidos" e a lista; 3.º a passagem para "Com quem partilho".
- **Composição:** separador "Os meus dados" + sino + "Sair". Título "Os meus pedidos"; frase-resumo `corpoForte` "Tem 3 pedidos em curso."; `InlineNotice` informativo enquanto não existir a 003 (ver Decisões em aberto). Grupos com cabeçalho `rotulo` `tintaMedia`, coluna `larguraLeitura` 640:
  - **Em curso:** cada pedido numa linha com régua: tipo em `subtitulo`; "Do escritório {escritório}" em `corpoPequeno` `tintaMedia` (até 2 linhas); trilho "Etapa 1 de 4: Pedido criado" + `registo` com a data; `corpoPequeno` "4 documentos e 2 dados pedidos"; à direita (médio/largo) ou por baixo a toda a largura (compacto) `SecondaryButton` "Ver o pedido" (48).
  - **Com o acesso retirado** (US 4.3): apoio "Estes escritórios já não veem os pedidos nem os seus dados. Se voltar a dar acesso, os pedidos continuam onde estavam."; a linha leva o carimbo novo "Acesso retirado" (`estadoInativo`, `undo`) em vez do trilho. "Ver o pedido" continua (ver não é uma ação sobre o pedido).
  - A `s48`, depois de uma régua: "Com quem partilho" (`subtitulo`), "Partilha os seus dados com 2 escritórios." e `SecondaryButton` "Ver com quem partilho" (abre o ecrã 4 da 001, que perde o papel de ecrã inicial mas fica igual).
- **Copy:** "Os meus pedidos"; "Tem {n} pedido(s) em curso."; "Em curso"; "Com o acesso retirado"; "Do escritório {escritório}"; "Etapa 1 de 4: Pedido criado"; "{d} documento(s) e {i} dado(s) pedidos"; "Ver o pedido"; "Acesso retirado"; "Com quem partilho"; vazio "Ainda não tem pedidos." + "Quando um escritório lhe pedir documentos para um seguro, o pedido aparece aqui e recebe também um email."; erro "Não foi possível carregar os seus pedidos. Tente de novo."

### 5. Pedido [cliente; só leitura]

- **Hierarquia:** 1.º tipo e escritório; 2.º o que lhe pedem (com a mensagem antes, como contexto); 3.º as etapas.
- **Composição** (coluna 640): regresso "Os meus pedidos"; título com o tipo; "Pedido do escritório Ribeira Seguros" (`corpoForte`); "Enviado por Ana Martins, mediadora" + `registo` data; trilho "Etapa 1 de 4: Pedido criado"; `InlineNotice` interino; "Mensagem de Ana Martins" (`rotulo` `tintaMedia`) + texto `corpo` (quebra livre, nunca cortado); "O que lhe pedem" (`subtitulo`) + `registo` "4 documentos · 2 dados"; notas (condições particulares e nota do tipo); itens com réguas (natureza + texto, sem ação); "Etapas" (`subtitulo`) e a **faixa de etapas**; rodapé "Os documentos que enviar ficam no seu dossiê; só os vê quem tem acesso aos seus dados."
- **Faixa de etapas (`StageStrip`):** médio/largo, 4 colunas iguais com réguas verticais `regua`, régua de baixo, e em cima de cada coluna uma barra de `AppStroke.etapa` 4: `tinta` nas etapas feitas, `regua` nas outras. Em cada coluna: número em `subtitulo` (serifa, tabular; `tintaTenue` se por fazer), nome em `corpoPequeno` (600 se feita, `tintaMedia` se não) e o estado: `check_circle` 18 + `registo` com a data, ou `registo` "Por fazer". Compacto: 4 linhas empilhadas (número à esquerda, nome e estado à direita), a barra passa para a esquerda da linha (4 de largura) só nas feitas. Nomes: "Pedido criado", "Documentos enviados", "Em análise pelo mediador", "Enviado às seguradoras".
- **Acesso retirado:** em vez do trilho, carimbo "Acesso retirado" + `registo` "Retirado a 26 nov 2026, 15:02" e `corpo` "O escritório Ribeira Seguros já não vê este pedido nem os seus dados. Se voltar a dar acesso, o pedido continua onde estava." Sem aviso interino e sem ações.
- **Sem acesso / não encontrado:** "Pedido não encontrado" + "Este pedido não existe ou não é seu. Veja os seus pedidos na página inicial." + `SecondaryButton` "Ver os meus pedidos" (56).

### 6. Sino e notificações [cliente]

- **Sino:** ver "Estrutura comum". Leitura de ecrã: "Notificações, 2 por ler". Tooltip igual (hover, foco, toque longo).
- **Painel:** médio/largo, folha lateral de `folhaLateral` 440 à direita (regras de folha lateral da 001: véu, Esc, foco preso e devolvido ao sino); compacto, ecrã inteiro com rota própria (regresso "Os meus pedidos", título "Notificações"). Cabeçalho: "Notificações" (`subtitulo`) + `registo` "2 por ler" / "Todas lidas"; à direita `TextAction` "Fechar" (`close`), só na folha.
- **Linha:** alvo da linha inteira (é uma lista de ligações) com `chevron_right` 18 `tintaMedia` à direita. Coluna de 8 à esquerda com o quadrado `marcaNaoLida` 8 a `tinta` nas por ler. Texto: "Novo pedido: {tipo}" (`corpoForte` por ler; `corpo` `tintaMedia` lida), escritório em `corpoPequeno` `tintaMedia` (até 2 linhas), `registo` "Por ler · 27 nov 2026, 10:14" ou só a data. "Por ler" está escrito: a marca e o peso nunca são o único sinal. Altura mínima `linhaTabela` 72. Por data decrescente, 25 de cada vez com `SecondaryButton` "Mostrar mais 25".
- **Abrir:** leva ao pedido (ecrã 5); a linha passa a lida e o contador desce só quando o servidor confirmar (sem update otimista, US 7.6). Se o escritório perdeu o acesso, abre o pedido com "Acesso retirado".
- **Copy:** "Notificações"; "{n} por ler"; "Todas lidas"; "Fechar"; "Novo pedido: {tipo}"; "Por ler"; vazio "Sem notificações" + "Quando um escritório lhe enviar um pedido, o aviso aparece aqui."; erro "Não foi possível carregar as notificações. Tente de novo."; offline (dentro do painel, por baixo da `OfflineBar`) "Sem ligação. Está a ver as notificações de {data, hora}. Abrir uma notificação só a marca como lida quando a ligação voltar."

### 7. Email do pedido

Um email por criação (os N pedidos juntos), enviado por função de servidor (não é template do Supabase Auth, por isso pode ter a data de envio). Mesmo esqueleto de `supabase/templates/magic-link.html`: caixa `folha` de 560 com régua e raio 10, título em serifa 26, bloco `realce` com rótulos, botão cheio a tinta, colofão.

- **Assunto:** "Ribeira Seguros pede-lhe elementos para Automóvel e Vida" (tipos unidos por ", " e " e "; com mais de 3, "para 4 seguros").
- **Pré-cabeçalho:** "Veja na app o que lhe pedem. A lista não vai neste email."
- **Corpo:** título "Ribeira Seguros pede-lhe elementos para 2 seguros" (1 tipo: "… para o seguro Automóvel"); "Ana Martins, do escritório Ribeira Seguros, criou 2 pedidos para si no ProDossier. Na app vê a lista do que precisa de enviar para cada um."; bloco: "Pedidos" (um tipo por linha, serifa 21), "Escritório" ("Ribeira Seguros, enviado por Ana Martins"), "Mensagem de Ana Martins" (só se houver); botão "Ver os pedidos" (abre Os meus pedidos; sem sessão passa por Entrar); "Por segurança, a lista de documentos e dados não vai neste email: só a vê na app, depois de entrar."; endereço em texto; colofão "O dossiê dos seus seguros, partilhado só com quem autorizar." + "Enviado a 27 nov 2026, 10:14 para maria.figueiredo@exemplo.pt".
- Texto simples (`.txt`) com a mesma copy, como na 001. Nunca leva itens, notas do tipo nem dados de saúde.

## Componentes novos e alterados (para o flutter-dev)

| Widget | Onde | Notas de integração |
| --- | --- | --- |
| `StatusStamp` | `lib/core/widgets/status_stamp.dart` | Novo valor `StampStatus.acessoRetirado` ("ACESSO RETIRADO", `Icons.undo`, `estadoInativo`, falado "acesso retirado"). Os carimbos continuam a ser só estados de partilha: etapas de pedido **não** são carimbos. |
| `StageTrack` (novo) | `lib/core/widgets/` | 4 segmentos `segmentoEtapa` 16 × `AppStroke.etapa` 4, `s4` entre eles, feitos a `tinta`, os outros a `regua`; sempre com a palavra ao lado (`corpoPequeno`). `Semantics`: "Etapa 1 de 4: Pedido criado" (os segmentos ficam excluídos). Sem animação. |
| `StageStrip` (novo) | `lib/core/widgets/` | Faixa de 4 colunas (largo/médio) ou 4 linhas (compacto, mesma regra de `textoMinimo` das linhas). Recebe a etapa atual e as datas. Lista semântica de 4 itens com "feita a {data}" / "por fazer". |
| `CheckRow` (novo) | `lib/core/widgets/` | Linha com réguas, caixa própria de 24 e texto; alvo 48 na linha toda; `Semantics` de checkbox; anel `foco` na caixa. Não usar `Checkbox`/`CheckboxListTile` com estilo por defeito. Usado nos tipos e nas condições particulares. |
| `Etiqueta` / `TagLabel` (novo) | `lib/core/widgets/` | Contorno `reguaForte` 1, raio `carimbo`, `rotulo` `tintaMedia`, padding `s8` dos lados, sem fundo, sem maiúsculas (distingue-se dos carimbos). |
| `RequestSheet` (novo) | `lib/features/requests/presentation/` | A folha de um pedido: cabeçalho, notas, `RequestItemRow`s, rodapé. Modo `editable` (Novo pedido: Tirar, Acrescentar item, Repor lista) e modo leitura (pedido aberto, mediador e cliente). Em leitura não tem superfície `folha`: fica sobre o `papel` da página. |
| `RequestItemRow` (novo) | idem | Natureza (`colunaNatureza` 120) + texto + ação opcional; passa a empilhado em compacto ou quando o texto fica abaixo de `textoMinimo`. |
| `NotificationBell` (novo) | `lib/core/widgets/` (vai para `AccountActions` do cliente) | Ícone + palavra (médio/largo) + contador retangular; nunca `Badge` do Material. Estado aberto com fundo `cartolina`. |
| `NotificationsPanel` (novo) | `lib/features/notifications/presentation/` | Folha lateral (médio/largo) reutilizando a folha lateral da 001; ecrã inteiro em compacto. |
| `LabeledField` | existente | Precisa de multilinha (`minHeight` `campoMensagem`) e de contador à direita da ajuda; o contador é `registo` e passa a erro acima do limite. |
| `PageFrame` / `AccountActions` | existentes | A linha da conta do cliente passa a ter o sino antes de "Sair" (`s8` entre eles). A ligação de regresso por cima da linha do separador já existe no consentimento: generalizar como parâmetro do `PageFrame` em vez de cada ecrã a desenhar. |
| Barra fixa do Novo pedido | `PageFrame.bottom` | Reutiliza a barra fixa do consentimento: resumo à esquerda, `PrimaryButton` à direita, razão por baixo do botão. |

## Tokens propostos (a acrescentar em DESIGN.md e `tokens.dart` só depois do gate 2)

| Token | Valor | Uso |
| --- | --- | --- |
| `AppSize.colunaEtapa` | 200 | Coluna Pedidos (Clientes, largo) e Etapa (ficha, largo) |
| `AppSize.segmentoEtapa` | 16 | Largura de cada segmento do `StageTrack` |
| `AppStroke.etapa` | 4 | Espessura do trilho e da barra de cada coluna da faixa de etapas |
| `AppSize.colunaNatureza` | 120 | "Documento" / "Dado" à esquerda de cada item (o mais largo, "Documento" com ícone, mede ~104) |
| `AppSize.campoMensagem` | 128 | Altura mínima do campo de mensagem (4 linhas de 26 + padding) |
| `AppSize.marcaNaoLida` | 8 | Quadrado a tinta das notificações por ler |

Nenhuma cor nova. O contador do sino usa `tinta`/`sobreTinta`, `AppType.carimbo` e `iconePequeno` 18 como altura; a caixa de seleção usa `icone` 24.

## Responsividade por ecrã

| Ecrã | Compacto (< 640) | Médio (640 a 1100) | Largo (> 1100) | Folhas e diálogos | Teclado e foco |
| --- | --- | --- | --- | --- | --- |
| Novo pedido | Uma coluna; tipos numa coluna; folha por baixo; barra com resumo + botão 56 a toda a largura | Uma coluna; tipos em 2 colunas (de cima para baixo); folha por baixo | Escolhas 400 + folha 592 lado a lado | Nenhuma (acrescentar item é inline) | Ordem de leitura; Espaço marca; Enter acrescenta item; Esc fecha a escolha de cliente e o acrescentar |
| Clientes | Empilhado; "Novo pedido" 56 + "Criar cliente" 48 | 3 colunas (Estado e pedidos 248) | 4 colunas (248 / 200 / 160) | Criar cliente como na 001 | Novo pedido, Criar cliente, nomes (ligação) e ações por ordem |
| Ficha | Empilhado; "Novo pedido" 56 a toda a largura | Tipo + Criado (248), trilho por baixo do tipo | Tipo / Etapa 200 / Criado 248 | Nenhuma | Novo pedido, depois cada tipo |
| Pedido aberto (mediador e cliente) | Coluna toda; faixa de etapas em 4 linhas | Coluna 640; faixa em 4 colunas | Idem na moldura | Nenhuma | Foco no título; nada focável além do regresso |
| Os meus pedidos | Linhas empilhadas; "Ver o pedido" 48 a toda a largura | Coluna 640, "Ver o pedido" à direita | Idem na moldura | Notificações: ecrã inteiro | Sino, Sair, cada "Ver o pedido", "Ver com quem partilho" |
| Notificações | Ecrã inteiro com regresso | Folha lateral 440 | Folha lateral 440 | Véu, Esc, voltar do navegador fecha | Foco no título da folha; devolvido ao sino |

## Matriz de estados

Ação principal entre parênteses. Offline: `OfflineBar` da 001; nunca se mostra como criado ou lido algo que o servidor não confirmou.

| Ecrã | Populado | Vazio | A carregar | Erro | Offline | Desativado | Sem permissão |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Novo pedido | Cliente, 2 tipos, lista editada, condições, mensagem (Criar 2 pedidos) | Sem clientes ativos: texto + (Criar cliente); sem tipos: caixa tracejada e botão desativado com razão | Catálogo: 13 linhas de skeleton nos tipos e uma folha em skeleton; cliente e cabeçalho já no sítio; "A criar…" com spinner no botão e escolhas inertes | Falha ao criar (nada criado, escolha mantida, Criar volta ativo); concessão perdida (Voltar a Clientes); catálogo (Tentar de novo); lista vazia de um tipo | Faixa; tudo editável, "Criar" desativado com razão; escolha preservada | Criar até haver cliente e ≥ 1 tipo com lista; tipo repetido sem confirmação não conta | Pendente/recusada/retirada: motivo + ação; outro escritório: "Sem acesso" |
| Clientes | Tabela com coluna Pedidos (Novo pedido) | Igual à 001 | `SkeletonRows` 6 com a coluna Pedidos | Igual à 001 | Faixa; Novo pedido, Criar cliente e ações de linha desativados com razão | Igual à 001 | Igual à 001 |
| Ficha | 5 pedidos; depois de criar, aviso + realce | "Sem pedidos" (Novo pedido) | 3 linhas de skeleton, cabeçalho visível | "Não foi possível carregar os pedidos." (Tentar de novo); email não enviado (Reenviar email) | Faixa; "Novo pedido" desativado com razão | "Reenviar email" 60 s com a hora | "Sem acesso" sem revelar existência (Voltar a Clientes) |
| Pedido aberto (mediador) | Lista, mensagem, autor, etapas | n/a | Skeleton com a forma (título, faixa, 6 itens) | "Não foi possível abrir este pedido." (Tentar de novo) | Faixa; nada muda (só leitura) | n/a | "Sem acesso" (como a ficha) |
| Os meus pedidos | Em curso + acesso retirado + Com quem partilho (Ver o pedido) | "Ainda não tem pedidos." | 3 linhas de skeleton; o bloco pendente da 001 nunca em skeleton | "Não foi possível carregar os seus pedidos." (Tentar de novo) | Faixa; a lista fica (só leitura) | n/a | Sessão terminada como na 001 |
| Pedido (cliente) | Lista, mensagem, etapas | n/a | Skeleton com a forma | "Não foi possível abrir este pedido." (Tentar de novo) | Faixa; igual | n/a | "Pedido não encontrado" (Ver os meus pedidos); acesso retirado: carimbo e explicação, sem ações |
| Notificações | 2 por ler + 2 lidas | "Sem notificações" | 4 linhas de skeleton | "Não foi possível carregar…" (Tentar de novo) | Último estado conhecido + aviso com a hora; abrir não marca como lida | Contador oculto a 0 | Só as suas (RLS); nunca de outros |
| Sino | Contador 1 a 9, "9+" | Sem contador | Sem contador até chegar (nunca "0" provisório) | Sem contador; o painel mostra o erro | Último contador conhecido | n/a | n/a |

## Motion

Tokens de `AppMotion`. Com "reduzir movimento", tudo a 0 e corte seco. Nenhuma informação só no movimento.

| Elemento | Gatilho | Duração / curva (token) |
| --- | --- | --- |
| Caixa de seleção (tipo, condições) | Marcar / desmarcar | Fundo e `check` em `rapido` / `mudar` |
| Folha de um tipo em "O cliente vai receber" | Tipo escolhido / tirado | Entra `base` / `entrar` (opacidade + altura); sai `base` / `sair`; as outras folhas deslizam para o sítio em `base` / `mudar` |
| Aviso de pedido repetido | Escolher um tipo em curso | `InlineNotice` `base` / `entrar` (opacidade + altura) |
| Item tirado | "Tirar" | Sai `base` / `sair` (opacidade + altura); "1 item tirado · Repor lista" aparece `base` / `entrar` |
| Item acrescentado / lista reposta | "Acrescentar" / "Repor lista" | Entra `lento` / `entrar`; fundo `realce` desvanece em `AppMotion.realce` 1600 |
| Caixa "Acrescentar item" | Abrir / fechar | `base` / `entrar`, `base` / `sair` (altura) |
| Lista de escolha do cliente | Escrever no campo | Abre `base` / `entrar` (altura); filtrar não anima (troca seca) |
| Texto do resumo e do botão da barra ("Criar 2 pedidos") | Muda o número | Cross-fade `rapido` / `mudar`; a largura do botão ajusta sem saltar a barra |
| Botão para "A criar…" | Envio | `rapido` / `mudar` (como na 001) |
| Ficha depois de criar | Servidor confirma | Transição de página `base`; `InlineNotice` `base` / `entrar`; linhas novas `lento` / `entrar` com `realce` 1600 |
| Contador do sino | Notificação nova ou lida confirmada | Cross-fade do número `base` / `mudar`; aparece/desaparece em opacidade `base`; nunca salta nem pulsa |
| Marca de não lida | Lida confirmada | Desvanece `base` / `sair`; o texto passa de 600 a 400 em `base` / `mudar` |
| Painel de notificações (médio/largo) | Abrir / fechar | Folha lateral: `lento` / `entrar`, `base` / `sair` |
| Notificações em compacto, Novo pedido, Ficha, Pedido | Navegação | Cross-fade de página `base` (regra da 001) |
| Trilho e faixa de etapas | n/a | Sem animação na 002 (na 003/004, mudança de etapa: segmento a `tinta` em `base` / `mudar`) |
| Skeletons | A carregar | `pulsar` 1200, mínimo 0.55; nunca shimmer |

## Transições e fluxos

Regras de transição da 001 ("Transições entre ecrãs") sem mudanças. Storyboards em `renders/`:

1. `fluxo-1-novo-pedido.png`: Clientes → escolher cliente → tipos e lista → a criar → ficha com os pedidos novos → pedido aberto.
2. `fluxo-2-cliente.png`: email → Os meus pedidos (sino com 2) → Notificações → pedido. Ramos: acesso retirado, painel lateral em desktop, cliente sem conta.
3. `fluxo-3-excecoes.png`: pedido repetido → falha ao criar → email não enviado → email reenviado. Ramos: concessão perdida, lista vazia, offline, catálogo, sem acesso.

## Acessibilidade (verificar na implementação)

- Tipos e condições: `Semantics` de checkbox com o nome ("Automóvel, por escolher"; "Multirriscos Habitação, em curso desde 20 de novembro de 2026").
- "Tirar" e "Acrescentar item" dizem a que tipo e item se referem ("Tirar Morada do pedido de Automóvel").
- A barra fixa é uma região com nome ("Resumo do pedido"); a mudança de "Criar 2 pedidos" para "Criar 1 pedido" é anunciada (live region educada).
- Trilho: só a frase "Etapa 1 de 4: Pedido criado" é lida. Faixa: lista de 4 itens.
- Sino: "Notificações, 2 por ler"; ao abrir, o foco vai para o título do painel; ao fechar, volta ao sino.
- Escala de texto 1.3: a barra fixa do Novo pedido cresce em altura (nunca corta o botão); itens e linhas descem um nível pela regra de `textoMinimo`.
- Contraste: todos os pares de texto já aprovados (DESIGN.md); `tintaTenue` nunca sobre `cartolina` (o sino aberto usa `tinta` sobre `cartolina`, 12.1).

## Decisões em aberto (para o gate 2)

1. **Ecrã inicial do cliente.** A: "Os meus pedidos" passa a ser o ecrã inicial, com passagem para "Com quem partilho" no fim (renders). B: "Com quem partilho" continua inicial e ganha uma secção de pedidos no topo. C: uma só página "Os meus dados" com as duas secções. **Recomendação A**: os pedidos são o que o cliente vem fazer e as decisões de partilha merecem um ecrã próprio, calmo; o bloco de consentimento pendente da 001 continua no topo de A.
2. **Aviso interino ao cliente até à 003** ("Para já, aqui só pode ver o que lhe pedem. O envio pela app chega em breve; até lá, combine o envio com o escritório."). A: manter (renders). B: não dizer nada. C: texto sem promessa de "em breve" ("Por agora, combine o envio dos documentos com o escritório."). **Recomendação C** se a 003 não tiver data; A se vier logo a seguir.
3. **Notas do catálogo na voz do mediador.** As notas 8 ("pedir também o CC…"), 9 e 10 ("Pedir a apólice em vigor") falam para o mediador, mas o cliente vai lê-las. A: reescrever na voz do cliente no catálogo (renders usam "Se o condutor habitual não for o tomador, envie também o Cartão de Cidadão, a carta de condução e a morada do condutor." e "Se já tem seguro, a apólice em vigor é essencial."). B: duas notas por tipo (mediador e cliente). **Recomendação A** (o supabase-dev ajusta os dados do catálogo; a referência `docs/reference/tipos-de-seguro.md` fica como está).
4. **Hierarquia dos botões de Clientes.** A: "Novo pedido" principal e "Criar cliente" secundário (renders). B: manter "Criar cliente" principal da 001. **Recomendação A**.
5. **Tabela de Clientes em largo perde a coluna Data separada** (passa a carimbo + data na mesma coluna, como no médio) para caber a coluna Pedidos. Assumida; ver se o Henrique sente falta da data numa coluna à parte.
6. **Um email por criação (N pedidos juntos) e não um por pedido.** A spec diz "email curto com os tipos pedidos", o que já sugere um; também poupa o limite de 2 emails por hora do Supabase. Assumida.
7. **Tokens novos** (tabela acima) entram em DESIGN.md e `tokens.dart` depois de aprovados; o `StampStatus.acessoRetirado` também.

## Renders

Índice completo e comando para regenerar em `renders/README.md`. Cada ecrã a 390 × 844, 768 × 1024 e 1280 × 800 (PNG a 2×), com os estados da matriz; `-completo-` é a página inteira. Os goldens continuam a ser a verificação da implementação (Modo 2, `test/design_review/002_novo_pedido/`, tag `design-review`, escala 1.0 e 1.3).
