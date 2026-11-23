import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

/// Settings row: title, explanation and a switch.
class PortableSwitchRow extends StatelessWidget {
  const PortableSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => OiSwitchTile(
    title: title,
    subtitle: subtitle,
    value: value,
    onChanged: onChanged,
    enabled: enabled,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  );
}
