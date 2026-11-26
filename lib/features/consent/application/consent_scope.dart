import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_consent_repository.dart';
import '../domain/consent_repository.dart';

/// Dá o [ConsentRepository] aos ecrãs do cliente. Os testes envolvem os
/// ecrãs com um fake; sem scope, usa o Supabase já inicializado em
/// `main.dart` (assim as rotas não precisam de saber deste repositório).
class ConsentScope extends InheritedWidget {
  const ConsentScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final ConsentRepository repository;

  static ConsentRepository? _fallback;

  static ConsentRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ConsentScope>();
    if (scope != null) return scope.repository;
    return _fallback ??= SupabaseConsentRepository(Supabase.instance.client);
  }

  @override
  bool updateShouldNotify(ConsentScope old) => repository != old.repository;
}

/// Passagem do consentimento para "Com quem partilho": a concessão acabada
/// de responder (confirmada pelo servidor) entra no seu grupo com o fundo
/// `realce` a desvanecer. Lido uma vez, como `session.takeNotice()`.
abstract final class ConsentHandoff {
  static String? _answeredGrantId;

  static void answered(String grantId) => _answeredGrantId = grantId;

  static String? take() {
    final id = _answeredGrantId;
    _answeredGrantId = null;
    return id;
  }
}
