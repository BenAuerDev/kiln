// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'kiln';

  @override
  String get commonUnofficialNotice =>
      'Inoffizielle App, nicht mit Storz & Bickel verbunden.';

  @override
  String commonSavedTo(String deviceName) {
    return 'Auf $deviceName gespeichert';
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
  String get commonCancel => 'Abbrechen';

  @override
  String commonSemanticsWithDetail(String label, String detail) {
    return '$label, $detail';
  }

  @override
  String commonSemanticsTitleSubtitle(String title, String subtitle) {
    return '$title. $subtitle';
  }

  @override
  String get errorBluetoothUnavailable =>
      'Bluetooth ist aus oder nicht verfügbar.';

  @override
  String get errorPermissionDenied =>
      'kiln braucht die Bluetooth-Berechtigung, um mit deinem Gerät zu sprechen.';

  @override
  String get errorDeviceNotFound =>
      'Gerät nicht gefunden. Ist es eingeschaltet und in der Nähe?';

  @override
  String get errorConnectionFailed =>
      'Verbindung fehlgeschlagen. Versuch es noch einmal.';

  @override
  String get errorConnectionLost => 'Verbindung verloren.';

  @override
  String get errorTimeout => 'Das Gerät hat nicht rechtzeitig geantwortet.';

  @override
  String get errorProtocol => 'Das Gerät hat etwas Unerwartetes gesendet.';

  @override
  String get errorStorage => 'Konnte auf diesem Handy nicht speichern.';

  @override
  String get errorWriteNotVerified =>
      'Dieser Befehl ist deaktiviert, bis er überprüft wurde.';

  @override
  String get errorNotConnected => 'Kein Gerät verbunden.';

  @override
  String get errorUnknown => 'Etwas ist schiefgelaufen.';

  @override
  String get navControl => 'Steuerung';

  @override
  String get navSetup => 'Einstellen';

  @override
  String get navDevices => 'Geräte';

  @override
  String get navWorkflows => 'Abläufe';

  @override
  String get portableDefaultName => 'Vaporizer';

  @override
  String portableBatteryLevel(int percent) {
    return '$percent % Akku';
  }

  @override
  String portableBatteryCharging(int percent) {
    return '$percent % · lädt';
  }

  @override
  String portableStatusLine(String first, String second) {
    return '$first · $second';
  }

  @override
  String portableOpenSettings(String deviceName) {
    return 'Einstellungen für $deviceName';
  }

  @override
  String portableSetupIntro(String deviceName) {
    return 'Dein $deviceName merkt sich diese Einstellungen. Stell sie hier einmal ein und nutz dann einfach die Taste.';
  }

  @override
  String portableScaleLabel(String base, String boost, String superBoost) {
    return 'Basis $base, Boost $boost, Superboost $superBoost';
  }

  @override
  String get portableBaseName => 'Basis';

  @override
  String get portableBaseHint => 'Wenn du ihn einschaltest';

  @override
  String get portableBaseSub => 'Start';

  @override
  String get portableBoostName => 'Boost';

  @override
  String get portableBoostHint => 'Doppelklick';

  @override
  String get portableSuperBoostName => 'Superboost';

  @override
  String get portableSuperBoostHint => 'Noch ein Doppelklick';

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
    return '→ $temperature max.';
  }

  @override
  String get portableLowerBase => 'Basistemperatur senken';

  @override
  String get portableRaiseBase => 'Basistemperatur erhöhen';

  @override
  String get portableLowerBoost => 'Boost senken';

  @override
  String get portableRaiseBoost => 'Boost erhöhen';

  @override
  String get portableLowerSuperBoost => 'Superboost senken';

  @override
  String get portableRaiseSuperBoost => 'Superboost erhöhen';

  @override
  String get portableQuickSetups => 'Schnellauswahl';

  @override
  String get portableQuickSetupFlavour => 'Geschmack';

  @override
  String get portableQuickSetupBalanced => 'Ausgewogen';

  @override
  String get portableQuickSetupFull => 'Voll';

  @override
  String portableQuickSetupRange(int from, int to) {
    return '$from–$to°';
  }

  @override
  String get portableGaugeLabel => 'Temperaturanzeige';

  @override
  String get portablePhaseOff => 'Heizung aus';

  @override
  String get portablePhaseHeating => 'Heizt';

  @override
  String get portablePhaseReady => 'Bereit';

  @override
  String get portableNoTemperature => '–';

  @override
  String portableCurrentTemperatureLabel(String temperature) {
    return 'Aktuelle Temperatur $temperature';
  }

  @override
  String portableTargetTemperatureLabel(String temperature) {
    return 'Zieltemperatur $temperature';
  }

  @override
  String portableTargetLine(String temperature) {
    return 'Ziel $temperature';
  }

  @override
  String get portableTargetOnlyLine => 'Zieltemperatur';

  @override
  String get portableSetTemperature => 'eingestellte Temperatur';

  @override
  String get portableLowerTarget => 'Zieltemperatur senken';

  @override
  String get portableRaiseTarget => 'Zieltemperatur erhöhen';

  @override
  String portablePresetLabel(String temperature) {
    return 'Ziel auf $temperature setzen';
  }

  @override
  String get portableHeaterOn => 'Heizung an';

  @override
  String get portableHeaterOff => 'Heizung aus';

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
  String get portableSettingsBack => 'Zurück';

  @override
  String portableFindTitle(String deviceName) {
    return 'Finde meinen $deviceName';
  }

  @override
  String get portableFindSubtitle => 'Lässt ihn vibrieren und blinken';

  @override
  String portableFindingTitle(String deviceName) {
    return 'Dein $deviceName vibriert…';
  }

  @override
  String get portableFindingSubtitle => 'Hör auf das Summen';

  @override
  String get portableBatteryHeading => 'Akku';

  @override
  String get portableChargeLimitTitle => 'Ladegrenze';

  @override
  String get portableChargeLimitSubtitle =>
      'Hört bei etwa 90 % auf zu laden, damit der Akku mehr Jahre hält.';

  @override
  String get portableBatterySaverTitle => 'Akkusparmodus';

  @override
  String get portableBatterySaverSubtitle =>
      'Heizt etwas sanfter für mehr Sessions pro Ladung.';

  @override
  String get portableDeviceHeading => 'Gerät';

  @override
  String get portableVibrateTitle => 'Vibrieren, wenn bereit';

  @override
  String get portableVibrateSubtitle =>
      'Summt, sobald die Temperatur erreicht ist.';

  @override
  String get portableBoostLedsTitle => 'Boost auf den LEDs zeigen';

  @override
  String get portableBoostLedsSubtitle =>
      'Das Licht zeigt dir, auf welcher Stufe du bist.';

  @override
  String get portableUnitTitle => 'Temperatureinheit';

  @override
  String get portableUnitCelsius => '°C';

  @override
  String get portableUnitFahrenheit => '°F';

  @override
  String get portableThemeHeading => 'App-Design';

  @override
  String get portableThemeMatchTitle => 'Wie mein Gerät';

  @override
  String portableThemeMatchDetected(String finish, String deviceName) {
    return '$finish, von deinem $deviceName gelesen';
  }

  @override
  String get portableThemeMatchUnknown => 'Noch nicht gelesen, bis dahin Ember';

  @override
  String portableThemeSwatchLabel(String finish) {
    return 'Design $finish';
  }

  @override
  String portableThemeNote(String deviceName) {
    return 'Nur für diesen $deviceName. Jedes Gerät behält sein eigenes Design.';
  }

  @override
  String get portableForgetDevice => 'Dieses Gerät vergessen';

  @override
  String portableForgetTitle(String deviceName) {
    return '$deviceName vergessen?';
  }

  @override
  String get portableForgetBody =>
      'kiln trennt die Verbindung und entfernt es samt Design aus deinen Geräten.';

  @override
  String get portableForgetConfirm => 'Vergessen';

  @override
  String get volcanoDefaultName => 'Volcano Hybrid';

  @override
  String volcanoDeviceLine(String deviceName, String connection) {
    return '$deviceName · $connection';
  }

  @override
  String get volcanoGaugeLabel => 'Temperaturanzeige';

  @override
  String get volcanoPhaseOff => 'Heizung aus';

  @override
  String get volcanoPhaseHeating => 'Heizt auf';

  @override
  String get volcanoPhaseReady => 'Bereit';

  @override
  String get volcanoNoTemperature => '–';

  @override
  String volcanoCurrentTemperatureLabel(String temperature) {
    return 'Aktuelle Temperatur $temperature';
  }

  @override
  String volcanoTargetLine(String temperature) {
    return 'Ziel $temperature';
  }

  @override
  String get volcanoSetTemperature => 'Solltemperatur';

  @override
  String get volcanoLowerTarget => 'Zieltemperatur senken';

  @override
  String get volcanoRaiseTarget => 'Zieltemperatur erhöhen';

  @override
  String volcanoPresetLabel(String temperature) {
    return 'Ziel auf $temperature setzen';
  }

  @override
  String get volcanoHeaterOn => 'Heizung an';

  @override
  String get volcanoHeaterOff => 'Heizung aus';

  @override
  String get volcanoAirOn => 'Luft an';

  @override
  String get volcanoAirOff => 'Luft aus';

  @override
  String get welcomeLanguageLabel => 'Sprache';

  @override
  String get welcomeTitle => 'Lass uns deinen Verdampfer finden';

  @override
  String get welcomeBody =>
      'kiln spricht per Bluetooth mit deinem Gerät. Dein Handy fragt gleich nach der Erlaubnis.';

  @override
  String get welcomePointPrivacy => 'Kein Konto. Nichts verlässt dein Handy.';

  @override
  String get welcomePointReconnect =>
      'Verbindet sich beim nächsten Mal von selbst.';

  @override
  String get welcomePointDevices => 'Volcano Hybrid, Venty, Veazy und Crafty+.';

  @override
  String get welcomeContinue => 'Weiter';

  @override
  String get welcomeScanLooking => 'Ich schau mich um…';

  @override
  String welcomeScanFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gefunden',
      one: 'Eins gefunden',
    );
    return '$_temp0';
  }

  @override
  String get welcomeScanNothing => 'Noch nichts gefunden';

  @override
  String get welcomeScanHint => 'Schalte es ein und halte es in der Nähe.';

  @override
  String get welcomeScanAgain => 'Nochmal suchen';

  @override
  String get welcomeSkip => 'Erst mal überspringen';

  @override
  String get welcomeScanSemantics => 'Suche nach Geräten';

  @override
  String get devicesTitle => 'Geräte';

  @override
  String get devicesBack => 'Zurück zur Steuerung';

  @override
  String get devicesYours => 'Deine Geräte';

  @override
  String get devicesEmpty =>
      'Noch keine Geräte. Schalte deins ein, dann taucht es unten auf.';

  @override
  String get devicesActive => 'Aktiv';

  @override
  String get devicesStatusConnected => 'Verbunden';

  @override
  String get devicesStatusConnecting => 'Verbinde…';

  @override
  String get devicesStatusReconnecting => 'Verbinde erneut…';

  @override
  String get devicesStatusDisconnected => 'Nicht verbunden';

  @override
  String get devicesStatusUnavailable => 'Nicht erreichbar';

  @override
  String get devicesStatusInlineConnected => 'verbunden';

  @override
  String get devicesStatusInlineConnecting => 'verbindet …';

  @override
  String get devicesStatusInlineReconnecting => 'verbindet erneut …';

  @override
  String get devicesStatusInlineDisconnected => 'nicht verbunden';

  @override
  String get devicesStatusInlineUnavailable => 'nicht erreichbar';

  @override
  String devicesLastUsed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Zuletzt vor $days Tagen benutzt',
      one: 'Zuletzt gestern benutzt',
      zero: 'Zuletzt heute benutzt',
    );
    return '$_temp0';
  }

  @override
  String get devicesNeverUsed => 'Noch nicht benutzt';

  @override
  String get devicesScanning => 'Suche in der Nähe';

  @override
  String get devicesNearby => 'In der Nähe';

  @override
  String get devicesScan => 'Suchen';

  @override
  String get devicesNoneNearby => 'Nichts Neues in der Nähe.';

  @override
  String get devicesSignalStrong => 'Starkes Signal';

  @override
  String get devicesSignalFair => 'Mittleres Signal';

  @override
  String get devicesSignalWeak => 'Schwaches Signal';

  @override
  String devicesNearbySubtitle(String signal) {
    return '$signal · nicht gekoppelt';
  }

  @override
  String get devicesPair => 'Koppeln';

  @override
  String get devicesConnect => 'Verbinden';

  @override
  String devicesConnectSemantics(String deviceName) {
    return 'Mit $deviceName verbinden';
  }

  @override
  String devicesOpenSemantics(String deviceName) {
    return '$deviceName öffnen';
  }

  @override
  String get devicesDisconnect => 'Trennen';

  @override
  String get devicesForget => 'Vergessen';

  @override
  String devicesForgetSemantics(String deviceName) {
    return '$deviceName vergessen';
  }

  @override
  String get devicesForgetConfirm => 'Dieses Gerät vergessen?';

  @override
  String devicesForgotten(String deviceName) {
    return '$deviceName vergessen';
  }

  @override
  String devicesNotSupportedYet(String deviceName) {
    return '$deviceName wird noch nicht unterstützt.';
  }

  @override
  String get devicesUnofficialNotice =>
      'Inoffizielle App. Nicht mit Storz & Bickel verbunden und nicht von Storz & Bickel unterstützt. Gerätenamen dienen nur zur Angabe der Kompatibilität.';

  @override
  String get devicesFinishMatch => 'Wie mein Gerät';

  @override
  String get devicesFinishEmber => 'Glut';

  @override
  String get devicesFinishLava => 'Lava';

  @override
  String get devicesFinishBlue => 'Blau';

  @override
  String get devicesFinishPink => 'Pink';

  @override
  String get devicesFinishMono => 'Mono';

  @override
  String get devicesDemoTry => 'Demo ausprobieren';

  @override
  String get devicesDemoTitle => 'kiln ohne Gerät ausprobieren';

  @override
  String get devicesDemoIntro =>
      'Wähle ein Gerät, das simuliert wird. Es heizt auf, meldet seinen Akku und reagiert auf jede Einstellung. Nichts wird per Bluetooth verbunden und nichts gespeichert.';

  @override
  String get devicesDemoBack => 'Zurück';

  @override
  String get devicesDemoVolcanoDescription =>
      'Live-Temperatur, Heizung und Luft';

  @override
  String get devicesDemoPortableDescription => 'Heizung, Boost und Akku';

  @override
  String devicesDemoStartSemantics(String deviceName) {
    return 'Demo von $deviceName starten';
  }

  @override
  String get devicesDemoBadge => 'Demo';

  @override
  String get devicesDemoLeaveSemantics => 'Demo beenden und zurückgehen';

  @override
  String get devicesDemoStart => 'Starten';

  @override
  String get workflowsTitle => 'Abläufe';

  @override
  String get workflowsIntro =>
      'Schritt für Schritt: heizen, warten, Ballon füllen. kiln macht den Rest.';

  @override
  String get workflowsPresets => 'Vorlagen';

  @override
  String get workflowsYours => 'Deine Abläufe';

  @override
  String get workflowsNoneYet =>
      'Noch keine. Bearbeite eine Vorlage oder fang neu an.';

  @override
  String get workflowsNew => 'Neuer Ablauf';

  @override
  String get workflowsStart => 'Starten';

  @override
  String workflowsStartSemantics(String name) {
    return '$name starten';
  }

  @override
  String workflowsEditSemantics(String name) {
    return '$name bearbeiten';
  }

  @override
  String workflowsStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schritte',
      one: '1 Schritt',
    );
    return '$_temp0';
  }

  @override
  String durationAboutMinutes(int minutes) {
    return 'etwa $minutes Min.';
  }

  @override
  String get durationUnderAMinute => 'unter einer Minute';

  @override
  String workflowsSummary(String steps, String duration) {
    return '$steps · $duration';
  }

  @override
  String workflowsDeviceSummary(String summary) {
    return 'Volcano Hybrid · $summary';
  }

  @override
  String get workflowsRunningNow => 'Läuft gerade';

  @override
  String get workflowsOpenRun => 'Öffnen';

  @override
  String get workflowsPresetThreeBalloons => 'Drei-Ballon-Session';

  @override
  String get workflowsPresetSingleBalloon => 'Ein Ballon';

  @override
  String get workflowsPresetFlavourLadder => 'Aroma-Leiter';

  @override
  String get workflowsRunTitle => 'Ablauf';

  @override
  String get workflowsBack => 'Zurück';

  @override
  String get workflowsEdit => 'Ablauf bearbeiten';

  @override
  String workflowsStepOf(int current, int total, String kind) {
    return 'Schritt $current von $total · $kind';
  }

  @override
  String get workflowsKindHeat => 'Heizen';

  @override
  String get workflowsKindHold => 'Halten';

  @override
  String get workflowsKindAir => 'Luft';

  @override
  String get workflowsPaused => 'Pausiert · Volcano nicht verbunden';

  @override
  String get workflowsFinished => 'Fertig';

  @override
  String get workflowsStopped => 'Gestoppt';

  @override
  String get workflowsInterrupted =>
      'Gestoppt · Volcano nicht erreichbar, er läuft eventuell noch';

  @override
  String get workflowsSkip => 'Schritt überspringen';

  @override
  String get workflowsStop => 'Stopp';

  @override
  String get workflowsDone => 'Fertig';

  @override
  String get workflowsRunAgain => 'Nochmal starten';

  @override
  String get workflowsNoRun => 'Gerade läuft kein Ablauf.';

  @override
  String workflowsHeatTitle(int celsius) {
    return 'Auf $celsius °C heizen';
  }

  @override
  String workflowsHoldTitle(String duration) {
    return '$duration halten';
  }

  @override
  String workflowsAirTitle(String duration) {
    return 'Luft $duration';
  }

  @override
  String get workflowsHeatSubtitle => 'Warten bis bereit, dann vibrieren';

  @override
  String get workflowsHoldSubtitle => 'Temperatur halten';

  @override
  String workflowsAirSubtitle(int number) {
    return 'Ballon $number füllen';
  }

  @override
  String workflowsThenHeaterOff(String subtitle) {
    return '$subtitle, danach Heizung aus';
  }

  @override
  String get workflowsTagDone => 'Fertig';

  @override
  String get workflowsTagNow => 'Jetzt';

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes Min. $seconds s';
  }

  @override
  String get workflowsEditorNewTitle => 'Neuer Ablauf';

  @override
  String get workflowsEditorEditTitle => 'Ablauf bearbeiten';

  @override
  String get workflowsEditorName => 'Name';

  @override
  String get workflowsEditorNameHint => 'z. B. Abendsession';

  @override
  String get workflowsEditorSteps => 'Schritte';

  @override
  String get workflowsEditorNoSteps => 'Füge mindestens einen Schritt hinzu.';

  @override
  String workflowsEditorAddSemantics(String kind) {
    return 'Schritt hinzufügen: $kind';
  }

  @override
  String get workflowsEditorHeaterOff => 'Am Ende Heizung aus';

  @override
  String get workflowsEditorHeaterOffHint =>
      'Empfohlen, damit der Volcano nicht weiterheizt.';

  @override
  String get workflowsEditorSave => 'Speichern';

  @override
  String get workflowsEditorDelete => 'Ablauf löschen';

  @override
  String get workflowsEditorDeleteConfirm => 'Zum Löschen nochmal tippen';

  @override
  String workflowsEditorLower(String step) {
    return 'Verringern: $step';
  }

  @override
  String workflowsEditorRaise(String step) {
    return 'Erhöhen: $step';
  }

  @override
  String workflowsEditorMoveUp(String step) {
    return 'Nach oben: $step';
  }

  @override
  String workflowsEditorMoveDown(String step) {
    return 'Nach unten: $step';
  }

  @override
  String workflowsEditorRemove(String step) {
    return 'Entfernen: $step';
  }

  @override
  String get workflowsSaved => 'Ablauf gespeichert';

  @override
  String get workflowsDeleted => 'Ablauf gelöscht';

  @override
  String get workflowsStopFailed =>
      'Gestoppt. kiln hat den Volcano nicht erreicht, er heizt eventuell noch.';

  @override
  String get rampsTitle => 'Rampe';

  @override
  String get rampsIntro =>
      'Die Basis steigt Schritt für Schritt, während du dampfst. Boost funktioniert weiter.';

  @override
  String get rampsChoose => 'Rampe wählen';

  @override
  String get rampsPresetGentle => 'Sanft';

  @override
  String get rampsPresetClassic => 'Klassisch';

  @override
  String get rampsPresetQuick => 'Schnell';

  @override
  String rampsRange(int start, int end) {
    return '$start–$end°';
  }

  @override
  String rampsSummary(int step, String interval, String total) {
    return '+$step° alle $interval · $total';
  }

  @override
  String get rampsStart => 'Rampe starten';

  @override
  String get rampsStop => 'Rampe stoppen';

  @override
  String get rampsNotWhileBoosting => 'Nicht während Boost';

  @override
  String rampsNow(int target, int next, String time) {
    return 'Jetzt $target° · $next° in $time';
  }

  @override
  String rampsWaitingForBoost(int target, int next) {
    return 'Jetzt $target° · $next° nach dem Boost';
  }

  @override
  String rampsFinished(int target) {
    return 'Rampe fertig · $target°';
  }

  @override
  String get rampsRunning => 'Rampe läuft';

  @override
  String get backgroundChannelSession => 'Laufende Session';

  @override
  String get backgroundChannelReady => 'Bereit-Hinweise';

  @override
  String backgroundTitle(String device, int temperature) {
    return '$device · $temperature°';
  }

  @override
  String backgroundHeating(int target) {
    return 'Heizt auf $target°';
  }

  @override
  String backgroundReady(int target) {
    return 'Bereit bei $target°';
  }

  @override
  String backgroundWithBattery(String text, int battery) {
    return '$text · Akku $battery %';
  }

  @override
  String backgroundWorkflow(String name, String step) {
    return '$name: $step';
  }

  @override
  String backgroundReadyTitle(String device, int temperature) {
    return '$device ist bereit · $temperature°';
  }

  @override
  String backgroundReadyBoost(int boost) {
    return 'Doppelklick für Boost $boost°';
  }

  @override
  String get backgroundReadyVolcano => 'Zeit, einen Ballon zu füllen.';

  @override
  String get backgroundReadyPlain => 'Kann losgehen.';

  @override
  String homeWidgetBattery(int percent) {
    return '$percent %';
  }

  @override
  String get homeWidgetBase => 'Basis';

  @override
  String get homeWidgetBoost => 'Boost';

  @override
  String get homeWidgetSuper => 'Super';

  @override
  String homeWidgetTemperature(int temperature) {
    return '$temperature°';
  }

  @override
  String get homeWidgetNoTemperature => '–';

  @override
  String homeWidgetHeating(int target) {
    return 'Heizt auf $target°';
  }

  @override
  String homeWidgetReady(int target) {
    return 'Bereit bei $target°';
  }

  @override
  String homeWidgetHeaterOff(int target) {
    return 'Heizung aus · $target°';
  }

  @override
  String get homeWidgetOffline => 'Nicht verbunden';

  @override
  String get homeWidgetHeat => 'Heizen';

  @override
  String get homeWidgetHeatOff => 'Heizung aus';

  @override
  String get homeWidgetAir => 'Luft';

  @override
  String get homeWidgetAirOff => 'Luft aus';

  @override
  String homeWidgetVolcanoGauge(String device, int temperature, int target) {
    return '$device bei $temperature von $target Grad';
  }

  @override
  String homeWidgetVolcanoGaugeNoReading(String device) {
    return '$device, noch keine Temperatur';
  }

  @override
  String get homeWidgetSuperBoost => 'Superboost';

  @override
  String get homeWidgetBoostOff => 'Boost aus';

  @override
  String homeWidgetPortableRing(String device, int percent) {
    return '$device, Akku $percent %';
  }

  @override
  String homeWidgetPortableLadder(int base, int boost, int superBoost) {
    return 'Basis $base°, Boost $boost°, Superboost $superBoost°';
  }
}
