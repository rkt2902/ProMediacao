# ProMediação: contexto inicial

> **Rascunho.** Nada aqui é definitivo, nem o que está marcado como [decidido]: é o ponto de partida vindo da thread de planeamento. Cada ponto só passa a definitivo quando for aprovado num gate do `/feature` e registado em `docs/decisions.md`.
>
> Nota: entretanto já foi criado um projeto Supabase (`aboducqavmsmlzslrseu`, eu-west-1) e o projeto Flutter. O backend continua por confirmar.


Resumo do trabalho feito na thread de planeamento (16/10 a 25/11/2026), para servir de ponto de partida no repositório `rkt2902/ProMediacao`.
Legenda: **[decidido]** foi acordado com o Henrique · **[proposto]** foi sugerido mas não confirmado · **[por decidir]** nunca foi discutido.

## 1. O produto

**Numa frase:** um portal onde o mediador pede ao cliente os documentos e dados de que precisa para um seguro (e, mais tarde, um crédito), o cliente envia tudo num só sítio, e a IA organiza a informação numa ficha pronta a introduzir nas plataformas das seguradoras.

**Para quem:**
- **Mediadores** de seguros, que recolhem documentos e preparam simulações e propostas.
- **Clientes** particulares e empresas, que enviam documentos, acompanham os pedidos e gerem os seus seguros.
- **Admin** (o Henrique), que gere mediadores, clientes e a plataforma.

**Problema que resolve:**
- Hoje o mediador pede documentos avulso (email, WhatsApp, papel) e a lista muda consoante o tipo de seguro.
- Depois passa os dados à mão para a plataforma de cada seguradora.
- O portal dá ao cliente uma lista clara do que falta e guarda os documentos para reutilizar. Ao mediador, entrega uma ficha única, já extraída e verificada.

**Fonte dos requisitos:** o documento "Documentos Seguros.pdf", com os dados e documentos pedidos por tipo de seguro. Os tipos são:
- Vida, Vida Habitação e Doenças Graves
- Multirriscos Habitação e Multirriscos Negócio
- Saúde, Acidentes Pessoais e Automóvel
- Acidentes de Trabalho, de prémio fixo e de prémio variável
- Pets, Responsabilidade Civil e Obras

**Seguradoras de referência** (do mesmo documento): Metlife, InovaGo, April, Mapfre, Prevoir, Tranquilidade, Real Vida, Victoria, Allianz, Saúde Prime, UNA Seguros, ASISA, Zurich e Arag.

**Alternativa ao pedido documento a documento:** pedir as **condições particulares** da apólice atual, que concentram os dados do tomador.

## 2. Modelo de receita e concorrentes

- **Modelo de receita:** [decidido] fase 1 em uso interno, sem cobrar. Direção futura: mensalidade por mediador/escritório até X pedidos, e acima disso extra ou outro plano. Cobra-se só ao mediador/escritório, nunca ao cliente final e sem comissão (nem por apólice, nem por leads, nem % do prémio). Valores por validar. Ver `docs/business/research/02-receita-concorrentes.md`.
- **Concorrentes:** [proposto] analisados 7 em `docs/business/research/02-receita-concorrentes.md`. Não se encontrou portal português equivalente (a confirmar com colegas da APROSE). Diferenciação proposta: arquivo de documentos do cliente reutilizável e partilhável, com consentimento, com vários mediadores.

## 3. Restrições

**Aviso:** estas restrições são um ponto de partida e não foram validadas por um jurista.

- **RGPD:** há dados pessoais e de **saúde**, que são uma categoria especial (art. 9.º). Isto implica:
  - consentimento explícito;
  - encriptação e alojamento na UE;
  - acesso só dos mediadores a quem o cliente deu consentimento (ver secção 4);
  - poder apagar documentos a pedido do cliente.
- **Distribuição de seguros:** é uma atividade regulada pela ASF (Lei n.º 7/2019). A app apoia o mediador e não deve parecer uma seguradora nem vender diretamente.
- **Intermediação de crédito**, para a fase dos empréstimos: é regulada pelo Banco de Portugal (DL 81-C/2017) e exige registo próprio. Deve ser confirmado antes de lançar essa parte.
- **Uso de IA:** a IA só extrai e sugere. As decisões e a validação dos dados ficam sempre com o mediador, através da revisão manual.

