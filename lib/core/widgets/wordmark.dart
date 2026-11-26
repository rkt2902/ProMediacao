import 'package:material_ui/material_ui.dart';

import '../design/typography.dart';

/// Wordmark "ProDossier" (`AppType.marca`): "Pro" em itálico 400
/// `tintaMedia` e "Dossier" em 600 `tinta`. Lê-se "ProDossier", numa palavra.
/// Só aparece no colofão (DESIGN.md, "Colofão").
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  static const String name = 'ProDossier';

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Pro', style: AppType.marcaPro),
          TextSpan(text: 'Dossier', style: AppType.marca),
        ],
      ),
      semanticsLabel: name,
      maxLines: 1,
      softWrap: false,
    );
  }
}
