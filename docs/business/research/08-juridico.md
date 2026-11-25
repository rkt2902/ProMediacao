# Briefing para parecer jurídico (RGPD e distribuição de seguros)

> Documento para entregar ao jurista. Contém factos sobre o produto e perguntas. Nenhuma das afirmações sobre enquadramento legal é uma conclusão: são hipóteses de trabalho que pedimos para confirmar ou corrigir.
> Estado: rascunho, 2026-11-25. Decisão de origem: `docs/decisions.md` (validação jurídica antes de qualquer cliente real).

## 1. O produto e o fluxo de dados

1. **ProDossier** (nome de trabalho) é uma app web/móvel que ajuda mediadores de seguros a recolher documentos e dados dos clientes para preparar simulações e propostas. Mais tarde inclui crédito (habitação e outros).
2. **Fluxo:** o mediador cria um pedido por tipo de seguro (vida, saúde, automóvel, acidentes de trabalho, etc.); o cliente recebe um link por email (ou dentro da app), carrega documentos e dados; o mediador revê cada documento; a app gera uma ficha (PDF/Excel) que o mediador introduz à mão nas plataformas das seguradoras. A app não contacta seguradoras.
3. **Dados tratados:** identificação (CC, NIF), morada, contactos, dados financeiros e, nos seguros de vida, saúde e doenças graves, **dados de saúde**.
4. **Os dados são do cliente** e são partilhados por consentimento explícito com cada **escritório** de mediação, tudo ou nada: todos os mediadores desse escritório veem o arquivo. O cliente vê a que escritórios deu acesso e pode retirar a qualquer momento. Pode pedir a vários escritórios ao mesmo tempo; nenhum vê os outros.
5. O cliente pode ser criado por um mediador ou registar-se sozinho. Os documentos ficam num arquivo pessoal e são reutilizados entre pedidos.
6. **Admin da plataforma** (a empresa que explora a app) **não acede** a documentos nem a dados de pedidos: vê só contagens e agregados, sem nome nem email.
7. **Sem encriptação por escritório na fase 1** (encriptação em trânsito e em repouso do fornecedor, sim). O dono do projeto mantém **acesso técnico de serviço** à base de dados, que será auditado.
8. **Alojamento:** Supabase (base de dados, ficheiros, autenticação), região UE **eu-west-1 (Irlanda)**.
9. **IA:** leitura de texto/OCR feita localmente; a estruturação dos campos é feita pelo **Claude Haiku**, via **API da Anthropic** (EUA). Um modelo maior pode ser usado em digitalizações más. A IA só extrai e sugere; o mediador revê e decide sempre.
10. **Comunicações:** email transacional (fornecedor por escolher). SMS e WhatsApp integrados ficam **fora** da fase 1; o mediador pode copiar o link e enviá-lo pelo seu telemóvel. **Receita futura:** mensalidade paga pelo escritório, sem comissões. Fase 1 em uso interno, sem cobrar.

## 2. Perguntas