## 4. Decisões tomadas

- [decidido] Os dados são do cliente e partilhados por consentimento explícito, mediador a mediador (X, Y, Z...), com o cliente sempre ciente e a poder retirar. Condiciona o modelo de dados, o RLS e a validação RGPD.
- [decidido] A partilha é do cliente para o **escritório**, tudo ou nada: todos os mediadores do escritório veem o arquivo, e o cliente vê e pode retirar cada escritório. O admin da plataforma **não** acede a documentos nem a dados dos clientes, só a metadados e agregados.
- [decidido] Há três perfis: admin, mediador e cliente (particular ou empresa).
- [decidido] O mediador cria um pedido por tipo de seguro, e a lista do que pedir é gerada automaticamente a partir do tipo.
- [decidido] O mediador também pode preencher dados no perfil do cliente.
- [decidido] O cliente pode enviar as condições particulares em vez dos documentos um a um.
- [decidido] A extração faz-se em duas fases:
  - leitura de texto local e gratuita (texto do PDF, OCR com Tesseract ou PaddleOCR, leitura ótica do CC);
  - estruturação dos campos com o Claude Haiku 5.5, a cerca de 0,001 USD por pedido (estimativa, não medida).
- [decidido] Um modelo maior só é usado como recurso para digitalizações más.
- [decidido] O design veio antes da especificação e da base de dados, para mostrar a ideia a um cliente.
- [decidido] Cada documento recebido tem revisão manual pelo mediador, que o aprova ou pede um novo com uma nota para o cliente.
- [decidido] Antes de exportar a ficha, a IA faz uma análise rápida: confirma o que está certo, lista o que falta e sugere valores encontrados nos documentos.
- [decidido] O cliente tem uma área própria com os seus seguros, os pedidos com estado, a possibilidade de pedir vários seguros e um arquivo de documentos.
- [decidido] Os documentos guardados são reutilizados entre pedidos. Por exemplo, o CC carregado uma vez serve para todos.
- [decidido] O design é responsivo em três tamanhos: desktop, tablet ou PC pequeno (até 1100 px) e telemóvel (até 640 px).
- [decidido] A app vai incluir empréstimos no futuro, e por isso o nome não pode ser só de seguros.
- [decidido] O trabalho continua no repositório `rkt2902/ProMediacao`, com uma app Flutter.
- [decidido] Stack: Flutter + **Supabase** (eu-west-1, projeto vazio). Auth: cliente por link mágico por email; mediador e admin por email e palavra-passe (2FA mais tarde). SMS só no futuro. Ver `docs/decisions.md`.
- [decidido] O nome de trabalho é **ProDossier** (reserva: Reúne). O repositório e o package id `pt.promediacao` ficam como nome interno. Falta verificar a marca no INPI/TMview (classes 9, 42, 35) e os domínios antes de publicar nas lojas. Ver `docs/decisions.md`.

## 5. Backlog

| Funcionalidade | Estado |
|---|---|
| Login e perfis admin, mediador e cliente | aprovada |
| Painel do mediador com os pedidos, o progresso e filtros por estado | aprovada |
| Novo pedido: escolher o cliente e o tipo de seguro, com a lista automática do que pedir | aprovada |
| Opção "condições particulares" em vez dos documentos individuais | aprovada |
| Envio do pedido ao cliente por link seguro (email ou SMS) | aprovada |
| Cliente carrega documentos e preenche dados, com indicação de progresso | aprovada |
| Extração automática (OCR local e estruturação com o Haiku) | aprovada |
| Ficha extraída com a origem de cada campo e os campos a confirmar | aprovada |
| Revisão manual de cada documento (aprovar ou pedir novo com nota) | aprovada |
| Análise da IA antes de exportar, com sugestões para os dados em falta | aprovada |
| Exportar a ficha em PDF e Excel | aprovada |
| Mediador preenche dados em falta diretamente na ficha | aprovada |
| Área do cliente com os seguros ativos, a seguradora, a renovação e o prémio | aprovada |
| Estado do pedido em 4 etapas (criado, documentos enviados, em análise, enviado às seguradoras) | aprovada |
| Cliente pede um ou vários seguros de uma vez | aprovada |
| Arquivo de documentos do cliente: ver, atualizar, remover, validade, onde é usado | aprovada |
| Reutilização de documentos entre pedidos | aprovada |
| Avisos de documentos a atualizar (por exemplo, morada com mais de 6 meses) | aprovada |
| "Pedir alteração" e "Comparar preços" a partir de uma apólice | aprovada |
| Painel de admin: mediadores, clientes, pedidos e custo de IA | aprovada |
| Design responsivo (desktop, tablet e telemóvel) | aprovada |
| Fichas ajustadas ao formulário de cada seguradora | proposta |
| Módulo de empréstimos e crédito | proposta |
| Piloto com mediadores reais | proposta |
| Testar a extração com documentos reais e escolher o modelo mais barato que acerte | proposta |

