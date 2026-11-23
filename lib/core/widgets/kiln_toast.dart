import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../services/toast_service.dart';
import '../theme/build_context_x.dart';

/// The pill from the "Saved to Veazy" mockup. Sits above the system inset and
/// the tab bar, which `OiToast` does not account for.
class KilnToast extends StatelessWidget {
  const KilnToast({required this.message, required this.level, super.key});

  final String message;
  final ToastLevel level;

  /// Clears kiln's bottom tab bar (mockup: 104 px from the bottom edge).
  static const _bottomOffset = 88.0;
  static const _entryCurve = Cubic(0.2, 0.9, 0.3, 1.2);

  @override
  Widget build(BuildContext context) {
    final surfaces = context.kiln.surfaces;
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom + _bottomOffset;
    final iconColor = switch (level) {
      ToastLevel.error => colors.error.base,
      ToastLevel.warning => colors.warning.base,
      ToastLevel.info || ToastLevel.success => surfaces.toastText,
    };
    final icon = switch (level) {
      ToastLevel.success => OiIcons.check,
      ToastLevel.info => OiIcons.info,
      ToastLevel.warning || ToastLevel.error => OiIcons.circleAlert,
    };

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 280),
            curve: _entryCurve,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - t)),
                child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
              ),
            ),
            child: Semantics(
              liveRegion: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaces.toastBackground,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: context.shadows.lg,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: OiRow(
                    breakpoint: OiBreakpoint.compact,
                    mainAxisSize: MainAxisSize.min,
                    gap: const OiResponsive(8),
                    children: [
                      OiIcon.decorative(icon: icon, size: 16, color: iconColor),
                      Flexible(
                        child: OiLabel.smallStrong(
                          message,
                          color: surfaces.toastText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
