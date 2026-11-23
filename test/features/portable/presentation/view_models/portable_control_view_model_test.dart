import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_heat_phase.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_control_view_model.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_tab.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';
import '../presentation_mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
    registerFallbackValue(HeaterMode.off);
    registerFallbackValue(PortableTab.control);
  });

  late BindingHarness h;
  late MockAdjustBaseTemperatureUseCase adjustBase;
  late MockSetBaseTemperatureUseCase setBase;
  late MockTogglePortableHeaterUseCase toggleHeater;
  late MockTogglePortableBoostUseCase toggleBoost;
  late MockPortableNavigator navigator;
  late PortableControlViewModel vm;

  setUp(() async {
    h = BindingHarness();
    adjustBase = MockAdjustBaseTemperatureUseCase();
    setBase = MockSetBaseTemperatureUseCase();
    toggleHeater = MockTogglePortableHeaterUseCase();
    toggleBoost = MockTogglePortableBoostUseCase();
    navigator = MockPortableNavigator();
    vm = PortableControlViewModel(
      session: h.binding(),
      ladderService: PortableLadderService(),
      adjustBase: adjustBase,
      setBase: setBase,
      toggleHeater: toggleHeater,
      toggleBoost: toggleBoost,
      navigator: navigator,
    );
    await h.connect();
  });

  tearDown(() => vm.dispose());

  group('state', () {
    test('heater off', () {
      expect(vm.phase.value, PortableHeatPhase.off);
      expect(vm.activeTarget.value, 180);
      expect(vm.gaugeProgress.value, 0);
    });

    test('heating without a live reading keeps the arc empty', () {
      h.status.value = testStatus(heaterMode: HeaterMode.normal);
      expect(vm.phase.value, PortableHeatPhase.heating);
      expect(vm.gaugeProgress.value, 0);
    });

    test('ready without a live reading fills the arc to the target', () {
      h.status.value = testStatus(
        heaterMode: HeaterMode.normal,
      ).copyWith(setpointReached: true);
      expect(vm.phase.value, PortableHeatPhase.ready);
      expect(vm.gaugeProgress.value, closeTo(140 / 170, 1e-9));
    });

    test('a live reading drives the arc', () {
      h.status.value = testStatus(
        heaterMode: HeaterMode.normal,
      ).copyWith(currentTemperature: 125);
      expect(vm.gaugeProgress.value, closeTo(0.5, 1e-9));
    });

    test('boost raises the active target', () {
      h.status.value = testStatus(heaterMode: HeaterMode.boost);
      expect(vm.activeTarget.value, 195);
      h.status.value = testStatus(heaterMode: HeaterMode.superboost);
      expect(vm.activeTarget.value, 210);
      expect(vm.targetPosition.value, 1);
    });
  });

  test('−/+ steps tick immediately and confirm once', () async {
    when(() => adjustBase(any())).thenAnswer((_) async => right(some(181)));

    vm
      ..increaseTarget()
      ..increaseTarget()
      ..decreaseTarget();

    verify(() => h.haptics.tick()).called(3);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    verify(() => adjustBase(1)).called(2);
    verify(() => adjustBase(-1)).called(1);
    h.verifySaved(1);
  });

  test('a preset writes and confirms', () async {
    when(() => setBase(any())).thenAnswer((_) async => right(some(195)));

    await vm.selectPreset(195);

    verify(() => setBase(195)).called(1);
    h.verifySaved(1);
  });

  test('the current preset does not confirm', () async {
    when(() => setBase(any())).thenAnswer((_) async => right(none()));

    await vm.selectPreset(180);

    h.verifyNoToast();
  });

  test('presets come from the domain', () {
    expect(vm.presets, [175, 185, 195, 205]);
  });

  test('heater toggle ticks and confirms', () async {
    when(
      () => toggleHeater(),
    ).thenAnswer((_) async => right(HeaterMode.normal));

    await vm.toggleHeater();

    verify(() => toggleHeater()).called(1);
    verify(() => h.haptics.tick()).called(1);
    h.verifySaved(1);
  });

  test('heater toggle error shows a toast', () async {
    when(
      () => toggleHeater(),
    ).thenAnswer((_) async => left(const AppError.connectionLost()));

    await vm.toggleHeater();

    verify(
      () => h.toasts.show(strings.errorConnectionLost, level: ToastLevel.error),
    ).called(1);
    verifyNever(() => h.haptics.success());
  });

  test('a rejected boost write explains itself', () async {
    when(
      () => toggleBoost(),
    ).thenAnswer((_) async => left(const AppError.writeNotVerified('boost')));

    await vm.toggleBoost();

    verify(() => h.haptics.warning()).called(1);
    verify(
      () =>
          h.toasts.show(strings.errorWriteNotVerified, level: ToastLevel.error),
    ).called(1);
    verifyNever(() => h.haptics.success());
  });

  test('navigation', () {
    vm
      ..selectTab(PortableTab.devices)
      ..selectTab(PortableTab.control)
      ..selectTab(PortableTab.setup);

    verify(() => navigator.goToTab(PortableTab.devices)).called(1);
    verify(() => navigator.goToTab(PortableTab.setup)).called(1);
    verifyNever(() => navigator.goToTab(PortableTab.control));
  });
}
