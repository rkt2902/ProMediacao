#!/bin/bash
# Setup script do ambiente cloud do Claude Code: instala o Flutter.
# Cola isto em claude.ai/code, no teu ambiente, campo "Setup script".
# Corre como root em Ubuntu 24.04 antes de o Claude Code arrancar.
# Tem de acabar em menos de ~5 minutos para o ambiente ficar em cache.

# Troca "stable" pela versão que usas no PC (vê com: flutter --version),
# por exemplo 3.27.4, para o analyzer e os testes darem os mesmos resultados.
FLUTTER_VERSION="stable"
FLUTTER_DIR=/opt/flutter

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR" || exit 0
fi

git config --global --add safe.directory "$FLUTTER_DIR" || true
ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter
ln -sf "$FLUTTER_DIR/bin/dart" /usr/local/bin/dart

flutter config --no-analytics >/dev/null 2>&1 || true

# Descarrega o Dart SDK e os artefactos usados pelo flutter test.
flutter --version || true
flutter precache --no-android --no-ios >/dev/null 2>&1 || true

exit 0
