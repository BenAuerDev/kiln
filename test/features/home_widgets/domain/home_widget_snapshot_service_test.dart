import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/home_widgets/domain/models/volcano_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/domain/services/home_widget_snapshot_service.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_battery.dart';
import 'package:kiln/features/portable/domain/models/portable_heat_phase.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/volcano/domain/models/volcano_heat_phase.dart';

import '../../portable/helpers/portable_fixtures.dart' show testStatus;
import '../mocks.dart';

void main() {
  final service = HomeWidgetSnapshotService(PortableLadderService());
  const connected = ConnectionStatus.connected;

  group('portable', () {
    test('a connected Venty/Veazy gives battery, ladder and finish', () {
      final snapshot = service.portable(
        device: veazy,
        connection: connected,
        status: testStatus(
          target: 185,
          boost: 15,
          superBoost: 15,
          heaterMode: HeaterMode.boost,
        ),
      )!;
      expect(snapshot.model, DeviceModel.veazy);
      expect(
        snapshot.battery,
        const PortableBattery(percent: 80, charging: false),
      );
      expect(snapshot.ladder.base, 185);
      expect(snapshot.ladder.boostTemperature, 200);
      // Capped at the device maximum.
      expect(snapshot.ladder.superBoostTemperature, 210);
      expect(snapshot.finish, DeviceFinish.blue);
      expect(snapshot.heaterMode, HeaterMode.boost);
      expect(snapshot.phase, PortableHeatPhase.heating);
      expect(snapshot.activeTemperature, 200);
    });

    test('nothing for a demo, another model, no link or no status', () {
      final status = testStatus();
      expect(
        service.portable(
          device: demoVeazy,
          connection: connected,
          status: status,
        ),
        isNull,
      );
      expect(
        service.portable(
          device: volcanoDevice,
          connection: connected,
          status: status,
        ),
        isNull,
      );
      expect(
        service.portable(device: null, connection: connected, status: status),
        isNull,
      );
      expect(
        service.portable(
          device: veazy,
          connection: ConnectionStatus.reconnecting,
          status: status,
        ),
        isNull,
      );
      expect(
        service.portable(device: veazy, connection: connected, status: null),
        isNull,
      );
    });
  });

  group('volcano', () {
    test('a connected Volcano gives rounded temperature and gauge', () {
      final snapshot = service.volcano(
        device: volcanoDevice,
        connection: connected,
        status: volcanoStatus(current: 134.6, target: 185),
      )!;
      expect(snapshot.temperature, 135);
      expect(snapshot.target, 185);
      expect(snapshot.phase, VolcanoHeatPhase.heating);
      expect(snapshot.heaterOn, isTrue);
      expect(snapshot.pumpOn, isFalse);
      // (135 − 40) / (230 − 40)
      expect(snapshot.progress, 0.5);
      expect(snapshot.finish, DeviceFinish.ember);
    });

    test('tenths of a degree give the same snapshot', () {
      VolcanoWidgetSnapshot? at(double current) => service.volcano(
        device: volcanoDevice,
        connection: connected,
        status: volcanoStatus(current: current),
      );
      expect(at(142.1), at(142.4));
    });

    test('no reading yet: no temperature, empty gauge', () {
      final snapshot = service.volcano(
        device: volcanoDevice,
        connection: connected,
        status: volcanoStatus(current: null),
      )!;
      expect(snapshot.temperature, isNull);
      expect(snapshot.progress, 0);
    });

    test('keeps the previous one while reconnecting or until a status', () {
      const previous = VolcanoWidgetSnapshot(
        temperature: 170,
        target: 185,
        phase: VolcanoHeatPhase.heating,
        pumpOn: false,
        progress: 0.7,
        finish: DeviceFinish.ember,
      );
      expect(
        service.volcano(
          device: volcanoDevice,
          connection: ConnectionStatus.reconnecting,
          status: null,
          previous: previous,
        ),
        previous,
      );
      expect(
        service.volcano(
          device: volcanoDevice,
          connection: connected,
          status: null,
          previous: previous,
        ),
        previous,
      );
      expect(
        service.volcano(
          device: volcanoDevice,
          connection: connected,
          status: null,
          startFailed: true,
          previous: previous,
        ),
        isNull,
      );
      expect(
        service.volcano(
          device: volcanoDevice,
          connection: ConnectionStatus.disconnected,
          status: volcanoStatus(),
          previous: previous,
        ),
        isNull,
      );
    });

    test('offline for a demo, a portable or nothing active', () {
      final status = volcanoStatus();
      expect(
        service.volcano(
          device: demoVolcano,
          connection: connected,
          status: status,
        ),
        isNull,
      );
      expect(
        service.volcano(device: veazy, connection: connected, status: status),
        isNull,
      );
      expect(
        service.volcano(device: null, connection: connected, status: status),
        isNull,
      );
    });
  });
}
