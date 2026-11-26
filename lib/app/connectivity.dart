import 'dart:async';

import 'package:flutter/foundation.dart';

/// Estado de ligação. Sem plugin de rede: fica offline quando um pedido
/// falha por rede e volta a ficar online quando o servidor responde (teste
/// periódico enquanto offline).
class AppConnectivity extends ChangeNotifier {
  AppConnectivity({
    this.probe,
    this.retryEvery = const Duration(seconds: 5),
  });

  final Future<bool> Function()? probe;
  final Duration retryEvery;

  bool _online = true;
  Timer? _timer;

  bool get online => _online;

  void reportNetworkFailure() {
    if (!_online) return;
    _online = false;
    notifyListeners();
    if (probe != null) {
      _timer = Timer.periodic(retryEvery, (_) async {
        if (await probe!()) reportReachable();
      });
    }
  }

  void reportReachable() {
    if (_online) return;
    _online = true;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
