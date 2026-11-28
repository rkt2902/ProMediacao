import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import 'folder_tab.dart';

/// Coluna cujos filhos saem com animação (`base` / `sair`: opacidade e
/// altura) em vez de desaparecerem a seco. O filho retirado da lista de
/// [children] fica no sítio, a recolher, até a saída acabar; só depois é
/// removido da árvore. Os filhos novos não animam aqui (quem os cria
/// envolve-os, por exemplo, numa entrada `lento` / `entrar`).
///
/// - Cada filho tem de ter [Key] (é por ela que se sabe quem saiu); sem
///   chave, usa-se a posição.
/// - [ruled]: réguas `fino` entre os filhos e nas pontas (como a
///   `RuledList`), que saem e recolhem com cada filho.
/// - [gap]: espaço entre filhos (anima quando a posição muda).
/// - Com "reduzir movimento" a saída é um corte seco.
class ExitingList extends StatefulWidget {
  const ExitingList({
    super.key,
    required this.children,
    this.ruled = false,
    this.gap = 0,
  });

  final List<Widget> children;
  final bool ruled;
  final double gap;

  @override
  State<ExitingList> createState() => _ExitingListState();
}

class _Slot {
  _Slot(this.key, this.child, TickerProvider vsync)
    : controller = AnimationController(vsync: vsync, value: 1) {
    curve = CurvedAnimation(
      parent: controller,
      curve: AppMotion.entrar,
      reverseCurve: AppMotion.sair,
    );
  }

  final Key key;
  Widget child;
  final AnimationController controller;
  late final CurvedAnimation curve;
  bool leaving = false;

  void dispose() {
    curve.dispose();
    controller.dispose();
  }
}

class _ExitingListState extends State<ExitingList>
    with TickerProviderStateMixin {
  final List<_Slot> _slots = [];

  Key _keyOf(Widget w, int i) => w.key ?? ValueKey<int>(i);

  @override
  void initState() {
    super.initState();
    for (final (i, w) in widget.children.indexed) {
      _slots.add(_Slot(_keyOf(w, i), w, this));
    }
  }

  @override
  void didUpdateWidget(ExitingList old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final byKey = {for (final s in _slots) s.key: s};
    final nextKeys = <Key>[];
    final result = <_Slot>[];
    for (final (i, w) in widget.children.indexed) {
      final k = _keyOf(w, i);
      nextKeys.add(k);
      var slot = byKey[k];
      if (slot == null) {
        slot = _Slot(k, w, this);
      } else {
        slot.child = w;
        if (slot.leaving) {
          slot.leaving = false;
          slot.controller.forward();
        }
      }
      result.add(slot);
    }
    final reduced = AppMotion.reduced(context);
    for (var i = 0; i < _slots.length; i++) {
      final s = _slots[i];
      if (nextKeys.contains(s.key)) continue;
      if (reduced) {
        s.dispose();
        continue;
      }
      var at = 0;
      for (var j = i - 1; j >= 0; j--) {
        final idx = result.indexOf(_slots[j]);
        if (idx >= 0) {
          at = idx + 1;
          break;
        }
      }
      result.insert(at, s);
      if (!s.leaving) {
        s.leaving = true;
        s.controller
            .animateBack(
              0,
              duration: AppMotion.resolve(context, AppMotion.base),
            )
            .whenComplete(() => _finish(s));
      }
    }
    _slots
      ..clear()
      ..addAll(result);
  }

  void _finish(_Slot s) {
    if (!mounted || !s.leaving || !_slots.contains(s)) return;
    setState(() => _slots.remove(s));
    s.dispose();
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gapDur = AppMotion.resolve(context, AppMotion.base);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.ruled && _slots.isNotEmpty) const AppRule(),
        for (final (i, s) in _slots.indexed)
          KeyedSubtree(
            key: s.key,
            child: SizeTransition(
              sizeFactor: s.curve,
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: s.curve,
                child: IgnorePointer(
                  ignoring: s.leaving,
                  child: ExcludeSemantics(
                    excluding: s.leaving,
                    child: AnimatedPadding(
                      duration: gapDur,
                      curve: AppMotion.mudar,
                      padding: EdgeInsets.only(top: i == 0 ? 0 : widget.gap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [s.child, if (widget.ruled) const AppRule()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
