import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/devices/domain/models/device_finish.dart';
import 'package:kiln/features/devices/presentation/extensions/device_finish_x.dart';
import 'package:kiln/features/home_widgets/domain/models/ramp_widget_snapshot.dart';
import 'package:kiln/features/home_widgets/presentation/extensions/ramp_widget_snapshot_x.dart';
import 'package:kiln/l10n/generated/app_localizations.dart';

import '../mocks.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));

  RampWidgetSnapshot with_(RampWidgetPhase phase, {int step = 1}) =>
      RampWidgetSnapshot(
        profile: rampSnapshot.profile,
        phase: phase,
        target: phase == RampWidgetPhase.idle ? 180 : 185,
        step: phase == RampWidgetPhase.idle ? 0 : step,
        steps: 4,
        duration: rampSnapshot.duration,
        nextTarget: phase == RampWidgetPhase.finished ? null : 190,
        nextStepAt: phase == RampWidgetPhase.running ? rampDue : null,
        finish: DeviceFinish.blue,
      );

  test('running: step, countdown to the next step, Stop', () {
    final content = rampSnapshot.content(en);
    expect(content.name, 'Classic');
    expect(content.center, '185°');
    // The start counts as a step: 180 → 185 is step 2 of 5.
    expect(content.status, 'Step 2 of 5');
    expect(content.statusAccent, isTrue);
    expect(content.countdownFormat, '190° in %s');
    expect(content.nextStepAtMillis, rampDue.millisecondsSinceEpoch);
    expect(content.progress, 0.25);
    expect(content.gaugeDescription, 'Classic, step 2 of 5, now 185 degrees');
    expect(content.buttonLabel, 'Stop ramp');
    expect(content.buttonActive, isTrue);
    expect(content.offlineButtonLabel, 'Start ramp');
    expect(content.accent, DeviceFinish.blue.tokens.dark.accent.toARGB32());
  });

  test('idle: summary, no countdown, Start', () {
    final content = with_(RampWidgetPhase.idle).content(en);
    expect(content.center, '180°');
    expect(content.status, '+5° every 1 min 30 s · 6 min');
    expect(content.statusAccent, isFalse);
    expect(content.countdownFormat, '');
    expect(content.nextStepAtMillis, 0);
    expect(content.progress, 0);
    expect(content.gaugeDescription, 'Classic, 180 to 200 degrees');
    expect(content.buttonLabel, 'Start ramp');
    expect(content.buttonActive, isFalse);
  });

  test('idle while boosting: Start says why it would fail', () {
    final idle = with_(RampWidgetPhase.idle);
    final boosting = RampWidgetSnapshot(
      profile: idle.profile,
      phase: idle.phase,
      target: idle.target,
      step: idle.step,
      steps: idle.steps,
      duration: idle.duration,
      boosting: true,
      finish: idle.finish,
    );
    expect(boosting.content(en).buttonLabel, 'Not while boosting');
    expect(boosting.content(de).buttonLabel, 'Nicht während Boost');
  });

  test('waiting for boost and finished', () {
    final waiting = with_(RampWidgetPhase.waitingForBoost).content(en);
    expect(waiting.status, '190° after boost');
    expect(waiting.countdownFormat, '');
    expect(waiting.buttonLabel, 'Stop ramp');

    final finished = with_(RampWidgetPhase.finished, step: 4).content(en);
    expect(finished.status, 'Done · 185°');
    expect(finished.progress, 1);
    expect(finished.buttonLabel, 'Start ramp');
  });

  test('German', () {
    final content = rampSnapshot.content(de);
    expect(content.name, 'Klassisch');
    expect(content.status, 'Schritt 2 von 5');
    expect(content.countdownFormat, '190° in %s');
    expect(content.buttonLabel, 'Rampe stoppen');
  });
}
