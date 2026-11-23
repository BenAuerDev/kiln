import '../../l10n/generated/app_localizations.dart';

abstract final class TemperatureFormatter {
  static int toFahrenheit(num celsius) => (celsius * 9 / 5 + 32).round();

  /// Degrees without unit, as used for large numbers in the UI.
  static String degrees(
    num celsius,
    AppLocalizations l10n, {
    bool fahrenheit = false,
  }) =>
      l10n.commonDegrees(fahrenheit ? toFahrenheit(celsius) : celsius.round());

  static String withUnit(
    num celsius,
    AppLocalizations l10n, {
    bool fahrenheit = false,
  }) => fahrenheit
      ? l10n.commonDegreesFahrenheit(toFahrenheit(celsius))
      : l10n.commonDegreesCelsius(celsius.round());
}
