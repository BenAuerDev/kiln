import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/l10n/l10n_service.dart';
import 'package:kiln/features/home_widgets/domain/models/portable_widget_content.dart';
import 'package:kiln/features/home_widgets/domain/models/portable_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/domain/models/ramp_widget_content.dart';
import 'package:kiln/features/home_widgets/domain/models/ramp_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/domain/models/volcano_widget_content.dart';
import 'package:kiln/features/home_widgets/presentation/extensions/ramp_widget_snapshot_x.dart';
import 'package:kiln/features/home_widgets/domain/models/volcano_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/presentation/view_models/home_widgets_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../mocks.dart';

void main() {
  late Signal<PortableWidgetSnapshot?> portable;
  late Signal<VolcanoWidgetSnapshot?> volcano;
  late MockCurrentVolcanoWidgetUseCase currentVolcano;
  late MockShowPortableWidgetUseCase showPortable;
  late MockShowVolcanoWidgetUseCase showVolcano;
  late MockListenToHomeWidgetActionsUseCase listen;
  late Signal<RampWidgetSnapshot?> ramp;
  late MockShowRampWidgetUseCase showRamp;
  late MockLoadRampsUseCase loadRamps;
  late L10nService l10n;
  late HomeWidgetsViewModel vm;
  var disposed = false;

  setUpAll(() {
    registerFallbackValue(portableContent);
    registerFallbackValue(rampSnapshot.content(en));
  });

  setUp(() {
    disposed = false;
    portable = signal(null);
    volcano = signal(null);
    final currentPortable = MockCurrentPortableWidgetUseCase();
    when(() => currentPortable()).thenAnswer((_) => portable.value);
    currentVolcano = MockCurrentVolcanoWidgetUseCase();
    when(
      () => currentVolcano(previous: any(named: 'previous')),
    ).thenAnswer((_) => volcano.value);
    showPortable = MockShowPortableWidgetUseCase();
    when(
      () => showPortable(any(), live: any(named: 'live')),
    ).thenAnswer((_) async => right(unit));
    showVolcano = MockShowVolcanoWidgetUseCase();
    when(
      () => showVolcano(any(), live: any(named: 'live')),
    ).thenAnswer((_) async => right(unit));
    listen = MockListenToHomeWidgetActionsUseCase();
    ramp = signal(null);
    final currentRamp = MockCurrentRampWidgetUseCase();
    when(() => currentRamp()).thenAnswer((_) => ramp.value);
    showRamp = MockShowRampWidgetUseCase();
    when(
      () => showRamp(any(), live: any(named: 'live')),
    ).thenAnswer((_) async => right(unit));
    loadRamps = MockLoadRampsUseCase();
    when(() => loadRamps()).thenAnswer((_) async => right(unit));
    l10n = L10nService()..updateLocale(const Locale('en'));
    vm = HomeWidgetsViewModel(
      currentPortable: currentPortable,
      currentVolcano: currentVolcano,
      showPortable: showPortable,
      showVolcano: showVolcano,
      currentRamp: currentRamp,
      showRamp: showRamp,
      loadRamps: loadRamps,
      listenToActions: listen,
      l10n: l10n,
    );
  });

  tearDown(() {
    if (!disposed) vm.dispose();
  });

  test('takes every widget offline at start and loads the ramps', () {
    verify(() => showPortable(null, live: false)).called(1);
    verify(() => showVolcano(null, live: false)).called(1);
    verify(() => showRamp(null, live: false)).called(1);
    verify(() => loadRamps()).called(1);
  });

  test('ramp: live while connected, last values after', () {
    clearInteractions(showRamp);
    ramp.value = rampSnapshot;
    final content =
        verify(() => showRamp(captureAny(), live: true)).captured.single
            as RampWidgetContent;
    expect(content.name, 'Classic');
    expect(content.buttonLabel, 'Stop ramp');

    ramp.value = null;
    verify(() => showRamp(content, live: false)).called(1);
  });

  test('portable: live while connected, last values after', () {
    clearInteractions(showPortable);
    portable.value = veazySnapshot;
    final content =
        verify(() => showPortable(captureAny(), live: true)).captured.single
            as PortableWidgetContent;
    expect(content.battery, '72%');
    expect(content.status, 'Heating to 180°');

    portable.value = null;
    verify(() => showPortable(content, live: false)).called(1);
  });

  test('a language change re-sends the texts, also while offline', () {
    portable.value = veazySnapshot;
    portable.value = null;
    volcano.value = volcanoSnapshot;
    volcano.value = null;
    clearInteractions(showPortable);
    clearInteractions(showVolcano);

    l10n.updateLocale(const Locale('de'));
    final german =
        verify(() => showPortable(captureAny(), live: false)).captured.single
            as PortableWidgetContent;
    expect(german.baseLabel, 'Basis');
    final volcanoGerman =
        verify(() => showVolcano(captureAny(), live: false)).captured.single
            as VolcanoWidgetContent;
    expect(volcanoGerman.offlineStatus, 'Nicht verbunden');
  });

  test('volcano: live while connected, keeps its content offline', () {
    clearInteractions(showVolcano);
    volcano.value = volcanoSnapshot;
    final content =
        verify(() => showVolcano(captureAny(), live: true)).captured.single
            as VolcanoWidgetContent;
    expect(content.temperature, '142°');

    volcano.value = null;
    verify(() => showVolcano(content, live: false)).called(1);
  });

  test('passes the previous Volcano snapshot on', () {
    volcano.value = volcanoSnapshot;
    volcano.value = null;
    final previous = verify(
      () => currentVolcano(previous: captureAny(named: 'previous')),
    ).captured;
    expect(previous, [null, null, volcanoSnapshot]);
  });

  test('listens to widget buttons until disposed', () {
    verify(() => listen(listen: true)).called(1);
    vm.dispose();
    disposed = true;
    verify(() => listen(listen: false)).called(1);
  });
}
