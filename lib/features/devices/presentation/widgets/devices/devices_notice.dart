import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';

class DevicesNotice extends StatelessWidget {
  const DevicesNotice({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
    child: OiLabel.tiny(
      getAppLocalizations(context).devicesUnofficialNotice,
      textAlign: TextAlign.center,
      color: context.colors.textSubtle,
    ),
  );
}
