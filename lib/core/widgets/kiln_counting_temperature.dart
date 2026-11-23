import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../formatters/temperature_formatter.dart';
import '../l10n/get_app_localizations.dart';

/// A large temperature that counts through the whole degrees between two
/// readings instead of jumping. It starts at the first value it gets, never
/// at zero, and only ever shows values between two real readings.
class KilnCountingTemperature extends StatelessWidget {
  const KilnCountingTemperature({
    required this.celsius,
    required this.semanticsLabel,
    super.key,
  });

  /// Shared with gauge arcs so number and arc arrive together.
  static const duration = Duration(milliseconds: 700);
  static const curve = Curves.easeOut;

  final double celsius;

  /// Announces the real reading, not every intermediate degree.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: celsius),
      duration: reduceMotion ? Duration.zero : duration,
      curve: curve,
      builder: (context, value, _) => OiLabel.display(
        TemperatureFormatter.degrees(value, l10n),
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
