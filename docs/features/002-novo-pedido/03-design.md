# 03 Design: 002 Novo pedido (mediador) + clientes com o estado dos pedidos

> **Gate 2 aprovado (2026-11-27)** pelo Henrique, com as decisões fechadas na secção "Decisões do gate 2". Tokens novos e o carimbo "Acesso retirado" já estão em `docs/design/DESIGN.md`. Renders em `renders/` (índice em `renders/README.md`).
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
  - Sem acesso (link antigo ou endereço direto; US 2.1): cliente com carimbo e data, `InlineNotice` aviso "Não é possível criar pedidos para este cliente." + motivo: pendente "Ainda não aceitou. Reenvie o pedido de partilha." com `SecondaryButton` "Reenviar pedido de partilha"; recusada "Recusou a partilha. Não é possível criar pedidos."; retirada: o mesmo "Sem acesso" da ficha, sem motivo (gate 4, 28/11, D1 = A) Sempre "Voltar a Clientes". Cliente de outro escritório ou inexistente: o ecrã "Sem acesso" da ficha (não revela existência).

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
- **Composição:** separador "Os meus dados" + sino + "Sair". Título "Os meus pedidos"; frase-resumo `corpoForte` "Tem 3 pedidos em curso."; `InlineNotice` informativo enquanto não existir a 003: "Para já, aqui só pode ver o que lhe pedem. Combine o envio com o escritório." (sem promessa de data; sai quando a 003 entrar). Grupos com cabeçalho `rotulo` `tintaMedia`, coluna `larguraLeitura` 640:
  - **Em curso:** cada pedido numa linha com régua: tipo em `subtitulo`; "Do escritório {escritório}" em `corpoPequeno` `tintaMedia` (até 2 linhas); trilho "Etapa 1 de 4: Pedido criado" + `registo` com a data; `corpoPequeno` "4 documentos e 2 dados pedidos"; à direita (médio/largo) ou por baixo a toda a largura (compacto) `SecondaryButton` "Ver o pedido" (48).
  - **Com o acesso retirado** (US 4.3): apoio "Estes escritórios já não veem os pedidos nem os seus dados. Se voltar a dar acesso, os pedidos continuam onde estavam."; a linha leva o carimbo novo "Acesso retirado" (`estadoInativo`, `undo`) em vez do trilho. "Ver o pedido" continua (ver não é uma ação sobre o pedido).
  - A `s48`, depois de uma régua: "Com quem partilho" (`subtitulo`), "Partilha os seus dados com 2 escritórios." e `SecondaryButton` "Ver com quem partilho" (abre o ecrã 4 da 001, que perde o papel de ecrã inicial mas fica igual).
- **Copy:** "Os meus pedidos"; "Tem {n} pedido(s) em curso."; "Em curso"; "Com o acesso retirado"; "Do escritório {escritório}"; "Etapa 1 de 4: Pedido criado"; "{d} documento(s) e {i} dado(s) pedidos"; "Ver o pedido"; "Acesso retirado"; "Com quem partilho"; vazio "Ainda não tem pedidos." + "Quando um escritório lhe pedir documentos para um seguro, o pedido aparece aqui e recebe também um email."; erro "Não foi possível carregar os seus pedidos. Tente de novo."

### 5. Pedido [cliente; só leitura]

- **Hierarquia:** 1.º tipo e escritório; 2.º o que lhe pedem (com a mensagem antes, como contexto); 3.º as etapas.
- **Composição** (coluna 640): regresso "Os meus pedidos"; título com o tipo; "Pedido do escritório Ribeira Seguros" (`corpoForte`); "Enviado por Ana Martins, mediadora" + `registo` data; trilho "Etapa 1 de 4: Pedido criado"; `InlineNotice` interino (mesmo texto de Os meus pedidos); "Mensagem de Ana Martins" (`rotulo` `tintaMedia`) + texto `corpo` (quebra livre, nunca cortado); "O que lhe pedem" (`subtitulo`) + `registo` "4 documentos · 2 dados"; notas (condições particulares e nota do tipo); itens com réguas (natureza + texto, sem ação); "Etapas" (`subtitulo`) e a **faixa de etapas**; rodapé "Os documentos que enviar ficam no seu dossiê; só os vê quem tem acesso aos seus dados."
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

## Tokens novos (em DESIGN.md desde o gate 2; o flutter-dev cria-os em `tokens.dart`)

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

