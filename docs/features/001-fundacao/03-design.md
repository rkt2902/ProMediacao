# 03 Design: 001 Fundação (autenticação, perfis, escritórios e consentimento)

> **Gate 2 aprovado (2026-11-26):** direção "Dossiê arrumado" e fontes Source Serif 4 + Atkinson Hyperlegible Next/Mono. Emendas incorporadas: o cliente pede um link novo no ecrã de entrada e no ecrã de link expirado; os pedidos pendentes aparecem dentro da app em "Com quem partilho" para clientes com conta; o mediador tem "Reenviar pedido"; os recusados aparecem na lista do mediador sem ações; tratamento formal; bloqueio de 60 s nos reenvios.
>
> **Revisão responsiva (2026-11-26, decisão web-first em `docs/decisions.md`):** a app corre no navegador, sem instalação. Os ecrãs de cliente e de mediador deixam de ter um tamanho "primeiro": cada um tem composição explícita em compacto (telemóvel, < 640), médio (tablet, 640 a 1100) e largo (desktop, > 1100), com a mesma qualidade nos três. Só o admin é desktop-first. Ver "Responsividade" abaixo e a secção com o mesmo nome em DESIGN.md.
>
> **Revisão de autenticação (2026-11-26, decisão "Autenticação do cliente" em `docs/decisions.md`):** o cliente passa a ter palavra-passe opcional. Mudou: o ecrã Entrar unifica-se num só formulário (email + palavra-passe) com "Receber link de acesso por email" como alternativa; novo ecrã 1c "Criar palavra-passe" depois da entrada por link, com "Agora não"; nova secção "A sua conta" no fim de "Com quem partilho" com "Criar palavra-passe"; o link expirado ganha "Já tem palavra-passe? Entrar com ela"; os ecrãs antes da sessão (Entrar, Recuperar, Link expirado) usam o separador fixo "Acesso". Assumidas as duas recomendações pendentes dos renders: (1) a régua por baixo do separador corre a largura da moldura; (2) em largo, os formulários de entrada ficam à esquerda da moldura (o `AuthLayout` que desloca a coluna para 1/3 da janela tem de mudar).
>
> **Revisão de acabamento (2026-11-26, pedidos do Henrique):** (1) sem linha de cabeçalho nem marca nos ecrãs com sessão: o separador é a primeira linha e "Sair" fica na mesma linha, à direita; nos ecrãs sem sessão o separador diz "ProDossier" (substituído pela revisão de marca: volta a "Acesso"); (2) palavra-passe segura com regras em tempo real, sem confirmação (secção 1d); (3) renders de todos os estados (erro, offline, a carregar, vazio, sucesso); (4) transições entre ecrãs fixadas e storyboards dos fluxos (secções "Transições entre ecrãs" e "Fluxos").
>
> **Revisão de marca (2026-11-26, escolha do Henrique entre três propostas):** a marca entra pelo **colofão**, o fim de cada página (secção "Colofão" abaixo e em DESIGN.md). O separador dos ecrãs sem sessão volta a dizer "Acesso" (deixa de dizer "ProDossier"). As propostas "etiqueta da lombada" e "selo de registo" ficam em DESIGN.md, "Rejeitado".
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

- `PageFrame`: fundo `papel`; margens `s16` / `s32` / `s48` (compacto / médio / largo). **Sem linha de cabeçalho nem marca nos ecrãs com sessão** (decisão do Henrique, 2026-11-26): a primeira linha do ecrã é o `FolderTab`, a `s16` (compacto) ou `s24` (médio/largo) do topo da janela. Em largo, a moldura inteira (separador, conta, conteúdo) tem largura máxima `larguraLista` 1040 e fica **centrada na janela**; dentro dela tudo alinha à esquerda. Em compacto e médio ocupa a janela menos as margens.
- `FolderTab` colado ao topo da área de conteúdo (`separadorAltura` 40, `cartolina`, `AppRadius.separador` em cima), texto `rotulo` `tinta`: "Ribeira Seguros" (mediador), "Administração" (admin), "Os meus dados" (cliente com sessão), "Pedido de acesso" (consentimento) ou "Acesso" (ecrãs antes da sessão: Entrar, Recuperar e definir palavra-passe, Link expirado). Por baixo, uma régua `regua` com a largura da moldura (1040 em largo), mesmo quando a coluna é de 400 ou 640: é a borda da pasta, e a "pasta" é o ecrã (decisão assumida em 2026-11-26). Nome de escritório longo no separador: uma linha com reticências; o separador nunca passa de `larguraFormulario` 400 em médio/largo, nem da largura toda menos `s48` em compacto (o nome completo está no título ou na leitura de ecrã).
- **Linha do separador e conta (revisto a 2026-11-26, pedidos do Henrique):** o `FolderTab` à esquerda e, na mesma linha, encostado à margem direita da moldura, o bloco da conta: `TextAction` "Sair" (ícone `logout` + palavra) e, onde couber (médio/largo, perfis de escritório), o nome em `rotulo` `tintaMedia` a `s16` antes dele. O bloco tem a altura do separador (`separadorAltura` 40) e fica centrado verticalmente com ele; o alvo de "Sair" continua 48 (excede 4 em cima e em baixo, sem mexer na linha). Em compacto o separador tem no máximo a largura toda menos 2 × `alvoMinimo` (o espaço de "Sair"). A régua por baixo continua à largura da moldura. O título fica a `s32` da régua.
- **Marca:** só no colofão (secção seguinte). O separador dos ecrãs sem sessão (Entrar, Recuperar, Definir palavra-passe, Link expirado) diz "Acesso"; quem chega de um email confirma onde está pelo colofão, no fundo da janela.
- **Consentimento:** o `TextAction` "Com quem partilho" (48) é a primeira linha, a `s8` acima da linha do separador.
- Sem AppBar nem barra de navegação (inferior ou lateral) nesta feature, em nenhum tamanho: cada perfil tem só 1 ou 2 ecrãs, e as passagens entre eles são botões com texto dentro do conteúdo.

### Colofão (todos os ecrãs de página)

Regra geral em DESIGN.md, "Colofão". Aqui o que se aplica a cada ecrã desta feature.

- **Widget:** `Colophon`, desenhado pelo `PageFrame` como último filho do scroll. Recebe a linha de identidade e o registo (opcional); o wordmark é sempre o mesmo `Wordmark`.
- **Composição:** a `s72` do fim do conteúdo em médio/largo e `s48` em compacto; régua `regua` 1 à largura da moldura (1040 em largo; a largura toda menos as margens em compacto e médio), igual à régua do separador, mesmo em ecrãs de coluna 400 ou 640; a `s16`, `Wordmark` (`AppType.marca`), linha de identidade (`corpoPequeno` `tintaMedia`) e registo (`registo` `tintaTenue`) numa linha, com `s16` entre eles, alinhados pela base; `s32` por baixo (`s24` em compacto). Quando o conteúdo é mais curto do que a janela, o colofão encosta ao fundo dela (o espaço livre fica entre o conteúdo e a régua); quando é mais longo, aparece só no fim do scroll.
- **Por tamanho:** *compacto*: wordmark, linha e registo empilhados à esquerda com `s4`, a linha quebra livremente (o nome completo nunca leva reticências); *médio* e *largo*: uma linha; se não couber (escala 1.3, nome longo) passa ao empilhado do compacto, nunca corta.
- **Texto por perfil (fixtures):**
  - Sem sessão (Entrar, Recuperar, Definir palavra-passe, Link expirado): "O dossiê dos seus seguros, partilhado só com quem autorizar." Sem registo.
  - Cliente (Consentimento, Criar/alterar palavra-passe, Com quem partilho): "Dossiê de Maria do Carmo Figueiredo" + "Aberto a 12 nov 2026" (data de criação da conta, `profiles.created_at`).
  - Mediador (Clientes): "Ana Martins, Ribeira Seguros" + "Na equipa desde 3 nov 2026" (data de entrada no escritório, `office_members.created_at`). Em compacto é o único sítio onde o nome do mediador se vê (a linha do separador só tem "Sair").
  - Admin: "Administração da plataforma". Sem nome, sem registo.
- **Estados:**
  - *A carregar* (skeleton): cliente e mediador mostram só o wordmark até o perfil chegar; a linha e o registo entram com `base` / `entrar` (opacidade). Nunca há blocos `esqueleto` no colofão. Admin e sem sessão não esperam por nada.
  - *Erro, vazio, offline, desativado:* o colofão não muda. Em vazio e erro o conteúdo é curto, por isso o colofão fica no fundo da janela.
  - *Sessão terminada:* volta a Entrar, com o colofão sem sessão.
