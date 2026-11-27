import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/ramps/domain/models/ramp_field.dart';
import 'package:kiln/features/ramps/domain/models/ramp_profile.dart';
import 'package:kiln/features/ramps/domain/services/ramp_editing_service.dart';

void main() {
  final editing = RampEditingService();

  RampProfile ramp({
    int start = 180,
    int end = 200,
    int step = 5,
    Duration interval = const Duration(seconds: 90),
  }) => RampProfile(
    id: '',
    startCelsius: start,
    endCelsius: end,
    stepCelsius: step,
    interval: interval,
  );

  group('adjust', () {
    test('temperatures by 5°, step by 1°, interval by 15 s', () {
      expect(editing.adjust(ramp(), RampField.start, 1).startCelsius, 185);
      expect(editing.adjust(ramp(), RampField.end, -1).endCelsius, 195);
      expect(editing.adjust(ramp(), RampField.step, 1).stepCelsius, 6);
      expect(
        editing.adjust(ramp(), RampField.interval, -1).interval,
        const Duration(seconds: 75),
      );
    });

    test('raising the start past the end pushes the end up', () {
      final next = editing.adjust(ramp(end: 185), RampField.start, 1);
      expect([next.startCelsius, next.endCelsius], [185, 190]);
    });

    test('lowering the end below the start pulls the start down', () {
      final next = editing.adjust(
        ramp(start: 180, end: 185),
        RampField.end,
        -1,
      );
      expect([next.startCelsius, next.endCelsius], [175, 180]);
    });

    test('stays within 40–210 °C, the step and interval limits', () {
      expect(
        editing.adjust(ramp(start: 205, end: 210), RampField.start, 1),
        ramp(start: 205, end: 210),
      );
      expect(
        editing.adjust(ramp(start: 40, end: 45), RampField.end, -1),
        ramp(start: 40, end: 45),
      );
      expect(editing.adjust(ramp(step: 1), RampField.step, -1).stepCelsius, 1);
      expect(editing.adjust(ramp(step: 25), RampField.step, 1).stepCelsius, 25);
      expect(
        editing
            .adjust(
              ramp(interval: const Duration(seconds: 15)),
              RampField.interval,
              -1,
            )
            .interval,
        const Duration(seconds: 15),
      );
      expect(
        editing
            .adjust(
              ramp(interval: const Duration(minutes: 10)),
              RampField.interval,
              1,
            )
            .interval,
        const Duration(minutes: 10),
      );
    });

    test('never moves a value against the tap', () {
      // 209 is off the 5° grid; clamping a raise would give 205.
      final odd = ramp(start: 209, end: 210);
      expect(identical(editing.adjust(odd, RampField.start, 1), odd), isTrue);
    });

    test('returns the same ramp when nothing changes', () {
      final top = ramp(step: 25);
      expect(identical(editing.adjust(top, RampField.step, 1), top), isTrue);
    });
  });

  test('normalise clamps everything and keeps the end above the start', () {
    final fixed = editing.normalise(
      ramp(start: 230, end: 20, step: 0, interval: Duration.zero),
    );
    expect(fixed.startCelsius, 209);
    expect(fixed.endCelsius, 210);
    expect(fixed.stepCelsius, 1);
    expect(fixed.interval, const Duration(seconds: 15));
  });

  test('can save with a name and the end above the start', () {
    expect(editing.canSave('Evening', ramp()), isTrue);
    expect(editing.canSave('  ', ramp()), isFalse);
    expect(editing.canSave('Evening', ramp(start: 200, end: 200)), isFalse);
  });
}
