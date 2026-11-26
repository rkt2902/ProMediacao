# 03 Design: 001 Fundação (autenticação, perfis, escritórios e consentimento)

> **Gate 2 aprovado (2026-11-26):** direção "Dossiê arrumado" e fontes Source Serif 4 + Atkinson Hyperlegible Next/Mono. Emendas incorporadas: o cliente pede um link novo no ecrã de entrada e no ecrã de link expirado; os pedidos pendentes aparecem dentro da app em "Com quem partilho" para clientes com conta; o mediador tem "Reenviar pedido"; os recusados aparecem na lista do mediador sem ações; tratamento formal; bloqueio de 60 s nos reenvios.
>
> **Revisão responsiva (2026-11-26, decisão web-first em `docs/decisions.md`):** a app corre no navegador, sem instalação. Os ecrãs de cliente e de mediador deixam de ter um tamanho "primeiro": cada um tem composição explícita em compacto (telemóvel, < 640), médio (tablet, 640 a 1100) e largo (desktop, > 1100), com a mesma qualidade nos três. Só o admin é desktop-first. Ver "Responsividade" abaixo e a secção com o mesmo nome em DESIGN.md.
>
> Classificação: **transformação visível** (não existe identidade: a app é o contador por defeito). Esta feature fixa a direção de arte do produto em `docs/design/DESIGN.md`; os tokens citados aqui (`AppColors.papel`, `AppType.titulo`, `AppMotion.base`...) estão todos definidos lá.
> Referência: o protótipo HTML "Dossier" não está no repositório (só `docs/reference/prototipo/README.md`) e os links de artefacto não foram abertos. Usou-se a descrição da secção 6 de `docs/business/context.md`. O protótipo não cobre login, consentimento nem admin, por isso estes ecrãs são desenhados de raiz.

## Diagnóstico

- **Tarefa principal:** o cliente decide, de forma consciente, que escritório vê os seus dados e consegue desfazer essa decisão sozinho; o mediador põe um cliente "à espera de aceitar" em menos de um minuto.
- **O que falha hoje:** não há ecrã nenhum. O risco concreto é o default: Material 3 com seed azul, AppBar, cartões com elevação e um "Aceitar" grande ao lado de um "Recusar" pequeno, o que faz a app parecer um banco e empurra o cliente para o "sim".

## Direção

- **Escolhida: "Dossiê arrumado".** Papel e tinta, um único acento cor de cartolina no separador de pasta que diz em nome de quem se está a ver, títulos em serifa, estados como carimbos (ícone + palavra), listas com réguas em vez de cartões.
- **Porquê:** o produto é literalmente um dossiê do cliente partilhado com escritórios. O separador de pasta responde à pergunta mais importante de privacidade ("quem está a ver isto?") em todos os ecrãs, sem decoração gratuita. Tinta sobre papel dá confiança pelo contraste (15:1) e não pela cor institucional, por isso não lembra seguradoras nem bancos. A Atkinson Hyperlegible no corpo serve os clientes com pouca destreza ou visão.
- **Descartadas:**
  1. *Material institucional* (seed azul, escudos e cadeados, cartões com sombra, AppBar): é a mais previsível e parece exatamente uma seguradora ou um banco.
  2. *Livro de registo* (tudo monoespaçado, linhas com data e hora como num livro-razão, linguagem de auditoria): diferenciadora e honesta, mas fria e difícil para clientes pouco digitais. Fica só a fonte mono para datas e versões.

## Fixtures (para goldens e revisão)

- Escritório: "Ribeira Seguros". Caso longo: "Gabinete de Mediação de Seguros Vale do Sousa & Filhos, Lda."
- Mediadora: "Ana Martins". Admin sem nome visível.
- Clientes: "Maria do Carmo Figueiredo" (ativa, desde 12 nov 2026, 10:04); "Construções Teixeira & Irmão, Unipessoal Lda." (pendente, enviado 25 nov 2026, 15:04); "João Pedro Albuquerque de Vasconcelos Sampaio" com `joao.pedro.albuquerque.vasconcelos@correio-exemplo.pt` (caso longo, pendente).
- Contagens: 1 escritório, 3 mediadores, 12 clientes.

## Estrutura comum

- `PageFrame`: fundo `papel`; margens `s16` / `s32` / `s48` (compacto / médio / largo); topo com a marca "ProDossier" em `rotulo` `tintaMedia` à esquerda e o menu da conta à direita (ver "Conta e navegação por tamanho" abaixo). Em largo, a moldura inteira (marca, conta, separador, conteúdo) tem largura máxima `larguraLista` 1040 e fica **centrada na janela**; dentro dela tudo alinha à esquerda. Em compacto e médio ocupa a janela menos as margens.
- `FolderTab` colado ao topo da área de conteúdo (`separadorAltura` 40, `cartolina`, `AppRadius.separador` em cima), texto `rotulo` `tinta`: "Ribeira Seguros" (mediador), "Administração" (admin), "Os meus dados" (cliente) ou "Pedido de acesso" (consentimento). Por baixo, uma régua `regua` com a largura da moldura: a "pasta" é o ecrã. Nome de escritório longo no separador: uma linha com reticências; o separador nunca passa de `larguraFormulario` 400 em médio/largo, nem da largura toda menos `s48` em compacto (o nome completo está no título ou na leitura de ecrã).
- Sem AppBar nem barra de navegação (inferior ou lateral) nesta feature, em nenhum tamanho: cada perfil tem só 1 ou 2 ecrãs, e as passagens entre eles são botões com texto dentro do conteúdo.

## Responsividade

