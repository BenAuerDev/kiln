import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'kiln'**
  String get appTitle;

  /// No description provided for @commonUnofficialNotice.
  ///
  /// In en, this message translates to:
  /// **'Unofficial app, not affiliated with Storz & Bickel.'**
  String get commonUnofficialNotice;

  /// No description provided for @commonSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {deviceName}'**
  String commonSavedTo(String deviceName);

  /// No description provided for @commonDegrees.
  ///
  /// In en, this message translates to:
  /// **'{value}°'**
  String commonDegrees(int value);

  /// No description provided for @commonDegreesCelsius.
  ///
  /// In en, this message translates to:
  /// **'{value} °C'**
  String commonDegreesCelsius(int value);

  /// No description provided for @commonDegreesFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'{value} °F'**
  String commonDegreesFahrenheit(int value);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSemanticsWithDetail.
  ///
  /// In en, this message translates to:
  /// **'{label}, {detail}'**
  String commonSemanticsWithDetail(String label, String detail);

  /// No description provided for @commonSemanticsTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{title}. {subtitle}'**
  String commonSemanticsTitleSubtitle(String title, String subtitle);

  /// No description provided for @errorBluetoothUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off or not available.'**
  String get errorBluetoothUnavailable;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'kiln needs Bluetooth permission to talk to your device.'**
  String get errorPermissionDenied;

  /// No description provided for @errorDeviceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Device not found. Is it switched on and nearby?'**
  String get errorDeviceNotFound;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Try again.'**
  String get errorConnectionFailed;

  /// No description provided for @errorConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost.'**
  String get errorConnectionLost;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The device didn\'t answer in time.'**
  String get errorTimeout;

  /// No description provided for @errorProtocol.
  ///
  /// In en, this message translates to:
  /// **'The device sent something unexpected.'**
  String get errorProtocol;

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save on this phone.'**
  String get errorStorage;

  /// No description provided for @errorWriteNotVerified.
  ///
  /// In en, this message translates to:
  /// **'This command is disabled until it has been verified.'**
  String get errorWriteNotVerified;

  /// No description provided for @errorNotConnected.
  ///
  /// In en, this message translates to:
  /// **'No device connected.'**
  String get errorNotConnected;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnknown;

  /// No description provided for @navControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get navControl;

  /// No description provided for @navSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get navSetup;

  /// No description provided for @navDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get navDevices;

  /// No description provided for @portableDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Vaporizer'**
  String get portableDefaultName;

  /// No description provided for @portableBatteryLevel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% battery'**
  String portableBatteryLevel(int percent);

  /// No description provided for @portableBatteryCharging.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · charging'**
  String portableBatteryCharging(int percent);

  /// No description provided for @portableStatusLine.
  ///
  /// In en, this message translates to:
  /// **'{first} · {second}'**
  String portableStatusLine(String first, String second);

  /// No description provided for @portableOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} settings'**
  String portableOpenSettings(String deviceName);

  /// No description provided for @portableSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Your {deviceName} keeps these settings. Set them here once, then just use the button.'**
  String portableSetupIntro(String deviceName);

  /// No description provided for @portableScaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Base {base}, boost {boost}, superboost {superBoost}'**
  String portableScaleLabel(String base, String boost, String superBoost);

  /// No description provided for @portableBaseName.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get portableBaseName;

  /// No description provided for @portableBaseHint.
  ///
  /// In en, this message translates to:
  /// **'When you switch it on'**
  String get portableBaseHint;

  /// No description provided for @portableBaseSub.
  ///
  /// In en, this message translates to:
  /// **'start'**
  String get portableBaseSub;

  /// No description provided for @portableBoostName.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get portableBoostName;

  /// No description provided for @portableBoostHint.
  ///
  /// In en, this message translates to:
  /// **'Double-click'**
  String get portableBoostHint;

  /// No description provided for @portableSuperBoostName.
  ///
  /// In en, this message translates to:
  /// **'Superboost'**
  String get portableSuperBoostName;

  /// No description provided for @portableSuperBoostHint.
  ///
  /// In en, this message translates to:
  /// **'Double-click again'**
  String get portableSuperBoostHint;

  /// No description provided for @portableOffset.
  ///
  /// In en, this message translates to:
  /// **'+{value}°'**
  String portableOffset(int value);

  /// No description provided for @portableLadderTo.
  ///
  /// In en, this message translates to:
  /// **'→ {temperature}'**
  String portableLadderTo(String temperature);

  /// No description provided for @portableLadderToMax.
  ///
  /// In en, this message translates to:
  /// **'→ {temperature} max'**
  String portableLadderToMax(String temperature);

  /// No description provided for @portableLowerBase.
  ///
  /// In en, this message translates to:
  /// **'Lower base temperature'**
  String get portableLowerBase;

  /// No description provided for @portableRaiseBase.
  ///
  /// In en, this message translates to:
  /// **'Raise base temperature'**
  String get portableRaiseBase;

  /// No description provided for @portableLowerBoost.
  ///
  /// In en, this message translates to:
  /// **'Lower boost'**
  String get portableLowerBoost;

  /// No description provided for @portableRaiseBoost.
  ///
  /// In en, this message translates to:
  /// **'Raise boost'**
  String get portableRaiseBoost;

  /// No description provided for @portableLowerSuperBoost.
  ///
  /// In en, this message translates to:
  /// **'Lower superboost'**
  String get portableLowerSuperBoost;

  /// No description provided for @portableRaiseSuperBoost.
  ///
  /// In en, this message translates to:
  /// **'Raise superboost'**
  String get portableRaiseSuperBoost;

  /// No description provided for @portableQuickSetups.
  ///
  /// In en, this message translates to:
  /// **'Quick setups'**
  String get portableQuickSetups;

  /// No description provided for @portableQuickSetupFlavour.
  ///
  /// In en, this message translates to:
  /// **'Flavour'**
  String get portableQuickSetupFlavour;

  /// No description provided for @portableQuickSetupBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get portableQuickSetupBalanced;

  /// No description provided for @portableQuickSetupFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get portableQuickSetupFull;

  /// No description provided for @portableQuickSetupRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}°'**
  String portableQuickSetupRange(int from, int to);

  /// No description provided for @portableGaugeLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature gauge'**
  String get portableGaugeLabel;

  /// No description provided for @portablePhaseOff.
  ///
  /// In en, this message translates to:
  /// **'Heater off'**
  String get portablePhaseOff;

  /// No description provided for @portablePhaseHeating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get portablePhaseHeating;

  /// No description provided for @portablePhaseReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get portablePhaseReady;

  /// No description provided for @portableNoTemperature.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get portableNoTemperature;

  /// No description provided for @portableCurrentTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Current temperature {temperature}'**
  String portableCurrentTemperatureLabel(String temperature);

  /// No description provided for @portableTargetTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Target temperature {temperature}'**
  String portableTargetTemperatureLabel(String temperature);

  /// No description provided for @portableTargetLine.
  ///
  /// In en, this message translates to:
  /// **'target {temperature}'**
  String portableTargetLine(String temperature);

  /// No description provided for @portableTargetOnlyLine.
  ///
  /// In en, this message translates to:
  /// **'target temperature'**
  String get portableTargetOnlyLine;

  /// No description provided for @portableSetTemperature.
  ///
  /// In en, this message translates to:
  /// **'set temperature'**
  String get portableSetTemperature;

  /// No description provided for @portableLowerTarget.
  ///
  /// In en, this message translates to:
  /// **'Lower target temperature'**
  String get portableLowerTarget;

  /// No description provided for @portableRaiseTarget.
  ///
  /// In en, this message translates to:
  /// **'Raise target temperature'**
  String get portableRaiseTarget;

  /// No description provided for @portablePresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Set target to {temperature}'**
  String portablePresetLabel(String temperature);

  /// No description provided for @portableHeaterOn.
  ///
  /// In en, this message translates to:
  /// **'Heater on'**
  String get portableHeaterOn;

  /// No description provided for @portableHeaterOff.
  ///
  /// In en, this message translates to:
  /// **'Heater off'**
  String get portableHeaterOff;

  /// No description provided for @portableBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get portableBoost;

  /// No description provided for @portableBoostOn.
  ///
  /// In en, this message translates to:
  /// **'Boost +{value}°'**
  String portableBoostOn(int value);

  /// No description provided for @portableSettingsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get portableSettingsBack;

  /// No description provided for @portableFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Find my {deviceName}'**
  String portableFindTitle(String deviceName);

  /// No description provided for @portableFindSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Makes it vibrate and blink'**
  String get portableFindSubtitle;

  /// No description provided for @portableFindingTitle.
  ///
  /// In en, this message translates to:
  /// **'Buzzing your {deviceName}…'**
  String portableFindingTitle(String deviceName);

  /// No description provided for @portableFindingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listen for the vibration'**
  String get portableFindingSubtitle;

  /// No description provided for @portableBatteryHeading.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get portableBatteryHeading;

  /// No description provided for @portableChargeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Charge limit'**
  String get portableChargeLimitTitle;

  /// No description provided for @portableChargeLimitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stops charging around 90% so the battery lasts more years.'**
  String get portableChargeLimitSubtitle;

  /// No description provided for @portableBatterySaverTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery saver'**
  String get portableBatterySaverTitle;

  /// No description provided for @portableBatterySaverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Heats a little gentler for more sessions per charge.'**
  String get portableBatterySaverSubtitle;

  /// No description provided for @portableDeviceHeading.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get portableDeviceHeading;

  /// No description provided for @portableVibrateTitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when ready'**
  String get portableVibrateTitle;

  /// No description provided for @portableVibrateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buzzes once it reaches temperature.'**
  String get portableVibrateSubtitle;

  /// No description provided for @portableBoostLedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show boost on LEDs'**
  String get portableBoostLedsTitle;

  /// No description provided for @portableBoostLedsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The light tells you which level you are on.'**
  String get portableBoostLedsSubtitle;

  /// No description provided for @portableUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Temperature unit'**
  String get portableUnitTitle;

  /// No description provided for @portableUnitCelsius.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get portableUnitCelsius;

  /// No description provided for @portableUnitFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'°F'**
  String get portableUnitFahrenheit;

  /// No description provided for @portableThemeHeading.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get portableThemeHeading;

  /// No description provided for @portableThemeMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Match my device'**
  String get portableThemeMatchTitle;

  /// No description provided for @portableThemeMatchDetected.
  ///
  /// In en, this message translates to:
  /// **'{finish}, read from your {deviceName}'**
  String portableThemeMatchDetected(String finish, String deviceName);

  /// No description provided for @portableThemeMatchUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not read yet, Ember until then'**
  String get portableThemeMatchUnknown;

  /// No description provided for @portableThemeSwatchLabel.
  ///
  /// In en, this message translates to:
  /// **'{finish} theme'**
  String portableThemeSwatchLabel(String finish);

  /// No description provided for @portableThemeNote.
  ///
  /// In en, this message translates to:
  /// **'Only for this {deviceName}. Each device keeps its own theme.'**
  String portableThemeNote(String deviceName);

  /// No description provided for @portableForgetDevice.
  ///
  /// In en, this message translates to:
  /// **'Forget this device'**
  String get portableForgetDevice;

  /// No description provided for @portableForgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget {deviceName}?'**
  String portableForgetTitle(String deviceName);

  /// No description provided for @portableForgetBody.
  ///
  /// In en, this message translates to:
  /// **'kiln disconnects and removes it from your devices, together with its theme.'**
  String get portableForgetBody;

  /// No description provided for @portableForgetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get portableForgetConfirm;

  /// No description provided for @volcanoDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Volcano Hybrid'**
  String get volcanoDefaultName;

  /// No description provided for @volcanoDeviceLine.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} · {connection}'**
  String volcanoDeviceLine(String deviceName, String connection);

  /// No description provided for @volcanoGaugeLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature gauge'**
  String get volcanoGaugeLabel;

  /// No description provided for @volcanoPhaseOff.
  ///
  /// In en, this message translates to:
  /// **'Heater off'**
  String get volcanoPhaseOff;

  /// No description provided for @volcanoPhaseHeating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get volcanoPhaseHeating;

  /// No description provided for @volcanoPhaseReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get volcanoPhaseReady;

  /// No description provided for @volcanoNoTemperature.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get volcanoNoTemperature;

  /// No description provided for @volcanoCurrentTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Current temperature {temperature}'**
  String volcanoCurrentTemperatureLabel(String temperature);

  /// No description provided for @volcanoTargetLine.
  ///
  /// In en, this message translates to:
  /// **'target {temperature}'**
  String volcanoTargetLine(String temperature);

  /// No description provided for @volcanoSetTemperature.
  ///
  /// In en, this message translates to:
  /// **'set temperature'**
  String get volcanoSetTemperature;

  /// No description provided for @volcanoLowerTarget.
  ///
  /// In en, this message translates to:
  /// **'Lower target temperature'**
  String get volcanoLowerTarget;

  /// No description provided for @volcanoRaiseTarget.
  ///
  /// In en, this message translates to:
  /// **'Raise target temperature'**
  String get volcanoRaiseTarget;

  /// No description provided for @volcanoPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Set target to {temperature}'**
  String volcanoPresetLabel(String temperature);

  /// No description provided for @volcanoHeaterOn.
  ///
  /// In en, this message translates to:
  /// **'Heater on'**
  String get volcanoHeaterOn;

  /// No description provided for @volcanoHeaterOff.
  ///
  /// In en, this message translates to:
  /// **'Heater off'**
  String get volcanoHeaterOff;

  /// No description provided for @volcanoAirOn.
  ///
  /// In en, this message translates to:
  /// **'Air on'**
  String get volcanoAirOn;

  /// No description provided for @volcanoAirOff.
  ///
  /// In en, this message translates to:
  /// **'Air off'**
  String get volcanoAirOff;

  /// No description provided for @welcomeLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get welcomeLanguageLabel;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s find your vaporizer'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'kiln talks to your device over Bluetooth. Your phone will ask for permission next.'**
  String get welcomeBody;

  /// No description provided for @welcomePointPrivacy.
  ///
  /// In en, this message translates to:
  /// **'No account. Nothing leaves your phone.'**
  String get welcomePointPrivacy;

  /// No description provided for @welcomePointReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnects by itself next time.'**
  String get welcomePointReconnect;

  /// No description provided for @welcomePointDevices.
  ///
  /// In en, this message translates to:
  /// **'Volcano Hybrid, Venty, Veazy and Crafty+.'**
  String get welcomePointDevices;

  /// No description provided for @welcomeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get welcomeContinue;

  /// No description provided for @welcomeScanLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking around…'**
  String get welcomeScanLooking;

  /// No description provided for @welcomeScanFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found one} other{Found {count}}}'**
  String welcomeScanFound(int count);

  /// No description provided for @welcomeScanNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found yet'**
  String get welcomeScanNothing;

  /// No description provided for @welcomeScanHint.
  ///
  /// In en, this message translates to:
  /// **'Switch it on and keep it close.'**
  String get welcomeScanHint;

  /// No description provided for @welcomeScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get welcomeScanAgain;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get welcomeSkip;

  /// No description provided for @welcomeScanSemantics.
  ///
  /// In en, this message translates to:
  /// **'Searching for devices'**
  String get welcomeScanSemantics;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devicesTitle;

  /// No description provided for @devicesBack.
  ///
  /// In en, this message translates to:
  /// **'Back to control'**
  String get devicesBack;

  /// No description provided for @devicesYours.
  ///
  /// In en, this message translates to:
  /// **'Your devices'**
  String get devicesYours;

  /// No description provided for @devicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No devices yet. Switch yours on and it shows up below.'**
  String get devicesEmpty;

  /// No description provided for @devicesActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get devicesActive;

  /// No description provided for @devicesStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get devicesStatusConnected;

  /// No description provided for @devicesStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get devicesStatusConnecting;

  /// No description provided for @devicesStatusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get devicesStatusReconnecting;

  /// No description provided for @devicesStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get devicesStatusDisconnected;

  /// No description provided for @devicesStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach it'**
  String get devicesStatusUnavailable;

  /// No description provided for @devicesStatusInlineConnected.
  ///
  /// In en, this message translates to:
  /// **'connected'**
  String get devicesStatusInlineConnected;

  /// No description provided for @devicesStatusInlineConnecting.
  ///
  /// In en, this message translates to:
  /// **'connecting…'**
  String get devicesStatusInlineConnecting;

  /// No description provided for @devicesStatusInlineReconnecting.
  ///
  /// In en, this message translates to:
  /// **'reconnecting…'**
  String get devicesStatusInlineReconnecting;

  /// No description provided for @devicesStatusInlineDisconnected.
  ///
  /// In en, this message translates to:
  /// **'not connected'**
  String get devicesStatusInlineDisconnected;

  /// No description provided for @devicesStatusInlineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get devicesStatusInlineUnavailable;

  /// No description provided for @devicesLastUsed.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Last used today} =1{Last used yesterday} other{Last used {days} days ago}}'**
  String devicesLastUsed(int days);

  /// No description provided for @devicesNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Not used yet'**
  String get devicesNeverUsed;

  /// No description provided for @devicesScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning nearby'**
  String get devicesScanning;

  /// No description provided for @devicesNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get devicesNearby;

  /// No description provided for @devicesScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get devicesScan;

  /// No description provided for @devicesNoneNearby.
  ///
  /// In en, this message translates to:
  /// **'Nothing new nearby.'**
  String get devicesNoneNearby;

  /// No description provided for @devicesSignalStrong.
  ///
  /// In en, this message translates to:
  /// **'Signal strong'**
  String get devicesSignalStrong;

  /// No description provided for @devicesSignalFair.
  ///
  /// In en, this message translates to:
  /// **'Signal fair'**
  String get devicesSignalFair;

  /// No description provided for @devicesSignalWeak.
  ///
  /// In en, this message translates to:
  /// **'Signal weak'**
  String get devicesSignalWeak;

  /// No description provided for @devicesNearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{signal} · not paired'**
  String devicesNearbySubtitle(String signal);

  /// No description provided for @devicesPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get devicesPair;

  /// No description provided for @devicesConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get devicesConnect;

  /// No description provided for @devicesConnectSemantics.
  ///
  /// In en, this message translates to:
  /// **'Connect to {deviceName}'**
  String devicesConnectSemantics(String deviceName);

  /// No description provided for @devicesOpenSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open {deviceName}'**
  String devicesOpenSemantics(String deviceName);

  /// No description provided for @devicesDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get devicesDisconnect;

  /// No description provided for @devicesForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get devicesForget;

  /// No description provided for @devicesForgetSemantics.
  ///
  /// In en, this message translates to:
  /// **'Forget {deviceName}'**
  String devicesForgetSemantics(String deviceName);

  /// No description provided for @devicesForgetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget this device?'**
  String get devicesForgetConfirm;

  /// No description provided for @devicesForgotten.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} forgotten'**
  String devicesForgotten(String deviceName);

  /// No description provided for @devicesNotSupportedYet.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} isn\'t supported yet.'**
  String devicesNotSupportedYet(String deviceName);

  /// No description provided for @devicesUnofficialNotice.
  ///
  /// In en, this message translates to:
  /// **'Unofficial app. Not affiliated with or endorsed by Storz & Bickel. Device names are used only to identify compatibility.'**
  String get devicesUnofficialNotice;

  /// No description provided for @devicesFinishMatch.
  ///
  /// In en, this message translates to:
  /// **'Match my device'**
  String get devicesFinishMatch;

  /// No description provided for @devicesFinishEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get devicesFinishEmber;

  /// No description provided for @devicesFinishLava.
  ///
  /// In en, this message translates to:
  /// **'Lava'**
  String get devicesFinishLava;

  /// No description provided for @devicesFinishBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get devicesFinishBlue;

  /// No description provided for @devicesFinishPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get devicesFinishPink;

  /// No description provided for @devicesFinishMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get devicesFinishMono;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
