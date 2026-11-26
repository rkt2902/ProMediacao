import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/widgets.dart';
import '../../features/auth/presentation/account_menu.dart';

/// MARCADOR TEMPORÁRIO: o ecrã de consentimento é da tarefa 5.
class ConsentPlaceholder extends StatelessWidget {
  const ConsentPlaceholder({super.key, required this.grantId});

  final String grantId;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      tabLabel: 'Pedido de acesso',
      trailing: const AccountMenu(),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s32),
        child: Text(
          'Pedido de acesso',
          style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
        ),
      ),
    );
  }
}
