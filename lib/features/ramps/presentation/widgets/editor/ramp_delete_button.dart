import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/ramp_editor_view_model.dart';

/// Delete, with a second tap to confirm. Only for saved user ramps.
class RampDeleteButton extends SignalWidget {
  const RampDeleteButton({required this.vm, super.key});

  final RampEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.isExisting.value) return const SizedBox.shrink();
    final l10n = getAppLocalizations(context);
    return OiButton.destructive(
      label: vm.confirmingDelete.value
          ? l10n.rampsEditorDeleteConfirm
          : l10n.rampsEditorDelete,
      icon: OiIcons.trash2,
      fullWidth: true,
      onTap: vm.delete,
    );
  }
}