Regras gerais em DESIGN.md ("Responsividade (web)"). O que se aplica a todos os ecrãs desta feature:

- **Tamanho pela largura lógica da janela**, não pelo aparelho: um desktop com zoom de 200% ou uma janela estreita recebe o layout compacto, e um tablet deitado (1180) recebe o largo. Largura mínima suportada: 320 (zoom de 400% num portátil), sem scroll horizontal.
- **Os alvos não encolhem com a largura.** Toque é possível em qualquer tamanho (tablets deitados e portáteis com ecrã tátil caem em largo): mínimo `alvoMinimo` 48 em tudo o que se carrega, `alvoPrincipal` 56 nas ações principais do cliente em todos os tamanhos e nas ações principais de mediador e admin em compacto (48 em médio/largo).
- **Rato:** cursor de clique em tudo o que se carrega e de texto nos campos; hover só reforça (fundo/contorno em `rapido`), nunca é o único sítio onde aparece informação. Tooltips abrem com hover, foco de teclado **e** toque longo; e a razão de um botão desativado está sempre escrita por baixo, não só no tooltip.
- **Teclado** (qualquer tamanho, obrigatório em largo): Tab segue a ordem de leitura; anel de foco `foco` 2 com `AppStroke.focoAfastamento` 2, só quando a navegação é por teclado; Enter submete o formulário a partir do último campo; Esc fecha folhas e diálogos (= Cancelar); dentro de folhas e diálogos o foco fica preso e, ao fechar, volta ao botão que os abriu. Nenhum atalho de teclado próprio nesta feature.
- **Navegador:** cada ecrã tem endereço próprio (os links do email abrem-no direto); o botão "voltar" do navegador fecha primeiro a folha ou o diálogo aberto e só depois muda de ecrã. Texto de consentimento, emails e nomes são selecionáveis para copiar (rato e toque longo).
- **Teclado virtual (telemóvel e tablet):** o campo com foco e o botão de envio ficam visíveis acima do teclado (o ecrã faz scroll até eles). Em compacto não há foco automático no primeiro campo ao abrir um ecrã (abriria o teclado por cima do contexto); em médio/largo há. Campos com o tipo de teclado e o preenchimento automático certos (email, palavra-passe nova/atual). O texto dos campos é 17, o que evita o zoom automático do Safari no iOS.
- **Altura baixa** (telemóvel deitado, altura < `AppBreakpoints.alturaBaixa` 480): as barras fixas em baixo perdem a linha de texto de apoio (passa para o fim do scroll) e o padding vertical passa de `s16` a `s8`; as folhas inferiores ocupam a altura toda menos `s16` em cima.
- **Faixas e barras fixas** (`OfflineBar`, barra de ações do consentimento, barra de botões das folhas): o fundo ocupa a largura da janela; o conteúdo alinha com a coluna do ecrã (mesma margem esquerda e mesma largura máxima), em todos os tamanhos.
- **Folhas e diálogos por tamanho:**
  - `ConfirmSheet` de decisão (retirar acesso): compacto, folha inferior à largura da janela, cantos superiores `AppRadius.superficie`, padding `s24` e o espaço seguro de baixo respeitado, botões empilhados a toda a largura; médio e largo, diálogo centrado de `AppSize.dialogo` 480, botões lado a lado ("Cancelar" à esquerda, ação à direita). Véu `AppColors.veu`, sombra `AppShadow.superficie`. Fecha com "Cancelar", Esc, toque no véu e "voltar" do navegador; arrastar para baixo também fecha a folha, mas nunca é a única forma. Foco inicial em "Cancelar": Enter nunca dispara a ação destrutiva por acidente.
  - `ConfirmSheet` só de leitura (texto aceite): compacto, folha inferior com altura máxima da janela menos `s48`, texto com scroll e "Fechar" fixo em baixo; médio e largo, diálogo de `larguraLeitura` 640 (não 480: é texto longo), altura máxima da janela menos 2 × `s48`, mesmo scroll e "Fechar".
  - Folha lateral de formulário (criar cliente; no admin, criar escritório e convidar): largo e médio, `folhaLateral` 440 encostada à direita, altura toda, véu sobre o resto, botões numa barra fixa no fundo da folha; compacto, ecrã inteiro (rota própria) com os botões **no fluxo, a seguir aos campos** e não fixos, porque o teclado virtual ocupa metade do ecrã. Foco inicial no primeiro campo (exceto compacto, pela regra do teclado virtual).

### Conta e navegação por tamanho

| | Compacto | Médio | Largo |
| --- | --- | --- | --- |
| Linha do topo | Marca à esquerda; à direita só `TextAction` "Sair" (ícone `logout` + palavra, alvo 48). A leitura de ecrã diz "Sair da conta de Ana Martins" | Marca à esquerda; à direita o nome ("Ana Martins", `rotulo` `tintaMedia`, uma linha, reticências) + `s16` + "Sair" | Igual ao médio, alinhado com a moldura centrada de 1040 |
| Cliente | Só "Sair" nos três tamanhos (o cliente sabe quem é; o separador "Os meus dados" já o diz) | idem | idem |
| Entre ecrãs | Botões com texto no conteúdo ("Responder", "Ver com quem partilho") e o `TextAction` "Com quem partilho" com ícone `arrow_back` no consentimento (ver ecrã 3); "voltar" do navegador funciona sempre | idem | idem |
| Sair | Sem confirmação; volta a Entrar com o separador do perfil que saiu | idem | idem |

## Ecrãs

### 1. Entrar (cliente, mediador e admin)

