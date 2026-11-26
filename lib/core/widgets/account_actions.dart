import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_buttons.dart';

/// Conta no topo do `PageFrame`, por tamanho (03-design.md):
/// compacto só "Sair" (o nome fica na leitura de ecrã); médio e largo o nome
/// numa linha com reticências, `s16` e "Sair".
class AccountActions extends StatelessWidget {
  const AccountActions({
    super.key,
    required this.onSignOut,
    this.name,
    this.signOutLabel = 'Sair',
  });

  final VoidCallback? onSignOut;

  /// Nome da pessoa (só mediador e admin; o cliente não passa nome).
  final String? name;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromContext(context) == Breakpoint.compacto;
    final showName = name != null && !compact;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showName) ...[
          Flexible(
            child: Text(
              name!,
              style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpace.s16),
        ],
        TextAction(
          label: signOutLabel,
          icon: Icons.logout,
          semanticsLabel: name == null
              ? null
              : '$signOutLabel da conta de $name',
          onPressed: onSignOut,
        ),
      ],
    );
  }
}