1. **Dados de saúde (art. 9.º RGPD).** Recolhemos questionários e relatórios médicos para seguros de vida e saúde. Qual a base de licitude adequada (consentimento explícito do art. 9.º, n.º 2, al. a), ou outra) e quem a deve recolher: a plataforma, o escritório ou ambos?
2. **AIPD.** Pela combinação de dados de saúde, uso de IA e partilha com vários escritórios, é obrigatória uma avaliação de impacto (art. 35.º)? Quem a faz (plataforma, escritório) e pode ser feita uma vez para todos os escritórios?
3. **Responsável vs subcontratante.** O nosso entendimento provisório: cada escritório é responsável pelo tratamento dos dados dos seus clientes e a plataforma é subcontratante. Mas o cliente pode registar-se sozinho e guardar o arquivo antes de partilhar com qualquer escritório. Nesse período, e no arquivo pessoal em geral, a plataforma passa a ser responsável? Há corresponsabilidade (art. 26.º)?
4. **DPA.** Que acordos são precisos: plataforma–escritório (art. 28.º), plataforma–subcontratantes ulteriores, e eventualmente acordo de corresponsáveis? Como se gere a autorização de subcontratantes ulteriores (geral com aviso, ou específica)?
5. **Retirada de consentimento vs conservação.** Quando o cliente retira o acesso, o escritório perde de imediato os documentos originais; fichas já exportadas e o histórico ficam sem os originais. O mediador tem deveres de conservação (Lei 7/2019, branqueamento de capitais, fiscais). Este desenho é compatível? A plataforma deve guardar uma cópia em nome do escritório, ou isso cabe ao escritório fora da app?
6. **Apagamento a pedido do cliente.** Se o cliente apaga um documento do arquivo, que limites existem quando esse documento já serviu de base a uma proposta ou apólice?
7. **Ficheiros exportados.** A ficha em PDF/Excel sai da plataforma para o computador do mediador. A partir desse momento a responsabilidade é só do escritório? Devemos informar o cliente disso no consentimento?
8. **Transferências internacionais e subcontratantes.** Anthropic (EUA, API do Claude), Supabase (empresa dos EUA, dados na Irlanda), fornecedor de email (por escolher) e, no futuro, SMS. Que mecanismo é preciso para cada um (EU-US Data Privacy Framework, cláusulas contratuais-tipo, avaliação de impacto da transferência)? É aceitável enviar dados de saúde para a API da Anthropic, e com que condições (retenção zero, não uso para treino, DPA)?
9. **Acesso técnico do dono do projeto.** Na fase 1 não há encriptação por escritório e o dono do projeto tem acesso de serviço à base de dados. Isto é aceitável com dados de saúde? Que medidas mínimas pedem (registo de acessos, compromisso de confidencialidade, justificação por acesso, cláusula no DPA)? A encriptação por escritório deve ser condição antes de clientes reais?
10. **Uso de IA.** A IA extrai campos e sugere valores; a decisão e a validação são sempre do mediador. Isto afasta o art. 22.º RGPD (decisões automatizadas)? Há obrigações do Regulamento da IA (AI Act) aplicáveis, por exemplo de transparência, dado o setor de seguros de vida e saúde?
11. **Posição face à ASF (Lei 7/2019).** A app não vende, não aconselha, não compara preços em nome de seguradoras e não recebe comissões; apoia o mediador na recolha de documentos. Isto é suficiente para a plataforma não ser considerada distribuidora nem mediadora de seguros? Há funcionalidades previstas que mudem isso, como "Comparar preços" e "Pedir alteração" a partir de uma apólice, ou o cliente enviar pedidos a vários escritórios?
12. **Nome e comunicação.** O nome **ProDossier** e os textos da app levantam algum problema (parecer seguradora ou mediador)? O nome interno "ProMediação" poderia ser usado publicamente?
13. **Crédito (DL 81-C/2017).** O Henrique indica que o registo no Banco de Portugal é do lado do mediador/intermediário de crédito e que a app só manipula documentos. Isto chega, ou a plataforma precisa de algum registo, estatuto ou cuidado específico (por exemplo, não poder ser vista como intermediário de crédito ou prestador de serviços de consultoria)?
14. **Modelo de receita.** Mensalidade paga pelo escritório, por escalões de pedidos, sem comissão por apólice, lead ou percentagem do prémio. Este modelo tem implicações na qualificação da plataforma perante a ASF ou o Banco de Portugal? Cobrar por pedido (e não só mensalidade fixa) muda alguma coisa?
15. **Fase 1 em uso interno.** O uso interno já envolve dados reais de clientes de um escritório. Que mínimo é preciso ter em vigor antes desse primeiro uso (DPA, política, consentimento, AIPD, registo de atividades)?
16. **Encarregado de proteção de dados.** A plataforma e/ou os escritórios precisam de designar um EPD (art. 37.º), tendo em conta o tratamento de dados de saúde em escala?

## 3. Documentos a pedir ao jurista

1. **Minuta de DPA** entre a plataforma e cada escritório (art. 28.º), com anexo de subcontratantes ulteriores e medidas de segurança.
2. **Política de privacidade** da plataforma (cliente final e mediador).
3. **Texto de consentimento** do cliente para partilha com cada escritório, incluindo dados de saúde e uso de IA, e o texto de retirada.
4. **Termos de utilização** para escritórios (com a delimitação do papel da plataforma face à ASF e ao Banco de Portugal) e para clientes.
5. **Modelo de AIPD** ou indicação de quem a faz, caso seja obrigatória.
6. **Registo de atividades de tratamento** (art. 30.º) da plataforma, em modelo.
7. **Lista de verificação** das condições mínimas para entrar o primeiro cliente real.
