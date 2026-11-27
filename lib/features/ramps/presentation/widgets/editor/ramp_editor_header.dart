import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/ramp_editor_view_model.dart';

/// Back, "New ramp" / "Edit ramp" and Save.
class RampEditorHeader extends SignalWidget {
  const RampEditorHeader({required this.vm, super.key});

  final RampEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        spacing: 12,
        children: [
          SizedBox.square(
            dimension: 48,
            child: OiIconButton(
              icon: OiIcons.chevronLeft,
              semanticLabel: l10n.rampsEditorBack,
              variant: OiButtonVariant.outline,
              onTap: vm.back,
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: OiLabel.h4(
                vm.isExisting.value
                    ? l10n.rampsEditorEditTitle
                    : l10n.rampsEditorNewTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          OiButton.primary(
            label: l10n.rampsEditorSave,
            enabled: vm.canSave.value,
            loading: vm.saving.value,
            onTap: vm.save,
          ),
        ],
      ),
    );
  }
}
