# Renders da 001 Fundação (tarefa 4b)

Referências visuais de cada ecrã, **antes** da implementação das tarefas 5, 6 e 7. São HTML estático feito só com os tokens de `docs/design/DESIGN.md` e as fontes reais de `assets/fonts/`; o flutter-dev integra com os widgets de `lib/core/widgets/`, não copia o HTML.

- Tamanhos: telemóvel 390 × 844, tablet 768 × 1024, desktop 1280 × 800 (PNG a 2×). Os `-completo-` são a página inteira (o que se vê ao fazer scroll).
- Páginas em `src/` (um HTML por ecrã; o estado escolhe-se por parâmetro, ex.: `clientes.html?folha=criar`). Os cortes 640 e 1100 são os mesmos da app.
- Gerar de novo: `node docs/features/001-fundacao/renders/src/shoot.js [prefixo]` (serve a raiz do repositório por HTTP local; o Chromium bloqueia fontes em `file://`). Para abrir no navegador: `python3 -m http.server` na raiz e `http://localhost:8000/docs/features/001-fundacao/renders/src/entrar.html`.
- Ícones: subconjunto da fonte Material Icons do Flutter (`src/fonts/`, licença Apache 2.0), os mesmos `Icons.*` dos widgets.
- Dados fictícios: escritórios e pessoas das fixtures do `03-design.md`; emails em `exemplo.pt`.

## Índice

| Ecrã | Ficheiros | O que mostra |
| --- | --- | --- |
| Entrar (todos os perfis) | `entrar-{telemovel,tablet,desktop}.png` | Separador fixo "Acesso", email + palavra-passe, "Entrar" 56, "Esqueci-me da palavra-passe", régua e alternativa "Receber link de acesso por email" (contorno, 56) |
| Entrar, depois de pedir o link | `entrar-link-enviado-{telemovel,tablet,desktop}.png` | Confirmação (`realce`), "Enviar outra vez" bloqueado com a razão, "Usar outro email", "Entrar com palavra-passe" |
| Criar palavra-passe (cliente) | `criar-palavra-passe-{telemovel,tablet,desktop}.png` | Depois da entrada por link: email só de leitura, campo com "Mostrar", regra cumprida, "Guardar palavra-passe" e "Agora não" com o mesmo tamanho |
| A sua conta (cliente) | `conta-cliente-{telemovel,tablet,desktop}.png` | Fim de "Com quem partilho": email e "Palavra-passe: Ainda não criou" com "Criar palavra-passe" |
| Recuperar palavra-passe | `recuperar-palavra-passe-{telemovel,tablet,desktop}.png` | Separador fixo "Acesso" (todos os perfis), um campo, "Voltar a entrar" |
| Link expirado | `link-expirado-{telemovel,tablet,desktop}.png` | Separador "Acesso", explicação, campo de email, "Enviar link novo", "Já tem palavra-passe? Entrar com ela", alternativa pelo mediador |
| Link expirado, depois de enviar | `link-expirado-enviado-{telemovel,tablet,desktop}.png` | Confirmação (`realce`), "Enviar outra vez" bloqueado com a razão escrita, "Usar outro email" |
| Consentimento | `consentimento-{telemovel,tablet,desktop}.png`, `consentimento-completo-telemovel.png` | Quem pede, resumo em 3 réguas, texto v0-rascunho, barra fixa Recusar/Aceitar com o mesmo peso |
| Com quem partilho | `com-quem-partilho-{telemovel,tablet,desktop}.png`, `com-quem-partilho-completo-telemovel.png` | Bloco pendente (nome longo), 1 ativo com "Retirar acesso" e "Ler o texto aceite", 1 retirado e 1 recusado sem ações |
| Retirar acesso (confirmação) | `retirar-acesso-{telemovel,tablet,desktop}.png` | Folha inferior no telemóvel (destrutivo em cima); diálogo de 480 em tablet e desktop, "Cancelar" à esquerda com anel de foco |
| Clientes | `clientes-{telemovel,tablet,desktop}.png`, `clientes-completo-telemovel.png` | Ativo, Pendente, Recusado (sem ação), nome e email longos, um reenvio bloqueado 60 s; 4 colunas / 3 colunas / lista empilhada |
| Clientes, vazio | `clientes-vazio-{telemovel,tablet,desktop}.png` | "Ainda não tem clientes" e um só "Criar cliente" |
| Criar cliente | `criar-cliente-{telemovel,tablet,desktop}.png` | Folha lateral de 440 com barra fixa (tablet, desktop); ecrã inteiro com botões no fluxo (telemóvel) |
| Painel do admin | `admin-{telemovel,desktop}.png`, `admin-completo-telemovel.png` | 3 contagens numa faixa com réguas (não cartões), nota de privacidade, escritórios com "Convidar mediador" |

## Decisões para o Henrique olhar

0a. **Ritmo vertical (2026-11-26, pedido do Henrique):** o separador de pasta cola-se à linha do topo (`s16` em cima, 48 de altura, 0 em baixo) em todos os ecrãs; sai o vazio extra de 32 / 48 / 72 acima dos formulários; "Sem acesso" passa a `s32` de "Com acesso". Todos os PNG regenerados.
0. **Revisão de 2026-11-26 (palavra-passe do cliente):** Entrar deixou de ter os separadores "Sou cliente" / "Trabalho num escritório" e passou a um só formulário com a alternativa por link; justificação no `03-design.md`, ecrã 1.
1. **Régua do separador à largura da moldura.** Assumida (recomendação aceite por omissão a 2026-11-26): o `PageFrame` do código tem de a desenhar à largura da moldura, não da coluna.
2. **Formulários de entrada à esquerda da moldura em desktop.** Assumida a 2026-11-26: o `AuthLayout` deixa de deslocar a coluna para 1/3 da janela.
3. **Consentimento: "Recusar" e "Aceitar" com a mesma largura e a mesma altura**, contorno contra cheio. O "não" não é um link. Ver se o contraste de peso entre contorno e cheio ainda parece "empurrar" para o sim.
4. **Bloco pendente em `realce`** é a única superfície de cor no ecrã do cliente, para ser a primeira coisa vista.
5. **Coluna Data passou de 200 para 248** (`AppSize.colunaData`, alterado no DESIGN.md): "Recusado a 20 nov 2026, 09:12" em mono 13 mede 238 e partia em 2 linhas.
6. **Reenvio bloqueado:** a célula mostra "Reenviar pedido" desativado + "Pode reenviar às 15:05"; tirei o "Enviado às 15:04" porque a coluna Data já mostra a hora do envio (03-design atualizado).
7. **"A sua resposta fica registada com data e hora."** passou de mono (`registo`) a `corpoPequeno` `tintaMedia`: é uma frase, não uma data, e em mono partia em 2 linhas no telemóvel (03-design atualizado).
8. **Clientes vazio:** o botão "Criar cliente" do cabeçalho desaparece e fica só o do estado vazio (uma ação principal por ecrã).
9. **Admin:** dados fictícios com 3 escritórios (um com o nome longo e outro "Sem mediadores"), por isso as contagens são 3 / 4 / 12 e não 1 / 3 / 12 como nas fixtures.

## Não incluído

Definir palavra-passe (recuperação), Alterar palavra-passe, erro de credenciais com a dica do link, a validar (skeleton), offline, erros, "Ler o texto aceite", resultado depois de aceitar/recusar, criar escritório e convidar mediador, escala de texto 1.3 e 320 de largura. Estes ficam para os goldens da tarefa 9 ou para uma segunda volta, se o Henrique os quiser ver antes.
