import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/connection_status.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';
import 'package:kiln/features/devices/domain/models/known_device.dart';
import 'package:kiln/features/devices/domain/models/known_device_entry.dart';
import 'package:kiln/features/devices/presentation/widgets/devices/known_device_card.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_kiln.dart';

void main() {
  Widget card(
    KnownDeviceEntry entry, {
    bool confirming = false,
    void Function(String)? onAction,
  }) => SizedBox(
    width: 390,
    child: KnownDeviceCard(
      entry: entry,
      connecting: false,
      confirmingForget: confirming,
      onTap: () => onAction?.call('tap'),
      onForget: () => onAction?.call('forget'),
      onConfirmForget: () => onAction?.call('confirm'),
      onCancelForget: () => onAction?.call('cancel'),
    ),
  );

  testWidgets('connected device shows status and active badge', (tester) async {
    await pumpKiln(
      tester,
      card(
        const KnownDeviceEntry(
          device: volcano,
          status: ConnectionStatus.connected,
        ),
      ),
    );

    expect(find.text('Volcano Hybrid'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('inactive device shows last use and taps through', (
    tester,
  ) async {
    final actions = <String>[];
    await pumpKiln(
      tester,
      card(
        const KnownDeviceEntry(device: veazy, daysSinceLastUse: 1),
        onAction: actions.add,
      ),
    );

    expect(find.text('Last used yesterday'), findsOneWidget);
    expect(find.text('Active'), findsNothing);

    await tester.tap(find.text('Veazy'));
    await tester.tap(find.bySemanticsLabel('Forget Veazy'));
    expect(actions, ['tap', 'forget']);
  });

  testWidgets('asks before forgetting', (tester) async {
    final actions = <String>[];
    await pumpKiln(
      tester,
      card(
        const KnownDeviceEntry(device: veazy),
        confirming: true,
        onAction: actions.add,
      ),
    );

    expect(find.text('Forget this device?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.tap(find.text('Forget'));
    expect(actions, ['cancel', 'confirm']);
  });

  testWidgets('a demo device is labelled as demo', (tester) async {
    await pumpKiln(
      tester,
      card(
        const KnownDeviceEntry(
          device: KnownDevice(
            id: 'demo:veazy',
            name: 'kiln demo',
            model: DeviceModel.veazy,
          ),
          status: ConnectionStatus.connected,
        ),
      ),
    );
    expect(find.text('Demo'), findsOneWidget);
  });

  testWidgets('a real device has no demo label', (tester) async {
    await pumpKiln(tester, card(const KnownDeviceEntry(device: veazy)));
    expect(find.text('Demo'), findsNothing);
  });
}
