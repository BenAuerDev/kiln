import 'dart:ui';

import 'package:signals_flutter/signals_flutter.dart';

import '../../l10n/generated/app_localizations.dart';

/// Context-free access to strings for view models. Follows the locale the app
/// is currently rendered in.
class L10nService {
  final _locale = signal<Locale>(_resolve(PlatformDispatcher.instance.locale));

  ReadonlySignal<Locale> get locale => _locale;

  AppLocalizations get strings => lookupAppLocalizations(_locale.value);

  void updateLocale(Locale locale) => updateLocales([locale]);

  /// Picks the first preferred language kiln supports, like Flutter's own
  /// locale resolution, so view-model strings match the rendered screens.
  void updateLocales(List<Locale> preferred) =>
      _locale.value = _resolveFirst(preferred);

  static Locale _resolve(Locale locale) => _resolveFirst([locale]);

  static Locale _resolveFirst(List<Locale> preferred) {
    for (final locale in preferred) {
      final supported = AppLocalizations.supportedLocales.any(
        (l) => l.languageCode == locale.languageCode,
      );
      if (supported) return Locale(locale.languageCode);
    }
    return const Locale('en');
  }
}
