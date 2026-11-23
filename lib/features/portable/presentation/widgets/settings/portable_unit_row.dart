import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

/// "Temperature unit" with a °C / °F segmented control.
class PortableUnitRow extends StatelessWidget {
  const PortableUnitRow({
    required this.title,
    required this.celsiusLabel,
    required this.fahrenheitLabel,
    required this.fahrenheit,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String celsiusLabel;
  final String fahrenheitLabel;
  final bool fahrenheit;

  /// Called with `true` for °F.
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: OiLabel.body(title)),
          OiSegmentedControl<bool>(
            semanticLabel: title,
            size: OiSegmentedControlSize.small,
            enabled: enabled,
            selected: fahrenheit,
            onChanged: onChanged,
            segments: [
              OiSegment(value: false, label: celsiusLabel),
              OiSegment(value: true, label: fahrenheitLabel),
            ],
          ),
        ],
      ),
    ),
  );
}
