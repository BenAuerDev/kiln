import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/portable/domain/models/quick_setup.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_setup_view_model.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_tab.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';
import '../presentation_mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
    registerFallbackValue(QuickSetup.flavour);
    registerFallbackValue(PortableTab.control);
  });

  late BindingHarness h;
  late MockAdjustBaseTemperatureUseCase adjustBase;
  late MockAdjustBoostOffsetUseCase adjustBoost;
  late MockAdjustSuperBoostOffsetUseCase adjustSuperBoost;
  late MockApplyQuickSetupUseCase applyQuickSetup;
  late MockPortableNavigator navigator;
  late PortableSetupViewModel vm;

  setUp(() async {
    h = BindingHarness();
    adjustBase = MockAdjustBaseTemperatureUseCase();
    adjustBoost = MockAdjustBoostOffsetUseCase();
    adjustSuperBoost = MockAdjustSuperBoostOffsetUseCase();
    applyQuickSetup = MockApplyQuickSetupUseCase();
    navigator = MockPortableNavigator();
    vm = PortableSetupViewModel(
      session: h.binding(),
      ladderService: PortableLadderService(),
      adjustBase: adjustBase,
      adjustBoost: adjustBoost,
      adjustSuperBoost: adjustSuperBoost,
      applyQuickSetup: applyQuickSetup,
      navigator: navigator,
    );
    await h.connect();
  });

  tearDown(() => vm.dispose());

  test('derives the ladder and the matching quick setup', () {
    final ladder = vm.ladder.value!;
    expect(ladder.base, 180);
    expect(ladder.boostTemperature, 195);
    expect(ladder.superBoostTemperature, 210);
    expect(ladder.superBoostAtMax, isTrue);
    expect(vm.matchingQuickSetup.value, QuickSetup.balanced);

    h.status.value = testStatus(target: 175, boost: 10, superBoost: 10);
    expect(vm.matchingQuickSetup.value, QuickSetup.flavour);

    h.status.value = testStatus(target: 176);
    expect(vm.matchingQuickSetup.value, isNull);
  });

  test('lists every quick setup with its ladder', () {
    expect(vm.quickSetups.map((option) => option.setup), QuickSetup.values);
    final flavour = vm.quickSetups.first.ladder;
    expect(flavour.base, 175);
    expect(flavour.superBoostTemperature, 195);
  });

  test('exposes the ends of the scale', () {
    expect(vm.scaleMinimum, 40);
    expect(vm.scaleMaximum, 210);
  });

  test('each −/+ adjusts its own value', () async {
    when(() => adjustBase(any())).thenAnswer((_) async => right(some(1)));
    when(() => adjustBoost(any())).thenAnswer((_) async => right(some(1)));
    when(() => adjustSuperBoost(any())).thenAnswer((_) async => right(some(1)));

    vm
      ..lowerBase()
      ..raiseBase()
      ..lowerBoost()
      ..raiseBoost()
      ..lowerSuperBoost()
      ..raiseSuperBoost();
    await pumpEventQueue();

    verify(() => adjustBase(-1)).called(1);
    verify(() => adjustBase(1)).called(1);
    verify(() => adjustBoost(-1)).called(1);
    verify(() => adjustBoost(1)).called(1);
    verify(() => adjustSuperBoost(-1)).called(1);
    verify(() => adjustSuperBoost(1)).called(1);
    verify(() => h.haptics.tick()).called(6);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    h.verifySaved(1);
  });

  test('a quick setup is applied and confirmed', () async {
    when(() => applyQuickSetup(any())).thenAnswer((_) async => right(unit));

    await vm.applyQuickSetup(QuickSetup.full);

    verify(() => applyQuickSetup(QuickSetup.full)).called(1);
    h.verifySaved(1);
  });

  test('the matching quick setup is not written again', () async {
    await vm.applyQuickSetup(QuickSetup.balanced);

    verifyNever(() => applyQuickSetup(any()));
    h.verifyNoToast();
  });

  test('a failed quick setup shows the error', () async {
    when(
      () => applyQuickSetup(any()),
    ).thenAnswer((_) async => left(const AppError.connectionLost()));

    await vm.applyQuickSetup(QuickSetup.flavour);

    verify(
      () => h.toasts.show(strings.errorConnectionLost, level: ToastLevel.error),
    ).called(1);
  });

  test('navigation', () {
    vm
      ..openSettings()
      ..selectTab(PortableTab.setup)
      ..selectTab(PortableTab.devices);

    verify(() => navigator.openSettings()).called(1);
    verify(() => navigator.goToTab(PortableTab.devices)).called(1);
    verifyNever(() => navigator.goToTab(PortableTab.setup));
  });
}
