import '../presentation/auth_copy.dart';

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// `null` se o email estiver bem escrito.
String? validateEmail(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return AuthCopy.emailEmpty;
  if (!_email.hasMatch(v)) return AuthCopy.emailInvalid;
  return null;
}
