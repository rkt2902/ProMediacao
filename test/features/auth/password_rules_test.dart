import 'package:flutter_test/flutter_test.dart';
import 'package:promediacao/features/auth/application/password_rules.dart';

void main() {
  group('regras da palavra-passe (cada uma isolada)', () {
    test('comprimento: 9 falha, 10 cumpre', () {
      expect(meetsRule(PasswordRule.length, 'Aa1!aaaaa'), isFalse);
      expect(meetsRule(PasswordRule.length, 'Aa1!aaaaaa'), isTrue);
    });

    test('maiúscula', () {
      expect(meetsRule(PasswordRule.upper, 'abc1!'), isFalse);
      expect(meetsRule(PasswordRule.upper, 'aBc1!'), isTrue);
    });

    test('minúscula', () {
      expect(meetsRule(PasswordRule.lower, 'ABC1!'), isFalse);
      expect(meetsRule(PasswordRule.lower, 'ABc1!'), isTrue);
    });

    test('número', () {
      expect(meetsRule(PasswordRule.digit, 'Abcdef!'), isFalse);
      expect(meetsRule(PasswordRule.digit, 'Abcdef!7'), isTrue);
    });

    test('carácter especial (símbolos do Supabase Auth)', () {
      expect(meetsRule(PasswordRule.special, 'Abcdef12'), isFalse);
      for (final c in ['!', '?', '#', '@', '-', '_', '.', '~']) {
        expect(meetsRule(PasswordRule.special, 'Abc1$c'), isTrue, reason: c);
      }
      // Espaço e letras acentuadas não contam como especial.
      expect(meetsRule(PasswordRule.special, 'Abc 1é'), isFalse);
    });
  });

  test('10 caracteres sem número falha; as 5 cumpridas passam', () {
    final noDigit = PasswordCheck('Abcdefghi!');
    expect(noDigit.ok, isFalse);
    expect(noDigit.missing, [PasswordRule.digit]);
    expect(PasswordCheck('Maria#2026').ok, isTrue);
  });

  test('vazio: falham as 5', () {
    expect(PasswordCheck('').missing.length, 5);
  });
}
