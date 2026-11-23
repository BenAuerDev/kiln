import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/volcano/presentation/view_models/volcano_session_sync.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../mocks.dart';

void main() {
  late MockConnectionRepository connection;
  late MockVolcanoRepository repository;
  late MockStartVolcanoSessionUseCase start;
  late MockStopVolcanoSessionUseCase stop;
  late Signal<String?> activeId;
  late Signal<ConnectionStatus> status;
  late Signal<bool> sessionActive;
  late List<AppError> errors;

  setUp(() {
    connection = MockConnectionRepository();
    repository = MockVolcanoRepository();
    start = MockStartVolcanoSessionUseCase();
    stop = MockStopVolcanoSessionUseCase();
    activeId = signal('v');
    status = signal(ConnectionStatus.connected);
    sessionActive = signal(false);
    errors = [];
    when(() => connection.activeDeviceId).thenReturn(activeId);
    when(() => connection.status).thenReturn(status);
    when(() => repository.sessionActive).thenReturn(sessionActive);
    when(() => start(any())).thenAnswer((_) async => right(unit));
    when(() => stop()).thenAnswer((_) async => right(unit));
  });

  VolcanoSessionSync build() => VolcanoSessionSync(
    connection: connection,
    repository: repository,
    startSession: start,
    stopSession: stop,
    onError: errors.add,
  );

  test('starts the session while connected, stops it after', () async {
    final sync = build();
    verify(() => start('v')).called(1);
    sessionActive.value = true;
    status.value = ConnectionStatus.disconnected;
    verify(() => stop()).called(1);
    sync.dispose();
  });

  test('passes start errors on, except a superseded start', () async {
    when(
      () => start(any()),
    ).thenAnswer((_) async => left(const AppError.timeout()));
    final sync = build();
    await pumpEventQueue();
    expect(errors.single, isA<TimeoutError>());

    when(
      () => start(any()),
    ).thenAnswer((_) async => left(const AppError.notConnected()));
    status.value = ConnectionStatus.reconnecting;
    status.value = ConnectionStatus.connected;
    await pumpEventQueue();
    expect(errors, hasLength(1));
    sync.dispose();
  });
}
