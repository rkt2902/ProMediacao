# Renders da 001 Fundação (tarefa 4b)

Referências visuais de cada ecrã, **antes** da implementação das tarefas 5, 6 e 7. São HTML estático feito só com os tokens de `docs/design/DESIGN.md` e as fontes reais de `assets/fonts/`; o flutter-dev integra com os widgets de `lib/core/widgets/`, não copia o HTML.

- Tamanhos: telemóvel 390 × 844, tablet 768 × 1024, desktop 1280 × 800 (PNG a 2×). Os `-completo-` são a página inteira (o que se vê ao fazer scroll).
- Páginas em `src/` (um HTML por ecrã; o estado escolhe-se por parâmetro, ex.: `clientes.html?estado=offline` ou `?folha=criar`, tratado por `src/estado.js`). Os cortes 640 e 1100 são os mesmos da app.
- Gerar de novo: `node docs/features/001-fundacao/renders/src/shoot.js [nomes separados por vírgula, aceita prefixo*]` (serve a raiz do repositório por HTTP local; o Chromium bloqueia fontes em `file://`). Para abrir no navegador: `python3 -m http.server` na raiz e `http://localhost:8000/docs/features/001-fundacao/renders/src/entrar.html`.
- Ícones: subconjunto da fonte Material Icons do Flutter (`src/fonts/`, licença Apache 2.0), os mesmos `Icons.*` dos widgets.
- Dados fictícios: escritórios e pessoas das fixtures do `03-design.md`; emails em `exemplo.pt`.

## Índice

Todos os ecrãs em `-telemovel`, `-tablet` e `-desktop` (admin: `-telemovel` e `-desktop`), salvo indicação. `-completo-` = página inteira.

### Cabeçalho (revisão de 2026-11-26)
Sem marca nem linha de cabeçalho nos ecrãs com sessão: o separador é a primeira linha e "Sair" (com o nome, onde couber) fica à direita na mesma linha. Sem sessão, o separador diz "ProDossier". Todos os PNG foram regenerados com este cabeçalho.

### Entrar e palavra-passe
| Ficheiros | Estado |
| --- | --- |
| `entrar-*` | Populado: email + palavra-passe, "Esqueci-me", alternativa "Receber link de acesso por email" |
| `entrar-link-enviado-*` | Sucesso: link enviado, "Enviar outra vez" bloqueado com a razão |
| `entrar-erro-*` | Erro: "Email ou palavra-passe incorretos." + dica do link |
| `entrar-validacao-*` | Validação: email incompleto e palavra-passe vazia, erro por baixo de cada campo |
| `entrar-sem-rede-*` | Falha de rede: "Não foi possível ligar…" |
| `entrar-sessao-terminada-*` | Sem permissão / sessão terminada |
| `entrar-offline-*` | Offline: faixa a tinta, botões desativados com a razão |
| `recuperar-palavra-passe-*` | Recuperar: um campo, "Voltar a entrar" |
| `definir-palavra-passe-*` | Definir (recuperação ou convite de mediador), regras em tempo real |
| `criar-palavra-passe-*` | Cliente depois do link: regras em tempo real (3 de 5 cumpridas), "Agora não" |
| `criar-palavra-passe-cumprida-*` | Todas as regras cumpridas |
| `criar-palavra-passe-fraca-*` | Erro de palavra-passe fraca: campo a `erro`, regras em falta com ícone de erro |
| `criar-palavra-passe-erro-*` | Falha ao guardar |
| `criar-palavra-passe-offline-*` | Offline: "Guardar" desativado, "Agora não" ativo |
| `alterar-palavra-passe-*` | Alterar, a partir da conta, com "Cancelar" |
| `link-expirado-*`, `link-expirado-enviado-*` | Link expirado ou inválido; novo link enviado |

