import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/background/domain/models/background_notice.dart';
import 'package:kiln/features/background/domain/repositories/background_service_repository.dart';
import 'package:kiln/features/background/domain/use_cases/alert_ready_use_case.dart';
import 'package:kiln/features/background/domain/use_cases/show_background_session_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

void main() {
  late MockBackgroundServiceDataSource dataSource;
  late BackgroundServiceRepository repository;

  const notice = BackgroundNotice(
    title: 'Veazy · 180°',
    text: 'Heating to 180°',
    sessionChannel: 'Running session',
    readyChannel: 'Ready alerts',
  );

  setUp(() {
    dataSource = MockBackgroundServiceDataSource();
    when(() => dataSource.isSupported).thenReturn(true);
    when(
      () => dataSource.requestNotificationPermission(),
    ).thenAnswer((_) async => true);
    when(
      () => dataSource.start(
        title: any(named: 'title'),
        text: any(named: 'text'),
        sessionChannel: any(named: 'sessionChannel'),
        readyChannel: any(named: 'readyChannel'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => dataSource.update(
        title: any(named: 'title'),
        text: any(named: 'text'),
      ),
    ).thenAnswer((_) async {});
    when(() => dataSource.stop()).thenAnswer((_) async {});
    repository = BackgroundServiceRepository(dataSource: dataSource);
  });

  test(
    'first show asks for permission and starts; later ones update',
    () async {
      await repository.show(notice);
      await repository.show(notice);
      await repository.show(
        const BackgroundNotice(
          title: 'Veazy · 180°',
          text: 'Ready at 180°',
          sessionChannel: 'Running session',
          readyChannel: 'Ready alerts',
        ),
      );
      verify(() => dataSource.requestNotificationPermission()).called(1);
      verify(
        () => dataSource.start(
          title: 'Veazy · 180°',
          text: 'Heating to 180°',
          sessionChannel: 'Running session',
          readyChannel: 'Ready alerts',
        ),
      ).called(1);
      verify(
        () => dataSource.update(title: 'Veazy · 180°', text: 'Ready at 180°'),
      ).called(1);
      expect(repository.running.value, isTrue);
    },
  );

  test('hide stops a running service only', () async {
    await repository.hide();
    verifyNever(() => dataSource.stop());
    await repository.show(notice);
    await repository.hide();
    verify(() => dataSource.stop()).called(1);
    expect(repository.running.value, isFalse);
  });

  test('a hide during a start waiting for permission is not lost', () async {
    final permission = Completer<bool>();
    when(
      () => dataSource.requestNotificationPermission(),
    ).thenAnswer((_) => permission.future);
    final showing = repository.show(notice);
    final hiding = repository.hide();
    permission.complete(false);
    await showing;
    await hiding;
    verify(() => dataSource.stop()).called(1);
    expect(repository.running.value, isFalse);
  });

  test(
    'a refused start (kiln in the background) is an error, not running',
    () async {
      when(
        () => dataSource.start(
          title: any(named: 'title'),
          text: any(named: 'text'),
          sessionChannel: any(named: 'sessionChannel'),
          readyChannel: any(named: 'readyChannel'),
        ),
      ).thenThrow(PlatformException(code: 'not_allowed'));
      expect((await repository.show(notice)).isLeft(), isTrue);
      expect(repository.running.value, isFalse);
    },
  );

  test(
    'reset stops a leftover service; dismissAlert cancels the alert',
    () async {
      when(() => dataSource.cancelAlert()).thenAnswer((_) async {});
      await repository.reset();
      verify(() => dataSource.stop()).called(1);
      expect(repository.running.value, isFalse);
      await repository.dismissAlert();
      verify(() => dataSource.cancelAlert()).called(1);
    },
  );

  test('does nothing where it is not supported', () async {
    when(() => dataSource.isSupported).thenReturn(false);
    expect(await repository.show(notice), right<AppError, Unit>(unit));
    expect(await repository.alert(notice), right<AppError, Unit>(unit));
    verifyNever(() => dataSource.requestNotificationPermission());
  });

  test('use cases: show with a notice, hide without; alert', () async {
    when(
      () => dataSource.alert(
        title: any(named: 'title'),
        text: any(named: 'text'),
        sessionChannel: any(named: 'sessionChannel'),
        readyChannel: any(named: 'readyChannel'),
      ),
    ).thenAnswer((_) async {});
    final show = ShowBackgroundSessionUseCase(repository: repository);
    await show(notice);
    expect(repository.running.value, isTrue);
    await show(null);
    expect(repository.running.value, isFalse);
    await AlertReadyUseCase(repository: repository)(notice);
    verify(
      () => dataSource.alert(
        title: 'Veazy · 180°',
        text: 'Heating to 180°',
        sessionChannel: 'Running session',
        readyChannel: 'Ready alerts',
      ),
    ).called(1);
  });
}
