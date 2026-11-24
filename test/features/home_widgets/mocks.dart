import 'dart:ui';

import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/finish_preference.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/home_widgets/data/data_sources/home_widget_data_source.dart';
import 'package:kiln/features/home_widgets/domain/models/portable_widget_content.dart';
import 'package:kiln/features/home_widgets/domain/models/portable_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/domain/models/volcano_widget_content.dart';
import 'package:kiln/features/home_widgets/domain/models/volcano_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/presentation/extensions/portable_widget_snapshot_x.dart';
import 'package:kiln/features/home_widgets/presentation/extensions/volcano_widget_snapshot_x.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/portable/domain/models/portable_heat_phase.dart';
import 'package:kiln/features/portable/domain/services/portable_ladder_service.dart';
import 'package:kiln/features/volcano/domain/models/volcano_heat_phase.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';
import 'package:kiln/features/home_widgets/domain/repositories/home_widgets_repository.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/current_portable_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/current_volcano_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/handle_home_widget_action_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/show_portable_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/show_volcano_widget_use_case.dart';
import 'package:kiln/features/home_widgets/domain/use_cases/listen_to_home_widget_actions_use_case.dart';
import 'package:kiln/features/volcano/domain/models/volcano_status.dart';
import 'package:mocktail/mocktail.dart';

import '../portable/helpers/portable_fixtures.dart';

class MockHomeWidgetDataSource extends Mock implements HomeWidgetDataSource {}

class MockHomeWidgetsRepository extends Mock implements HomeWidgetsRepository {}

class MockCurrentPortableWidgetUseCase extends Mock
    implements CurrentPortableWidgetUseCase {}

class MockCurrentVolcanoWidgetUseCase extends Mock
    implements CurrentVolcanoWidgetUseCase {}

class MockShowPortableWidgetUseCase extends Mock
    implements ShowPortableWidgetUseCase {}

class MockShowVolcanoWidgetUseCase extends Mock
    implements ShowVolcanoWidgetUseCase {}

class MockListenToHomeWidgetActionsUseCase extends Mock
    implements ListenToHomeWidgetActionsUseCase {}

class MockHandleHomeWidgetActionUseCase extends Mock
    implements HandleHomeWidgetActionUseCase {}

const veazy = KnownDevice(
  id: 'vz',
  name: 'S&B VZ',
  model: DeviceModel.veazy,
  finishPreference: FixedFinish(DeviceFinish.blue),
);

const volcanoDevice = KnownDevice(
  id: 'vol',
  name: 'S&B VOLCANO H',
  model: DeviceModel.volcanoHybrid,
);

const demoVeazy = KnownDevice(
  id: 'demo:veazy',
  name: 'Veazy',
  model: DeviceModel.veazy,
);

const demoVolcano = KnownDevice(
  id: 'demo:volcano',
  name: 'Volcano Hybrid',
  model: DeviceModel.volcanoHybrid,
);

VolcanoStatus volcanoStatus({
  double? current = 142.4,
  int target = 185,
  bool heaterOn = true,
  bool pumpOn = false,
}) => VolcanoStatus(
  currentTemperature: current,
  targetTemperature: target,
  heaterOn: heaterOn,
  pumpOn: pumpOn,
  autoShutdown: true,
  fahrenheit: false,
  displayOnCooling: false,
  vibrationWhenReady: true,
);

final en = lookupAppLocalizations(const Locale('en'));

final veazySnapshot = PortableWidgetSnapshot(
  model: DeviceModel.veazy,
  batteryPercent: 72,
  ladder: PortableLadderService().ladder(testStatus(target: 180)),
  heaterMode: HeaterMode.normal,
  phase: PortableHeatPhase.heating,
  activeTemperature: 180,
  finish: DeviceFinish.blue,
);

const volcanoSnapshot = VolcanoWidgetSnapshot(
  temperature: 142,
  target: 185,
  phase: VolcanoHeatPhase.heating,
  pumpOn: false,
  progress: 0.54,
  finish: DeviceFinish.ember,
);

final PortableWidgetContent portableContent = veazySnapshot.content(en);

VolcanoWidgetContent volcanoContent({int temperature = 142}) =>
    VolcanoWidgetSnapshot(
      temperature: temperature,
      target: 185,
      phase: VolcanoHeatPhase.heating,
      pumpOn: false,
      progress: 0.54,
      finish: DeviceFinish.ember,
    ).content(en);
