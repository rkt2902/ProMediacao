import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/tokens.dart';
import '../core/design/typography.dart';
import '../core/widgets/widgets.dart';
import '../features/auth/presentation/session_colophon.dart';
import 'app_scope.dart';
import 'routes.dart';

/// MARCADORES TEMPORÁRIOS dos ecrãs da 002 (tarefa 3). As tarefas 4 e 5 põem
/// os ecrãs reais; o lead troca a ligação em `route_builders.dart`:
///
/// | Rota | Marcador | Ecrã real (tarefa) |
/// | --- | --- | --- |
/// | Novo pedido | [PendingScreen.newRequest] | `NewRequestPage` em `lib/features/mediator/presentation/new_request_page.dart` (4) |
/// | Ficha do cliente | [PendingScreen.clientFile] | `ClientFilePage` em `lib/features/mediator/presentation/client_file_page.dart` (4) |
/// | Pedido do mediador | [PendingScreen.mediatorRequest] | `MediatorRequestPage` em `lib/features/mediator/presentation/mediator_request_page.dart` (4) |
/// | Os meus pedidos | [PendingScreen.myRequests] | `MyRequestsPage` em `lib/features/client_requests/presentation/my_requests_page.dart` (5) |
/// | Pedido do cliente | [PendingScreen.clientRequest] | `ClientRequestPage` em `lib/features/client_requests/presentation/client_request_page.dart` (5) |
/// | Notificações | [PendingScreen.notifications] | `NotificationsPage` em `lib/features/notifications/presentation/notifications_page.dart` (5) |
class PendingScreen extends StatefulWidget {
  const PendingScreen._({
    required this.title,
    required this.forClient,
    this.backLabel,
    this.backTo,
    this.showSharingLink = false,
    this.takeNotice = false,
  });

  /// Novo pedido (mediador). [fromClientFile]: regresso à ficha.
  factory PendingScreen.newRequest({
    String? clientId,
    bool fromClientFile = false,
  }) => PendingScreen._(
    title: 'Novo pedido',
    forClient: false,
    backLabel: fromClientFile ? 'Cliente' : 'Clientes',
    backTo: fromClientFile && clientId != null
        ? AppRoutes.mediatorClient(clientId)
        : AppRoutes.mediator,
  );

  factory PendingScreen.clientFile(String clientId) => const PendingScreen._(
    title: 'Ficha do cliente',
    forClient: false,
    backLabel: 'Clientes',
    backTo: AppRoutes.mediator,
  );

  factory PendingScreen.mediatorRequest(String clientId, String requestId) =>
      PendingScreen._(
        title: 'Pedido',
        forClient: false,
        backLabel: 'Cliente',
        backTo: AppRoutes.mediatorClient(clientId),
      );

  /// Ecrã inicial do cliente.
  factory PendingScreen.myRequests() => const PendingScreen._(
    title: 'Os meus pedidos',
    forClient: true,
    showSharingLink: true,
    takeNotice: true,
  );

  factory PendingScreen.clientRequest(String requestId) =>
      const PendingScreen._(
        title: 'Pedido',
        forClient: true,
        backLabel: 'Os meus pedidos',
        backTo: AppRoutes.client,
      );

  factory PendingScreen.notifications() => const PendingScreen._(
    title: 'Notificações',
    forClient: true,
    backLabel: 'Os meus pedidos',
    backTo: AppRoutes.client,
  );

  final String title;
  final bool forClient;
  final String? backLabel;
  final String? backTo;
  final bool showSharingLink;

  /// Mostra o aviso que chega de outro ecrã (ex.: "Palavra-passe criada…"),
  /// como o ecrã inicial do cliente na 001.
  final bool takeNotice;

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  String? _notice;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    if (widget.takeNotice) _notice = AppScope.of(context).session.takeNotice();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final back = widget.backTo;
    return PageFrame(
      tabLabel: widget.forClient
          ? 'Os meus dados'
          : services.session.session?.officeName ?? '',
      maxWidth: AppSize.larguraLeitura,
      onSignOut: services.session.signOut,
      backLabel: widget.backLabel,
      onBack: back == null ? null : () => context.go(back),
      colophon: const SessionColophon(),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_notice != null) ...[
              InlineNotice(message: _notice!),
              const SizedBox(height: AppSpace.s24),
            ],
            Text(
              widget.title,
              style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
            ),
            if (widget.showSharingLink) ...[
              const SizedBox(height: AppSpace.s48),
              Align(
                alignment: Alignment.centerLeft,
                child: SecondaryButton(
                  label: 'Ver com quem partilho',
                  onPressed: () => context.go(AppRoutes.clientSharing),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
