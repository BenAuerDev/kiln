import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

import '../../../../../core/theme/build_context_x.dart';

/// Small uppercase heading above a group, as in the mockups.
class PortableSectionLabel extends StatelessWidget {
  const PortableSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: OiLabel.overline(
      text.toUpperCase(),
      semanticsLabel: text,
      color: context.kiln.surfaces.muted,
    ),
  );
}
