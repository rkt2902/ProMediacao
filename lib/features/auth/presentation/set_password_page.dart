import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../application/validators.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';

/// Ecrã 1b (definir): vindo da recuperação ou do convite de mediador.
/// Exige sessão (o router manda para o link expirado se não houver).
class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _formError;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _valid => _password.text.length >= minPasswordLength;

  Future<void> _submit() async {
    final services = AppScope.of(context);
    setState(() {
      _loading = true;
      _formError = null;
    });
    try {
      await services.auth.updatePassword(_password.text);
      services.connectivity.reportReachable();
      services.session.finishRecovery();
      final role = services.session.role;
      if (mounted && role != null) context.go(homeFor(role));
    } on AuthFailure catch (f) {
      if (f.kind == AuthFailureKind.network) {
        services.connectivity.reportNetworkFailure();
      }
      if (mounted) {
        setState(() {
          _formError = f.kind == AuthFailureKind.network
              ? AuthCopy.networkError
              : AuthCopy.sendFailed;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return AuthLayout(
      offlineMessage: AuthCopy.offlineEntry,
      tabs: const FolderTab(label: AuthCopy.tabOffice),
      children: [
        const SizedBox(height: AppSpace.s32),
        Semantics(
          header: true,
          child: Text(
            AuthCopy.setTitle,
            style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        ListenableBuilder(
          listenable: services.connectivity,
          builder: (context, _) {
            final online = services.connectivity.online;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: AuthCopy.newPassword,
                  controller: _password,
                  readOnly: _loading,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  trailing: TextAction(
                    label: _obscure ? AuthCopy.show : AuthCopy.hide,
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Semantics(
                  label:
                      '${AuthCopy.ruleLength}: ${_valid ? 'cumprida' : 'por cumprir'}',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Icon(
                        _valid ? Icons.check_circle : Icons.circle_outlined,
                        size: AppSize.iconePequeno,
                        color: _valid
                            ? AppColors.estadoAtivo
                            : AppColors.tintaMedia,
                      ),
                      const SizedBox(width: AppSpace.s8),
                      Text(
                        AuthCopy.ruleLength,
                        style: AppType.corpoPequeno.copyWith(
                          color: AppColors.tintaMedia,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: AppSpace.s16),
                  InlineNotice(kind: NoticeKind.erro, message: _formError!),
                ],
                const SizedBox(height: AppSpace.s24),
                PrimaryButton(
                  label: AuthCopy.saveAndEnter,
                  loadingLabel: AuthCopy.saving,
                  loading: _loading,
                  principal: true,
                  expand: true,
                  onPressed: online && _valid ? _submit : null,
                  disabledReason: online ? null : AuthCopy.offlineReason,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
