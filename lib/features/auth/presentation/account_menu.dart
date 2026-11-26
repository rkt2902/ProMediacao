import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_copy.dart';

/// Menu da conta no topo do `PageFrame` (03-design.md): nome opcional e
/// "Sair". Reutilizável pelos ecrãs das tarefas 5, 6 e 7.
class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key, this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (name != null) ...[
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
          label: AuthCopy.signOut,
          onPressed: services.session.signOut,
        ),
      ],
    );
  }
}
