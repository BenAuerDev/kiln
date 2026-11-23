import '../../../../core/theme/kiln_palette.dart';
import '../../../../core/theme/kiln_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/device_finish.dart';

extension DeviceFinishX on DeviceFinish {
  KilnFinishTokens get tokens => switch (this) {
    DeviceFinish.ember => KilnPalette.ember,
    DeviceFinish.lava => KilnPalette.lava,
    DeviceFinish.blue => KilnPalette.blue,
    DeviceFinish.pink => KilnPalette.pink,
    DeviceFinish.mono => KilnPalette.mono,
  };

  String label(AppLocalizations l10n) => switch (this) {
    DeviceFinish.ember => l10n.devicesFinishEmber,
    DeviceFinish.lava => l10n.devicesFinishLava,
    DeviceFinish.blue => l10n.devicesFinishBlue,
    DeviceFinish.pink => l10n.devicesFinishPink,
    DeviceFinish.mono => l10n.devicesFinishMono,
  };
}
