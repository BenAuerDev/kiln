import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/known_device_entry.dart';
import 'package:kiln/features/devices/presentation/extensions/known_device_entry_x.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';

import '../../helpers/fixtures.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('active devices show their connection status', () {
    expect(
      const KnownDeviceEntry(
        device: veazy,
        status: ConnectionStatus.reconnecting,
      ).subtitle(en),
      'Reconnecting…',
    );
  });

  test('other devices show when they were last used', () {
    expect(
      const KnownDeviceEntry(device: veazy, daysSinceLastUse: 0).subtitle(en),
      'Last used today',
    );
    expect(
      const KnownDeviceEntry(device: veazy, daysSinceLastUse: 1).subtitle(en),
      'Last used yesterday',
    );
    expect(
      const KnownDeviceEntry(device: veazy, daysSinceLastUse: 3).subtitle(en),
      'Last used 3 days ago',
    );
    expect(const KnownDeviceEntry(device: veazy).subtitle(en), 'Not used yet');
  });
}
