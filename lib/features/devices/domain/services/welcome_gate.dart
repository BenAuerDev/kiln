import '../models/known_device.dart';

/// When kiln is past the first-launch welcome: once it was completed, or
/// while any device is known (saved, or the in-memory demo device). The
/// router's welcome gate and every "where to go now" decision use this.
abstract final class WelcomeGate {
  static bool isPast({
    required bool welcomeCompleted,
    required List<KnownDevice> devices,
  }) => welcomeCompleted || devices.isNotEmpty;
}
