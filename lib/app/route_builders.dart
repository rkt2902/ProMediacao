import 'package:material_ui/material_ui.dart';

import 'placeholders/admin_home_placeholder.dart';
import 'placeholders/client_home_placeholder.dart';
import 'placeholders/consent_placeholder.dart';
import 'placeholders/mediator_home_placeholder.dart';

/// Ecrãs por papel. Cada tarefa (5, 6, 7) troca o seu marcador por o ecrã
/// real mudando só a linha correspondente aqui.
class RouteBuilders {
  const RouteBuilders({
    this.adminHome = _admin,
    this.mediatorHome = _mediator,
    this.clientHome = _client,
    this.consent = _consent,
  });

  final WidgetBuilder adminHome;
  final WidgetBuilder mediatorHome;
  final WidgetBuilder clientHome;
  final Widget Function(BuildContext context, String grantId) consent;

  static Widget _admin(BuildContext c) => const AdminHomePlaceholder();
  static Widget _mediator(BuildContext c) => const MediatorHomePlaceholder();
  static Widget _client(BuildContext c) => const ClientHomePlaceholder();
  static Widget _consent(BuildContext c, String id) =>
      ConsentPlaceholder(grantId: id);
}
