import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Bridges a signal to a [Listenable] for `GoRouter.refreshListenable`.
class SignalListenable extends ChangeNotifier {
  SignalListenable(ReadonlySignal<Object?> source) {
    _dispose = source.subscribe((_) => notifyListeners());
  }

  late final void Function() _dispose;

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}