Um só ecrã de entrada com dois separadores de pasta: "Sou cliente" (link por email, sem palavra-passe) e "Trabalho num escritório" (email e palavra-passe). O cliente nunca fica sem saída: se o link expirou, pede outro aqui sem depender do mediador.

- **Hierarquia:** 1.º a escolha entre os dois separadores; 2.º o título "Entrar" e o(s) campo(s) do separador ativo; 3.º o botão principal; 4.º ligações secundárias ("Esqueci-me da palavra-passe").
- **Composição:** sem cartão nem hero. Coluna de 400 alinhada à esquerda na grelha (em largo começa a 1/3 da largura; em compacto ocupa a largura toda), a `s72` do topo em largo e `s32` em compacto. No topo da coluna, `FolderTabs` com os dois separadores lado a lado (50/50, `alvoMinimo` 48): o ativo em `cartolina` com texto `tinta`, o inativo em `papel` com contorno `regua` e texto `tintaMedia`; régua de largura total por baixo. Título "Entrar" a `s32` do separador; campos empilhados com `s16`; botão a `s24` dos campos, largura da coluna, `alvoPrincipal`. Separador inicial: "Sou cliente" na primeira visita; depois, o último usado neste dispositivo.
- **Separador "Sou cliente":** um campo "Email" e `PrimaryButton` "Enviar link de acesso". Depois de enviar, o formulário é substituído por uma `InlineNotice` (fundo `realce`) com a confirmação, o email em `corpoForte` e `TextAction` "Enviar outra vez" (bloqueado 60 s, com a razão escrita) e "Usar outro email". A resposta é igual exista ou não a conta.
- **Separador "Trabalho num escritório":** "Email", "Palavra-passe", `PrimaryButton` "Entrar", `TextAction` "Esqueci-me da palavra-passe".
- **Componentes e tokens:** `FolderTabs` (novo, ver DESIGN.md), `LabeledField` (rótulo `rotulo`, campo `campo` 52, contorno `reguaForte` `controlo` 1.5, `AppRadius.controlo`, foco `foco` 2); `PrimaryButton` (`tinta` / `sobreTinta`); `TextAction`; `InlineNotice`.
- **Copy:**
  - Separadores: "Sou cliente" / "Trabalho num escritório"
  - Título (ambos): "Entrar"
  - Cliente, apoio (`corpoPequeno` `tintaMedia`): "Indique o seu email. Enviamos-lhe um link para entrar, sem palavra-passe."
  - Cliente, botão: "Enviar link de acesso"; a carregar: "A enviar…"
  - Cliente, confirmação: "Se este email tiver acesso ao ProDossier, o link chega a {email} dentro de alguns minutos. Abra-o neste dispositivo. Veja também a pasta de spam."; ações "Enviar outra vez" (depois de enviar: "Pode enviar outra vez daqui a 1 minuto.") e "Usar outro email"
  - Escritório, apoio: "Para mediadores e administração."
  - Escritório, campos: "Email", "Palavra-passe"; ação no campo: "Mostrar" / "Ocultar"
  - Escritório, botão: "Entrar"; a carregar: "A entrar…"
  - Ligação: "Esqueci-me da palavra-passe"
  - Erro de credenciais: "Email ou palavra-passe incorretos."
  - Campo vazio: "Escreva o seu email." / "Escreva a palavra-passe."; email mal escrito: "Escreva um email completo, por exemplo nome@exemplo.pt."
  - Sessão terminada: "A sua sessão terminou. Entre de novo para continuar."

### 1b. Recuperar e definir palavra-passe

- **Hierarquia:** 1.º título; 2.º um campo; 3.º confirmação.
- **Composição:** igual a "Entrar". Depois de enviar, o formulário é substituído por uma `InlineNotice` (fundo `realce`) com a confirmação e "Voltar a entrar".
- **Copy (recuperar):** título "Recuperar palavra-passe"; texto "Indique o email da sua conta. Se existir, enviamos um link para definir uma nova palavra-passe."; botão "Enviar link" / "A enviar…"; confirmação (igual exista ou não a conta): "Se houver uma conta com este email, o link chega dentro de alguns minutos. Veja também a pasta de spam."; ligação "Voltar a entrar".
- **Copy (definir, vindo da recuperação ou do convite de mediador):** título "Definir palavra-passe"; para convite, linha de apoio "Foi convidado para a Ribeira Seguros." (nome do escritório em `corpoForte`); campo "Nova palavra-passe"; regra visível com ícone que muda de vazio para visto: "Pelo menos 10 caracteres"; botão "Guardar e entrar"; link expirado: título "Este link já não é válido", texto "Por segurança, os links expiram. Peça um novo em Recuperar palavra-passe ou ao administrador, se foi convidado."

### 2. Abrir o link (cliente)

Estados de passagem antes do consentimento ou de "Com quem partilho".

- **A validar:** skeleton do ecrã de consentimento (separador, bloco do título, 3 linhas). Sem spinner de página.
- **Link expirado ou inválido:** `FolderTab` "Os meus dados"; título "Este link já não é válido"; texto "Os links de acesso expiram ao fim de algum tempo, por segurança. Peça um novo aqui: basta o seu email."; campo "Email" e `PrimaryButton` "Enviar link novo" (mesmo comportamento e confirmação do separador "Sou cliente" do ecrã 1); por baixo, `corpoPequeno` `tintaMedia`: "Também pode pedir ao seu mediador que reenvie o pedido." Depois de entrar com o link novo, os pedidos pendentes aparecem em "Com quem partilho" (ecrã 4), por isso o cliente não perde o pedido original.
- **Pedido já respondido:** vai direto para "Com quem partilho", com `InlineNotice` "Já respondeu a este pedido a 26 nov 2026, 14:32."

