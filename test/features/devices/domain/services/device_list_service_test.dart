import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/discovered_device.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/services/device_list_service.dart';

import '../../helpers/fixtures.dart';

void main() {
  const service = DeviceListService();

  group('knownEntries', () {
    final older = veazy.copyWith(lastConnectedAt: DateTime(2026, 11, 1));
    final newer = volcano.copyWith(lastConnectedAt: DateTime(2026, 11, 22));
    const never = KnownDevice(
      id: 'never',
      name: 'S&B VY9',
      model: DeviceModel.venty,
    );

    test('sorts by last use, never used last', () {
      final entries = service.knownEntries(
        devices: [never, older, newer],
        activeDeviceId: null,
        status: ConnectionStatus.disconnected,
        now: fixedNow,
      );

      expect(entries.map((e) => e.device.id), [newer.id, older.id, never.id]);
      expect(entries.every((e) => !e.isActive), isTrue);
      expect(entries.first.daysSinceLastUse, 1);
      expect(entries.last.daysSinceLastUse, isNull);
    });

    test('puts the active device first with the connection status', () {
      final entries = service.knownEntries(
        devices: [newer, older],
        activeDeviceId: older.id,
        status: ConnectionStatus.reconnecting,
        now: fixedNow,
      );

      expect(entries.first.device.id, older.id);
      expect(entries.first.status, ConnectionStatus.reconnecting);
      expect(entries.last.status, isNull);
    });

    test('empty list', () {
      expect(
        service.knownEntries(
          devices: const [],
          activeDeviceId: 'x',
          status: ConnectionStatus.connected,
          now: fixedNow,
        ),
        isEmpty,
      );
    });
  });

  test('nearbyUnknown hides known devices', () {
    const knownHit = DiscoveredDevice(
      id: 'veazy-id',
      name: 'S&B VZ123456',
      model: DeviceModel.veazy,
      rssi: -40,
    );
    final result = service.nearbyUnknown(
      discovered: const [knownHit, discoveredVenty],
      known: const [veazy],
    );

    expect(result, [discoveredVenty]);
  });
}
