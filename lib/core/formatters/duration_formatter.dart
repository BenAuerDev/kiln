import '../../l10n/generated/app_localizations.dart';

abstract final class DurationFormatter {
  /// `0:18`, `12:05`: minutes and seconds of a running clock.
  static String clock(Duration duration) {
    final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '${seconds ~/ 60}:$rest';
  }

  /// `45 s`, `2 min`, `1 min 30 s`.
  static String short(Duration duration, AppLocalizations l10n) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return l10n.durationSeconds(seconds);
    if (seconds == 0) return l10n.durationMinutes(minutes);
    return l10n.durationMinutesSeconds(minutes, seconds);
  }

  /// `about 5 min`, or `under a minute`. Rounded to the nearest minute.
  static String about(Duration duration, AppLocalizations l10n) {
    final minutes = (duration.inSeconds / 60).round();
    return minutes < 1
        ? l10n.durationUnderAMinute
        : l10n.durationAboutMinutes(minutes);
  }
}