## Decisões do gate 2 (fechadas a 2026-11-27)

1. **Ecrã inicial do cliente: A.** "Os meus pedidos" passa a ser o ecrã onde o cliente aterra (com o bloco pendente da 001 no topo, se houver) e tem, no fim, a passagem para "Com quem partilho", que fica igual mas deixa de ser inicial. Um link de um pedido de acesso concreto continua a abrir o consentimento.
2. **Aviso interino: C.** "Para já, aqui só pode ver o que lhe pedem. Combine o envio com o escritório." em Os meus pedidos e no pedido do cliente (não aparece em pedidos com acesso retirado). Sem promessa de data. Sai com a 003.
3. **Notas do catálogo na voz do cliente: aceite.** Texto final na secção seguinte.
4. **Clientes: "Novo pedido" principal, "Criar cliente" secundário: aceite.**
5. **Um só email por criação (N pedidos juntos): aceite.** Também ficam assumidas a coluna Estado + data em largo na tabela de Clientes e os tokens novos.

## Catálogo: notas na voz do cliente

Texto final das notas para os dados do catálogo (o supabase-dev usa estas frases tal como estão; `docs/reference/tipos-de-seguro.md` fica como fonte histórica). As notas são lidas pelo cliente no pedido e pelo mediador na pré-visualização, por isso estão todas na voz do cliente, em PT-PT formal, e terminam com ponto. As 10 restantes mantêm o texto do catálogo; acrescenta-se só o ponto final onde falta.

| # | Tipo | Nota no catálogo original | Nota final (dados) |
| --- | --- | --- | --- |
| 8 | Automóvel | Se o condutor for diferente do tomador, pedir também o CC, a carta de condução e a morada do condutor | Se o condutor habitual não for o tomador, envie também o Cartão de Cidadão, a carta de condução e a morada do condutor. |
| 9 | Acidentes de Trabalho (prémio fixo) | Pedir a apólice em vigor | Se a empresa já tem seguro, envie a apólice em vigor. |
| 10 | Acidentes de Trabalho (prémio variável) | Pedir a apólice em vigor | Se a empresa já tem seguro, envie a apólice em vigor. |

Notas sem alteração de texto (só ponto final): 1 e 2 (nota saúde), 3, 5, 6, 7, 13. Tipos 4, 11 e 12 não têm nota (a folha não mostra a linha de nota).

## Renders

Índice completo e comando para regenerar em `renders/README.md`. Cada ecrã a 390 × 844, 768 × 1024 e 1280 × 800 (PNG a 2×), com os estados da matriz; `-completo-` é a página inteira. Os goldens continuam a ser a verificação da implementação (Modo 2, `test/design_review/002_novo_pedido/`, tag `design-review`, escala 1.0 e 1.3).

## Polimento (modo 2)

> Tarefa 7 do `04-plan.md`, 2026-11-28. Goldens da app real em `test/design_review/002_novo_pedido/goldens/` (76 PNG; gerar com `flutter test --update-goldens test/design_review/002_novo_pedido`; tag `design-review`, fora da regressão). Fixtures desta secção "Fixtures" (catálogo de 13 tipos, Maria com 5 pedidos, Multirriscos em curso, mensagem de 156). Comparado com `renders/` e com este ficheiro. Nada em `lib/` foi alterado: cada item diz o ficheiro dono, para o flutter-dev.
> Teste de cara de IA: passa (0 sinais). A identidade está lá em todos os ecrãs; os problemas abaixo são de acabamento, não de direção.

### Crítico

| # | Ecrã | O que está diferente | Ficheiro dono | Correção proposta |
| --- | --- | --- | --- | --- |
| C1 | Sino em todos os ecrãs do cliente (`meus-pedidos-*`, `pedido-cliente-*`, `notificacoes-*`) | O contador "2" estica à altura do alvo: retângulo de 18 × 48 em vez de 18 × 18, e atravessa a régua do separador. Parece uma barra preta, não um contador. | `lib/core/widgets/notification_bell.dart` (`_Counter`) | O `Container` tem `alignment: Alignment.center`, que vira um `Align` e ocupa a altura máxima que o `Row` lhe dá (48). Tirar o `alignment` e centrar o texto com `Align(widthFactor: 1, heightFactor: 1)` (ou fixar `height: AppSize.iconePequeno`). Acrescentar em `test/core/` um teste que mede 18 de altura. |
| C2 | Painel de notificações, tablet e desktop (`notificacoes-tablet`, `notificacoes-desktop`) | O título parte a meio da palavra: "Notificaçõe / s", em duas linhas, com o cabeçalho a ficar 104 de altura. | `lib/features/notifications/presentation/notifications_panel.dart` | No cabeçalho, o `Flexible` do título e o `Spacer` dividem o espaço livre ao meio (o título fica com ~110). Título sem `Flexible`; o resumo "2 por ler" num `Expanded` com `maxLines: 1` e reticências; tirar o `Spacer`. |

