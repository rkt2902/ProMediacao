import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'app_pressable.dart';

/// Régua de largura total (1 de espessura, `regua`).
class AppRule extends StatelessWidget {
  const AppRule({super.key, this.vertical = false, this.strong = false});

  final bool vertical;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = strong ? AppColors.reguaForte : AppColors.regua;
    return vertical
        ? Container(width: AppStroke.fino, color: color)
        : Container(height: AppStroke.fino, color: color);
  }
}

/// Separador de pasta colado ao topo da área de conteúdo: diz em nome de
/// quem se está a ver. Nunca leva reticências: se a linha não cabe, o texto
/// passa a duas linhas e a altura cresce. `cartolina`, cantos superiores arredondados.
/// Por baixo, uma régua de largura total (a "pasta" é o ecrã); com
/// [showRule] a `false` é só o separador (o `PageFrame` desenha a régua à
/// largura da moldura).
class FolderTab extends StatelessWidget {
  const FolderTab({super.key, required this.label, this.showRule = true});

  final String label;
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    final tab = Semantics(
      container: true,
      header: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSize.separadorAltura),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s4,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cartolina,
          borderRadius: AppRadius.separadorBorda,
        ),
        child: Center(
          widthFactor: 1,
          child: Text(label, style: AppType.rotulo),
        ),
      ),
    );
    if (!showRule) return tab;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: tab),
        const AppRule(),
      ],
    );
  }
}

/// Um separador escolhível de [FolderTabs].
class FolderTabItem {
  const FolderTabItem({required this.label});
  final String label;
}

/// Dois ou mais separadores escolhíveis, 50/50 (repartidos por igual), com
/// alvo de 48. Ativo em `cartolina`; inativos em `papel` com contorno
/// `regua` e texto `tintaMedia`. Régua de largura total por baixo.
class FolderTabs extends StatelessWidget {
  const FolderTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(items.length >= 2);

  final List<FolderTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.resolve(context, AppMotion.rapido);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: AppPressable(
                    selected: i == selectedIndex,
                    borderRadius: AppRadius.separadorBorda,
                    onPressed: () => onChanged(i),
                    builder: (context, s) {
                      final selected = i == selectedIndex;
                      return AnimatedContainer(
                        duration: dur,
                        curve: AppMotion.mudar,
                        constraints: const BoxConstraints(
                          minHeight: AppSize.alvoMinimo,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s12,
                          vertical: AppSpace.s8,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.cartolina
                              : (s.hovered
                                    ? AppColors.realce
                                    : AppColors.papel),
                          borderRadius: AppRadius.separadorBorda,
                          border: selected
                              ? null
                              : Border.all(
                                  color: AppColors.regua,
                                  width: AppStroke.fino,
                                ),
                        ),
                        child: Text(
                          items[i].label,
                          textAlign: TextAlign.center,
                          style: AppType.rotulo.copyWith(
                            color: selected
                                ? AppColors.tinta
                                : AppColors.tintaMedia,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const AppRule(),
      ],
    );
  }
}
