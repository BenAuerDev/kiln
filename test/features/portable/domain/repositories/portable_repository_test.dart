import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/ble/ble_connection_state.dart';
import 'package:kiln/core/ble/ble_exceptions.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/portable/data/data_sources/portable_ble_data_source.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_settings.dart';
import 'package:kiln/features/portable/domain/models/portable_status.dart';
import 'package:kiln/features/portable/domain/repositories/portable_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/portable_fixtures.dart';

class MockPortableBleDataSource extends Mock implements PortableBleDataSource {}

const _id = 'AA:BB';

final _firmwareRequest = packet({0: 0x02});
final _statusPoll = packet({0: 0x01});
const _settingsRead = [6, 0, 0, 0, 0, 0, 0];

void main() {
  late MockPortableBleDataSource dataSource;
  late StreamController<List<int>> notifications;
  late StreamController<BleConnectionState> connection;
  late List<List<int>> writes;
  late List<int>? Function(List<int> request) replyTo;
  late PortableRepository repository;

  PortableRepository build({
    Duration pollInterval = const Duration(hours: 1),
    Duration writeHold = const Duration(milliseconds: 1500),
  }) => PortableRepository(
    dataSource: dataSource,
    pollInterval: pollInterval,
    replyTimeout: const Duration(seconds: 2),
    firmwareInfoAttempts: 3,
    writeHold: writeHold,
  );

  setUp(() {
    dataSource = MockPortableBleDataSource();
    notifications = StreamController<List<int>>();
    connection = StreamController<BleConnectionState>.broadcast();
    writes = [];
    replyTo = (request) => request[0] == 0x02 ? firmwareReply() : null;
    when(
      () => dataSource.subscribe(_id),
    ).thenAnswer((_) => notifications.stream);
    when(() => dataSource.enableNotifications(any())).thenAnswer((_) async {});
    when(
      () => dataSource.connectionState(any()),
    ).thenAnswer((_) => connection.stream);
    when(() => dataSource.write(_id, any())).thenAnswer((invocation) async {
      final bytes = invocation.positionalArguments[1] as List<int>;
      writes.add(bytes);
      final reply = replyTo(bytes);
      if (reply != null) notifications.add(reply);
    });
    repository = build();
  });

  // Not awaited: close() never completes for a stream nobody listened to.
  tearDown(() => unawaited(notifications.close()));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Starts a Veazy session and feeds one status packet.
  Future<void> startWithStatus(
    List<int> status, {
    DeviceModel model = DeviceModel.veazy,
  }) async {
    final result = await repository.startSession(_id, model);
    expect(result.isRight(), isTrue);
    notifications.add(status);
    await settle();
    writes.clear();
    clearInteractions(dataSource);
  }

  group('connection loss', () {
    test('ends the session when the link drops', () async {
      await startWithStatus(statusPacket());

      connection.add(BleConnectionState.disconnected);
      await settle();

      expect(repository.sessionActive.value, isFalse);
      expect(repository.status.value, isNull);
    });

    test('a new start after a drop runs the init again', () async {
      await startWithStatus(statusPacket());
      connection.add(BleConnectionState.disconnected);
      await settle();
      notifications = StreamController<List<int>>();

      final result = await repository.startSession(_id, DeviceModel.veazy);

      expect(result.isRight(), isTrue);
      expect(writes, [_firmwareRequest, _statusPoll, _settingsRead]);
    });
  });

  group('readColorIndex', () {
    List<int> identityReply({int? color}) {
      final reply = List<int>.filled(color == null ? 18 : 20, 0)..[0] = 0x05;
      if (color != null) reply[18] = color;
      return reply;
    }

    test('sends 05 and returns the colour byte of the reply', () async {
      await startWithStatus(statusPacket());
      replyTo = (request) =>
          request[0] == 0x05 ? identityReply(color: 3) : null;

      final result = await repository.readColorIndex();

      expect(result.getRight().toNullable()?.toNullable(), 3);
      expect(writes, [
        packet({0: 0x05}),
      ]);
    });

    test('returns none() when the reply has no colour byte', () async {
      await startWithStatus(statusPacket());
      replyTo = (request) => request[0] == 0x05 ? identityReply() : null;

      final result = await repository.readColorIndex();

      expect(result.getRight().toNullable()?.isNone(), isTrue);
    });

    test('times out when the device does not answer', () {
      fakeAsync((async) {
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        replyTo = (_) => null;

        Either<AppError, Option<int>>? result;
        repository.readColorIndex().then((r) => result = r);
        async.elapse(const Duration(seconds: 3));

        expect(result?.getLeft().toNullable(), isA<TimeoutError>());
      });
    });

    test('needs an active session', () async {
      final result = await repository.readColorIndex();

      expect(result.getLeft().toNullable(), isA<NotConnectedError>());
      expect(writes, isEmpty);
    });
  });

  group('startSession', () {
    test('runs the verified init sequence and activates the session', () async {
      final result = await repository.startSession(_id, DeviceModel.veazy);

      expect(result, right<AppError, Unit>(unit));
      expect(repository.sessionActive.value, isTrue);
      expect(writes, [_firmwareRequest, _statusPoll, _settingsRead]);
    });

    test('is idempotent for the same device', () async {
      await repository.startSession(_id, DeviceModel.veazy);
      final result = await repository.startSession(_id, DeviceModel.veazy);

      expect(result.isRight(), isTrue);
      expect(writes.where((w) => w[0] == 0x02), hasLength(1));
      verify(() => dataSource.subscribe(_id)).called(1);
    });

    test('concurrent starts for the same device share one init', () async {
      final first = repository.startSession(_id, DeviceModel.venty);
      final second = repository.startSession(_id, DeviceModel.venty);

      expect(await first, right<AppError, Unit>(unit));
      expect(await second, right<AppError, Unit>(unit));
      expect(writes, [_firmwareRequest, _statusPoll, _settingsRead]);
    });

    test('aborts in bootloader mode and sends nothing else', () async {
      replyTo = (request) => firmwareReply(flags: 0x10);

      final result = await repository.startSession(_id, DeviceModel.veazy);

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
      expect(repository.sessionActive.value, isFalse);
      expect(writes, [_firmwareRequest]);
    });

    test('rejects non-portable models without BLE I/O', () async {
      final result = await repository.startSession(
        _id,
        DeviceModel.volcanoHybrid,
      );

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
      verifyNever(() => dataSource.subscribe(any()));
    });

    test('maps a failing write to an AppError', () async {
      when(
        () => dataSource.write(_id, any()),
      ).thenThrow(const BleConnectionException('gone'));

      final result = await repository.startSession(_id, DeviceModel.veazy);

      expect(result.getLeft().toNullable(), isA<ConnectionFailedError>());
      expect(repository.sessionActive.value, isFalse);
    });

    test('maps a notification error during init to an AppError', () async {
      replyTo = (_) => null;
      when(() => dataSource.subscribe(_id)).thenAnswer(
        (_) => Stream.error(const BleCharacteristicNotFoundException('char')),
      );

      final result = await repository.startSession(_id, DeviceModel.veazy);

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
    });

    test('retries the firmware request when the first reply is lost', () {
      fakeAsync((async) {
        var requests = 0;
        replyTo = (request) =>
            request[0] == 0x02 && ++requests == 2 ? firmwareReply() : null;
        Either<AppError, Unit>? result;

        repository.startSession(_id, DeviceModel.veazy).then((r) => result = r);
        async.elapse(const Duration(seconds: 3));

        expect(result, right<AppError, Unit>(unit));
        expect(writes.where((w) => w[0] == 0x02), hasLength(2));
      });
    });

    test('times out when the device never answers', () {
      fakeAsync((async) {
        replyTo = (_) => null;
        Either<AppError, Unit>? result;

        repository.startSession(_id, DeviceModel.veazy).then((r) => result = r);
        async.elapse(const Duration(seconds: 30));

        expect(result?.getLeft().toNullable(), isA<TimeoutError>());
        expect(writes, List.filled(3, _firmwareRequest));
        expect(repository.sessionActive.value, isFalse);
      });
    });

    test('stopSession during init cancels it without further writes', () {
      fakeAsync((async) {
        replyTo = (_) => null;
        Either<AppError, Unit>? result;

        repository.startSession(_id, DeviceModel.veazy).then((r) => result = r);
        async.flushMicrotasks();
        repository.stopSession();
        async.elapse(const Duration(seconds: 10));

        expect(result?.getLeft().toNullable(), isA<NotConnectedError>());
        expect(writes, [_firmwareRequest]);
      });
    });

    test('starting another device stops the current session', () async {
      await startWithStatus(statusPacket());
      final other = StreamController<List<int>>();
      addTearDown(other.close);
      when(() => dataSource.subscribe('other')).thenAnswer((_) => other.stream);
      when(() => dataSource.write('other', any())).thenAnswer((_) async {
        other.add(firmwareReply());
      });

      final result = await repository.startSession('other', DeviceModel.venty);

      expect(result.isRight(), isTrue);
      expect(notifications.hasListener, isFalse);
      expect(repository.status.value, isNull);
    });
  });

  group('polling', () {
    test('polls 01 00 every 500 ms until the session stops', () {
      fakeAsync((async) {
        repository = build(pollInterval: const Duration(milliseconds: 500));
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        writes.clear();

        async.elapse(const Duration(milliseconds: 1600));
        expect(writes, List.filled(3, _statusPoll));

        repository.stopSession();
        async.elapse(const Duration(seconds: 2));
        expect(writes, hasLength(3));
      });
    });

    test('pausing stops the poll but keeps the session', () {
      fakeAsync((async) {
        repository = build(pollInterval: const Duration(milliseconds: 500));
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        writes.clear();

        repository.pausePolling();
        async.elapse(const Duration(seconds: 3));

        expect(writes, isEmpty);
        expect(repository.sessionActive.value, isTrue);
      });
    });

    test('resuming polls at once and then every 500 ms', () {
      fakeAsync((async) {
        repository = build(pollInterval: const Duration(milliseconds: 500));
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        repository.pausePolling();
        writes.clear();

        repository.resumePolling();
        async.flushMicrotasks();
        expect(writes, [_statusPoll]);

        async.elapse(const Duration(milliseconds: 1100));
        expect(writes, List.filled(3, _statusPoll));
      });
    });

    test('a session started while paused does not poll until resumed', () {
      fakeAsync((async) {
        repository = build(pollInterval: const Duration(milliseconds: 500));
        repository.pausePolling();
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        writes.clear();

        async.elapse(const Duration(seconds: 2));
        expect(writes, isEmpty);

        repository.resumePolling();
        async.flushMicrotasks();
        expect(writes, [_statusPoll]);
      });
    });

    test('resuming twice does not start a second poll', () {
      fakeAsync((async) {
        repository = build(pollInterval: const Duration(milliseconds: 500));
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        writes.clear();

        repository.resumePolling();
        async.elapse(const Duration(milliseconds: 1100));

        expect(writes, List.filled(2, _statusPoll));
      });
    });

    test('keeps polling after a failed poll write', () {
      fakeAsync((async) {
        repository = build(pollInterval: const Duration(milliseconds: 500));
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        when(
          () => dataSource.write(_id, any()),
        ).thenThrow(const BleOperationException('busy'));

        async.elapse(const Duration(milliseconds: 600));
        expect(repository.sessionActive.value, isTrue);
      });
    });
  });

  group('notifications', () {
    test('statusUpdatedAt follows status packets and clears on stop', () async {
      expect(repository.statusUpdatedAt.value, isNull);
      await startWithStatus(statusPacket());
      final first = repository.statusUpdatedAt.value;
      expect(first, isNotNull);
      await repository.stopSession();
      expect(repository.statusUpdatedAt.value, isNull);
    });

    test('sessionNumber goes up with every session start', () async {
      expect(repository.sessionNumber.value, 0);
      await startWithStatus(statusPacket());
      expect(repository.sessionNumber.value, 1);
    });

    test(
      'decode into the status signal (Veazy boost visualisation inverted)',
      () async {
        await startWithStatus(
          statusPacket(
            currentTenths: 1842,
            targetTenths: 1850,
            boost: 12,
            superBoost: 8,
            battery: 64,
            autoOffLow: 30,
            heaterMode: 1,
            charger: 1,
            settings: 0x01 | 0x02 | 0x08 | 0x20,
          ),
        );

        expect(
          repository.status.value,
          const PortableStatus(
            currentTemperature: 184.2,
            targetTemperature: 185,
            boostOffset: 12,
            superBoostOffset: 8,
            batteryPercent: 64,
            charging: true,
            heaterMode: HeaterMode.normal,
            autoOffSeconds: 30,
            settings: PortableSettings(
              fahrenheit: true,
              vibrateWhenReady: false,
              ecoCharge: true,
              ecoVoltage: true,
              boostVisualisation: true,
            ),
            setpointReached: true,
          ),
        );
      },
    );

    test('Venty boost visualisation is not inverted', () async {
      await startWithStatus(
        statusPacket(settings: 0x40),
        model: DeviceModel.venty,
      );

      expect(repository.status.value?.settings.boostVisualisation, isTrue);
    });

    test('0x8000 current temperature becomes null', () async {
      await startWithStatus(statusPacket(currentTenths: 0x8000));

      expect(repository.status.value?.currentTemperature, isNull);
    });

    test('vibration comes from the 0x06 reply', () async {
      replyTo = (request) => switch (request[0]) {
        0x02 => firmwareReply(),
        0x06 => deviceSettingsReply(vibration: true),
        _ => null,
      };
      await startWithStatus(statusPacket());

      expect(repository.status.value?.settings.vibrateWhenReady, isTrue);
    });

    test('target follows the device while not boosting', () async {
      await startWithStatus(statusPacket(targetTenths: 1800, heaterMode: 1));

      notifications.add(statusPacket(targetTenths: 1900, heaterMode: 1));
      await settle();

      expect(repository.status.value?.targetTemperature, 190);
    });

    test('keeps the base while boosting (real Veazy values)', () async {
      // Veazy log: base 185, boost +15, mode 2 reports 200, flag 0x10 always.
      await startWithStatus(
        statusPacket(targetTenths: 1850, heaterMode: 1, settings: 0xB8),
      );

      notifications.add(
        statusPacket(targetTenths: 2000, heaterMode: 2, settings: 0xBA),
      );
      await settle();
      expect(repository.status.value?.targetTemperature, 185);
      expect(repository.status.value?.heaterMode, HeaterMode.boost);

      notifications.add(
        statusPacket(targetTenths: 1850, heaterMode: 1, settings: 0xB8),
      );
      await settle();
      expect(repository.status.value?.targetTemperature, 185);
    });

    test('derives the base when a session starts mid-boost', () async {
      await startWithStatus(
        statusPacket(targetTenths: 2000, boost: 15, heaterMode: 2),
      );

      expect(repository.status.value?.targetTemperature, 185);
    });

    test('derives the base when a session starts mid-superboost', () async {
      await startWithStatus(
        statusPacket(
          targetTenths: 2050,
          boost: 10,
          superBoost: 10,
          heaterMode: 3,
        ),
      );

      expect(repository.status.value?.targetTemperature, 185);
    });

    test('malformed packets are ignored', () async {
      await startWithStatus(statusPacket(boost: 15));

      notifications
        ..add(statusPacket(boost: 3, length: 10))
        ..add(const []);
      await settle();

      expect(repository.status.value?.boostOffset, 15);
      expect(repository.sessionActive.value, isTrue);
    });

    test('a notification error after init ends the session', () async {
      await startWithStatus(statusPacket());

      notifications.addError(const BleConnectionException('lost'));
      await settle();

      expect(repository.sessionActive.value, isFalse);
      expect(repository.status.value, isNull);
    });
  });

  group('writes', () {
    test('without a session return notConnected and do no I/O', () async {
      final results = [
        await repository.setTargetTemperature(180),
        await repository.setBoostOffset(10),
        await repository.setSuperBoostOffset(10),
        await repository.setHeaterMode(HeaterMode.normal),
        await repository.setSettings(testSettings),
        await repository.findDevice(),
      ];

      for (final result in results) {
        expect(result.getLeft().toNullable(), isA<NotConnectedError>());
      }
      expect(writes, isEmpty);
    });

    test(
      'setTargetTemperature writes 01 02 and updates optimistically',
      () async {
        await startWithStatus(statusPacket(targetTenths: 1800));

        final result = await repository.setTargetTemperature(185);

        expect(result.isRight(), isTrue);
        expect(writes, [
          packet({0: 0x01, 1: 0x02, 4: 0x3A, 5: 0x07}),
        ]);
        expect(repository.status.value?.targetTemperature, 185);
      },
    );

    test(
      'setBoostOffset and setSuperBoostOffset write their byte only',
      () async {
        await startWithStatus(statusPacket());

        await repository.setBoostOffset(20);
        await repository.setSuperBoostOffset(5);

        expect(writes, [
          packet({0: 0x01, 1: 0x04, 6: 20}),
          packet({0: 0x01, 1: 0x08, 7: 5}),
        ]);
        expect(repository.status.value?.boostOffset, 20);
        expect(repository.status.value?.superBoostOffset, 5);
      },
    );

    test('a failing write returns Left and keeps the status', () async {
      await startWithStatus(statusPacket(boost: 15));
      when(
        () => dataSource.write(_id, any()),
      ).thenThrow(const BleTimeoutException('write'));

      final result = await repository.setBoostOffset(20);

      expect(result.getLeft().toNullable(), isA<TimeoutError>());
      expect(repository.status.value?.boostOffset, 15);
    });

    test('heater on and off write byte 11', () async {
      await startWithStatus(statusPacket(heaterMode: 0));

      await repository.setHeaterMode(HeaterMode.normal);
      expect(repository.status.value?.heaterMode, HeaterMode.normal);
      await repository.setHeaterMode(HeaterMode.off);

      expect(writes, [
        packet({0: 0x01, 1: 0x20, 11: 1}),
        packet({0: 0x01, 1: 0x20}),
      ]);
      expect(repository.status.value?.heaterMode, HeaterMode.off);
    });

    test('boost writes heater mode 2 and updates optimistically', () async {
      await startWithStatus(statusPacket(heaterMode: 1));

      final result = await repository.setHeaterMode(HeaterMode.boost);

      expect(result.isRight(), isTrue);
      expect(writes, [
        packet({0: 0x01, 1: 0x20, 11: 0x02}),
      ]);
      expect(repository.status.value?.heaterMode, HeaterMode.boost);
    });

    test('superboost writes heater mode 3', () async {
      await startWithStatus(statusPacket(heaterMode: 2));

      final result = await repository.setHeaterMode(HeaterMode.superboost);

      expect(result.isRight(), isTrue);
      expect(writes, [
        packet({0: 0x01, 1: 0x20, 11: 0x03}),
      ]);
      expect(repository.status.value?.heaterMode, HeaterMode.superboost);
    });

    test('target writes are rejected while boosting', () async {
      await startWithStatus(statusPacket(heaterMode: 2));

      final result = await repository.setTargetTemperature(190);

      expect(result.getLeft().toNullable(), isA<WriteNotVerifiedError>());
      expect(writes, isEmpty);
    });

    test('findDevice writes 0D 01', () async {
      await startWithStatus(statusPacket());

      final result = await repository.findDevice();

      expect(result.isRight(), isTrue);
      expect(writes, [
        packet({0: 0x0D, 1: 0x01}),
      ]);
    });

    test('a written field ignores stale poll replies for a moment', () {
      fakeAsync((async) {
        repository.startSession(_id, DeviceModel.veazy);
        async.flushMicrotasks();
        notifications.add(statusPacket(boost: 15));
        async.flushMicrotasks();

        repository.setBoostOffset(20);
        async.flushMicrotasks();
        notifications.add(statusPacket(boost: 15));
        async.flushMicrotasks();
        expect(repository.status.value?.boostOffset, 20);

        async.elapse(const Duration(seconds: 2));
        notifications.add(statusPacket(boost: 15));
        async.flushMicrotasks();
        expect(repository.status.value?.boostOffset, 15);
      });
    });
  });

  group('setSettings', () {
    const deviceSettings = PortableSettings(
      fahrenheit: false,
      vibrateWhenReady: false,
      ecoCharge: false,
      ecoVoltage: false,
      boostVisualisation: false,
    );

    test('writes one packet per changed setting', () async {
      // Veazy with bit 0x40 set = visualisation off.
      await startWithStatus(statusPacket(settings: 0x40));
      expect(repository.status.value?.settings, deviceSettings);

      final result = await repository.setSettings(
        deviceSettings.copyWith(fahrenheit: true, ecoVoltage: true),
      );

      expect(result.isRight(), isTrue);
      expect(writes, [
        packet({0: 0x01, 1: 0x80, 14: 0x01, 15: 0x01}),
        packet({0: 0x01, 1: 0x80, 14: 0x20, 15: 0x20}),
      ]);
      expect(
        repository.status.value?.settings,
        deviceSettings.copyWith(fahrenheit: true, ecoVoltage: true),
      );
    });

    test('inverts boost visualisation on a Veazy', () async {
      await startWithStatus(statusPacket(settings: 0x40));

      await repository.setSettings(
        deviceSettings.copyWith(boostVisualisation: true),
      );

      expect(writes, [
        packet({0: 0x01, 1: 0x80, 15: 0x40}),
      ]);
      expect(repository.status.value?.settings.boostVisualisation, isTrue);
    });

    test('does not invert boost visualisation on a Venty', () async {
      await startWithStatus(statusPacket(), model: DeviceModel.venty);

      await repository.setSettings(
        deviceSettings.copyWith(boostVisualisation: true),
      );

      expect(writes, [
        packet({0: 0x01, 1: 0x80, 14: 0x40, 15: 0x40}),
      ]);
    });

    test('writes vibration through the 0x06 command', () async {
      await startWithStatus(statusPacket(settings: 0x40));

      await repository.setSettings(
        deviceSettings.copyWith(vibrateWhenReady: true),
      );

      expect(writes, [
        [6, 8, 0, 0, 0, 1, 0],
      ]);
      expect(repository.status.value?.settings.vibrateWhenReady, isTrue);
    });

    test('stops at the first failing write', () async {
      await startWithStatus(statusPacket(settings: 0x40));
      when(
        () => dataSource.write(_id, any()),
      ).thenThrow(const BleOperationException('nope'));

      final result = await repository.setSettings(
        deviceSettings.copyWith(fahrenheit: true, ecoCharge: true),
      );

      expect(result.getLeft().toNullable(), isA<ProtocolError>());
      verify(() => dataSource.write(_id, any())).called(1);
      expect(repository.status.value?.settings, deviceSettings);
    });

    test('never sets the factory-reset bit', () async {
      await startWithStatus(statusPacket(settings: 0x40));

      await repository.setSettings(
        const PortableSettings(
          fahrenheit: true,
          vibrateWhenReady: true,
          ecoCharge: true,
          ecoVoltage: true,
          boostVisualisation: true,
        ),
      );

      for (final bytes in writes.where((w) => w[0] == 0x01)) {
        expect(bytes[14] & 0x04, 0);
        expect(bytes[15] & 0x04, 0);
      }
    });
  });

  test('stopSession clears status and session', () async {
    await startWithStatus(statusPacket());

    await repository.stopSession();

    expect(repository.sessionActive.value, isFalse);
    expect(repository.status.value, isNull);
    expect(notifications.hasListener, isFalse);
  });
}
