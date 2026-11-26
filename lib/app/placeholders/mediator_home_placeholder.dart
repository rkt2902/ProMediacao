import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/widgets/widgets.dart';
import '../../features/auth/presentation/session_colophon.dart';
import '../app_scope.dart';

/// MARCADOR TEMPORÁRIO: "Clientes" é da tarefa 6. Só serve para a rota por
/// papel existir, já com a moldura (escritório no separador, nome + "Sair")
/// e o colofão do mediador.
class MediatorHomePlaceholder extends StatelessWidget {
  const MediatorHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => PageFrame(
        tabLabel: session.session?.officeName ?? 'Escritório',
        accountName: accountNameFor(session.session),
        onSignOut: session.signOut,
        colophon: const SessionColophon(),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpace.s32),
          child: Text(
            'Clientes',
            style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
          ),
        ),
      ),
    );
  }
}
