import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/service_locator.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/presentation/screens/demo_screen.dart';
import 'package:kiln/features/devices/presentation/view_models/demo_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/pump_kiln.dart';

class _MockDemoViewModel extends Mock implements DemoViewModel {}

void main() {
  late _MockDemoViewModel vm;
  late Signal<DeviceModel?> starting;

  setUpAll(() => registerFallbackValue(DeviceModel.veazy));

  setUp(() {
    vm = _MockDemoViewModel();
    starting = signal(null);
    when(() => vm.models).thenReturn(const [
      DeviceModel.volcanoHybrid,
      DeviceModel.venty,
      DeviceModel.veazy,
    ]);
    when(() => vm.startingModel).thenReturn(starting);
    when(() => vm.start(any())).thenAnswer((_) async {});
    sl.registerFactory<DemoViewModel>(() => vm);
  });

  tearDown(sl.reset);

  testWidgets('lists one demo per device and starts the chosen one', (
    tester,
  ) async {
    await pumpKiln(tester, const DemoScreen());

    expect(find.text('Try kiln without a device'), findsOneWidget);
    for (final name in ['Volcano Hybrid', 'Venty', 'Veazy']) {
      expect(find.text(name), findsOneWidget);
    }

    await tester.tap(find.bySemanticsLabel('Start the Venty demo'));
    verify(() => vm.start(DeviceModel.venty)).called(1);

    await tester.tap(find.bySemanticsLabel('Back'));
    verify(() => vm.back()).called(1);
  });
}
