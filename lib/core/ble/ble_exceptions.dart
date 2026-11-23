sealed class BleException implements Exception {
  const BleException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class BleUnavailableException extends BleException {
  const BleUnavailableException(super.message);
}

final class BlePermissionException extends BleException {
  const BlePermissionException(super.message);
}

final class BleConnectionException extends BleException {
  const BleConnectionException(super.message);
}

final class BleTimeoutException extends BleException {
  const BleTimeoutException(super.message);
}

final class BleCharacteristicNotFoundException extends BleException {
  const BleCharacteristicNotFoundException(super.message);
}

final class BleOperationException extends BleException {
  const BleOperationException(super.message);
}
