import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/finish_preference.dart';
import 'package:kiln/features/devices/presentation/extensions/device_finish_x.dart';
import 'package:kiln/features/devices/presentation/extensions/finish_preference_x.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  test('tokens come from the palette', () {
    expect(DeviceFinish.ember.tokens, same(KilnPalette.ember));
    expect(DeviceFinish.lava.tokens, same(KilnPalette.lava));
    expect(DeviceFinish.blue.tokens, same(KilnPalette.blue));
    expect(DeviceFinish.pink.tokens, same(KilnPalette.pink));
    expect(DeviceFinish.mono.tokens, same(KilnPalette.mono));
  });

  test('every finish has a label in both languages', () {
    for (final finish in DeviceFinish.values) {
      expect(finish.label(en), isNotEmpty);
      expect(finish.label(de), isNotEmpty);
    }
    expect(DeviceFinish.blue.label(en), 'Blue');
    expect(DeviceFinish.blue.label(de), 'Blau');
  });

  test('finish preference labels', () {
    expect(const MatchDevice().label(en), 'Match my device');
    expect(const FixedFinish(DeviceFinish.pink).label(en), 'Pink');
  });
}