- **Folhas e diálogos:** o colofão nunca aparece dentro de `ConfirmSheet`, diálogos ou folhas laterais; fica no sítio, por trás do véu. Os formulários em ecrã inteiro do compacto (criar cliente, criar escritório, convidar mediador) **não** têm colofão: são passagens, não páginas.
- **Consentimento (barra fixa):** o colofão fica a seguir à "Versão do texto", antes do fim do scroll; a barra de ações continua fixa por cima dele enquanto se faz scroll e, no fim, o colofão fica inteiro visível acima da barra (o scroll tem a altura da barra a mais no fim, como hoje). Depois de responder, sai a barra e o colofão fica a seguir ao bloco de resultado e ao texto.
- **Tabelas e listas longas** (Clientes, Com quem partilho, admin): o colofão fica depois de "Mostrar mais 25" (ou da última linha, ou de "A sua conta"); carregar mais 25 empurra-o para baixo, sem animação própria. Nunca é fixo nem flutua sobre a tabela.
- **Teclado e leitura de ecrã:** o colofão não tem nada focável (fica fora da ordem de Tab). É uma região de rodapé (`Semantics` de contentinfo na web); o wordmark lê-se "ProDossier", numa palavra.
- **Motion:** nenhum, exceto a linha de identidade a entrar quando o perfil chega (`base` / `entrar`). Com "reduzir movimento", corte seco.

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
| Linha do separador | Separador à esquerda; à direita só `TextAction` "Sair" (ícone `logout` + palavra, alvo 48), centrado com o separador. A leitura de ecrã diz "Sair da conta de Ana Martins" | Separador; à direita o nome ("Ana Martins", `rotulo` `tintaMedia`, uma linha, reticências) + `s16` + "Sair" | Igual ao médio, alinhado com a moldura centrada de 1040 |
| Cliente | Só "Sair" nos três tamanhos (o cliente sabe quem é; o separador "Os meus dados" já o diz) | idem | idem |
| Entre ecrãs | Botões com texto no conteúdo ("Responder", "Ver com quem partilho") e o `TextAction` "Com quem partilho" com ícone `arrow_back` no consentimento (ver ecrã 3); "voltar" do navegador funciona sempre | idem | idem |
| Sair | Sem confirmação; volta a Entrar com o email preenchido | idem | idem |

## Ecrãs

### 1. Entrar (cliente, mediador e admin)

Um só formulário para todos: email e palavra-passe. Por baixo, separada por uma régua, a alternativa do cliente: "Receber link de acesso por email". O cliente nunca fica sem saída: sem palavra-passe, ou com o link expirado, pede um link aqui.

- **Separadores unificados (decisão do designer, 2026-11-26):** saem os dois separadores "Sou cliente" / "Trabalho num escritório". Com a palavra-passe para todos, o método principal é igual nos dois perfis e a escolha passou a ser uma pergunta sem consequência no caminho principal, mais uma decisão para clientes mais velhos antes de escrever o email.
  A única diferença (o link) fica como alternativa explícita, com "Só para clientes." escrito; fica um `FolderTab` fixo "Acesso" para manter a assinatura do separador (a marca está no colofão).
- **Descartadas:** (a) manter os dois separadores, com palavra-passe + link no do cliente: dois formulários quase iguais e a escolha "quem sou" antes de tudo; (b) link mágico como botão principal e palavra-passe escondida atrás de "Tenho palavra-passe": contraria a decisão (palavra-passe é o método principal depois da primeira entrada).
- **Hierarquia:** 1.º título "Entrar" e os dois campos; 2.º `PrimaryButton` "Entrar"; 3.º "Esqueci-me da palavra-passe"; 4.º a alternativa por link (pergunta em `corpoForte`, apoio, `SecondaryButton`).
- **Composição:** sem cartão nem hero. `FolderTab` "Acesso"; régua à largura da moldura. Coluna de `larguraFormulario` 400 alinhada à esquerda da moldura. Título "Entrar" a `s32` do separador; campos a `s24` do título, empilhados com `s16`; `PrimaryButton` "Entrar" a `s24`, largura da coluna, `alvoPrincipal` 56; `TextAction` "Esqueci-me da palavra-passe" a `s8` (alvo 48). Alternativa: régua `regua` à largura da coluna a `s24`, e a `s24` dela: `corpoForte` "Prefere entrar sem palavra-passe?", a `s4` `corpoPequeno` `tintaMedia` "Enviamos um link para o email acima. Só para clientes.", a `s16` `SecondaryButton` "Receber link de acesso por email", largura da coluna, 56 (é ação principal de cliente: mesmo alvo do "Entrar", peso visual menor por ser contorno).
- **Comportamento do link:** usa o email do campo de cima (não há segundo campo). Email vazio ou mal escrito: o erro aparece no campo Email e o foco vai para lá; a palavra-passe é ignorada. Com email válido, o formulário inteiro (campos, botões, alternativa) é substituído por uma `InlineNotice` (fundo `realce`) com a confirmação, o email em `corpoForte`, `TextAction` "Enviar outra vez" (bloqueado 60 s, com a razão escrita) e "Usar outro email"; por baixo da notice, a `s16`, `TextAction` "Entrar com palavra-passe" com ícone `arrow_back`, que repõe o formulário. A resposta é igual exista ou não a conta, e igual para um email de mediador ou admin (o servidor não envia link a esses perfis; ver riscos no handoff).
- **Por tamanho:**
  - *Compacto:* coluna à largura da janela menos `s16` de cada lado; separador como primeira linha do ecrã (ver "Linha do separador e conta"). Botões a toda a largura, 56. Sem foco automático no Email. Teclado virtual: Email com teclado de email e "seguinte"; Palavra-passe com "entrar", que submete "Entrar". A alternativa fica abaixo da dobra com o teclado aberto, e está bem: quem a procura fecha o teclado e vê-a a seguir ao "Esqueci-me".
  - *Médio:* coluna de 400 à esquerda; o resto da largura fica em `papel` vazio. Foco automático no Email.
  - *Largo:* igual ao médio dentro da moldura centrada de 1040, coluna encostada à esquerda da moldura (não a 1/3 da janela). A 1280 × 800 o botão do link acaba a cerca de 680: cabe sem scroll, também em portáteis com cerca de 700 de altura útil; o colofão fica no fundo da janela (a 800 de altura vê-se inteiro; com menos altura fica logo abaixo da dobra, e está bem). Teclado: Tab Email, Palavra-passe, "Mostrar", "Entrar", "Esqueci-me…", "Receber link…"; Enter em qualquer campo submete "Entrar" (nunca o link).
  - *Todos:* sem conta na linha do separador (ainda não entrou). Preenchimento automático: `username` no Email e `current-password` na palavra-passe, para os gestores de palavras-passe do navegador.
- **Componentes e tokens:** `FolderTab`, `LabeledField` (rótulo `rotulo`, campo `campo` 52, contorno `reguaForte` `controlo` 1.5, `AppRadius.controlo`, foco `foco` 2); `PrimaryButton`; `SecondaryButton`; `TextAction`; `InlineNotice`. `FolderTabs` deixa de ser usado nesta feature.
- **Copy:**
  - Separador: "Acesso"; título: "Entrar"; colofão sem sessão
  - Campos: "Email", "Palavra-passe"; ação no campo: "Mostrar" / "Ocultar"
  - Botão: "Entrar"; a carregar: "A entrar…"
  - Ligação: "Esqueci-me da palavra-passe"
  - Alternativa: "Prefere entrar sem palavra-passe?" / "Enviamos um link para o email acima. Só para clientes." / botão "Receber link de acesso por email"; a carregar: "A enviar…"
  - Confirmação do link: "Se este email tiver acesso ao ProDossier, o link chega a {email} dentro de alguns minutos. Abra-o neste dispositivo. Veja também a pasta de spam."; ações "Enviar outra vez" (bloqueado: "Pode enviar outra vez daqui a 1 minuto.") e "Usar outro email"; ligação "Entrar com palavra-passe"
  - Erro de credenciais (igual para todos os perfis, exista ou não a conta): "Email ou palavra-passe incorretos." Cliente sem palavra-passe que tenta uma recebe esta mesma mensagem; por isso, abaixo dela, em `corpoPequeno` `tintaMedia`: "Se ainda não criou palavra-passe, use Receber link de acesso por email."
  - Campo vazio: "Escreva o seu email." / "Escreva a palavra-passe."; email mal escrito: "Escreva um email completo, por exemplo nome@exemplo.pt."
  - Sessão terminada: "A sua sessão terminou. Entre de novo para continuar." (por cima do formulário)

### 1b. Recuperar e definir palavra-passe