### 3. Aceitar partilha (consentimento) [cliente, telemóvel primeiro]

- **Hierarquia:**
  1. Quem pede: o nome do escritório em `titulo` (26 em compacto, 30 em médio/largo) seguido de "pede acesso aos seus dados", e por baixo quem enviou ("Enviado por Ana Martins, mediadora", `corpoPequeno`).
  2. O que significa: resumo em 3 linhas com réguas (ícone + frase), antes do texto completo.
  3. A decisão: "Recusar" e "Aceitar", com o mesmo tamanho, numa barra fixa em baixo.
- **Composição:** coluna `larguraLeitura` 640, alinhada à esquerda em largo. Ordem: `FolderTab` "Pedido de acesso"; título a `s32`; remetente a `s8`; resumo a `s32` (3 `RuledRow`, ícone 24 `tinta` + `corpo`); título de secção "Texto completo" (`rotulo`) a `s48`; texto completo em `corpo`, parágrafos numerados com `s16` entre eles; no fim, `registo` "Versão do texto: v0-rascunho". O ecrã inteiro faz scroll; a barra de ações (`folha`, régua no topo, padding `s16`) fica sempre visível. Botões lado a lado em todos os tamanhos (50/50 com `s12` de intervalo), `alvoPrincipal` 56; "Recusar" à esquerda como `SecondaryButton`, "Aceitar" à direita como `PrimaryButton`. Por cima dos botões, `registo` `tintaTenue`: "A sua resposta fica registada com data e hora." Não se obriga a fazer scroll até ao fim para ativar "Aceitar" (prejudica a acessibilidade; o resumo garante a leitura do essencial).
- **Depois de responder:** a barra de ações é substituída por um bloco de resultado no fim do resumo, e o foco de leitura de ecrã passa para esse bloco.
  - Aceitou: `StatusStamp` ativo + "Partilha ativa desde 26 nov 2026, 14:32" (`registo`) + frase "A Ribeira Seguros já pode ver os seus dados. Pode retirar o acesso quando quiser." + `PrimaryButton` "Ver com quem partilho".
  - Recusou: `StatusStamp` recusado + "Recusado a 26 nov 2026, 14:32" + "A Ribeira Seguros não tem acesso aos seus dados nem documentos. Se mudar de ideias, peça ao escritório um novo pedido." + `PrimaryButton` "Ver com quem partilho".
- **Componentes e tokens:** `FolderTab`, `RuledRow`, `PrimaryButton`, `SecondaryButton`, `StatusStamp`, `InlineNotice`; `AppType.titulo`, `corpo`, `corpoPequeno`, `rotulo`, `registo`; `AppColors.papel`, `folha`, `tinta`, `regua`.
- **Copy (ecrã):**
  - Separador: "Pedido de acesso"
  - Título: "Ribeira Seguros" / linha seguinte em `corpoForte`: "pede acesso aos seus dados"
  - Remetente: "Enviado por Ana Martins, mediadora"
  - Resumo:
    - (ícone visibilidade) "Vê os dados e documentos que guardar aqui, incluindo dados de saúde, se os enviar."
    - (ícone visibilidade riscada) "Não sabe com que outros escritórios partilha, e eles não sabem deste."
    - (ícone desfazer) "Pode retirar o acesso quando quiser, em Com quem partilho."
  - Secção: "Texto completo"
  - Botões: "Recusar" / "Aceitar"; a enviar: "A registar…" no botão carregado, o outro fica desativado.

**Texto de consentimento `v0-rascunho` (A VALIDAR PELO JURISTA; não usar com clientes reais):**

> **Autorização de acesso aos seus dados**
>
> Ao carregar em Aceitar, autoriza o escritório **{escritório}** a aceder aos dados e documentos que guardar no ProDossier, nos termos seguintes.
>
> 1. **Quem tem acesso.** Todas as pessoas que trabalham no {escritório} e usam o ProDossier. Mais ninguém: outros escritórios não veem os seus dados e a administração da plataforma também não.
> 2. **Que dados.** Os dados do seu perfil e os documentos que carregar ou que o escritório lhe pedir. Podem incluir dados de saúde, por exemplo questionários médicos para seguros de vida, saúde ou doenças graves.
> 3. **Para quê.** Só para preparar simulações, propostas e alterações dos seus seguros. Os documentos podem ser lidos por um sistema automático para preencher campos; quem confirma os dados é sempre o mediador.
> 4. **Durante quanto tempo.** Enquanto não retirar o acesso.
> 5. **Como retirar.** A qualquer momento, em Com quem partilho, com o botão Retirar acesso. A partir desse momento o escritório deixa de ver os seus dados e documentos no ProDossier, incluindo o que escreveu no seu perfil. Retirar não desfaz o que o escritório já tenha enviado a seguradoras antes disso.
> 6. **Se recusar.** O escritório não tem acesso aos seus dados nem documentos. Recusar não tem qualquer custo nem consequência na app.
> 7. **Registo.** Guardamos a data e a hora em que aceitou, recusou ou retirou, e a versão deste texto, para que possa sempre comprovar o que autorizou.
> 8. **Responsável e contactos.** {A definir pelo jurista: responsável pelo tratamento, contacto para exercer os seus direitos, direito de reclamação à CNPD.}
>
> Versão v0-rascunho.

Notas para o jurista e para o pm: a base de licitude (pergunta 1 do briefing) pode mudar o verbo "autoriza"; o ponto 3 refere a extração automática, que só chega em features seguintes; o ponto 5 assume a decisão 2 = A do gate 1 e a resposta à pergunta 5 do briefing.

