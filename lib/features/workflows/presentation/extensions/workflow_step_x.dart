import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../core/formatters/duration_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/workflow_step.dart';

extension WorkflowStepX on WorkflowStep {
  /// `Heat to 185 °C`, `Hold 30 s`, `Air 45 s`.
  String title(AppLocalizations l10n) => switch (this) {
    HeatStep(:final celsius) => l10n.workflowsHeatTitle(celsius),
    HoldStep(:final duration) => l10n.workflowsHoldTitle(
      DurationFormatter.short(duration, l10n),
    ),
    AirStep(:final duration) => l10n.workflowsAirTitle(
      DurationFormatter.short(duration, l10n),
    ),
  };

  WorkflowStepKind get kind => switch (this) {
    HeatStep() => WorkflowStepKind.heat,
    HoldStep() => WorkflowStepKind.hold,
    AirStep() => WorkflowStepKind.air,
  };
}

extension WorkflowStepKindX on WorkflowStepKind {
  String label(AppLocalizations l10n) => switch (this) {
    WorkflowStepKind.heat => l10n.workflowsKindHeat,
    WorkflowStepKind.hold => l10n.workflowsKindHold,
    WorkflowStepKind.air => l10n.workflowsKindAir,
  };

  IconData get icon => switch (this) {
    WorkflowStepKind.heat => OiIcons.flame,
    WorkflowStepKind.hold => OiIcons.timer,
    WorkflowStepKind.air => OiIcons.wind,
  };
}
