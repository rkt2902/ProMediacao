import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';

/// Faixa a `tinta` no topo, com a razão de estarmos sem ligação. Desliza e
/// empurra o conteúdo ao entrar (`base` / `entrar`), sai com `base` / `sair`.
class OfflineBar extends StatelessWidget {
  const OfflineBar({
    super.key,
    required this.visible,
    this.message =
        'Sem ligação à internet. Pode ver o que está no ecrã; as alterações '
        'ficam bloqueadas até a ligação voltar.',
  });

  final bool visible;
  final String message;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.resolve(context, AppMotion.base);
    return AnimatedSize(
      duration: dur,
      curve: visible ? AppMotion.entrar : AppMotion.sair,
      alignment: Alignment.topCenter,
      child: visible
          ? Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                width: double.infinity,
                color: AppColors.tinta,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s16,
                  vertical: AppSpace.s12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: AppSize.icone,
                      color: AppColors.sobreTinta,
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Text(
                        message,
                        style: AppType.corpoPequeno.copyWith(
                          color: AppColors.sobreTinta,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