### Médio

| # | Ecrã | O que está diferente | Ficheiro dono | Correção proposta |
| --- | --- | --- | --- | --- |
| M1 | Cliente a 320 e a 390 com escala 1.3 (`meus-pedidos-320`, `-telemovel-1.3`, `pedido-cliente-*`, `notificacoes-*`) | O separador "Os meus dados" é cortado para "Os meu…" porque o sino e "Sair" ocupam a linha. O separador é a assinatura e diz de quem são os dados; o público com texto grande é exatamente este. | `lib/core/widgets/page_frame.dart` / `account_actions.dart` (a linha do separador) | O separador nunca leva reticências. Quando a linha não cabe, encolhe primeiro a conta: "Sair" perde o ícone (fica a palavra, alvo 48) e o sino perde o padding lateral `s4`. Só se ainda não couber, o separador passa a duas linhas (altura cresce, nunca corta). Regra nova em DESIGN.md. |
| M2 | Novo pedido, folhas em médio/largo (`novo-pedido-completo-desktop`, `-repetido-desktop`) | Cada item editável mede 73 de altura (padding `s12` em cima e em baixo somado ao alvo 48 do "Tirar"); nos renders mede ~51. A folha de Automóvel fica ~130 mais alta e no desktop a 1.ª folha deixa de caber na janela. Além disso a natureza e o "Tirar" ficam centrados nas duas linhas de um item longo; nos renders alinham com a 1.ª linha. | `lib/core/widgets/request_item_row.dart` | Com ação, padding vertical `s4` (uma linha = 48 + 8 = 56; o alvo já dá o ar); sem ação (leitura) fica `s12` como hoje (~50, igual ao render). Em médio/largo, `crossAxisAlignment.start` para a natureza e o "Tirar" (topo alinhado com a 1.ª linha do texto); em compacto fica centrado, como está escrito na composição. |
| M3 | Novo pedido, escolher o cliente (`novo-pedido-escolher-cliente-*`) | O fundo `realce` da opção ativa só cobre a largura do texto (termina a ~395 de 520 no desktop); no render cobre a linha toda. | `lib/features/mediator/presentation/new_request_sections.dart` (lista de opções) | A opção ocupa a largura da lista (`width: double.infinity` ou `CrossAxisAlignment.stretch` na coluna das opções). |
| M4 | Novo pedido, pedido repetido; ficha, email não enviado (`novo-pedido-repetido-*`, `ficha-email-falhou-*`) | As ações do aviso ("Criar outro na mesma" / "Tirar este tipo"; "Reenviar email") ficam fora da caixa, em `papel`, por baixo dela; nos renders estão dentro da caixa, alinhadas com o texto do aviso. No repetido o aviso também começa na margem da caixa de seleção em vez de alinhar com o nome do tipo. A decisão fica separada da pergunta que ela responde. | `lib/core/widgets/inline_notice.dart`; `new_request_sections.dart` (`_RepeatNotice`); `client_file_page.dart` | `InlineNotice` ganha `actions` (widget opcional) desenhado dentro da caixa, a `s12` do texto e com o recuo do ícone (`icone` + `s12`), como já faz o `actionLabel`. O repetido usa-o e recua o aviso até ao texto do tipo (`icone` 24 + `s12`). A ficha passa "Reenviar email" e a razão "Pode reenviar às…" para dentro. |
| M5 | Novo pedido offline (`novo-pedido-offline-*`) | A faixa diz "as alterações ficam bloqueadas até a ligação voltar", mas o ecrã continua editável e a razão do botão diz "A sua escolha fica guardada neste ecrã". Duas frases que se contradizem no mesmo ecrã. | `lib/features/mediator/presentation/new_request_page.dart` | O `OfflineBar` já aceita `message`. Copy: "Sem ligação à internet. Pode continuar a escolher; criar fica disponível quando a ligação voltar." |
| M6 | Clientes (coluna Pedidos, largo) e ficha (coluna Etapa, largo) (`clientes-desktop`, `ficha-desktop`) | Com a etapa 2, a palavra do trilho parte em duas linhas ao lado dos segmentos: "Documentos / enviados", e a linha fica mais alta do que as outras. Hoje só aparece com a fixture de etapa 2, mas a 003 vai trazer estas etapas. | `lib/core/widgets/stage_track.dart` | Quando a palavra não cabe numa linha ao lado dos segmentos, desce para baixo deles (a `s4`), numa linha; nunca parte a meio da palavra ao lado do trilho. |
| M7 | Admin em compacto (`admin-telemovel`, `admin-320`) | Os números estão centrados numa caixa de 88: "3" e "4" ficam a meio, desalinhados de "128"; de 3 algarismos para cima o número cola ao rótulo sem espaço ("128Clientes", "1046Pedidos"). | `lib/features/admin/presentation/admin_home_page.dart` (`_count`) | `AnimatedSwitcher` com `layoutBuilder` alinhado ao início (`Alignment.centerStart`) e `SizedBox(width: AppSpace.s16)` entre o número e o rótulo. |
| M8 | Novo pedido em compacto (`novo-pedido-320`, `-telemovel-1.3`) | O resumo da barra fixa ocupa 3 linhas (nome + tipos em 2): a barra tem 172 de 700 a 320 e ~190 de 844 a 1.3, e a zona de trabalho fica com menos de 2/3 da janela. A composição pede o resumo numa linha em compacto. | `new_request_page.dart` (`_bar`) | Em compacto, a linha dos tipos com `maxLines: 1` e reticências (o nome já tem 1). O texto completo fica na leitura de ecrã da região "Resumo do pedido". |
| M9 | Novo pedido, motion das folhas e dos itens | Pendente conhecido, confirmado: tipo desmarcado e item tirado desaparecem a seco (`novo-pedido-tirar-meio-desktop`, aos 100 ms, já sem a linha); item acrescentado e lista reposta só têm o `realce`, sem a entrada `lento`. E há um defeito novo, visto no código: a `ValueKey('folha-…')` está no `Entering` dentro de um `Padding` sem chave, por isso, ao escolher um tipo anterior no catálogo, as folhas seguintes são recriadas e voltam a fazer a entrada, em vez de deslizarem para o sítio. | `new_request_sections.dart` (e `lib/core/widgets/request_sheet.dart` se a lista de itens for lá) | Chave no widget de topo de cada folha (o `Padding`). Saída simétrica ao `Entering` (`Leaving`: opacidade + altura em `base` / `sair`, a linha fica até acabar), para folhas e itens; envolver itens novos ou repostos em `Entering` (`lento` / `entrar`) além do `realce`. Com "reduzir movimento", corte seco como hoje. |

