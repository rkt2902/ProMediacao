import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../design/typography.dart';

/// Estados de uma partilha.
enum StampStatus {
  ativo('ATIVO', 'ativo', Icons.check_circle_outline, AppColors.estadoAtivo),
  pendente('PENDENTE', 'pendente', Icons.schedule, AppColors.estadoPendente),
  recusado('RECUSADO', 'recusado', Icons.block, AppColors.estadoInativo),
  retirado('RETIRADO', 'retirado', Icons.undo, AppColors.estadoInativo),

  /// Pedido de um escritório a quem o cliente retirou o acesso (002).
  acessoRetirado(
    'ACESSO RETIRADO',
    'acesso retirado',
    Icons.undo,
    AppColors.estadoInativo,
  );

  const StampStatus(this.label, this.spoken, this.icon, this.color);

  /// Palavra no carimbo (maiúsculas).
  final String label;

  /// Palavra para leitura de ecrã.
  final String spoken;
  final IconData icon;
  final Color color;
}

/// Carimbo de estado: etiqueta retangular de canto quase reto, contorno de
/// 1.5 na cor do estado, fundo `folha`, ícone + palavra (nunca só cor).
class StatusStamp extends StatelessWidget {
  const StatusStamp({super.key, required this.status, this.semanticsDetail});

  final StampStatus status;

  /// Complemento para leitura de ecrã, ex.: "desde 12 de novembro de 2026".
  final String? semanticsDetail;

  @override
  Widget build(BuildContext context) {
    final spoken = semanticsDetail == null
        ? 'Estado: ${status.spoken}'
        : 'Estado: ${status.spoken} ${semanticsDetail!}';
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: AppMotion.resolve(context, AppMotion.base),
        switchInCurve: AppMotion.mudar,
        switchOutCurve: AppMotion.mudar,
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [...previous, ?current],
        ),
        child: _Stamp(key: ValueKey(status), status: status),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({super.key, required this.status});

  final StampStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s8,
        vertical: AppSpace.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.folha,
        borderRadius: AppRadius.carimboBorda,
        border: Border.all(color: status.color, width: AppStroke.controlo),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: AppSize.iconePequeno, color: status.color),
          const SizedBox(width: AppSpace.s4),
          Text(
            status.label,
            style: AppType.carimbo.copyWith(color: status.color),
          ),
        ],
      ),
    );
  }
}