- **Hierarquia:** 1.º título; 2.º um campo; 3.º confirmação.
- **Composição:** igual a "Entrar", nos três tamanhos (coluna 400, mesmo separador como primeira linha, mesmo foco automático), com `FolderTab` "Acesso" (serve todos os perfis: o cliente também recupera ou cria a palavra-passe por aqui) e `TextAction` "Voltar a entrar" com ícone `arrow_back` por baixo do botão. Em "Definir palavra-passe", as regras (secção 1d) ficam por baixo do campo e acima do botão em todos os tamanhos (em compacto, visíveis acima do teclado virtual junto com o campo). Depois de enviar, o formulário é substituído por uma `InlineNotice` (fundo `realce`) com a confirmação e "Voltar a entrar".
- **Cliente sem palavra-passe:** "Esqueci-me da palavra-passe" serve-lhe para a criar (a copy não muda: "definir uma nova palavra-passe" lê-se bem nos dois casos).
- **Copy (recuperar):** título "Recuperar palavra-passe"; texto "Indique o email da sua conta. Se existir, enviamos um link para definir uma nova palavra-passe."; botão "Enviar link" / "A enviar…"; confirmação (igual exista ou não a conta): "Se houver uma conta com este email, o link chega dentro de alguns minutos. Veja também a pasta de spam."; ligação "Voltar a entrar".
- **Copy (definir, vindo da recuperação, de qualquer perfil, ou do convite de mediador):** título "Definir palavra-passe"; para convite, linha de apoio "Foi convidado para a Ribeira Seguros." (nome do escritório em `corpoForte`); campo "Nova palavra-passe"; regras em tempo real (secção 1d); botão "Guardar e entrar"; botão "Guardar e entrar"; link expirado: título "Este link já não é válido", texto "Por segurança, os links expiram. Peça um novo em Recuperar palavra-passe ou ao administrador, se foi convidado."

### 1c. Criar palavra-passe [cliente, depois de entrar por link; compacto, médio e largo]

Convite, não obrigação: o cliente entrou por link, não tem palavra-passe, e a app propõe-lhe uma para a próxima vez.

- **Quando aparece:** depois de uma entrada por link de um cliente sem palavra-passe, antes de "Com quem partilho". Nunca antes nem durante o consentimento: se o link abre um pedido (ecrã 3), o convite aparece só depois de responder, ao carregar "Ver com quem partilho". "Agora não" segue para "Com quem partilho"; o convite volta no máximo na entrada seguinte por link (spec, US 4). Nunca aparece a quem já tem palavra-passe nem a quem entrou com ela.
- **Hierarquia:** 1.º título e a frase que diz o que ganha; 2.º o campo e a regra; 3.º "Guardar palavra-passe"; 4.º "Agora não" e onde a encontra depois.
- **Composição:** composição dos ecrãs de entrada (coluna `larguraFormulario` 400 à esquerda da moldura, separador como primeira linha), mas com sessão: `FolderTab` "Os meus dados" e "Sair" na linha do separadoro. Título "Criar palavra-passe" a `s32`; apoio em `corpo` `tintaMedia` a `s8`; a `s24`, "Email" em `rotulo` e o email em `corpo` (só leitura, não é campo; existe para o cliente saber com que email vai entrar e para o gestor de palavras-passe o associar); a `s24`, `LabeledField` "Nova palavra-passe" com "Mostrar"; a `s16`, as regras da palavra-passe em tempo real (secção 1d). `PrimaryButton` "Guardar palavra-passe" a `s24`; `SecondaryButton` "Agora não" a `s12`; ambos à largura da coluna, 56, empilhados nos três tamanhos (lado a lado dariam 194 cada, e "Guardar palavra-passe" não cabe a 1.3). A `s16`, `corpoPequeno` `tintaMedia` com o sítio onde fica.
- **"Agora não" é contorno, não ligação:** não é uma decisão sobre dados (onde as duas opções têm o mesmo peso), mas tem de ser tão fácil de encontrar como o "sim" para quem não quer: mesmo tamanho, mesma largura, menos tinta.
- **Por tamanho:**
  - *Compacto:* coluna à largura da janela menos `s16`; sem foco automático. Com o teclado aberto, o campo, a regra e "Guardar palavra-passe" ficam visíveis acima dele; "Agora não" pode ficar por baixo.
  - *Médio:* coluna de 400 à esquerda, foco automático no campo.
  - *Largo:* idem na moldura centrada. Tab: "Sair", campo, "Mostrar", "Guardar palavra-passe", "Agora não". Enter no campo guarda (se a regra estiver cumprida).
  - *Todos:* preenchimento automático `new-password` no campo e `username` (oculto, com o email) para o gestor de palavras-passe guardar o par certo.
- **Estados:** regras em tempo real enquanto escreve (secção 1d); "Guardar palavra-passe" está sempre ativo (nunca desativado por regras: o cliente percebe melhor um erro que diz o que falta do que um botão morto); se carregar com regras por cumprir, aparece o erro de palavra-passe fraca (1d). A guardar: "A guardar…" no botão, "Agora não" desativado; erro de rede: `InlineNotice` erro por cima dos botões "Não foi possível guardar a palavra-passe. Nada foi alterado. Tente de novo."; offline: faixa e "Guardar" desativado com "Precisa de ligação para guardar." ("Agora não" continua ativo: não precisa de servidor). Sucesso: vai para "Com quem partilho" com `InlineNotice` "Palavra-passe criada. Da próxima vez pode entrar com o seu email e esta palavra-passe."
- **A partir da conta** (secção "A sua conta" do ecrã 4): o mesmo ecrã, sem "Agora não" e sem a frase final; no lugar, `SecondaryButton` "Cancelar", que volta a "Com quem partilho". Se o cliente já tiver palavra-passe, o título passa a "Alterar palavra-passe" e o apoio a "A palavra-passe antiga deixa de funcionar. O link de acesso continua a funcionar."
- **Componentes e tokens:** `PageFrame`, `FolderTab`, `LabeledField`, `PrimaryButton`, `SecondaryButton`, `InlineNotice`; `AppSize.larguraFormulario`, `iconePequeno`, `alvoPrincipal`; `AppType.titulo`, `corpo`, `corpoPequeno`, `rotulo`.
- **Copy:**
  - Título: "Criar palavra-passe" (da conta, com palavra-passe: "Alterar palavra-passe")
  - Apoio: "Da próxima vez pode entrar com o seu email e esta palavra-passe, sem esperar pelo email. O link de acesso continua a funcionar."
  - "Email" / {email}; campo "Nova palavra-passe"; "Mostrar" / "Ocultar"; regras em 1d
  - Botões: "Guardar palavra-passe" / "A guardar…"; "Agora não" (da conta: "Cancelar")
  - Rodapé: "Pode criar mais tarde, em Com quem partilho, na secção A sua conta."
  - Sucesso: "Palavra-passe criada. Da próxima vez pode entrar com o seu email e esta palavra-passe." (alterar: "Palavra-passe alterada.")

### 1d. Regras da palavra-passe [todos os ecrãs que definem uma: criar, alterar, definir (recuperação e convite de mediador)]

Decisão do Henrique (2026-11-26): mínimo de 10 caracteres com maiúscula, minúscula, número e carácter especial; **sem campo de confirmação** ("Mostrar" cobre o erro de escrita). Regra igual para todos os perfis.

- **Onde:** por baixo do campo "Nova palavra-passe", a `s16`: `rotulo` `tintaMedia` "A palavra-passe precisa de ter:" e, a `s8`, uma lista de 5 linhas com `s4` entre elas. Cada linha: ícone `iconePequeno` + texto `corpoPequeno`. Fica sempre visível (não aparece só ao errar), e em compacto fica junto ao campo, acima do teclado virtual.
- **Três estados por regra, cada um com forma própria (nunca só cor):**
  - por cumprir: `circle_outlined`, texto `tintaMedia`;
  - cumprida: `check_circle` (cheio), texto `tinta`;
  - em erro (só depois de carregar em guardar com a regra por cumprir): `error_outline`, texto `erro` em peso 600.
  A troca é em tempo real a cada tecla (ícone em `rapido` / `mudar`). Uma regra em erro volta a "cumprida" assim que fica cumprida, sem esperar por novo envio.
- **Erro de palavra-passe fraca:** o campo fica com contorno `erro` e, por baixo dele (antes da lista), a mensagem do `LabeledField` com ícone: "A palavra-passe ainda não é segura. Falta cumprir {n} regras." (1 regra: "Falta cumprir 1 regra."). O foco volta ao campo; a leitura de ecrã lê a mensagem e as regras em falta ("Falta: pelo menos 10 caracteres, um carácter especial.").
- **Leitura de ecrã:** cada linha anuncia o estado antes do texto ("Cumprida: uma letra maiúscula." / "Por cumprir: …"); as mudanças em tempo real não são anunciadas a cada tecla (seria ruído), só o total ao sair do campo ("3 de 5 regras cumpridas").
- **Copy das regras:** "Pelo menos 10 caracteres" / "Uma letra maiúscula" / "Uma letra minúscula" / "Um número" / "Um carácter especial, como ! ? # @"
- **Botão:** nunca desativado por regras; o erro aparece ao carregar. Desativado só offline (com a razão escrita) e durante o envio.
- **Renders:** `criar-palavra-passe-*` (parcial, em tempo real), `criar-palavra-passe-cumprida-*`, `criar-palavra-passe-fraca-*`, `definir-palavra-passe-*`, `alterar-palavra-passe-*`.

