import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/services/workflow_editing_service.dart';

void main() {
  final service = WorkflowEditingService();

  group('add', () {
    test('first heat step is 185 °C, the next one 10 °C hotter', () {
      final one = service.add(const [], WorkflowStepKind.heat);
      expect(one, [const HeatStep(185)]);
      expect(service.add(one, WorkflowStepKind.heat).last, const HeatStep(195));
    });

    test('hold 30 s and air 45 s', () {
      expect(service.add(const [], WorkflowStepKind.hold), [
        const HoldStep(Duration(seconds: 30)),
      ]);
      expect(service.add(const [], WorkflowStepKind.air), [
        const AirStep(Duration(seconds: 45)),
      ]);
    });

    test('a new heat step stays within 230 °C', () {
      expect(
        service.add(const [HeatStep(225)], WorkflowStepKind.heat).last,
        const HeatStep(230),
      );
    });

    test('stops at the step limit', () {
      final full = List<WorkflowStep>.filled(
        WorkflowEditingService.maxSteps,
        const HeatStep(185),
      );
      expect(service.add(full, WorkflowStepKind.air), same(full));
    });
  });

  test('remove and move', () {
    const steps = [
      HeatStep(170),
      AirStep(Duration(seconds: 45)),
      HeatStep(190),
    ];
    expect(service.remove(steps, 1), [
      const HeatStep(170),
      const HeatStep(190),
    ]);
    expect(service.move(steps, 2, -1), [
      const HeatStep(170),
      const HeatStep(190),
      const AirStep(Duration(seconds: 45)),
    ]);
    expect(service.move(steps, 0, -1), same(steps));
    expect(service.move(steps, 2, 1), same(steps));
  });

  group('adjust', () {
    test('5 °C per tap, clamped to 40–230 °C', () {
      expect(service.adjust(const [HeatStep(185)], 0, 1), [
        const HeatStep(190),
      ]);
      expect(service.adjust(const [HeatStep(228)], 0, 1), [
        const HeatStep(230),
      ]);
      expect(service.adjust(const [HeatStep(42)], 0, -1), [const HeatStep(40)]);
    });

    test('5 s per tap, clamped to 5 s – 10 min', () {
      expect(service.adjust(const [AirStep(Duration(seconds: 45))], 0, 1), [
        const AirStep(Duration(seconds: 50)),
      ]);
      expect(service.adjust(const [HoldStep(Duration(seconds: 5))], 0, -1), [
        const HoldStep(Duration(seconds: 5)),
      ]);
      expect(service.adjust(const [AirStep(Duration(minutes: 10))], 0, 1), [
        const AirStep(Duration(minutes: 10)),
      ]);
    });

    test('an index out of range changes nothing', () {
      const steps = [HeatStep(185)];
      expect(service.adjust(steps, 3, 1), same(steps));
    });
  });

  test('normalise brings stored values into the limits', () {
    expect(service.normalise(const HeatStep(300)), const HeatStep(230));
    expect(
      service.normalise(const AirStep(Duration(seconds: 1))),
      const AirStep(Duration(seconds: 5)),
    );
    expect(
      service.normalise(const HoldStep(Duration(hours: 1))),
      const HoldStep(Duration(minutes: 10)),
    );
  });

  test('canSave needs a name and a step', () {
    expect(service.canSave('Evening', const [HeatStep(185)]), isTrue);
    expect(service.canSave('   ', const [HeatStep(185)]), isFalse);
    expect(service.canSave('Evening', const []), isFalse);
  });
}
