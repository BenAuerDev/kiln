import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/core/services/toast_service.dart';
import 'package:kiln/core/theme/kiln_palette.dart';
import 'package:kiln/core/theme/kiln_theme.dart';
import 'package:kiln/core/theme/kiln_theme_scope.dart';
import 'package:kiln/core/widgets/kiln_toast.dart';
import 'package:obers_ui/obers_ui.dart';

void main() {
  testWidgets('sits above the system inset and the tab bar', (tester) async {
    const size = Size(390, 844);
    const systemInset = 34.0;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      KilnThemeScope(
        finish: KilnPalette.ember,
        child: OiApp(
          theme: buildKilnTheme(KilnPalette.ember, Brightness.dark),
          darkTheme: buildKilnTheme(KilnPalette.ember, Brightness.dark),
          home: const MediaQuery(
            data: MediaQueryData(
              size: size,
              viewPadding: EdgeInsets.only(bottom: systemInset),
              disableAnimations: true,
            ),
            child: KilnToast(
              message: 'Saved to Veazy',
              level: ToastLevel.success,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pill = tester.getRect(find.byType(DecoratedBox).last);
    expect(find.text('Saved to Veazy'), findsOneWidget);
    expect(pill.bottom, lessThanOrEqualTo(size.height - systemInset - 88));
  });
}