### 4. Com quem partilho [cliente; ecrã inicial do cliente]

É sempre o ecrã onde o cliente aterra ao entrar (pelo separador "Sou cliente" ou por um link genérico). Um link de um pedido concreto continua a abrir direto o ecrã 3. Os pedidos pendentes aparecem aqui também quando o cliente já tem conta e o escritório lhe enviou um pedido sem link: não é preciso email para responder.

- **Hierarquia:**
  1. Se houver pedidos pendentes: o bloco "À espera da sua resposta", no topo e acima de tudo o resto.
  2. A frase-resumo ("Partilha os seus dados com 2 escritórios.") e os escritórios com acesso, com nome, carimbo e data.
  3. A ação de cada linha ("Retirar acesso") e a explicação do que retirar faz.
- **Composição:** `FolderTab` "Os meus dados"; título "Com quem partilho" (`titulo`).
  - **Bloco de pedidos pendentes** (só se existir algum), a `s24` do título: superfície `realce` com `AppRadius.superficie`, padding `s24` (`s16` em compacto), sem sombra. Cabeçalho `subtitulo` "À espera da sua resposta" + `corpo` "Estes escritórios pedem acesso aos seus dados. Nada é partilhado até responder." Cada pedido é uma `RuledRow` (réguas `regua` dentro do bloco): nome do escritório em `corpoForte`, "Enviado por Ana Martins, mediadora" em `corpoPequeno` `tintaMedia`, `StatusStamp` pendente + `registo` "Pedido a 25 nov 2026, 15:04", e `PrimaryButton` "Responder" (`alvoPrincipal` 56; a toda a largura em compacto, à direita nos outros), que abre o ecrã 3. É o único bloco com fundo de cor no ecrã, para ser a primeira coisa vista. O leitor de ecrã anuncia-o ao entrar ("Tem 1 pedido de acesso à espera da sua resposta.").
  - **Frase-resumo** em `corpoForte` a `s48` do bloco (ou a `s8` do título se não houver bloco).
  - Dois grupos por baixo, cada um com cabeçalho `rotulo` e lista com réguas, separados por `s48`, mostrados só se tiverem linhas: 1) "Com acesso" (ativos); 2) "Sem acesso" (recusados e retirados).
  - Cada linha (`RuledRow`, padding vertical `s16`): nome do escritório em `subtitulo` (até 2 linhas, depois reticências; nome completo na leitura de ecrã); por baixo, `StatusStamp` + `registo` com a data; à direita em médio/largo, ou por baixo a toda a largura em compacto, a ação com `alvoMinimo` 48. Ativos: `SecondaryButton` com texto `erro` "Retirar acesso" e `TextAction` "Ler o texto aceite" (abre o texto da versão aceite numa `ConfirmSheet` só de leitura). Sem acesso: sem ação. Rodapé `corpoPequeno` `tintaMedia` a `s48`. Coluna máxima `larguraLeitura`.
- **Depois de responder a um pedido (vindo do ecrã 3):** o pedido sai do bloco; se aceitou, entra em "Com acesso" com fundo `realce` a desvanecer; se recusou, entra em "Sem acesso". Quando o último pedido sai, o bloco fecha.
- **Confirmação de retirada (`ConfirmSheet`: folha inferior em compacto, diálogo de 480 em médio/largo):** título `subtitulo`; texto `corpo`; `DestructiveButton` "Retirar acesso" e `SecondaryButton` "Cancelar", empilhados em compacto (destrutivo em cima), lado a lado nos outros. Sem "anular" depois: voltar a dar acesso exige um novo pedido e um novo consentimento.
- **Depois de retirar:** a linha sai de "Com acesso" e entra em "Sem acesso" com fundo `realce` a desvanecer, carimbo "Retirado" e "Retirado a 26 nov 2026, 15:02"; `InlineNotice` no topo: "Acesso retirado. A Ribeira Seguros já não vê os seus dados." A frase-resumo atualiza.
- **Componentes e tokens:** `FolderTab`, `RuledList`, `RuledRow`, `StatusStamp`, `SecondaryButton`, `PrimaryButton`, `DestructiveButton`, `TextAction`, `ConfirmSheet`, `InlineNotice`, `SkeletonRows`; `AppColors.erro` só no botão de retirar e no destrutivo.
- **Copy:**
  - Título: "Com quem partilho"
  - Frase-resumo: "Partilha os seus dados com 1 escritório." / "Partilha os seus dados com {n} escritórios." / "Neste momento não partilha os seus dados com nenhum escritório."
  - Bloco pendente: "À espera da sua resposta" / "Estes escritórios pedem acesso aos seus dados. Nada é partilhado até responder." (com 1 pedido: "Este escritório pede acesso aos seus dados. Nada é partilhado até responder."); remetente "Enviado por {mediador}, mediador(a)"; botão "Responder"; anúncio "Tem {n} pedido(s) de acesso à espera da sua resposta."
  - Grupos: "Com acesso", "Sem acesso"
  - Datas: "Desde 12 nov 2026, 10:04" / "Pedido a 25 nov 2026, 15:04" / "Recusado a 20 nov 2026, 09:12" / "Retirado a 26 nov 2026, 15:02"
  - Carimbos: "ATIVO", "PENDENTE", "RECUSADO", "RETIRADO"
  - Ações: "Retirar acesso", "Ler o texto aceite", "Responder"
  - Diálogo: título "Retirar o acesso da Ribeira Seguros?"; texto "A partir de agora, ninguém deste escritório vê os seus dados e documentos no ProDossier, incluindo o que o mediador escreveu no seu perfil. Para voltar a partilhar, o escritório terá de lhe enviar um novo pedido."; botões "Retirar acesso" / "Cancelar"; a enviar: "A retirar…"
  - Rodapé: "Retirar é imediato e não precisa de justificação. Cada resposta fica registada com data, hora e a versão do texto que aceitou."
  - Vazio: "Ainda não partilha dados com nenhum escritório." + "Quando um escritório lhe pedir acesso, o pedido aparece aqui."

