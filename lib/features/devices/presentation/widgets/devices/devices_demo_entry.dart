import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';

/// "Try the demo" below the device lists.
class DevicesDemoEntry extends StatelessWidget {
  const DevicesDemoEntry({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OiButton.ghost(
    label: getAppLocalizations(context).devicesDemoTry,
    icon: OiIcons.play,
    fullWidth: true,
    onTap: onTap,
  );
}
