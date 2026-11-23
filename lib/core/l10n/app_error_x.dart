import '../../l10n/generated/app_localizations.dart';
import '../errors/app_error.dart';

extension AppErrorX on AppError {
  String message(AppLocalizations l10n) => switch (this) {
    BluetoothUnavailableError() => l10n.errorBluetoothUnavailable,
    PermissionDeniedError() => l10n.errorPermissionDenied,
    DeviceNotFoundError() => l10n.errorDeviceNotFound,
    ConnectionFailedError() => l10n.errorConnectionFailed,
    ConnectionLostError() => l10n.errorConnectionLost,
    TimeoutError() => l10n.errorTimeout,
    ProtocolError() => l10n.errorProtocol,
    StorageError() => l10n.errorStorage,
    WriteNotVerifiedError() => l10n.errorWriteNotVerified,
    NotConnectedError() => l10n.errorNotConnected,
    UnknownError() => l10n.errorUnknown,
  };
}
