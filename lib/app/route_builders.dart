import 'package:material_ui/material_ui.dart';

import '../features/admin/presentation/admin_home_page.dart';
import '../features/consent/presentation/client_home_page.dart';
import '../features/consent/presentation/consent_page.dart';
import '../features/mediator/presentation/mediator_home_page.dart';
import 'pending_screens.dart';

/// Como se chegou ao Novo pedido.
class NewRequestArgs {
  const NewRequestArgs({this.clientId, this.fromClientFile = false});

  /// Cliente já escolhido (da ficha ou da linha de Clientes); nulo = começa
  /// pela escolha.
  final String? clientId;

  /// Veio da ficha: o regresso é o nome do cliente e volta à ficha; senão é
  /// "Clientes".
  final bool fromClientFile;
}

/// Ecrãs por papel (podem ser trocados nos testes).
class RouteBuilders {
  const RouteBuilders({
    this.adminHome = _admin,
    this.mediatorHome = _mediator,
    this.clientHome = _client,
    this.consent = _consent,
    this.clientSharing = _sharing,
    this.newRequest = _newRequest,
    this.clientFile = _clientFile,
    this.mediatorRequest = _mediatorRequest,
    this.clientRequest = _clientRequest,
    this.notifications = _notifications,
  });

  final WidgetBuilder adminHome;
  final WidgetBuilder mediatorHome;

  /// Ecrã inicial do cliente (`/cliente`): "Os meus pedidos" desde a 002.
  final WidgetBuilder clientHome;
  final Widget Function(BuildContext context, String grantId) consent;

  /// "Com quem partilho" (`/cliente/partilhas`).
  final WidgetBuilder clientSharing;

  final Widget Function(BuildContext context, NewRequestArgs args) newRequest;
  final Widget Function(BuildContext context, String clientId) clientFile;
  final Widget Function(BuildContext context, String clientId, String requestId)
  mediatorRequest;
  final Widget Function(BuildContext context, String requestId) clientRequest;
  final WidgetBuilder notifications;

  static Widget _admin(BuildContext c) => const AdminHomePage();
  static Widget _mediator(BuildContext c) => const MediatorHomePage();
  static Widget _consent(BuildContext c, String id) => ConsentPage(grantId: id);
  static Widget _sharing(BuildContext c) => const ClientHomePage();

  // Marcadores até às tarefas 4 e 5 (ver `pending_screens.dart`).
  static Widget _client(BuildContext c) => PendingScreen.myRequests();
  static Widget _newRequest(BuildContext c, NewRequestArgs a) =>
      PendingScreen.newRequest(
        clientId: a.clientId,
        fromClientFile: a.fromClientFile,
      );
  static Widget _clientFile(BuildContext c, String clientId) =>
      PendingScreen.clientFile(clientId);
  static Widget _mediatorRequest(BuildContext c, String cid, String rid) =>
      PendingScreen.mediatorRequest(cid, rid);
  static Widget _clientRequest(BuildContext c, String id) =>
      PendingScreen.clientRequest(id);
  static Widget _notifications(BuildContext c) => PendingScreen.notifications();
}
