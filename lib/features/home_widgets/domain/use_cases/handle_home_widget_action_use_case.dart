import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/service_locator.dart';
import '../../../devices/domain/extensions/device_model_x.dart';
import '../../../devices/domain/extensions/known_device_x.dart';
import '../../../devices/domain/models/device_model.dart';
import '../../../devices/domain/repositories/known_devices_repository.dart';
import '../../../portable/domain/use_cases/toggle_portable_boost_use_case.dart';
import '../../../portable/domain/use_cases/toggle_portable_heater_use_case.dart';
import '../../../volcano/domain/use_cases/toggle_volcano_heater_use_case.dart';
import '../../../volcano/domain/use_cases/toggle_volcano_pump_use_case.dart';
import '../models/home_widget_action.dart';

/// A widget button, run like the same button on the control screen: Heat
/// and Air on the Volcano, Heat and Boost on a Venty/Veazy. Only the active
/// device of the widget's kind is controlled, and never a demo device.
class HandleHomeWidgetActionUseCase {
  HandleHomeWidgetActionUseCase({
    KnownDevicesRepository? knownDevices,
    ToggleVolcanoHeaterUseCase? toggleVolcanoHeater,
    ToggleVolcanoPumpUseCase? toggleVolcanoPump,
    TogglePortableHeaterUseCase? togglePortableHeater,
    TogglePortableBoostUseCase? togglePortableBoost,
  }) : _knownDevices = knownDevices ?? sl<KnownDevicesRepository>(),
       _toggleVolcanoHeater =
           toggleVolcanoHeater ?? sl<ToggleVolcanoHeaterUseCase>(),
       _toggleVolcanoPump = toggleVolcanoPump ?? sl<ToggleVolcanoPumpUseCase>(),
       _togglePortableHeater =
           togglePortableHeater ?? sl<TogglePortableHeaterUseCase>(),
       _togglePortableBoost =
           togglePortableBoost ?? sl<TogglePortableBoostUseCase>();

  final KnownDevicesRepository _knownDevices;
  final ToggleVolcanoHeaterUseCase _toggleVolcanoHeater;
  final ToggleVolcanoPumpUseCase _toggleVolcanoPump;
  final TogglePortableHeaterUseCase _togglePortableHeater;
  final TogglePortableBoostUseCase _togglePortableBoost;

  Future<Either<AppError, Unit>> call(HomeWidgetAction action) async {
    final device = _knownDevices.activeDevice.value;
    final forVolcano =
        action == HomeWidgetAction.volcanoHeat ||
        action == HomeWidgetAction.volcanoAir;
    final matches = forVolcano
        ? device?.model == DeviceModel.volcanoHybrid
        : device?.model.isPortable ?? false;
    if (device == null || device.isDemo || !matches) {
      return left(const AppError.notConnected());
    }
    return switch (action) {
      HomeWidgetAction.volcanoHeat => (await _toggleVolcanoHeater()).map(
        (_) => unit,
      ),
      HomeWidgetAction.volcanoAir => (await _toggleVolcanoPump()).map(
        (_) => unit,
      ),
      HomeWidgetAction.portableHeat => (await _togglePortableHeater()).map(
        (_) => unit,
      ),
      HomeWidgetAction.portableBoost => (await _togglePortableBoost()).map(
        (_) => unit,
      ),
    };
  }
}
