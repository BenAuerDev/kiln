import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/ramp_editor_view_model.dart';

/// The ramp's name. Takes over the draft's name whenever the view model
/// replaces the draft (after loading).
class RampNameField extends HookWidget {
  const RampNameField({required this.vm, super.key});

  final RampEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final controller = useTextEditingController(text: vm.name.value);
    useEffect(
      () => vm.draftVersion.subscribe((_) {
        if (controller.text != vm.name.value) controller.text = vm.name.value;
      }),
      [vm],
    );
    return OiTextInput(
      controller: controller,
      label: l10n.rampsEditorName,
      placeholder: l10n.rampsEditorNameHint,
      maxLength: vm.maxNameLength,
      textCapitalization: TextCapitalization.sentences,
      onChanged: vm.setName,
    );
  }
}
