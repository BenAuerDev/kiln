import 'package:flutter/services.dart';

class HapticsService {
  Future<void> tick() => HapticFeedback.selectionClick();

  Future<void> success() => HapticFeedback.mediumImpact();

  Future<void> warning() => HapticFeedback.heavyImpact();
}
