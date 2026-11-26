// shared_preferences vem como dependência transitiva do supabase_flutter.
import 'package:shared_preferences/shared_preferences.dart';

/// Lembra-se, neste navegador, de que o cliente carregou "Agora não" no
/// convite para criar palavra-passe, por entrada por link ([key] identifica
/// a entrada). Assim o convite volta no máximo na entrada seguinte por link.
/// Qualquer falha de leitura ou escrita é ignorada.
abstract interface class PasswordPromptStore {
  Future<bool> isDismissed(String key);
  Future<void> dismiss(String key);
}

class SharedPrefsPasswordPromptStore implements PasswordPromptStore {
  static const _key = 'password_prompt_dismissed';

  @override
  Future<bool> isDismissed(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) == key;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> dismiss(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, key);
    } on Object {
      // ignorado de propósito
    }
  }
}

class MemoryPasswordPromptStore implements PasswordPromptStore {
  String? value;

  @override
  Future<bool> isDismissed(String key) async => value == key;

  @override
  Future<void> dismiss(String key) async => value = key;
}
