import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../core/format/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_models.dart';

/// Colofão do perfil com sessão (03-design.md, "Colofão"): lê a sessão e
/// escreve a linha de identidade e o registo só quando há dados. Enquanto o
/// perfil não chega, só o wordmark. Reutilizável pelas tarefas 5, 6 e 7.
class SessionColophon extends StatelessWidget {
  const SessionColophon({super.key});

  /// Linha de identidade e registo para [s] (nulos se não houver dados).
  static (String?, String?) linesFor(AppSession? s) {
    if (s == null) return (Colophon.signedOutLine, null);
    switch (s.role) {
      case AppRole.admin:
        return (Colophon.adminLine, null);
      case AppRole.cliente:
        return (
          s.fullName == null ? null : 'Dossiê de ${s.fullName}',
          s.createdAt == null
              ? null
              : 'Aberto a ${AppDates.date(s.createdAt!)}',
        );
      case AppRole.mediador:
        final name = s.fullName;
        final office = s.officeName;
        return (
          name == null ? null : (office == null ? name : '$name, $office'),
          s.officeJoinedAt == null
              ? null
              : 'Na equipa desde ${AppDates.date(s.officeJoinedAt!)}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final (identity, record) = linesFor(session.session);
        return Colophon(identity: identity, record: record);
      },
    );
  }
}

/// Nome na linha do separador: só o mediador (o cliente sabe quem é; o
/// admin não tem nome visível).
String? accountNameFor(AppSession? s) =>
    s?.role == AppRole.mediador ? s?.fullName : null;
