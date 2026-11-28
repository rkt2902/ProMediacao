import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import '../design/typography.dart';

/// Etiqueta neutra (002): contorno `reguaForte` 1, texto `rotulo` em
/// `tintaMedia`, sem maiúsculas nem fundo, para distinguir de um carimbo.
/// Ex.: "Condições particulares", "Origem: mediador". O texto é lido tal e
/// qual (uma só vez).
class TagLabel extends StatelessWidget {
  const TagLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.carimboBorda,
        border: Border.all(color: AppColors.reguaForte, width: AppStroke.fino),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
        child: Text(
          label,
          style: AppType.rotulo.copyWith(color: AppColors.tintaMedia),
        ),
      ),
    );
  }
}