### 5. Clientes [mediador; desktop e tablet primeiro]

- **Hierarquia:** 1.º título "Clientes" e o botão "Criar cliente"; 2.º a lista com nome e estado; 3.º email, data e "Reenviar pedido".
- **Composição:** `FolderTab` "Ribeira Seguros". Linha de título: "Clientes" (`titulo`) à esquerda, `PrimaryButton` "Criar cliente" à direita na mesma linha de base; por baixo, `registo` "12 clientes · 3 pendentes · 1 recusado". Lista a `s32`, coluna máxima `larguraLista` 1040.
  - Largo e médio: tabela com réguas, cabeçalhos `rotulo` `tintaMedia`. Colunas: **Cliente** (nome em `corpoForte` + email em `corpoPequeno` `tintaMedia`, uma linha cada, reticências; flexível), **Estado** (carimbo, 140), **Data** (`registo`, 200), **Ação** (`TextAction`, 160, alinhada à direita). Linhas com 72 de altura.
  - Compacto: cada linha empilha nome, email, carimbo + data na mesma linha e "Reenviar pedido" a toda a largura com 48. "Criar cliente" passa para baixo do título, a toda a largura.
  - Ordem: alterações mais recentes primeiro. Paginação de 25 com `SecondaryButton` "Mostrar mais 25" no fim (sem números de página).
  - Linhas ativas não têm ação nem são clicáveis nesta feature (a ficha do cliente vem depois): sem seta nem hover de ligação.
  - **Linhas recusadas:** carimbo "Recusado" (`estadoInativo`), data "Recusado a 20 nov 2026, 09:12", célula de ação vazia, sem hover nem clique. O nome mantém-se em `corpoForte` `tinta` (o mediador precisa de o reconhecer) e o email em `tintaMedia`; a leitura de ecrã diz "Recusado. Sem ações disponíveis." O mediador não pode reenviar nem insistir a partir daqui.
  - Clientes que retiraram o acesso não aparecem (regra da spec).
- **Criar cliente:** `folhaLateral` 440 à direita em largo/médio, ecrã inteiro em compacto. Título `subtitulo` "Criar cliente"; texto de apoio; campos "Nome completo" e "Email"; `InlineNotice` informativa; `PrimaryButton` "Criar e enviar pedido" e `SecondaryButton` "Cancelar". Ao confirmar, a folha fecha, a linha nova entra no topo com fundo `realce` e aparece uma `InlineNotice` por cima da tabela. A copy é a mesma quer o cliente receba um email com link (ainda não tem conta) quer veja o pedido dentro da app (já tem conta, eventualmente noutro escritório): o mediador nunca fica a saber se o email já existia.
- **Reenviar pedido** (só em linhas pendentes): `TextAction` na coluna Ação. Passa a "A enviar…" (spinner dentro), depois mostra `registo` "Enviado às 15:04" e fica desativado durante 60 s, com a razão no tooltip e na leitura de ecrã ("Pode reenviar daqui a 1 minuto."). Para um cliente sem conta envia um link novo; para um cliente com conta volta a pôr o pedido no topo do bloco pendente dele. O rótulo é o mesmo nos dois casos.
- **Componentes e tokens:** `FolderTab`, `PageFrame`, `RuledList`, `StatusStamp`, `PrimaryButton`, `SecondaryButton`, `TextAction`, `LabeledField`, `InlineNotice`, `SkeletonRows`; `AppSize.larguraLista`, `folhaLateral`; `AppColors.realce`.
- **Copy:**
  - Título: "Clientes"; contagem: "{n} clientes · {p} pendentes · {r} recusados" (singular: "1 cliente", "1 pendente", "1 recusado"; partes a zero omitem-se)
  - Cabeçalhos: "Cliente", "Estado", "Data", "Ação" (o último só para leitura de ecrã; visualmente vazio)
  - Datas: "Desde 12 nov 2026" (ativo) / "Enviado a 25 nov 2026, 15:04" (pendente) / "Recusado a 20 nov 2026, 09:12" (recusado)
  - Carimbos: "ATIVO", "PENDENTE", "RECUSADO"
  - Ação: "Reenviar pedido" / "A enviar…" / "Enviado às 15:04"
  - Folha: título "Criar cliente"; apoio "O cliente recebe o pedido com o nome da Ribeira Seguros e o seu: por email ou, se já usar o ProDossier, dentro da app. Só vê os dados dele depois de ele aceitar."; campos "Nome completo", "Email"; nota "Até o cliente aceitar, vê apenas o nome, o email e o estado do pedido."; botões "Criar e enviar pedido" / "A criar…" / "Cancelar"
  - Sucesso: "Pedido enviado a maria.figueiredo@exemplo.pt. O acesso fica pendente até o cliente aceitar."
  - Erros: "Escreva o nome do cliente." / "Escreva um email completo, por exemplo nome@exemplo.pt." / "Este email já é cliente da Ribeira Seguros." / "O cliente foi criado, mas o pedido não seguiu. Tente Reenviar pedido daqui a pouco."
  - Nota: um email que já é cliente de outro escritório tem a mesma resposta de sucesso (não se revela nada).
  - Vazio: título de estado "Ainda não tem clientes" + "Crie o primeiro cliente. Ele recebe um pedido para aceitar a partilha dos dados com a Ribeira Seguros." + `PrimaryButton` "Criar cliente"

