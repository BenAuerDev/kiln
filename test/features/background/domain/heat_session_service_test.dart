import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/background/domain/models/heat_session.dart';
import 'package:kiln/features/background/domain/services/heat_session_service.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/services/workflow_presets.dart';

import '../../portable/helpers/portable_fixtures.dart' show testStatus;

void main() {
  final service = HeatSessionService();
  const veazy = KnownDevice(id: 'vz', name: 'VZ', model: DeviceModel.veazy);
  const volcano = KnownDevice(
    id: 'vh',
    name: 'VH',
    model: DeviceModel.volcanoHybrid,
  );

  VolcanoStatus volcanoStatus({bool heaterOn = true, double? current = 172}) =>
      VolcanoStatus(
        currentTemperature: current,
        targetTemperature: 185,
        heaterOn: heaterOn,
        pumpOn: false,
        autoShutdown: true,
        fahrenheit: false,
        displayOnCooling: true,
        vibrationWhenReady: true,
      );

  HeatSession? of(
    KnownDevice device, {
    ConnectionStatus connection = ConnectionStatus.connected,
    HeatSession? previous,
    HeaterMode mode = HeaterMode.normal,
    VolcanoStatus? volcanoStatus,
    WorkflowRun? workflow,
  }) => service.session(
    device: device,
    connection: connection,
    previous: previous,
    portable: testStatus(target: 180, heaterMode: mode),
    volcano: volcanoStatus,
    workflow: workflow,
  );

  test('nothing without a connected device or with the heater off', () {
    expect(of(veazy, connection: ConnectionStatus.disconnected), isNull);
    expect(of(veazy, connection: ConnectionStatus.connecting), isNull);
    expect(of(veazy, mode: HeaterMode.off), isNull);
    expect(of(volcano, volcanoStatus: volcanoStatus(heaterOn: false)), isNull);
    expect(of(volcano), isNull);
  });

  test('a short drop keeps the previous session while reconnecting', () {
    final heating = of(veazy)!;
    expect(
      of(veazy, connection: ConnectionStatus.reconnecting, previous: heating),
      heating,
    );
    expect(of(veazy, connection: ConnectionStatus.reconnecting), isNull);
    // A failed session start ends it.
    expect(
      service.session(
        device: veazy,
        connection: ConnectionStatus.connected,
        portable: null,
        volcano: null,
        workflow: null,
        startFailed: true,
        previous: heating,
      ),
      isNull,
    );
    // Connected again, but the device has not reported its status yet.
    expect(
      service.session(
        device: veazy,
        connection: ConnectionStatus.connected,
        portable: null,
        volcano: null,
        workflow: null,
        previous: heating,
      ),
      heating,
    );
  });

  test('demo devices never get a background session', () {
    expect(
      of(
        const KnownDevice(
          id: 'demo:veazy',
          name: 'kiln demo',
          model: DeviceModel.veazy,
        ),
      ),
      isNull,
    );
  });

  test('portable: setpoint with boost included, boost target at base', () {
    final base = of(veazy)!;
    expect(base.temperature, 180);
    expect(base.boostTarget, 195);
    expect(base.batteryPercent, 80);
    final boost = of(veazy, mode: HeaterMode.boost)!;
    expect(boost.temperature, 195);
    expect(boost.boostTarget, isNull);
    expect(of(veazy, mode: HeaterMode.superboost)!.temperature, 210);
  });

  test('volcano: current temperature and ready from the ready rule', () {
    final heating = of(volcano, volcanoStatus: volcanoStatus())!;
    expect(heating.temperature, 172);
    expect(heating.target, 185);
    expect(heating.ready, isFalse);
    expect(
      of(volcano, volcanoStatus: volcanoStatus(current: 185))!.ready,
      isTrue,
    );
  });

  test(
    'a running workflow on the Volcano keeps a session, heater off or not',
    () {
      final run = WorkflowRun(
        deviceId: 'vh',
        workflow: WorkflowPresets.all.first,
        stepIndex: 1,
        stepStartedAt: DateTime(2026),
      );
      final session = of(
        volcano,
        volcanoStatus: volcanoStatus(heaterOn: false),
        workflow: run,
      )!;
      expect(session.workflow, run);
      final elsewhere = WorkflowRun(
        deviceId: 'other',
        workflow: WorkflowPresets.all.first,
        stepIndex: 1,
        stepStartedAt: DateTime(2026),
      );
      expect(
        of(
          volcano,
          volcanoStatus: volcanoStatus(heaterOn: false),
          workflow: elsewhere,
        ),
        isNull,
      );
    },
  );
}
