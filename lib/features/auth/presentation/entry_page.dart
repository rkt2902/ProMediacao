import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/design/motion.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../data/entry_tab_store.dart';
import '../domain/auth_models.dart';
import 'auth_copy.dart';
import 'auth_layout.dart';
import 'client_link_form.dart';
import 'login_form.dart';

/// Ecrã 1: entrada com dois separadores (cliente e escritório).
class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  EntryTab _tab = EntryTab.client;
  bool _userChose = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final services = AppScope.of(context);
    final ended = services.session.endedRole;
    if (ended != null) {
      // Sessão terminada: o separador do perfil que saiu.
      _tab = ended == AppRole.cliente ? EntryTab.client : EntryTab.office;
      _userChose = true;
    } else {
      services.tabStore.read().then((saved) {
        if (!mounted || _userChose || saved == null) return;
        setState(() => _tab = saved);
      });
    }
  }

  void _choose(int i) {
    final tab = EntryTab.values[i];
    setState(() {
      _tab = tab;
      _userChose = true;
    });
    AppScope.of(context).tabStore.write(tab);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final client = _tab == EntryTab.client;
    return AuthLayout(
      offlineMessage: AuthCopy.offlineEntry,
      tabs: FolderTabs(
        items: const [
          FolderTabItem(label: AuthCopy.tabClient),
          FolderTabItem(label: AuthCopy.tabOffice),
        ],
        selectedIndex: _tab.index,
        onChanged: _choose,
      ),
      children: [
        ListenableBuilder(
          listenable: services.session,
          builder: (context, _) {
            final s = services.session;
            final show =
                s.sessionEnded &&
                s.endedRole != null &&
                (s.endedRole == AppRole.cliente) == client;
            if (!show) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.s24),
              child: InlineNotice(
                kind: NoticeKind.aviso,
                message: client
                    ? AuthCopy.sessionEndedClient
                    : AuthCopy.sessionEndedOffice,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpace.s32),
        Semantics(
          header: true,
          child: Text(
            AuthCopy.title,
            style: AppType.tituloPara(AppBreakpoints.fromContext(context)),
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        AnimatedSwitcher(
          duration: AppMotion.resolve(context, AppMotion.base),
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: client
                ? const ClientLinkForm(help: AuthCopy.clientHelp)
                : LoginForm(onForgot: () => context.go(AppRoutes.recover)),
          ),
        ),
      ],
    );
  }
}