### 6. Painel do admin [desktop]

- **Hierarquia:** 1.º as 3 contagens; 2.º a lista de escritórios e "Criar escritório"; 3.º a nota de privacidade.
- **Composição:** `FolderTab` "Administração"; título "Plataforma". Contagens numa única faixa, **não** em 3 cartões: três colunas iguais separadas por réguas verticais `regua`, cada uma com o número em `numero` (56, serifa, tabular) e o rótulo por baixo em `rotulo` `tintaMedia`; a faixa tem réguas em cima e em baixo e padding vertical `s24`. Em compacto as três ficam empilhadas com o número à esquerda e o rótulo à direita na mesma linha. Por baixo, a `s8`, a nota de privacidade em `corpoPequeno` `tintaTenue`. A `s48`, secção "Escritórios" (`subtitulo`) com `PrimaryButton` "Criar escritório" à direita; lista com réguas: nome do escritório (`corpoForte`), `registo` "3 mediadores", `TextAction` "Convidar mediador". Sem nomes nem emails de pessoas em lado nenhum.
- **Criar escritório / Convidar mediador:** `folhaLateral` com um formulário cada.
- **Componentes e tokens:** `FolderTab`, `RuledList`, `PrimaryButton`, `TextAction`, `LabeledField`, `InlineNotice`, `SkeletonRows`; `AppType.numero`.
- **Copy:**
  - Título: "Plataforma"
  - Contagens: "Escritórios", "Mediadores", "Clientes"
  - Nota: "Só contagens. Por privacidade, a administração não vê nomes, emails nem documentos."
  - Lista: "{n} mediadores" (singular "1 mediador"; zero "Sem mediadores")
  - Criar escritório: título "Criar escritório"; campo "Nome do escritório"; botão "Criar escritório" / "A criar…"; sucesso "Escritório criado. Convide agora o primeiro mediador."; erro "Já existe um escritório com este nome."
  - Convidar mediador: título "Convidar mediador"; campos "Email" e "Escritório" (preenchido quando se vem de uma linha); apoio "O mediador recebe um email para definir a palavra-passe. Cada mediador pertence a um só escritório."; botão "Enviar convite" / "A enviar…"; sucesso "Convite enviado."; erro "Não foi possível convidar este email. Pode já pertencer a um escritório."
  - Vazio: "Ainda não há escritórios." + "Crie o primeiro escritório para poder convidar mediadores." + `PrimaryButton` "Criar escritório"; contagens a "0".

## Matriz de estados

Ação principal de cada estado entre parênteses. Offline: `OfflineBar` no topo (fundo `tinta`, texto `sobreTinta`, ícone "cloud_off") com "Sem ligação à internet. Pode ver o que está no ecrã; as alterações ficam bloqueadas até a ligação voltar."; nunca se mostra como aceite, recusado ou retirado algo que o servidor não confirmou.

| Ecrã | Populado | Vazio | A carregar | Erro | Offline | Desativado | Sem acesso / sessão |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Entrar | Cliente: email preenchido (Enviar link de acesso); depois, confirmação com "Enviar outra vez". Escritório: campos preenchidos (Entrar) | Separador inicial vazio, foco no Email | Spinner no botão ("A enviar…" / "A entrar…"); campos só de leitura | Escritório: "Email ou palavra-passe incorretos." por cima do botão, foco no Email. Ambos: "Não foi possível ligar. Verifique a ligação e tente de novo." (repetir) | Faixa com texto próprio: "Sem ligação à internet. Precisa de ligação para entrar." (nenhuma) | Botão desativado com razão por baixo se offline; "Enviar outra vez" bloqueado 60 s | Sessão terminada: mensagem por cima do formulário, no separador do perfil que saiu |
| Recuperar / definir palavra-passe | Email ou nova palavra-passe preenchidos (Enviar link / Guardar e entrar) | Campo vazio (idem) | Spinner no botão | Link expirado: ecrã "Este link já não é válido" (Recuperar palavra-passe); falha de envio: "Não foi possível enviar. Tente de novo." | Faixa; botão desativado | Regra dos 10 caracteres por cumprir: botão desativado com a regra visível | n/a |
| Abrir link | n/a | n/a | Skeleton do consentimento | Expirado ou inválido: ecrã explicativo com campo de email (Enviar link novo) | Faixa + "Precisa de ligação para abrir o link." | "Enviar link novo" bloqueado 60 s após envio | Já respondido: vai para Com quem partilho com aviso |
| Aceitar partilha | Título, resumo, texto, barra de ações (Aceitar / Recusar, mesmo peso) | n/a | Skeleton (separador, título 2 linhas, 3 linhas de resumo, 6 linhas de texto); barra de ações já visível mas desativada | Falha ao registar: `InlineNotice` erro por cima dos botões "Não foi possível registar a sua resposta. Nada foi alterado. Tente de novo." (botão carregado volta ao normal); texto de consentimento não carregou: "Não foi possível carregar o texto. Sem o ler não pode responder." (Tentar de novo) | Faixa; ambos os botões desativados com "Precisa de ligação para responder." | Durante envio: o outro botão desativado | Pedido já não pendente: aviso e Com quem partilho |
| Com quem partilho | Com pendentes: bloco `realce` no topo (Responder). Sem pendentes: grupos com linhas (Retirar acesso) | "Ainda não partilha dados com nenhum escritório." (sem botão; explica que os pedidos aparecem aqui) | `SkeletonRows` 3 linhas com a forma nome + carimbo + data; o bloco pendente só aparece com dados confirmados (nunca em skeleton com fundo `realce`) | "Não foi possível carregar a lista. Tente de novo." (Tentar de novo); falha ao retirar: aviso dentro da folha "Não foi possível retirar o acesso. O escritório continua com acesso. Tente de novo." e a linha fica igual | Faixa; "Retirar acesso" e "Responder" desativados com "Precisa de ligação." por baixo | "Retirar acesso" desativado enquanto a folha envia | Sessão terminada: "A sua sessão terminou. Entre de novo com o seu email: enviamos-lhe um link." (Entrar) |
| Clientes | Tabela com ativos, pendentes e recusados (estes sem ação); caso longo com reticências (Criar cliente) | "Ainda não tem clientes" (Criar cliente) | `SkeletonRows` 6 linhas com as colunas da tabela; título e botão visíveis | Lista: "Não foi possível carregar os clientes. Tente de novo." (Tentar de novo); erros de criar e de reenviar como na copy | Faixa; "Criar cliente" e "Reenviar pedido" desativados com razão | "Reenviar pedido" 60 s após envio; "Criar e enviar pedido" até os dois campos serem válidos; linhas recusadas sem ação (não é desativado: não existe botão) | Cliente que retirou desaparece da lista sem aviso; dados de outro escritório nunca aparecem |
| Painel do admin | 3 contagens + escritórios (Criar escritório) | Contagens a 0 + "Ainda não há escritórios." (Criar escritório) | Contagens como blocos `esqueleto` de 56 de altura (nunca "0" provisório) + `SkeletonRows` 3 | "Não foi possível carregar as contagens. Tente de novo." (Tentar de novo) | Faixa; criar e convidar desativados | Botões das folhas até o formulário ser válido | Perfil não admin: rota inexistente, volta ao ecrã do seu perfil |

