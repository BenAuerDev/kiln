import 'device_finish.dart';

sealed class FinishPreference {
  const FinishPreference();
}

/// Follow the detected finish of the device, falling back to ember.
final class MatchDevice extends FinishPreference {
  const MatchDevice();

  @override
  bool operator ==(Object other) => other is MatchDevice;

  @override
  int get hashCode => (MatchDevice).hashCode;
}

final class FixedFinish extends FinishPreference {
  const FixedFinish(this.finish);

  final DeviceFinish finish;

  @override
  bool operator ==(Object other) =>
      other is FixedFinish && other.finish == finish;

  @override
  int get hashCode => finish.hashCode;
}
