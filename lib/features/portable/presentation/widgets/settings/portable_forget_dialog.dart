import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';

class PortableForgetDialog extends StatelessWidget {
  const PortableForgetDialog({
    required this.deviceName,
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final String deviceName;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = getAppLocalizations(context);
    final title = l10n.portableForgetTitle(deviceName);
    return OiDialog.confirm(
      label: title,
      title: title,
      content: OiLabel.body(
        l10n.portableForgetBody,
        color: context.colors.textSubtle,
      ),
      onClose: onCancel,
      actions: [
        OiButton.ghost(label: l10n.commonCancel, onTap: onCancel),
        OiButton.destructive(
          label: l10n.portableForgetConfirm,
          onTap: onConfirm,
        ),
      ],
    );
  }
}
