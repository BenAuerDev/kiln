import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/home_widgets/data/models/portable_widget_dto.dart';
import 'package:kiln/features/home_widgets/data/models/ramp_widget_dto.dart';
import 'package:kiln/features/home_widgets/data/models/volcano_widget_dto.dart';
import 'package:kiln/features/home_widgets/presentation/extensions/ramp_widget_snapshot_x.dart';
import 'package:kiln/features/home_widgets/domain/models/home_widget_action.dart';
import 'package:kiln/features/home_widgets/domain/repositories/home_widgets_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

class _FakePortableDto extends Fake implements PortableWidgetDto {}

class _FakeVolcanoDto extends Fake implements VolcanoWidgetDto {}

class _FakeRampDto extends Fake implements RampWidgetDto {}

void main() {
  late MockHomeWidgetDataSource dataSource;
  late HomeWidgetsRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakePortableDto());
    registerFallbackValue(_FakeVolcanoDto());
    registerFallbackValue(_FakeRampDto());
  });

  setUp(() {
    dataSource = MockHomeWidgetDataSource();
    when(() => dataSource.isSupported).thenReturn(true);
    when(() => dataSource.savePortable(any())).thenAnswer((_) async {});
    when(() => dataSource.savePortableLive(any())).thenAnswer((_) async {});
    when(() => dataSource.saveVolcano(any())).thenAnswer((_) async {});
    when(() => dataSource.saveVolcanoLive(any())).thenAnswer((_) async {});
    when(() => dataSource.updatePortable()).thenAnswer((_) async {});
    when(() => dataSource.updateVolcano()).thenAnswer((_) async {});
    when(() => dataSource.saveRamp(any())).thenAnswer((_) async {});
    when(() => dataSource.saveRampLive(any())).thenAnswer((_) async {});
    when(() => dataSource.updateRamp()).thenAnswer((_) async {});
    repository = HomeWidgetsRepository(dataSource: dataSource);
  });

  group('portable', () {
    test('saves content and live flag, then skips the unchanged', () async {
      expect(
        await repository.showPortable(portableContent, live: true),
        right(unit),
      );
      expect(
        await repository.showPortable(portableContent, live: true),
        right(unit),
      );

      final dto =
          verify(() => dataSource.savePortable(captureAny())).captured.single
              as PortableWidgetDto;
      expect(dto.name, 'Veazy');
      expect(dto.boost, '195°');
      expect(dto.heatLabel, 'Heat off');
      verify(() => dataSource.savePortableLive(true)).called(1);
      verify(() => dataSource.updatePortable()).called(1);
      expect(repository.portable.value, portableContent);
    });

    test('offline keeps the content and only writes the flag', () async {
      await repository.showPortable(portableContent, live: true);
      clearInteractions(dataSource);
      await repository.showPortable(portableContent, live: false);
      verifyNever(() => dataSource.savePortable(any()));
      verify(() => dataSource.savePortableLive(false)).called(1);
      verify(() => dataSource.updatePortable()).called(1);
    });

    test('a failed save is a storage error and is retried next time', () async {
      when(() => dataSource.savePortable(any())).thenThrow(StateError('x'));
      expect(
        await repository.showPortable(portableContent, live: true),
        left(const AppError.storage()),
      );
      expect(repository.portable.value, isNull);

      when(() => dataSource.savePortable(any())).thenAnswer((_) async {});
      expect(
        await repository.showPortable(portableContent, live: true),
        right(unit),
      );
      verify(() => dataSource.updatePortable()).called(1);
    });
  });

  test('ramp: saves content and live flag, then skips the unchanged', () async {
    final content = rampSnapshot.content(en);
    expect(await repository.showRamp(content, live: true), right(unit));
    final dto =
        verify(() => dataSource.saveRamp(captureAny())).captured.single
            as RampWidgetDto;
    expect(dto.toJson()['countdownFormat'], '190° in %s');
    expect(dto.toJson()['nextStepAtMillis'], rampDue.millisecondsSinceEpoch);
    verify(() => dataSource.saveRampLive(true)).called(1);
    verify(() => dataSource.updateRamp()).called(1);
    expect(repository.ramp.value, content);

    await repository.showRamp(content, live: true);
    verifyNever(() => dataSource.saveRamp(any()));
    verifyNever(() => dataSource.updateRamp());

    // Offline: the content stays, only the flag is written.
    await repository.showRamp(content, live: false);
    verifyNever(() => dataSource.saveRamp(any()));
    verify(() => dataSource.saveRampLive(false)).called(1);
    verify(() => dataSource.updateRamp()).called(1);
  });

  group('volcano', () {
    test('the first offline of a run is always written', () async {
      expect(await repository.showVolcano(null, live: false), right(unit));
      expect(await repository.showVolcano(null, live: false), right(unit));
      verify(() => dataSource.saveVolcanoLive(false)).called(1);
      verify(() => dataSource.updateVolcano()).called(1);
      verifyNever(() => dataSource.saveVolcano(any()));
    });

    test('without content it is never live', () async {
      await repository.showVolcano(null, live: true);
      verify(() => dataSource.saveVolcanoLive(false)).called(1);
    });

    test('goes live with content, sends only what changed', () async {
      await repository.showVolcano(volcanoContent(), live: true);
      verifyInOrder([
        () => dataSource.saveVolcano(any()),
        () => dataSource.saveVolcanoLive(true),
        () => dataSource.updateVolcano(),
      ]);

      await repository.showVolcano(volcanoContent(), live: true);
      verifyNever(() => dataSource.updateVolcano());

      await repository.showVolcano(
        volcanoContent(temperature: 150),
        live: true,
      );
      verify(() => dataSource.saveVolcano(any())).called(1);
      verifyNever(() => dataSource.saveVolcanoLive(any()));
      verify(() => dataSource.updateVolcano()).called(1);
      expect(repository.volcano.value, volcanoContent(temperature: 150));
    });

    test('after a failed write everything is written again', () async {
      when(() => dataSource.updateVolcano()).thenThrow(StateError('x'));
      expect(
        await repository.showVolcano(volcanoContent(), live: true),
        left(const AppError.storage()),
      );
      expect(repository.volcano.value, isNull);

      when(() => dataSource.updateVolcano()).thenAnswer((_) async {});
      clearInteractions(dataSource);
      expect(
        await repository.showVolcano(volcanoContent(), live: true),
        right(unit),
      );
      verify(() => dataSource.saveVolcano(any())).called(1);
      verify(() => dataSource.saveVolcanoLive(true)).called(1);
    });
  });

  test('writes run one after another', () async {
    final gate = Completer<void>();
    when(
      () => dataSource.saveVolcanoLive(false),
    ).thenAnswer((_) => gate.future);
    final offline = repository.showVolcano(null, live: false);
    final live = repository.showVolcano(volcanoContent(), live: true);
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => dataSource.saveVolcano(any()));

    gate.complete();
    expect(await offline, right(unit));
    expect(await live, right(unit));
    verifyInOrder([
      () => dataSource.saveVolcanoLive(false),
      () => dataSource.updateVolcano(),
      () => dataSource.saveVolcano(any()),
      () => dataSource.saveVolcanoLive(true),
      () => dataSource.updateVolcano(),
    ]);
  });

  test('does nothing where widgets are not supported', () async {
    when(() => dataSource.isSupported).thenReturn(false);
    await repository.showPortable(portableContent, live: true);
    await repository.showVolcano(volcanoContent(), live: true);
    verifyNever(() => dataSource.updatePortable());
    verifyNever(() => dataSource.updateVolcano());
  });

  test('maps button names to actions and drops unknown ones', () async {
    Future<void> Function(String)? installed;
    when(() => dataSource.setActionHandler(any())).thenAnswer((invocation) {
      installed =
          invocation.positionalArguments.single
              as Future<void> Function(String)?;
    });
    final received = <HomeWidgetAction>[];
    repository.setActionHandler((action) async => received.add(action));
    for (final name in ['volcanoAir', 'x', 'portableBoost']) {
      await installed!(name);
    }
    expect(received, [
      HomeWidgetAction.volcanoAir,
      HomeWidgetAction.portableBoost,
    ]);

    repository.setActionHandler(null);
    expect(installed, isNull);
  });
}
