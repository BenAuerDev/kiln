import 'dart:async';

import 'package:obers_ui/obers_ui.dart';

import '../router/navigator_keys.dart';
import '../widgets/kiln_toast.dart';

enum ToastLevel { info, success, warning, error }

/// Shows one toast at a time; a new one replaces the current one.
class ToastService {
  static const _duration = Duration(milliseconds: 1800);

  OiOverlayHandle? _current;
  Timer? _timer;

  void show(String message, {ToastLevel level = ToastLevel.info}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final overlays = OiOverlays.maybeOf(context);
    if (overlays == null) return;
    _dismissCurrent();
    final handle = overlays.show(
      label: message,
      zOrder: OiOverlayZOrder.toast,
      dismissible: false,
      builder: (_) => KilnToast(message: message, level: level),
    );
    _current = handle;
    _timer = Timer(_duration, () {
      if (identical(_current, handle)) _dismissCurrent();
    });
  }

  void _dismissCurrent() {
    _timer?.cancel();
    _timer = null;
    final current = _current;
    _current = null;
    if (current != null && !current.isDismissed) current.dismiss();
  }
}
