import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/portable/domain/models/heater_mode.dart';
import 'package:kiln/features/ramps/domain/models/ramp_run.dart';
import 'package:kiln/features/ramps/domain/repositories/ramp_run_repository.dart';
import 'package:kiln/features/ramps/domain/services/ramp_service.dart';
import 'package:kiln/features/ramps/presentation/widgets/portable_ramp_banner.dart';
import 'package:kiln/features/ramps/presentation/widgets/portable_ramp_card.dart';

import '../../../portable/helpers/portable_fixtures.dart' show testStatus;
import '../../../portable/presentation/pump_app.dart';
import '../../helpers/ramp_registration.dart';

void main() {
  tearDown(sl.reset);

  testWidgets('card shows the presets and Start', (tester) async {
    registerRamp(status: testStatus(heaterMode: HeaterMode.normal));
    await pumpKiln(tester, const PortableRampCard());
    expect(find.text('Gentle'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('180–200°'), findsOneWidget);
    expect(find.text('Start ramp'), findsOneWidget);
  });

  testWidgets('banner only while a ramp runs', (tester) async {
    final runs = RampRunRepository()
      ..update(
        RampRun(
          profile: RampService.presets.first,
          deviceId: 'veazy-id',
          session: 1,
          target: 175,
          nextTarget: 180,
          nextStepAt: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );
    registerRamp(
      runs: runs,
      status: testStatus(heaterMode: HeaterMode.normal),
    );
    await pumpKiln(tester, const PortableRampBanner());
    expect(find.text('RAMP RUNNING'), findsOneWidget);
    expect(find.text('Stop ramp'), findsOneWidget);
  });
}
