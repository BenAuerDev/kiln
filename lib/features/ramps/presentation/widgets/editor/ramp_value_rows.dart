import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../portable/presentation/widgets/common/portable_card.dart';
import '../../../domain/models/ramp_field.dart';
import '../../view_models/ramp_editor_view_model.dart';
import 'ramp_value_row.dart';

/// Start, end, step and interval with −/+, like the Setup tab's ladder.
class RampValueRows extends StatelessWidget {
  const RampValueRows({required this.vm, super.key});

  final RampEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return PortableCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RampValueRow(
            vm: vm,
            field: RampField.start,
            icon: OiIcons.thermometer,
            name: l10n.rampsEditorStart,
            semanticName: l10n.rampsEditorStartField,
            hint: l10n.rampsEditorStartHint,
            value: vm.startLabel,
            divider: false,
          ),
          RampValueRow(
            vm: vm,
            field: RampField.end,
            icon: OiIcons.flag,
            name: l10n.rampsEditorEnd,
            semanticName: l10n.rampsEditorEndField,
            hint: l10n.rampsEditorEndHint,
            value: vm.endLabel,
            sub: vm.stepCount,
          ),
          RampValueRow(
            vm: vm,
            field: RampField.step,
            icon: OiIcons.chevronsUp,
            name: l10n.rampsEditorStep,
            semanticName: l10n.rampsEditorStepField,
            hint: l10n.rampsEditorStepHint,
            value: vm.stepLabel,
          ),
          RampValueRow(
            vm: vm,
            field: RampField.interval,
            icon: OiIcons.timer,
            name: l10n.rampsEditorInterval,
            semanticName: l10n.rampsEditorIntervalField,
            hint: l10n.rampsEditorIntervalHint,
            value: vm.intervalLabel,
            sub: vm.minutesUnit,
          ),
        ],
      ),
    );
  }
}
