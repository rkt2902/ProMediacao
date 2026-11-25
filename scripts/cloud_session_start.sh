#!/bin/bash
# Hook SessionStart: prepara o projeto Flutter nas sessões cloud do Claude Code.
# Localmente (CLAUDE_CODE_REMOTE diferente de "true") sai logo e não faz nada.

if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter não encontrado nesta sessão cloud: confirma o setup script do ambiente." >&2
  exit 0
fi

# flutter pub get só quando as dependências mudaram desde a última vez
if [ ! -f .dart_tool/package_config.json ] \
  || [ pubspec.yaml -nt .dart_tool/package_config.json ] \
  || { [ -f pubspec.lock ] && [ pubspec.lock -nt .dart_tool/package_config.json ]; }; then
  flutter pub get >/dev/null 2>&1 || echo "flutter pub get falhou" >&2
fi

exit 0
