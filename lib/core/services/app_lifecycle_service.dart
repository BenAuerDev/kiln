import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AppLifecycleService {
  AppLifecycleService() {
    _listener = AppLifecycleListener(
      onStateChange: (state) => _state.value = state,
    );
  }

  late final AppLifecycleListener _listener;
  final _state = signal<AppLifecycleState>(AppLifecycleState.resumed);

  ReadonlySignal<AppLifecycleState> get state => _state;

  void dispose() => _listener.dispose();
}