### 2. Abrir o link (cliente)

Estados de passagem antes do consentimento ou de "Com quem partilho".

- **A validar:** skeleton do ecrã de consentimento (separador, bloco do título, 3 linhas). Sem spinner de página.
- **Link expirado ou inválido:** `FolderTab` "Acesso" (ainda não há sessão; antes era "Os meus dados"); título "Este link já não é válido"; texto "Os links de acesso expiram ao fim de algum tempo, por segurança. Peça um novo aqui: basta o seu email."; campo "Email" e `PrimaryButton` "Enviar link novo" (mesmo comportamento e confirmação da alternativa por link do ecrã 1); a `s16` do botão, `TextAction` "Já tem palavra-passe? Entrar com ela", que abre Entrar com o email já preenchido (some quando a confirmação de envio substitui o formulário); por baixo, a `s24`, `corpoPequeno` `tintaMedia`: "Também pode pedir ao seu mediador que reenvie o pedido." Depois de entrar com o link novo, os pedidos pendentes aparecem em "Com quem partilho" (ecrã 4), por isso o cliente não perde o pedido original.
  - *Por tamanho:* composição de "Entrar" nos três tamanhos: coluna `larguraFormulario` 400 (à largura da janela menos `s16` em compacto), separador como primeira linha, botão 56 a toda a largura da coluna, sem conta na linha do topo. Em compacto sem foco automático no campo (o cliente lê primeiro porque é que o link falhou); em médio/largo o foco vai para o título (não para o campo), pela mesma razão, e Tab segue para o Email, "Enviar link novo" e "Já tem palavra-passe? Entrar com ela". A confirmação de envio substitui o campo como no ecrã 1, com as mesmas ações empilhadas/lado a lado.
- **A validar (por tamanho):** o skeleton tem a forma do consentimento do tamanho em que vai aparecer (título 26 ou 30, coluna 640 ou largura toda) e a barra de ações já aparece no sítio final, para nada saltar quando os dados chegam.
- **Pedido já respondido:** vai direto para "Com quem partilho", com `InlineNotice` "Já respondeu a este pedido a 26 nov 2026, 14:32."

### 3. Aceitar partilha (consentimento) [cliente; compacto, médio e largo]

- **Hierarquia:**
  1. Quem pede: o nome do escritório em `titulo` (26 em compacto, 30 em médio/largo) seguido de "pede acesso aos seus dados", e por baixo quem enviou ("Enviado por Ana Martins, mediadora", `corpoPequeno`).
  2. O que significa: resumo em 3 linhas com réguas (ícone + frase), antes do texto completo.
  3. A decisão: "Recusar" e "Aceitar", com o mesmo tamanho, numa barra fixa em baixo.
- **Composição:** coluna `larguraLeitura` 640, alinhada à esquerda em largo. Ordem: `FolderTab` "Pedido de acesso"; título a `s32`; remetente a `s8`; resumo a `s32` (3 `RuledRow`, ícone 24 `tinta` + `corpo`); título de secção "Texto completo" (`rotulo`) a `s48`; texto completo em `corpo`, parágrafos numerados com `s16` entre eles; no fim, `registo` "Versão do texto: v0-rascunho", e a seguir o colofão do cliente. O ecrã inteiro faz scroll; a barra de ações (`folha`, régua no topo, padding `s16`) fica sempre visível. Botões lado a lado em todos os tamanhos (50/50 com `s12` de intervalo), `alvoPrincipal` 56; "Recusar" à esquerda como `SecondaryButton`, "Aceitar" à direita como `PrimaryButton`. Por cima dos botões, `corpoPequeno` `tintaMedia`: "A sua resposta fica registada com data e hora." (revisto nos renders: é uma frase, não uma data; em `registo` partia em 2 linhas a 390) Não se obriga a fazer scroll até ao fim para ativar "Aceitar" (prejudica a acessibilidade; o resumo garante a leitura do essencial).
- **Saída sem responder:** quando o cliente tem sessão, `TextAction` "Com quem partilho" com ícone `arrow_back`, alvo 48, como primeira linha do ecrã, a `s8` acima da linha do separador, nos três tamanhos. Sair sem responder não regista nada; o pedido continua no bloco pendente do ecrã 4. Sem sessão (link do email ainda por validar) não aparece.
- **Por tamanho:**
  - *Compacto:* coluna à largura da janela menos `s16`; título 26/32. Resumo com ícone `icone` 24 à esquerda e texto a `s12`, a quebrar livremente. Barra de ações fixa: fundo `folha` à largura da janela, padding `s16` e o espaço seguro de baixo, linha "A sua resposta fica registada…" por cima, botões 50/50 com `s12` de intervalo, 56 de altura; a 320 de largura cada botão tem 138, chega para "Recusar" e "Aceitar" a escala 1.3. Com altura < `alturaBaixa` 480 (telemóvel deitado), a linha de apoio passa para o fim do texto (antes de "Versão do texto") e o padding da barra passa a `s8`. O texto completo é selecionável com toque longo.
  - *Médio:* coluna `larguraLeitura` 640 à esquerda da moldura (em 640 a 704 de janela, a coluna é a largura toda menos `s32`); título 30/36. Barra fixa: fundo à largura da janela, conteúdo alinhado com a coluna de texto (mesma margem esquerda, largura máxima 640), botões 50/50 dentro dela. Toque: tudo como em compacto.
  - *Largo:* igual ao médio dentro da moldura centrada; a coluna de 640 fica à esquerda da moldura e os 400 restantes ficam vazios (linhas de texto mais largas que 640 cansam a leitura; nada de coluna lateral de "ajuda"). Barra fixa com o conteúdo alinhado com a coluna. Teclado: foco inicial no título (leitura de ecrã anuncia escritório e pedido); Tab percorre "Com quem partilho", ligações dentro do texto (se houver), "Recusar", "Aceitar". **Nenhum botão é o "por defeito"**: Enter só ativa o botão que tem foco; Esc não faz nada (não há nada para fechar). Rato: o texto completo seleciona-se com arrastar; hover nos dois botões é igual em intensidade.
  - *Todos:* "Recusar" à esquerda e "Aceitar" à direita, sempre lado a lado e com a mesma largura, nunca empilhados (empilhar põe um deles por cima e dá-lhe peso). O bloco de resultado ocupa a largura da coluna; "Ver com quem partilho" a toda a largura em compacto e com a largura do texto (mínimo 56 de altura) em médio/largo.
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

É sempre o ecrã onde o cliente aterra ao entrar (com palavra-passe, por link genérico, ou depois do ecrã 1c). Um link de um pedido concreto continua a abrir direto o ecrã 3. Os pedidos pendentes aparecem aqui também quando o cliente já tem conta e o escritório lhe enviou um pedido sem link: não é preciso email para responder.

- **Hierarquia:**
  1. Se houver pedidos pendentes: o bloco "À espera da sua resposta", no topo e acima de tudo o resto.
  2. A frase-resumo ("Partilha os seus dados com 2 escritórios.") e os escritórios com acesso, com nome, carimbo e data.
  3. A ação de cada linha ("Retirar acesso") e a explicação do que retirar faz.
- **Composição:** `FolderTab` "Os meus dados"; título "Com quem partilho" (`titulo`).
  - **Bloco de pedidos pendentes** (só se existir algum), a `s24` do título: superfície `realce` com `AppRadius.superficie`, padding `s24` (`s16` em compacto), sem sombra. Cabeçalho `subtitulo` "À espera da sua resposta" + `corpo` "Estes escritórios pedem acesso aos seus dados. Nada é partilhado até responder." Cada pedido é uma `RuledRow` (réguas `regua` dentro do bloco): nome do escritório em `corpoForte`, "Enviado por Ana Martins, mediadora" em `corpoPequeno` `tintaMedia`, `StatusStamp` pendente + `registo` "Pedido a 25 nov 2026, 15:04", e `PrimaryButton` "Responder" (`alvoPrincipal` 56; a toda a largura em compacto, à direita nos outros), que abre o ecrã 3. É o único bloco com fundo de cor no ecrã, para ser a primeira coisa vista. O leitor de ecrã anuncia-o ao entrar ("Tem 1 pedido de acesso à espera da sua resposta.").
  - **Frase-resumo** em `corpoForte` a `s48` do bloco (ou a `s8` do título se não houver bloco).
  - Dois grupos por baixo, cada um com cabeçalho `rotulo` e lista com réguas, a `s32` da frase-resumo e `s32` entre eles (revisto: com `s48` o vazio entre grupos da mesma lista pesava mais do que o conteúdo), mostrados só se tiverem linhas: 1) "Com acesso" (ativos); 2) "Sem acesso" (recusados e retirados).
  - Cada linha (`RuledRow`, padding vertical `s16`): nome do escritório em `subtitulo` (até 2 linhas, depois reticências; nome completo na leitura de ecrã); por baixo, `StatusStamp` + `registo` com a data; à direita em médio/largo, ou por baixo a toda a largura em compacto, a ação com `alvoMinimo` 48. Ativos: `SecondaryButton` com texto `erro` "Retirar acesso" e `TextAction` "Ler o texto aceite" (abre o texto da versão aceite numa `ConfirmSheet` só de leitura). Sem acesso: sem ação. Rodapé `corpoPequeno` `tintaMedia` a `s48`. Coluna máxima `larguraLeitura`.
