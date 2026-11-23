// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'kiln';

  @override
  String get commonUnofficialNotice =>
      'Unofficial app, not affiliated with Storz & Bickel.';

  @override
  String commonSavedTo(String deviceName) {
    return 'Saved to $deviceName';
  }

  @override
  String commonDegrees(int value) {
    return '$value°';
  }

  @override
  String commonDegreesCelsius(int value) {
    return '$value °C';
  }

  @override
  String commonDegreesFahrenheit(int value) {
    return '$value °F';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String commonSemanticsWithDetail(String label, String detail) {
    return '$label, $detail';
  }

  @override
  String commonSemanticsTitleSubtitle(String title, String subtitle) {
    return '$title. $subtitle';
  }

  @override
  String get errorBluetoothUnavailable => 'Bluetooth is off or not available.';

  @override
  String get errorPermissionDenied =>
      'kiln needs Bluetooth permission to talk to your device.';

  @override
  String get errorDeviceNotFound =>
      'Device not found. Is it switched on and nearby?';

  @override
  String get errorConnectionFailed => 'Couldn\'t connect. Try again.';

  @override
  String get errorConnectionLost => 'Connection lost.';

  @override
  String get errorTimeout => 'The device didn\'t answer in time.';

  @override
  String get errorProtocol => 'The device sent something unexpected.';

  @override
  String get errorStorage => 'Couldn\'t save on this phone.';

  @override
  String get errorWriteNotVerified =>
      'This command is disabled until it has been verified.';

  @override
  String get errorNotConnected => 'No device connected.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get navControl => 'Control';

  @override
  String get navSetup => 'Setup';

  @override
  String get navDevices => 'Devices';

  @override
  String get portableDefaultName => 'Vaporizer';

  @override
  String portableBatteryLevel(int percent) {
    return '$percent% battery';
  }

  @override
  String portableBatteryCharging(int percent) {
    return '$percent% · charging';
  }

  @override
  String portableStatusLine(String first, String second) {
    return '$first · $second';
  }

  @override
  String portableOpenSettings(String deviceName) {
    return '$deviceName settings';
  }

  @override
  String portableSetupIntro(String deviceName) {
    return 'Your $deviceName keeps these settings. Set them here once, then just use the button.';
  }

  @override
  String portableScaleLabel(String base, String boost, String superBoost) {
    return 'Base $base, boost $boost, superboost $superBoost';
  }

  @override
  String get portableBaseName => 'Base';

  @override
  String get portableBaseHint => 'When you switch it on';

  @override
  String get portableBaseSub => 'start';

  @override
  String get portableBoostName => 'Boost';

  @override
  String get portableBoostHint => 'Double-click';

  @override
  String get portableSuperBoostName => 'Superboost';

  @override
  String get portableSuperBoostHint => 'Double-click again';

  @override
  String portableOffset(int value) {
    return '+$value°';
  }

  @override
  String portableLadderTo(String temperature) {
    return '→ $temperature';
  }

  @override
  String portableLadderToMax(String temperature) {
    return '→ $temperature max';
  }

  @override
  String get portableLowerBase => 'Lower base temperature';

  @override
  String get portableRaiseBase => 'Raise base temperature';

  @override
  String get portableLowerBoost => 'Lower boost';

  @override
  String get portableRaiseBoost => 'Raise boost';

  @override
  String get portableLowerSuperBoost => 'Lower superboost';

  @override
  String get portableRaiseSuperBoost => 'Raise superboost';

  @override
  String get portableQuickSetups => 'Quick setups';

  @override
  String get portableQuickSetupFlavour => 'Flavour';

  @override
  String get portableQuickSetupBalanced => 'Balanced';

  @override
  String get portableQuickSetupFull => 'Full';

  @override
  String portableQuickSetupRange(int from, int to) {
    return '$from–$to°';
  }

  @override
  String get portableGaugeLabel => 'Temperature gauge';

  @override
  String get portablePhaseOff => 'Heater off';

  @override
  String get portablePhaseHeating => 'Heating';

  @override
  String get portablePhaseReady => 'Ready';

  @override
  String get portableNoTemperature => '–';

  @override
  String portableCurrentTemperatureLabel(String temperature) {
    return 'Current temperature $temperature';
  }

  @override
  String portableTargetTemperatureLabel(String temperature) {
    return 'Target temperature $temperature';
  }

  @override
  String portableTargetLine(String temperature) {
    return 'target $temperature';
  }

  @override
  String get portableTargetOnlyLine => 'target temperature';

  @override
  String get portableSetTemperature => 'set temperature';

  @override
  String get portableLowerTarget => 'Lower target temperature';

  @override
  String get portableRaiseTarget => 'Raise target temperature';

  @override
  String portablePresetLabel(String temperature) {
    return 'Set target to $temperature';
  }

  @override
  String get portableHeaterOn => 'Heater on';

  @override
  String get portableHeaterOff => 'Heater off';

  @override
  String get portableBoost => 'Boost';

  @override
  String portableBoostOn(int value) {
    return 'Boost +$value°';
  }

  @override
  String portableSuperBoostOn(int value) {
    return 'Superboost +$value°';
  }

  @override
  String get portableSettingsBack => 'Back';

  @override
  String portableFindTitle(String deviceName) {
    return 'Find my $deviceName';
  }

  @override
  String get portableFindSubtitle => 'Makes it vibrate and blink';

  @override
  String portableFindingTitle(String deviceName) {
    return 'Buzzing your $deviceName…';
  }

  @override
  String get portableFindingSubtitle => 'Listen for the vibration';

  @override
  String get portableBatteryHeading => 'Battery';

  @override
  String get portableChargeLimitTitle => 'Charge limit';

  @override
  String get portableChargeLimitSubtitle =>
      'Stops charging around 90% so the battery lasts more years.';

  @override
  String get portableBatterySaverTitle => 'Battery saver';

  @override
  String get portableBatterySaverSubtitle =>
      'Heats a little gentler for more sessions per charge.';

  @override
  String get portableDeviceHeading => 'Device';

  @override
  String get portableVibrateTitle => 'Vibrate when ready';

  @override
  String get portableVibrateSubtitle => 'Buzzes once it reaches temperature.';

  @override
  String get portableBoostLedsTitle => 'Show boost on LEDs';

  @override
  String get portableBoostLedsSubtitle =>
      'The light tells you which level you are on.';

  @override
  String get portableUnitTitle => 'Temperature unit';

  @override
  String get portableUnitCelsius => '°C';

  @override
  String get portableUnitFahrenheit => '°F';

  @override
  String get portableThemeHeading => 'App theme';

  @override
  String get portableThemeMatchTitle => 'Match my device';

  @override
  String portableThemeMatchDetected(String finish, String deviceName) {
    return '$finish, read from your $deviceName';
  }

  @override
  String get portableThemeMatchUnknown => 'Not read yet, Ember until then';

  @override
  String portableThemeSwatchLabel(String finish) {
    return '$finish theme';
  }

  @override
  String portableThemeNote(String deviceName) {
    return 'Only for this $deviceName. Each device keeps its own theme.';
  }

  @override
  String get portableForgetDevice => 'Forget this device';

  @override
  String portableForgetTitle(String deviceName) {
    return 'Forget $deviceName?';
  }

  @override
  String get portableForgetBody =>
      'kiln disconnects and removes it from your devices, together with its theme.';

  @override
  String get portableForgetConfirm => 'Forget';

  @override
  String get volcanoDefaultName => 'Volcano Hybrid';

  @override
  String volcanoDeviceLine(String deviceName, String connection) {
    return '$deviceName · $connection';
  }

  @override
  String get volcanoGaugeLabel => 'Temperature gauge';

  @override
  String get volcanoPhaseOff => 'Heater off';

  @override
  String get volcanoPhaseHeating => 'Heating';

  @override
  String get volcanoPhaseReady => 'Ready';

  @override
  String get volcanoNoTemperature => '–';

  @override
  String volcanoCurrentTemperatureLabel(String temperature) {
    return 'Current temperature $temperature';
  }

  @override
  String volcanoTargetLine(String temperature) {
    return 'target $temperature';
  }

  @override
  String get volcanoSetTemperature => 'set temperature';

  @override
  String get volcanoLowerTarget => 'Lower target temperature';

  @override
  String get volcanoRaiseTarget => 'Raise target temperature';

  @override
  String volcanoPresetLabel(String temperature) {
    return 'Set target to $temperature';
  }

  @override
  String get volcanoHeaterOn => 'Heater on';

  @override
  String get volcanoHeaterOff => 'Heater off';

  @override
  String get volcanoAirOn => 'Air on';

  @override
  String get volcanoAirOff => 'Air off';

  @override
  String get welcomeLanguageLabel => 'Language';

  @override
  String get welcomeTitle => 'Let\'s find your vaporizer';

  @override
  String get welcomeBody =>
      'kiln talks to your device over Bluetooth. Your phone will ask for permission next.';

  @override
  String get welcomePointPrivacy => 'No account. Nothing leaves your phone.';

  @override
  String get welcomePointReconnect => 'Reconnects by itself next time.';

  @override
  String get welcomePointDevices => 'Volcano Hybrid, Venty, Veazy and Crafty+.';

  @override
  String get welcomeContinue => 'Continue';

  @override
  String get welcomeScanLooking => 'Looking around…';

  @override
  String welcomeScanFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count',
      one: 'Found one',
    );
    return '$_temp0';
  }

  @override
  String get welcomeScanNothing => 'Nothing found yet';

  @override
  String get welcomeScanHint => 'Switch it on and keep it close.';

  @override
  String get welcomeScanAgain => 'Search again';

  @override
  String get welcomeSkip => 'Skip for now';

  @override
  String get welcomeScanSemantics => 'Searching for devices';

  @override
  String get devicesTitle => 'Devices';

  @override
  String get devicesBack => 'Back to control';

  @override
  String get devicesYours => 'Your devices';

  @override
  String get devicesEmpty =>
      'No devices yet. Switch yours on and it shows up below.';

  @override
  String get devicesActive => 'Active';

  @override
  String get devicesStatusConnected => 'Connected';

  @override
  String get devicesStatusConnecting => 'Connecting…';

  @override
  String get devicesStatusReconnecting => 'Reconnecting…';

  @override
  String get devicesStatusDisconnected => 'Not connected';

  @override
  String get devicesStatusUnavailable => 'Couldn\'t reach it';

  @override
  String get devicesStatusInlineConnected => 'connected';

  @override
  String get devicesStatusInlineConnecting => 'connecting…';

  @override
  String get devicesStatusInlineReconnecting => 'reconnecting…';

  @override
  String get devicesStatusInlineDisconnected => 'not connected';

  @override
  String get devicesStatusInlineUnavailable => 'unavailable';

  @override
  String devicesLastUsed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last used $days days ago',
      one: 'Last used yesterday',
      zero: 'Last used today',
    );
    return '$_temp0';
  }

  @override
  String get devicesNeverUsed => 'Not used yet';

  @override
  String get devicesScanning => 'Scanning nearby';

  @override
  String get devicesNearby => 'Nearby';

  @override
  String get devicesScan => 'Scan';

  @override
  String get devicesNoneNearby => 'Nothing new nearby.';

  @override
  String get devicesSignalStrong => 'Signal strong';

  @override
  String get devicesSignalFair => 'Signal fair';

  @override
  String get devicesSignalWeak => 'Signal weak';

  @override
  String devicesNearbySubtitle(String signal) {
    return '$signal · not paired';
  }

  @override
  String get devicesPair => 'Pair';

  @override
  String get devicesConnect => 'Connect';

  @override
  String devicesConnectSemantics(String deviceName) {
    return 'Connect to $deviceName';
  }

  @override
  String devicesOpenSemantics(String deviceName) {
    return 'Open $deviceName';
  }

  @override
  String get devicesDisconnect => 'Disconnect';

  @override
  String get devicesForget => 'Forget';

  @override
  String devicesForgetSemantics(String deviceName) {
    return 'Forget $deviceName';
  }

  @override
  String get devicesForgetConfirm => 'Forget this device?';

  @override
  String devicesForgotten(String deviceName) {
    return '$deviceName forgotten';
  }

  @override
  String devicesNotSupportedYet(String deviceName) {
    return '$deviceName isn\'t supported yet.';
  }

  @override
  String get devicesUnofficialNotice =>
      'Unofficial app. Not affiliated with or endorsed by Storz & Bickel. Device names are used only to identify compatibility.';

  @override
  String get devicesFinishMatch => 'Match my device';

  @override
  String get devicesFinishEmber => 'Ember';

  @override
  String get devicesFinishLava => 'Lava';

  @override
  String get devicesFinishBlue => 'Blue';

  @override
  String get devicesFinishPink => 'Pink';

  @override
  String get devicesFinishMono => 'Mono';

  @override
  String get devicesDemoTry => 'Try the demo';

  @override
  String get devicesDemoTitle => 'Try kiln without a device';

  @override
  String get devicesDemoIntro =>
      'Pick a device to simulate. It heats up, reports its battery and reacts to every control. Nothing connects over Bluetooth and nothing is saved.';

  @override
  String get devicesDemoBack => 'Back';

  @override
  String get devicesDemoVolcanoDescription =>
      'Live temperature, heater and air';

  @override
  String get devicesDemoPortableDescription => 'Heater, boost and battery';

  @override
  String devicesDemoStartSemantics(String deviceName) {
    return 'Start the $deviceName demo';
  }

  @override
  String get devicesDemoBadge => 'Demo';

  @override
  String get devicesDemoLeaveSemantics => 'Leave the demo and go back';

  @override
  String get devicesDemoStart => 'Start';
}