## Motion

Tokens de `AppMotion` (DESIGN.md). Com "reduzir movimento" ativo, tudo passa a 0 ms. Nenhuma informação existe só como movimento: cada mudança deixa texto (carimbo, data, `InlineNotice`).

| Elemento | Gatilho | Duração / curva (token) |
| --- | --- | --- |
| Botão (fundo e contorno) | Hover, pressão, foco | `rapido` / `mudar` |
| Texto do botão para spinner e de volta | Envio começa / termina | `rapido` / `mudar` (cross-fade; a largura do botão não muda) |
| `OfflineBar` | Perde ou recupera ligação | entra `base` / `entrar` (desliza de cima e empurra o conteúdo); sai `base` / `sair` |
| `InlineNotice` | Aparece um erro ou confirmação | `base` / `entrar` (opacidade + altura) |
| `ConfirmSheet` em compacto | Carregar "Retirar acesso" | entra `lento` / `entrar` (sobe do fundo); sai `base` / `sair` |
| `ConfirmSheet` em médio/largo | Idem | entra `base` / `entrar` (opacidade + escala 0.98 a 1.0); sai `rapido` / `sair` |
| Folha lateral (criar cliente, escritório, convite) | Abrir / fechar | entra `lento` / `entrar` (desliza da direita, origem no botão do mesmo lado); sai `base` / `sair` |
| `StatusStamp` | Estado confirmado pelo servidor | `base` / `mudar` (cross-fade do carimbo antigo para o novo) |
| Linha retirada | Retirada confirmada | sai de "Com acesso" `base` / `sair` (opacidade + altura); entra em "Sem acesso" `lento` / `entrar`; fundo `realce` desvanece em `realce` |
| Pedido no bloco pendente | Respondido (vindo do ecrã 3) | sai do bloco `base` / `sair` (opacidade + altura); o bloco fecha com `lento` / `mudar` quando fica vazio; a linha entra no grupo de destino `lento` / `entrar` com `realce` a desvanecer |
| `FolderTabs` (entrar) | Trocar de separador | `rapido` / `mudar` (cor do separador); o formulário troca sem deslizar (cross-fade `base`) |
| Linha de cliente nova | Cliente criado | entra no topo `lento` / `entrar`; fundo `realce` desvanece em `realce` |
| Barra de ações do consentimento para bloco de resultado | Resposta confirmada | `base` / `mudar` (cross-fade); o foco move-se para o resultado e é anunciado (live region) |
| Skeleton | A carregar | `pulsar` (opacidade 1.0 a 0.55, ida e volta) |
| Contagens do admin | Dados chegam | Sem contagem animada: o número aparece com `base` / `entrar` em opacidade |
| Mudança de ecrã | Navegação | Transição de página por defeito da plataforma sem extras; nenhuma animação de entrada de ecrã |

## Acessibilidade (verificar na implementação)

- Ordem de foco: separador, título, conteúdo, ações. Em consentimento: título, resumo, texto, Recusar, Aceitar.
- Carimbos com semântica de texto ("Estado: ativo desde 12 de novembro de 2026").
- Escala de texto 1.3: barra de ações do consentimento cresce em altura, nunca corta; tabela de clientes passa para o layout empilhado se a coluna Cliente ficar abaixo de 240.
- Contraste: todos os pares de texto usados estão a 4.5:1 ou mais (tabela em DESIGN.md); `tintaTenue` nunca sobre `cartolina`.

## Renders

Ainda não existem renders: não há código nem tema. Na passagem de polimento (Modo 2) os goldens ficam em `test/design_review/001_fundacao/` (tag `design-review`): os 6 ecrãs, populado + vazio + erro + offline, a 390 e a 1280 de largura, escala de texto 1.0 e 1.3, com as fontes reais carregadas.
