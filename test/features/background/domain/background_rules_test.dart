import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/background/domain/models/heat_session.dart';
import 'package:kiln/features/background/domain/models/ready_alert_state.dart';
import 'package:kiln/features/background/domain/services/background_rules.dart';
import 'package:kiln/features/devices/domain/models/device_model.dart';

void main() {
  final rules = BackgroundRules();

  HeatSession session({bool ready = false, int target = 185}) => HeatSession(
    model: DeviceModel.volcanoHybrid,
    temperature: target,
    target: target,
    ready: ready,
  );

  test('poll: in front, or in the background while heating', () {
    expect(rules.keepPolling(inFront: true, heating: false), isTrue);
    expect(rules.keepPolling(inFront: false, heating: true), isTrue);
    expect(rules.keepPolling(inFront: false, heating: false), isFalse);
  });

  group('ready alert', () {
    test(
      'alerts once in the background; holding temperature does not repeat',
      () {
        var (state, action) = rules.readyAlert(
          const ReadyAlertState(),
          session: session(ready: true),
          inFront: false,
        );
        expect(action, ReadyAlertAction.alert);
        (state, action) = rules.readyAlert(
          state,
          session: session(),
          inFront: false,
        );
        expect(action, ReadyAlertAction.none);
        (state, action) = rules.readyAlert(
          state,
          session: session(ready: true),
          inFront: false,
        );
        expect(action, ReadyAlertAction.none);
      },
    );

    test('a new target re-arms it', () {
      final (state, _) = rules.readyAlert(
        const ReadyAlertState(),
        session: session(ready: true),
        inFront: false,
      );
      final (_, action) = rules.readyAlert(
        state,
        session: session(ready: true, target: 200),
        inFront: false,
      );
      expect(action, ReadyAlertAction.alert);
    });

    test('ready in front counts as seen, no alert later', () {
      var (state, action) = rules.readyAlert(
        const ReadyAlertState(),
        session: session(ready: true),
        inFront: true,
      );
      expect(action, ReadyAlertAction.none);
      (state, action) = rules.readyAlert(
        state,
        session: session(ready: true),
        inFront: false,
      );
      expect(action, ReadyAlertAction.none);
    });

    test('dismissed when kiln comes to the front or nothing heats', () {
      final (shown, _) = rules.readyAlert(
        const ReadyAlertState(),
        session: session(ready: true),
        inFront: false,
      );
      expect(
        rules
            .readyAlert(shown, session: session(ready: true), inFront: true)
            .$2,
        ReadyAlertAction.dismiss,
      );
      final (ended, action) = rules.readyAlert(
        shown,
        session: null,
        inFront: false,
      );
      expect(action, ReadyAlertAction.dismiss);
      expect(ended, const ReadyAlertState());
      expect(
        rules.readyAlert(ended, session: null, inFront: false).$2,
        ReadyAlertAction.none,
      );
    });
  });
}