- **Secção "A sua conta"** (no fim do ecrã, a `s48` do rodapé, como qualquer grupo: é a coisa menos importante do ecrã e fica onde não compete com a partilha): `subtitulo` "A sua conta"; a `s16`, `RuledList` com duas linhas. Linha 1: `rotulo` `tintaMedia` "Email" e o email em `corpo` (quebra em qualquer caractere), sem ação. Linha 2: `rotulo` `tintaMedia` "Palavra-passe" e o estado em `corpo` ("Ainda não criou. Entra com um link enviado para o seu email." ou "Criada a 26 nov 2026." com a data em `registo`); ação `SecondaryButton` "Criar palavra-passe" / "Alterar palavra-passe" (48), à direita em médio/largo e a toda a largura por baixo em compacto, com a mesma regra de passagem das outras linhas (`textoMinimo` 240). Abre o ecrã 1c. O nome da ação é "Criar palavra-passe" (e não "Definir"): é o título do ecrã que abre, e "Definir palavra-passe" já é o ecrã da recuperação.
- **Por tamanho:**
  - *Compacto:* coluna à largura da janela menos `s16`. Bloco pendente com padding `s16`; cada pedido empilha nome (`corpoForte`, até 2 linhas), remetente, carimbo + data (a data passa para a linha de baixo se não couber ao lado do carimbo) e "Responder" a toda a largura, 56, a `s16`. Linhas com acesso: nome (`subtitulo`, até 2 linhas), carimbo + data, e por baixo, a `s16`, `SecondaryButton` "Retirar acesso" a toda a largura (48) e `TextAction` "Ler o texto aceite" alinhado à esquerda a `s8` (alvo 48). Sem gestos: nada de deslizar a linha para retirar.
  - *Médio:* coluna `larguraLeitura` 640 à esquerda. Linha em duas zonas: texto à esquerda (flexível) e ações à direita, alinhadas ao topo da linha e empilhadas à direita: "Retirar acesso" (largura do texto, 48) e por baixo, a `s8`, "Ler o texto aceite". No bloco pendente, "Responder" (56) à direita, alinhado ao topo. Se a zona de texto ficar abaixo de `AppSize.textoMinimo` 240 (escala 1.3, ou janela perto de 640), a linha passa para o layout compacto.
  - *Largo:* igual ao médio dentro da moldura centrada; a coluna mantém 640 (é uma lista curta para ler, não uma tabela). Teclado: Tab segue "Responder" de cada pedido, depois "Retirar acesso" e "Ler o texto aceite" de cada linha, por ordem, e por fim "Criar palavra-passe"; foco inicial no título, ou no bloco pendente se existir (anunciado). Hover: só nos botões; as linhas não são clicáveis e não reagem ao rato. Nome longo: até 2 linhas e reticências; o nome completo no tooltip (hover, foco, toque longo) e na leitura de ecrã.
  - *Todos:* depois de retirar ou de voltar do ecrã 3, o foco passa para a `InlineNotice` do topo e o ecrã faz scroll até ela. o pedido sai do bloco; se aceitou, entra em "Com acesso" com fundo `realce` a desvanecer; se recusou, entra em "Sem acesso". Quando o último pedido sai, o bloco fecha.
- **Confirmação de retirada (`ConfirmSheet`: folha inferior em compacto, diálogo de `dialogo` 480 em médio/largo; regras completas em "Responsividade"):** título `subtitulo`; texto `corpo`; `DestructiveButton` "Retirar acesso" e `SecondaryButton` "Cancelar", ambos 56: empilhados a toda a largura em compacto (destrutivo em cima), lado a lado nos outros ("Cancelar" à esquerda). Foco inicial em "Cancelar"; Esc, véu e "voltar" do navegador cancelam; ao fechar, o foco volta ao "Retirar acesso" da linha. "Ler o texto aceite" usa a variante só de leitura (folha alta em compacto, diálogo de 640 em médio/largo). Sem "anular" depois: voltar a dar acesso exige um novo pedido e um novo consentimento.
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
  - Conta: "A sua conta"; "Email"; "Palavra-passe"; "Ainda não criou. Entra com um link enviado para o seu email." / "Criada a {data}."; "Criar palavra-passe" / "Alterar palavra-passe"

### 5. Clientes [mediador; compacto, médio e largo]

- **Hierarquia:** 1.º título "Clientes" e o botão "Criar cliente"; 2.º a lista com nome e estado; 3.º email, data e "Reenviar pedido".
- **Composição:** `FolderTab` "Ribeira Seguros". Linha de título: "Clientes" (`titulo`) à esquerda, `PrimaryButton` "Criar cliente" à direita na mesma linha de base; por baixo, `registo` "12 clientes · 3 pendentes · 1 recusado". Lista a `s32`, coluna máxima `larguraLista` 1040. O layout da lista escolhe-se pela largura que sobra à coluna Cliente, não só pelo breakpoint:
  - **Largo (tabela de 4 colunas):** tabela com réguas, cabeçalhos `rotulo` `tintaMedia`. Colunas: **Cliente** (nome em `corpoForte` + email em `corpoPequeno` `tintaMedia`, uma linha cada, reticências; flexível), **Estado** (carimbo, `colunaEstado` 140), **Data** (`registo`, `colunaData` 248), **Ação** (`TextAction`, `colunaAcao` 160, alinhada à direita). Linhas com `linhaTabela` 72 de altura mínima.
  - **Médio (tabela de 3 colunas):** num tablet de 768 a tabela de 4 colunas deixaria Cliente abaixo de 240. Estado e Data juntam-se numa coluna **Estado** de `colunaData` 248: carimbo em cima, `registo` da data por baixo a `s4`. Cliente flexível, Ação 160. Linha com 72 de altura mínima (cresce com a data). Cabeçalhos "Cliente", "Estado", "Ação" (este só para leitura de ecrã).
  - **Compacto (lista empilhada):** sem cabeçalhos. Cada linha (padding vertical `s16`) empilha nome (`corpoForte`, até 2 linhas), email (`corpoPequeno`, até 2 linhas, quebra em qualquer caractere: no toque não há hover para ver o resto), carimbo + data na mesma linha (a data desce se não couber) e "Reenviar pedido" alinhado à esquerda, alvo 48 a toda a largura. "Criar cliente" passa para baixo da contagem, a toda a largura, 56.
  - **Regra de passagem:** se a coluna Cliente ficar abaixo de `textoMinimo` 240 (escala 1.3, janela estreita, zoom do navegador), desce um nível: 4 colunas para 3, 3 para empilhada.
  - Ordem: alterações mais recentes primeiro. Paginação de 25 com `SecondaryButton` "Mostrar mais 25" no fim (sem números de página).
  - Linhas ativas não têm ação nem são clicáveis nesta feature (a ficha do cliente vem depois): sem seta nem hover de ligação.
  - **Linhas recusadas:** carimbo "Recusado" (`estadoInativo`), data "Recusado a 20 nov 2026, 09:12", célula de ação vazia, sem hover nem clique. O nome mantém-se em `corpoForte` `tinta` (o mediador precisa de o reconhecer) e o email em `tintaMedia`; a leitura de ecrã diz "Recusado. Sem ações disponíveis." O mediador não pode reenviar nem insistir a partir daqui.
  - Clientes que retiraram o acesso não aparecem (regra da spec).
- **Rato, toque e teclado (todos os tamanhos):**
  - Linhas não clicáveis: sem hover de linha, sem cursor de clique; só "Reenviar pedido" reage (sublinhado mais grosso em `rapido`). Nome e email selecionáveis para copiar.
  - Nome ou email cortado por reticências (médio/largo): tooltip com o texto completo no hover, no foco e no toque longo (tablet).
  - Teclado: Tab "Criar cliente", depois cada "Reenviar pedido" por ordem da lista, depois "Mostrar mais 25". Foco inicial no título em médio/largo. Linhas sem ação não recebem foco de Tab (a leitura de ecrã lê-as em modo de navegação).
  - Toque (médio e compacto): o alvo de "Reenviar pedido" tem 48 de altura e toda a largura da coluna Ação (ou da linha, em compacto), não só a largura do texto.