O outro pendente, **entrada `lento` das linhas novas na ficha, está feito** (`Entering` em `client_file_page.dart`); no golden `ficha-pedidos-criados-meio-desktop` (160 ms) as duas linhas novas estão a meio da altura e com `realce`.

### Menor

| # | Ecrã | O que está diferente | Ficheiro dono | Correção proposta |
| --- | --- | --- | --- | --- |
| m1 | Novo pedido, tipos | "Em curso desde 20 nov 2026" está em `corpoPequeno` (sans); a composição e o render pedem `registo` (mono), como todas as datas. | `lib/core/widgets/check_row.dart` + `new_request_sections.dart` | `CheckRow` ganha `meta` (texto em `registo`) além de `description` (`corpoPequeno`); os tipos usam `meta`. |
| m2 | Novo pedido, repetido | "À espera da sua confirmação" vai para baixo do título da folha em `corpoPequeno`; no render ocupa o lugar de "Pedido 1 de 2", à direita, em `registo`. | `lib/core/widgets/request_sheet.dart` / `new_request_sections.dart` | Passar o texto como `indexLabel` (mesmo sítio e estilo) quando o tipo espera confirmação. |
| m3 | Clientes, linhas ativas (`clientes-*`) | Entre o nome (ligação) e o email há ~35; nas linhas pendentes e recusadas há ~24. O alvo 48 da ligação soma altura e quebra o ritmo da tabela. | `lib/features/mediator/presentation/clients_list.dart` | O alvo da ligação passa a ser o bloco nome + email (passa os 48 sem acrescentar espaço); o sublinhado continua só no nome. |
| m4 | Novo pedido sem cliente (`novo-pedido-escolher-cliente-*`) | A caixa tracejada diz "Escolha pelo menos um tipo…" mesmo sem cliente; o render diz "Escolha o cliente e pelo menos um tipo de seguro para ver aqui a lista que o cliente vai receber." e a barra tinha a 2.ª linha "Ainda sem tipos de seguro". | `lib/features/mediator/presentation/request_copy.dart` / `new_request_page.dart` | Texto da caixa conforme haja ou não cliente; 2.ª linha da barra quando não há tipos. |
| m5 | Notificações, painel e ecrã | A marca de não lida está centrada na altura da linha (a meio do escritório), não na 1.ª linha do título; no painel há régua dupla no topo da lista (régua do cabeçalho + régua da 1.ª linha, a 9 de distância). | `lib/features/notifications/presentation/notifications_body.dart` / `notifications_panel.dart` | Marca alinhada com a 1.ª linha do título (`crossAxisAlignment.start` + o meio da altura de linha do `corpoForte`); a lista do painel começa sem régua de topo. |
| m6 | Os meus pedidos, "Com o acesso retirado" | O apoio "Estes escritórios já não veem…" está em `corpo` `tinta` (17) e pesa mais do que as linhas de pedido; no render está em `corpoPequeno` `tintaMedia`. | `lib/features/client_requests/presentation/my_requests_page.dart` | `corpoPequeno` `tintaMedia`. |
| m7 | Pedido aberto, faixa de etapas | Em médio/largo a data da etapa feita leva hora e parte em duas linhas na coluna de 160 ("27 nov 2026, / 10:14"); em compacto sai só a data. | `lib/core/widgets/stage_strip.dart` | Só a data em todos os tamanhos (a hora já está no cabeçalho do pedido). |
| m8 | Novo pedido, mensagem | O rótulo "Para o cliente (opcional)" é todo `rotulo` 600; no render "(opcional)" vai a 400 `tintaMedia`. | `lib/core/widgets/labeled_field.dart` | Parâmetro `optional` que acrescenta " (opcional)" a 400 `tintaMedia`. |

