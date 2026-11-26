// shared_preferences vem como dependência transitiva do supabase_flutter;
// falta declará-la no pubspec (ver handoff).
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Separadores do ecrã de entrada.
enum EntryTab { client, office }

/// Memória local do último separador usado. Qualquer falha de leitura ou
/// escrita é ignorada: a app funciona sem isto.
abstract interface class EntryTabStore {
  Future<EntryTab?> read();
  Future<void> write(EntryTab tab);
}

class SharedPrefsEntryTabStore implements EntryTabStore {
  static const _key = 'entry_tab';

  @override
  Future<EntryTab?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      for (final t in EntryTab.values) {
        if (t.name == v) return t;
      }
    } on Object {
      // sem armazenamento: usa o valor por defeito
    }
    return null;
  }

  @override
  Future<void> write(EntryTab tab) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, tab.name);
    } on Object {
      // ignorado de propósito
    }
  }
}

class MemoryEntryTabStore implements EntryTabStore {
  MemoryEntryTabStore([this.value]);
  EntryTab? value;

  @override
  Future<EntryTab?> read() async => value;

  @override
  Future<void> write(EntryTab tab) async => value = tab;
}
