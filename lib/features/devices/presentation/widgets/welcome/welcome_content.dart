import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../view_models/welcome_step.dart';
import '../../view_models/welcome_view_model.dart';
import 'welcome_intro.dart';
import 'welcome_scan_section.dart';

class WelcomeContent extends SignalWidget {
  const WelcomeContent({required this.vm, super.key});

  final WelcomeViewModel vm;

  @override
  Widget build(BuildContext context) => switch (vm.step.value) {
    WelcomeStep.intro => const WelcomeIntro(),
    WelcomeStep.scan => WelcomeScanSection(vm: vm),
  };
}
