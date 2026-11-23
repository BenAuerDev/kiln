import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../extensions/portable_ladder_x.dart';
import '../../extensions/quick_setup_x.dart';
import '../../view_models/portable_setup_view_model.dart';
import '../common/portable_section_label.dart';
import 'portable_quick_setup_control.dart';

class PortableQuickSetupSection extends SignalWidget {
  const PortableQuickSetupSection({required this.vm, super.key});

  final PortableSetupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final options = vm.quickSetups;
    final matching = vm.matchingQuickSetup.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        PortableSectionLabel(l10n.portableQuickSetups),
        PortableQuickSetupControl(
          semanticLabel: l10n.portableQuickSetups,
          options: [
            for (final option in options)
              (
                name: option.setup.label(l10n),
                range: option.ladder.rangeLabel(l10n),
              ),
          ],
          checkedIndex: matching == null
              ? null
              : options.indexWhere((option) => option.setup == matching),
          enabled: vm.controlsEnabled.value,
          onSelect: (index) => vm.applyQuickSetup(options[index].setup),
        ),
      ],
    );
  }
}
