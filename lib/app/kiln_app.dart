import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:obers_ui/obers_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../core/router/app_router.dart';
import '../core/router/signal_listenable.dart';
import '../core/service_locator.dart';
import '../core/theme/kiln_theme.dart';
import '../core/theme/kiln_theme_scope.dart';
import '../features/background/presentation/view_models/background_view_model.dart';
import '../features/home_widgets/presentation/view_models/home_widgets_view_model.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_view_model.dart';

class KilnApp extends HookWidget {
  const KilnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = useMemoized(() => sl<AppViewModel>());
    useEffect(() => vm.dispose, [vm]);
    final background = useMemoized(() => sl<BackgroundViewModel>());
    useEffect(() => background.dispose, [background]);
    final homeWidgets = useMemoized(() => sl<HomeWidgetsViewModel>());
    useEffect(() => homeWidgets.dispose, [homeWidgets]);
    final refresh = useMemoized(() => SignalListenable(vm.pastWelcome));
    useEffect(() => refresh.dispose, [refresh]);
    final router = useMemoized(
      () => buildAppRouter(refresh: refresh, pastWelcome: vm.pastWelcome),
    );
    useEffect(() => router.dispose, [router]);

    return SignalBuilder(
      builder: (context) {
        final finish = vm.finish.value;
        return KilnThemeScope(
          finish: finish,
          // Some Obers components (e.g. OiBottomBar labels) use a bare
          // TextStyle and would otherwise fall back to the platform font.
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: KilnFonts.body),
            child: OiApp.router(
              routerConfig: router,
              title: vm.title.value,
              theme: buildKilnTheme(finish, Brightness.light),
              darkTheme: buildKilnTheme(finish, Brightness.dark),
              locale: vm.locale.value,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              debugShowCheckedModeBanner: false,
            ),
          ),
        );
      },
    );
  }
}
