import 'device_finish.dart';
import 'device_model.dart';
import 'finish_preference.dart';

class KnownDevice {
  const KnownDevice({
    required this.id,
    required this.name,
    required this.model,
    this.finishPreference = const MatchDevice(),
    this.detectedFinish,
    this.lastConnectedAt,
  });

  final String id;
  final String name;
  final DeviceModel model;
  final FinishPreference finishPreference;
  final DeviceFinish? detectedFinish;
  final DateTime? lastConnectedAt;

  KnownDevice copyWith({
    String? name,
    FinishPreference? finishPreference,
    DeviceFinish? detectedFinish,
    DateTime? lastConnectedAt,
  }) => KnownDevice(
    id: id,
    name: name ?? this.name,
    model: model,
    finishPreference: finishPreference ?? this.finishPreference,
    detectedFinish: detectedFinish ?? this.detectedFinish,
    lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is KnownDevice &&
      other.id == id &&
      other.name == name &&
      other.model == model &&
      other.finishPreference == finishPreference &&
      other.detectedFinish == detectedFinish &&
      other.lastConnectedAt == lastConnectedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    model,
    finishPreference,
    detectedFinish,
    lastConnectedAt,
  );
}
