import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/l10n/get_app_localizations.dart';
import '../../../../../core/theme/build_context_x.dart';
import '../common/portable_card.dart';

/// "Find my Veazy" row. While [finding], a ping ripples from the icon
/// (not under reduced motion).
class PortableFindDeviceButton extends HookWidget {
  const PortableFindDeviceButton({
    required this.title,
    required this.subtitle,
    required this.finding,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool finding;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final kiln = context.kiln;
    final animate = finding && !MediaQuery.disableAnimationsOf(context);
    final ping = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );
    useEffect(() {
      if (animate) {
        ping.repeat();
      } else {
        ping
          ..stop()
          ..value = 0;
      }
      return null;
    }, [animate]);
    final t = useAnimation(ping);
    final radius = BorderRadius.circular(18);
    return OiTappable(
      semanticLabel: getAppLocalizations(
        context,
      ).commonSemanticsTitleSubtitle(title, subtitle),
      enabled: enabled,
      onTap: onTap,
      clipBorderRadius: radius,
      child: SizedBox(
        height: 60,
        child: PortableCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 14,
            children: [
              SizedBox.square(
                dimension: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (animate)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.9 * (1 - t),
                          child: Transform.scale(
                            scale: 0.6 + 1.6 * t,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: kiln.accent.glow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: kiln.surfaces.surfaceRaised,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: OiIcon.decorative(
                            icon: OiIcons.locateFixed,
                            size: 20,
                            color: kiln.accent.accentText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    OiLabel.bodyStrong(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    OiLabel.small(
                      subtitle,
                      color: kiln.surfaces.muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
