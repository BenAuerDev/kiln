import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/formatters/duration_formatter.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  test('clock is m:ss and never negative', () {
    expect(DurationFormatter.clock(const Duration(seconds: 18)), '0:18');
    expect(DurationFormatter.clock(const Duration(seconds: 725)), '12:05');
    expect(DurationFormatter.clock(const Duration(seconds: -3)), '0:00');
  });

  test('short', () {
    expect(DurationFormatter.short(const Duration(seconds: 45), en), '45 s');
    expect(DurationFormatter.short(const Duration(minutes: 2), en), '2 min');
    expect(
      DurationFormatter.short(const Duration(seconds: 90), en),
      '1 min 30 s',
    );
    expect(DurationFormatter.short(const Duration(minutes: 2), de), '2 Min.');
  });

  test('about rounds to minutes', () {
    expect(
      DurationFormatter.about(const Duration(seconds: 179), en),
      'about 3 min',
    );
    expect(
      DurationFormatter.about(const Duration(seconds: 20), en),
      'under a minute',
    );
    expect(
      DurationFormatter.about(const Duration(minutes: 5), de),
      'etwa 5 Min.',
    );
  });
}