## 6. Protótipo (referência)

**Importante:** o protótipo serve de referência de fluxos e de conteúdo. A app Flutter deve integrá-lo da melhor forma e não copiar o HTML.

**Onde está:**
- Página funcional: https://claude.ai/artifact/MWLvfyRNXQu6L1N4KngYY6
- Ficheiro autónomo: `/mnt/project-files/prototipo/Dossier-Seguros-prototipo.html`
- Canvas de design inicial: https://claude.ai/artifact/DkeiuBuxqHTWCT3FMNmxfg

O nome provisório no protótipo é "Dossier". Um seletor no canto inferior troca entre a vista do mediador e a do cliente, e as duas partilham os mesmos dados.

**Ecrãs do mediador:**
1. **Painel:** os pedidos de todos os clientes, com o progresso, o estado (à espera do cliente, pronto para exportar, exportado) e a etiqueta "Pedido pelo cliente".
2. **Novo pedido:** o nome e o contacto do cliente, os 13 tipos de seguro, a lista gerada do que pedir (documento ou dado), as notas de cada tipo, a opção de condições particulares e uma mensagem.
3. **Ficha do pedido:**
   - Os documentos recebidos, cada um com "Abrir para rever". A revisão mostra a pré-visualização, uma checklist e os botões aprovar ou pedir novo.
   - Os campos do tomador e do seguro, com a origem de cada um e campos editáveis.
   - Exportar abre a análise da IA, com o que está certo, o que falta, sugestões e "Pedir ao cliente".

**Ecrãs do cliente:**
1. **Os meus seguros:** um resumo, os pedidos em curso com as 4 etapas, e as apólices com "Pedir alteração" e "Comparar preços".
2. **Pedir seguro:** a escolha de vários tipos, quantos documentos já tem guardados para cada um e uma nota.
3. **Documentos:** o arquivo pessoal com o estado, a validade, os pedidos que usam cada documento, e as opções atualizar, remover e adicionar.
4. **Pedido:** o estado, o progresso, os documentos (incluindo os reutilizados), os dados, o aviso quando o mediador pede um novo documento, e o atalho das condições particulares.

**Fluxo principal:**
1. O mediador cria um pedido.
2. O cliente envia documentos e dados.
3. O mediador revê os documentos.
4. A IA analisa a ficha e sugere o que falta.
5. O mediador exporta a ficha e introduz os dados nas plataformas das seguradoras.

## 7. O que ficou por decidir

1. ~~O nome final e a marca~~ **Decidido: ProDossier** (nome de trabalho). Pendente: o Henrique verifica o INPI e os domínios.
2. ~~O modelo de receita~~ **Decidido:** uso interno agora; mensalidade por mediador/escritório com escalões de pedidos no futuro.
3. Os concorrentes e o que diferencia a ProDossier. Analisados; diferenciação proposta (dados do cliente partilháveis por consentimento) por confirmar.
4. ~~O backend e a autenticação~~ **Decidido:** Supabase; cliente por link mágico por email, mediador/admin por palavra-passe. Pendente: plano de produção (decisão 8).
5. O modelo de dados: clientes, pedidos, documentos, apólices e mediadores.
6. O formato final da ficha exportada e se é ajustado a cada seguradora.
7. Como o cliente recebe o pedido (email, SMS ou WhatsApp).
8. A validação jurídica do RGPD (dados de saúde) e do registo para a intermediação de crédito.
9. O âmbito e os documentos do módulo de empréstimos.
10. O piloto: com que mediadores e clientes, e quando.
