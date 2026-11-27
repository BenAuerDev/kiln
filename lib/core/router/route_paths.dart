abstract final class RoutePaths {
  static const root = '/';
  static const welcome = '/welcome';
  static const devices = '/devices';
  static const demo = '/demo';
  static const portableControl = '/portable/control';
  static const portableSetup = '/portable/setup';
  static const portableSettings = '/portable/settings';

  /// Query `id`: the user ramp to edit; or `from`: the ramp whose values a
  /// new ramp starts with.
  static const rampEditor = '/portable/ramps/edit';
  static const volcanoControl = '/volcano/control';
  static const volcanoWorkflows = '/volcano/workflows';
  static const workflowRun = '/volcano/workflows/run';

  /// Query `id`: the workflow to edit (a preset is copied). Without it, a
  /// new workflow.
  static const workflowEditor = '/volcano/workflows/edit';
}
