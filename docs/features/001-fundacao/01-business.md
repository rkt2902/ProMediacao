# 01 Negócio: 001 Fundação (autenticação, perfis, escritórios e consentimento)

**Objetivo de negócio:**
Esta feature não traz valor que o cliente ou o mediador vejam, mas sem ela não há produto: é a base de tudo o resto. O valor de negócio está em provar desde o início o diferenciador proposto, ou seja, que os dados são do cliente, que são partilhados com um escritório por consentimento e que esse consentimento pode ser retirado. Também desbloqueia dois critérios de que dependem o piloto e o parecer jurídico: o isolamento entre escritórios testado pelo qa (passagem da fase A para a B) e o registo auditável do consentimento (pergunta 15 do briefing jurídico). Se esta base sair errada, cada feature seguinte herda o erro no RLS, e corrigi-lo com dados reais custa muito mais.

**Métrica de sucesso:** (verificada no fecho da feature, pelo qa, sem dados reais)
1. **Isolamento: zero fugas** numa matriz de testes de RLS feita contra a base de dados e não só na UI. Cenários mínimos:
   - um mediador do escritório A não lê clientes, concessões nem auditoria do escritório B;
   - um mediador não lê um cliente sem concessão ativa;
   - um cliente não vê os outros escritórios a que outro cliente deu acesso;
   - o admin não consegue ler nome nem email de ninguém e só obtém contagens;
   - um utilizador sem sessão não lê nada.
2. **Retirada imediata:** depois de o cliente retirar o acesso, o pedido seguinte do mediador já devolve 0 linhas (sem cache nem atraso).
3. **Auditoria completa:** 100% das criações e retiradas de concessões ficam no registo com quem, quando, que escritório e que versão do texto foi aceite. O registo não pode ser alterado nem apagado por nenhum perfil da app.
4. **Tempo de arranque:** o admin cria o escritório e o mediador, o mediador cria o cliente e o cliente entra pelo link mágico e aceita a partilha, tudo em **menos de 10 minutos** e sem ajuda técnica. Mede-se uma vez, com o Henrique, no ambiente de teste.

**Versão mínima que prova valor:**
- Login do mediador e do admin com email e palavra-passe, e do cliente por link mágico. Recuperação de palavra-passe com o fluxo por defeito do Supabase.
- O admin cria escritórios e convida mediadores. Cada mediador pertence a **um só** escritório.
- O mediador cria um cliente (nome e email). A concessão fica **pendente** até o cliente a aceitar pelo link mágico. Criar o cliente não é o mesmo que ter consentimento.
- O cliente tem um ecrã "Com quem partilho", com a lista de escritórios, o estado de cada um e o botão "Retirar acesso" com confirmação.
- Tabela de auditoria só de acrescentar, com a versão do texto de consentimento guardada.
- O admin vê 3 números: escritórios, mediadores e clientes.

**Cortar ou adiar:**
- **Autorregisto do cliente com escolha de escritórios:** adiar a UI para a feature em que o cliente inicia pedidos. Obriga a ter um diretório público de escritórios (que é uma questão de privacidade e de produto) e não faz falta na fase A, em que todos os clientes vêm do escritório do Henrique. O modelo de dados fica preparado já.
- 2FA, SMS, gestão avançada de equipa (papéis dentro do escritório, transferir mediadores entre escritórios) e escritórios criados pelo próprio mediador (na fase A só há um).
- Painel de admin para além das 3 contagens. O custo de IA e os pedidos entram quando existirem.
- Concessão por documento e encriptação por escritório (já decidido que ficam para o futuro).
- Texto de consentimento final: usar um texto provisório com versão (`v0-rascunho`) e substituí-lo pelo do jurista sem mexer no código.

**Riscos:**
- **Legal:**
  - O texto e a base de licitude ainda não foram validados (perguntas 1, 3 e 15 do briefing). O jurista pode dizer que a base para o escritório não é o consentimento mas o contrato ou as diligências pré-contratuais. Por isso, a concessão deve ser modelada como "acesso autorizado pelo cliente", com versão do texto, e não amarrada a uma única base legal.
  - O acesso de serviço do dono do projeto (service role) contorna o RLS. O registo desse acesso não é coberto por esta feature e tem de ficar escrito como medida em falta.
  - Com um só escritório, as contagens do admin quase identificam pessoas. É baixo risco na fase A, mas a regra de não mostrar dados pessoais deve aplicar-se também a agregados pequenos quando houver mais escritórios.
- **Confiança:**
  - O cliente recebe um link de uma marca que não conhece (ProDossier) e pode achar que é phishing. O email e o ecrã de aceitação têm de mostrar o nome do escritório e do mediador em destaque.
  - Falta decidir o que acontece aos dados que o mediador introduziu no perfil do cliente quando este retira o acesso. Se ficarem visíveis, a promessa "retiro e perdem o acesso" fica quebrada.
- **Suporte:**
  - O link mágico é a maior fonte provável de pedidos de ajuda: email no spam, link expirado, aberto noutro dispositivo. Mitigação: link reenviável pelo mediador e mensagem clara quando expira.
  - As palavras-passe de mediadores esquecidas ficam do lado do admin enquanto não houver recuperação testada.
  - O fornecedor de email ainda não foi escolhido e bloqueia a métrica 4.

**Veredicto:** **avançar mais pequeno.** A feature é obrigatória e o âmbito pedido está quase certo. Cortar o autorregisto do cliente e a gestão avançada de escritórios. Não cortar a concessão pendente até o cliente aceitar nem a auditoria só de acrescentar com versão do texto: são estas que sustentam o diferenciador e o parecer jurídico.
