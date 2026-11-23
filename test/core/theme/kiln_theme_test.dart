import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('builds light and dark themes for every finish', () {
    for (final finish in [
      KilnPalette.ember,
      KilnPalette.lava,
      KilnPalette.blue,
      KilnPalette.pink,
      KilnPalette.mono,
    ]) {
      expect(
        buildKilnTheme(finish, Brightness.dark).colors.primary.base,
        finish.dark.accent,
      );
      expect(
        buildKilnTheme(finish, Brightness.light).colors.primary.base,
        finish.light.accent,
      );
    }
  });
}
