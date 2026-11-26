import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/widgets.dart';
import '../../features/auth/presentation/account_menu.dart';

/// MARCADOR TEMPORÁRIO: o ecrã inicial de "admin" é substituído pela sua
/// tarefa (ver 04-plan.md). Só serve para a rota por papel existir.
class AdminHomePlaceholder extends StatelessWidget {
  const AdminHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      tabLabel: 'Administração',
      trailing: const AccountMenu(),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: Text(
          'Painel do administrador',
          style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
        ),
      ),
    );
  }
}
