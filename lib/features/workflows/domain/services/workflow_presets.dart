import '../models/workflow.dart';
import '../models/workflow_preset.dart';
import '../models/workflow_step.dart';

/// The workflows that ship with kiln (design: `Workflow.dc.html`).
abstract final class WorkflowPresets {
  static const _air = AirStep(Duration(seconds: 45));

  static const all = [
    Workflow(
      id: 'preset.threeBalloons',
      name: '',
      preset: WorkflowPreset.threeBalloons,
      steps: [HeatStep(175), _air, HeatStep(185), _air, HeatStep(195), _air],
    ),
    Workflow(
      id: 'preset.singleBalloon',
      name: '',
      preset: WorkflowPreset.singleBalloon,
      steps: [HeatStep(185), _air],
    ),
    Workflow(
      id: 'preset.flavourLadder',
      name: '',
      preset: WorkflowPreset.flavourLadder,
      steps: [
        HeatStep(170),
        HoldStep(Duration(seconds: 30)),
        _air,
        HeatStep(190),
        HoldStep(Duration(seconds: 30)),
        _air,
      ],
    ),
  ];
}
