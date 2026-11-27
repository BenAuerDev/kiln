import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/theme/build_context_x.dart';
import '../view_models/ramp_editor_view_model.dart';
import '../widgets/editor/ramp_delete_button.dart';
import '../widgets/editor/ramp_editor_header.dart';
import '../widgets/editor/ramp_name_field.dart';
import '../widgets/editor/ramp_preview.dart';
import '../widgets/editor/ramp_value_rows.dart';

/// Creates or edits a Venty/Veazy ramp. [rampId] is a user ramp to edit;
/// without it, a new ramp starts with the values of [fromId].
class RampEditorScreen extends HookWidget {
  const RampEditorScreen({this.rampId, this.fromId, super.key});

  final String? rampId;
  final String? fromId;

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(
      () => sl<RampEditorViewModel>(param1: rampId, param2: fromId),
      [rampId, fromId],
    );
    useEffect(() => vm.dispose, [vm]);
    return ColoredBox(
      color: context.kiln.surfaces.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RampEditorHeader(vm: vm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    RampNameField(vm: vm),
                    RampPreview(vm: vm),
                    RampValueRows(vm: vm),
                    RampDeleteButton(vm: vm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
