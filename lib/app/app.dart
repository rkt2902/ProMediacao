import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/app_theme.dart';
import 'app_scope.dart';
import 'route_builders.dart';
import 'router.dart';

/// Raiz da app: tema, serviços e router por papel.
class ProMediacaoApp extends StatefulWidget {
  const ProMediacaoApp({
    super.key,
    required this.services,
    this.builders = const RouteBuilders(),
    this.initialLocation,
  });

  final AppServices services;
  final RouteBuilders builders;
  final String? initialLocation;

  @override
  State<ProMediacaoApp> createState() => _ProMediacaoAppState();
}

class _ProMediacaoAppState extends State<ProMediacaoApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(
      widget.services.session,
      builders: widget.builders,
      initialLocation: widget.initialLocation,
    );
    widget.services.session.start();
  }

  @override
  void dispose() {
    _router.dispose();
    widget.services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      child: MaterialApp.router(
        title: 'ProDossier',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
