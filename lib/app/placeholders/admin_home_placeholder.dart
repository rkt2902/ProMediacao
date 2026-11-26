import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/widgets.dart';
import '../app_scope.dart';

/// MARCADOR TEMPORÁRIO: o painel do admin é da tarefa 7. Só serve para a
/// rota por papel existir, já com a moldura e o colofão finais.
class AdminHomePlaceholder extends StatelessWidget {
  const AdminHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      tabLabel: 'Administração',
      onSignOut: AppScope.of(context).session.signOut,
      colophon: const Colophon(identity: Colophon.adminLine),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: Text(
          'Plataforma',
          style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
        ),
      ),
    );
  }
}
