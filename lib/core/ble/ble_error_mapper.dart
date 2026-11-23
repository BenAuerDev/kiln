import '../errors/app_error.dart';
import 'ble_exceptions.dart';

abstract final class BleErrorMapper {
  static AppError toAppError(Object error) => switch (error) {
    BleUnavailableException() => const AppError.bluetoothUnavailable(),
    BlePermissionException() => const AppError.permissionDenied(),
    BleConnectionException() => const AppError.connectionFailed(),
    BleTimeoutException() => const AppError.timeout(),
    BleCharacteristicNotFoundException(:final message) => AppError.protocol(
      message,
    ),
    BleOperationException(:final message) => AppError.protocol(message),
    FormatException(:final message) => AppError.protocol(message),
    final AppError appError => appError,
    final Object other => AppError.unknown(other),
  };
}
