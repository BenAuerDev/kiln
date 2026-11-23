import 'package:flutter/widgets.dart';

import 'app/kiln_app.dart';
import 'core/service_locator.dart';
import 'features/app_settings/domain/repositories/app_settings_repository.dart';
import 'features/devices/domain/use_cases/load_known_devices_use_case.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await sl<AppSettingsRepository>().load();
  await sl<LoadKnownDevicesUseCase>()();
  runApp(const KilnApp());
}
