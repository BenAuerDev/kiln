import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../l10n/generated/app_localizations.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({
    required this.selected,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  /// Language code, e.g. `en`.
  final String selected;
  final ValueChanged<String> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => OiSegmentedControl<String>(
    segments: [
      for (final locale in AppLocalizations.supportedLocales)
        OiSegment(
          value: locale.languageCode,
          label: locale.languageCode.toUpperCase(),
        ),
    ],
    selected: selected,
    onChanged: onChanged,
    size: OiSegmentedControlSize.small,
    semanticLabel: semanticLabel,
  );
}
