/// Regras da palavra-passe (03-design.md, 1d; decisão de 2026-11-26): pelo
/// menos 10 caracteres, uma maiúscula, uma minúscula, um número e um carácter
/// especial. Iguais para todos os perfis e iguais às do Supabase Auth
/// (conjuntos ASCII: o Auth só conta essas letras e estes símbolos).
enum PasswordRule { length, upper, lower, digit, special }

const int minPasswordLength = 10;

/// Símbolos aceites pelo Supabase Auth como "carácter especial".
const String passwordSymbols = r'''!@#$%^&*()_+-=[]{};'\:"|<>?,./`~''';

final RegExp _upper = RegExp('[A-Z]');
final RegExp _lower = RegExp('[a-z]');
final RegExp _digit = RegExp('[0-9]');

/// `true` se [password] cumpre [rule]. Cada regra é testável isoladamente.
bool meetsRule(PasswordRule rule, String password) => switch (rule) {
  PasswordRule.length => password.runes.length >= minPasswordLength,
  PasswordRule.upper => _upper.hasMatch(password),
  PasswordRule.lower => _lower.hasMatch(password),
  PasswordRule.digit => _digit.hasMatch(password),
  PasswordRule.special => password.split('').any(passwordSymbols.contains),
};

/// Resultado das 5 regras para uma palavra-passe.
class PasswordCheck {
  PasswordCheck(String password)
    : met = {
        for (final r in PasswordRule.values)
          if (meetsRule(r, password)) r,
      };

  final Set<PasswordRule> met;

  List<PasswordRule> get missing =>
      PasswordRule.values.where((r) => !met.contains(r)).toList();

  bool get ok => met.length == PasswordRule.values.length;
}
