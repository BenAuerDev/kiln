sealed class AppError {
  const AppError();

  const factory AppError.bluetoothUnavailable() = BluetoothUnavailableError;
  const factory AppError.permissionDenied() = PermissionDeniedError;
  const factory AppError.deviceNotFound() = DeviceNotFoundError;
  const factory AppError.connectionFailed() = ConnectionFailedError;
  const factory AppError.connectionLost() = ConnectionLostError;
  const factory AppError.timeout() = TimeoutError;
  const factory AppError.protocol(String detail) = ProtocolError;
  const factory AppError.storage() = StorageError;
  const factory AppError.writeNotVerified(String command) =
      WriteNotVerifiedError;
  const factory AppError.notConnected() = NotConnectedError;
  const factory AppError.unknown(Object cause) = UnknownError;
}

final class BluetoothUnavailableError extends AppError {
  const BluetoothUnavailableError();
}

final class PermissionDeniedError extends AppError {
  const PermissionDeniedError();
}

final class DeviceNotFoundError extends AppError {
  const DeviceNotFoundError();
}

final class ConnectionFailedError extends AppError {
  const ConnectionFailedError();
}

final class ConnectionLostError extends AppError {
  const ConnectionLostError();
}

final class TimeoutError extends AppError {
  const TimeoutError();
}

final class ProtocolError extends AppError {
  const ProtocolError(this.detail);

  final String detail;
}

final class StorageError extends AppError {
  const StorageError();
}

/// Returned instead of sending a BLE write whose byte layout has not been
/// confirmed against the official app or an HCI capture.
final class WriteNotVerifiedError extends AppError {
  const WriteNotVerifiedError(this.command);

  final String command;
}

final class NotConnectedError extends AppError {
  const NotConnectedError();
}

final class UnknownError extends AppError {
  const UnknownError(this.cause);

  final Object cause;
}
