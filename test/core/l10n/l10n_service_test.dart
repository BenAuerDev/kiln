import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/l10n/l10n_service.dart';

void main() {
  late L10nService service;

  setUp(() => service = L10nService());

  test('picks the first supported language from the preferred list', () {
    service.updateLocales(const [Locale('fr'), Locale('de', 'AT')]);

    expect(service.locale.value, const Locale('de'));
    expect(service.strings.localeName, 'de');
  });

  test('falls back to English when nothing is supported', () {
    service.updateLocales(const [Locale('fr'), Locale('es')]);

    expect(service.locale.value, const Locale('en'));
  });

  test('a single override is applied directly', () {
    service.updateLocale(const Locale('de'));

    expect(service.locale.value, const Locale('de'));
  });
}
