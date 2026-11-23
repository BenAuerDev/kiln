import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SystemLocaleService with WidgetsBindingObserver {
  SystemLocaleService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _locales = signal<List<Locale>>(
    WidgetsBinding.instance.platformDispatcher.locales,
  );

  /// The user's preferred languages, most preferred first.
  ReadonlySignal<List<Locale>> get locales => _locales;

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (locales != null && locales.isNotEmpty) _locales.value = locales;
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
