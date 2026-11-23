import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../view_models/welcome_view_model.dart';
import 'radar_scan.dart';

class WelcomeRadar extends SignalWidget {
  const WelcomeRadar({required this.vm, super.key});

  final WelcomeViewModel vm;

  @override
  Widget build(BuildContext context) => RadarScan(
    scanning: vm.scanning.value,
    semanticLabel: getAppLocalizations(context).welcomeScanSemantics,
  );
}