- **Criar cliente:** `folhaLateral` 440 à direita em largo e médio (num tablet de 768 ficam 328 da lista visíveis por trás do véu, o que mantém o contexto), ecrã inteiro em compacto com os botões no fluxo a seguir aos campos ("Criar e enviar pedido" a toda a largura 56, "Cancelar" por baixo a `s12`, a toda a largura). Em largo/médio, barra de botões fixa no fundo da folha ("Cancelar" à esquerda, "Criar e enviar pedido" à direita), que sobe com o teclado virtual no tablet. Foco inicial em "Nome completo" (exceto compacto); Enter em "Email" submete; Esc, véu e "voltar" do navegador cancelam sem confirmação (são dois campos); ao fechar, o foco volta a "Criar cliente" ou, depois de criar, para a `InlineNotice` de sucesso. Título `subtitulo` "Criar cliente"; texto de apoio; campos "Nome completo" e "Email"; `InlineNotice` informativa; `PrimaryButton` "Criar e enviar pedido" e `SecondaryButton` "Cancelar". Ao confirmar, a folha fecha, a linha nova entra no topo com fundo `realce` e aparece uma `InlineNotice` por cima da tabela. A copy é a mesma quer o cliente receba um email com link (ainda não tem conta) quer veja o pedido dentro da app (já tem conta, eventualmente noutro escritório): o mediador nunca fica a saber se o email já existia.
- **Reenviar pedido** (só em linhas pendentes): `TextAction` na coluna Ação. Passa a "A enviar…" (spinner dentro), depois fica desativado durante 60 s (texto `tintaTenue`), com a razão **escrita** por baixo em `corpoPequeno` `tintaMedia`, como em qualquer `TextAction` desativado ("Pode reenviar às 15:05"); a coluna Data passa a mostrar a hora do novo envio, por isso não se repete "Enviado às" na célula (revisto nos renders: cabia em 3 linhas nos 160), nos três tamanhos: em tablet e telemóvel não há hover, por isso a razão não pode viver só num tooltip. Leitura de ecrã: "Pode reenviar daqui a 1 minuto.". Hora absoluta e não contagem decrescente (nada a mexer no ecrã). Para um cliente sem conta envia um link novo; para um cliente com conta volta a pôr o pedido no topo do bloco pendente dele. O rótulo é o mesmo nos dois casos.
- **Componentes e tokens:** `FolderTab`, `PageFrame`, `RuledList`, `StatusStamp`, `PrimaryButton`, `SecondaryButton`, `TextAction`, `LabeledField`, `InlineNotice`, `SkeletonRows`; `AppSize.larguraLista`, `folhaLateral`; `AppColors.realce`.
- **Copy:**
  - Título: "Clientes"; contagem: "{n} clientes · {p} pendentes · {r} recusados" (singular: "1 cliente", "1 pendente", "1 recusado"; partes a zero omitem-se)
  - Cabeçalhos: "Cliente", "Estado", "Data", "Ação" (o último só para leitura de ecrã; visualmente vazio)
  - Datas: "Desde 12 nov 2026" (ativo) / "Enviado a 25 nov 2026, 15:04" (pendente) / "Recusado a 20 nov 2026, 09:12" (recusado)
  - Carimbos: "ATIVO", "PENDENTE", "RECUSADO"
  - Ação: "Reenviar pedido" / "A enviar…" / "Reenviar pedido" desativado + "Pode reenviar às 15:05"
  - Folha: título "Criar cliente"; apoio "O cliente recebe o pedido com o nome da Ribeira Seguros e o seu: por email ou, se já usar o ProDossier, dentro da app. Só vê os dados dele depois de ele aceitar."; campos "Nome completo", "Email"; nota "Até o cliente aceitar, vê apenas o nome, o email e o estado do pedido."; botões "Criar e enviar pedido" / "A criar…" / "Cancelar"
  - Sucesso: "Pedido enviado a maria.figueiredo@exemplo.pt. O acesso fica pendente até o cliente aceitar."
  - Reenvio confirmado: `InlineNotice` no topo "Pedido reenviado a {email}." e a linha com fundo `realce` a desvanecer; a célula de ação mostra o bloqueio ("Pode reenviar às 15:05").
  - Erros: "Escreva o nome do cliente." / "Escreva um email completo, por exemplo nome@exemplo.pt." / "Este email já é cliente da Ribeira Seguros." / "O cliente foi criado, mas o pedido não seguiu. Tente Reenviar pedido daqui a pouco."
  - Nota: um email que já é cliente de outro escritório tem a mesma resposta de sucesso (não se revela nada).
  - Vazio: título de estado "Ainda não tem clientes" + "Crie o primeiro cliente. Ele recebe um pedido para aceitar a partilha dos dados com a Ribeira Seguros." + `PrimaryButton` "Criar cliente"

### 6. Painel do admin [desktop-first; utilizável em médio e compacto]

- **Hierarquia:** 1.º as 3 contagens; 2.º a lista de escritórios e "Criar escritório"; 3.º a nota de privacidade.
- **Composição:** `FolderTab` "Administração"; título "Plataforma". Contagens numa única faixa, **não** em 3 cartões: três colunas iguais separadas por réguas verticais `regua`, cada uma com o número em `numero` (56, serifa, tabular) e o rótulo por baixo em `rotulo` `tintaMedia`; a faixa tem réguas em cima e em baixo e padding vertical `s24`. Em compacto as três ficam empilhadas com o número à esquerda e o rótulo à direita na mesma linha. Por baixo, a `s8`, a nota de privacidade em `corpoPequeno` `tintaTenue`. A `s48`, secção "Escritórios" (`subtitulo`) com `PrimaryButton` "Criar escritório" à direita; lista com réguas: nome do escritório (`corpoForte`), `registo` "3 mediadores", `TextAction` "Convidar mediador". Sem nomes nem emails de pessoas em lado nenhum.
- **Criar escritório / Convidar mediador:** `folhaLateral` com um formulário cada (regras de folha lateral por tamanho em "Responsividade").
- **Médio e compacto (utilizável, não otimizado):** médio igual ao largo sem moldura centrada. Compacto: contagens empilhadas (número à esquerda, rótulo à direita, réguas entre elas); "Criar escritório" passa para baixo do título da secção, a toda a largura, 56; cada escritório empilha nome, "3 mediadores" e "Convidar mediador" (alvo 48); folhas laterais passam a ecrã inteiro.
- **Componentes e tokens:** `FolderTab`, `RuledList`, `PrimaryButton`, `TextAction`, `LabeledField`, `InlineNotice`, `SkeletonRows`; `AppType.numero`.
- **Copy:**
  - Título: "Plataforma"
  - Contagens: "Escritórios", "Mediadores", "Clientes"
  - Nota: "Só contagens. Por privacidade, a administração não vê nomes, emails nem documentos."
  - Lista: "{n} mediadores" (singular "1 mediador"; zero "Sem mediadores")
  - Criar escritório: título "Criar escritório"; campo "Nome do escritório"; botão "Criar escritório" / "A criar…"; sucesso "Escritório criado. Convide agora o primeiro mediador."; erro "Já existe um escritório com este nome."
  - Convidar mediador: título "Convidar mediador"; campos "Email" e "Escritório" (preenchido quando se vem de uma linha); apoio "O mediador recebe um email para definir a palavra-passe. Cada mediador pertence a um só escritório."; botão "Enviar convite" / "A enviar…"; sucesso "Convite enviado."; erro "Não foi possível convidar este email. Pode já pertencer a um escritório."
  - Vazio: "Ainda não há escritórios." + "Crie o primeiro escritório para poder convidar mediadores." + `PrimaryButton` "Criar escritório"; contagens a "0".

## Responsividade por ecrã

Compacto < 640 (telemóvel), médio 640 a 1100 (tablet), largo > 1100 (desktop). "Moldura" = `PageFrame`; em largo fica centrada com máximo 1040. Alvos: 48 em tudo; 56 onde indicado.

