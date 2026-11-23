import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/presentation/view_models/ramp_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../portable/helpers/portable_fixtures.dart' show testStatus;
import '../../mocks.dart';

void main() {
  late RampRunRepository runs;
  late Signal<PortableStatus?> status;
  late MockStartRampUseCase start;
  late MockStopRampUseCase stop;
  late MockToastService toast;
  late Signal<String?> activeId;
  late DateTime now;
  late RampViewModel vm;

  final t0 = DateTime(2026, 11, 23, 21);
  final classic = RampService.presets[1];

  setUpAll(() {
    registerFallbackValue(classic);
    registerFallbackValue(ToastLevel.info);
  });

  setUp(() {
    runs = RampRunRepository();
    status = signal(testStatus(heaterMode: HeaterMode.normal));
    final portable = MockPortableRepository();
    when(() => portable.status).thenReturn(status);
    when(() => portable.sessionActive).thenReturn(signal(true));
    when(() => portable.sessionNumber).thenReturn(signal(1));
    activeId = signal('v');
    final connection = MockConnectionRepository();
    when(() => connection.activeDeviceId).thenReturn(activeId);
    start = MockStartRampUseCase();
    stop = MockStopRampUseCase();
    when(() => start(any())).thenAnswer((_) async => right(unit));
    when(() => stop()).thenAnswer((_) async => right(unit));
    final haptics = MockHapticsService();
    when(() => haptics.tick()).thenAnswer((_) async {});
    when(() => haptics.success()).thenAnswer((_) async {});
    when(() => haptics.warning()).thenAnswer((_) async {});
    toast = MockToastService();
    now = t0;
    vm = RampViewModel(
      runs: runs,
      portable: portable,
      connection: connection,
      ramps: RampService(),
      startRamp: start,
      stopRamp: stop,
      l10n: FakeL10nService(),
      haptics: haptics,
      toast: toast,
      clock: () => now,
      refresh: const Duration(hours: 1),
    );
  });

  tearDown(() {
    vm.dispose();
    runs.clear();
  });

  test('shows the chosen preset and its summary', () {
    expect(vm.selectedIndex.value, 1);
    expect(vm.nameOf(classic), 'Classic');
    expect(vm.rangeOf(classic), '180–200°');
    expect(vm.selectedSummary.value, '+5° every 1 min 30 s · 6 min');
    vm.select(2);
    expect(vm.selectedIndex.value, 2);
  });

  test('start uses the chosen preset; errors become a toast', () async {
    await vm.start();
    verify(() => start(classic)).called(1);
    when(
      () => start(any()),
    ).thenAnswer((_) async => left(const AppError.notConnected()));
    await vm.start();
    verify(() => toast.show(any(), level: ToastLevel.error)).called(1);
  });

  test('cannot start while boosting or while a ramp runs', () {
    expect(vm.canStart.value, isTrue);
    status.value = testStatus(heaterMode: HeaterMode.boost);
    expect(vm.canStart.value, isFalse);
    expect(vm.boosting.value, isTrue);
    status.value = testStatus(heaterMode: HeaterMode.normal);
    runs.update(
      RampRun(
        profile: classic,
        deviceId: 'v',
        session: 1,
        target: 185,
        nextTarget: 190,
        nextStepAt: t0.add(const Duration(seconds: 42)),
      ),
    );
    expect(vm.canStart.value, isFalse);
    expect(vm.statusLine.value, 'Now 185° · 190° in 0:42');
    vm.select(0);
    expect(vm.selectedIndex.value, 1);
  });

  test('status line: waiting for boost, then done', () {
    final run = RampRun(
      profile: classic,
      deviceId: 'v',
      session: 1,
      target: 185,
      nextTarget: 190,
      nextStepAt: t0,
      waitingForBoost: true,
    );
    runs.update(run);
    expect(vm.statusLine.value, 'Now 185° · 190° after boost');
    runs.end(
      run.copyWith(
        target: 200,
        clearNextTarget: true,
        phase: RampRunPhase.finished,
      ),
    );
    status.value = testStatus(target: 200, heaterMode: HeaterMode.normal);
    expect(vm.statusLine.value, 'Ramp done · 200°');
    expect(vm.activeRun.value, isNull);
    // Gone once the base was changed by hand.
    status.value = testStatus(target: 190, heaterMode: HeaterMode.normal);
    expect(vm.statusLine.value, '');
    status.value = testStatus(target: 200, heaterMode: HeaterMode.normal);
    // Not on another device.
    activeId.value = 'other';
    expect(vm.statusLine.value, '');
  });

  test('stop goes to the use case', () async {
    await vm.stop();
    verify(() => stop()).called(1);
  });
}
