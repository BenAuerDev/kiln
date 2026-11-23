import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/features/background/domain/models/background_notice.dart';
import 'package:kiln/features/background/domain/models/heat_session.dart';
import 'package:kiln/features/background/domain/services/heat_session_service.dart';
import 'package:kiln/features/background/domain/use_cases/alert_ready_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/current_heat_session_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/dismiss_ready_alert_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/reset_background_service_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/show_background_session_use_case.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/devices/domain/repositories/known_devices_repository.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/repositories/portable_repository.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:kiln/features/volcano/domain/repositories/volcano_repository.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../portable/helpers/portable_fixtures.dart' show testStatus;
import '../mocks.dart';

class _MockConnection extends Mock implements ConnectionRepository {}

class _MockKnownDevices extends Mock implements KnownDevicesRepository {}

class _MockPortable extends Mock implements PortableRepository {}

class _MockVolcano extends Mock implements VolcanoRepository {}

void main() {
  const notice = BackgroundNotice(
    title: 'T',
    text: 'X',
    sessionChannel: 'S',
    readyChannel: 'R',
  );

  setUpAll(() => registerFallbackValue(notice));

  group('service use cases go to the repository', () {
    late MockBackgroundServiceRepository repository;

    setUp(() {
      repository = MockBackgroundServiceRepository();
      when(() => repository.show(any())).thenAnswer((_) async => right(unit));
      when(() => repository.hide()).thenAnswer((_) async => right(unit));
      when(() => repository.alert(any())).thenAnswer((_) async => right(unit));
      when(
        () => repository.dismissAlert(),
      ).thenAnswer((_) async => right(unit));
      when(() => repository.reset()).thenAnswer((_) async => right(unit));
    });

    test('show with a notice, hide without', () async {
      final show = ShowBackgroundSessionUseCase(repository: repository);
      await show(notice);
      await show(null);
      verify(() => repository.show(notice)).called(1);
      verify(() => repository.hide()).called(1);
    });

    test('alert, dismiss, reset', () async {
      await AlertReadyUseCase(repository: repository)(notice);
      await DismissReadyAlertUseCase(repository: repository)();
      await ResetBackgroundServiceUseCase(repository: repository)();
      verify(() => repository.alert(notice)).called(1);
      verify(() => repository.dismissAlert()).called(1);
      verify(() => repository.reset()).called(1);
    });
  });

  test('current session reads the active device and its status', () {
    final connection = _MockConnection();
    final knownDevices = _MockKnownDevices();
    final portable = _MockPortable();
    final volcano = _MockVolcano();
    final status = signal(ConnectionStatus.connected);
    when(() => connection.status).thenReturn(status);
    when(() => knownDevices.activeDevice).thenReturn(
      signal<KnownDevice?>(
        const KnownDevice(id: 'vz', name: 'VZ', model: DeviceModel.veazy),
      ),
    );
    when(() => portable.status).thenReturn(
      signal(testStatus(target: 180, heaterMode: HeaterMode.normal)),
    );
    when(() => volcano.status).thenReturn(signal<VolcanoStatus?>(null));
    when(() => portable.startFailed).thenReturn(signal(false));
    when(() => volcano.startFailed).thenReturn(signal(false));
    final current = CurrentHeatSessionUseCase(
      connection: connection,
      knownDevices: knownDevices,
      portable: portable,
      volcano: volcano,
      workflowRuns: WorkflowRunRepository(),
      service: HeatSessionService(),
    );
    final HeatSession heating = current()!;
    expect(heating.temperature, 180);
    status.value = ConnectionStatus.reconnecting;
    expect(current(previous: heating), heating);
    expect(current(), isNull);
  });
}
