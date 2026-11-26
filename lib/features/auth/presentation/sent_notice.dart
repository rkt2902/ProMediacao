import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';

/// Confirmação em fundo `realce` com o email em `corpoForte`
/// (03-design.md, ecrã 1). O `InlineNotice` só aceita texto simples.
class SentNotice extends StatelessWidget {
  const SentNotice({
    super.key,
    required this.before,
    this.emphasis,
    this.after = '',
    this.children = const [],
  });

  final String before;
  final String? emphasis;
  final String after;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.s16),
        decoration: const BoxDecoration(
          color: AppColors.realce,
          borderRadius: AppRadius.controloBorda,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.tinta),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppType.corpo,
                      children: [
                        TextSpan(text: before),
                        if (emphasis != null)
                          TextSpan(text: emphasis, style: AppType.corpoForte),
                        TextSpan(text: after),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
