import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../portable/domain/use_cases/start_portable_session_use_case.dart';
import '../../../volcano/domain/use_cases/start_volcano_session_use_case.dart';

/// Starts the device session for [model], whatever screen is open: after a
/// reconnect while kiln shows another screen (or is hidden), nothing else
/// would. Idempotent: a running or pending start is reused.
class StartDeviceSessionUseCase {
  StartDeviceSessionUseCase({
    StartPortableSessionUseCase? startPortable,
    StartVolcanoSessionUseCase? startVolcano,
  }) : _startPortable = startPortable ?? sl<StartPortableSessionUseCase>(),
       _startVolcano = startVolcano ?? sl<StartVolcanoSessionUseCase>();

  final StartPortableSessionUseCase _startPortable;
  final StartVolcanoSessionUseCase _startVolcano;

  Future<Either<AppError, Unit>> call(String deviceId, DeviceModel model) =>
      switch (model) {
        DeviceModel.volcanoHybrid => _startVolcano(deviceId),
        DeviceModel.venty ||
        DeviceModel.veazy => _startPortable(deviceId, model),
        DeviceModel.craftyPlus => Future.value(right(unit)),
      };
}
