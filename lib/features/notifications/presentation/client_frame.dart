import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/session_colophon.dart';
import 'notifications_panel.dart';

/// Moldura dos ecrãs do cliente (002): `PageFrame` com o separador "Os meus
/// dados", o sino de notificações antes de "Sair" (contador do servidor, só
/// o último conhecido), a faixa offline e o colofão.
///
/// O sino abre o painel lateral em médio/largo e o ecrã inteiro
/// [AppRoutes.clientNotifications] em compacto. Com o painel (ou o ecrã)
/// aberto fica com o fundo `cartolina`.
class ClientFrame extends StatefulWidget {
  const ClientFrame({
    super.key,
    required this.child,
    this.backLabel,
    this.backTo,
    this.colophon = true,
    this.notificationsScreen = false,
    this.maxWidth = AppSize.larguraLeitura,
  });

  final Widget child;

  /// Ligação de regresso por cima do separador (ex.: "Os meus pedidos").
  final String? backLabel;
  final String? backTo;
  final bool colophon;

  /// Este é o ecrã de notificações: o sino aparece aberto e fecha-o.
  final bool notificationsScreen;
  final double maxWidth;

  @override
  State<ClientFrame> createState() => _ClientFrameState();
}

class _ClientFrameState extends State<ClientFrame> {
  bool _panelOpen = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Contador do sino: lê o servidor ao entrar em cada ecrã do cliente.
    AppScope.of(context).notifications.refreshCount();
  }

  Future<void> _bell() async {
    if (widget.notificationsScreen) {
      context.go(widget.backTo ?? AppRoutes.client);
      return;
    }
    if (AppBreakpoints.fromContext(context) == Breakpoint.compacto) {
      context.go(AppRoutes.clientNotifications);
      return;
    }
    if (_panelOpen) return;
    setState(() => _panelOpen = true);
    await showNotificationsPanel(context);
    if (mounted) setState(() => _panelOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final back = widget.backTo;
    return ListenableBuilder(
      listenable: Listenable.merge([
        services.connectivity,
        services.notifications,
      ]),
      builder: (context, _) => PageFrame(
        tabLabel: 'Os meus dados',
        maxWidth: widget.maxWidth,
        onSignOut: services.session.signOut,
        onNotifications: _bell,
        unreadNotifications: services.notifications.unread,
        notificationsOpen: _panelOpen || widget.notificationsScreen,
        backLabel: widget.backLabel,
        onBack: back == null ? null : () => context.go(back),
        banner: OfflineBar(visible: !services.connectivity.online),
        colophon: widget.colophon ? const SessionColophon() : null,
        child: widget.child,
      ),
    );
  }
}
