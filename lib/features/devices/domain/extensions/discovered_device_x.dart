import '../models/discovered_device.dart';
import '../models/signal_strength.dart';

extension DiscoveredDeviceX on DiscoveredDevice {
  SignalStrength get signalStrength => switch (rssi) {
    >= -65 => SignalStrength.strong,
    >= -80 => SignalStrength.fair,
    _ => SignalStrength.weak,
  };
}
