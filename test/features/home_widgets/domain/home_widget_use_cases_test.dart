import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/home_widgets/domain/models/home_widget_action.dart';
import 'package:kiln/features/home_widgets/domain/services/home_widget_snapshot_service.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/current_portable_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/current_volcano_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/handle_home_widget_action_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/show_portable_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/show_volcano_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/listen_to_home_widget_actions_use_case.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../portable/helpers/portable_fixtures.dart';
import '../../portable/presentation/presentation_mocks.dart'
    show MockTogglePortableBoostUseCase, MockTogglePortableHeaterUseCase;
import '../../volcano/mocks.dart';
import '../mocks.dart';

void main() {
  final service = HomeWidgetSnapshotService(PortableLadderService());

  group('current snapshots read the active device and its status', () {
    late MockConnectionRepository connection;
    late MockKnownDevicesRepository knownDevices;
    late Signal<KnownDevice?> active;

    setUp(() {
      connection = MockConnectionRepository();
      knownDevices = MockKnownDevicesRepository();
      active = signal(null);
      when(
        () => connection.status,
      ).thenReturn(signal(ConnectionStatus.connected));
      when(() => knownDevices.activeDevice).thenReturn(active);
    });

    test('portable', () {
      final portable = MockPortableRepository();
      when(
        () => portable.status,
      ).thenReturn(signal<PortableStatus?>(testStatus(target: 180)));
      final current = CurrentPortableWidgetUseCase(
        connection: connection,
        knownDevices: knownDevices,
        portable: portable,
        service: service,
      );
      expect(current(), isNull);
      active.value = veazy;
      expect(current()!.ladder.base, 180);
    });

    test('volcano', () {
      final volcano = MockVolcanoRepository();
      when(
        () => volcano.status,
      ).thenReturn(signal<VolcanoStatus?>(volcanoStatus(current: 150)));
      final startFailed = signal(false);
      when(() => volcano.startFailed).thenReturn(startFailed);
      final current = CurrentVolcanoWidgetUseCase(
        connection: connection,
        knownDevices: knownDevices,
        volcano: volcano,
        service: service,
      );
      expect(current(), isNull);
      active.value = volcanoDevice;
      expect(current()!.temperature, 150);
      // A failed start ends the kept snapshot.
      when(() => volcano.status).thenReturn(signal<VolcanoStatus?>(null));
      final previous = current();
      expect(current(previous: previous), previous);
      startFailed.value = true;
      expect(current(previous: previous), isNull);
    });
  });

  group('widget writes go to the repository', () {
    late MockHomeWidgetsRepository repository;

    setUp(() {
      repository = MockHomeWidgetsRepository();
      registerFallbackValue(portableContent);
      registerFallbackValue(HomeWidgetAction.volcanoHeat);
      when(
        () => repository.showPortable(any(), live: any(named: 'live')),
      ).thenAnswer((_) async => right(unit));
      when(
        () => repository.showVolcano(any(), live: any(named: 'live')),
      ).thenAnswer((_) async => right(unit));
    });

    test('show portable, take the Volcano offline', () async {
      await ShowPortableWidgetUseCase(repository: repository)(
        portableContent,
        live: true,
      );
      await ShowVolcanoWidgetUseCase(repository: repository)(null, live: false);
      verify(
        () => repository.showPortable(portableContent, live: true),
      ).called(1);
      verify(() => repository.showVolcano(null, live: false)).called(1);
    });

    test('listen runs the action use case until switched off', () async {
      Future<void> Function(HomeWidgetAction)? installed;
      when(() => repository.setActionHandler(any())).thenAnswer((invocation) {
        installed =
            invocation.positionalArguments.single
                as Future<void> Function(HomeWidgetAction)?;
      });
      final handle = MockHandleHomeWidgetActionUseCase();
      when(
        () => handle(any()),
      ).thenAnswer((_) async => left(const AppError.notConnected()));
      final listen = ListenToHomeWidgetActionsUseCase(
        repository: repository,
        handleAction: handle,
      );

      listen(listen: true);
      // An error is dropped, not thrown at Android.
      await installed!(HomeWidgetAction.volcanoAir);
      verify(() => handle(HomeWidgetAction.volcanoAir)).called(1);

      listen(listen: false);
      expect(installed, isNull);
    });
  });

  group('handle action', () {
    late MockKnownDevicesRepository knownDevices;
    late Signal<KnownDevice?> active;
    late MockToggleVolcanoHeaterUseCase volcanoHeater;
    late MockToggleVolcanoPumpUseCase pump;
    late MockTogglePortableHeaterUseCase portableHeater;
    late MockTogglePortableBoostUseCase boost;
    late HandleHomeWidgetActionUseCase handle;

    setUp(() {
      knownDevices = MockKnownDevicesRepository();
      active = signal(volcanoDevice);
      when(() => knownDevices.activeDevice).thenReturn(active);
      volcanoHeater = MockToggleVolcanoHeaterUseCase();
      pump = MockToggleVolcanoPumpUseCase();
      portableHeater = MockTogglePortableHeaterUseCase();
      boost = MockTogglePortableBoostUseCase();
      when(() => volcanoHeater()).thenAnswer((_) async => right(false));
      when(() => pump()).thenAnswer((_) async => right(true));
      when(
        () => portableHeater(),
      ).thenAnswer((_) async => right(HeaterMode.normal));
      when(() => boost()).thenAnswer((_) async => right(HeaterMode.boost));
      handle = HandleHomeWidgetActionUseCase(
        knownDevices: knownDevices,
        toggleVolcanoHeater: volcanoHeater,
        toggleVolcanoPump: pump,
        togglePortableHeater: portableHeater,
        togglePortableBoost: boost,
      );
    });

    void verifyNothingToggled() {
      verifyNever(() => volcanoHeater());
      verifyNever(() => pump());
      verifyNever(() => portableHeater());
      verifyNever(() => boost());
    }

    test('Volcano: Heat toggles the heater, Air the pump', () async {
      expect(await handle(HomeWidgetAction.volcanoHeat), right(unit));
      verify(() => volcanoHeater()).called(1);
      expect(await handle(HomeWidgetAction.volcanoAir), right(unit));
      verify(() => pump()).called(1);
      verifyNever(() => portableHeater());
      verifyNever(() => boost());
    });

    test('Venty/Veazy: Heat toggles the heater, Boost steps boost', () async {
      active.value = veazy;
      expect(await handle(HomeWidgetAction.portableHeat), right(unit));
      verify(() => portableHeater()).called(1);
      expect(await handle(HomeWidgetAction.portableBoost), right(unit));
      verify(() => boost()).called(1);
      verifyNever(() => volcanoHeater());
      verifyNever(() => pump());
    });

    test('passes a failed write on', () async {
      when(
        () => volcanoHeater(),
      ).thenAnswer((_) async => left(const AppError.notConnected()));
      expect(
        await handle(HomeWidgetAction.volcanoHeat),
        left(const AppError.notConnected()),
      );
    });

    for (final (label, device) in [
      ('nothing active', null),
      ('a demo Volcano', demoVolcano),
      ('a demo Veazy', demoVeazy),
    ]) {
      test('controls nothing for $label', () async {
        active.value = device;
        for (final action in HomeWidgetAction.values) {
          expect(await handle(action), left(const AppError.notConnected()));
        }
        verifyNothingToggled();
      });
    }

    test('a button of one widget never controls the other device', () async {
      active.value = veazy;
      expect(
        await handle(HomeWidgetAction.volcanoHeat),
        left(const AppError.notConnected()),
      );
      active.value = volcanoDevice;
      expect(
        await handle(HomeWidgetAction.portableBoost),
        left(const AppError.notConnected()),
      );
      verifyNothingToggled();
    });
  });
}
