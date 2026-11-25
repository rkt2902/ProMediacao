# Correr a equipa de agentes na cloud (claude.ai/code)

As sessões cloud clonam o repo, por isso os agentes, as skills, o CLAUDE.md, o `.mcp.json` e o `.claude/settings.json` vêm com o clone. O que não está no repo configura-se uma vez no ambiente cloud.

## 1. Ambiente cloud (uma vez)

Em claude.ai/code, abre o teu ambiente para editar:

1. **Network access:** deixa em **Trusted**. Já inclui github.com, storage.googleapis.com (Flutter e Dart SDK) e pub.dev.
2. **Setup script:** cola o conteúdo de `docs/cloud/setup-flutter.sh`. Antes, troca `FLUTTER_VERSION="stable"` pela versão que tens no PC (`flutter --version`).
3. **Network secret do Supabase** (depois de existir o projeto Supabase e o `.mcp.json`, criado a partir de `docs/cloud/supabase.mcp.json` com o project ref): em Network secrets, Add secret:
   - Name: `Supabase MCP`
   - Allowed websites: `mcp.supabase.com`
   - Custom headers: `Authorization`, prefixo `Bearer`, valor = um personal access token do Supabase (Dashboard > Account > Access Tokens)
   - No plano Team sem papel de admin o formulário é mais curto: Host `mcp.supabase.com`, tipo Token.
4. Não ponhas tokens em Environment variables: quem usa o ambiente consegue lê-las.

## 2. Primeira sessão: teste rápido

Abre uma sessão no repo e pede:

> Corre `flutter --version`, `flutter analyze` e `flutter test`. Depois usa o MCP do Supabase para listar as tabelas do schema public. Diz-me o que falhou.

Se o Supabase não aparecer, há duas alternativas:
- Ativar o conector do Supabase do claude.ai na sessão, se o tiveres (confirma que fica só em leitura).
- Ficar sem acesso ao live na cloud: no gate 3, o QA dá-te as queries de verificação e tu corres no SQL Editor.

## 3. Dia a dia

- Abres uma sessão em claude.ai/code ou na app do Claude, e escreves `/feature <ideia>` ou `/ideias`.
- Respondes aos gates a partir do telemóvel.
- Gate 3: aplicas o SQL no SQL Editor do Supabase (também dá no telemóvel).
- Gate 4: o lead abre um PR; tu fazes merge.

## 4. Diferenças em relação ao PC

- **Plugins não são instalados na cloud.** O plugin oficial de Flutter (skills + Dart MCP) só existe no PC. Na cloud os agentes usam `flutter analyze` e `flutter test` pela linha de comandos.
- **Sem language servers** (navegação por símbolos) na cloud.
- **Recursos:** cerca de 4 vCPUs e 16 GB de RAM. Comandos esperam 2 minutos por defeito e até 10 minutos. Se o `flutter test` for longo, adiciona `BASH_DEFAULT_TIMEOUT_MS=600000` às variáveis do ambiente.
- **Goldens:** os renders mudam entre Linux e Windows. Os goldens do designer ficam em `test/design_review/`, fora dos testes de regressão.
- **Testar no telemóvel** continua a precisar de um build feito a partir do branch.
- **Ficheiros fora do repo** (por exemplo um `.env` local) não existem na cloud. Se os testes precisarem deles, usa valores de teste.
