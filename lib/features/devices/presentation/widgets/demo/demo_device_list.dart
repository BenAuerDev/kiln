import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../view_models/demo_view_model.dart';
import 'demo_device_card.dart';

class DemoDeviceList extends SignalWidget {
  const DemoDeviceList({required this.vm, super.key});

  final DemoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final starting = vm.startingModel.value;
    return OiColumn(
      breakpoint: OiBreakpoint.compact,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: const OiResponsive(12),
      children: [
        for (final model in vm.models)
          DemoDeviceCard(
            model: model,
            starting: starting == model,
            enabled: starting == null,
            onStart: () => vm.start(model),
          ),
      ],
    );
  }
}
