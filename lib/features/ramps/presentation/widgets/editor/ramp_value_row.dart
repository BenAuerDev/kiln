import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../portable/presentation/widgets/setup/portable_ladder_row.dart';
import '../../../domain/models/ramp_field.dart';
import '../../view_models/ramp_editor_view_model.dart';

/// One value of the ramp with −/+, like a row of the Setup tab's ladder.
/// [semanticName] names the value in "Lower …" / "Raise …" ("interval"),
/// where the visible [name] ("Every") would not read well.
class RampValueRow extends SignalWidget {
  const RampValueRow({
    required this.vm,
    required this.field,
    required this.icon,
    required this.name,
    required this.semanticName,
    required this.hint,
    required this.value,
    this.sub,
    this.divider = true,
    super.key,
  });

  final RampEditorViewModel vm;
  final RampField field;
  final IconData icon;
  final String name;
  final String semanticName;
  final String hint;
  final ReadonlySignal<String> value;
  final ReadonlySignal<String>? sub;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    return PortableLadderRow(
      divider: divider,
      icon: icon,
      name: name,
      hint: hint,
      value: value.value,
      sub: sub?.value ?? '',
      lowerLabel: l10n.rampsEditorLower(semanticName),
      raiseLabel: l10n.rampsEditorRaise(semanticName),
      onLower: () => vm.lower(field),
      onRaise: () => vm.raise(field),
    );
  }
}
