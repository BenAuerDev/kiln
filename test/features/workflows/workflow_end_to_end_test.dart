// A workflow on the simulated Volcano, through the real BLE client, data
// source, write allow-list and repositories.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/ble/ble_client.dart';
import 'package:kiln/core/ble/demo/ble_simulator.dart';
import 'package:kiln/core/ble/demo/demo_device_ids.dart';
import 'package:kiln/features/devices/data/data_sources/device_connection_data_source.dart';
import 'package:kiln/features/devices/domain/repositories/connection_repository.dart';
import 'package:kiln/features/volcano/data/data_sources/volcano_ble_data_source.dart';
import 'package:kiln/features/volcano/domain/repositories/volcano_repository.dart';
import 'package:kiln/features/workflows/domain/models/workflow.dart';
import 'package:kiln/features/workflows/domain/models/workflow_run.dart';
import 'package:kiln/features/workflows/domain/models/workflow_step.dart';
import 'package:kiln/features/workflows/domain/repositories/workflow_run_repository.dart';
import 'package:kiln/features/workflows/domain/services/workflow_step_service.dart';
import 'package:kiln/features/workflows/domain/use_cases/advance_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/start_workflow_run_use_case.dart';
import 'package:kiln/features/workflows/domain/use_cases/stop_workflow_run_use_case.dart';

/// The demo Volcano behind the real BLE client, connected and in session,
/// with the workflow use cases on a fake clock.
({
  VolcanoRepository volcano,
  WorkflowRunRepository runs,
  StartWorkflowRunUseCase start,
})
_demoVolcano(FakeAsync async) {
  final clock = async.getClock(DateTime(2026, 11, 23, 20));
  final ble = BleClient(BleSimulator());
  final connection = ConnectionRepository(
    dataSource: DeviceConnectionDataSource(ble),
  )..connect(DemoDeviceIds.volcano);
  async.elapse(const Duration(seconds: 1));
  final volcano = VolcanoRepository(dataSource: VolcanoBleDataSource(ble))
    ..startSession(DemoDeviceIds.volcano);
  async.elapse(const Duration(seconds: 1));
  final runs = WorkflowRunRepository();
  final advance = AdvanceWorkflowRunUseCase(
    runs: runs,
    volcano: volcano,
    connection: connection,
    steps: WorkflowStepService(),
    clock: clock.now,
  );
  final start = StartWorkflowRunUseCase(
    runs: runs,
    volcano: volcano,
    connection: connection,
    advance: advance,
    clock: clock.now,
  );
  return (volcano: volcano, runs: runs, start: start);
}

void main() {
  test('heat, air, heat, air, then heater off on the demo Volcano', () {
    fakeAsync((async) {
      final (:volcano, :runs, :start) = _demoVolcano(async);
      const workflow = Workflow(
        id: 'test',
        name: 'Test',
        steps: [
          HeatStep(180),
          AirStep(Duration(seconds: 20)),
          HeatStep(190),
          AirStep(Duration(seconds: 20)),
        ],
      );

      final steps = <int>[];
      runs.run.subscribe((run) {
        if (run != null && (steps.isEmpty || steps.last != run.stepIndex)) {
          steps.add(run.stepIndex);
        }
      });

      start(workflow);
      async.elapse(const Duration(seconds: 2));
      expect(volcano.status.value!.heaterOn, isTrue);
      expect(volcano.status.value!.targetTemperature, 180);
      expect(runs.run.value!.stepIndex, 0);

      // ~30 s to 180 °C, then the first balloon.
      async.elapse(const Duration(seconds: 35));
      expect(runs.run.value!.stepIndex, 1);
      expect(volcano.status.value!.pumpOn, isTrue);

      async.elapse(const Duration(seconds: 60));
      expect(steps, [0, 1, 2, 3]);
      expect(runs.run.value!.phase, WorkflowRunPhase.finished);
      expect(volcano.status.value!.targetTemperature, 190);
      expect(volcano.status.value!.heaterOn, isFalse);
      expect(volcano.status.value!.pumpOn, isFalse);

      volcano.stopSession();
    });
  });

  test('stop turns pump and heater off mid-air', () {
    fakeAsync((async) {
      final (:volcano, :runs, :start) = _demoVolcano(async);
      start(
        const Workflow(
          id: 'air',
          name: 'Air',
          steps: [AirStep(Duration(minutes: 1))],
          heaterOffAtEnd: false,
        ),
      );
      async.elapse(const Duration(seconds: 2));
      expect(volcano.status.value!.pumpOn, isTrue);

      StopWorkflowRunUseCase(runs: runs, volcano: volcano)();
      async.elapse(const Duration(seconds: 1));
      expect(runs.run.value!.phase, WorkflowRunPhase.stopped);
      expect(volcano.status.value!.pumpOn, isFalse);
      expect(volcano.status.value!.heaterOn, isFalse);

      volcano.stopSession();
    });
  });
}
