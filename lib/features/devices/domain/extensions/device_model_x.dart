import '../models/device_model.dart';

extension DeviceModelX on DeviceModel {
  /// Speaks the shared Venty/Veazy protocol of the `portable` feature.
  /// Crafty+ is handheld too but uses a different protocol, so it is not
  /// included.
  bool get isPortable => this == DeviceModel.venty || this == DeviceModel.veazy;

  /// kiln can control this model. Crafty+ can be found and remembered only.
  bool get isSupported => this != DeviceModel.craftyPlus;

  /// Plain-text product name. Never render it as a logo or wordmark.
  String get displayName => switch (this) {
    DeviceModel.volcanoHybrid => 'Volcano Hybrid',
    DeviceModel.venty => 'Venty',
    DeviceModel.veazy => 'Veazy',
    DeviceModel.craftyPlus => 'Crafty+',
  };
}