### Desvios aceites (ficam como estão)

- **Erro ao criar na barra fixa**, por cima do resumo, e não no topo da página como no render: fica junto ao botão onde o olho está e não depende do scroll. Melhor do que o render.
- **Realce das linhas novas da ficha** dentro das margens da coluna (o render saía 12 para cada lado): mantém o alinhamento da moldura.
- **Parte coincidente sublinhada também no email** na escolha do cliente: ajuda a ver porque é que o resultado apareceu.
- **Aviso de sucesso da ficha em duas linhas** ("2 pedidos criados" + detalhe), e não numa só: o mesmo padrão do aviso de email não enviado.

### Estado depois da correção (revisão de 2026-11-28, commit `f6a278c`)

Goldens regenerados pelo flutter-dev (001 e 002) e lidos de novo, sobretudo `*-320`, `*-telemovel-1.3`, `novo-pedido-*`, `clientes-*`, `notificacoes-*` e os da 001 com `PageFrame`.

| Item | Estado | Verificado em |
| --- | --- | --- |
| C1 contador do sino | Feito: 18 × 18, já não toca na régua | `meus-pedidos-telemovel`, `notificacoes-*` |
| C2 título do painel | Feito: "Notificações" numa linha, cabeçalho com ~96 de altura | `notificacoes-tablet`, `-desktop` |
| M1 separador sem reticências (opção A) | Feito: "Os meus dados" inteiro a 320 e a 390 com 1.3; a 320 com 1.3 o "Sair" perde o ícone e fica a palavra | `meus-pedidos-320`, `-telemovel-1.3`; 001 `com-quem-partilho-320-1.3` |
| M2 altura dos itens editáveis | Feito: 57 numa linha (era 73). O alinhamento ainda não está certo (ver N2) | `novo-pedido-completo-desktop` |
| M3 realce da opção ativa | Feito: a linha toda | `novo-pedido-escolher-cliente-desktop` |
| M4 ações dentro do aviso | Feito: repetido e "Reenviar email" dentro da caixa, recuados como o texto; o aviso do repetido alinha com o nome do tipo | `novo-pedido-repetido-desktop`, `ficha-email-falhou-telemovel` |
| M5 faixa offline do Novo pedido | Feito: "Pode continuar a escolher; criar fica disponível quando a ligação voltar." | `novo-pedido-offline-desktop` |
| M6 palavra do trilho | Feito: desce para baixo dos segmentos numa linha. Fica uma inconsistência pequena (ver N3) | `clientes-desktop`, `ficha-desktop` |
| M7 números do admin em compacto | Feito: alinhados ao início, com `s16` até ao rótulo | `admin-320` |
| M8 resumo da barra em compacto | Feito: uma linha de tipos com reticências | `novo-pedido-320` |
| M9 motion de folhas e itens | Feito no código: `ExitingList` (`base` / `sair`) nas folhas e nos itens, e a chave da folha no widget de topo. O golden `novo-pedido-tirar-meio-desktop` não apanha a saída porque o scroll do `ensureVisible` a deixa fora da janela; o frame fica por ver | código (`exiting_list.dart`, `request_sheet.dart`, `new_request_sections.dart`) |
| m1 "Em curso desde" em `registo` | Feito | `novo-pedido-completo-desktop` |
| m2 "À espera da sua confirmação" | Feito: à direita, no lugar de "Pedido x de n" | `novo-pedido-repetido-desktop` |
| m3 nome → email nas linhas ativas | Feito, mas a correção passou do ponto (ver N1) | `clientes-desktop` |
| m4 copy sem cliente | Feito: caixa e 2.ª linha da barra | `novo-pedido-escolher-cliente-desktop` |
| m5 marca de não lida e régua dupla | Feito | `notificacoes-*` |
| m6 apoio do acesso retirado | Feito: `corpoPequeno` `tintaMedia` | `notificacoes-tablet` (fundo) |
| m7 data na faixa de etapas | Não revisto em PNG nesta passagem (o flutter-dev dá-o como feito) | n/a |
| m8 "(opcional)" | Feito: 400 `tintaMedia` | `novo-pedido-completo-desktop` |