| Ecrã | Compacto | Médio | Largo | Folhas e diálogos | Teclado e foco (todos; obrigatório em largo) |
| --- | --- | --- | --- | --- | --- |
| 1. Entrar | Coluna à largura toda (margem 16), separador fixo "Acesso", "Entrar" e "Receber link…" 56 a toda a largura, sem foco automático, sem conta no topo | Coluna 400 à esquerda, resto em `papel`, foco no Email | Coluna 400 à esquerda da moldura (não a 1/3 da janela) | Nenhuma | Enter submete "Entrar", nunca o link; "Receber link…" no fim da ordem |
| 1c. Criar palavra-passe | Coluna à largura toda, botões empilhados 56, sem foco automático, "Sair" no topo | Coluna 400 à esquerda, foco no campo | Idem na moldura | Nenhuma | Enter guarda; "Agora não" depois de "Guardar" |
| 1b. Recuperar / definir palavra-passe | Como Entrar; regras visíveis acima do teclado junto com o campo | Como Entrar | Como Entrar | Nenhuma | Enter submete; "Voltar a entrar" no fim da ordem |
| 2. Link expirado | Como Entrar, separador "Acesso", sem foco automático | Coluna 400, foco no título | Idem | Nenhuma | Título, Email, "Enviar link novo", "Já tem palavra-passe? Entrar com ela" |
| 2. A validar link | Skeleton com a forma do consentimento compacto | Skeleton na coluna 640 | Idem | n/a | n/a |
| 3. Aceitar partilha | Largura toda, título 26, barra fixa à largura da janela, botões 50/50 56; altura < 480: barra sem linha de apoio e padding 8 | Coluna 640 à esquerda, título 30, barra com conteúdo alinhado à coluna | Coluna 640 na moldura centrada, 400 livres à direita | Nenhuma | Foco no título; Recusar antes de Aceitar; sem botão por defeito; Esc sem efeito |
| 4. Com quem partilho | Linhas empilhadas; "Responder" 56, "Retirar acesso" e "Criar palavra-passe" 48 a toda a largura | Coluna 640, ações à direita empilhadas; passa a empilhado se o texto < 240 | Idem na moldura centrada | Retirar: folha inferior (compacto) / diálogo 480; texto aceite: folha alta / diálogo 640 | Foco no bloco pendente ou título; foco inicial do diálogo em "Cancelar"; Esc cancela; foco volta à linha |
| 5. Clientes | Lista empilhada sem cabeçalhos, email até 2 linhas, "Criar cliente" 56 a toda a largura | Tabela de 3 colunas (Estado + data juntos, 248) | Tabela de 4 colunas (140 / 248 / 160) em 1040 | Criar cliente: ecrã inteiro com botões no fluxo (compacto) / folha lateral 440 com barra fixa | Criar cliente, Reenviar por ordem, Mostrar mais; Enter submete a folha; Esc fecha |
| 6. Admin | Contagens empilhadas, linhas empilhadas, folhas em ecrã inteiro | Como largo sem centrar | Desenho de referência | Folha lateral 440 / ecrã inteiro | Igual às outras folhas |
| Todos | Linha do separador: separador + "Sair" (sem nome); marca só no colofão, empilhado, no fim do scroll | Separador + nome + "Sair" | Idem, alinhado à moldura | Véu `veu`, sombra `AppShadow.superficie`, "voltar" do navegador fecha primeiro a folha | Anel `foco` 2 + afastamento 2, só com teclado |

## Matriz de estados

Ação principal de cada estado entre parênteses. Offline: `OfflineBar` no topo (fundo `tinta`, texto `sobreTinta`, ícone "cloud_off") com "Sem ligação à internet. Pode ver o que está no ecrã; as alterações ficam bloqueadas até a ligação voltar."; nunca se mostra como aceite, recusado ou retirado algo que o servidor não confirmou.

| Ecrã | Populado | Vazio | A carregar | Erro | Offline | Desativado | Sem acesso / sessão |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Entrar | Email e palavra-passe preenchidos (Entrar); depois de "Receber link", confirmação com "Enviar outra vez" | Campos vazios, foco no Email (médio/largo) | Spinner no botão carregado ("A entrar…" / "A enviar…"); o outro botão e os campos ficam desativados | "Email ou palavra-passe incorretos." por cima do botão, com a dica do link por baixo, foco no Email; link sem email: erro no campo Email. Todos: "Não foi possível ligar. Verifique a ligação e tente de novo." (repetir) | Faixa com texto próprio: "Sem ligação à internet. Precisa de ligação para entrar." (nenhuma) | "Entrar" e "Receber link…" desativados com razão por baixo se offline; "Enviar outra vez" bloqueado 60 s | Sessão terminada: mensagem por cima do formulário |
| Criar palavra-passe | Campo preenchido, regra cumprida (Guardar palavra-passe) | Campo vazio, regra com ícone vazio (Agora não continua ativo) | "A guardar…" no botão; "Agora não" desativado | "Não foi possível guardar a palavra-passe. Tente de novo." por cima dos botões | Faixa; "Guardar" desativado com "Precisa de ligação para guardar."; "Agora não" ativo | Regra por cumprir: "Guardar" desativado com a regra visível | Sessão terminada: volta a Entrar com a mensagem de sessão |
| Recuperar / definir palavra-passe | Email ou nova palavra-passe preenchidos (Enviar link / Guardar e entrar) | Campo vazio (idem) | Spinner no botão | Link expirado: ecrã "Este link já não é válido" (Recuperar palavra-passe); falha de envio: "Não foi possível enviar. Tente de novo." | Faixa; botão desativado | Regras por cumprir: o botão continua ativo; ao carregar, erro de palavra-passe fraca (1d) | n/a |
| Abrir link | n/a | n/a | Skeleton do consentimento | Expirado ou inválido: ecrã explicativo com campo de email (Enviar link novo) | Faixa + "Precisa de ligação para abrir o link." | "Enviar link novo" bloqueado 60 s após envio | Já respondido: vai para Com quem partilho com aviso |
| Aceitar partilha | Título, resumo, texto, barra de ações (Aceitar / Recusar, mesmo peso) | n/a | Skeleton (separador, título 2 linhas, 3 linhas de resumo, 6 linhas de texto); barra de ações já visível mas desativada | Falha ao registar: `InlineNotice` erro por cima dos botões "Não foi possível registar a sua resposta. Nada foi alterado. Tente de novo." (botão carregado volta ao normal); texto de consentimento não carregou: "Não foi possível carregar o texto. Sem o ler não pode responder." (Tentar de novo) | Faixa; ambos os botões desativados com "Precisa de ligação para responder." | Durante envio: o outro botão desativado | Pedido já não pendente: aviso e Com quem partilho |
| Com quem partilho | Com pendentes: bloco `realce` no topo (Responder). Sem pendentes: grupos com linhas (Retirar acesso). No fim, "A sua conta" (Criar palavra-passe) | "Ainda não partilha dados com nenhum escritório." (sem botão; explica que os pedidos aparecem aqui) | `SkeletonRows` 3 linhas com a forma nome + carimbo + data; o bloco pendente só aparece com dados confirmados (nunca em skeleton com fundo `realce`) | "Não foi possível carregar a lista. Tente de novo." (Tentar de novo); falha ao retirar: aviso dentro da folha "Não foi possível retirar o acesso. O escritório continua com acesso. Tente de novo." e a linha fica igual | Faixa; "Retirar acesso" e "Responder" desativados com "Precisa de ligação." por baixo | "Retirar acesso" desativado enquanto a folha envia | Sessão terminada: "A sua sessão terminou. Entre de novo para continuar." (Entrar) |
| Clientes | Tabela com ativos, pendentes e recusados (estes sem ação); caso longo com reticências (Criar cliente) | "Ainda não tem clientes" (Criar cliente) | `SkeletonRows` 6 linhas com as colunas da tabela; título e botão visíveis | Lista: "Não foi possível carregar os clientes. Tente de novo." (Tentar de novo); erros de criar e de reenviar como na copy | Faixa; "Criar cliente" e "Reenviar pedido" desativados com razão | "Reenviar pedido" 60 s após envio; "Criar e enviar pedido" até os dois campos serem válidos; linhas recusadas sem ação (não é desativado: não existe botão) | Cliente que retirou desaparece da lista sem aviso; dados de outro escritório nunca aparecem |
| Colofão (todos) | Wordmark + linha do perfil + registo | Igual; encosta ao fundo da janela | Só o wordmark (cliente e mediador) até o perfil chegar; nunca skeleton | Igual | Igual (a faixa fica no topo) | n/a (nada focável) | Sem sessão: frase sem sessão, sem registo |
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
| `ConfirmSheet` (escala do diálogo) | Idem | escala inicial `AppMotion.escalaDialogo` 0.98 |
| Folha lateral (criar cliente, escritório, convite), médio e largo | Abrir / fechar | entra `lento` / `entrar` (desliza da direita, origem no botão do mesmo lado); sai `base` / `sair` |
| Formulário em ecrã inteiro (compacto) | Abrir / fechar | Transição de página (ver "Transições entre ecrãs"); nada de deslizar da direita a imitar a folha |
| Barra fixa (consentimento, folha) ao abrir o teclado virtual | Teclado aparece | Sem animação própria: acompanha o teclado |
| `StatusStamp` | Estado confirmado pelo servidor | `base` / `mudar` (cross-fade do carimbo antigo para o novo) |
| Linha retirada | Retirada confirmada | sai de "Com acesso" `base` / `sair` (opacidade + altura); entra em "Sem acesso" `lento` / `entrar`; fundo `realce` desvanece em `realce` |
| Pedido no bloco pendente | Respondido (vindo do ecrã 3) | sai do bloco `base` / `sair` (opacidade + altura); o bloco fecha com `lento` / `mudar` quando fica vazio; a linha entra no grupo de destino `lento` / `entrar` com `realce` a desvanecer |
| Entrar: formulário para confirmação do link e de volta | "Receber link" confirmado / "Entrar com palavra-passe" ou "Usar outro email" | cross-fade `base` / `mudar`, sem deslizar; a altura ajusta em `base` / `mudar`; o foco passa para a confirmação (live region) ou para o Email |
| Regra da palavra-passe (1c e definir) | Passa a cumprida ou deixa de estar | troca de ícone em `rapido` / `mudar`; o texto não muda; leitura de ecrã anuncia "Regra cumprida" |
| Linha de cliente nova | Cliente criado | entra no topo `lento` / `entrar`; fundo `realce` desvanece em `realce` |
| Barra de ações do consentimento para bloco de resultado | Resposta confirmada | `base` / `mudar` (cross-fade); o foco move-se para o resultado e é anunciado (live region) |
| Skeleton | A carregar | `pulsar` (opacidade 1.0 a `pulsarMinimo` 0.55, ida e volta) |
| Mudança de breakpoint (janela redimensionada, tablet rodado) | Largura cruza 640 ou 1100 | Sem animação: o layout troca de corte seco; o foco e a posição de scroll mantêm-se no mesmo elemento |
| Contagens do admin | Dados chegam | Sem contagem animada: o número aparece com `base` / `entrar` em opacidade |
| Mudança de ecrã | Navegação | Cross-fade `base` (ver "Transições entre ecrãs"); nenhuma animação de entrada de ecrã além disso |
| Linha do colofão | Perfil chega (cliente, mediador) | `base` / `entrar` (opacidade); o wordmark já estava no sítio |