### Consentimento (cliente)
| Ficheiros | Estado |
| --- | --- |
| `consentimento-*`, `consentimento-completo-telemovel` | Populado: Recusar e Aceitar com o mesmo peso |
| `consentimento-a-carregar-*` | Skeleton com a forma final; barra já no sítio, desativada |
| `consentimento-erro-*` | Falha ao registar a resposta |
| `consentimento-offline-*` | Offline: botões desativados com "Precisa de ligação para responder." |
| `consentimento-aceite-*`, `consentimento-recusado-*` | Sucesso: resultado com carimbo, data e "Ver com quem partilho" |

### Com quem partilho (cliente)
| Ficheiros | Estado |
| --- | --- |
| `com-quem-partilho-*`, `com-quem-partilho-completo-telemovel` | Populado: pendente, com acesso, sem acesso, A sua conta |
| `com-quem-partilho-a-carregar-*` | Skeleton (nunca o bloco pendente em skeleton) |
| `com-quem-partilho-vazio-*` | Vazio |
| `com-quem-partilho-erro-*` | Lista não carregou, "Tentar de novo" |
| `com-quem-partilho-offline-*` | Offline: Responder e Retirar desativados |
| `conta-cliente-*` | Secção "A sua conta" com "Criar palavra-passe" |
| `palavra-passe-criada-*` | Sucesso: "Palavra-passe criada…" |
| `retirar-acesso-*` | Confirmação: folha inferior (telemóvel), diálogo 480 |
| `retirar-acesso-erro-*` | Falha ao retirar, dentro da folha |
| `acesso-retirado-*` | Sucesso: linha em "Sem acesso" com realce, aviso no topo |

### Clientes (mediador)
| Ficheiros | Estado |
| --- | --- |
| `clientes-*`, `clientes-completo-telemovel` | Populado: 4 / 3 colunas / lista empilhada |
| `clientes-vazio-*` | Vazio |
| `clientes-a-carregar-*` | Skeleton de 6 linhas com as colunas |
| `clientes-erro-*` | Lista não carregou |
| `clientes-offline-*` | Offline: Criar e Reenviar desativados, razão escrita |
| `criar-cliente-*` | Folha lateral (tablet, desktop) / ecrã inteiro (telemóvel) |
| `criar-cliente-validacao-*` | Nome vazio e email já cliente |
| `cliente-criado-*` | Sucesso: linha nova com realce e aviso |
| `pedido-reenviado-*` | Sucesso: reenvio confirmado, bloqueio até 15:05 |

### Admin (desktop e telemóvel)
| Ficheiros | Estado |
| --- | --- |
| `admin-*`, `admin-completo-telemovel` | Populado: contagens numa faixa, escritórios |
| `admin-a-carregar-*` | Blocos de 56 no lugar dos números (nunca "0" provisório) |
| `admin-vazio-*` | Contagens a 0, "Criar escritório" |
| `admin-erro-*` | Contagens não carregaram |
| `admin-offline-*` | Offline |
| `criar-escritorio-*`, `convidar-mediador-*` | Folha lateral / ecrã inteiro |
| `escritorio-criado-*` | Sucesso: linha nova com realce |

### Fluxos e transições
| Ficheiro | Fluxo |
| --- | --- |
| `fluxo-1-convite.png` | Convite por link → consentimento → criar palavra-passe → Com quem partilho |
| `fluxo-2-entrar.png` | Entrar com palavra-passe, erro, recuperar |
| `fluxo-3-link-expirado.png` | Link expirado → novo link |
| `fluxo-4-criar-cliente.png` | Mediador cria cliente → reenvia |
| `fluxo-5-retirar-acesso.png` | Retirar acesso |
| `fluxo-6-admin.png` | Admin cria escritório e convida mediador |
| `src/prototipo.html` | Protótipo navegável dos fluxos 1 e 5, com as transições, o voltar do navegador e reduzir movimento |

As setas dos storyboards dizem a ação e a transição (tipo, duração e curva de `AppMotion`); a especificação completa está em `03-design.md`, "Transições entre ecrãs".

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

Escala de texto 1.3 e 320 de largura (ficam para os goldens da tarefa 9).
