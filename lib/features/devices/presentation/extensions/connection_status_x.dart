import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/connection_status.dart';

extension ConnectionStatusX on ConnectionStatus {
  /// Stand-alone status, e.g. a subtitle ("Connected").
  String label(AppLocalizations l10n) => switch (this) {
    ConnectionStatus.connected => l10n.devicesStatusConnected,
    ConnectionStatus.connecting => l10n.devicesStatusConnecting,
    ConnectionStatus.reconnecting => l10n.devicesStatusReconnecting,
    ConnectionStatus.disconnected => l10n.devicesStatusDisconnected,
    ConnectionStatus.unavailable => l10n.devicesStatusUnavailable,
  };

  /// Status after a device name ("Volcano Hybrid · connected").
  String inlineLabel(AppLocalizations l10n) => switch (this) {
    ConnectionStatus.connected => l10n.devicesStatusInlineConnected,
    ConnectionStatus.connecting => l10n.devicesStatusInlineConnecting,
    ConnectionStatus.reconnecting => l10n.devicesStatusInlineReconnecting,
    ConnectionStatus.disconnected => l10n.devicesStatusInlineDisconnected,
    ConnectionStatus.unavailable => l10n.devicesStatusInlineUnavailable,
  };
}