## Transições entre ecrãs

Revisto a 2026-11-26. Antes dizia "transição por defeito da plataforma"; em web isso varia por versão do Flutter, por isso fica fixada aqui. Nada desliza entre ecrãs: a app não tem pilha de ecrãs visível (não é uma app nativa) e um deslize sugere uma hierarquia que o navegador não mostra. Tokens de `AppMotion` (DESIGN.md).

| Tipo | Quando | Movimento | Duração / curva | O que persiste | Voltar do navegador | Foco | Reduzir movimento |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Página | Mudança de rota (Entrar → Com quem partilho, consentimento → Criar palavra-passe, Clientes → criar cliente em compacto) | Cross-fade: o ecrã novo entra em opacidade 0 → 1, o antigo sai 1 → 0 | `base` 200 ms; entra `entrar`, sai `sair` | Nada se anima à parte; a moldura e o separador aparecem já no sítio final (mesma posição nos dois ecrãs, por isso parecem ficar) | Volta ao ecrã anterior com a mesma transição | Título do ecrã novo (médio/largo) ou topo do documento (compacto); se houver `InlineNotice` de resultado, vai para ela | Corte seco |
| Estado no mesmo ecrã | Resposta do servidor muda o ecrã (Aceitar → resultado, erro, enviado, regra cumprida) | Cross-fade do bloco que muda; a altura ajusta | `base` 200 ms / `mudar` | Tudo o que não muda fica parado (título, separador, resumo) | Não cria entrada no histórico (é o mesmo ecrã) | Vai para o bloco novo, anunciado (live region) | Corte seco |
| Skeleton → dados | Dados chegam | Cross-fade dos blocos `esqueleto` para o conteúdo; o skeleton já tem a forma final, nada salta | `base` 200 ms / `entrar`; o skeleton pulsa em `pulsar` 1200 ms até lá | Separador, título e barra de ações (já no sítio, desativada) | n/a | Fica onde estava | Sem pulsar; corte seco |
| Diálogo (médio/largo) | Retirar acesso, Ler o texto aceite | Véu em opacidade; diálogo opacidade + escala `escalaDialogo` 0.98 → 1 | entra `base` / `entrar`; sai `rapido` / `sair` | O ecrã por baixo não se mexe | Fecha o diálogo primeiro | Preso no diálogo; inicial em "Cancelar"; devolvido ao botão de origem | Corte seco |
| Folha inferior (compacto) | Os mesmos | Sobe do fundo; véu em opacidade | entra `lento` / `entrar`; sai `base` / `sair` | Idem | Fecha a folha primeiro | Idem | Corte seco |
| Folha lateral (médio/largo) | Criar cliente, criar escritório, convidar mediador | Desliza da direita (o lado do botão que a abre); véu | entra `lento` / `entrar`; sai `base` / `sair` | Idem; a lista fica visível por trás do véu | Fecha a folha primeiro | Preso na folha; inicial no primeiro campo; volta a "Criar…" ou à `InlineNotice` de sucesso | Corte seco |
| Fecho com resultado | Folha/diálogo confirmados (cliente criado, acesso retirado, escritório criado) | Folha sai; depois a linha nova entra (opacidade + altura) com `realce` a desvanecer | sai `base` / `sair`; linha `lento` / `entrar`; `realce` 1600 ms | A lista; só a linha alterada se move | O "voltar" não desfaz (não há anular) | `InlineNotice` de sucesso | Sem movimento; o `realce` fica 1600 ms e desaparece de corte |
| Fora da app | Links de email (convite, novo link, recuperação) | Abre um separador novo do navegador; sem transição própria | n/a | n/a | O voltar do separador novo não leva ao email | Título do ecrã | n/a |
| Mudança de breakpoint | Janela redimensionada, tablet rodado | Nenhum: troca de layout em corte seco | 0 | Foco e posição de scroll no mesmo elemento | n/a | Mantém-se | n/a |

Regras: nunca duas transições de página seguidas sem o utilizador agir (exceção: "A validar link" → pedido, que é uma troca de estado e não de página); durante uma transição, cliques e teclas no ecrã que sai são ignorados; nenhuma informação existe só no movimento.

## Fluxos (storyboards)

PNG com a sequência de ecrãs, a ação que leva de um ao outro e a transição usada (`renders/fluxo-*.png`, gerados de `renders/src/fluxos.html`):

1. `fluxo-1-convite.png`: convite por link → a validar → consentimento → aceite → Criar palavra-passe (regras em tempo real) → Com quem partilho com "Palavra-passe criada". Ramos: "Agora não", "Recusar", erro e offline.
2. `fluxo-2-entrar.png`: Entrar → credenciais erradas → Recuperar → email → Definir palavra-passe → ecrã inicial.
3. `fluxo-3-link-expirado.png`: link antigo → "Este link já não é válido" → enviado → email novo → Com quem partilho com o pedido pendente.
4. `fluxo-4-criar-cliente.png`: Clientes → folha Criar cliente → erros de campo → cliente criado → pedido reenviado.
5. `fluxo-5-retirar-acesso.png`: Com quem partilho → folha de confirmação → acesso retirado (ramo: falha ao retirar).
6. `fluxo-6-admin.png`: plataforma vazia → criar escritório → escritório criado → convidar mediador → mediador define a palavra-passe → Clientes vazio.

**Protótipo navegável do fluxo principal:** `renders/src/prototipo.html` (servir a raiz do repositório com `python3 -m http.server` e abrir `http://localhost:8000/docs/features/001-fundacao/renders/src/prototipo.html`). Cobre o fluxo 1 e o 5 com as transições desta secção, o voltar do navegador (fecha primeiro a folha) e "reduzir movimento" do sistema. É HTML de referência: o flutter-dev implementa com `AppMotion`, não copia o código.

## Acessibilidade (verificar na implementação)

- Ordem de foco: separador, título, conteúdo, ações. Em Entrar: Email, Palavra-passe, Mostrar, Entrar, Esqueci-me, Receber link. Em consentimento: título, resumo, texto, Recusar, Aceitar.
- Carimbos com semântica de texto ("Estado: ativo desde 12 de novembro de 2026").
- Escala de texto 1.3: barra de ações do consentimento cresce em altura, nunca corta; tabela de clientes desce um nível (4 colunas, 3 colunas, empilhada) se a coluna Cliente ficar abaixo de `textoMinimo` 240; o mesmo para as linhas de Com quem partilho.
- Zoom do navegador até 400% (largura lógica 320): sem scroll horizontal, nenhuma ação fora do ecrã.
- Folhas e diálogos: foco preso lá dentro, Esc fecha, o foco volta ao botão que os abriu.
- Contraste: todos os pares de texto usados estão a 4.5:1 ou mais (tabela em DESIGN.md); `tintaTenue` nunca sobre `cartolina`.

## Renders

Referências visuais (HTML estático com os tokens e as fontes reais) em `renders/`, com o índice completo em `renders/README.md`: cada ecrã nos três tamanhos (admin: desktop e telemóvel) e, para cada um, os estados populado, vazio, a carregar (skeleton), erro, offline e sucesso, mais os storyboards `fluxo-*.png` e o protótipo `renders/src/prototipo.html`. Todos os PNG com o colofão (regenerados a 2026-11-26); `marca-colofao-*` mostram a proposta escolhida (Entrar e Com quem partilho em página inteira). Os goldens continuam a ser a verificação da implementação: na passagem de polimento (Modo 2) ficam em `test/design_review/001_fundacao/` (tag `design-review`), a 390 × 844, 768 × 1024 e 1280 × 800, escala de texto 1.0 e 1.3, com as fontes reais. Extras: 320 de largura (Entrar e consentimento), 844 × 390 (consentimento em altura baixa), 1024 de largura (Clientes no limite da tabela de 3 colunas). Admin: só 1280 e 390.
