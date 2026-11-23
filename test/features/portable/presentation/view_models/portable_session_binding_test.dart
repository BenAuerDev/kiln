import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kiln/core/errors/app_error.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/portable/presentation/view_models/portable_session_binding.dart';
import 'package:mocktail/mocktail.dart';

import '../presentation_mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(ToastLevel.info);
    registerFallbackValue(DeviceModel.veazy);
  });

  late BindingHarness h;
  late PortableSessionBinding binding;

  setUp(() {
    h = BindingHarness();
    binding = h.binding();
  });

  tearDown(() => binding.dispose());

  group('session', () {
    test('does not start while disconnected', () async {
      await pumpEventQueue();
      verifyNever(() => h.startSession(any(), any()));
    });

    test('starts for a connected Veazy', () async {
      await h.connect();

      verify(() => h.startSession(deviceId, DeviceModel.veazy)).called(1);
      expect(binding.controlsEnabled.value, isTrue);
      expect(binding.deviceName.value, 'Veazy');
    });

    test('starts for a connected Venty', () async {
      binding.dispose();
      h = BindingHarness(
        device: const KnownDevice(
          id: deviceId,
          name: 'Venty',
          model: DeviceModel.venty,
        ),
      );
      binding = h.binding();

      await h.connect();

      verify(() => h.startSession(deviceId, DeviceModel.venty)).called(1);
    });

    for (final model in [DeviceModel.volcanoHybrid, DeviceModel.craftyPlus]) {
      test('never starts for ${model.name}', () async {
        binding.dispose();
        h = BindingHarness(
          device: KnownDevice(id: deviceId, name: 'Other', model: model),
        );
        binding = h.binding();

        await h.connect();

        verifyNever(() => h.startSession(any(), any()));
      });
    }

    test('waits until the device is known', () async {
      binding.dispose();
      h = BindingHarness(device: null);
      binding = h.binding();

      await h.connect();

      verifyNever(() => h.startSession(any(), any()));
      expect(binding.deviceName.value, strings.portableDefaultName);
    });

    test('stops when the connection goes away', () async {
      await h.connect();

      h.connectionStatus.value = ConnectionStatus.reconnecting;
      await pumpEventQueue();

      verify(() => h.stopSession()).called(1);
    });

    test('does not stop on dispose', () async {
      await h.connect();

      binding.dispose();

      verifyNever(() => h.stopSession());
      binding = h.binding();
    });

    test('shows a toast when the start fails', () async {
      when(
        () => h.startSession(any(), any()),
      ).thenAnswer((_) async => left(const AppError.timeout()));

      await h.connect();

      verify(
        () => h.toasts.show(strings.errorTimeout, level: ToastLevel.error),
      ).called(1);
    });

    test('stays quiet when a start was superseded', () async {
      when(
        () => h.startSession(any(), any()),
      ).thenAnswer((_) async => left(const AppError.notConnected()));

      await h.connect();

      h.verifyNoToast();
    });
  });

  group('step', () {
    setUp(() => h.connect());

    test('ticks per step and confirms once after they settle', () async {
      var value = 180;
      Future<Either<AppError, Option<int>>> adjust() async =>
          right(some(++value));

      final first = binding.step(adjust);
      final second = binding.step(adjust);

      verify(() => h.haptics.tick()).called(2);
      await Future.wait([first, second]);
      verifyNever(() => h.haptics.success());

      await Future<void>.delayed(const Duration(milliseconds: 30));

      h.verifySaved(1);
    });

    test('runs writes one after another', () async {
      final order = <String>[];
      Future<Either<AppError, Option<int>>> slow() async {
        order.add('slow start');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        order.add('slow end');
        return right(some(1));
      }

      Future<Either<AppError, Option<int>>> fast() async {
        order.add('fast');
        return right(some(2));
      }

      await Future.wait([binding.step(slow), binding.step(fast)]);

      expect(order, ['slow start', 'slow end', 'fast']);
    });

    test('a clamped step warns but does not confirm', () async {
      await binding.step(() async => right(none()));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => h.haptics.warning()).called(1);
      verifyNever(() => h.haptics.success());
      h.verifyNoToast();
    });

    test('an error shows a toast and no confirmation', () async {
      await binding.step(
        () async => left(const AppError.writeNotVerified('boost')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => h.haptics.warning()).called(1);
      verify(
        () => h.toasts.show(
          strings.errorWriteNotVerified,
          level: ToastLevel.error,
        ),
      ).called(1);
      verifyNever(() => h.haptics.success());
    });

    test('no confirmation after dispose', () async {
      await binding.step(() async => right(some(181)));
      binding.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verifyNever(() => h.haptics.success());
      binding = h.binding();
    });
  });
}
