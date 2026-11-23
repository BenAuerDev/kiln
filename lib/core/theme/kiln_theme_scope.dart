import 'package:flutter/widgets.dart';

import 'kiln_tokens.dart';

/// Provides the active finish to the tree. Sits above `OiApp`, so tokens are
/// resolved against the current Obers brightness at lookup time.
class KilnThemeScope extends InheritedWidget {
  const KilnThemeScope({required this.finish, required super.child, super.key});

  final KilnFinishTokens finish;

  static KilnFinishTokens of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KilnThemeScope>()!.finish;

  @override
  bool updateShouldNotify(KilnThemeScope oldWidget) =>
      finish != oldWidget.finish;
}