Nada crítico novo. Ficam três itens novos:

| # | Ecrã | O que está diferente | Ficheiro dono | Correção proposta |
| --- | --- | --- | --- | --- |
| N1 (médio) | Clientes, largo e médio (`clientes-desktop`, `-tablet`) | As linhas ativas passaram a padding vertical `s4` (`clients_list.dart`, `link == null ? s12 : s4`) e medem 60 a 64, enquanto as pendentes e recusadas medem 76. O carimbo "ATIVO" fica a 7 da régua de cima, contra 12 nas outras. A tabela perde o ritmo, agora no sentido oposto. A regra do `s4` só vale quando o alvo de 48 é o elemento mais alto da linha, o que aqui não acontece (carimbo + data + trilho já passam os 48). | `lib/features/mediator/presentation/clients_list.dart` | `s12` em todas as linhas da tabela. O bloco nome + email continua a ser o alvo (já passa os 48) e não precisa de padding próprio. Regra esclarecida em DESIGN.md. |
| N2 (menor) | Folhas do Novo pedido, médio/largo | Na linha de item há três alturas diferentes: a natureza ("Documento", `rotulo` 14/20) está ~3 acima da 1.ª linha do texto (`corpo` 17/26) e o "Tirar" (alvo 48) está ~3 abaixo dela. | `lib/core/widgets/request_item_row.dart` | Alinhar pela linha de base: `Row` com `CrossAxisAlignment.baseline`, ou recuo de topo de 3 na natureza ((26 − 20) / 2) e o "Tirar" centrado na 1.ª linha (recuo negativo de (48 − 26) / 2 = 11 dentro do padding `s4`). |
| N3 (menor) | Clientes, coluna Pedidos (largo) | Na mesma coluna, umas linhas têm a palavra ao lado dos segmentos ("Criado") e outras por baixo ("Documentos enviados"), conforme o comprimento. | `lib/core/widgets/stage_track.dart` (ou quem o chama em `clients_list.dart`) | Em colunas estreitas (`colunaEtapa` 200), a palavra vai sempre por baixo dos segmentos (parâmetro `stacked` decidido pela coluna, não pela palavra). Opcional: só se vê a partir da 003. |

**Fecho (28/11, lead):** N1, N2 e N3 corrigidos em `6c612f0` (Clientes com `s12` em todas as linhas e trilho `stacked` na coluna Pedidos; alinhamento da linha do item confirmado pelo lead em `novo-pedido-completo-desktop.png`). Polimento da 002 fechado; goldens de 001 e 002 regenerados (133).
